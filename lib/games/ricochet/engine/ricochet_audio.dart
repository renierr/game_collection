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

  /// Builds every clip. Separate from [load] so the synthesis can be rendered
  /// and inspected without an audio device.
  static Map<String, Uint8List> build() {
    return <String, Uint8List>{
      for (var i = 0; i < hitVariants; i++)
        '$hitPrefix$i': WavBuilder.mix([
          // An impact is a transient, not a note: a bright click of noise for
          // the contact, and a pitched body under it that falls away at once.
          // The original's bare square wave read as a beep because it had the
          // body and none of the click.
          WavBuilder.noise(
            seconds: 0.03,
            gain: 0.12,
            decay: 14,
            highPassHz: 800,
            lowPassHz: 4500,
            seed: 0x51 + i,
          ),
          WavBuilder.tone(
            // The original jittered 300–420 Hz per hit; the variants span the
            // same range in even steps.
            frequency: 300 + 120 * i / (hitVariants - 1),
            seconds: 0.045,
            waveform: Waveform.triangle,
            gain: 0.10,
            slideHz: -170,
            decay: 13,
          ),
        ]),
      breakTile: WavBuilder.mix([
        // Shattering is the same shape with the noise pushed brighter and held
        // longer — the difference between a tile taking a hit and coming apart.
        WavBuilder.noise(
          seconds: 0.14,
          gain: 0.17,
          decay: 9,
          highPassHz: 900,
          lowPassHz: 5200,
          seed: 0xbeef,
        ),
        WavBuilder.tone(
          frequency: 620,
          seconds: 0.11,
          waveform: Waveform.triangle,
          gain: 0.19,
          slideHz: -330,
          decay: 9,
        ),
      ]),
      boom: WavBuilder.mix([
        // Three layers, because that is what an explosion is: the crack of the
        // detonation, a low-passed roar for the body, and a pitch-swept sine
        // under both for the thump you feel. A single sawtooth had none of the
        // three and read as a buzz.
        WavBuilder.noise(
          seconds: 0.06,
          gain: 0.16,
          decay: 18,
          highPassHz: 1500,
          seed: 0xb00,
        ),
        WavBuilder.noise(
          seconds: 0.55,
          gain: 0.38,
          decay: 5.2,
          lowPassHz: 380,
          seed: 0x0b1,
        ),
        WavBuilder.tone(
          frequency: 120,
          seconds: 0.34,
          waveform: Waveform.sine,
          gain: 0.40,
          slideHz: -88,
          decay: 5.5,
          // Without a ramp the sine starts mid-cycle and cracks; the thump has
          // to swell, however briefly.
          attackSeconds: 0.004,
        ),
      ]),
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
      launch: WavBuilder.mix([
        WavBuilder.tone(
          frequency: 340,
          seconds: 0.09,
          waveform: Waveform.triangle,
          gain: 0.18,
          slideHz: 220,
        ),
        // A breath of air behind the chirp, so firing reads as a release.
        WavBuilder.noise(
          seconds: 0.07,
          gain: 0.07,
          decay: 11,
          highPassHz: 1400,
          seed: 0x1a,
        ),
      ]),
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
  }

  /// Builds every clip and hands them to the mixer. Runs off the first frame of
  /// the game page.
  static Future<void> load() => GameAudio.instance.registerAll(build());
}
