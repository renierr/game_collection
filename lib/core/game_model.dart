import 'package:flutter/material.dart';
import 'package:provider/single_child_widget.dart';

import '../l10n/app_localizations.dart';

/// Resolves a localized string from the active [AppLocalizations]. Declared in
/// each game's `config.dart` so localization stays self-contained — it takes
/// [AppLocalizations], never a `BuildContext`.
typedef GameL10nResolver = String Function(AppLocalizations l10n);

/// Metadata for one game in the collection. Every game exposes exactly one
/// `const`/`final` [GameModel] from its `config.dart`; the registry, the router
/// and the overview grid are all generated from that list.
class GameModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String route;
  final Color accentColor;
  final String sectionId;

  /// Built by the router when the game's route is pushed.
  final Widget Function() createPage;

  /// Game-scoped [ChangeNotifier]s, auto-collected into the app's
  /// `MultiProvider` in `main.dart`. Registering here keeps the shell from
  /// importing any game state directly.
  final List<SingleChildWidget> Function()? stateProviders;

  final GameL10nResolver? nameL10n;
  final GameL10nResolver? descriptionL10n;

  const GameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.route,
    required this.accentColor,
    required this.sectionId,
    required this.createPage,
    this.stateProviders,
    this.nameL10n,
    this.descriptionL10n,
  });

  String localizedName(AppLocalizations l10n) => nameL10n?.call(l10n) ?? name;

  String localizedDescription(AppLocalizations l10n) =>
      descriptionL10n?.call(l10n) ?? description;
}

/// A group of games in the overview.
class GameSection {
  final String id;
  final String title;
  final IconData icon;
  final GameL10nResolver? titleL10n;

  const GameSection({
    required this.id,
    required this.title,
    required this.icon,
    this.titleL10n,
  });

  String localizedTitle(AppLocalizations l10n) =>
      titleL10n?.call(l10n) ?? title;
}
