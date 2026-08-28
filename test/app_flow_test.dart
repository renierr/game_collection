import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_collection/app.dart';
import 'package:game_collection/core/game_registry.dart';
import 'package:game_collection/games/ricochet/config.dart';
import 'package:game_collection/games/ricochet/widgets/ricochet_action_bar.dart';
import 'package:game_collection/games/minesweeper/widgets/minesweeper_board.dart';
import 'package:game_collection/games/ricochet/widgets/ricochet_board.dart';
import 'package:game_collection/games/snake/widgets/snake_board.dart';
import 'package:game_collection/games/tetris/widgets/tetris_board.dart';
import 'package:game_collection/games/twenty48/widgets/twenty48_board.dart';
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

  /// Taps a game's card on the overview and waits for its page to come up.
  ///
  /// The card may not be built yet on a small surface, so the grid is dragged
  /// until it is rather than assuming the whole collection fits on screen.
  Future<void> openGame(WidgetTester tester, String name) async {
    final card = find.text(name);
    if (card.evaluate().isEmpty) {
      await tester.dragUntilVisible(
        card,
        find.byType(Scrollable).first,
        const Offset(0, -120),
      );
    }
    await tester.tap(card.first);
    await pumpFrames(tester, 24);
    // A page's bootstrap builds its audio clips and asks its store for a saved
    // run before the first board exists.
    await letAsyncWorkFinish(tester, 400);
    await pumpFrames(tester, 24);
  }

  Future<void> openRicochet(WidgetTester tester) =>
      openGame(tester, l10n.gameNameRicochet);

  /// Tears the app down. Every game page holds a ticker or a periodic timer, and
  /// leaving one running past the end of a test fails it.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFrames(tester, 2);
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

  testWidgets('every game page fits every phone size', (tester) async {
    // Readouts beside buttons above a board is the tightest row in the app, and
    // a debug overflow is a thrown FlutterError, so a clean takeException is the
    // assertion. Run for every game rather than the one that overflowed once.
    const sizes = [
      Size(320, 568), // smallest phone still in circulation
      Size(360, 640),
      Size(411, 731),
      Size(422, 720), // the width that first overflowed
      Size(640, 360), // landscape phone: the HUD moves beside the board
      Size(800, 600),
    ];
    addTearDown(tester.view.reset);

    for (final game in GameRegistry.all) {
      final name = game.localizedName(l10n);
      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        // Pumping an empty tree first tears down the previous app, so each size
        // starts a fresh router back on the overview.
        await closeApp(tester);
        await pumpApp(tester);
        await openGame(tester, name);
        await pumpFrames(tester, 30);
        expect(
          tester.takeException(),
          isNull,
          reason: '$name does not fit ${size.width}x${size.height}',
        );
      }
    }
    await closeApp(tester);
  });

  testWidgets('every game page survives a run of frames', (tester) async {
    // Catches an exception thrown from a painter or a simulation once the clock
    // is running, which a single pump would miss.
    for (final game in GameRegistry.all) {
      await closeApp(tester);
      await pumpApp(tester);
      await openGame(tester, game.localizedName(l10n));
      await pumpFrames(tester, 240);
      expect(
        tester.takeException(),
        isNull,
        reason: '${game.id} threw while running',
      );
    }
    await closeApp(tester);
  });

  testWidgets('2048 merges a pair on a swipe', (tester) async {
    await pumpApp(tester);
    await openGame(tester, l10n.gameName2048);

    // A fresh board holds two tiles worth 2 or 4. Swiping every direction in
    // turn is guaranteed to bring them together and score.
    for (final offset in const [
      Offset(0, -160),
      Offset(-160, 0),
      Offset(0, 160),
      Offset(160, 0),
    ]) {
      await tester.drag(find.byType(Twenty48Board), offset);
      await pumpFrames(tester, 20);
    }
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.commonScore.toUpperCase()), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Minesweeper uncovers a square on a tap', (tester) async {
    await pumpApp(tester);
    await openGame(tester, l10n.gameNameMinesweeper);

    await tester.tap(find.byType(MinesweeperBoard));
    await pumpFrames(tester, 40);
    expect(tester.takeException(), isNull);
    // The clock only starts once a square is uncovered, so a running clock is
    // proof the tap reached the engine.
    expect(find.text(l10n.minesweeperMines.toUpperCase()), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Tetris rotates a piece on a tap', (tester) async {
    await pumpApp(tester);
    await openGame(tester, l10n.gameNameTetris);

    await tester.tap(find.byType(TetrisBoard));
    await pumpFrames(tester, 30);
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.tetrisHold.toUpperCase()), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Snake starts on a swipe', (tester) async {
    await pumpApp(tester);
    await openGame(tester, l10n.gameNameSnake);
    expect(find.text(l10n.snakeTapToStart), findsOneWidget);

    await tester.drag(find.byType(SnakeBoard), const Offset(0, -120));
    await pumpFrames(tester, 60);
    expect(tester.takeException(), isNull);
    // The start prompt is gone once the run is under way.
    expect(find.text(l10n.snakeTapToStart), findsNothing);
    await closeApp(tester);
  });

  test('the route is derived from the game id', () {
    expect(RicochetGame.config.route, '/${RicochetGame.config.id}');
  });
}
