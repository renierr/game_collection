import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:game_collection/games/minesweeper/engine/minesweeper_engine.dart';
import 'package:game_collection/games/minesweeper/engine/minesweeper_store.dart';

class _MemoryStore implements MinesweeperStore {
  Map<String, dynamic>? save;
  final Map<String, int> best = {};

  @override
  Future<Map<String, int>> loadBestTimes() async => best;

  @override
  Future<void> saveBestTime(String levelId, int seconds) async =>
      best[levelId] = seconds;

  @override
  Future<Map<String, dynamic>?> loadSave() async => save;

  @override
  Future<void> writeSave(Map<String, dynamic> data) async => save = data;

  @override
  Future<void> clearSave() async => save = null;
}

Future<MinesweeperEngine> _engine({
  _MemoryStore? store,
  int seed = 11,
  MineLevel level = MineLevel.beginner,
}) async {
  final engine = MinesweeperEngine(
    store: store ?? _MemoryStore(),
    random: math.Random(seed),
  );
  await engine.start();
  if (level != engine.level) engine.newGame(level);
  return engine;
}

/// Uncovers every square that is not a mine, which is exactly what a solved
/// board looks like.
void _clearEverySafeSquare(MinesweeperEngine engine) {
  // The first reveal places the mines, so a safe starting square is only known
  // after it. Reveal once, then sweep.
  engine.reveal(0);
  for (var i = 0; i < engine.cells.length; i++) {
    if (!engine.cells[i].mine) engine.reveal(i);
  }
}

