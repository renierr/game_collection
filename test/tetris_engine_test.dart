import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:game_collection/games/tetris/engine/tetris_engine.dart';
import 'package:game_collection/games/tetris/engine/tetris_store.dart';
import 'package:game_collection/games/tetris/engine/tetromino.dart';

class _MemoryStore implements TetrisStore {
  Map<String, dynamic>? save;
  int best = 0;

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
}

/// A save blob for a board built by [fill], which is asked for the kind in each
/// cell. Crafting the stack directly is the only way to test row clears and
/// wall kicks against a known board.
Map<String, dynamic> _save({
  TetrominoKind? Function(int x, int y)? fill,
  Map<String, dynamic>? active,
  int score = 0,
  int lines = 0,
}) => {
  'score': score,
  'lines': lines,
  'combo': 0,
  'pieces': 0,
  'queue': [for (final kind in TetrominoKind.values) kind.index],
  'cells': [
    for (var y = 0; y < TetrisField.rows; y++)
      for (var x = 0; x < TetrisField.columns; x++)
        fill?.call(x, y)?.index ?? -1,
  ],
  'active': ?active,
};

Future<TetrisEngine> _engineWith(
  Map<String, dynamic> save, {
  _MemoryStore? store,
}) async {
  final memory = store ?? _MemoryStore();
  memory.save = save;
  final engine = TetrisEngine(store: memory, random: math.Random(9));
  await engine.start();
  return engine;
}

Future<TetrisEngine> _freshEngine({int seed = 9}) async {
  final engine = TetrisEngine(store: _MemoryStore(), random: math.Random(seed));
  await engine.start();
  return engine;
}

