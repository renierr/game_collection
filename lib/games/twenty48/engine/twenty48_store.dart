import '../../../core/game_store.dart';
import '../config.dart' show Twenty48Game;

/// 2048's persistence: the board in progress and the all-time best score.
///
/// The engine takes this as a constructor argument, so a test can hand it a
/// fake and never touch a database.
class Twenty48Store {
  static const String _keySave = 'save';
  static const String _keyBest = 'best';

  const Twenty48Store();

  GameStore get _store => GameStore(Twenty48Game.config.id, '2048');

  Future<int> loadBest() => _store.readInt(_keyBest);

  Future<void> saveBest(int best) => _store.writeInt(_keyBest, best);

  Future<Map<String, dynamic>?> loadSave() => _store.readJson(_keySave);

  Future<void> writeSave(Map<String, dynamic> data) =>
      _store.writeJson(_keySave, data);

  Future<void> clearSave() => _store.delete(_keySave);
}
