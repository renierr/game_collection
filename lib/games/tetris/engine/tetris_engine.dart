import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/frame_beacon.dart';
import '../../../services/game_audio.dart';
import 'tetris_audio.dart';
import 'tetris_store.dart';
import 'tetromino.dart';

/// The playfield's fixed dimensions.
///
/// Two rows above the visible area are where pieces spawn. They exist so a
/// piece can appear and be rotated before it is on screen, which is what makes
/// the top of the board playable rather than instantly fatal.
class TetrisField {
  TetrisField._();

  static const int columns = 10;
  static const int visibleRows = 20;
  static const int hiddenRows = 2;
  static const int rows = visibleRows + hiddenRows;
  static const int cells = columns * rows;

  /// Where a piece's box is placed on spawn.
  static const int spawnX = 3;
  static const int spawnY = 0;
}

class TetrisTuning {
  TetrisTuning._();

  /// How long a piece rests on the stack before it locks. The window is what
  /// lets a player slide a piece into a gap at the last moment.
  static const double lockDelay = 0.5;

  /// A move or rotation restarts the lock delay, but only this many times — the
  /// cap is what stops a spinning piece from never locking at all.
  static const int maxLockResets = 15;

  /// How long cleared rows flash before they are removed. Short enough not to
  /// break the rhythm, long enough to see what you did.
  static const double clearFlashSeconds = 0.22;

  static const int linesPerLevel = 10;

  /// Points per line count cleared at once, multiplied by the level. The jump
  /// at four is the whole reason to build a well instead of clearing singles.
  static const List<int> lineScores = [0, 100, 300, 500, 800];

  static const int comboBonus = 50;
  static const int softDropPoints = 1;
  static const int hardDropPoints = 2;

  /// How many upcoming pieces the player can see.
  static const int previewCount = 3;

  static const double minFallInterval = 0.025;
}

/// The piece under the player's control.
class ActivePiece {
  TetrominoKind kind;
  int rotation;

  /// Top-left of the piece's rotation box, in field coordinates.
  int x;
  int y;

  ActivePiece({
    required this.kind,
    required this.rotation,
    required this.x,
    required this.y,
  });

  /// Absolute field cells the piece currently fills.
  List<(int, int)> cells() => [
    for (final (cx, cy) in kind.cellsAt(rotation)) (x + cx, y + cy),
  ];
}

enum TetrisPhase { falling, clearing, over }

/// Tetris's simulation: a gravity-driven fall with SRS rotation and wall kicks.
///
/// Free of Flutter widgets — the page drives it with [update] once per frame
/// and paints from its public state. Row clears run through a short [clearing]
/// phase rather than resolving instantly, so the view has something to animate
/// and the player can see which rows went.
class TetrisEngine {
  final TetrisStore _store;
  final math.Random _random;

  final FrameBeacon _frames = FrameBeacon();
  final FrameBeacon _hud = FrameBeacon();

  /// Repaint signal for the board painter — fires every frame.
  Listenable get frames => _frames;

  /// Rebuild signal for the HUD — fires only when a displayed value changed.
  Listenable get hud => _hud;

  final List<TetrominoKind?> _cells = List<TetrominoKind?>.filled(
    TetrisField.cells,
    null,
  );

  /// The next pieces, kept topped up from [_bag].
  final List<TetrominoKind> _queue = [];

  /// The current shuffled bag. A 7-bag means every piece arrives once per seven
  /// — long droughts are impossible, which is what makes the game a test of
  /// stacking rather than of luck.
  final List<TetrominoKind> _bag = [];

  final List<int> _clearing = [];

  ActivePiece? _active;
  TetrominoKind? _hold;

  /// Hold is once per piece. Without the limit a player could shuffle two
  /// pieces back and forth forever instead of committing to a placement.
  bool _holdUsed = false;

  int _score = 0;
  int _best = 0;
  int _lines = 0;
  int _combo = 0;
  int _pieces = 0;

