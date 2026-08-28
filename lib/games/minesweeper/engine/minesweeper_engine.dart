import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../services/game_audio.dart';
import 'minesweeper_audio.dart';
import 'minesweeper_store.dart';

/// The three classic board sizes.
///
/// The ids are persisted as part of the best-time key, so they are part of the
/// save format and must not be renamed.
enum MineLevel {
  beginner('beginner', 9, 9, 10),
  intermediate('intermediate', 16, 16, 40),
  expert('expert', 30, 16, 99);

  final String id;
  final int columns;
  final int rows;
  final int mines;

  const MineLevel(this.id, this.columns, this.rows, this.mines);

  int get cells => columns * rows;

  static MineLevel? byId(String id) {
    for (final level in values) {
      if (level.id == id) return level;
    }
    return null;
  }
}

enum CellState { hidden, revealed, flagged }

/// One square on the board.
class MineCell {
  bool mine = false;
  CellState state = CellState.hidden;

  /// Mines in the eight neighbours. Valid only once mines are placed.
  int neighbours = 0;

  /// The mine the player actually clicked, drawn differently from the rest so
  /// a loss shows *where* it went wrong.
  bool exploded = false;

  /// Position in the most recent reveal batch, or -1. The painter staggers the
  /// reveal animation by this, which is what turns a flood fill into a visible
  /// cascade instead of a whole region blinking on at once.
  int revealOrder = -1;
}

enum MineOutcome { playing, won, lost }

/// Minesweeper's simulation.
///
/// Turn-based like 2048, so there is no frame loop — except for the clock,
/// which ticks once a second through its own [clock] listenable so the timer
/// readout can rebuild without touching the board.
class MinesweeperEngine extends ChangeNotifier {
  final MinesweeperStore _store;
  final math.Random _random;

  MineLevel _level = MineLevel.beginner;
  List<MineCell> _cells = [];

  /// Mines are placed on the first reveal, not at deal time, so the first
  /// click can be guaranteed safe. Losing on move one is not a puzzle.
  bool _seeded = false;

  MineOutcome _outcome = MineOutcome.playing;
  int _elapsedSeconds = 0;
  bool _clockRunning = false;
  int _revealBatch = 0;
  int _batchOrder = 0;
  final Map<String, int> _bestTimes = {};

  MinesweeperEngine({MinesweeperStore? store, math.Random? random})
    : _store = store ?? const MinesweeperStore(),
      _random = random ?? math.Random();

  MineLevel get level => _level;
  List<MineCell> get cells => _cells;
  MineOutcome get outcome => _outcome;
  bool get isOver => _outcome != MineOutcome.playing;
  int get elapsedSeconds => _elapsedSeconds;

  /// Mines the player has not yet accounted for. Goes negative when they have
  /// over-flagged, which is information, not an error.
  int get flagsLeft =>
      _level.mines - _cells.where((c) => c.state == CellState.flagged).length;

  int get revealedCount =>
      _cells.where((c) => c.state == CellState.revealed).length;

  /// Best time in seconds for the current level, or null if never solved.
  int? get bestTime => _bestTimes[_level.id];

  /// Which reveal batch the cells' [MineCell.revealOrder] belongs to. The view
  /// restarts its cascade animation when this changes.
  int get revealBatch => _revealBatch;

  int index(int x, int y) => y * _level.columns + x;

  // ------------------------------------------------------------------ lifecycle

  Future<void> start() async {
    _bestTimes.addAll(await _store.loadBestTimes());
    final save = await _store.loadSave();
    if (save == null || !_hydrate(save)) {
      _deal(_level);
    }
    notifyListeners();
  }

  void newGame([MineLevel? level]) {
    _deal(level ?? _level);
    unawaited(_store.clearSave());
    notifyListeners();
  }

  void _deal(MineLevel level) {
    _level = level;
    _cells = List.generate(level.cells, (_) => MineCell());
    _seeded = false;
    _outcome = MineOutcome.playing;
    _elapsedSeconds = 0;
    _clockRunning = false;
    _revealBatch = 0;
    _batchOrder = 0;
  }

  // ---------------------------------------------------------------------- clock

  /// Called once a second by the page. Only advances while a game is actually
  /// in progress, so a board left open on the start screen reads 0.
  void tickClock() {
    if (!_clockRunning || isOver) return;
    _elapsedSeconds++;
    notifyListeners();
  }

