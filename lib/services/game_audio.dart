import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import '../helpers/debug_log.dart';

/// Plays a game's synthesized sound effects through SoLoud.
///
/// Clips are registered once by key (see [register]) and then fired by key,
/// so the per-hit path never touches WAV generation or disk. Every SoLoud call
/// is guarded: a machine with no audio device — a headless CI box, a Linux VM
/// without PulseAudio — must leave the game fully playable and silent rather
/// than throwing on the first brick.
///
/// SoLoud drops a play once its voice budget is gone, returning a handle that
/// addresses nothing rather than throwing. [_voiceCeiling] lifts that budget
/// past anything a board asks for.
class GameAudio {
  GameAudio._();

  static final GameAudio instance = GameAudio._();

  /// Frames per mix. SoLoud's default 2048 is ~46ms at 44.1kHz — longer than a
  /// 45ms impact tick, so every clip fired inside one window starts at the same
  /// sample offset. Near-identical ticks clumped like that merge into one sound
  /// to the ear, and a clip fired on a keypress waits up to a full buffer to be
  /// heard. 512 frames is ~12ms: short enough that neither shows.
  static const int _bufferFrames = 512;

  /// Concurrent voices asked of SoLoud, well above what any board generates.
  /// The engine's own hard maximum is 1023.
  static const int _voiceCeiling = 64;

  final Map<String, AudioSource> _clips = {};

  /// Last play time per throttle group.
  final Map<String, int> _lastPlayMs = {};

  Future<void>? _initFuture;
  bool _available = false;
  double _masterVolume = 0.7;

  /// Whether sound actually reaches a device. False until [init] succeeds, and
  /// permanently false when the platform has no working audio backend.
  bool get isAvailable => _available;

  /// Idempotent, and safe to call from several games at once — the first call
  /// owns the initialization and the rest await the same future.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init(bufferSize: _bufferFrames);
      }
      _raiseVoiceCeiling();
      _available = true;
    } catch (e) {
      errorLog('[GameAudio] Audio unavailable, running silent: $e');
      _available = false;
    }
  }

  /// The default 16 is nowhere near a board that can land a dozen impacts in
  /// one frame, and overflowing it drops sounds silently. Above the ceiling
  /// SoLoud keeps the loudest voices rather than refusing new ones, so the
  /// failure mode past this is graceful instead of arbitrary.
  void _raiseVoiceCeiling() {
    try {
      SoLoud.instance.setMaxActiveVoiceCount(_voiceCeiling);
    } catch (_) {}
  }

  /// Volume every clip is scaled by, 0..1. Games pass `AppState.effectiveVolume`
  /// so the settings mute switch and slider both land here.
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
  }

  /// Loads one clip under [key], replacing any clip already registered there.
  /// [wav] is raw WAV bytes, normally from `WavBuilder`.
  Future<void> register(String key, Uint8List wav) async {
    await init();
    if (!_available) return;
    try {
      final existing = _clips.remove(key);
      if (existing != null) SoLoud.instance.disposeSource(existing);
      // SoLoud hashes sounds by name, so a stable per-key name lets a re-register
      // replace the clip instead of colliding with the old one.
      _clips[key] = await SoLoud.instance.loadMem('ga_$key.wav', wav);
    } catch (e) {
      errorLog('[GameAudio] Failed to register clip "$key": $e');
    }
  }

  Future<void> registerAll(Map<String, Uint8List> clips) async {
    for (final entry in clips.entries) {
      await register(entry.key, entry.value);
    }
    // Re-assert the ceiling per game: an engine that reinitialized underneath
    // us — an audio device change, an interruption — comes back at the default.
    if (_available) _raiseVoiceCeiling();
  }

  /// Fires a registered clip.
  ///
  /// [minGapMs] is the shortest gap between two plays of the same [group] (the
  /// key itself by default). It exists for the clips a collision fires: at one
  /// per frame they still sound continuous, and forty in a frame is one sound
  /// to the ear and thirty-nine voices of wasted mixing. It is the *only*
  /// rationing here — anything cleverer is a place for a sound to go missing
  /// for reasons the player cannot hear.
  void play(
    String key, {
    double volume = 1.0,
    int minGapMs = 0,
    String? group,
  }) {
    if (!_available || _masterVolume <= 0) return;
    final source = _clips[key];
    if (source == null) return;

    if (minGapMs > 0) {
      final bucket = group ?? key;
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = _lastPlayMs[bucket];
      if (last != null && now - last < minGapMs) return;
      _lastPlayMs[bucket] = now;
    }

    try {
      SoLoud.instance.play(
        source,
        volume: (volume * _masterVolume).clamp(0.0, 1.0),
      );
    } catch (e) {
      debugLog('[GameAudio] play("$key") failed: $e');
    }
  }

  /// Releases every registered clip. Called when a game page is disposed; the
  /// SoLoud engine itself stays up for the next game.
  Future<void> releaseAll() async {
    for (final source in _clips.values) {
      try {
        SoLoud.instance.disposeSource(source);
      } catch (_) {}
    }
    _clips.clear();
    _lastPlayMs.clear();
  }
}
