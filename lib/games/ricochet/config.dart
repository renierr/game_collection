import 'package:flutter/material.dart';

import '../../core/game_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import 'ricochet_page.dart';

/// Ricochet's registry entry. The id string lives here and nowhere else —
/// saves, routes and settings all read it from [config].
class RicochetGame {
  RicochetGame._();

  static const GameModel config = GameModel(
    id: 'ricochet',
    name: 'Ricochet',
    description:
        'Aim a volley of bouncing balls, crush numbered bricks, and ride '
        'endlessly through self-generating levels.',
    icon: Icons.sports_baseball_outlined,
    route: '/ricochet',
    accentColor: AppTheme.accentBlue,
    sectionId: 'arcade',
    createPage: _createPage,
    nameL10n: _name,
    descriptionL10n: _description,
  );

  static Widget _createPage() => const RicochetPage();

  static String _name(AppLocalizations l10n) => l10n.gameNameRicochet;

  static String _description(AppLocalizations l10n) =>
      l10n.gameDescriptionRicochet;
}
