import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_collection/app.dart';
import 'package:game_collection/games/ricochet/config.dart';
import 'package:game_collection/games/ricochet/widgets/ricochet_action_bar.dart';
import 'package:game_collection/games/ricochet/widgets/ricochet_board.dart';
import 'package:game_collection/l10n/app_localizations.dart';
import 'package:game_collection/providers/app_state.dart';
import 'package:game_collection/services/database_service.dart';
import 'package:game_collection/services/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Walks the real app — router, database, overview, game page — rather than
/// widgets in isolation, so a broken wiring between them cannot pass.
///
/// Two constraints shape how these tests drive the app:
///
/// * `testWidgets` runs its body in a fake-async zone, and sqflite's real file
///   I/O never completes there. Anything that waits on the database is either
///   done in `setUp` (a real zone) or wrapped in [letAsyncWorkFinish], which
///   uses `runAsync` to step outside the fake clock.
/// * A game page runs a `Ticker` that never goes idle, so `pumpAndSettle` would
///   hang on it. Frames are advanced explicitly with [pumpFrames].
void main() {
  late AppLocalizations l10n;
  late SettingsService settings;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() async {
    // A fresh in-memory database per test: no test may touch the real saves.
    DatabaseService.instance.dbPathOverride = inMemoryDatabasePath;
    await DatabaseService.instance.database;
    settings = await SettingsService.init();
  });

  tearDown(() async {
    await DatabaseService.instance.close();
  });

  Future<void> pumpFrames(WidgetTester tester, [int frames = 16]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Lets pending real-async work — a database read, an engine bootstrap —
  /// actually run, then draws the result.
  Future<void> letAsyncWorkFinish(WidgetTester tester, [int ms = 150]) async {
    await tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: ms)),
    );
    await pumpFrames(tester, 4);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(settings),
        child: const GameCollectionApp(),
      ),
    );
    await letAsyncWorkFinish(tester);
  }

  Future<void> openRicochet(WidgetTester tester) async {
    await tester.tap(find.text(l10n.gameNameRicochet));
    await pumpFrames(tester, 24);
    // The page's bootstrap builds the audio clips and asks the store for a
    // saved run before the first board exists.
    await letAsyncWorkFinish(tester, 400);
    await pumpFrames(tester, 24);
  }

  testWidgets('the overview lists the collection', (tester) async {
    await pumpApp(tester);
    expect(find.text(l10n.gameNameRicochet), findsOneWidget);
    expect(find.text(l10n.sectionTitleArcade), findsOneWidget);
    expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
  });

  testWidgets('search filters the collection', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'zzz');
    await pumpFrames(tester, 8);
    expect(find.text(l10n.overviewNoGamesFound), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'rico');
    await pumpFrames(tester, 8);
    expect(find.text(l10n.gameNameRicochet), findsOneWidget);
  });

  testWidgets('settings and about are reachable', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await pumpFrames(tester, 24);
    expect(find.text(l10n.appearanceTitle), findsOneWidget);
    expect(find.text(l10n.gameplayTitle), findsOneWidget);

    await tester.tap(find.text(l10n.aboutTitle).first);
    await pumpFrames(tester, 24);
    await letAsyncWorkFinish(tester);
    expect(find.text('AGPL-3.0-or-later'), findsOneWidget);
  });

  testWidgets('opening Ricochet renders a live board', (tester) async {
    await pumpApp(tester);
    await openRicochet(tester);

    expect(find.byType(RicochetBoard), findsOneWidget);
    expect(find.byType(RicochetActionBar), findsOneWidget);

    // The HUD's four readouts, which only appear once the engine has started.
    for (final label in [
      l10n.ricochetScore,
      l10n.ricochetBest,
      l10n.ricochetLevel,
      l10n.ricochetBalls,
    ]) {
      expect(find.text(label.toUpperCase()), findsOneWidget);
    }

    // Letting the frame clock run catches an exception thrown from the painter
    // or the simulation, which a single pump would miss.
    await pumpFrames(tester, 60);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging the board fires a volley', (tester) async {
    await pumpApp(tester);
    await openRicochet(tester);

    final board = tester.getRect(find.byType(RicochetBoard));
    final gesture = await tester.startGesture(board.center);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveTo(Offset(board.center.dx + 30, board.top + 40));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();

    // Balls launch staggered, so the volley needs a moment to get going.
    await pumpFrames(tester, 120);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the power-up menu opens and leads to the help page', (
    tester,
  ) async {
    await pumpApp(tester);
    await openRicochet(tester);

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await pumpFrames(tester, 32);
    expect(find.text(l10n.ricochetPowerBalls), findsOneWidget);
    expect(find.text(l10n.ricochetPowerClearRow), findsOneWidget);

    await tester.tap(find.text(l10n.ricochetHowToPlay));
    await pumpFrames(tester, 32);
    expect(find.text(l10n.ricochetHelpTitle), findsOneWidget);
  });

  testWidgets('a power-up from the menu reaches the engine', (tester) async {
    await pumpApp(tester);
    await openRicochet(tester);

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await pumpFrames(tester, 32);
    await tester.tap(find.text(l10n.ricochetPowerBalls));
    await pumpFrames(tester, 32);

    // A fresh run starts with one ball, so +10 Balls must read 11 in the HUD.
    expect(find.text('11'), findsOneWidget);
  });

  test('the route is derived from the game id', () {
    expect(RicochetGame.config.route, '/${RicochetGame.config.id}');
  });
}
