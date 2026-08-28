import 'package:flutter/material.dart';

import 'database_service.dart';

/// App-wide preferences, cached in memory after one read at startup and written
/// through to the `_app` pseudo-game row in [DatabaseService].
class SettingsService {
  static const String _gameId = '_app';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLocale = 'locale';
  static const String _keyCompactMode = 'compact_mode';
  static const String _keySortBy = 'sort_by';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyMasterVolume = 'master_volume';
  static const String _keyKeepScreenAwake = 'keep_screen_awake';
  static const String _keyHaptics = 'haptics_enabled';

  final Map<String, String> _cache;

  SettingsService._(this._cache);

  static Future<SettingsService> init() async {
    return SettingsService._(
      await DatabaseService.instance.getAllSettings(_gameId),
    );
  }

  Future<void> _write(String key, String value) async {
    _cache[key] = value;
    await DatabaseService.instance.setSetting(_gameId, key, value);
  }

  ThemeMode getThemeMode() {
    final index = _cache[_keyThemeMode];
    if (index == null) return ThemeMode.dark;
    return ThemeMode.values[int.tryParse(index) ?? ThemeMode.dark.index];
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _write(_keyThemeMode, mode.index.toString());

  /// The stored UI locale, or null to follow the system language.
  Locale? getLocale() {
    final code = _cache[_keyLocale];
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> setLocale(Locale? locale) =>
      _write(_keyLocale, locale?.languageCode ?? '');

  bool getCompactMode() => _cache[_keyCompactMode] == 'true';

  Future<void> setCompactMode(bool value) =>
      _write(_keyCompactMode, value.toString());

  String getSortBy() => _cache[_keySortBy] ?? 'recent';

  Future<void> setSortBy(String value) => _write(_keySortBy, value);

  bool getSoundEnabled() => _cache[_keySoundEnabled] != 'false';

  Future<void> setSoundEnabled(bool value) =>
      _write(_keySoundEnabled, value.toString());

  double getMasterVolume() =>
      double.tryParse(_cache[_keyMasterVolume] ?? '')?.clamp(0.0, 1.0) ?? 0.7;

  Future<void> setMasterVolume(double value) =>
      _write(_keyMasterVolume, value.toStringAsFixed(2));

  bool getKeepScreenAwake() => _cache[_keyKeepScreenAwake] != 'false';

  Future<void> setKeepScreenAwake(bool value) =>
      _write(_keyKeepScreenAwake, value.toString());

  bool getHapticsEnabled() => _cache[_keyHaptics] != 'false';

  Future<void> setHapticsEnabled(bool value) =>
      _write(_keyHaptics, value.toString());

  Future<void> reload() async {
    final fresh = await DatabaseService.instance.getAllSettings(_gameId);
    _cache
      ..clear()
      ..addAll(fresh);
  }
}