  double _gravity = 0;
  double _lockTimer = 0;
  int _lockResets = 0;
  bool _resting = false;
  double _clearTimer = 0;

  TetrisPhase _phase = TetrisPhase.falling;
  bool _paused = false;
  bool _started = false;

  TetrisEngine({TetrisStore? store, math.Random? random})
    : _store = store ?? const TetrisStore(),
      _random = random ?? math.Random();

  List<TetrominoKind?> get cells => _cells;
  ActivePiece? get active => _active;
  TetrominoKind? get hold => _hold;
  bool get holdUsed => _holdUsed;
  List<TetrominoKind> get preview =>
      _queue.take(TetrisTuning.previewCount).toList();
  List<int> get clearingRows => _clearing;
  int get score => _score;
  int get best => _best;
  int get lines => _lines;
  int get pieces => _pieces;
  int get combo => _combo;
  int get level => 1 + _lines ~/ TetrisTuning.linesPerLevel;
  TetrisPhase get phase => _phase;
  bool get isOver => _phase == TetrisPhase.over;
  bool get isPaused => _paused;
  bool get hasStarted => _started;

  /// 0..1 of the row-clear flash still to run, for the view.
  double get clearProgress => _clearing.isEmpty
      ? 0
      : 1 - (_clearTimer / TetrisTuning.clearFlashSeconds).clamp(0.0, 1.0);

  /// Seconds a piece takes to fall one row at the current level — the standard
  /// guideline curve, which starts forgiving and becomes brutal around 13.
  double get fallInterval => math.max(
    TetrisTuning.minFallInterval,
    math.pow(0.8 - (level - 1) * 0.007, level - 1).toDouble(),
  );

  /// Where the active piece would land if dropped now. The ghost outline drawn
  /// there is the single biggest readability win on a fast board.
  int get ghostDrop {
    final piece = _active;
    if (piece == null) return 0;
    var distance = 0;
    while (_fits(piece.kind, piece.rotation, piece.x, piece.y + distance + 1)) {
      distance++;
    }
    return distance;
  }

  // ------------------------------------------------------------------ lifecycle

  Future<void> start() async {
    _best = await _store.loadBest();
    final save = await _store.loadSave();
    if (save == null || !_hydrate(save)) {
      _reset();
    }
    _started = true;
    _hud.ping();
  }

  void newGame() {
    _reset();
    unawaited(_store.clearSave());
    _hud.ping();
    _frames.ping();
  }

  void _reset() {
    _cells.fillRange(0, TetrisField.cells, null);
    _queue.clear();
    _bag.clear();
    _clearing.clear();
    _hold = null;
    _holdUsed = false;
    _score = 0;
    _lines = 0;
    _combo = 0;
    _pieces = 0;
    _gravity = 0;
    _lockTimer = 0;
    _lockResets = 0;
    _resting = false;
    _clearTimer = 0;
    _phase = TetrisPhase.falling;
    _paused = false;
    _refillQueue();
    _spawn();
  }

  void dispose() {
    _frames.dispose();
    _hud.dispose();
  }

  void togglePause() {
    if (isOver) return;
    _paused = !_paused;
    if (_paused) unawaited(saveNow());
    _hud.ping();
    _frames.ping();
  }

  // ----------------------------------------------------------------------- loop

  void update(double dt) {
    if (_phase == TetrisPhase.over || _paused) {
      _frames.ping();
      return;
    }

    if (_phase == TetrisPhase.clearing) {
      _clearTimer -= dt;
      if (_clearTimer <= 0) _finishClear();
      _frames.ping();
      return;
    }

    final piece = _active;
    if (piece == null) {
      _frames.ping();
      return;
    }

    if (_resting) {
      _lockTimer += dt;
      if (_lockTimer >= TetrisTuning.lockDelay) {
        _lock();
        _frames.ping();
        return;
      }
    } else {
      _gravity += dt;
      while (_gravity >= fallInterval && !_resting) {
        _gravity -= fallInterval;
        _fall();
      }
    }
    _frames.ping();
  }

