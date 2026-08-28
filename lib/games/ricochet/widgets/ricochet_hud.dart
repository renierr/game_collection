import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/game_hud.dart';
import '../../../widgets/game_stat.dart';
import '../engine/ricochet_engine.dart';
import '../ricochet_colors.dart';

/// Score, best, level and ball count, plus the top-row controls.
///
/// Only the readouts and the button set are Ricochet's; the responsive layout
/// is [GameHud]. Rebuilt from `engine.hud`, which fires when a displayed value
/// changes rather than every frame.
class RicochetHud extends StatelessWidget {
  final RicochetEngine engine;
  final bool vertical;
  final VoidCallback onOpenPowers;
  final VoidCallback onRestartLevel;
  final VoidCallback onOpenHelp;
  final VoidCallback onToggleSound;
  final bool soundEnabled;

  const RicochetHud({
    super.key,
    required this.engine,
    required this.vertical,
    required this.onOpenPowers,
    required this.onRestartLevel,
    required this.onOpenHelp,
    required this.onToggleSound,
    required this.soundEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: engine.hud,
      builder: (context, _) => GameHud(
        vertical: vertical,
        stats: [
          GameStat(label: l10n.ricochetScore, value: '${engine.score}'),
          GameStat(
            label: l10n.ricochetBest,
            value: '${engine.best}',
            color: RicochetColors.bonus,
          ),
          GameStat(label: l10n.ricochetLevel, value: '${engine.level}'),
          GameStat(
            label: l10n.ricochetBalls,
            value: '${engine.totalBalls}',
            color: RicochetColors.launcher,
          ),
        ],
        actions: [
          GameHudAction(
            icon: Icons.grid_view_rounded,
            tooltip: l10n.ricochetPowerMenu,
            onPressed: onOpenPowers,
          ),
          GameHudAction(
            icon: Icons.refresh_rounded,
            tooltip: l10n.ricochetRestartLevel,
            onPressed: onRestartLevel,
          ),
          GameHudAction(
            icon: Icons.help_outline_rounded,
            tooltip: l10n.ricochetHowToPlay,
            onPressed: onOpenHelp,
          ),
          GameHudAction(
            icon: soundEnabled ? Icons.volume_up : Icons.volume_off,
            tooltip: soundEnabled ? l10n.commonMute : l10n.commonUnmute,
            onPressed: onToggleSound,
          ),
        ],
      ),
    );
  }
}
