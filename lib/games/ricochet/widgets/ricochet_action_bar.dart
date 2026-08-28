import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../engine/ricochet_engine.dart';
import '../ricochet_colors.dart';

/// The two in-volley controls, pinned to the bottom corners of the board.
///
/// Both dim to inert when no volley is in flight rather than disappearing, so
/// their position is learned once and the layout never shifts mid-turn.
class RicochetActionBar extends StatelessWidget {
  final RicochetEngine engine;

  const RicochetActionBar({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: engine.hud,
      builder: (context, _) {
        final active = engine.volleyActive;
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ActionButton(
                label: l10n.ricochetRecall,
                icon: Icons.undo_rounded,
                enabled: active,
                color: RicochetColors.ballTrail,
                onPressed: engine.recallBalls,
              ),
              _ActionButton(
                label: engine.speedMultiplier > 1
                    ? l10n.ricochetSpeedActive(engine.speedMultiplier)
                    : l10n.ricochetSpeed,
                icon: Icons.fast_forward_rounded,
                enabled:
                    active && engine.speedMultiplier < RicochetTuning.maxSpeed,
                highlighted: engine.speedMultiplier > 1,
                color: RicochetColors.bonus,
                onPressed: engine.boostSpeed,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool highlighted;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.color,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = highlighted ? color : Colors.white;
    return AnimatedOpacity(
      opacity: enabled || highlighted ? 1 : 0.32,
      duration: const Duration(milliseconds: 180),
      child: FilledButton.tonalIcon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          foregroundColor: tint,
          backgroundColor: RicochetColors.board.withValues(alpha: 0.82),
          disabledForegroundColor: tint,
          disabledBackgroundColor: RicochetColors.board.withValues(alpha: 0.82),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          side: BorderSide(color: tint.withValues(alpha: 0.35)),
        ),
      ),
    );
  }
}
