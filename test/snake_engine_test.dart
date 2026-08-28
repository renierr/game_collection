import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:game_collection/core/game_direction.dart';
import 'package:game_collection/games/snake/engine/snake_engine.dart';
import 'package:game_collection/games/snake/engine/snake_store.dart';

class _MemoryStore implements SnakeStore {
  int best = 0;

  @override
  Future<int> loadBest() async => best;

  @override
  Future<void> saveBest(int value) async => best = value;
}

Future<SnakeEngine> _engine({int seed = 4}) async {
  final engine = SnakeEngine(store: _MemoryStore(), random: math.Random(seed));
  await engine.start();
  return engine;
}

/// Advances exactly one grid step. The interval shortens as the snake eats, so
/// it is read back from the engine rather than assumed.
void _step(SnakeEngine engine) {
  engine.update(1 / engine.speed + 1e-6);
}

/// Steers towards the food one step at a time, which is the only way to reach
/// it without the engine exposing a "put the food here" seam it does not need.
///
/// Returns as soon as one meal has been eaten. Chasing the replacement food as
/// well would just be a long random walk, and the snake would eventually run
/// into itself — which is not what the caller is testing.
void _driveToFood(SnakeEngine engine, {int maxSteps = 400}) {
  final before = engine.score;
  for (var i = 0; i < maxSteps; i++) {
    final food = engine.food;
    if (food == null || engine.isDead || engine.score > before) return;
    final head = engine.body.first;

    // Close the vertical gap first, then the horizontal one: with a short
    // snake on a 19-wide board this never doubles back on itself.
    if (head.y != food.cell.y) {
      engine.turn(food.cell.y < head.y ? GameDirection.up : GameDirection.down);
    } else if (head.x != food.cell.x) {
      engine.turn(
        food.cell.x < head.x ? GameDirection.left : GameDirection.right,
      );
    }
    _step(engine);
  }
}

void main() {
  test('a fresh run starts centred and waits for the player', () async {
    final engine = await _engine();

    expect(engine.length, SnakeTuning.startLength);
    expect(engine.hasStarted, isFalse);
    expect(engine.isDead, isFalse);
    expect(engine.score, 0);
    expect(engine.food, isNotNull);

    final head = engine.body.first;
    expect(head.x, SnakeGrid.columns ~/ 2);
    expect(head.y, SnakeGrid.rows ~/ 2);
  });

  test('an idle board does not move on its own', () async {
    final engine = await _engine();
    final head = engine.body.first;

    for (var i = 0; i < 20; i++) {
      _step(engine);
    }
    expect(engine.body.first, head);
    expect(engine.isDead, isFalse);
  });

  test('a turn starts the run and is applied on the next step', () async {
    final engine = await _engine();
    final head = engine.body.first;

    engine.turn(GameDirection.up);
    expect(engine.hasStarted, isTrue);

    _step(engine);
    expect(engine.body.first.y, head.y - 1);
    expect(engine.direction, GameDirection.up);
  });

  test('reversing into your own neck is refused, not fatal', () async {
    final engine = await _engine();
    engine.startRun();

    // Starts facing right, so left is a reversal.
    engine.turn(GameDirection.left);
    _step(engine);

    expect(engine.isDead, isFalse);
    expect(engine.direction, GameDirection.right);
  });

  test('at most two turns are buffered', () async {
    final engine = await _engine();

    engine.turn(GameDirection.up);
    engine.turn(GameDirection.left);
    // A third would let the player queue a path they cannot see yet.
    engine.turn(GameDirection.down);

    _step(engine);
    expect(engine.direction, GameDirection.up);
    _step(engine);
    expect(engine.direction, GameDirection.left);
    _step(engine);
    expect(engine.direction, GameDirection.left);
  });

  test('eating grows the snake and scores', () async {
    final engine = await _engine();
    final startLength = engine.length;
    engine.startRun();

    _driveToFood(engine);
    expect(engine.isDead, isFalse);
    expect(engine.score, greaterThan(0));

    // Growth is paid out over the following steps, so a couple of steps are
    // needed before the new length shows.
    for (var i = 0; i < 4; i++) {
      _step(engine);
    }
    expect(engine.length, greaterThan(startLength));
  });

  test('eating speeds the snake up', () async {
    final engine = await _engine();
    final startSpeed = engine.speed;
    engine.startRun();

    _driveToFood(engine);
    expect(engine.speed, greaterThan(startSpeed));
  });

  test('running into a wall ends the run', () async {
    final engine = await _engine();
    engine.startRun();

    // Straight right from the middle reaches the wall in a bounded number of
    // steps whatever else is on the board.
    for (var i = 0; i < SnakeGrid.columns + 2 && !engine.isDead; i++) {
      _step(engine);
    }
    expect(engine.isDead, isTrue);
    expect(engine.hasStarted, isFalse);
  });

  test('a death banks the best score', () async {
    final store = _MemoryStore();
    final engine = SnakeEngine(store: store, random: math.Random(4));
    await engine.start();
    engine.startRun();

    _driveToFood(engine);
    final scored = engine.score;
    expect(scored, greaterThan(0));

    while (!engine.isDead) {
      _step(engine);
    }
    expect(store.best, greaterThanOrEqualTo(scored));
    expect(engine.best, store.best);
  });

  test('a saved best is loaded and not overwritten by a worse run', () async {
    final store = _MemoryStore()..best = 9999;
    final engine = SnakeEngine(store: store, random: math.Random(4));
    await engine.start();
    expect(engine.best, 9999);

    engine.startRun();
    while (!engine.isDead) {
      _step(engine);
    }
    expect(store.best, 9999);
  });

  test('pausing freezes the snake', () async {
    final engine = await _engine();
    engine.turn(GameDirection.up);
    _step(engine);

    engine.togglePause();
    final head = engine.body.first;
    for (var i = 0; i < 10; i++) {
      _step(engine);
    }
    expect(engine.body.first, head);

    engine.togglePause();
    _step(engine);
    expect(engine.body.first, isNot(head));
  });

  test('step progress runs 0..1 between steps', () async {
    final engine = await _engine();
    engine.startRun();
    expect(engine.stepProgress, 0);

    final interval = 1 / engine.speed;
    engine.update(interval * 0.5);
    expect(engine.stepProgress, closeTo(0.5, 0.05));

    engine.update(interval * 0.5);
    expect(engine.stepProgress, lessThan(0.2));
  });

  test('a new game clears the run', () async {
    final engine = await _engine();
    engine.startRun();
    while (!engine.isDead) {
      _step(engine);
    }

    engine.newGame();
    expect(engine.isDead, isFalse);
    expect(engine.hasStarted, isFalse);
    expect(engine.score, 0);
    expect(engine.length, SnakeTuning.startLength);
  });
}
