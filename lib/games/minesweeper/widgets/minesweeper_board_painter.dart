import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../helpers/board_text.dart';
import '../engine/minesweeper_engine.dart';
import '../minesweeper_colors.dart';

/// Draws the whole board in cell units — the canvas is scaled so one unit is
/// one cell, which keeps every coordinate here readable as a grid position.
///
/// One painter rather than a widget per square: expert is 480 cells, and 480
/// elements that each rebuild on any board change costs far more than one
/// repaint. Input is mapped back through the same fit by the board widget.
class MinesweeperBoardPainter extends CustomPainter {
  final MinesweeperEngine engine;

  /// Milliseconds into the current reveal cascade. Cells animate in staggered
  /// by their [MineCell.revealOrder], so a flood fill visibly spreads from
  /// where it was clicked instead of appearing all at once.
  final double cascadeMs;

  /// Which batch [cascadeMs] belongs to. Older batches are drawn settled.
  final int cascadeBatch;

  const MinesweeperBoardPainter({
    required this.engine,
    required this.cascadeMs,
    required this.cascadeBatch,
  });

  /// How long one cell takes to appear, and how far apart consecutive cells
  /// start. The stagger is capped in total so a 300-cell region still finishes
  /// promptly.
  static const double _cellMs = 150;
  static const double _stepMs = 11;
  static const double _maxDelayMs = 420;

  @override
  void paint(Canvas canvas, Size size) {
    final level = engine.level;
    final scale = math.min(
      size.width / level.columns,
      size.height / level.rows,
    );
    canvas.save();
    canvas.translate(
      (size.width - level.columns * scale) / 2,
      (size.height - level.rows * scale) / 2,
    );
    canvas.scale(scale);

    final bounds = Rect.fromLTWH(
      0,
      0,
      level.columns.toDouble(),
      level.rows.toDouble(),
    );
    canvas.drawRect(bounds, Paint()..color = MinesweeperColors.board);

    final cells = engine.cells;
    for (var i = 0; i < cells.length; i++) {
      final x = (i % level.columns).toDouble();
      final y = (i ~/ level.columns).toDouble();
      _paintCell(canvas, cells[i], Rect.fromLTWH(x, y, 1, 1));
    }

    canvas.restore();
  }

  /// 0..1 of the way in, for a cell in the current cascade. Already-settled
  /// cells return 1 and are drawn without any transform.
  double _appearance(MineCell cell) {
    if (cell.revealOrder < 0 || engine.revealBatch != cascadeBatch) return 1;
    final delay = math.min(cell.revealOrder * _stepMs, _maxDelayMs);
    return ((cascadeMs - delay) / _cellMs).clamp(0.0, 1.0);
  }

  void _paintCell(Canvas canvas, MineCell cell, Rect rect) {
    if (cell.state != CellState.revealed) {
      _paintCover(canvas, cell, rect);
      return;
    }

    final t = _appearance(cell);
    if (t < 1) {
      // The cover is still there until its cell has finished appearing, so a
      // cascade never shows a hole in the board.
      _paintCover(canvas, cell, rect);
      if (t <= 0) return;
      canvas.save();
      // Shrinks towards the centre as it fades in, which reads as the cover
      // dropping away rather than the tile growing.
      final scale = 0.6 + 0.4 * t;
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.scale(scale);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      _paintFace(canvas, cell, rect, t);
      canvas.restore();
      return;
    }
    _paintFace(canvas, cell, rect, 1);
  }

  void _paintCover(Canvas canvas, MineCell cell, Rect rect) {
    final tile = RRect.fromRectAndRadius(
      rect.deflate(0.045),
      const Radius.circular(0.16),
    );
    canvas.drawRRect(tile, Paint()..color = MinesweeperColors.hidden);
    // A single lit top edge is enough to read as raised; a full bevel at this
    // size turns to mush.
    canvas.drawLine(
      Offset(rect.left + 0.16, rect.top + 0.11),
      Offset(rect.right - 0.16, rect.top + 0.11),
      Paint()
        ..strokeWidth = 0.055
        ..strokeCap = StrokeCap.round
        ..color = MinesweeperColors.hiddenEdge,
    );
    if (cell.state == CellState.flagged) _paintFlag(canvas, rect);
  }

  void _paintFace(Canvas canvas, MineCell cell, Rect rect, double alpha) {
    final background = cell.exploded
        ? MinesweeperColors.explosion
        : MinesweeperColors.revealed;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.045), const Radius.circular(0.12)),
      Paint()..color = background.withValues(alpha: alpha),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.02
        ..color = MinesweeperColors.gridLine.withValues(alpha: alpha),
    );

    if (cell.mine) {
      _paintMine(canvas, rect, alpha);
      return;
    }
    if (cell.neighbours == 0) return;
    BoardText.draw(
      canvas,
      '${cell.neighbours}',
      x: rect.center.dx,
      y: rect.center.dy,
      size: 0.62,
      color: MinesweeperColors.forNeighbours(
        cell.neighbours,
      ).withValues(alpha: alpha),
      weight: FontWeight.w800,
    );
  }

  void _paintFlag(Canvas canvas, Rect rect) {
    final paint = Paint()..color = MinesweeperColors.flag;
    canvas.drawLine(
      Offset(rect.left + 0.44, rect.top + 0.24),
      Offset(rect.left + 0.44, rect.bottom - 0.26),
      Paint()
        ..strokeWidth = 0.07
        ..strokeCap = StrokeCap.round
        ..color = MinesweeperColors.flag.withValues(alpha: 0.75),
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.left + 0.44, rect.top + 0.22)
        ..lineTo(rect.left + 0.44, rect.top + 0.52)
        ..lineTo(rect.left + 0.2, rect.top + 0.37)
        ..close(),
      paint,
    );
  }

  void _paintMine(Canvas canvas, Rect rect, double alpha) {
    final center = rect.center;
    final paint = Paint()
      ..color = MinesweeperColors.mine.withValues(alpha: alpha);
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 4;
      final arm = Offset(math.cos(angle), math.sin(angle)) * 0.28;
      canvas.drawLine(
        center - arm,
        center + arm,
        Paint()
          ..strokeWidth = 0.06
          ..strokeCap = StrokeCap.round
          ..color = paint.color,
      );
    }
    canvas.drawCircle(center, 0.19, paint);
    canvas.drawCircle(
      center + const Offset(-0.06, -0.06),
      0.05,
      Paint()..color = MinesweeperColors.board.withValues(alpha: alpha * 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant MinesweeperBoardPainter oldDelegate) =>
      oldDelegate.engine != engine ||
      oldDelegate.cascadeMs != cascadeMs ||
      oldDelegate.cascadeBatch != cascadeBatch;
}
