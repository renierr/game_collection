import 'dart:convert';

import '../helpers/debug_log.dart';
import '../services/database_service.dart';

/// Key/value persistence for one game, on top of the shared settings table.
///
/// Every game stores its run the same way — a JSON blob for the board, plain
/// integers for records — so the guarded read/write pair lives here once. A
/// game wraps this in its own small store class so its engine depends on a
/// named, injectable seam rather than on the database.
///
/// Writes never throw. Saves are fire-and-forget from a game loop, and a full
/// disk or a database closing under a page teardown must cost the player one
/// save, not an unhandled error.
class GameStore {
  final String gameId;

  /// Prefixes every log line, so a failure names the game that caused it.
  final String logTag;

  const GameStore(this.gameId, this.logTag);

  Future<int> readInt(String key, {int fallback = 0}) async {
    final raw = await _read(key);
    return int.tryParse(raw ?? '') ?? fallback;
  }

  Future<void> writeInt(String key, int value) => write(key, value.toString());

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await _read(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      // A corrupt blob must cost the player at most this one save, never a
      // crash on launch.
      errorLog('[$logTag] Discarding unreadable "$key": $e');
      return null;
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> data) =>
      write(key, jsonEncode(data));

  Future<void> write(String key, String value) async {
    try {
      await DatabaseService.instance.setSetting(gameId, key, value);
    } catch (e) {
      errorLog('[$logTag] Could not save "$key": $e');
    }
  }

  Future<void> delete(String key) async {
    try {
      await DatabaseService.instance.deleteSetting(gameId, key);
    } catch (e) {
      errorLog('[$logTag] Could not clear "$key": $e');
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await DatabaseService.instance.getSetting(gameId, key);
    } catch (e) {
      errorLog('[$logTag] Could not read "$key": $e');
      return null;
    }
  }
}
