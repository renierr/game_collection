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
/// SoLoud has a fixed voice budget (16) and *silently* drops a `play()` once it
/// is full — it reports `maxActiveVoiceCountReached` and returns a handle that
/// addresses no voice, without throwing. Worse, the refusal is not even-handed:
/// a clip that already has a voice playing steals its own oldest one and is
/// always heard, while a clip with none is simply refused. A game that fires a
/// tick per collision therefore loses precisely the rare sounds that carry
/// information — the launch, the level clear — while the ticks play on.
///
/// [play] answers that from both ends: it rations the ambient clips by rate
/// ([minGapMs] and a rolling window) *and* by voice count, and when an
/// [important] clip is refused anyway it ends the ticks and asks again.
class GameAudio {
  GameAudio._();

  static final GameAudio instance = GameAudio._();

  /// Ambient plays allowed inside [_windowMs], and voices they may hold at
  /// once. Both stay well under SoLoud's own budget so an [important] clip
  /// finds room without having to evict anything.
  static const int _ambientBudget = 5;
  static const int _windowMs = 120;
  static const int _ambientVoiceCap = 4;

  final Map<String, AudioSource> _clips = {};

  /// Last play time per throttle group, the timestamps of the ambient plays
  /// still inside the rolling window, and the voices those plays hold, oldest
  /// first.
  final Map<String, int> _lastPlayMs = {};
  final List<int> _recentAmbient = [];
  final List<SoundHandle> _ambientVoices = [];
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
  ///
  /// [minGapMs] is the shortest gap between two plays of the same [group]
  /// (the key itself by default): a hit tick that fires forty times in one
  /// frame is one sound to the ear, so collapsing it costs nothing and keeps
  /// voices free. Set [important] on the clips a player is waiting for — a
  /// level clear, a game over — so they are never rationed away.
  void play(
    String key, {
    double volume = 1.0,
    int minGapMs = 0,
    String? group,
    bool important = false,
  }) {
    if (!_available || _masterVolume <= 0) return;
    final source = _clips[key];
    if (source == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (minGapMs > 0) {
      final bucket = group ?? key;
      final last = _lastPlayMs[bucket];
      if (last != null && now - last < minGapMs) return;
      _lastPlayMs[bucket] = now;
    }

    if (important) {
      if (_startVoice(source, key, volume) != null) return;
      // Refused for want of a voice. The ticks are the cheapest thing playing
      // and none of them is missed, so end them and ask once more.
      _stopAmbientVoices();
      if (_startVoice(source, key, volume) == null) {
        // Only reachable when the budget is full of sounds this class did not
        // start, which nothing in the app currently does.
        debugLog('[GameAudio] no voice for "$key" even after freeing ticks');
      }
      return;
    }

    _recentAmbient.removeWhere((at) => now - at > _windowMs);
    if (_recentAmbient.length >= _ambientBudget) return;
    _pruneAmbientVoices();
    if (_ambientVoices.length >= _ambientVoiceCap) {
      _stopVoice(_ambientVoices.removeAt(0));
    }
    final handle = _startVoice(source, key, volume);
    if (handle == null) return;
    _recentAmbient.add(now);
    _ambientVoices.add(handle);
  }

  /// Starts one voice, or returns null when SoLoud would not. A full budget is
  /// not an exception there — it hands back a handle that addresses nothing —
  /// so the zero check is the only way to know the sound never played.
  SoundHandle? _startVoice(AudioSource source, String key, double volume) {
    try {
      final handle = SoLoud.instance.play(
        source,
        volume: (volume * _masterVolume).clamp(0.0, 1.0),
      );
      return handle.id == 0 ? null : handle;
    } catch (e) {
      debugLog('[GameAudio] play("$key") failed: $e');
      return null;
    }
  }

  void _pruneAmbientVoices() {
    _ambientVoices.removeWhere((handle) {
      try {
        return !SoLoud.instance.getIsValidVoiceHandle(handle);
      } catch (_) {
        return true;
      }
    });
  }

  void _stopAmbientVoices() {
    for (final handle in _ambientVoices) {
      _stopVoice(handle);
    }
    _ambientVoices.clear();
  }

  /// The native stop takes effect before the returned future completes, so a
  /// voice freed here is available to the very next [_startVoice].
  void _stopVoice(SoundHandle handle) {
    try {
      unawaited(SoLoud.instance.stop(handle).catchError((_) {}));
    } catch (_) {}
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
    _recentAmbient.clear();
    _ambientVoices.clear();
  }
}
