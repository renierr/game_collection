import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/frame_clock.dart';
import '../../core/game_page_state.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/game_audio.dart';
import '../../services/wake_lock_guard.dart';
import '../../widgets/directional_input.dart';
import '../../widgets/game_hud.dart';
import '../../widgets/game_layout.dart';
import '../../widgets/game_result_overlay.dart';
import '../../widgets/game_stat.dart';
import '../../widgets/responsive_layout.dart';
import 'engine/snake_audio.dart';
import 'engine/snake_engine.dart';
import 'snake_colors.dart';
import 'widgets/snake_board.dart';

/// Snake's entry point: owns the engine, the frame clock and the page chrome.
///
/// The board repaints from `engine.frames` and the HUD rebuilds from
/// `engine.hud`, so a running game never rebuilds the widget tree per frame.
class SnakePage extends StatefulWidget {
  const SnakePage({super.key});

  @override
  State<SnakePage> createState() => _SnakePageState();
}

class _SnakePageState extends State<SnakePage>
    with
        SingleTickerProviderStateMixin,
        DisposeCleanup,
        WidgetsBindingObserver {
  final SnakeEngine _engine = SnakeEngine();
  final WakeLockGuard _wakeLock = WakeLockGuard();
  late final FrameClock _clock = FrameClock(this, _onTick);

  /// Mirrored from settings in [build] so the per-frame tick never does a
  /// provider lookup.
  bool _keepScreenAwake = true;
  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onDispose(() => WidgetsBinding.instance.removeObserver(this));
    onDispose(_clock.dispose);
    onDispose(_wakeLock.release);
    onDispose(_engine.dispose);
    onDispose(() => unawaited(GameAudio.instance.releaseAll()));
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await SnakeSfx.load();
    await _engine.start();
    if (mounted) _clock.start();
  }

  void _onTick(double dt) {
    _engine.update(dt);
    _wakeLock.want(_keepScreenAwake && _engine.hasStarted);
  }

  /// A backgrounded game must not keep walking into a wall while the player
  /// cannot see it.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _clock.start();
    } else {
      if (_engine.hasStarted && !_engine.isPaused) _engine.togglePause();
      _clock.stop();
      _wakeLock.release();
    }
  }

  void _turn(GameDirection direction) {
    _engine.turn(direction);
    if (_haptics) HapticFeedback.selectionClick();
  }

  void _tapBoard() {
    if (!_engine.hasStarted) {
      _engine.startRun();
    } else {
      _engine.togglePause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    _keepScreenAwake = appState.keepScreenAwake;
    _haptics = appState.hapticsEnabled;
    GameAudio.instance.setMasterVolume(appState.effectiveVolume);

    return GameLayout(
      title: l10n.gameNameSnake,
      backgroundColor: SnakeColors.page,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hud = AnimatedBuilder(
            animation: _engine.hud,
            builder: (context, _) => GameHud(
              vertical: constraints.canSplit,
              stats: [
                GameStat(
                  label: l10n.commonScore,
                  value: '${_engine.score}',
                  color: SnakeColors.score,
                  centered: true,
                ),
                GameStat(
                  label: l10n.commonBest,
                  value: '${_engine.best}',
                  color: SnakeColors.best,
                  centered: true,
                ),
                GameStat(
                  label: l10n.snakeLength,
                  value: '${_engine.length}',
                  centered: true,
                ),
                GameStat(
                  label: l10n.snakeSpeed,
                  value: _engine.speed.toStringAsFixed(1),
                  centered: true,
                ),
              ],
              actions: [
                GameHudAction(
                  icon: _engine.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  tooltip: _engine.isPaused
                      ? l10n.commonResume
                      : l10n.commonPause,
                  onPressed: _engine.hasStarted || _engine.isPaused
                      ? _engine.togglePause
                      : null,
                ),
                GameHudAction(
                  icon: Icons.restart_alt_rounded,
                  tooltip: l10n.commonNewGame,
                  onPressed: _engine.newGame,
                ),
                GameHudAction(
                  icon: appState.soundEnabled
                      ? Icons.volume_up
                      : Icons.volume_off,
                  tooltip: appState.soundEnabled
                      ? l10n.commonMute
                      : l10n.commonUnmute,
                  onPressed: () =>
                      appState.setSoundEnabled(!appState.soundEnabled),
                ),
              ],
            ),
          );

          final board = Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: ConstrainedBox(
                // A 19×19 grid does not get better with a whole desktop
                // window behind it; past this the cells just get fat.
                constraints: const BoxConstraints(maxWidth: 640),
                child: DirectionalInput(
                  onDirection: _turn,
                  onTap: _tapBoard,
                  extraKeys: {
                    LogicalKeyboardKey.space: _tapBoard,
                    LogicalKeyboardKey.escape: _engine.togglePause,
                  },
                  child: Stack(
                    children: [
                      SnakeBoard(engine: _engine),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _engine.hud,
                          builder: (context, _) => _SnakeOverlay(
                            engine: _engine,
                            onNewGame: _engine.newGame,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          if (constraints.canSplit) {
            return Row(
              children: [
                Expanded(child: board),
                SizedBox(
                  width: math.min(220, constraints.maxWidth * 0.28),
                  child: hud,
                ),
              ],
            );
          }
          return Column(
            children: [
              hud,
              Expanded(child: board),
            ],
          );
        },
      ),
    );
  }
}

/// The start prompt, the paused veil and the game-over panel.
class _SnakeOverlay extends StatelessWidget {
  final SnakeEngine engine;
  final VoidCallback onNewGame;

  const _SnakeOverlay({required this.engine, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (engine.isDead) {
      return GameResultOverlay(
        title: l10n.commonGameOver,
        headline: '${engine.score}',
        headlineColor: SnakeColors.score,
        subtitle: engine.score >= engine.best && engine.score > 0
            ? l10n.commonNewBest
            : l10n.commonBestScore(engine.best),
        footnote: l10n.snakeFinalLength(engine.length),
        scrimColor: SnakeColors.board,
        actions: [
          GameResultAction(
            label: l10n.commonNewGame,
            icon: Icons.restart_alt_rounded,
            onPressed: onNewGame,
          ),
        ],
      );
    }

    if (!engine.hasStarted) {
      return _Veil(message: l10n.snakeTapToStart, icon: Icons.swipe_rounded);
    }
    if (engine.isPaused) {
      return _Veil(message: l10n.commonPaused, icon: Icons.pause_rounded);
    }
    return const IgnorePointer(child: SizedBox.shrink());
  }
}

/// A dimmed message over the board. Deliberately not a dialog: the player must
/// still see the position they are about to resume into.
class _Veil extends StatelessWidget {
  final String message;
  final IconData icon;

  const _Veil({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: ColoredBox(
        color: SnakeColors.board.withValues(alpha: 0.66),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: Colors.white70),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
