import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/game_direction.dart';
import '../engine/snake_engine.dart';
import '../snake_colors.dart';

/// Draws the board in cell units — the canvas is scaled so one unit is one
/// cell, which keeps every offset here readable as a grid coordinate.
///
/// The snake is drawn as a single stroked polyline through the cell centres
/// rather than as a row of squares. That is what lets it be interpolated: the
/// head runs ahead of its cell by [SnakeEngine.stepProgress] and the tail
/// retreats out of its own by the same amount, so a 6-steps-per-second
/// simulation reads as continuous motion at 60 Hz.
class SnakeBoardPainter extends CustomPainter {
  final SnakeEngine engine;

  SnakeBoardPainter(this.engine) : super(repaint: engine.frames);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / SnakeGrid.columns,
      size.height / SnakeGrid.rows,
    );
    canvas.save();
    canvas.translate(
      (size.width - SnakeGrid.columns * scale) / 2,
      (size.height - SnakeGrid.rows * scale) / 2,
    );
    canvas.scale(scale);

    final bounds = Rect.fromLTWH(
      0,
      0,
      SnakeGrid.columns.toDouble(),
      SnakeGrid.rows.toDouble(),
    );
    canvas.clipRect(bounds);
    canvas.drawRect(bounds, Paint()..color = SnakeColors.board);

    _paintGrid(canvas);
    _paintFood(canvas);
    _paintSnake(canvas);
    // Last, so the head never paints over the wall it is about to hit.
    _paintWalls(canvas, bounds);

    canvas.restore();
  }

  /// A faint lattice. Without it the snake's speed has nothing to read against
  /// and the board looks like empty space rather than a grid.
  void _paintGrid(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.03
      ..color = SnakeColors.grid;
    for (var x = 1; x < SnakeGrid.columns; x++) {
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x.toDouble(), SnakeGrid.rows.toDouble()),
        paint,
      );
    }
    for (var y = 1; y < SnakeGrid.rows; y++) {
      canvas.drawLine(
        Offset(0, y.toDouble()),
        Offset(SnakeGrid.columns.toDouble(), y.toDouble()),
        paint,
      );
    }
  }

  void _paintWalls(Canvas canvas, Rect bounds) {
    canvas.drawRect(
      bounds.deflate(0.04),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.08
        ..color = SnakeColors.wall,
    );
  }

  void _paintFood(Canvas canvas) {
    final food = engine.food;
    if (food == null) return;
    final center = _centre(food.cell);
    final color = food.bonus ? SnakeColors.bonus : SnakeColors.food;

    // A bonus shrinks as its window closes, so the pressure is visible without
    // reading a timer.
    final urgency = food.bonus ? 0.55 + 0.45 * food.freshness : 1.0;
    final pulse = 1 + 0.08 * math.sin(engine.timeSeconds * 6);
    final radius = 0.3 * urgency * pulse;

    canvas.drawCircle(
      center,
      radius * 2.1,
      Paint()..color = color.withValues(alpha: 0.16),
    );
    canvas.drawCircle(center, radius, Paint()..color = color);
    if (food.bonus) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.06
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  void _paintSnake(Canvas canvas) {
    final body = engine.body;
    if (body.isEmpty) return;

    final points = [for (final cell in body) _centre(cell)];
    final progress = engine.hasStarted && !engine.isPaused
        ? engine.stepProgress
        : 0.0;

    // The head runs ahead of its cell towards the one it is entering.
    points[0] += _step(engine.direction) * progress;

    // The tail slides out of its cell, unless the snake is still growing into
    // food it ate — then it holds, and the snake gets longer instead.
    if (points.length > 1 && !engine.tailHolding) {
      final last = points.length - 1;
      points[last] += (points[last - 1] - points[last]) * progress;
    }

    // Drawn segment by segment with round caps: the overlapping caps join into
    // one continuous body, and each segment can carry its own colour, which is
    // how the gradient from head to tail happens without a shader.
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(
        points[i],
        points[i + 1],
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.78
          ..color = SnakeColors.segment(i / math.max(1, points.length - 1)),
      );
    }

    final head = points.first;
    canvas.drawCircle(head, 0.42, Paint()..color = SnakeColors.head);
    _paintEyes(canvas, head);
  }

  void _paintEyes(Canvas canvas, Offset head) {
    final forward = _step(engine.direction);
    final sideways = Offset(-forward.dy, forward.dx);
    final paint = Paint()..color = SnakeColors.eye;
    for (final side in [1.0, -1.0]) {
      canvas.drawCircle(
        head + forward * 0.13 + sideways * 0.16 * side,
        0.075,
        paint,
      );
    }
  }

  static Offset _centre(SnakeCell cell) => Offset(cell.x + 0.5, cell.y + 0.5);

  static Offset _step(GameDirection direction) {
    switch (direction) {
      case GameDirection.up:
        return const Offset(0, -1);
      case GameDirection.down:
        return const Offset(0, 1);
      case GameDirection.left:
        return const Offset(-1, 0);
      case GameDirection.right:
        return const Offset(1, 0);
    }
  }

  @override
  bool shouldRepaint(covariant SnakeBoardPainter oldDelegate) =>
      oldDelegate.engine != engine;
}
