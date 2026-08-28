import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_collection/core/game_registry.dart';
import 'package:game_collection/games/ricochet/ricochet_help_page.dart';
import 'package:game_collection/l10n/app_localizations.dart';

Widget wrap(Widget child) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets('every registered game has a localized name in both locales', (
    tester,
  ) async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final game in GameRegistry.all) {
        expect(game.localizedName(l10n), isNotEmpty);
        expect(game.localizedDescription(l10n), isNotEmpty);
      }
      for (final section in GameRegistry.sections.values) {
        expect(section.localizedTitle(l10n), isNotEmpty);
      }
    }
  });

  test('every game declares a section the registry knows', () {
    for (final game in GameRegistry.all) {
      expect(
        GameRegistry.sections.containsKey(game.sectionId),
        isTrue,
        reason: '${game.id} points at unknown section "${game.sectionId}"',
      );
    }
  });

  test('game ids and routes are unique', () {
    final ids = GameRegistry.all.map((g) => g.id).toSet();
    final routes = GameRegistry.all.map((g) => g.route).toSet();
    expect(ids.length, GameRegistry.all.length);
    expect(routes.length, GameRegistry.all.length);
  });

  testWidgets('the tile legend renders every tile', (tester) async {
    // The legend is a long scroll; a tall surface lets every row build so the
    // test checks the content rather than the viewport.
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const RicochetHelpPage()));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final name in [
      l10n.ricochetTileBrick,
      l10n.ricochetTileBomb,
      l10n.ricochetTileGift,
      l10n.ricochetTileMult,
      l10n.ricochetTilePierce,
      l10n.ricochetTileBlast,
      l10n.ricochetTileRamp,
      l10n.ricochetTileOrb,
      l10n.ricochetTilePickup,
    ]) {
      expect(find.text(name), findsOneWidget, reason: 'missing "$name"');
    }
  });
}
