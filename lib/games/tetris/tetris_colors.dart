import 'package:flutter/material.dart';

import 'engine/tetromino.dart';

/// Tetris's own palette.
///
/// The seven piece colours are the guideline ones — cyan I, blue J, orange L,
/// yellow O, green S, purple T, red Z. Players read the board by colour at
/// speed, and a clever recolouring would cost them that.
class TetrisColors {
  TetrisColors._();

  static const Color page = Color(0xFF05070D);
  static const Color board = Color(0xFF0E1119);
  static const Color gridLine = Color(0xFF181D2A);
  static const Color wall = Color(0xFF313B54);
  static const Color ghost = Color(0xFF8FA3C8);
  static const Color flash = Color(0xFFFFFFFF);
  static const Color score = Color(0xFF60A5FA);
  static const Color best = Color(0xFFFBBF24);
  static const Color panelLabel = Color(0xFF7C8AA5);

  static const Color i = Color(0xFF22D3EE);
  static const Color j = Color(0xFF3B82F6);
  static const Color l = Color(0xFFF97316);
  static const Color o = Color(0xFFFACC15);
  static const Color s = Color(0xFF22C55E);
  static const Color t = Color(0xFFA855F7);
  static const Color z = Color(0xFFEF4444);

  static Color forKind(TetrominoKind kind) {
    switch (kind) {
      case TetrominoKind.i:
        return i;
      case TetrominoKind.j:
        return j;
      case TetrominoKind.l:
        return l;
      case TetrominoKind.o:
        return o;
      case TetrominoKind.s:
        return s;
      case TetrominoKind.t:
        return t;
      case TetrominoKind.z:
        return z;
    }
  }
}
