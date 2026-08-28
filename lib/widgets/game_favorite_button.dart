import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/theme.dart';

class GameFavoriteButton extends StatelessWidget {
  final String gameId;
  final double iconSize;

  const GameFavoriteButton({
    super.key,
    required this.gameId,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final isFavorite = appState.isFavorite(gameId);
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_outline,
        size: iconSize,
        color: isFavorite
            ? AppTheme.favoriteStar
            : Theme.of(context).colorScheme.onSurface.withAlpha(100),
      ),
      onPressed: () => context.read<AppState>().toggleFavorite(gameId),
      visualDensity: VisualDensity.compact,
      tooltip: isFavorite
          ? l10n.overviewRemoveFavorite
          : l10n.overviewAddFavorite,
    );
  }
}
