import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/game_page_state.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/game_audio.dart';
import '../../widgets/game_layout.dart';
import '../../widgets/responsive_layout.dart';
import 'engine/ricochet_audio.dart';
import 'engine/ricochet_engine.dart';
import 'engine/ricochet_strings.dart';
import 'ricochet_colors.dart';
import 'widgets/game_over_overlay.dart';
import 'widgets/power_menu_sheet.dart';
import 'widgets/ricochet_action_bar.dart';
import 'widgets/ricochet_board.dart';
import 'widgets/ricochet_hud.dart';

/// Ricochet's entry point: owns the engine, the frame clock and the page
/// chrome, and composes the board, HUD and overlays. All game logic lives in
/// the engine — this page only drives and presents it.
class RicochetPage extends StatefulWidget {
  const RicochetPage({super.key});

  @override
  State<RicochetPage> createState() => _RicochetPageState();
}

class _RicochetPageState extends State<RicochetPage>
    with
        SingleTickerProviderStateMixin,
        DisposeCleanup,
        WidgetsBindingObserver {
  final RicochetEngine _engine = RicochetEngine();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  /// Keeps a volley resolving while the app is backgrounded and the Ticker is
  /// silenced — a turn can run for tens of seconds with no input, and losing it
  /// to a screen lock would be indistinguishable from a crash.
  Timer? _backgroundTicker;
  bool _wakeLockHeld = false;

  /// Mirrored from settings in [build] so the per-frame tick never does a
  /// provider lookup.
  bool _keepScreenAwake = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
    onDispose(() => WidgetsBinding.instance.removeObserver(this));
    onDispose(_ticker.dispose);
    onDispose(_stopBackgroundTicker);
    onDispose(_releaseWakeLock);
    onDispose(_engine.dispose);
    onDispose(() => unawaited(GameAudio.instance.releaseAll()));
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await RicochetSfx.load();
    await _engine.start();
    if (!mounted) return;
    _lastTick = Duration.zero;
    _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The engine paints its own toasts and banners, so it needs the localized
    // text; rebuilding here picks up a locale switch without restarting a run.
    _engine.strings = _buildStrings(AppLocalizations.of(context));
  }

  RicochetStrings _buildStrings(AppLocalizations l10n) => RicochetStrings(
    pierceArmed: l10n.ricochetToastPierceArmed,
    bombArmed: l10n.ricochetToastBombArmed,
    recalled: l10n.ricochetToastRecalled,
    rowCleared: l10n.ricochetToastRowCleared,
    plusOneBall: l10n.ricochetToastPlusOneBall,
    dragToAim: l10n.ricochetHintDragToAim,
    pierceLabel: l10n.ricochetChipPierce,
    bombLabel: l10n.ricochetChipBomb,
    plusBalls: l10n.ricochetToastPlusBalls,
    speedBoost: l10n.ricochetToastSpeed,
    autoSpeed: l10n.ricochetToastAutoSpeed,
    levelBanner: l10n.ricochetBannerLevel,
    scorePopup: (points) => '+$points',
    scorePopupDoubled: l10n.ricochetPopupDoubled,
    chargeChip: (label, count) => count > 1 ? '$label ×$count' : label,
  );

  void _onTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 1 / 60
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    // A frame longer than a fifth of a second is a stall, not slow motion.
    _engine.update(dt.clamp(0.0, 0.25));
    _syncWakeLock(_keepScreenAwake);
  }

  // ------------------------------------------------------------- app lifecycle

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _stopBackgroundTicker();
      _lastTick = Duration.zero;
      if (!_ticker.isActive) _ticker.start();
    } else {
      unawaited(_engine.saveNow());
      if (_engine.turnInProgress) _startBackgroundTicker();
    }
  }

  void _startBackgroundTicker() {
    _backgroundTicker ??= Timer.periodic(const Duration(milliseconds: 200), (
      _,
    ) {
      _engine.update(0.2);
      if (!_engine.turnInProgress) _stopBackgroundTicker();
    });
  }

  void _stopBackgroundTicker() {
    _backgroundTicker?.cancel();
    _backgroundTicker = null;
  }

  /// Held only while a turn plays itself out, so idle aiming never keeps a
  /// phone's screen lit.
  void _syncWakeLock(bool allowed) {
    final want = allowed && _engine.turnInProgress;
    if (want == _wakeLockHeld) return;
    _wakeLockHeld = want;
    unawaited(WakelockPlus.toggle(enable: want).catchError((_) {}));
  }

  void _releaseWakeLock() {
    if (!_wakeLockHeld) return;
    _wakeLockHeld = false;
    unawaited(WakelockPlus.disable().catchError((_) {}));
  }

  // -------------------------------------------------------------------- intent

  Future<void> _openPowerMenu() async {
    final power = await PowerMenuSheet.show(context, onHowToPlay: _openHelp);
    if (power != null) _engine.usePower(power);
  }

  void _openHelp() {
    if (!mounted) return;
    context.push('/ricochet/help');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    _keepScreenAwake = appState.keepScreenAwake;
    GameAudio.instance.setMasterVolume(appState.effectiveVolume);

    return GameLayout(
      title: l10n.gameNameRicochet,
      backgroundColor: RicochetColors.board,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hud = RicochetHud(
            engine: _engine,
            vertical: constraints.canSplit,
            soundEnabled: appState.soundEnabled,
            onOpenPowers: _openPowerMenu,
            onRestartLevel: () => unawaited(_engine.retryLevel()),
            onOpenHelp: _openHelp,
            onToggleSound: () =>
                appState.setSoundEnabled(!appState.soundEnabled),
          );

          final board = Stack(
            fit: StackFit.passthrough,
            children: [
              RicochetBoard(engine: _engine),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: RicochetActionBar(engine: _engine),
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _engine.hud,
                  builder: (context, _) => _engine.mode == GameMode.over
                      ? GameOverOverlay(
                          engine: _engine,
                          onRetryLevel: () => unawaited(_engine.retryLevel()),
                          onStartOver: () => unawaited(_engine.resetGame()),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          );

          // Wide enough for two panes: the HUD becomes a fixed column beside
          // the board, which is what stops a landscape phone from spending half
          // its height on a stats row.
          if (constraints.canSplit) {
            return Row(
              children: [
                Expanded(child: Center(child: board)),
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
              Expanded(child: Center(child: board)),
            ],
          );
        },
      ),
    );
  }
}