void main() {
  test('a fresh board is fully covered and has no mines yet', () async {
    final engine = await _engine();

    expect(engine.cells.length, MineLevel.beginner.cells);
    expect(engine.cells.every((c) => c.state == CellState.hidden), isTrue);
    // Mines are placed on the first click, not at deal time.
    expect(engine.cells.where((c) => c.mine), isEmpty);
    expect(engine.flagsLeft, MineLevel.beginner.mines);
    expect(engine.elapsedSeconds, 0);
    expect(engine.isOver, isFalse);
  });

  test('the first click is safe and opens a region', () async {
    // Every seed: the guarantee is structural, not lucky.
    for (var seed = 0; seed < 25; seed++) {
      final engine = await _engine(seed: seed);
      final middle = engine.index(4, 4);
      engine.reveal(middle);

      expect(engine.cells[middle].mine, isFalse);
      expect(engine.cells[middle].state, CellState.revealed);
      expect(engine.outcome, MineOutcome.playing);
      // The clicked square's neighbours are kept clear too, so the first click
      // opens a patch rather than a bare number.
      expect(engine.revealedCount, greaterThan(1));
    }
  });

  test('the mine count matches the level', () async {
    for (final level in MineLevel.values) {
      final engine = await _engine(level: level);
      engine.reveal(engine.index(1, 1));
      expect(engine.cells.where((c) => c.mine).length, level.mines);
    }
  });

  test('flags toggle and are counted', () async {
    final engine = await _engine();
    final at = engine.index(0, 0);

    engine.toggleFlag(at);
    expect(engine.cells[at].state, CellState.flagged);
    expect(engine.flagsLeft, MineLevel.beginner.mines - 1);

    engine.toggleFlag(at);
    expect(engine.cells[at].state, CellState.hidden);
    expect(engine.flagsLeft, MineLevel.beginner.mines);
  });

  test('a flagged square cannot be uncovered by a plain reveal', () async {
    final engine = await _engine();
    final at = engine.index(3, 3);

    engine.toggleFlag(at);
    engine.reveal(at);
    expect(engine.cells[at].state, CellState.flagged);
  });

  test('uncovering a mine loses and shows the whole field', () async {
    final engine = await _engine();
    engine.reveal(engine.index(0, 0));

    final mine = engine.cells.indexWhere((c) => c.mine);
    engine.reveal(mine);

    expect(engine.outcome, MineOutcome.lost);
    expect(engine.isOver, isTrue);
    expect(engine.cells[mine].exploded, isTrue);
    // Every unflagged mine is shown, so the player can see what they missed.
    for (final cell in engine.cells) {
      if (cell.mine) {
        expect(cell.state, anyOf(CellState.revealed, CellState.flagged));
      }
    }
  });

  test('a lost game accepts no further moves', () async {
    final engine = await _engine();
    engine.reveal(engine.index(0, 0));
    engine.reveal(engine.cells.indexWhere((c) => c.mine));

    final revealed = engine.revealedCount;
    final safe = engine.cells.indexWhere(
      (c) => !c.mine && c.state == CellState.hidden,
    );
    if (safe >= 0) {
      engine.reveal(safe);
      expect(engine.revealedCount, revealed);
    }
  });

  test('chording a satisfied number clears its neighbours', () async {
    final engine = await _engine(seed: 3);
    engine.reveal(engine.index(4, 4));

    // Find an uncovered number whose mines are all correctly flagged, flag
    // them, then chord it.
    for (var at = 0; at < engine.cells.length; at++) {
      final cell = engine.cells[at];
      if (cell.state != CellState.revealed || cell.neighbours == 0) continue;

      final x = at % engine.level.columns;
      final y = at ~/ engine.level.columns;
      final neighbours = <int>[];
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 ||
              ny < 0 ||
              nx >= engine.level.columns ||
              ny >= engine.level.rows) {
            continue;
          }
          neighbours.add(ny * engine.level.columns + nx);
        }
      }
      final hidden = neighbours
          .where((i) => engine.cells[i].state == CellState.hidden)
          .toList();
      if (hidden.where((i) => engine.cells[i].mine).length != cell.neighbours) {
        continue;
      }
      if (hidden.any((i) => !engine.cells[i].mine) == false) continue;

      for (final i in hidden.where((i) => engine.cells[i].mine)) {
        engine.toggleFlag(i);
      }
      final before = engine.revealedCount;
      engine.chord(at);

      expect(engine.outcome, MineOutcome.playing);
      expect(engine.revealedCount, greaterThan(before));
      return;
    }
    fail('no chordable number appeared on the board');
  });

  test('chording an unsatisfied number does nothing', () async {
    final engine = await _engine(seed: 3);
    engine.reveal(engine.index(4, 4));

    final numbered = engine.cells.indexWhere(
      (c) => c.state == CellState.revealed && c.neighbours > 0,
    );
    expect(numbered, greaterThanOrEqualTo(0));

    final before = engine.revealedCount;
    engine.chord(numbered);
    expect(engine.revealedCount, before);
    expect(engine.outcome, MineOutcome.playing);
  });

  test('clearing every safe square wins and flags the mines', () async {
    final store = _MemoryStore();
    final engine = await _engine(store: store);
    _clearEverySafeSquare(engine);

    expect(engine.outcome, MineOutcome.won);
    expect(engine.flagsLeft, 0);
    for (final cell in engine.cells) {
      expect(cell.state, cell.mine ? CellState.flagged : CellState.revealed);
    }
  });

  test('a win records a best time, and a slower one does not', () async {
    final store = _MemoryStore();
    final engine = await _engine(store: store);
    engine.reveal(0);
    for (var i = 0; i < 5; i++) {
      engine.tickClock();
    }
    _clearEverySafeSquare(engine);
    expect(engine.outcome, MineOutcome.won);
    expect(store.best[MineLevel.beginner.id], 5);
    expect(engine.isRecord, isTrue);

    // A second, slower solve must not overwrite the record.
    final slower = MinesweeperEngine(store: store, random: math.Random(12));
    await slower.start();
    slower.reveal(0);
    for (var i = 0; i < 40; i++) {
      slower.tickClock();
    }
    _clearEverySafeSquare(slower);
    expect(slower.outcome, MineOutcome.won);
    expect(store.best[MineLevel.beginner.id], 5);
  });

  test('the clock only runs once the first square is uncovered', () async {
    final engine = await _engine();
    engine.tickClock();
    engine.tickClock();
    expect(engine.elapsedSeconds, 0);

    engine.reveal(engine.index(4, 4));
    engine.tickClock();
    expect(engine.elapsedSeconds, 1);
  });

  test('switching level deals a new board of that size', () async {
    final engine = await _engine();
    engine.newGame(MineLevel.expert);

    expect(engine.level, MineLevel.expert);
    expect(engine.cells.length, MineLevel.expert.cells);
    expect(engine.flagsLeft, MineLevel.expert.mines);
    expect(engine.elapsedSeconds, 0);
  });

  group('a hand-edited save is rejected rather than trusted', () {
    Future<MinesweeperEngine> engineForSave(Map<String, dynamic> save) async {
      final store = _MemoryStore()..save = save;
      final engine = MinesweeperEngine(store: store, random: math.Random(2));
      await engine.start();
      return engine;
    }

    test('an unknown level', () async {
      final engine = await engineForSave({'level': 'godmode', 'mines': []});
      expect(engine.level, MineLevel.beginner);
      expect(engine.cells.where((c) => c.mine), isEmpty);
    });

    test('a cell index off the board', () async {
      final engine = await engineForSave({
        'level': 'beginner',
        'seeded': true,
        'mines': [9999],
      });
      expect(engine.cells.where((c) => c.mine), isEmpty);
    });

    test('a mine count that does not match the level', () async {
      final engine = await engineForSave({
        'level': 'beginner',
        'seeded': true,
        'mines': [0, 1, 2],
      });
      expect(engine.cells.where((c) => c.mine), isEmpty);
    });

    test('a revealed square that is also a mine', () async {
      final engine = await engineForSave({
        'level': 'beginner',
        'seeded': true,
        'mines': List<int>.generate(10, (i) => i),
        'revealed': [0],
      });
      expect(engine.cells.where((c) => c.mine), isEmpty);
    });

    test('a legal save is restored', () async {
      final engine = await engineForSave({
        'level': 'intermediate',
        'seeded': true,
        'seconds': 42,
        'mines': List<int>.generate(40, (i) => i),
        'revealed': [200, 201],
        'flagged': [0],
      });

      expect(engine.level, MineLevel.intermediate);
      expect(engine.elapsedSeconds, 42);
      expect(engine.cells.where((c) => c.mine).length, 40);
      expect(engine.cells[200].state, CellState.revealed);
      expect(engine.cells[0].state, CellState.flagged);
      // Neighbour counts are recomputed rather than stored, so they cannot be
      // faked by a hand edit.
      expect(engine.cells[41].neighbours, greaterThan(0));
    });
  });
}
