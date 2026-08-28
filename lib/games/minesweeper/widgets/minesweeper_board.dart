import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/minesweeper_engine.dart';
import 'minesweeper_board_painter.dart';

/// The playfield plus its input.
///
/// Three gestures mean three different moves, and they have to work on both a
/// mouse and a finger:
/// * tap on a covered square — uncover it, or plant a flag while [flagMode] is
///   on;
/// * tap on an uncovered number — clear its neighbours, if it is satisfied;
/// * long-press, or right-click — toggle a flag.
///
/// Pointer positions are mapped back through the same fit the painter uses, so
/// a tap lands on the square under the finger at every scale and zoom level.
class MinesweeperBoard extends StatelessWidget {
  final MinesweeperEngine engine;

  /// While on, a plain tap flags instead of uncovering. A phone has no right
  /// button, and long-pressing every square in a minefield is exhausting.
  final bool flagMode;

  final double cascadeMs;
  final int cascadeBatch;

  const MinesweeperBoard({
    super.key,
    required this.engine,
    required this.flagMode,
    required this.cascadeMs,
    required this.cascadeBatch,
  });

  int _cellAt(Offset local, Size size) {
    final level = engine.level;
    final scale = math.min(
      size.width / level.columns,
      size.height / level.rows,
    );
    if (scale <= 0) return -1;
    final x = (local.dx - (size.width - level.columns * scale) / 2) / scale;
    final y = (local.dy - (size.height - level.rows * scale) / 2) / scale;
    if (x < 0 || y < 0 || x >= level.columns || y >= level.rows) return -1;
    final at = y.floor() * level.columns + x.floor();
    // The page builds before the engine has finished loading its board, so a
    // tap in those first frames must find nothing rather than index an empty
    // list.
    return at < engine.cells.length ? at : -1;
  }

  void _primary(Offset local, Size size) {
    final at = _cellAt(local, size);
    if (at < 0) return;
    if (flagMode) {
      engine.toggleFlag(at);
      return;
    }
    if (engine.cells[at].state == CellState.revealed) {
      engine.chord(at);
    } else {
      engine.reveal(at);
    }
  }

  void _secondary(Offset local, Size size) {
    final at = _cellAt(local, size);
    if (at >= 0) engine.toggleFlag(at);
  }

  @override
  Widget build(BuildContext context) {
    final level = engine.level;
    return AspectRatio(
      aspectRatio: level.columns / level.rows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _primary(details.localPosition, size),
            onLongPressStart: (details) =>
                _secondary(details.localPosition, size),
            onSecondaryTapUp: (details) =>
                _secondary(details.localPosition, size),
            child: CustomPaint(
              painter: MinesweeperBoardPainter(
                engine: engine,
                cascadeMs: cascadeMs,
                cascadeBatch: cascadeBatch,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}
