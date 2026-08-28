import 'package:flutter/material.dart';

import 'game_stat.dart';

/// One control button in a [GameHud].
class GameHudAction {
  final IconData icon;
  final String tooltip;

  /// A null callback disables the button, which is how a HUD shows a power that
  /// is out of charges without the icon disappearing and moving the others.
  final VoidCallback? onPressed;
  final Color? color;

  /// Small overlay label on the icon — a count or a multiplier. Information,
  /// not decoration; a plain name belongs in [tooltip].
  final String? badge;

  const GameHudAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.badge,
  });
}

/// The readouts-plus-controls bar every game page wears.
///
/// A row above the board when the room is tall, a column beside it when it is
/// wide — the same stats either way, so nothing is hidden on a phone in
/// landscape or on a desktop window. Below [_crampedWidth] the bar trades gaps
/// and tap-target padding for room rather than clipping a score.
class GameHud extends StatelessWidget {
  final List<GameStat> stats;
  final List<GameHudAction> actions;
  final bool vertical;

  const GameHud({
    super.key,
    required this.stats,
    required this.actions,
    required this.vertical,
  });

  /// Four readouts beside four buttons is a tight fit on a phone; this is the
  /// width where that stops being comfortable, not a device tier.
  static const double _crampedWidth = 460;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cramped = constraints.maxWidth < _crampedWidth;
        final controls = _Controls(
          actions: actions,
          vertical: vertical,
          compact: cramped,
        );

        if (vertical) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final stat in stats)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: stat,
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
  }
}

class _Controls extends StatelessWidget {
  final List<GameHudAction> actions;
  final bool vertical;
  final bool compact;

  const _Controls({
    required this.actions,
    required this.vertical,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap rather than Row: in the side column the buttons may need two lines,
    // and wrapping beats shrinking them further.
    return Wrap(
      alignment: vertical ? WrapAlignment.center : WrapAlignment.end,
      children: [
        for (final action in actions)
          IconButton(
            icon: action.badge == null
                ? Icon(action.icon)
                : Badge(
                    label: Text(action.badge!),
                    backgroundColor: action.color,
                    child: Icon(action.icon),
                  ),
            color: action.color,
            tooltip: action.tooltip,
            onPressed: action.onPressed,
            iconSize: compact ? 20 : 24,
            padding: compact ? const EdgeInsets.all(5) : null,
            visualDensity: compact ? VisualDensity.compact : null,
            constraints: compact
                ? const BoxConstraints(minWidth: 34, minHeight: 34)
                : null,
          ),
      ],
    );
  }
}
