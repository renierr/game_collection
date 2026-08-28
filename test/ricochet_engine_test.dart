import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_collection/games/ricochet/engine/geometry.dart';
import 'package:game_collection/games/ricochet/engine/ricochet_engine.dart';
import 'package:game_collection/games/ricochet/engine/ricochet_store.dart';
import 'package:game_collection/games/ricochet/engine/tile.dart';

/// Keeps saves in memory so the simulation can be exercised without opening the
/// app's real database.
class _MemoryStore implements RicochetStore {
  int best = 0;
  Map<String, dynamic>? save;
  Map<String, dynamic>? checkpoint;

  @override
  Future<int> loadBest() async => best;

  @override
  Future<void> saveBest(int value) async => best = value;

  @override
  Future<Map<String, dynamic>?> loadSave() async => save;

  @override
  Future<void> writeSave(Map<String, dynamic> data) async => save = data;

  @override
  Future<void> clearSave() async => save = null;

  @override
  Future<Map<String, dynamic>?> loadCheckpoint() async => checkpoint;

  @override
  Future<void> writeCheckpoint(Map<String, dynamic> data) async =>
      checkpoint = data;
}

void main() {
  late _MemoryStore store;
  late RicochetEngine engine;

  setUp(() {
    store = _MemoryStore();
    engine = RicochetEngine(store: store, random: Random(1));
  });

  tearDown(() => engine.dispose());

  /// Runs the simulation at a fixed 60 Hz for up to [seconds], stopping early
  /// once [until] holds.
  void run(double seconds, {bool Function()? until}) {
    const step = 1 / 60;
    for (var t = 0.0; t < seconds; t += step) {
      engine.update(step);
      if (until != null && until()) return;
    }
  }

  test('starts a fresh run when there is nothing saved', () async {
    await engine.start();
    expect(engine.level, 1);
    expect(engine.score, 0);
    expect(engine.totalBalls, 1);
    expect(engine.mode, GameMode.aiming);
    expect(engine.bricks, isNotEmpty);
  });

  test('aim direction never points flatter than the minimum angle', () async {
    await engine.start();
    for (final target in [
      const Offset(0, Board.launchY),
      const Offset(Board.width, Board.launchY),
      const Offset(Board.width, Board.height),
      const Offset(0, Board.height),
    ]) {
      final direction = engine.aimDirection(target);
      expect(direction.dy, lessThan(0), reason: 'must always go upward');
      final angle = atan2(direction.dy, direction.dx);
      expect(angle, lessThanOrEqualTo(-RicochetTuning.minAngle + 1e-9));
      expect(angle, greaterThanOrEqualTo(-pi + RicochetTuning.minAngle - 1e-9));
    }
  });

  test('firing launches the volley and returns to aiming', () async {
    await engine.start();
    engine.usePower(PowerUp.balls);
    engine.fire(const Offset(0, -1));
    expect(engine.mode, GameMode.shooting);

    run(60, until: () => engine.mode == GameMode.aiming);
    expect(
      engine.mode,
      anyOf(GameMode.aiming, GameMode.between, GameMode.over),
      reason: 'a volley must always resolve',
    );
  });

  test('a volley damages the board', () async {
    await engine.start();
    engine.usePower(PowerUp.balls);
    final before = engine.bricks.fold<int>(0, (sum, b) => sum + b.hp);
    engine.fire(const Offset(0, -1));
    run(60, until: () => engine.mode != GameMode.shooting);
    final after = engine.bricks.fold<int>(0, (sum, b) => sum + b.hp);
    expect(after, lessThan(before));
  });

  test('balls never leave the board sideways', () async {
    await engine.start();
    engine.usePower(PowerUp.balls);
    engine.fire(engine.aimDirection(const Offset(0, 0)));
    var checks = 0;
    for (var i = 0; i < 3600 && engine.mode == GameMode.shooting; i++) {
      engine.update(1 / 60);
      for (final ball in engine.balls) {
        expect(ball.x, inInclusiveRange(0, Board.width));
        expect(ball.y, greaterThanOrEqualTo(0));
        checks++;
      }
    }
    expect(checks, greaterThan(0), reason: 'no balls were ever in flight');
  });

  test('power-ups bank the charges their tiles do', () async {
    await engine.start();
    engine.usePower(PowerUp.pierce);
    engine.usePower(PowerUp.pierce);
    engine.usePower(PowerUp.bomb);
    expect(engine.pendingPierce, 2);
    expect(engine.pendingBomb, 1);

    engine.fire(const Offset(0, -1));
    // Charges move into the volley on fire; the chips keep showing what is
    // still to be spent.
    expect(engine.pierceCharges, 0);
    expect(engine.pendingPierce, greaterThan(0));
  });

  test('+10 balls respects the stash ceiling', () async {
    await engine.start();
    for (var i = 0; i < 40; i++) {
      engine.usePower(PowerUp.balls);
    }
    expect(engine.totalBalls, RicochetTuning.maxBalls);
  });

  test('clear row wipes the lowest row and nothing far above it', () async {
    await engine.start();
    final lowestY = engine.bricks.map((b) => b.y).reduce(max);
    bool inLowestRow(double y) => (y - lowestY).abs() < 2;
    // A bomb caught in that row still explodes, so bricks just above it may go
    // too — but nothing outside a blast radius of the row may be touched.
    final untouchable = engine.bricks
        .where((b) => b.y < lowestY - RicochetTuning.explosionRadius)
        .map((b) => b.uid)
        .toSet();

    engine.usePower(PowerUp.clearRow);

    expect(engine.bricks.any((b) => inLowestRow(b.y)), isFalse);
    final survivors = engine.bricks.map((b) => b.uid).toSet();
    expect(survivors.containsAll(untouchable), isTrue);
  });

  test('an exploding bomb clears its neighbourhood', () async {
    await engine.start();
    final target = engine.bricks.first;
    final near = engine.bricks
        .where(
          (b) =>
              (Offset(b.centerX, b.centerY) -
                      Offset(target.centerX, target.centerY))
                  .distance <=
              RicochetTuning.explosionRadius,
        )
        .length;
    expect(near, greaterThan(1), reason: 'need neighbours to test the blast');
    final before = engine.bricks.length;
    engine.explodeAt(target.centerX, target.centerY);
    expect(engine.bricks.length, before - near);
  });

  test('progress survives a save and reload', () async {
    await engine.start();
    engine.usePower(PowerUp.balls);
    await engine.saveNow();

    final restored = RicochetEngine(store: store, random: Random(2));
    addTearDown(restored.dispose);
    await restored.start();

    expect(restored.level, engine.level);
    expect(restored.totalBalls, engine.totalBalls);
    expect(restored.bricks.length, engine.bricks.length);
    expect(restored.bricks.first.type, engine.bricks.first.type);
    expect(restored.bricks.first.hp, engine.bricks.first.hp);
  });

  test('a hand-edited save cannot spawn bricks past the danger line', () async {
    store.save = {
      'v': 1,
      'level': 4,
      'score': 10,
      'best': 10,
      'totalBalls': 5,
      'originX': Board.width / 2,
      'bricks': [
        {'x': 0, 'y': Board.dangerY.round(), 'hp': 3, 'mh': 3, 't': 'normal'},
        {'x': 0, 'y': 40, 'hp': 3, 'mh': 3, 't': 'normal'},
      ],
      'pk': const [],
    };
    await engine.start();
    expect(engine.bricks.length, 1);
    expect(engine.bricks.single.y, 40);
  });

  test('an unknown tile kind falls back to a plain brick', () async {
    store.save = {
      'v': 1,
      'level': 2,
      'score': 0,
      'best': 0,
      'totalBalls': 1,
      'originX': Board.width / 2,
      'bricks': [
        {'x': 0, 'y': 40, 'hp': 3, 'mh': 3, 't': 'teleporter'},
      ],
      'pk': const [],
    };
    await engine.start();
    expect(engine.bricks.single.type, TileType.normal);
  });

  test('starting over discards the saved run', () async {
    await engine.start();
    engine.usePower(PowerUp.balls);
    await engine.saveNow();
    expect(store.save, isNotNull);

    await engine.resetGame();
    expect(store.save, isNull);
    expect(engine.level, 1);
    expect(engine.totalBalls, 1);
  });

  test('retry restores the board the level began with', () async {
    await engine.start();
    final startingBricks = engine.bricks.length;
    engine.usePower(PowerUp.clearRow);
    expect(engine.bricks.length, lessThan(startingBricks));

    await engine.retryLevel();
    expect(engine.bricks.length, startingBricks);
    expect(engine.mode, GameMode.aiming);
  });

  test('the best score is persisted as soon as it is beaten', () async {
    await engine.start();
    engine.usePower(PowerUp.clearRow);
    expect(engine.score, greaterThan(0));
    expect(store.best, engine.score);
  });
}
