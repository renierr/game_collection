import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../engine/tetris_engine.dart';
import '../tetris_colors.dart';
import 'tetris_piece_preview.dart';

/// The hold slot and the next queue combined.
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
    if (vertical) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TetrisHoldSlot(engine: engine, vertical: true, cell: 16),
            const SizedBox(height: 12),
            TetrisNextSlot(engine: engine, vertical: true, cell: 16),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TetrisHoldSlot(engine: engine, vertical: false, cell: 12),
          const SizedBox(width: 14),
          Expanded(
            child: TetrisNextSlot(engine: engine, vertical: false, cell: 11),
          ),
        ],
      ),
    );
  }
}

/// Standalone Hold slot widget.
class TetrisHoldSlot extends StatelessWidget {
  final TetrisEngine engine;
  final bool vertical;
  final double cell;

  const TetrisHoldSlot({
    super.key,
    required this.engine,
    this.vertical = true,
    this.cell = 12,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: engine.hud,
      builder: (context, _) => _Slot(
        label: l10n.tetrisHold,
        vertical: vertical,
        children: [
          TetrisPiecePreview(
            kind: engine.hold,
            cell: cell,
            dimmed: engine.holdUsed,
          ),
        ],
      ),
    );
  }
}

/// Standalone Next queue widget.
class TetrisNextSlot extends StatelessWidget {
  final TetrisEngine engine;
  final bool vertical;
  final double cell;

  const TetrisNextSlot({
    super.key,
    required this.engine,
    this.vertical = true,
    this.cell = 11,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: engine.hud,
      builder: (context, _) => _Slot(
        label: l10n.tetrisNext,
        vertical: vertical,
        children: [
          for (final kind in engine.preview)
            TetrisPiecePreview(kind: kind, cell: cell),
        ],
      ),
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