  // ----------------------------------------------------------------------- play

  /// Uncovers a square. The first reveal of a game also places the mines.
  void reveal(int at) {
    if (isOver || at < 0 || at >= _cells.length) return;
    final cell = _cells[at];
    if (cell.state != CellState.hidden) return;

    if (!_seeded) {
      _seedMines(around: at);
      _seeded = true;
      _clockRunning = true;
    }

    if (cell.mine) {
      cell.exploded = true;
      _lose();
      return;
    }

    _startBatch();
    _floodFrom(at);
    GameAudio.instance.play(MinesweeperSfx.reveal);
    _checkWin();
    _persist();
    notifyListeners();
  }

  void toggleFlag(int at) {
    if (isOver || at < 0 || at >= _cells.length) return;
    final cell = _cells[at];
    if (cell.state == CellState.revealed) return;
    cell.state = cell.state == CellState.flagged
        ? CellState.hidden
        : CellState.flagged;
    GameAudio.instance.play(MinesweeperSfx.flag);
    // Flagging every mine is not a win on its own — the remaining safe squares
    // still have to be cleared — so only the flag count changes here.
    _persist();
    notifyListeners();
  }

  /// Clears the neighbours of a satisfied number.
  ///
  /// This is the move that makes a large board playable: without it, expert is
  /// a few hundred individual clicks. It trusts the player's flags, so a
  /// misplaced flag loses the game — which is the point.
  void chord(int at) {
    if (isOver || at < 0 || at >= _cells.length) return;
    final cell = _cells[at];
    if (cell.state != CellState.revealed || cell.neighbours == 0) return;

    final neighbours = _neighboursOf(at);
    final flagged = neighbours
        .where((i) => _cells[i].state == CellState.flagged)
        .length;
    if (flagged != cell.neighbours) return;

    final toReveal = neighbours
        .where((i) => _cells[i].state == CellState.hidden)
        .toList();
    if (toReveal.isEmpty) return;

    final mine = toReveal.firstWhere((i) => _cells[i].mine, orElse: () => -1);
    if (mine >= 0) {
      _cells[mine].exploded = true;
      _lose();
      return;
    }

    _startBatch();
    for (final i in toReveal) {
      _floodFrom(i);
    }
    GameAudio.instance.play(MinesweeperSfx.reveal);
    _checkWin();
    _persist();
    notifyListeners();
  }

  void _startBatch() {
    _revealBatch++;
    _batchOrder = 0;
    for (final cell in _cells) {
      cell.revealOrder = -1;
    }
  }

  /// Iterative rather than recursive: an empty region on expert can run to
  /// several hundred cells, which is deep enough to matter.
  void _floodFrom(int start) {
    final stack = <int>[start];
    while (stack.isNotEmpty) {
      final at = stack.removeLast();
      final cell = _cells[at];
      if (cell.state != CellState.hidden) continue;
      cell.state = CellState.revealed;
      cell.revealOrder = _batchOrder++;
      if (cell.neighbours != 0) continue;
      for (final next in _neighboursOf(at)) {
        if (_cells[next].state == CellState.hidden) stack.add(next);
      }
    }
  }

  void _seedMines({required int around}) {
    // The clicked square and its eight neighbours are kept clear, so the first
    // click always opens a region rather than a bare number.
    final safe = {around, ..._neighboursOf(around)};
    final candidates = [
      for (var i = 0; i < _cells.length; i++)
        if (!safe.contains(i)) i,
    ];
    // On a board too small to spare a full safe patch, only the clicked square
    // is protected — beginner with 10 mines has room, a hand-built one may not.
    final pool = candidates.length >= _level.mines
        ? candidates
        : [
            for (var i = 0; i < _cells.length; i++)
              if (i != around) i,
          ];

    for (var placed = 0; placed < _level.mines && pool.isNotEmpty; placed++) {
      final pick = _random.nextInt(pool.length);
      _cells[pool.removeAt(pick)].mine = true;
    }

    for (var i = 0; i < _cells.length; i++) {
      _cells[i].neighbours = _neighboursOf(
        i,
      ).where((n) => _cells[n].mine).length;
    }
  }

