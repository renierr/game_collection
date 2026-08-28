import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app.dart';
import 'core/game_registry.dart';
import 'helpers/debug_log.dart';
import 'providers/app_state.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GameCollectionBootstrap());
}

/// Renders a splash immediately and moves startup I/O behind the first frame,
/// so slow storage or a failure at boot never leaves the user on a blank screen.
class GameCollectionBootstrap extends StatefulWidget {
  const GameCollectionBootstrap({super.key});

  @override
  State<GameCollectionBootstrap> createState() =>
      _GameCollectionBootstrapState();
}

class _GameCollectionBootstrapState extends State<GameCollectionBootstrap> {
  AppState? _appState;
  List<SingleChildWidget>? _gameProviders;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      await DatabaseService.instance.database;
      final settings = await SettingsService.init();
      final gameProviders = GameRegistry.all
          .map((game) => game.stateProviders)
          .nonNulls
          .expand((build) => build())
          .toList();
      if (!mounted) return;
      setState(() {
        _appState = AppState(settings);
        _gameProviders = gameProviders;
      });
    } catch (e) {
      errorLog('[Bootstrap] Startup failed: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = _appState;
    if (appState == null) {
      // The stored theme lives in the database that is still opening, so the
      // splash follows the platform brightness.
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: _BootstrapSplash(error: _error),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ...?_gameProviders,
      ],
      child: const GameCollectionApp(),
    );
  }
}

/// Shown while startup I/O runs, and turned into the failure message if it
/// throws. Cannot be localized — the locale is loaded by the work it waits on.
class _BootstrapSplash extends StatelessWidget {
  final Object? error;

  const _BootstrapSplash({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.colorScheme.error,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Startup failed: $error',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videogame_asset_rounded,
                      size: 48,
                      color: AppTheme.accentBlue,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.accentBlue,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
