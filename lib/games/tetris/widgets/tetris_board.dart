import 'package:flutter/material.dart';

import '../engine/tetris_engine.dart';
import 'tetris_board_painter.dart';

/// The playfield plus its touch input.
///
/// The gestures mirror what the piece can do rather than mapping to a virtual
/// d-pad: dragging sideways slides the piece cell by cell under the finger,
/// dragging down soft-drops it the same way, a flick down hard-drops, and a tap
/// rotates. The drag is measured against the on-screen cell width, so one cell
/// of finger travel is one cell of movement at any board scale.
class TetrisBoard extends StatefulWidget {
  final TetrisEngine engine;

  const TetrisBoard({super.key, required this.engine});

  @override
  State<TetrisBoard> createState() => _TetrisBoardState();
}

class _TetrisBoardState extends State<TetrisBoard> {
  double _dx = 0;
  double _dy = 0;
  double _cell = 24;

  /// Downward flick speed, in logical pixels per second, that counts as a hard
  /// drop rather than a fast soft drop.
  static const double _flickVelocity = 1400;

  void _onPanStart(DragStartDetails details) {
    _dx = 0;
    _dy = 0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final engine = widget.engine;
    _dx += details.delta.dx;
    _dy += details.delta.dy;

    while (_dx.abs() >= _cell) {
      final moved = _dx > 0 ? engine.moveRight() : engine.moveLeft();
      _dx -= _dx > 0 ? _cell : -_cell;
      if (!moved) break;
    }
    // Only downward drags do anything vertically; dragging up is how a player
    // repositions their finger, not a command.
    while (_dy >= _cell) {
      _dy -= _cell;
      engine.softDrop();
    }
    if (_dy < 0) _dy = 0;
  }

  void _onPanEnd(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dy > _flickVelocity) {
      widget.engine.hardDrop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: TetrisField.columns / TetrisField.visibleRows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _cell = constraints.maxWidth / TetrisField.columns;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.engine.rotate(clockwise: true),
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: TetrisBoardPainter(widget.engine),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}