  List<int> _neighboursOf(int at) {
    final x = at % _level.columns;
    final y = at ~/ _level.columns;
    final result = <int>[];
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= _level.columns || ny >= _level.rows) {
          continue;
        }
        result.add(ny * _level.columns + nx);
      }
    }
    return result;
  }

  void _lose() {
    _outcome = MineOutcome.lost;
    _clockRunning = false;
    for (final cell in _cells) {
      if (cell.mine && cell.state != CellState.flagged) {
        cell.state = CellState.revealed;
      }
    }
    GameAudio.instance.play(MinesweeperSfx.boom);
    unawaited(_store.clearSave());
    notifyListeners();
  }

  void _checkWin() {
    if (revealedCount != _level.cells - _level.mines) return;
    _outcome = MineOutcome.won;
    _clockRunning = false;
    // Every remaining hidden square is a mine by definition, so flagging them
    // saves the player a lap of the board to finish tidily.
    for (final cell in _cells) {
      if (cell.mine) cell.state = CellState.flagged;
    }
    final previous = _bestTimes[_level.id];
    if (previous == null || _elapsedSeconds < previous) {
      _bestTimes[_level.id] = _elapsedSeconds;
      unawaited(_store.saveBestTime(_level.id, _elapsedSeconds));
    }
    GameAudio.instance.play(MinesweeperSfx.win);
    unawaited(_store.clearSave());
  }

  /// True when the win was also a record. Used for the result panel's wording.
  bool get isRecord =>
      _outcome == MineOutcome.won && _bestTimes[_level.id] == _elapsedSeconds;

  // ---------------------------------------------------------------- persistence

  void _persist() {
    if (isOver) return;
    unawaited(_store.writeSave(_serialize()));
  }

  Future<void> saveNow() async {
    if (!isOver) await _store.writeSave(_serialize());
  }

  Map<String, dynamic> _serialize() => {
    'level': _level.id,
    'seconds': _elapsedSeconds,
    'seeded': _seeded,
    'mines': [
      for (var i = 0; i < _cells.length; i++)
        if (_cells[i].mine) i,
    ],
    'revealed': [
      for (var i = 0; i < _cells.length; i++)
        if (_cells[i].state == CellState.revealed) i,
    ],
    'flagged': [
      for (var i = 0; i < _cells.length; i++)
        if (_cells[i].state == CellState.flagged) i,
    ],
  };

  /// Rebuilds from a save, rejecting anything it cannot trust: an unknown
  /// level, an index off the board, a mine count that does not match the level,
  /// or a revealed square that is also a mine — which no legal game can reach.
  bool _hydrate(Map<String, dynamic> data) {
    final rawLevel = data['level'];
    if (rawLevel is! String) return false;
    final level = MineLevel.byId(rawLevel);
    if (level == null) return false;

    final mines = _indices(data['mines'], level.cells);
    final revealed = _indices(data['revealed'], level.cells);
    final flagged = _indices(data['flagged'], level.cells);
    if (mines == null || revealed == null || flagged == null) return false;

    final seeded = data['seeded'] == true;
    if (seeded && mines.length != level.mines) return false;
    if (!seeded && mines.isNotEmpty) return false;
    if (revealed.any(mines.contains)) return false;
    if (revealed.any(flagged.contains)) return false;
    if (revealed.length >= level.cells - level.mines) return false;

    _deal(level);
    _seeded = seeded;
    for (final i in mines) {
      _cells[i].mine = true;
    }
    if (seeded) {
      for (var i = 0; i < _cells.length; i++) {
        _cells[i].neighbours = _neighboursOf(
          i,
        ).where((n) => _cells[n].mine).length;
      }
    }
    for (final i in revealed) {
      _cells[i].state = CellState.revealed;
    }
    for (final i in flagged) {
      _cells[i].state = CellState.flagged;
    }
    final seconds = data['seconds'];
    _elapsedSeconds = seconds is int && seconds >= 0 ? seconds : 0;
    _clockRunning = seeded && revealed.isNotEmpty;
    return true;
  }

  /// A list of distinct in-range cell indices, or null if the blob is not one.
  static Set<int>? _indices(Object? raw, int limit) {
    if (raw == null) return <int>{};
    if (raw is! List) return null;
    final result = <int>{};
    for (final entry in raw) {
      if (entry is! int || entry < 0 || entry >= limit) return null;
      result.add(entry);
    }
    return result;
  }
}
