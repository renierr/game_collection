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
import 'engine/tetris_audio.dart';
import 'engine/tetris_engine.dart';
import 'tetris_colors.dart';
import 'widgets/tetris_board.dart';
import 'widgets/tetris_controls.dart';
import 'widgets/tetris_side_panel.dart';

/// Tetris's entry point: owns the engine, the frame clock and the page chrome.
///
/// The board repaints from `engine.frames` and the HUD rebuilds from
/// `engine.hud`, so a piece falling at level 15 never rebuilds the widget tree.
class TetrisPage extends StatefulWidget {
  const TetrisPage({super.key});

  @override
  State<TetrisPage> createState() => _TetrisPageState();
}

class _TetrisPageState extends State<TetrisPage>
    with
        SingleTickerProviderStateMixin,
        DisposeCleanup,
        WidgetsBindingObserver {
  final TetrisEngine _engine = TetrisEngine();
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
    onDispose(() => unawaited(_engine.saveNow()));
    onDispose(_engine.dispose);
    onDispose(() => unawaited(GameAudio.instance.releaseAll()));
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await TetrisSfx.load();
    await _engine.start();
    if (mounted) _clock.start();
  }

  void _onTick(double dt) {
    _engine.update(dt);
    _wakeLock.want(_keepScreenAwake && !_engine.isOver && !_engine.isPaused);
  }

  /// A backgrounded game must not keep dropping pieces the player cannot see.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _clock.start();
    } else {
      if (!_engine.isOver && !_engine.isPaused) _engine.togglePause();
      _clock.stop();
      _wakeLock.release();
    }
  }

  void _onDirection(GameDirection direction) {
    switch (direction) {
      case GameDirection.left:
        _engine.moveLeft();
      case GameDirection.right:
        _engine.moveRight();
      case GameDirection.down:
        _engine.softDrop();
      case GameDirection.up:
        _engine.rotate(clockwise: true);
    }
  }

  void _hardDrop() {
    _engine.hardDrop();
    if (_haptics) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    _keepScreenAwake = appState.keepScreenAwake;
    _haptics = appState.hapticsEnabled;
    GameAudio.instance.setMasterVolume(appState.effectiveVolume);

    return GameLayout(
      title: l10n.gameNameTetris,
      backgroundColor: TetrisColors.page,
      child: DirectionalInput(
        onDirection: _onDirection,
        // The board owns taps and drags itself, so this layer is keyboard only.
        enableSwipe: false,
        allowKeyRepeat: true,
        extraKeys: {
          LogicalKeyboardKey.space: _hardDrop,
          LogicalKeyboardKey.keyZ: () => _engine.rotate(clockwise: false),
          LogicalKeyboardKey.keyX: () => _engine.rotate(clockwise: true),
          LogicalKeyboardKey.keyC: _engine.holdPiece,
          LogicalKeyboardKey.shiftLeft: _engine.holdPiece,
          LogicalKeyboardKey.escape: _engine.togglePause,
          LogicalKeyboardKey.keyP: _engine.togglePause,
        },
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
                    color: TetrisColors.score,
                    centered: constraints.canSplit,
                  ),
                  GameStat(
                    label: l10n.commonBest,
                    value: '${_engine.best}',
                    color: TetrisColors.best,
                    centered: constraints.canSplit,
                  ),
                  GameStat(
                    label: l10n.tetrisLines,
                    value: '${_engine.lines}',
                    centered: constraints.canSplit,
                  ),
                  GameStat(
                    label: l10n.tetrisLevel,
                    value: '${_engine.level}',
                    centered: constraints.canSplit,
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
                    onPressed: _engine.isOver ? null : _engine.togglePause,
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

            final board = Center(
              child: Stack(
                children: [
                  TetrisBoard(engine: _engine),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _engine.hud,
                      builder: (context, _) => _TetrisOverlay(
                        engine: _engine,
                        onNewGame: _engine.newGame,
                        onResume: _engine.togglePause,
                      ),
                    ),
                  ),
                ],
              ),
            );

            final controls = AnimatedBuilder(
              animation: _engine.hud,
              builder: (context, _) => TetrisControls(
                onLeft: _engine.moveLeft,
                onRight: _engine.moveRight,
                onRotateCcw: () => _engine.rotate(clockwise: false),
                onRotateCw: () => _engine.rotate(clockwise: true),
                onSoftDrop: _engine.softDrop,
                onHardDrop: _hardDrop,
                onHold: _engine.holdPiece,
                holdEnabled: !_engine.holdUsed && !_engine.isOver,
              ),
            );

            if (constraints.canSplit) {
              return Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: board,
                    ),
                  ),
                  SizedBox(
                    width: math.min(230, constraints.maxWidth * 0.3),
                    child: Column(
                      children: [
                        Expanded(child: hud),
                        TetrisSidePanel(engine: _engine, vertical: true),
                        controls,
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                // Leave room for the floating back button in the top-left.
                const SizedBox(height: 44),
                hud,
                TetrisSidePanel(engine: _engine, vertical: false),
                Expanded(child: board),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The paused veil and the game-over panel.
class _TetrisOverlay extends StatelessWidget {
  final TetrisEngine engine;
  final VoidCallback onNewGame;
  final VoidCallback onResume;

  const _TetrisOverlay({
    required this.engine,
    required this.onNewGame,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (engine.isOver) {
      return GameResultOverlay(
        title: l10n.commonGameOver,
        headline: '${engine.score}',
        headlineColor: TetrisColors.score,
        subtitle: engine.score >= engine.best && engine.score > 0
            ? l10n.commonNewBest
            : l10n.commonBestScore(engine.best),
        footnote: l10n.tetrisClearedLines(engine.lines, engine.level),
        scrimColor: TetrisColors.board,
        actions: [
          GameResultAction(
            label: l10n.commonNewGame,
            icon: Icons.restart_alt_rounded,
            onPressed: onNewGame,
          ),
        ],
      );
    }

    if (!engine.isPaused) {
      return const IgnorePointer(child: SizedBox.shrink());
    }
    return ColoredBox(
      color: TetrisColors.board.withValues(alpha: 0.72),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_rounded, size: 40, color: Colors.white70),
              const SizedBox(height: 10),
              Text(
                l10n.commonPaused,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.commonResume),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
