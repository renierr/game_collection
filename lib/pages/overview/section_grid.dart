import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/game_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/game_card.dart';

/// One grid of game cards inside the overview's scroll view.
class SectionGrid extends StatelessWidget {
  final List<GameModel> games;
  final int crossAxisCount;
  final bool compact;
  final double childAspectRatio;

  const SectionGrid({
    super.key,
    required this.games,
    required this.crossAxisCount,
    required this.compact,
    required this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final game = games[index];
          return GameCard(
            game: game,
            compact: compact,
            onTap: () {
              context.read<AppState>().recordGameUsage(game.id);
              context.push(game.route);
            },
          );
        }, childCount: games.length),
      ),
    );
  }
}
