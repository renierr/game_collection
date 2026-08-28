import 'package:flutter/material.dart';

import '../core/game_model.dart';
import 'game_card_compact.dart';
import 'game_card_normal.dart';

/// One tile in the overview grid. The two layouts differ enough to live in
/// their own files; this picks between them and owns the shared card chrome.
class GameCard extends StatelessWidget {
  final GameModel game;
  final VoidCallback onTap;
  final bool compact;

  const GameCard({
    super.key,
    required this.game,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) => compact
              ? GameCardCompact(game: game, cardWidth: constraints.maxWidth)
              : GameCardNormal(game: game, cardWidth: constraints.maxWidth),
        ),
      ),
    );
  }
}
