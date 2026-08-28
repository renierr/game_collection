import 'package:flutter/material.dart';

import '../../core/game_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import 'twenty48_page.dart';

/// 2048's registry entry.
///
/// The folder is spelled out because a Dart identifier cannot start with a
/// digit; the id, which is what saves and routes are keyed by, is the real
/// name.
class Twenty48Game {
  Twenty48Game._();

  static const GameModel config = GameModel(
    id: '2048',
    name: '2048',
    description:
        'Swipe to slide the board, merge equal tiles, and chase a single '
        '2048 out of a grid that keeps filling up.',
    icon: Icons.grid_4x4,
    route: '/2048',
    accentColor: AppTheme.accentAmber,
    sectionId: 'puzzle',
    createPage: _createPage,
    nameL10n: _name,
    descriptionL10n: _description,
  );

  static Widget _createPage() => const Twenty48Page();

  static String _name(AppLocalizations l10n) => l10n.gameName2048;

  static String _description(AppLocalizations l10n) => l10n.gameDescription2048;
}
