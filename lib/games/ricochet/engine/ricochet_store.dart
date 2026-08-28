import '../../../core/game_store.dart';
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

  GameStore get _store => GameStore(RicochetGame.config.id, 'Ricochet');

  Future<int> loadBest() => _store.readInt(_keyBest);

  Future<void> saveBest(int best) => _store.writeInt(_keyBest, best);

  Future<Map<String, dynamic>?> loadSave() => _store.readJson(_keySave);

  Future<void> writeSave(Map<String, dynamic> data) =>
      _store.writeJson(_keySave, data);

  Future<void> clearSave() => _store.delete(_keySave);

  Future<Map<String, dynamic>?> loadCheckpoint() =>
      _store.readJson(_keyCheckpoint);

  Future<void> writeCheckpoint(Map<String, dynamic> data) =>
      _store.writeJson(_keyCheckpoint, data);
}
