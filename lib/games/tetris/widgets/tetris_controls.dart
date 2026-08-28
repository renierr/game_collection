import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../tetris_colors.dart';

/// The touch control bar.
///
/// The board's gestures cover ordinary play, but placing a piece into a
/// one-cell gap wants a button you can tap exactly — so both exist. Laid out as
/// a [Wrap] with generous targets, which is what keeps it usable on a 320-wide
/// phone without shrinking the buttons to nothing.
class TetrisControls extends StatelessWidget {
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onRotateCcw;
  final VoidCallback onRotateCw;
  final VoidCallback onSoftDrop;
  final VoidCallback onHardDrop;
  final VoidCallback onHold;
  final bool holdEnabled;

  const TetrisControls({
    super.key,
    required this.onLeft,
    required this.onRight,
    required this.onRotateCcw,
    required this.onRotateCw,
    required this.onSoftDrop,
    required this.onHardDrop,
    required this.onHold,
    required this.holdEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          _Key(
            icon: Icons.rotate_left_rounded,
            tooltip: l10n.tetrisRotateLeft,
            onPressed: onRotateCcw,
          ),
          _Key(
            icon: Icons.chevron_left_rounded,
            tooltip: l10n.tetrisMoveLeft,
            onPressed: onLeft,
          ),
          _Key(
            icon: Icons.keyboard_arrow_down_rounded,
            tooltip: l10n.tetrisSoftDrop,
            onPressed: onSoftDrop,
          ),
          _Key(
            icon: Icons.chevron_right_rounded,
            tooltip: l10n.tetrisMoveRight,
            onPressed: onRight,
          ),
          _Key(
            icon: Icons.rotate_right_rounded,
            tooltip: l10n.tetrisRotateRight,
            onPressed: onRotateCw,
          ),
          _Key(
            icon: Icons.vertical_align_bottom_rounded,
            tooltip: l10n.tetrisHardDrop,
            onPressed: onHardDrop,
            accent: TetrisColors.score,
          ),
          _Key(
            icon: Icons.swap_vert_rounded,
            tooltip: l10n.tetrisHold,
            onPressed: holdEnabled ? onHold : null,
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? accent;

  const _Key({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: TetrisColors.wall.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Icon(
              icon,
              size: 20,
              color: onPressed == null
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                  : (accent ?? theme.colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
