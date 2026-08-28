import '../../../core/game_store.dart';
import '../config.dart' show TetrisGame;

/// Tetris's persistence: the stack in progress and the all-time best score.
class TetrisStore {
  static const String _keySave = 'save';
  static const String _keyBest = 'best';

  const TetrisStore();

  GameStore get _store => GameStore(TetrisGame.config.id, 'Tetris');

  Future<int> loadBest() => _store.readInt(_keyBest);

  Future<void> saveBest(int best) => _store.writeInt(_keyBest, best);

  Future<Map<String, dynamic>?> loadSave() => _store.readJson(_keySave);

  Future<void> writeSave(Map<String, dynamic> data) =>
      _store.writeJson(_keySave, data);

  Future<void> clearSave() => _store.delete(_keySave);
}
