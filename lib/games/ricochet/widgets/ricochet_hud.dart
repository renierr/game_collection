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

        return LayoutBuilder(
          builder: (context, constraints) {
            // Four readouts beside four buttons is a tight fit on a phone.
            // Below this the HUD trades gaps and tap-target padding for room
            // rather than clipping a score.
            final cramped = constraints.maxWidth < 460;
            final controls = _Controls(
              vertical: vertical,
              compact: cramped,
              soundEnabled: soundEnabled,
              onOpenPowers: onOpenPowers,
              onRestartLevel: onRestartLevel,
              onOpenHelp: onOpenHelp,
              onToggleSound: onToggleSound,
            );

            if (vertical) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
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
                  // The readouts take whatever the buttons leave and share it
                  // evenly; each one scales its own text down to fit its slot.
                  Expanded(
                    child: Row(
                      children: [
                        for (final stat in stats)
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(right: cramped ? 8 : 18),
                              child: stat,
                            ),
                          ),
                      ],
                    ),
                  ),
                  controls,
                ],
              ),
            );
          },
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
    // Scaling down beats wrapping or clipping: a five-digit score in a narrow
    // slot stays one readable line instead of breaking across two.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              color: theme.colorScheme.onSurface.withAlpha(130),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final bool vertical;
  final bool compact;
  final bool soundEnabled;
  final VoidCallback onOpenPowers;
  final VoidCallback onRestartLevel;
  final VoidCallback onOpenHelp;
  final VoidCallback onToggleSound;

  const _Controls({
    required this.vertical,
    required this.compact,
    required this.soundEnabled,
    required this.onOpenPowers,
    required this.onRestartLevel,
    required this.onOpenHelp,
    required this.onToggleSound,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Widget button(IconData icon, String tooltip, VoidCallback onPressed) {
      return IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: compact ? 20 : 24,
        padding: compact ? const EdgeInsets.all(5) : null,
        visualDensity: compact ? VisualDensity.compact : null,
        constraints: compact
            ? const BoxConstraints(minWidth: 34, minHeight: 34)
            : null,
      );
    }

    final buttons = <Widget>[
      button(Icons.grid_view_rounded, l10n.ricochetPowerMenu, onOpenPowers),
      button(Icons.refresh_rounded, l10n.ricochetRestartLevel, onRestartLevel),
      button(Icons.help_outline_rounded, l10n.ricochetHowToPlay, onOpenHelp),
      button(
        soundEnabled ? Icons.volume_up : Icons.volume_off,
        soundEnabled ? l10n.ricochetMute : l10n.ricochetUnmute,
        onToggleSound,
      ),
    ];

    // Wrap rather than Row: in the side column the four buttons may need two
    // lines, and wrapping is better than shrinking them further.
    return Wrap(
      alignment: vertical ? WrapAlignment.center : WrapAlignment.end,
      children: buttons,
    );
  }
}
