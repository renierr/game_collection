import 'dart:async';

import 'package:wakelock_plus/wakelock_plus.dart';

/// Holds the screen awake only while a game actually needs it.
///
/// Games call [want] every frame with whether a turn is currently playing
/// itself out; only a change reaches the platform, so a 60 Hz caller costs one
/// channel call per state change rather than sixty a second. Idle aiming or a
/// paused board never keeps a phone lit.
///
/// Every call is guarded. The wake lock is a convenience — a platform without
/// one, or a channel that is not there yet, must leave the game playable.
class WakeLockGuard {
  bool _held = false;

  /// Whether the platform lock is currently held, as far as this guard knows.
  bool get isHeld => _held;

  void want(bool enabled) {
    if (enabled == _held) return;
    _held = enabled;
    unawaited(WakelockPlus.toggle(enable: enabled).catchError((_) {}));
  }

  /// Drops the lock if held. Safe to call from a page teardown.
  void release() {
    if (!_held) return;
    _held = false;
    unawaited(WakelockPlus.disable().catchError((_) {}));
  }
}