void main() {
  group('tetromino geometry', () {
    test('every rotation of every piece has four cells', () {
      for (final kind in TetrominoKind.values) {
        for (var rotation = 0; rotation < 4; rotation++) {
          expect(kind.cellsAt(rotation).length, 4, reason: '$kind@$rotation');
        }
      }
    });

    test('four turns return a piece to its spawn shape', () {
      for (final kind in TetrominoKind.values) {
        expect(
          kind.cellsAt(4).toSet(),
          kind.cellsAt(0).toSet(),
          reason: '$kind',
        );
      }
    });

    test('O never changes shape', () {
      for (var rotation = 0; rotation < 4; rotation++) {
        expect(
          TetrominoKind.o.cellsAt(rotation).toSet(),
          TetrominoKind.o.spawnCells.toSet(),
        );
      }
    });

    test('every cell stays inside the rotation box', () {
      for (final kind in TetrominoKind.values) {
        for (var rotation = 0; rotation < 4; rotation++) {
          for (final (x, y) in kind.cellsAt(rotation)) {
            expect(x, inInclusiveRange(0, kind.box - 1));
            expect(y, inInclusiveRange(0, kind.box - 1));
          }
        }
      }
    });

    test('the first kick offset is always the plain rotation', () {
      for (final kind in TetrominoKind.values) {
        for (var from = 0; from < 4; from++) {
          for (final clockwise in [true, false]) {
            final kicks = WallKicks.forRotation(
              kind: kind,
              from: from,
              clockwise: clockwise,
            );
            expect(kicks.first, (0, 0));
          }
        }
      }
    });

    test('an unknown piece index is rejected', () {
      expect(TetrominoKind.byIndex(-1), isNull);
      expect(TetrominoKind.byIndex(99), isNull);
      expect(TetrominoKind.byIndex(0), TetrominoKind.i);
    });
  });

  test('a fresh game has a piece, a preview and no score', () async {
    final engine = await _freshEngine();

    expect(engine.active, isNotNull);
    expect(engine.preview.length, TetrisTuning.previewCount);
    expect(engine.hold, isNull);
    expect(engine.score, 0);
    expect(engine.lines, 0);
    expect(engine.level, 1);
    expect(engine.isOver, isFalse);
  });

  test('the bag delivers all seven kinds before any repeats', () async {
    final engine = await _freshEngine();
    final seen = <TetrominoKind>[];

    for (var i = 0; i < 7; i++) {
      seen.add(engine.active!.kind);
      engine.hardDrop();
      // No row can complete from seven pieces dropped down the middle, so each
      // lock spawns the next piece directly.
      expect(engine.phase, TetrisPhase.falling);
    }
    expect(seen.toSet().length, 7);
  });

  test('a piece cannot be moved through a wall', () async {
    final engine = await _freshEngine();

    var moved = 0;
    while (engine.moveLeft()) {
      moved++;
      expect(moved, lessThan(20), reason: 'moveLeft never stopped');
    }
    for (final (x, _) in engine.active!.cells()) {
      expect(x, greaterThanOrEqualTo(0));
    }

    moved = 0;
    while (engine.moveRight()) {
      moved++;
      expect(moved, lessThan(20), reason: 'moveRight never stopped');
    }
    for (final (x, _) in engine.active!.cells()) {
      expect(x, lessThan(TetrisField.columns));
    }
  });

  test('gravity drops the piece one row at a time', () async {
    final engine = await _freshEngine();
    final startY = engine.active!.y;

    engine.update(engine.fallInterval + 1e-6);
    expect(engine.active!.y, startY + 1);
  });

  test('a hard drop scores two a row and locks immediately', () async {
    final engine = await _freshEngine();
    final distance = engine.ghostDrop;
    expect(distance, greaterThan(0));

    engine.hardDrop();
    expect(engine.score, distance * TetrisTuning.hardDropPoints);
    expect(engine.pieces, 1);
    // A new piece is already in play rather than the board sitting empty.
    expect(engine.active, isNotNull);
    expect(engine.active!.y, TetrisField.spawnY);
  });

  test('a soft drop scores one a row', () async {
    final engine = await _freshEngine();
    engine.softDrop();
    expect(engine.score, TetrisTuning.softDropPoints);
  });

  test('a piece rests before it locks, so it can still be moved', () async {
    final engine = await _freshEngine();
    // Drop it to the floor without locking.
    while (engine.ghostDrop > 0) {
      engine.softDrop();
    }
    final y = engine.active!.y;

    // Less than the lock delay: still the same piece, still movable.
    engine.update(TetrisTuning.lockDelay * 0.5);
    expect(engine.active!.y, y);
    expect(engine.pieces, 0);

    engine.update(TetrisTuning.lockDelay);
    expect(engine.pieces, 1);
  });

  test('a completed row clears, scores and counts a line', () async {
    // Row 21 is filled except column 0; a vertical I dropped into that column
    // completes it. The I's box sits at x = -2 so its cells land on column 0.
    final engine = await _engineWith(
      _save(
        fill: (x, y) =>
            y == TetrisField.rows - 1 && x > 0 ? TetrominoKind.z : null,
        active: {'kind': TetrominoKind.i.index, 'rotation': 1, 'x': -2, 'y': 0},
      ),
    );

    expect(engine.active!.kind, TetrominoKind.i);
    final drop = engine.ghostDrop;
    engine.hardDrop();

    // The clear flashes before it resolves, so the player sees which row went.
    expect(engine.phase, TetrisPhase.clearing);
    expect(engine.clearingRows, [TetrisField.rows - 1]);
    expect(engine.lines, 0);

    engine.update(TetrisTuning.clearFlashSeconds + 1e-6);
    expect(engine.phase, TetrisPhase.falling);
    expect(engine.lines, 1);
    expect(
      engine.score,
      drop * TetrisTuning.hardDropPoints + TetrisTuning.lineScores[1],
    );
    // The bottom row is now what was above it: empty except the I's leftovers.
    expect(engine.cells.where((c) => c != null).length, 3);
  });

  test('four rows at once score far more than four singles', () async {
    // The whole reason to build a well rather than clear as you go.
    expect(
      TetrisTuning.lineScores[4],
      greaterThan(4 * TetrisTuning.lineScores[1]),
    );
  });

  test('a vertical I kicks off the left wall instead of failing', () async {
    final engine = await _engineWith(
      _save(
        active: {'kind': TetrominoKind.i.index, 'rotation': 1, 'x': -2, 'y': 5},
      ),
    );
    expect(engine.active!.x, -2);

    // The plain rotation would put two cells outside the board; the SRS table's
    // second offset shifts it back in.
    expect(engine.rotate(clockwise: false), isTrue);
    expect(engine.active!.rotation, 0);
    for (final (x, _) in engine.active!.cells()) {
      expect(x, inInclusiveRange(0, TetrisField.columns - 1));
    }
  });

  test('a rotation with nowhere to go is refused', () async {
    // A horizontal I sealed inside a one-row pocket. Every kick offset needs
    // either a second row or a column outside the pocket, so all five fail —
    // note that a pocket open at the top would not prove this, because SRS is
    // allowed to kick a piece upwards out of the board.
    const gapRow = 10;
    final engine = await _engineWith(
      _save(
        fill: (x, y) =>
            y == gapRow && x >= 3 && x <= 6 ? null : TetrominoKind.z,
        active: {
          'kind': TetrominoKind.i.index,
          'rotation': 0,
          'x': 3,
          'y': gapRow - 1,
        },
      ),
    );

    expect(engine.active!.kind, TetrominoKind.i);
    expect(engine.rotate(clockwise: true), isFalse);
    expect(engine.rotate(clockwise: false), isFalse);
    expect(engine.active!.rotation, 0);
  });

  test('hold banks a piece, and only once per piece', () async {
    final engine = await _freshEngine();
    final first = engine.active!.kind;

    engine.holdPiece();
    expect(engine.hold, first);
    expect(engine.holdUsed, isTrue);
    expect(engine.active, isNotNull);

    final second = engine.active!.kind;
    engine.holdPiece();
    expect(engine.hold, first, reason: 'hold must be spent for this piece');
    expect(engine.active!.kind, second);
  });

  test('hold swaps back on the next piece', () async {
    final engine = await _freshEngine();
    final first = engine.active!.kind;
    engine.holdPiece();
    final second = engine.active!.kind;

    engine.hardDrop();
    expect(engine.holdUsed, isFalse);

    engine.holdPiece();
    expect(engine.hold, isNot(first));
    expect(engine.active!.kind, first);
    expect(second, isNotNull);
  });

  test('pausing stops gravity', () async {
    final engine = await _freshEngine();
    engine.togglePause();
    final y = engine.active!.y;

    engine.update(1);
    expect(engine.active!.y, y);

    engine.togglePause();
    engine.update(engine.fallInterval + 1e-6);
    expect(engine.active!.y, y + 1);
  });

  test('a paused game refuses moves', () async {
    final engine = await _freshEngine();
    engine.togglePause();

    expect(engine.moveLeft(), isFalse);
    expect(engine.rotate(clockwise: true), isFalse);
    expect(engine.softDrop(), isFalse);
  });

  test('the level and the fall speed climb with cleared lines', () async {
    final slow = await _freshEngine();
    final startInterval = slow.fallInterval;

    final fast = await _engineWith(_save(lines: 90));
    expect(fast.level, 10);
    expect(fast.fallInterval, lessThan(startInterval));
    // The curve is bounded, so a very high level cannot reach zero.
    expect(
      fast.fallInterval,
      greaterThanOrEqualTo(TetrisTuning.minFallInterval),
    );
  });

  test('a blocked spawn ends the game', () async {
    // Columns 3-6 filled to the very top, which is where a piece spawns.
    final store = _MemoryStore();
    final engine = await _engineWith(
      _save(fill: (x, y) => x >= 3 && x <= 6 ? TetrominoKind.z : null),
      store: store,
    );

    expect(engine.isOver, isTrue);
    expect(engine.phase, TetrisPhase.over);
    // A finished run leaves no save to resume into.
    expect(store.save, isNull);
  });

  test('a new game clears the board and the score', () async {
    final engine = await _freshEngine();
    engine.hardDrop();
    engine.hardDrop();
    expect(engine.score, greaterThan(0));

    engine.newGame();
    expect(engine.score, 0);
    expect(engine.pieces, 0);
    expect(engine.lines, 0);
    expect(engine.cells.where((c) => c != null), isEmpty);
    expect(engine.active, isNotNull);
  });

  test('a best score is banked and reloaded', () async {
    final store = _MemoryStore();
    final engine = await _engineWith(
      _save(
        fill: (x, y) => x >= 3 && x <= 6 ? TetrominoKind.z : null,
        score: 500,
      ),
      store: store,
    );
    expect(engine.isOver, isTrue);
    expect(store.best, 500);

    final next = TetrisEngine(store: store, random: math.Random(1));
    await next.start();
    expect(next.best, 500);
  });

  group('a hand-edited save is rejected rather than trusted', () {
    Future<TetrisEngine> engineForSave(Map<String, dynamic> save) async {
      final store = _MemoryStore()..save = save;
      final engine = TetrisEngine(store: store, random: math.Random(6));
      await engine.start();
      return engine;
    }

    test('a wrong-sized board', () async {
      final engine = await engineForSave({
        'queue': [0],
        'cells': [1, 2, 3],
      });
      expect(engine.cells.where((c) => c != null), isEmpty);
      expect(engine.score, 0);
    });

    test('an unknown piece index on the board', () async {
      final save = _save();
      (save['cells'] as List)[0] = 42;
      final engine = await engineForSave(save);
      expect(engine.cells.where((c) => c != null), isEmpty);
    });

    test('an active piece buried in the stack', () async {
      final engine = await engineForSave(
        _save(
          fill: (x, y) => TetrominoKind.z,
          active: {
            'kind': TetrominoKind.o.index,
            'rotation': 0,
            'x': 4,
            'y': 10,
          },
          score: 777,
        ),
      );
      // Rejected wholesale: a fresh board, and none of the claimed score.
      expect(engine.score, 0);
      expect(engine.cells.where((c) => c != null), isEmpty);
    });

    test('a rotation outside 0..3', () async {
      final engine = await engineForSave(
        _save(
          active: {
            'kind': TetrominoKind.t.index,
            'rotation': 9,
            'x': 3,
            'y': 0,
          },
          score: 55,
        ),
      );
      expect(engine.score, 0);
    });

    test('a legal save is restored', () async {
      final engine = await engineForSave(
        _save(
          fill: (x, y) =>
              y == TetrisField.rows - 1 && x < 4 ? TetrominoKind.s : null,
          active: {
            'kind': TetrominoKind.t.index,
            'rotation': 2,
            'x': 3,
            'y': 4,
          },
          score: 1234,
          lines: 12,
        ),
      );

      expect(engine.score, 1234);
      expect(engine.lines, 12);
      expect(engine.level, 2);
      expect(engine.active!.kind, TetrominoKind.t);
      expect(engine.active!.rotation, 2);
      expect(engine.cells.where((c) => c != null).length, 4);
    });
  });
}
