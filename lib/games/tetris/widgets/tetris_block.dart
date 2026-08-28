import 'package:flutter/material.dart';

/// Draws one tetromino cell.
///
/// Shared by the board painter and the hold/next previews so a piece looks
/// identical wherever it appears — a J in the queue must be recognisable as the
/// same object that lands on the stack.
class TetrisBlock {
  TetrisBlock._();

  /// [rect] is in whatever units the canvas is scaled to; every inset below is
  /// a fraction of the cell, so the block is resolution-independent.
  static void paint(Canvas canvas, Rect rect, Color color, {double alpha = 1}) {
    final body = RRect.fromRectAndRadius(
      rect.deflate(rect.width * 0.06),
      Radius.circular(rect.width * 0.18),
    );
    canvas.drawRRect(body, Paint()..color = color.withValues(alpha: alpha));
    // A single lit top edge rather than a full bevel: at ten cells across a
    // phone, anything more detailed turns to mush.
    canvas.drawLine(
      Offset(rect.left + rect.width * 0.24, rect.top + rect.height * 0.2),
      Offset(rect.right - rect.width * 0.24, rect.top + rect.height * 0.2),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = rect.height * 0.1
        ..color = Colors.white.withValues(alpha: alpha * 0.28),
    );
  }

  /// The hollow outline used for the ghost drop.
  static void paintOutline(
    Canvas canvas,
    Rect rect,
    Color color, {
    double alpha = 0.45,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(rect.width * 0.12),
        Radius.circular(rect.width * 0.16),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.width * 0.08
        ..color = color.withValues(alpha: alpha),
    );
  }
}
