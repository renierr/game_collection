import 'dart:io';

import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/debug_log.dart';

/// The app's single SQLite connection. Everything persistent goes through here:
/// per-game key/value settings (saves, high scores, options), favorites and
/// recent-usage timestamps.
class DatabaseService {
  static const String _dbName = 'game_collection.db';
  static const int _dbVersion = 1;
  static const String _tableFavorites = 'game_favorites';
  static const String _tableSettings = 'game_settings';
  static const String _tableRecentUsage = 'game_recent_usage';

  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Future<Database>? _databaseFuture;

  /// Overrides the database path — set to [inMemoryDatabasePath] in tests so a
  /// run never touches the user's real database.
  String? dbPathOverride;

  /// Memoizes the init future so concurrent first callers share one connection.
  Future<Database> get database => _databaseFuture ??= _initDatabase();

  Future<void> close() async {
    final future = _databaseFuture;
    if (future == null) return;
    _databaseFuture = null;
    await (await future).close();
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String path;
    if (dbPathOverride != null) {
      path = dbPathOverride!;
    } else {
      final supportDir = await getApplicationSupportDirectory();
      // Debug and profile runs get their own file so experimenting never
      // corrupts the installed app's saves.
      final modeSubdir = kReleaseMode
          ? ''
          : (kProfileMode ? 'profile' : 'debug');
      final dir = Directory(p.join(supportDir.path, modeSubdir));
      if (!await dir.exists()) await dir.create(recursive: true);
      path = p.join(dir.path, _dbName);
    }

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
    try {
      await db.execute('PRAGMA journal_mode=WAL;');
    } catch (e) {
      errorLog('[DatabaseService] WAL mode unavailable: $e');
    }
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableFavorites (
        game_id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_tableSettings (
        game_id TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        PRIMARY KEY (game_id, key)
      )
    ''');
    await db.execute('''
      CREATE TABLE $_tableRecentUsage (
        game_id TEXT PRIMARY KEY,
        last_used INTEGER NOT NULL
      )
    ''');
  }

  Future<void> setSetting(String gameId, String key, String value) async {
    final db = await database;
    await db.insert(_tableSettings, {
      'game_id': gameId,
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String gameId, String key) async {
    final db = await database;
    final rows = await db.query(
      _tableSettings,
      columns: ['value'],
      where: 'game_id = ? AND key = ?',
      whereArgs: [gameId, key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> deleteSetting(String gameId, String key) async {
    final db = await database;
    await db.delete(
      _tableSettings,
      where: 'game_id = ? AND key = ?',
      whereArgs: [gameId, key],
    );
  }

  Future<Map<String, String>> getAllSettings(String gameId) async {
    final db = await database;
    final rows = await db.query(
      _tableSettings,
      columns: ['key', 'value'],
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }

  Future<Set<String>> getFavoriteIds() async {
    final db = await database;
    final rows = await db.query(_tableFavorites, columns: ['game_id']);
    return {for (final row in rows) row['game_id'] as String};
  }

  Future<void> setFavorite(String gameId, bool value) async {
    final db = await database;
    if (value) {
      await db.insert(_tableFavorites, {
        'game_id': gameId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete(
        _tableFavorites,
        where: 'game_id = ?',
        whereArgs: [gameId],
      );
    }
  }

  Future<Map<String, int>> getRecentTimestamps() async {
    final db = await database;
    final rows = await db.query(_tableRecentUsage);
    return {
      for (final row in rows) row['game_id'] as String: row['last_used'] as int,
    };
  }

  Future<void> touchGameUsage(String gameId) async {
    final db = await database;
    await db.insert(_tableRecentUsage, {
      'game_id': gameId,
      'last_used': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Wipes every stored save, score and preference. Used by the reset action in
  /// the appearance/data settings page.
  Future<void> clearAllGameData() async {
    final db = await database;
    await db.delete(_tableSettings);
    await db.delete(_tableFavorites);
    await db.delete(_tableRecentUsage);
  }
}
