import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/tetris_engine.dart';
import '../tetris_colors.dart';
import 'tetris_block.dart';

/// Draws the visible playfield in cell units — the canvas is scaled so one unit
/// is one cell, which keeps every coordinate here readable as a grid position.
///
/// Only the twenty visible rows are drawn; the two spawn rows above them exist
/// so a piece can be rotated before it comes into view, and showing them would
/// just make the board look taller than it plays.
class TetrisBoardPainter extends CustomPainter {
  final TetrisEngine engine;

  TetrisBoardPainter(this.engine) : super(repaint: engine.frames);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / TetrisField.columns,
      size.height / TetrisField.visibleRows,
    );
    canvas.save();
    canvas.translate(
      (size.width - TetrisField.columns * scale) / 2,
      (size.height - TetrisField.visibleRows * scale) / 2,
    );
    canvas.scale(scale);

    final bounds = Rect.fromLTWH(
      0,
      0,
      TetrisField.columns.toDouble(),
      TetrisField.visibleRows.toDouble(),
    );
    canvas.clipRect(bounds);
    canvas.drawRect(bounds, Paint()..color = TetrisColors.board);

    _paintGrid(canvas);
    _paintStack(canvas);
    _paintGhost(canvas);
    _paintActive(canvas);
    _paintClearFlash(canvas);
    // Last, so a piece never paints over the wall it is resting against.
    _paintWalls(canvas, bounds);

    canvas.restore();
  }

  /// Row and column guides. A player judges a gap by counting columns, and on a
  /// near-empty board there is nothing else to count against.
  void _paintGrid(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.025
      ..color = TetrisColors.gridLine;
    for (var x = 1; x < TetrisField.columns; x++) {
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x.toDouble(), TetrisField.visibleRows.toDouble()),
        paint,
      );
    }
    for (var y = 1; y < TetrisField.visibleRows; y++) {
      canvas.drawLine(
        Offset(0, y.toDouble()),
        Offset(TetrisField.columns.toDouble(), y.toDouble()),
        paint,
      );
    }
  }

  void _paintWalls(Canvas canvas, Rect bounds) {
    canvas.drawRect(
      bounds.deflate(0.03),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.06
        ..color = TetrisColors.wall,
    );
  }

  void _paintStack(Canvas canvas) {
    final cells = engine.cells;
    for (var i = 0; i < cells.length; i++) {
      final kind = cells[i];
      if (kind == null) continue;
      final y = i ~/ TetrisField.columns - TetrisField.hiddenRows;
      if (y < 0) continue;
      final x = i % TetrisField.columns;
      TetrisBlock.paint(
        canvas,
        Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
        TetrisColors.forKind(kind),
      );
    }
  }

  void _paintGhost(Canvas canvas) {
    final piece = engine.active;
    if (piece == null || engine.isOver) return;
    final drop = engine.ghostDrop;
    // No outline when the piece is already where it would land — two overlapping
    // shapes just look like a rendering error.
    if (drop == 0) return;
    for (final (x, y) in piece.cells()) {
      final row = y + drop - TetrisField.hiddenRows;
      if (row < 0) continue;
      TetrisBlock.paintOutline(
        canvas,
        Rect.fromLTWH(x.toDouble(), row.toDouble(), 1, 1),
        TetrisColors.ghost,
      );
    }
  }

  void _paintActive(Canvas canvas) {
    final piece = engine.active;
    if (piece == null) return;
    final color = TetrisColors.forKind(piece.kind);
    for (final (x, y) in piece.cells()) {
      final row = y - TetrisField.hiddenRows;
      if (row < 0) continue;
      TetrisBlock.paint(
        canvas,
        Rect.fromLTWH(x.toDouble(), row.toDouble(), 1, 1),
        color,
      );
    }
  }

  /// Cleared rows flash white and collapse vertically before they are removed,
  /// so the player sees which rows they earned rather than the stack simply
  /// jumping down.
  void _paintClearFlash(Canvas canvas) {
    final rows = engine.clearingRows;
    if (rows.isEmpty) return;
    final t = engine.clearProgress;
    for (final row in rows) {
      final y = row - TetrisField.hiddenRows;
      if (y < 0) continue;
      final collapse = t * 0.5;
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          y + collapse,
          TetrisField.columns.toDouble(),
          1 - collapse * 2,
        ),
        Paint()
          ..color = TetrisColors.flash.withValues(alpha: 0.85 * (1 - t * 0.5)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TetrisBoardPainter oldDelegate) =>
      oldDelegate.engine != engine;
}
