import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../engine/minesweeper_engine.dart';

/// Picks the board size. A [Wrap] of chips rather than a segmented button so
/// three labels plus their mine counts still fit a 320-wide phone.
class MineLevelPicker extends StatelessWidget {
  final MineLevel selected;
  final ValueChanged<MineLevel> onSelected;

  const MineLevelPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static String labelFor(MineLevel level, AppLocalizations l10n) {
    switch (level) {
      case MineLevel.beginner:
        return l10n.minesweeperBeginner;
      case MineLevel.intermediate:
        return l10n.minesweeperIntermediate;
      case MineLevel.expert:
        return l10n.minesweeperExpert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final level in MineLevel.values)
          ChoiceChip(
            label: Text(
              '${labelFor(level, l10n)} · ${level.columns}×${level.rows}',
            ),
            selected: level == selected,
            onSelected: (_) => onSelected(level),
          ),
      ],
    );
  }
}
