import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/frame_beacon.dart';
import '../../../core/game_direction.dart';
import '../../../services/game_audio.dart';
import 'snake_audio.dart';
import 'snake_store.dart';

/// The playfield in cells. Square and odd, so the snake can start dead centre
/// facing right with equal room on both sides.
class SnakeGrid {
  SnakeGrid._();

  static const int columns = 19;
  static const int rows = 19;
  static const int cells = columns * rows;
}

/// How fast the snake moves and what food is worth.
class SnakeTuning {
  SnakeTuning._();

  /// Seconds per cell at the start of a run.
  static const double startInterval = 0.17;

  /// The floor — past this the snake outruns human reaction time.
  static const double minInterval = 0.062;

  /// Taken off the interval per food eaten. Reaching [minInterval] is a
  /// long run, not something the tenth apple does.
  static const double speedUpPerFood = 0.0034;

  static const int foodScore = 10;
  static const int bonusScore = 60;

  /// Every nth food is a bonus that must be eaten before it expires.
  static const int bonusEvery = 5;
  static const double bonusSeconds = 7;

  static const int startLength = 3;

  /// At most two turns are remembered. A player rounding a corner presses two
  /// directions faster than one step, and dropping the second feels broken —
  /// but buffering more than two lets them queue a path they cannot see.
  static const int maxQueuedTurns = 2;
}

/// A cell on the grid.
@immutable
class SnakeCell {
  final int x;
  final int y;

  const SnakeCell(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is SnakeCell && other.x == x && other.y == y;

  @override
  int get hashCode => x * SnakeGrid.columns + y;
}

/// Food on the board. A bonus expires; a plain apple waits forever.
class SnakeFood {
  final SnakeCell cell;
  final bool bonus;
  double remaining;

  SnakeFood({required this.cell, required this.bonus, this.remaining = 0});

  /// 0..1 of the bonus window still left, 1 for a plain apple.
  double get freshness =>
      bonus ? (remaining / SnakeTuning.bonusSeconds).clamp(0.0, 1.0) : 1.0;
}

/// Snake's simulation: a fixed-step grid walk driven by a variable frame clock.
///
/// The step is fixed so the game is the same on any refresh rate, but the view
/// wants smooth motion, so [stepProgress] exposes how far through the current
/// step the snake is and the painter interpolates. That split — integer
/// simulation, fractional presentation — is the whole trick.
class SnakeEngine {
  final SnakeStore _store;
  final math.Random _random;

  final FrameBeacon _frames = FrameBeacon();
  final FrameBeacon _hud = FrameBeacon();

  /// Repaint signal for the board painter — fires every frame.
  Listenable get frames => _frames;

  /// Rebuild signal for the HUD — fires only when a displayed value changed.
  Listenable get hud => _hud;

  /// Head first, tail last.
  final List<SnakeCell> _body = [];

  final List<GameDirection> _queued = [];

  GameDirection _direction = GameDirection.right;
  SnakeFood? _food;

  double _elapsed = 0;
  double _accumulator = 0;
  double _interval = SnakeTuning.startInterval;
  int _score = 0;
  int _best = 0;
  int _eaten = 0;

  /// Cells still owed to the tail. Eating grows the snake over the following
  /// steps rather than all at once, which is what keeps a bonus from teleporting
  /// the tail across the board.
  int _pendingGrowth = 0;

  bool _running = false;
  bool _dead = false;
  bool _paused = false;

  SnakeEngine({SnakeStore? store, math.Random? random})
    : _store = store ?? const SnakeStore(),
      _random = random ?? math.Random();

  List<SnakeCell> get body => _body;
  SnakeFood? get food => _food;
  GameDirection get direction => _direction;
  int get score => _score;
  int get best => _best;
  int get length => _body.length;
  bool get isDead => _dead;
  bool get isPaused => _paused;

  /// False until the first turn. A fresh board waits for the player instead of
  /// walking into a wall while they are still reading the screen.
  bool get hasStarted => _running;

  /// How far through the current step the snake is, 0..1. The painter slides
  /// the head forward and the tail out by this much.
  double get stepProgress =>
      _interval <= 0 ? 0 : (_accumulator / _interval).clamp(0.0, 1.0);

  /// True while the snake is still growing into the food it ate, so the tail
  /// holds its cell instead of sliding out of it.
  bool get tailHolding => _pendingGrowth > 0;

  /// Seconds since the page opened, for animations that must keep breathing
  /// while the game is paused.
  double get timeSeconds => _elapsed;

  /// Cells per second, for the HUD.
  double get speed => _interval <= 0 ? 0 : 1 / _interval;

  Future<void> start() async {
    _best = await _store.loadBest();
    _reset();
    _hud.ping();
  }

  void newGame() {
    _reset();
    _hud.ping();
    _frames.ping();
  }

  void _reset() {
    _body.clear();
    final midY = SnakeGrid.rows ~/ 2;
    final midX = SnakeGrid.columns ~/ 2;
    for (var i = 0; i < SnakeTuning.startLength; i++) {
      _body.add(SnakeCell(midX - i, midY));
    }
    _queued.clear();
    _direction = GameDirection.right;
    _accumulator = 0;
    _interval = SnakeTuning.startInterval;
    _score = 0;
    _eaten = 0;
    _pendingGrowth = 0;
    _running = false;
    _dead = false;
    _paused = false;
    _placeFood();
  }

