import 'package:flutter/material.dart';

/// Minesweeper's own palette.
///
/// The number colours are the classic ones — most players read a board by
/// colour before they read the digit, and relearning that mapping is a real
/// cost — but set against a dark tile rather than Windows grey.
class MinesweeperColors {
  MinesweeperColors._();

  static const Color page = Color(0xFF0A0B10);
  static const Color board = Color(0xFF13151F);
  static const Color hidden = Color(0xFF2A2F40);
  static const Color hiddenEdge = Color(0xFF3A4156);
  static const Color revealed = Color(0xFF191C27);
  static const Color gridLine = Color(0xFF222634);
  static const Color flag = Color(0xFFF87171);
  static const Color mine = Color(0xFFE2E8F0);
  static const Color explosion = Color(0xFFEF4444);
  static const Color cursor = Color(0xFF38BDF8);
  static const Color time = Color(0xFF38BDF8);
  static const Color best = Color(0xFF34D399);

  /// The classic 1–8 ramp: blue, green, red, navy, maroon, teal, black, grey.
  /// The last two are lifted off pure black so they stay legible on a dark tile.
  static const List<Color> _numbers = [
    Color(0xFF60A5FA),
    Color(0xFF4ADE80),
    Color(0xFFF87171),
    Color(0xFFA78BFA),
    Color(0xFFFB923C),
    Color(0xFF22D3EE),
    Color(0xFFE879F9),
    Color(0xFF94A3B8),
  ];

  static Color forNeighbours(int count) =>
      _numbers[(count - 1).clamp(0, _numbers.length - 1)];
}
