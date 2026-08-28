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
class GameAudio {
  GameAudio._();

  static final GameAudio instance = GameAudio._();

  final Map<String, AudioSource> _clips = {};
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
      if (!SoLoud.instance.isInitialized) await SoLoud.instance.init();
      _available = true;
    } catch (e) {
      errorLog('[GameAudio] Audio unavailable, running silent: $e');
      _available = false;
    }
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
  }

  /// Fires a registered clip. Unknown keys and playback failures are silent —
  /// a missing sound must never interrupt a volley.
  void play(String key, {double volume = 1.0}) {
    if (!_available || _masterVolume <= 0) return;
    final source = _clips[key];
    if (source == null) return;
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
  }
}