  void dispose() {
    _frames.dispose();
    _hud.dispose();
  }

  // ---------------------------------------------------------------------- input

  /// Queues a turn. Reversing into your own neck is rejected rather than fatal —
  /// it is nearly always a mis-swipe, and killing the run for it feels unfair.
  void turn(GameDirection direction) {
    if (_dead) return;
    final last = _queued.isEmpty ? _direction : _queued.last;
    if (direction == last || direction == last.opposite) return;
    if (_queued.length >= SnakeTuning.maxQueuedTurns) return;
    _queued.add(direction);
    if (!_running) {
      _running = true;
      _paused = false;
      _hud.ping();
    }
  }

  /// Begins the run without turning, for a tap on the board.
  void startRun() {
    if (_dead || _running) return;
    _running = true;
    _paused = false;
    _hud.ping();
  }

  void togglePause() {
    if (_dead || !_running) return;
    _paused = !_paused;
    _hud.ping();
    _frames.ping();
  }

  // ----------------------------------------------------------------------- loop

  void update(double dt) {
    _elapsed += dt;
    if (_dead || _paused || !_running) {
      _frames.ping();
      return;
    }

    final bonus = _food;
    if (bonus != null && bonus.bonus) {
      bonus.remaining -= dt;
      if (bonus.remaining <= 0) {
        // An expired bonus becomes an ordinary apple rather than vanishing;
        // a board with no food at all would be a dead end.
        _food = SnakeFood(cell: bonus.cell, bonus: false);
        _hud.ping();
      }
    }

    _accumulator += dt;
    // Capped rather than looped to exhaustion: after a stall, catching up on a
    // second of steps would move the snake somewhere the player never saw.
    var steps = 0;
    while (_accumulator >= _interval && !_dead && steps < 4) {
      _accumulator -= _interval;
      _step();
      steps++;
    }
    if (_accumulator > _interval) _accumulator = _interval;
    _frames.ping();
  }

  void _step() {
    if (_queued.isNotEmpty) _direction = _queued.removeAt(0);

    final head = _body.first;
    final next = _ahead(head, _direction);

    if (next.x < 0 ||
        next.y < 0 ||
        next.x >= SnakeGrid.columns ||
        next.y >= SnakeGrid.rows) {
      _die();
      return;
    }
    // The tail cell is about to move out of the way, so running into it is
    // legal — this is what lets a full-length snake follow itself round a bend.
    final ignoreTail = _pendingGrowth == 0;
    for (var i = 0; i < _body.length - (ignoreTail ? 1 : 0); i++) {
      if (_body[i] == next) {
        _die();
        return;
      }
    }

    _body.insert(0, next);
    final food = _food;
    if (food != null && food.cell == next) {
      _score += food.bonus ? SnakeTuning.bonusScore : SnakeTuning.foodScore;
      _eaten++;
      GameAudio.instance.play(
        food.bonus ? SnakeSfx.bonus : SnakeSfx.eat(_eaten),
      );
      _pendingGrowth += food.bonus ? 3 : 1;
      _interval = math.max(
        SnakeTuning.minInterval,
        SnakeTuning.startInterval - _eaten * SnakeTuning.speedUpPerFood,
      );
      _placeFood();
      _hud.ping();
    }

    if (_pendingGrowth > 0) {
      _pendingGrowth--;
    } else {
      _body.removeLast();
    }

    if (_body.length >= SnakeGrid.cells) _die();
  }

  static SnakeCell _ahead(SnakeCell cell, GameDirection direction) {
    switch (direction) {
      case GameDirection.up:
        return SnakeCell(cell.x, cell.y - 1);
      case GameDirection.down:
        return SnakeCell(cell.x, cell.y + 1);
      case GameDirection.left:
        return SnakeCell(cell.x - 1, cell.y);
      case GameDirection.right:
        return SnakeCell(cell.x + 1, cell.y);
    }
  }

  void _placeFood() {
    final taken = _body.toSet();
    final free = <SnakeCell>[];
    for (var y = 0; y < SnakeGrid.rows; y++) {
      for (var x = 0; x < SnakeGrid.columns; x++) {
        final cell = SnakeCell(x, y);
        if (!taken.contains(cell)) free.add(cell);
      }
    }
    if (free.isEmpty) {
      _food = null;
      return;
    }
    final bonus = _eaten > 0 && (_eaten + 1) % SnakeTuning.bonusEvery == 0;
    _food = SnakeFood(
      cell: free[_random.nextInt(free.length)],
      bonus: bonus,
      remaining: bonus ? SnakeTuning.bonusSeconds : 0,
    );
  }

  void _die() {
    _dead = true;
    GameAudio.instance.play(SnakeSfx.die);
    _running = false;
    if (_score > _best) {
      _best = _score;
      unawaited(_store.saveBest(_best));
    }
    _hud.ping();
  }
}
