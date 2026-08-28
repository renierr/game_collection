import 'package:flutter/material.dart';

import '../../core/game_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import 'minesweeper_page.dart';

/// Minesweeper's registry entry. The id string lives here and nowhere else.
class MinesweeperGame {
  MinesweeperGame._();

  static const GameModel config = GameModel(
    id: 'minesweeper',
    name: 'Minesweeper',
    description:
        'Read the numbers, flag what you can prove, and clear the field '
        'without guessing. The first click is always safe.',
    icon: Icons.flag_outlined,
    route: '/minesweeper',
    accentColor: AppTheme.accentRed,
    sectionId: 'puzzle',
    createPage: _createPage,
    nameL10n: _name,
    descriptionL10n: _description,
  );

  static Widget _createPage() => const MinesweeperPage();

  static String _name(AppLocalizations l10n) => l10n.gameNameMinesweeper;

  static String _description(AppLocalizations l10n) =>
      l10n.gameDescriptionMinesweeper;
}
