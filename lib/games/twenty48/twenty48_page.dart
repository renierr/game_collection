import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/game_page_state.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/game_audio.dart';
import '../../widgets/directional_input.dart';
import '../../widgets/game_hud.dart';
import '../../widgets/game_layout.dart';
import '../../widgets/game_result_overlay.dart';
import '../../widgets/game_stat.dart';
import '../../widgets/responsive_layout.dart';
import 'engine/twenty48_audio.dart';
import 'engine/twenty48_engine.dart';
import 'twenty48_colors.dart';
import 'widgets/twenty48_board.dart';

/// 2048's entry point: owns the engine, maps input onto it, and composes the
/// board, HUD and overlays.
///
/// There is no frame clock. The engine is a [ChangeNotifier] that fires once
/// per move, which is the only moment anything on screen can change.
class Twenty48Page extends StatefulWidget {
  const Twenty48Page({super.key});

  @override
  State<Twenty48Page> createState() => _Twenty48PageState();
}

class _Twenty48PageState extends State<Twenty48Page> with DisposeCleanup {
  final Twenty48Engine _engine = Twenty48Engine();

  /// A win is announced once. Dismissing it lets the run continue, because
  /// hitting 2048 with room left on the board is a milestone, not an ending.
  bool _winDismissed = false;

  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    onDispose(_engine.dispose);
    onDispose(() => unawaited(GameAudio.instance.releaseAll()));
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Twenty48Sfx.load();
    await _engine.start();
    if (mounted) setState(() => _winDismissed = _engine.won);
  }

  void _move(GameDirection direction) {
    final wasWon = _engine.won;
    if (!_engine.move(direction)) return;

    final merged = _engine.lastMergedValue;
    if (merged > 0) {
      GameAudio.instance.play(Twenty48Sfx.merge(merged));
      if (_haptics) HapticFeedback.selectionClick();
    } else {
      GameAudio.instance.play(Twenty48Sfx.slide);
    }
    if (_engine.won && !wasWon) GameAudio.instance.play(Twenty48Sfx.win);
    if (_engine.isStuck) GameAudio.instance.play(Twenty48Sfx.gameOver);
  }

  void _undo() {
    if (!_engine.canUndo) return;
    _engine.undoMove();
    GameAudio.instance.play(Twenty48Sfx.undo);
  }

  void _newGame() {
    _engine.newGame();
    setState(() => _winDismissed = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    _haptics = appState.hapticsEnabled;
    GameAudio.instance.setMasterVolume(appState.effectiveVolume);

    return GameLayout(
      title: l10n.gameName2048,
      backgroundColor: Twenty48Colors.page,
      child: AnimatedBuilder(
        animation: _engine,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final hud = GameHud(
              vertical: constraints.canSplit,
              stats: [
                GameStat(
                  label: l10n.commonScore,
                  value: '${_engine.score}',
                  centered: constraints.canSplit,
                ),
                GameStat(
                  label: l10n.commonBest,
                  value: '${_engine.best}',
                  color: Twenty48Colors.best,
                  centered: constraints.canSplit,
                ),
                GameStat(
                  label: l10n.twenty48Moves,
                  value: '${_engine.moves}',
                  centered: constraints.canSplit,
                ),
                GameStat(
                  label: l10n.twenty48Highest,
                  value: '${_engine.highestValue}',
                  color: Twenty48Colors.score,
                  centered: constraints.canSplit,
                ),
              ],
              actions: [
                GameHudAction(
                  icon: Icons.undo_rounded,
                  tooltip: l10n.twenty48Undo,
                  onPressed: _engine.canUndo ? _undo : null,
                ),
                GameHudAction(
                  icon: Icons.restart_alt_rounded,
                  tooltip: l10n.commonNewGame,
                  onPressed: _newGame,
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
            );

            final board = Padding(
              // A 4×4 grid does not benefit from a whole desktop window, so
              // the board is capped and centred while the HUD keeps the room.
              padding: const EdgeInsets.all(12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Stack(
                    children: [
                      DirectionalInput(
                        onDirection: _move,
                        child: Twenty48Board(engine: _engine),
                      ),
                      Positioned.fill(
                        child: _Overlay(
                          engine: _engine,
                          winDismissed: _winDismissed,
                          onKeepPlaying: () =>
                              setState(() => _winDismissed = true),
                          onNewGame: _newGame,
                          onUndo: _undo,
                        ),
                      ),
                    ],
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
                // Leave room for the floating back button in the top-left.
                const SizedBox(height: 44),
                hud,
                Expanded(child: board),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The win announcement and the dead-end panel, or nothing at all.
class _Overlay extends StatelessWidget {
  final Twenty48Engine engine;
  final bool winDismissed;
  final VoidCallback onKeepPlaying;
  final VoidCallback onNewGame;
  final VoidCallback onUndo;

  const _Overlay({
    required this.engine,
    required this.winDismissed,
    required this.onKeepPlaying,
    required this.onNewGame,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (engine.isStuck) {
      return GameResultOverlay(
        title: l10n.twenty48NoMovesLeft,
        headline: '${engine.score}',
        headlineColor: Twenty48Colors.score,
        subtitle: engine.score >= engine.best && engine.score > 0
            ? l10n.commonNewBest
            : l10n.commonBestScore(engine.best),
        footnote: l10n.twenty48ReachedTile(engine.highestValue),
        scrimColor: Twenty48Colors.board,
        actions: [
          GameResultAction(
            label: l10n.commonNewGame,
            icon: Icons.restart_alt_rounded,
            onPressed: onNewGame,
          ),
          if (engine.canUndo)
            GameResultAction(
              label: l10n.twenty48Undo,
              icon: Icons.undo_rounded,
              onPressed: onUndo,
            ),
        ],
      );
    }

    if (engine.won && !winDismissed) {
      return GameResultOverlay(
        title: l10n.twenty48YouWin,
        headline: '2048',
        headlineColor: Twenty48Colors.forValue(2048),
        subtitle: l10n.twenty48WinSubtitle(engine.score),
        scrimColor: Twenty48Colors.board,
        actions: [
          GameResultAction(
            label: l10n.twenty48KeepPlaying,
            icon: Icons.play_arrow_rounded,
            onPressed: onKeepPlaying,
          ),
          GameResultAction(
            label: l10n.commonNewGame,
            icon: Icons.restart_alt_rounded,
            onPressed: onNewGame,
          ),
        ],
      );
    }

    return const IgnorePointer(child: SizedBox.shrink());
  }
}
