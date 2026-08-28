import '../../../core/game_store.dart';
import '../config.dart' show SnakeGame;

/// Snake's persistence: the best score, and nothing else.
///
/// A run lasts a couple of minutes and is worthless once the snake is dead, so
/// there is no board to save — the record is the only thing worth keeping.
class SnakeStore {
  static const String _keyBest = 'best';

  const SnakeStore();

  GameStore get _store => GameStore(SnakeGame.config.id, 'Snake');

  Future<int> loadBest() => _store.readInt(_keyBest);

  Future<void> saveBest(int best) => _store.writeInt(_keyBest, best);
}