  void _fall() {
    final piece = _active;
    if (piece == null) return;
    if (_fits(piece.kind, piece.rotation, piece.x, piece.y + 1)) {
      piece.y++;
    } else {
      _resting = true;
      _lockTimer = 0;
    }
  }

  // ---------------------------------------------------------------------- input

  bool moveLeft() => _shift(-1);

  bool moveRight() => _shift(1);

  bool _shift(int dx) {
    final piece = _active;
    if (piece == null || _phase != TetrisPhase.falling || _paused) return false;
    if (!_fits(piece.kind, piece.rotation, piece.x + dx, piece.y)) return false;
    piece.x += dx;
    _afterPlayerMove();
    GameAudio.instance.play(TetrisSfx.move);
    return true;
  }

  /// One row down, for a tap or a held down-key. Worth a point, which is the
  /// small reward for driving the piece rather than waiting for gravity.
  bool softDrop() {
    final piece = _active;
    if (piece == null || _phase != TetrisPhase.falling || _paused) return false;
    if (!_fits(piece.kind, piece.rotation, piece.x, piece.y + 1)) {
      // Already resting: pressing down again commits the piece rather than
      // doing nothing, which is what players expect.
      _lock();
      return true;
    }
    piece.y++;
    _score += TetrisTuning.softDropPoints;
    _gravity = 0;
    // Starts the lock delay the moment the piece lands. Without this a piece
    // driven down by the player gets a whole extra fall interval of grace.
    _afterPlayerMove();
    _hud.ping();
    return true;
  }

  void hardDrop() {
    final piece = _active;
    if (piece == null || _phase != TetrisPhase.falling || _paused) return;
    final distance = ghostDrop;
    piece.y += distance;
    _score += distance * TetrisTuning.hardDropPoints;
    GameAudio.instance.play(TetrisSfx.hardDrop);
    _lock();
  }

  bool rotate({required bool clockwise}) {
    final piece = _active;
    if (piece == null || _phase != TetrisPhase.falling || _paused) return false;
    final target = (piece.rotation + (clockwise ? 1 : 3)) % 4;
    final kicks = WallKicks.forRotation(
      kind: piece.kind,
      from: piece.rotation,
      clockwise: clockwise,
    );
    for (final (dx, dy) in kicks) {
      if (_fits(piece.kind, target, piece.x + dx, piece.y + dy)) {
        piece.rotation = target;
        piece.x += dx;
        piece.y += dy;
        _afterPlayerMove();
        GameAudio.instance.play(TetrisSfx.rotate);
        return true;
      }
    }
    return false;
  }

  /// Swaps the active piece with the held one, or banks it if the hold is empty.
  void holdPiece() {
    final piece = _active;
    if (piece == null ||
        _holdUsed ||
        _phase != TetrisPhase.falling ||
        _paused) {
      return;
    }
    final banked = _hold;
    _hold = piece.kind;
    if (banked == null) {
      _spawn();
    } else {
      _spawn(kind: banked);
    }
    // Set after the spawn: taking a piece from the queue clears the flag, and
    // banking the very first piece does exactly that.
    _holdUsed = true;
    GameAudio.instance.play(TetrisSfx.hold);
    _hud.ping();
  }

  /// A successful player move refreshes the lock delay, so a piece can be slid
  /// along the floor into place — but only [TetrisTuning.maxLockResets] times.
  void _afterPlayerMove() {
    final piece = _active;
    if (piece == null) return;
    final grounded = !_fits(piece.kind, piece.rotation, piece.x, piece.y + 1);
    if (!grounded) {
      _resting = false;
      _lockTimer = 0;
      return;
    }
    _resting = true;
    if (_lockResets < TetrisTuning.maxLockResets) {
      _lockResets++;
      _lockTimer = 0;
    }
  }

  // ------------------------------------------------------------------- locking

