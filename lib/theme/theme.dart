import 'package:flutter/material.dart';

class AppTheme {
  static const Color accentBlue = Color(0xFF4FC3F7);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color accentAmber = Color(0xFFFFCA28);
  static const Color accentRed = Color(0xFFEF5350);
  static const Color accentPurple = Color(0xFFAB47BC);
  static const Color accentTeal = Color(0xFF26A69A);
  static const Color accentOrange = Color(0xFFFB923C);

  static const Color statusGreen = Color(0xFF66BB6A);
  static const Color statusAmber = Color(0xFFFFCA28);
  static const Color statusRed = Color(0xFFEF5350);
  static const Color favoriteStar = Color(0xFFFFCA28);

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: accentBlue,
    brightness: brightness,
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
