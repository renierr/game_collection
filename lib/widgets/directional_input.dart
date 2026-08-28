import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/game_direction.dart';

export '../core/game_direction.dart' show GameDirection;

/// Turns swipes and key presses into [GameDirection]s.
///
/// Three of the grid games take the identical input — arrows or WASD on a
/// desktop, a swipe on a phone — so the mapping lives here once. A swipe fires
/// the moment it crosses [threshold] rather than on release: waiting for the
/// finger to lift makes a grid game feel a frame behind the player.
class DirectionalInput extends StatefulWidget {
  final ValueChanged<GameDirection> onDirection;
  final Widget child;

  /// Game-specific keys — hard drop, hold, pause — checked before the
  /// direction mapping, so a game may shadow a key it needs for something else.
  final Map<LogicalKeyboardKey, VoidCallback> extraKeys;

  /// A tap anywhere on the child. Null leaves taps to pass through.
  final VoidCallback? onTap;

  /// Whether a held key repeats. Wanted for sliding a piece sideways, unwanted
  /// where one press must mean exactly one move.
  final bool allowKeyRepeat;

  final bool enableSwipe;
  final double threshold;

  const DirectionalInput({
    super.key,
    required this.onDirection,
    required this.child,
    this.extraKeys = const {},
    this.onTap,
    this.allowKeyRepeat = false,
    this.enableSwipe = true,
    this.threshold = 24,
  });

  @override
  State<DirectionalInput> createState() => _DirectionalInputState();
}

class _DirectionalInputState extends State<DirectionalInput> {
  /// Not const: [LogicalKeyboardKey] overrides `==`, which a constant map key
  /// may not do.
  static final Map<LogicalKeyboardKey, GameDirection> _keyMap = {
    LogicalKeyboardKey.arrowUp: GameDirection.up,
    LogicalKeyboardKey.arrowDown: GameDirection.down,
    LogicalKeyboardKey.arrowLeft: GameDirection.left,
    LogicalKeyboardKey.arrowRight: GameDirection.right,
    LogicalKeyboardKey.keyW: GameDirection.up,
    LogicalKeyboardKey.keyS: GameDirection.down,
    LogicalKeyboardKey.keyA: GameDirection.left,
    LogicalKeyboardKey.keyD: GameDirection.right,
  };

  Offset _drag = Offset.zero;
  bool _fired = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final isPress = event is KeyDownEvent;
    final isRepeat = event is KeyRepeatEvent;
    if (!isPress && !(isRepeat && widget.allowKeyRepeat)) {
      return KeyEventResult.ignored;
    }

    final extra = widget.extraKeys[event.logicalKey];
    if (extra != null) {
      extra();
      return KeyEventResult.handled;
    }
    final direction = _keyMap[event.logicalKey];
    if (direction != null) {
      widget.onDirection(direction);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_fired) return;
    _drag += details.delta;
    if (_drag.distance < widget.threshold) return;
    _fired = true;
    final horizontal = _drag.dx.abs() > _drag.dy.abs();
    widget.onDirection(
      horizontal
          ? (_drag.dx > 0 ? GameDirection.right : GameDirection.left)
          : (_drag.dy > 0 ? GameDirection.down : GameDirection.up),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    if (widget.enableSwipe || widget.onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanStart: widget.enableSwipe
            ? (_) {
                _drag = Offset.zero;
                _fired = false;
              }
            : null,
        onPanUpdate: widget.enableSwipe ? _onPanUpdate : null,
        child: child,
      );
    }
    // Autofocus so a desktop player can use the keyboard the instant the page
    // opens, without having to click the board first.
    return Focus(autofocus: true, onKeyEvent: _onKey, child: child);
  }
}
