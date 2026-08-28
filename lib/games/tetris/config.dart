import 'package:flutter/material.dart';

import '../../core/game_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import 'tetris_page.dart';

/// Tetris's registry entry. The id string lives here and nowhere else.
class TetrisGame {
  TetrisGame._();

  static const GameModel config = GameModel(
    id: 'tetris',
    name: 'Tetris',
    description:
        'Stack falling blocks into full rows. Modern rules throughout: wall '
        'kicks, a hold slot, a ghost drop and a seven-bag shuffle.',
    icon: Icons.view_week_outlined,
    route: '/tetris',
    accentColor: AppTheme.accentPurple,
    sectionId: 'arcade',
    createPage: _createPage,
    nameL10n: _name,
    descriptionL10n: _description,
  );

  static Widget _createPage() => const TetrisPage();

  static String _name(AppLocalizations l10n) => l10n.gameNameTetris;

  static String _description(AppLocalizations l10n) =>
      l10n.gameDescriptionTetris;
}
