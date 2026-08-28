import 'package:flutter/material.dart';

import '../../core/game_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import 'snake_page.dart';

/// Snake's registry entry. The id string lives here and nowhere else.
class SnakeGame {
  SnakeGame._();

  static const GameModel config = GameModel(
    id: 'snake',
    name: 'Snake',
    description:
        'Eat, grow, and keep the tail out of your own way as the board fills '
        'and the pace never lets up.',
    icon: Icons.gesture,
    route: '/snake',
    accentColor: AppTheme.accentGreen,
    sectionId: 'arcade',
    createPage: _createPage,
    nameL10n: _name,
    descriptionL10n: _description,
  );

  static Widget _createPage() => const SnakePage();

  static String _name(AppLocalizations l10n) => l10n.gameNameSnake;

  static String _description(AppLocalizations l10n) =>
      l10n.gameDescriptionSnake;
}
