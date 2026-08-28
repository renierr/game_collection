import 'package:flutter/material.dart';

import '../engine/tetromino.dart';
import '../tetris_colors.dart';
import 'tetris_block.dart';

/// One piece drawn in a small box, for the hold slot and the next queue.
///
/// Centred on its own filled cells rather than on its rotation box, so an I and
/// an O look equally deliberate instead of drifting to one side of the panel.
class TetrisPiecePreview extends StatelessWidget {
  final TetrominoKind? kind;

  /// Dimmed, for a hold slot that has already been used this piece.
  final bool dimmed;

  final double cell;

  const TetrisPiecePreview({
    super.key,
    required this.kind,
    required this.cell,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Four cells wide covers the I; every piece then shares one box size, so
      // the queue does not jitter as pieces come and go.
      width: cell * 4,
      height: cell * 2.4,
      child: kind == null
          ? const SizedBox.shrink()
          : CustomPaint(
              painter: _PreviewPainter(kind: kind!, dimmed: dimmed),
            ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final TetrominoKind kind;
  final bool dimmed;

  const _PreviewPainter({required this.kind, required this.dimmed});

  @override
  void paint(Canvas canvas, Size size) {
    final cells = kind.cellsAt(0);
    var minX = 4, maxX = 0, minY = 4, maxY = 0;
    for (final (x, y) in cells) {
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    final wide = maxX - minX + 1;
    final tall = maxY - minY + 1;
    final scale = (size.width / wide).clamp(0.0, size.height / tall);
    final offsetX = (size.width - wide * scale) / 2;
    final offsetY = (size.height - tall * scale) / 2;

    final color = TetrisColors.forKind(kind);
    for (final (x, y) in cells) {
      TetrisBlock.paint(
        canvas,
        Rect.fromLTWH(
          offsetX + (x - minX) * scale,
          offsetY + (y - minY) * scale,
          scale,
          scale,
        ),
        color,
        alpha: dimmed ? 0.3 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.dimmed != dimmed;
}
