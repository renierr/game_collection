import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_collection/games/ricochet/engine/geometry.dart';
import 'package:game_collection/games/ricochet/engine/level_generator.dart';
import 'package:game_collection/games/ricochet/engine/stencils.dart';

void main() {
  LevelGenerator generatorFor(int seed) {
    var uid = 0;
    return LevelGenerator(() => uid++, random: Random(seed));
  }

  /// Boards are seeded per level, so a handful of levels across many seeds is
  /// what actually exercises the unlock thresholds and the stacking rule.
  Iterable<LevelLayout> sample({
    int seeds = 40,
    List<int> levels = const [1, 5, 9, 15, 30],
  }) sync* {
    for (var seed = 0; seed < seeds; seed++) {
      final generator = generatorFor(seed);
      for (final level in levels) {
        yield generator.generate(level);
      }
    }
  }

  test('every tile lands inside the grid', () {
    for (final layout in sample()) {
      for (final brick in layout.bricks) {
        expect(brick.x, greaterThanOrEqualTo(0));
        expect(brick.x + brick.width, lessThanOrEqualTo(Board.width + 0.001));
      }
    }
  });

  test('no tile spawns inside the launch area', () {
    for (final layout in sample()) {
      for (final brick in layout.bricks) {
        expect(brick.y + brick.height, lessThan(Board.dangerY));
      }
    }
  });

  test('at least one row is always visible', () {
    for (final layout in sample()) {
      final visible =
          layout.bricks.where((b) => b.y >= 0).length + layout.pickups.length;
      expect(visible, greaterThan(0));
    }
  });

  test('boards carry at most three pickups', () {
    var withPickups = 0;
    var total = 0;
    for (final layout in sample()) {
      total++;
      // A stencil made entirely of shaped tiles (the funnel) leaves no plain
      // brick to convert, so a pickup-free board is legal — just rare.
      expect(layout.pickups.length, lessThanOrEqualTo(3));
      if (layout.pickups.isNotEmpty) withPickups++;
    }
    expect(withPickups / total, greaterThan(0.9));
  });

  test('rare seeding keeps every exotic kind in circulation', () {
    // The point of the seeding pass: without it ramps and orbs would each live
    // in one stencil and almost never be drawn.
    for (final seed in rareMix) {
      final boards = sample(seeds: 60, levels: [seed.from + 5]);
      final withKind = boards
          .where(
            (layout) => layout.bricks.any(
              (b) => seed.type.isRamp ? b.type.isRamp : b.type == seed.type,
            ),
          )
          .length;
      expect(
        withKind,
        greaterThan(15),
        reason: '${seed.type.name} barely appears above its unlock level',
      );
    }
  });

  test('brick hp scales with the level', () {
    int averageHp(int level) {
      var total = 0;
      var count = 0;
      for (var seed = 0; seed < 30; seed++) {
        for (final brick in generatorFor(seed).generate(level).bricks) {
          total += brick.maxHp;
          count++;
        }
      }
      return total ~/ count;
    }

    expect(averageHp(20), greaterThan(averageHp(5)));
    expect(averageHp(5), greaterThan(averageHp(1)));
  });

  test('the same seed reproduces the same board', () {
    final a = generatorFor(7).generate(12);
    final b = generatorFor(7).generate(12);
    expect(a.bricks.length, b.bricks.length);
    for (var i = 0; i < a.bricks.length; i++) {
      expect(a.bricks[i].x, b.bricks[i].x);
      expect(a.bricks[i].y, b.bricks[i].y);
      expect(a.bricks[i].type, b.bricks[i].type);
      expect(a.bricks[i].hp, b.bricks[i].hp);
    }
  });

  test('stencils are all 13 columns wide or narrower', () {
    for (final stencil in stencils) {
      for (final row in stencil) {
        expect(row.length, lessThanOrEqualTo(Board.columns));
        expect(row.length, stencil.first.length);
      }
    }
  });

  test('stencil characters are all recognized', () {
    for (final stencil in stencils) {
      for (final row in stencil) {
        for (final ch in row.split('')) {
          if (ch == '#' || ch == '.') continue;
          expect(
            stencilChars.containsKey(ch),
            isTrue,
            reason: 'unknown stencil character "$ch"',
          );
        }
      }
    }
  });
}
