import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/game_page_state.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/game_audio.dart';
import '../../widgets/game_hud.dart';
import '../../widgets/game_layout.dart';
import '../../widgets/game_result_overlay.dart';
import '../../widgets/game_stat.dart';
import '../../widgets/responsive_layout.dart';
import 'engine/minesweeper_audio.dart';
import 'engine/minesweeper_engine.dart';
import 'minesweeper_colors.dart';
import 'widgets/mine_level_picker.dart';
import 'widgets/minesweeper_board.dart';

/// Minesweeper's entry point: owns the engine, the one-second clock and the
/// reveal cascade, and composes the board, HUD and overlays.
///
/// There is no frame loop. The only continuous animation is the cascade after a
/// flood fill, which runs on a short-lived controller and stops on its own.
class MinesweeperPage extends StatefulWidget {
  const MinesweeperPage({super.key});

  @override
  State<MinesweeperPage> createState() => _MinesweeperPageState();
}

class _MinesweeperPageState extends State<MinesweeperPage>
    with SingleTickerProviderStateMixin, DisposeCleanup {
  final MinesweeperEngine _engine = MinesweeperEngine();

  late final AnimationController _cascade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  Timer? _clock;
  bool _flagMode = false;
  int _lastBatch = 0;
  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    _engine.addListener(_onEngineChanged);
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _engine.tickClock(),
    );
    onDispose(() => _engine.removeListener(_onEngineChanged));
    onDispose(() => _clock?.cancel());
    onDispose(_cascade.dispose);
    onDispose(() => unawaited(_engine.saveNow()));
    onDispose(_engine.dispose);
    onDispose(() => unawaited(GameAudio.instance.releaseAll()));
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await MinesweeperSfx.load();
    await _engine.start();
  }

  /// Restarts the cascade whenever the engine opens a new region, so each flood
  /// fill animates from its own click rather than continuing the last one.
  void _onEngineChanged() {
    if (_engine.revealBatch == _lastBatch) return;
    _lastBatch = _engine.revealBatch;
    _cascade.forward(from: 0);
    if (_haptics) HapticFeedback.selectionClick();
  }

  void _newGame([MineLevel? level]) {
    _engine.newGame(level);
    setState(() => _flagMode = false);
  }

  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    _haptics = appState.hapticsEnabled;
    GameAudio.instance.setMasterVolume(appState.effectiveVolume);

    return GameLayout(
      title: l10n.gameNameMinesweeper,
      backgroundColor: MinesweeperColors.page,
      child: AnimatedBuilder(
        animation: _engine,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final best = _engine.bestTime;
            final hud = GameHud(
              vertical: constraints.canSplit,
              stats: [
                GameStat(
                  label: l10n.minesweeperMines,
                  value: '${_engine.flagsLeft}',
                  color: MinesweeperColors.flag,
                  centered: true,
                ),
                GameStat(
                  label: l10n.minesweeperTime,
                  value: _formatTime(_engine.elapsedSeconds),
                  color: MinesweeperColors.time,
                  centered: true,
                ),
                GameStat(
                  label: l10n.commonBest,
                  value: best == null ? '—' : _formatTime(best),
                  color: MinesweeperColors.best,
                  centered: true,
                ),
              ],
              actions: [
                GameHudAction(
                  icon: _flagMode ? Icons.flag_rounded : Icons.flag_outlined,
                  tooltip: _flagMode
                      ? l10n.minesweeperFlagModeOn
                      : l10n.minesweeperFlagModeOff,
                  color: _flagMode ? MinesweeperColors.flag : null,
                  onPressed: () => setState(() => _flagMode = !_flagMode),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Stack(
                  children: [
                    // Expert is 480 tiny squares on a phone, so the board can
                    // be pinched open and panned; it starts fitted either way.
                    InteractiveViewer(
                      maxScale: 5,
                      child: AnimatedBuilder(
                        animation: _cascade,
                        builder: (context, _) => MinesweeperBoard(
                          engine: _engine,
                          flagMode: _flagMode,
                          cascadeMs:
                              _cascade.value *
                              _cascade.duration!.inMilliseconds,
                          cascadeBatch: _lastBatch,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: _MineOverlay(engine: _engine, onNewGame: _newGame),
                    ),
                  ],
                ),
              ),
            );

            final picker = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: MineLevelPicker(
                selected: _engine.level,
                onSelected: _newGame,
              ),
            );

            if (constraints.canSplit) {
              return Row(
                children: [
                  Expanded(child: board),
                  SizedBox(
                    width: math.min(240, constraints.maxWidth * 0.3),
                    child: Column(
                      children: [
                        Expanded(child: hud),
                        picker,
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                hud,
                Expanded(child: board),
                picker,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The win and loss panels, or nothing while the game is live.
class _MineOverlay extends StatelessWidget {
  final MinesweeperEngine engine;
  final ValueChanged<MineLevel?> onNewGame;

  const _MineOverlay({required this.engine, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!engine.isOver) return const IgnorePointer(child: SizedBox.shrink());

    final won = engine.outcome == MineOutcome.won;
    final best = engine.bestTime;
    return GameResultOverlay(
      title: won ? l10n.minesweeperCleared : l10n.minesweeperBoom,
      headline: _MinesweeperPageState._formatTime(engine.elapsedSeconds),
      headlineColor: won ? MinesweeperColors.best : MinesweeperColors.explosion,
      subtitle: won
          ? (engine.isRecord
                ? l10n.commonNewBest
                : l10n.minesweeperBestTime(
                    _MinesweeperPageState._formatTime(best ?? 0),
                  ))
          : l10n.minesweeperBoomSubtitle,
      footnote: l10n.minesweeperOnLevel(
        MineLevelPicker.labelFor(engine.level, l10n),
      ),
      scrimColor: MinesweeperColors.board,
      actions: [
        GameResultAction(
          label: l10n.commonNewGame,
          icon: Icons.restart_alt_rounded,
          onPressed: () => onNewGame(null),
        ),
      ],
    );
  }
}
