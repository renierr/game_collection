import '../../../core/game_store.dart';
import '../config.dart' show MinesweeperGame;
import 'minesweeper_engine.dart' show MineLevel;

/// Minesweeper's persistence: the board in progress, and a best time per
/// difficulty.
///
/// Times are keyed per level because a beginner record and an expert record are
/// not comparable — one board is not a harder version of the other, it is a
/// different game.
class MinesweeperStore {
  static const String _keySave = 'save';
  static const String _bestPrefix = 'best_';

  const MinesweeperStore();

  GameStore get _store => GameStore(MinesweeperGame.config.id, 'Minesweeper');

  Future<Map<String, int>> loadBestTimes() async {
    final result = <String, int>{};
    for (final level in MineLevel.values) {
      final seconds = await _store.readInt('$_bestPrefix${level.id}');
      if (seconds > 0) result[level.id] = seconds;
    }
    return result;
  }

  Future<void> saveBestTime(String levelId, int seconds) =>
      _store.writeInt('$_bestPrefix$levelId', seconds);

  Future<Map<String, dynamic>?> loadSave() => _store.readJson(_keySave);

  Future<void> writeSave(Map<String, dynamic> data) =>
      _store.writeJson(_keySave, data);

  Future<void> clearSave() => _store.delete(_keySave);
}
