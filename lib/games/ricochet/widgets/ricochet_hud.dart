import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../engine/ricochet_engine.dart';
import '../ricochet_colors.dart';

/// Score, best, level and ball count, plus the top-row controls.
///
/// Laid out as a row above the board when the room is tall, and as a column
/// beside it when it is wide — the same four readouts either way, so nothing is
/// hidden on a phone in landscape or on a desktop window.
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
      builder: (context, _) {
        final stats = <Widget>[
          _Stat(label: l10n.ricochetScore, value: '${engine.score}'),
          _Stat(
            label: l10n.ricochetBest,
            value: '${engine.best}',
            color: RicochetColors.bonus,
          ),
          _Stat(label: l10n.ricochetLevel, value: '${engine.level}'),
          _Stat(
            label: l10n.ricochetBalls,
            value: '${engine.totalBalls}',
            color: RicochetColors.launcher,
          ),
        ];
        final controls = _Controls(
          vertical: vertical,
          soundEnabled: soundEnabled,
          onOpenPowers: onOpenPowers,
          onRestartLevel: onRestartLevel,
          onOpenHelp: onOpenHelp,
          onToggleSound: onToggleSound,
        );

        if (vertical) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...stats.map(
                  (stat) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: stat,
                  ),
                ),
                const Spacer(),
                controls,
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              ...stats.map(
                (stat) => Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: stat,
                ),
              ),
              const Spacer(),
              controls,
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1,
            color: theme.colorScheme.onSurface.withAlpha(130),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  final bool vertical;
  final bool soundEnabled;
  final VoidCallback onOpenPowers;
  final VoidCallback onRestartLevel;
  final VoidCallback onOpenHelp;
  final VoidCallback onToggleSound;

  const _Controls({
    required this.vertical,
    required this.soundEnabled,
    required this.onOpenPowers,
    required this.onRestartLevel,
    required this.onOpenHelp,
    required this.onToggleSound,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buttons = <Widget>[
      IconButton(
        icon: const Icon(Icons.grid_view_rounded),
        tooltip: l10n.ricochetPowerMenu,
        onPressed: onOpenPowers,
      ),
      IconButton(
        icon: const Icon(Icons.refresh_rounded),
        tooltip: l10n.ricochetRestartLevel,
        onPressed: onRestartLevel,
      ),
      IconButton(
        icon: const Icon(Icons.help_outline_rounded),
        tooltip: l10n.ricochetHowToPlay,
        onPressed: onOpenHelp,
      ),
      IconButton(
        icon: Icon(soundEnabled ? Icons.volume_up : Icons.volume_off),
        tooltip: soundEnabled ? l10n.ricochetMute : l10n.ricochetUnmute,
        onPressed: onToggleSound,
      ),
    ];
    // Wrap rather than Row: on a narrow phone the four buttons and the four
    // readouts together can outgrow one line.
    return vertical
        ? Wrap(alignment: WrapAlignment.center, children: buttons)
        : Wrap(alignment: WrapAlignment.end, children: buttons);
  }
}
