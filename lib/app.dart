import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'core/game_registry.dart';
import 'games/ricochet/ricochet_help_page.dart';
import 'l10n/app_localizations.dart';
import 'pages/about_page.dart';
import 'pages/appearance_settings_page.dart';
import 'pages/gameplay_settings_page.dart';
import 'pages/overview/overview_page.dart';
import 'providers/app_state.dart';
import 'theme/theme.dart';

/// Builds the app's router.
///
/// Game routes are generated from [GameRegistry.all], so adding a game never
/// means editing a switch here. Only the shell's own pages, and pages a game
/// pushes on top of itself, are listed by hand.
///
/// One router per app instance rather than a shared global: a router remembers
/// where it is, and a global one would carry that across a hot restart or from
/// one test to the next.
GoRouter createAppRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'overview',
      builder: (_, _) => const OverviewPage(),
    ),
    GoRoute(
      path: '/appearance-settings',
      name: 'appearance-settings',
      builder: (_, _) => const AppearanceSettingsPage(),
    ),
    GoRoute(
      path: '/gameplay-settings',
      name: 'gameplay-settings',
      builder: (_, _) => const GameplaySettingsPage(),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (_, _) => const AboutPage(),
    ),
    GoRoute(
      path: '/ricochet/help',
      name: 'ricochet-help',
      builder: (_, _) => const RicochetHelpPage(),
    ),
    ...GameRegistry.all.map(
      (game) => GoRoute(
        path: game.route,
        name: game.id,
        builder: (_, _) => game.createPage(),
      ),
    ),
  ],
);

class GameCollectionApp extends StatefulWidget {
  const GameCollectionApp({super.key});

  @override
  State<GameCollectionApp> createState() => _GameCollectionAppState();
}

class _GameCollectionAppState extends State<GameCollectionApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp.router(
      title: AppConstants.appName,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appState.themeMode,
      locale: appState.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Desktop builds get mouse and trackpad dragging, which Flutter leaves off by
/// default — without it a scroll view cannot be dragged with the mouse.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