  void _lock() {
    final piece = _active;
    if (piece == null) return;
    for (final (x, y) in piece.cells()) {
      if (y >= 0 && y < TetrisField.rows && x >= 0 && x < TetrisField.columns) {
        _cells[y * TetrisField.columns + x] = piece.kind;
      }
    }
    _active = null;
    _resting = false;
    _lockTimer = 0;
    _lockResets = 0;
    _gravity = 0;
    _pieces++;

    final full = _fullRows();
    if (full.isEmpty) {
      _combo = 0;
      GameAudio.instance.play(TetrisSfx.lock);
      _spawn();
      _hud.ping();
      unawaited(saveNow());
      return;
    }

    _clearing
      ..clear()
      ..addAll(full);
    _clearTimer = TetrisTuning.clearFlashSeconds;
    _phase = TetrisPhase.clearing;
    GameAudio.instance.play(
      full.length >= 4 ? TetrisSfx.tetris : TetrisSfx.clear,
    );
  }

  List<int> _fullRows() {
    final full = <int>[];
    for (var y = 0; y < TetrisField.rows; y++) {
      var complete = true;
      for (var x = 0; x < TetrisField.columns; x++) {
        if (_cells[y * TetrisField.columns + x] == null) {
          complete = false;
          break;
        }
      }
      if (complete) full.add(y);
    }
    return full;
  }

  void _finishClear() {
    final cleared = _clearing.length;
    final levelBefore = level;

    // Rebuilt from the bottom up, skipping cleared rows: this shifts everything
    // above a clear down by exactly the number of rows removed below it,
    // including several non-adjacent clears at once.
    final kept = <TetrominoKind?>[];
    for (var y = TetrisField.rows - 1; y >= 0; y--) {
      if (_clearing.contains(y)) continue;
      for (var x = TetrisField.columns - 1; x >= 0; x--) {
        kept.add(_cells[y * TetrisField.columns + x]);
      }
    }
    _cells.fillRange(0, TetrisField.cells, null);
    for (var i = 0; i < kept.length; i++) {
      _cells[TetrisField.cells - 1 - i] = kept[i];
    }

    _lines += cleared;
    _score += TetrisTuning.lineScores[cleared.clamp(0, 4)] * levelBefore;
    if (_combo > 0) {
      _score += TetrisTuning.comboBonus * _combo * levelBefore;
    }
    _combo++;
    _clearing.clear();
    _phase = TetrisPhase.falling;
    if (level > levelBefore) GameAudio.instance.play(TetrisSfx.levelUp);
    if (_score > _best) {
      _best = _score;
      unawaited(_store.saveBest(_best));
    }
    _spawn();
    _hud.ping();
    unawaited(saveNow());
  }

  // -------------------------------------------------------------------- spawning

  void _refillQueue() {
    while (_queue.length <= TetrisTuning.previewCount) {
      if (_bag.isEmpty) {
        _bag.addAll(TetrominoKind.values);
        _bag.shuffle(_random);
      }
      _queue.add(_bag.removeLast());
    }
  }

  void _spawn({TetrominoKind? kind}) {
    _refillQueue();
    final next = kind ?? _queue.removeAt(0);
    _refillQueue();
    _holdUsed = kind != null ? _holdUsed : false;
    final piece = ActivePiece(
      kind: next,
      rotation: 0,
      x: TetrisField.spawnX,
      y: TetrisField.spawnY,
    );
    if (!_fits(piece.kind, piece.rotation, piece.x, piece.y)) {
      _active = piece;
      _gameOver();
      return;
    }
    _active = piece;
    _resting = false;
    _lockTimer = 0;
    _lockResets = 0;
    _gravity = 0;
  }

  void _gameOver() {
    _phase = TetrisPhase.over;
    if (_score > _best) {
      _best = _score;
      unawaited(_store.saveBest(_best));
    }
    GameAudio.instance.play(TetrisSfx.gameOver);
    unawaited(_store.clearSave());
    _hud.ping();
  }

