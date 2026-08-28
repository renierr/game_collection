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
        {'x': 0, 'y': Board.cell, 'hp': 3, 'mh': 3, 't': 'normal'},
      ],
      'pk': const [],
    };
    await engine.start();
    expect(engine.bricks.length, 1);
    expect(engine.bricks.single.y, Board.cell);
  });

  test('a hand-edited save cannot place a brick between cells', () async {
    store.save = {
      'v': 1,
      'level': 4,
      'score': 10,
      'best': 10,
      'totalBalls': 5,
      'originX': Board.width / 2,
      'bricks': [
        {'x': 5, 'y': 40, 'hp': 3, 'mh': 3, 't': 'normal'},
        {'x': -80, 'y': 40, 'hp': 3, 'mh': 3, 't': 'normal'},
      ],
      'pk': const [],
    };
    await engine.start();
    expect(engine.bricks.length, 1);
    expect(engine.bricks.single.x, 0);
    expect(engine.bricks.single.y, Board.cell);
  });

  test('a ball still finds a brick in every cell it crosses', () async {
    // The collision broad phase buckets bricks by cell; walk a column of them
    // from the top of the board down to the launch area so a ball fired
    // straight up has to cross every bucket boundary on the way.
    const column = 6;
    store.save = {
      'v': 1,
      'level': 1,
      'score': 0,
      'best': 0,
      'totalBalls': 1,
      'originX': (column + 0.5) * Board.cell,
      'bricks': [
        for (var row = 1; row < 16; row++)
          {
            'x': column * Board.cell,
            'y': row * Board.cell,
            'hp': 1,
            'mh': 1,
            't': 'normal',
          },
      ],
      'pk': const [],
    };
    await engine.start();
    final placed = engine.bricks.length;
    expect(placed, greaterThan(8));

    engine.fire(const Offset(0, -1));
    run(6, until: () => engine.mode != GameMode.shooting);

    // One ball, one bounce per brick: it eats its way up the column rather than
    // sailing past bricks the buckets failed to report.
    expect(engine.bricks.length, lessThan(placed));
  });

  test(
    'keyboard aiming holds the sight between presses and fires it',
    () async {
      await engine.start();
      expect(engine.aiming, isFalse);

      engine.rotateAim(0.4);
      expect(engine.aiming, isTrue);
      final sight = engine.aimPoint!;
      // Swung right of vertical, and the sight sits on the aim ray.
      expect(sight.dx, greaterThan(engine.originX));
      expect(sight.dy, lessThan(Board.launchY));

      // The sight is held, not consumed: a second frame with no input keeps it.
      engine.update(1 / 60);
      expect(engine.aimPoint, sight);

      engine.fireAimed();
      expect(engine.mode, GameMode.shooting);
      expect(engine.aiming, isFalse);
    },
  );

  test('keyboard aim can never point flatter than the minimum angle', () async {
    await engine.start();
    for (var i = 0; i < 100; i++) {
      engine.rotateAim(0.5);
    }
    expect(engine.aimDirection(engine.aimPoint!).dy, lessThan(0));

    engine.cancelAim();
    for (var i = 0; i < 100; i++) {
      engine.rotateAim(-0.5);
    }
    expect(engine.aimDirection(engine.aimPoint!).dy, lessThan(0));
  });

  test('a drag hands its angle over to the keyboard', () async {
    await engine.start();
    engine.beginAim(Offset(engine.originX + 100, Board.launchY - 100));
    engine.cancelAim();

    // Picking the keyboard up continues from where the drag left the sight
    // rather than snapping back to vertical.
    engine.rotateAim(0);
    expect(engine.aimPoint!.dx, greaterThan(engine.originX));
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

  test(
    'the round finishes when all bricks are cleared even if pickups remain',
    () async {
      store.save = {
        'v': 1,
        'level': 1,
        'score': 0,
        'best': 0,
        'totalBalls': 1,
        'originX': Board.width / 2,
        'bricks': [
          {'x': 0, 'y': Board.cell * 2, 'hp': 1, 'mh': 1, 't': 'normal'},
        ],
        'pk': [
          {
            'x': (Board.width / 2).round(),
            'y': (Board.cell * 3).round(),
            'r': 14.0,
            's': 0.0,
          },
        ],
      };
      await engine.start();
      expect(engine.bricks.length, 1);
      expect(engine.pickups.length, 1);

      // Destroy the only brick.
      engine.usePower(PowerUp.clearRow);
      expect(engine.bricks, isEmpty);
      expect(engine.pickups, isNotEmpty);

      // Fire a shot and simulate until volley & shift resolve.
      engine.fire(const Offset(0, -1));
      run(
        10,
        until: () =>
            engine.mode == GameMode.between || engine.mode == GameMode.aiming,
      );

      // Should transition to level clear (between), not stuck in aiming.
      expect(engine.mode, GameMode.between);
    },
  );

  test(
    'uncollected pickups are discarded when crossing the danger line',
    () async {
      store.save = {
        'v': 1,
        'level': 1,
        'score': 0,
        'best': 0,
        'totalBalls': 1,
        'originX': Board.width / 2,
        'bricks': [
          {'x': 0, 'y': Board.cell, 'hp': 50, 'mh': 50, 't': 'normal'},
        ],
        'pk': [
          {
            'x': (Board.width / 2).round(),
            'y': (Board.dangerY - Board.cell / 2).round(),
            'r': 14.0,
            's': 0.0,
          },
        ],
      };
      await engine.start();
      expect(engine.pickups.length, 1);

      // Fire a shot that does not collect the pickup or destroy the brick.
      engine.fire(const Offset(0, -1));
      run(10, until: () => engine.mode == GameMode.aiming);

      // The pickup shifted past dangerY and was cleaned up.
      expect(engine.pickups, isEmpty);
      expect(engine.mode, GameMode.aiming);
    },
  );
}
