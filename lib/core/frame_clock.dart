import 'package:flutter/scheduler.dart';

/// Drives a game's simulation once per rendered frame.
///
/// Wraps a [Ticker] and hands the callback a delta in seconds rather than a
/// cumulative [Duration], because every engine wants the former and would
/// otherwise each keep its own `_lastTick`. A frame longer than [maxDelta] is
/// treated as a stall and clamped: a game that has been backgrounded must not
/// resume by simulating the whole gap at once.
class FrameClock {
  final void Function(double dt) onTick;

  /// Seconds. Past this a frame is a stall, not slow motion.
  final double maxDelta;

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  FrameClock(TickerProvider provider, this.onTick, {this.maxDelta = 0.25}) {
    _ticker = provider.createTicker(_tick);
  }

  bool get isRunning => _ticker.isActive;

  /// Starts, or resumes after [stop] without counting the pause as one frame.
  void start() {
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void stop() {
    if (_ticker.isActive) _ticker.stop();
  }

  void dispose() => _ticker.dispose();

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    onTick(dt.clamp(0.0, maxDelta));
  }
}
