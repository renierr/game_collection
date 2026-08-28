import 'dart:convert';

import '../../../helpers/debug_log.dart';
import '../../../services/database_service.dart';
import '../config.dart' show RicochetGame;

/// Ricochet's persistence: the in-progress run, the level checkpoint used by
/// *Retry Level*, and the all-time best score.
///
/// Everything is stored as JSON in the shared per-game settings table, so a
/// full data reset from the settings page clears it along with everything else.
class RicochetStore {
  static const String _keySave = 'save';
  static const String _keyCheckpoint = 'checkpoint';
  static const String _keyBest = 'best';

  const RicochetStore();

  String get _gameId => RicochetGame.config.id;

  Future<int> loadBest() async {
    final raw = await DatabaseService.instance.getSetting(_gameId, _keyBest);
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> saveBest(int best) => _write(_keyBest, best.toString());

  Future<Map<String, dynamic>?> loadSave() => _readJson(_keySave);

  Future<void> writeSave(Map<String, dynamic> data) =>
      _writeJson(_keySave, data);

  Future<void> clearSave() async {
    try {
      await DatabaseService.instance.deleteSetting(_gameId, _keySave);
    } catch (e) {
      errorLog('[Ricochet] Could not clear "$_keySave": $e');
    }
  }

  Future<Map<String, dynamic>?> loadCheckpoint() => _readJson(_keyCheckpoint);

  Future<void> writeCheckpoint(Map<String, dynamic> data) =>
      _writeJson(_keyCheckpoint, data);

  Future<Map<String, dynamic>?> _readJson(String key) async {
    final raw = await DatabaseService.instance.getSetting(_gameId, key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      // A corrupt blob must cost the player at most this one save, never a
      // crash on launch.
      errorLog('[Ricochet] Discarding unreadable "$key": $e');
      return null;
    }
  }

  Future<void> _writeJson(String key, Map<String, dynamic> data) =>
      _write(key, jsonEncode(data));

  /// Saves are fire-and-forget from the frame loop, so a failed write must not
  /// surface as an unhandled error — a full disk or a database closing under a
  /// page teardown costs the player this one save, nothing more.
  Future<void> _write(String key, String value) async {
    try {
      await DatabaseService.instance.setSetting(_gameId, key, value);
    } catch (e) {
      errorLog('[Ricochet] Could not save "$key": $e');
    }
  }
}
