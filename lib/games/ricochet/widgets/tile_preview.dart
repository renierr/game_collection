import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/geometry.dart';
import '../engine/tile.dart';
import '../ricochet_colors.dart';
import 'tile_painter.dart';

/// A single tile drawn by the game's own [TilePainter], at legend size.
///
/// The whole point is that the reference cannot drift: the legend hands the
/// painter a throwaway [Brick] and gets back exactly the art the board draws.
class TilePreview extends StatelessWidget {
  final TileType type;
  final int hp;
  final double size;

  /// Draws the (+) pickup instead of a tile — it is not a brick and has no HP.
  final bool pickup;

  const TilePreview({
    super.key,
    required this.type,
    this.hp = 6,
    this.size = 52,
    this.pickup = false,
  });

  const TilePreview.pickup({super.key, this.size = 52})
    : type = TileType.normal,
      hp = 0,
      pickup = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TilePreviewPainter(type, hp, pickup)),
    );
  }
}

class _TilePreviewPainter extends CustomPainter {
  final TileType type;
  final int hp;
  final bool pickup;

  const _TilePreviewPainter(this.type, this.hp, this.pickup);

  @override
  void paint(Canvas canvas, Size size) {
    // Paint in board units and scale up, so glyph proportions match the board.
    final scale = size.width / Board.cell;
    canvas.scale(scale);
    final rect = Rect.fromLTWH(0, 0, Board.cell, Board.cell);
    if (pickup) {
      TilePainter.paintPickup(canvas, rect.center, 14, 0);
      return;
    }
    TilePainter.paintTile(
      canvas,
      Brick(uid: 0, x: 0, y: 0, hp: hp, maxHp: hp, type: type, flash: 0),
      rect,
    );
  }

  @override
  bool shouldRepaint(covariant _TilePreviewPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.hp != hp ||
      oldDelegate.pickup != pickup;
}

/// A looping animation of a ball being bent by one of the four tiles that
/// change its path, so the legend shows the mechanic rather than describing it.
class DeflectionDemo extends StatefulWidget {
  final TileType type;
  final double size;

  const DeflectionDemo({super.key, required this.type, this.size = 96});

  @override
  State<DeflectionDemo> createState() => _DeflectionDemoState();
}

class _DeflectionDemoState extends State<DeflectionDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _DeflectionPainter(widget.type, _controller.value),
        ),
      ),
    );
  }
}

class _DeflectionPainter extends CustomPainter {
  final TileType type;
  final double t;

  const _DeflectionPainter(this.type, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // A 3×3 cell stage with the tile in the middle, scaled to the widget.
    const stage = Board.cell * 3;
    canvas.scale(size.width / stage);

    final tileRect = Rect.fromLTWH(
      Board.cell,
      Board.cell,
      Board.cell,
      Board.cell,
    );
    TilePainter.paintTile(
      canvas,
      Brick(uid: 0, x: 0, y: 0, hp: 3, maxHp: 3, type: type, flash: 0),
      tileRect,
    );

    final path = _path(tileRect);
    final ball = _pointAt(path, t);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.28);
    for (var i = 1; i < path.length; i++) {
      canvas.drawLine(path[i - 1], path[i], paint);
    }
    canvas.drawCircle(
      ball,
      Board.ballRadius,
      Paint()..color = RicochetColors.ball,
    );
  }

  /// Where the ball goes in, where it turns, and where it leaves — the exact
  /// deflection the simulation produces for this tile.
  List<Offset> _path(Rect tile) {
    final center = tile.center;
    switch (type) {
      case TileType.rampA:
        // '/' slope: a ball dropping in leaves to the left.
        return [
          Offset(center.dx, 0),
          Offset(center.dx, center.dy),
          Offset(0, center.dy),
        ];
      case TileType.rampB:
        // '\' slope turns the same drop the opposite way.
        return [
          Offset(center.dx, 0),
          Offset(center.dx, center.dy),
          Offset(Board.cell * 3, center.dy),
        ];
      case TileType.orb:
        // Round bumper: an off-centre hit fans the ball out at an angle.
        final impact = center + Offset(-Board.cell * 0.28, Board.cell * 0.42);
        final normal = (impact - center) / (impact - center).distance;
        final incoming = const Offset(0, -1);
        final dot = incoming.dx * normal.dx + incoming.dy * normal.dy;
        final outgoing = incoming - normal * (2 * dot);
        return [
          impact - incoming * Board.cell * 1.4,
          impact,
          impact + outgoing * Board.cell * 1.6,
        ];
      case TileType.bomb:
        // Nothing bends — the ball stops here and the tile goes up.
        return [Offset(center.dx, Board.cell * 3), center];
      case TileType.normal:
      case TileType.gift:
      case TileType.mult:
      case TileType.pierce:
      case TileType.blast:
        return [
          Offset(center.dx, Board.cell * 3),
          Offset(center.dx, tile.bottom + Board.ballRadius),
          Offset(center.dx, Board.cell * 3),
        ];
    }
  }

  /// Walks the polyline at constant speed so the ball does not lurch at turns.
  Offset _pointAt(List<Offset> path, double progress) {
    var total = 0.0;
    for (var i = 1; i < path.length; i++) {
      total += (path[i] - path[i - 1]).distance;
    }
    var target = total * progress;
    for (var i = 1; i < path.length; i++) {
      final segment = (path[i] - path[i - 1]).distance;
      if (target <= segment || i == path.length - 1) {
        final f = segment == 0 ? 0.0 : math.min(1.0, target / segment);
        return Offset.lerp(path[i - 1], path[i], f)!;
      }
      target -= segment;
    }
    return path.last;
  }

  @override
  bool shouldRepaint(covariant _DeflectionPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.type != type;
}
