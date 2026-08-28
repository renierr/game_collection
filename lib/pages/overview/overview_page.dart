import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../core/game_model.dart';
import '../../core/game_page_state.dart';
import '../../core/game_registry.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../widgets/section_header.dart';
import 'section_grid.dart';
import 'settings_dialog.dart';

/// The app's home screen: every registered game, grouped by section, with
/// favorites pinned on top and a search box over the lot.
class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> with DisposeCleanup {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _collapsedSections = {};

  @override
  void initState() {
    super.initState();
    onDispose(_searchController.dispose);
  }

  int _crossAxisCount(double width) {
    if (width < 400) return 1;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  double _childAspectRatio(bool compact, double width) {
    final columns = _crossAxisCount(width);
    final cardWidth = (width - 32 - (columns - 1) * 12) / columns;
    return cardWidth / (compact ? 76.0 : 155.0);
  }

  List<GameModel> _visibleGames(AppState appState, AppLocalizations l10n) {
    final query = appState.searchQuery.trim().toLowerCase();
    final games = GameRegistry.all.where((game) {
      if (query.isEmpty) return true;
      return game.localizedName(l10n).toLowerCase().contains(query) ||
          game.localizedDescription(l10n).toLowerCase().contains(query);
    }).toList();

    switch (appState.sortBy) {
      case 'name':
        games.sort(
          (a, b) => a.localizedName(l10n).compareTo(b.localizedName(l10n)),
        );
      case 'recent':
        games.sort(
          (a, b) =>
              appState.getLastUsed(b.id).compareTo(appState.getLastUsed(a.id)),
        );
    }
    return games;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final isShort = MediaQuery.sizeOf(context).height < 600;
    final appBarHeight = isShort ? 40.0 : 56.0;

    final games = _visibleGames(appState, l10n);
    final favorites = games
        .where((game) => appState.isFavorite(game.id))
        .toList();

    final grouped = <String, List<GameModel>>{};
    for (final game in games) {
      grouped.putIfAbsent(game.sectionId, () => []).add(game);
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: AppBar(
          toolbarHeight: appBarHeight,
          title: Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: isShort ? 16 : 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.tune_outlined, size: isShort ? 20 : null),
              tooltip: l10n.commonSettings,
              onPressed: () => OverviewSettingsDialog.show(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = _crossAxisCount(constraints.maxWidth);
            final aspectRatio = _childAspectRatio(
              appState.compactMode,
              constraints.maxWidth,
            );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: appState.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: l10n.overviewSearchHint,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                tooltip: l10n.commonClear,
                                onPressed: () {
                                  _searchController.clear();
                                  appState.setSearchQuery('');
                                },
                              ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                if (games.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: theme.colorScheme.onSurface.withAlpha(80),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.overviewNoGamesFound,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (favorites.isNotEmpty)
                    SectionGrid(
                      games: favorites,
                      crossAxisCount: columns,
                      compact: appState.compactMode,
                      childAspectRatio: aspectRatio,
                    ),
                  for (final entry in _orderedSections(grouped))
                    ..._sectionSlivers(
                      context,
                      entry,
                      columns,
                      appState.compactMode,
                      aspectRatio,
                      l10n,
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Registry order first, then any section a game declared that the registry
  /// does not list — so a typo'd section id still shows its games.
  List<MapEntry<String, List<GameModel>>> _orderedSections(
    Map<String, List<GameModel>> grouped,
  ) {
    final remaining = Map<String, List<GameModel>>.from(grouped);
    final ordered = <MapEntry<String, List<GameModel>>>[];
    for (final id in GameRegistry.sections.keys) {
      final games = remaining.remove(id);
      if (games != null) ordered.add(MapEntry(id, games));
    }
    ordered.addAll(remaining.entries);
    return ordered;
  }

  List<Widget> _sectionSlivers(
    BuildContext context,
    MapEntry<String, List<GameModel>> entry,
    int columns,
    bool compact,
    double aspectRatio,
    AppLocalizations l10n,
  ) {
    final section = GameRegistry.sections[entry.key];
    final isCollapsed = _collapsedSections.contains(entry.key);
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: SectionHeader(
            icon: section?.icon ?? Icons.folder_outlined,
            title: section?.localizedTitle(l10n) ?? entry.key,
            gameCount: entry.value.length,
            isCollapsed: isCollapsed,
            onToggle: () => setState(() {
              if (isCollapsed) {
                _collapsedSections.remove(entry.key);
              } else {
                _collapsedSections.add(entry.key);
              }
            }),
          ),
        ),
      ),
      if (!isCollapsed)
        SectionGrid(
          games: entry.value,
          crossAxisCount: columns,
          compact: compact,
          childAspectRatio: aspectRatio,
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
    ];
  }
}
