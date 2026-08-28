import 'package:flutter/material.dart';

import '../games/ricochet/config.dart';
import '../l10n/app_localizations.dart';
import 'game_model.dart';

/// The single list every other part of the app is generated from: the routes in
/// `app.dart`, the provider list in `main.dart` and the overview grid.
///
/// Adding a game means writing its `config.dart` and adding one line here.
class GameRegistry {
  GameRegistry._();

  static const Map<String, GameSection> sections = {
    'arcade': GameSection(
      id: 'arcade',
      title: 'Arcade',
      icon: Icons.videogame_asset_outlined,
      titleL10n: _arcadeTitle,
    ),
    'puzzle': GameSection(
      id: 'puzzle',
      title: 'Puzzle',
      icon: Icons.extension_outlined,
      titleL10n: _puzzleTitle,
    ),
  };

  static const List<GameModel> all = [RicochetGame.config];

  static String _arcadeTitle(AppLocalizations l10n) => l10n.sectionTitleArcade;

  static String _puzzleTitle(AppLocalizations l10n) => l10n.sectionTitlePuzzle;
}
