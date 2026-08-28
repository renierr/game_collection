import 'package:flutter/material.dart';

import '../engine/snake_engine.dart';
import 'snake_board_painter.dart';

/// The playfield. Square at any size, so a phone and a maximized desktop
/// window play the identical board and only the scale differs.
class SnakeBoard extends StatelessWidget {
  final SnakeEngine engine;

  const SnakeBoard({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: SnakeGrid.columns / SnakeGrid.rows,
      child: CustomPaint(
        painter: SnakeBoardPainter(engine),
        size: Size.infinite,
      ),
    );
  }
}
