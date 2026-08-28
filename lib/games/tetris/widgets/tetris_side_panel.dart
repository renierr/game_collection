import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../engine/tetris_engine.dart';
import '../tetris_colors.dart';
import 'tetris_piece_preview.dart';

/// The hold slot and the next queue.
///
/// A column beside the board when there is room, a single row above it when
/// there is not — the queue is not optional information, so it never gets
/// dropped on a small screen, only reflowed.
class TetrisSidePanel extends StatelessWidget {
  final TetrisEngine engine;
  final bool vertical;

  const TetrisSidePanel({
    super.key,
    required this.engine,
    required this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: engine.hud,
      builder: (context, _) {
        final hold = _Slot(
          label: l10n.tetrisHold,
          vertical: vertical,
          children: [
            TetrisPiecePreview(
              kind: engine.hold,
              cell: vertical ? 16 : 12,
              dimmed: engine.holdUsed,
            ),
          ],
        );
        final next = _Slot(
          label: l10n.tetrisNext,
          vertical: vertical,
          children: [
            for (final kind in engine.preview)
              TetrisPiecePreview(kind: kind, cell: vertical ? 16 : 11),
          ],
        );

        if (vertical) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [hold, const SizedBox(height: 12), next],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              hold,
              const SizedBox(width: 14),
              Expanded(child: next),
            ],
          ),
        );
      },
    );
  }
}

class _Slot extends StatelessWidget {
  final String label;
  final bool vertical;
  final List<Widget> children;

  const _Slot({
    required this.label,
    required this.vertical,
    required this.children,
  });

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
            letterSpacing: 1.2,
            color: TetrisColors.panelLabel,
          ),
        ),
        const SizedBox(height: 4),
        // Wrap rather than a fixed Row or Column: three previews beside a hold
        // slot is more than a narrow phone can fit on one line.
        Wrap(
          spacing: 4,
          runSpacing: 2,
          direction: vertical ? Axis.vertical : Axis.horizontal,
          children: children,
        ),
      ],
    );
  }
}
