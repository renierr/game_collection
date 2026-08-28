import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../engine/ricochet_engine.dart';
import '../ricochet_colors.dart';

/// Shown over the board when a brick crosses the danger line.
///
/// *Retry Level* is the default and restores the board exactly as it looked
/// when the level began, so a bad break costs the level and not the run.
class GameOverOverlay extends StatelessWidget {
  final RicochetEngine engine;
  final VoidCallback onRetryLevel;
  final VoidCallback onStartOver;

  const GameOverOverlay({
    super.key,
    required this.engine,
    required this.onRetryLevel,
    required this.onStartOver,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isRecord = engine.score >= engine.best && engine.score > 0;

    return ColoredBox(
      color: RicochetColors.board.withValues(alpha: 0.88),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.ricochetGameOver,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${engine.score}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: RicochetColors.bonus,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  isRecord
                      ? l10n.ricochetNewBest
                      : l10n.ricochetBestScore(engine.best),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.ricochetReachedLevel(engine.level),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: onRetryLevel,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.ricochetRetryLevel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onStartOver,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l10n.ricochetStartOver),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    minimumSize: const Size.fromHeight(48),
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