  /// Whether [kind] at [rotation] fits with its box at ([x], [y]).
  bool _fits(TetrominoKind kind, int rotation, int x, int y) {
    for (final (cx, cy) in kind.cellsAt(rotation)) {
      final fx = x + cx;
      final fy = y + cy;
      if (fx < 0 || fx >= TetrisField.columns) return false;
      if (fy >= TetrisField.rows) return false;
      // Above the field is empty by definition — a piece may stick out of the
      // top while it is still being rotated into place.
      if (fy < 0) continue;
      if (_cells[fy * TetrisField.columns + fx] != null) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------- persistence

  Future<void> saveNow() async {
    if (isOver) return;
    await _store.writeSave(_serialize());
  }

  Map<String, dynamic> _serialize() {
    final piece = _active;
    return {
      'score': _score,
      'lines': _lines,
      'combo': _combo,
      'pieces': _pieces,
      'hold': _hold?.index,
      'holdUsed': _holdUsed,
      'queue': [for (final kind in _queue) kind.index],
      'cells': [for (final cell in _cells) cell?.index ?? -1],
      if (piece != null)
        'active': {
          'kind': piece.kind.index,
          'rotation': piece.rotation,
          'x': piece.x,
          'y': piece.y,
        },
    };
  }

  /// Rebuilds from a save, rejecting anything it cannot trust rather than
  /// trusting the blob: a wrong-sized board, an unknown piece index, or an
  /// active piece overlapping the stack — none of which legal play can produce.
  bool _hydrate(Map<String, dynamic> data) {
    final rawCells = data['cells'];
    if (rawCells is! List || rawCells.length != TetrisField.cells) return false;

    final board = List<TetrominoKind?>.filled(TetrisField.cells, null);
    for (var i = 0; i < rawCells.length; i++) {
      final value = rawCells[i];
      if (value is! int) return false;
      if (value == -1) continue;
      final kind = TetrominoKind.byIndex(value);
      if (kind == null) return false;
      board[i] = kind;
    }

    final rawQueue = data['queue'];
    if (rawQueue is! List || rawQueue.isEmpty) return false;
    final queue = <TetrominoKind>[];
    for (final value in rawQueue) {
      final kind = value is int ? TetrominoKind.byIndex(value) : null;
      if (kind == null) return false;
      queue.add(kind);
    }

    final rawHold = data['hold'];
    TetrominoKind? held;
    if (rawHold != null) {
      held = rawHold is int ? TetrominoKind.byIndex(rawHold) : null;
      if (held == null) return false;
    }

    ActivePiece? piece;
    final rawActive = data['active'];
    if (rawActive is Map) {
      final kind = rawActive['kind'] is int
          ? TetrominoKind.byIndex(rawActive['kind'] as int)
          : null;
      final rotation = rawActive['rotation'];
      final x = rawActive['x'];
      final y = rawActive['y'];
      if (kind == null || rotation is! int || x is! int || y is! int) {
        return false;
      }
      if (rotation < 0 || rotation > 3) return false;
      piece = ActivePiece(kind: kind, rotation: rotation, x: x, y: y);
    }

    _reset();
    _cells.setAll(0, board);
    _queue
      ..clear()
      ..addAll(queue);
    _hold = held;

    final score = data['score'];
    final lines = data['lines'];
    final combo = data['combo'];
    final pieces = data['pieces'];
    _score = score is int && score >= 0 ? score : 0;
    _lines = lines is int && lines >= 0 ? lines : 0;
    _combo = combo is int && combo >= 0 ? combo : 0;
    _pieces = pieces is int && pieces >= 0 ? pieces : 0;

    if (piece != null) {
      if (!_fits(piece.kind, piece.rotation, piece.x, piece.y)) return false;
      _active = piece;
    } else {
      // The piece [_reset] dealt was spawned against an empty board and may now
      // be buried in the restored stack, so it is replaced by one spawned
      // against the real board.
      _active = null;
      _spawn();
    }
    // After the spawn: taking a piece from the queue clears the flag, and the
    // saved value is the one that matters.
    _holdUsed = data['holdUsed'] == true;
    return true;
  }
}
