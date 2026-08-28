import 'package:flutter/material.dart';

import '../core/game_model.dart';
import '../l10n/app_localizations.dart';
import 'game_favorite_button.dart';

class GameCardNormal extends StatelessWidget {
  final GameModel game;
  final double cardWidth;

  const GameCardNormal({
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
        padding: EdgeInsets.all(isNarrow ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isNarrow ? 6 : 8),
                  decoration: BoxDecoration(
                    color: game.accentColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    game.icon,
                    size: isNarrow ? 18 : 22,
                    color: game.accentColor,
                  ),
                ),
                const Spacer(),
                GameFavoriteButton(
                  gameId: game.id,
                  iconSize: isNarrow ? 16 : 18,
                ),
              ],
            ),
            SizedBox(height: isNarrow ? 6 : 8),
            Text(
              game.localizedName(l10n),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isNarrow ? 13 : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                game.localizedDescription(l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(180),
                  height: 1.3,
                  fontSize: isNarrow ? 11 : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
