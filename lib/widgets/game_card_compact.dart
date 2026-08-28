import 'package:flutter/material.dart';

import '../core/game_model.dart';
import '../l10n/app_localizations.dart';
import 'game_favorite_button.dart';

class GameCardCompact extends StatelessWidget {
  final GameModel game;
  final double cardWidth;

  const GameCardCompact({
    super.key,
    required this.game,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isNarrow = cardWidth < 200;

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: game.accentColor, width: 3)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 8 : 12,
          vertical: isNarrow ? 8 : 10,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isNarrow ? 6 : 8),
              decoration: BoxDecoration(
                color: game.accentColor.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                game.icon,
                size: isNarrow ? 18 : 20,
                color: game.accentColor,
              ),
            ),
            SizedBox(width: isNarrow ? 8 : 12),
            Expanded(
              child: Text(
                game.localizedName(l10n),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isNarrow ? 13 : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GameFavoriteButton(gameId: game.id, iconSize: isNarrow ? 16 : 18),
            Icon(
              Icons.chevron_right,
              size: isNarrow ? 16 : 18,
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ],
        ),
      ),
    );
  }
}
