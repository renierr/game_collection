import 'package:flutter/material.dart';

/// Snake's own palette: a dark board with a single vivid gradient down the
/// body, so the head is always the brightest thing on screen and the eye
/// follows it without having to look for it.
class SnakeColors {
  SnakeColors._();

  static const Color page = Color(0xFF060A08);
  static const Color board = Color(0xFF0D1512);
  static const Color grid = Color(0xFF16221D);
  static const Color wall = Color(0xFF2F4A3E);

  static const Color head = Color(0xFF6EE7B7);
  static const Color tail = Color(0xFF0E7490);
  static const Color eye = Color(0xFF06231A);

  static const Color food = Color(0xFFF87171);
  static const Color bonus = Color(0xFFFBBF24);
  static const Color score = Color(0xFF6EE7B7);
  static const Color best = Color(0xFFFBBF24);

  /// Body colour by how far down the snake a segment is, 0 at the head.
  static Color segment(double t) =>
      Color.lerp(head, tail, t.clamp(0.0, 1.0)) ?? head;
}
