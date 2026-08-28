import 'dart:math' as math;
import 'dart:typed_data';

import '../../../helpers/wav_builder.dart';
import '../../../services/game_audio.dart';

/// Ricochet's sound effects, synthesized once when the game page opens.
///
/// The browser original built every blip live in Web Audio. Here the clips are
/// pre-rendered to WAV and handed to SoLoud, which means a volley that lands a
/// hundred hits a second never allocates a buffer mid-frame. Only the brick hit
/// varies in pitch, so it ships as a handful of fixed variants picked at random
/// — indistinguishable from the original's continuous jitter in practice.
class RicochetSfx {
  RicochetSfx._();

  static const String hitPrefix = 'ric_hit_';
  static const int hitVariants = 6;
  static const String breakTile = 'ric_break';
  static const String boom = 'ric_boom';
  static const String plus = 'ric_plus';
  static const String arm = 'ric_arm';
  static const String launch = 'ric_launch';
  static const String levelClear = 'ric_clear';
  static const String gameOver = 'ric_over';

  static final math.Random _random = math.Random();

  /// A random pitch variant of the brick-impact tick.
  static String get hit => '$hitPrefix${_random.nextInt(hitVariants)}';

  /// Builds every clip. Runs off the first frame of the game page.
  static Future<void> load() async {
    final clips = <String, Uint8List>{
      for (var i = 0; i < hitVariants; i++)
        '$hitPrefix$i': WavBuilder.tone(
          // The original jittered 300–420 Hz per hit; the variants span the
          // same range in even steps.
          frequency: 300 + 120 * i / (hitVariants - 1),
          seconds: 0.05,
          waveform: Waveform.square,
          gain: 0.09,
        ),
      breakTile: WavBuilder.tone(
        frequency: 520,
        seconds: 0.09,
        waveform: Waveform.triangle,
        gain: 0.26,
        slideHz: -180,
      ),
      boom: WavBuilder.tone(
        frequency: 90,
        seconds: 0.35,
        waveform: Waveform.sawtooth,
        gain: 0.3,
        slideHz: -40,
      ),
      plus: WavBuilder.sequence(
        notes: const [
          ToneSpec(frequency: 520, seconds: 0.08, gain: 0.22),
          ToneSpec(frequency: 780, seconds: 0.10, gain: 0.22),
        ],
        gapSeconds: 0.07,
      ),
      arm: WavBuilder.sequence(
        notes: const [
          ToneSpec(
            frequency: 240,
            seconds: 0.07,
            waveform: Waveform.square,
            gain: 0.18,
          ),
          ToneSpec(
            frequency: 360,
            seconds: 0.07,
            waveform: Waveform.square,
            gain: 0.18,
          ),
        ],
        gapSeconds: 0.06,
      ),
      launch: WavBuilder.tone(
        frequency: 340,
        seconds: 0.09,
        waveform: Waveform.triangle,
        gain: 0.2,
        slideHz: 220,
      ),
      levelClear: WavBuilder.sequence(
        notes: const [
          ToneSpec(
            frequency: 440,
            seconds: 0.14,
            waveform: Waveform.triangle,
            gain: 0.22,
          ),
          ToneSpec(
            frequency: 554,
            seconds: 0.14,
            waveform: Waveform.triangle,
            gain: 0.22,
          ),
          ToneSpec(
            frequency: 659,
            seconds: 0.14,
            waveform: Waveform.triangle,
            gain: 0.22,
          ),
          ToneSpec(
            frequency: 880,
            seconds: 0.14,
            waveform: Waveform.triangle,
            gain: 0.22,
          ),
        ],
        gapSeconds: 0.09,
      ),
      gameOver: WavBuilder.sequence(
        notes: const [
          ToneSpec(
            frequency: 392,
            seconds: 0.22,
            waveform: Waveform.sawtooth,
            gain: 0.2,
          ),
          ToneSpec(
            frequency: 330,
            seconds: 0.22,
            waveform: Waveform.sawtooth,
            gain: 0.2,
          ),
          ToneSpec(
            frequency: 262,
            seconds: 0.22,
            waveform: Waveform.sawtooth,
            gain: 0.2,
          ),
          ToneSpec(
            frequency: 196,
            seconds: 0.22,
            waveform: Waveform.sawtooth,
            gain: 0.2,
          ),
        ],
        gapSeconds: 0.16,
      ),
    };
    await GameAudio.instance.registerAll(clips);
  }
}
