import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

/// Global app state: theme, locale, overview presentation, and the audio /
/// screen preferences every game reads. Game-specific state lives in the game's
/// own `ChangeNotifier`, registered via `GameModel.stateProviders`.
class AppState extends ChangeNotifier {
  final SettingsService _settings;

  AppState(this._settings) {
    _themeMode = _settings.getThemeMode();
    _locale = _settings.getLocale();
    _compactMode = _settings.getCompactMode();
    _sortBy = _settings.getSortBy();
    _soundEnabled = _settings.getSoundEnabled();
    _masterVolume = _settings.getMasterVolume();
    _keepScreenAwake = _settings.getKeepScreenAwake();
    _hapticsEnabled = _settings.getHapticsEnabled();
    _loadPersistedState();
  }

  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _locale;
  bool _compactMode = false;
  String _sortBy = 'recent';
  String _searchQuery = '';
  bool _soundEnabled = true;
  double _masterVolume = 0.7;
  bool _keepScreenAwake = true;
  bool _hapticsEnabled = true;
  Set<String> _favorites = {};
  Map<String, int> _recentTimestamps = {};

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  List<Locale> get supportedLocales => AppLocalizations.supportedLocales;
  bool get compactMode => _compactMode;
  String get sortBy => _sortBy;
  String get searchQuery => _searchQuery;
  bool get soundEnabled => _soundEnabled;
  double get masterVolume => _masterVolume;
  bool get keepScreenAwake => _keepScreenAwake;
  bool get hapticsEnabled => _hapticsEnabled;
  Set<String> get favorites => _favorites;

  /// The volume a game should actually play at — the mute switch folded into
  /// the slider, so callers never have to check both.
  double get effectiveVolume => _soundEnabled ? _masterVolume : 0.0;

  bool isFavorite(String gameId) => _favorites.contains(gameId);

  int getLastUsed(String gameId) => _recentTimestamps[gameId] ?? 0;

  /// Loads everything the overview grid reads, then notifies once. Notifying
  /// per loader reshuffles the visible grid after the first frame.
  Future<void> _loadPersistedState() async {
    final db = DatabaseService.instance;
    _favorites = await db.getFavoriteIds();
    _recentTimestamps = await db.getRecentTimestamps();
    notifyListeners();
  }

  Future<void> toggleFavorite(String gameId) async {
    final newState = !_favorites.contains(gameId);
    await DatabaseService.instance.setFavorite(gameId, newState);
    if (newState) {
      _favorites.add(gameId);
    } else {
      _favorites.remove(gameId);
    }
    notifyListeners();
  }

  Future<void> recordGameUsage(String gameId) async {
    await DatabaseService.instance.touchGameUsage(gameId);
    _recentTimestamps[gameId] = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _settings.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    await _settings.setLocale(locale);
    notifyListeners();
  }

  Future<void> toggleCompactMode() async {
    _compactMode = !_compactMode;
    await _settings.setCompactMode(_compactMode);
    notifyListeners();
  }

  Future<void> setSortBy(String value) async {
    _sortBy = value;
    await _settings.setSortBy(value);
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _settings.setSoundEnabled(value);
    notifyListeners();
  }

  Future<void> setMasterVolume(double value) async {
    _masterVolume = value.clamp(0.0, 1.0);
    await _settings.setMasterVolume(_masterVolume);
    notifyListeners();
  }

  Future<void> setKeepScreenAwake(bool value) async {
    _keepScreenAwake = value;
    await _settings.setKeepScreenAwake(value);
    notifyListeners();
  }

  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    await _settings.setHapticsEnabled(value);
    notifyListeners();
  }

  /// Drops every save, high score and preference, then reloads from the empty
  /// database so the UI reflects the reset without a restart.
  Future<void> resetAllData() async {
    await DatabaseService.instance.clearAllGameData();
    await _settings.reload();
    _themeMode = _settings.getThemeMode();
    _locale = _settings.getLocale();
    _compactMode = _settings.getCompactMode();
    _sortBy = _settings.getSortBy();
    _soundEnabled = _settings.getSoundEnabled();
    _masterVolume = _settings.getMasterVolume();
    _keepScreenAwake = _settings.getKeepScreenAwake();
    _hapticsEnabled = _settings.getHapticsEnabled();
    await _loadPersistedState();
  }
}
