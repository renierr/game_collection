import 'dart:typed_data';

import '../../../helpers/wav_builder.dart';
import '../../../services/game_audio.dart';

/// Snake's sound effects. The eat blip rises with the combo count, so a long
/// unbroken feeding streak is audible before the score has caught up.
class SnakeSfx {
  SnakeSfx._();

  static const String eatPrefix = 'snk_eat_';
  static const int eatVariants = 6;
  static const String bonus = 'snk_bonus';
  static const String turn = 'snk_turn';
  static const String die = 'snk_die';

  /// The variant for the nth food eaten, climbing then holding at the top.
  static String eat(int eaten) => '$eatPrefix${eaten % eatVariants}';

  static Future<void> load() async {
    final clips = <String, Uint8List>{
      for (var i = 0; i < eatVariants; i++)
        '$eatPrefix$i': WavBuilder.tone(
          frequency: 440 + 60.0 * i,
          seconds: 0.07,
          waveform: Waveform.square,
          gain: 0.13,
          slideHz: 80,
        ),
      bonus: WavBuilder.sequence(
        notes: const [
          ToneSpec(frequency: 784, seconds: 0.09, gain: 0.18),
          ToneSpec(frequency: 1047, seconds: 0.12, gain: 0.18),
        ],
        gapSeconds: 0.07,
      ),
      turn: WavBuilder.noise(seconds: 0.03, gain: 0.03),
      die: WavBuilder.tone(
        frequency: 220,
        seconds: 0.45,
        waveform: Waveform.sawtooth,
        gain: 0.22,
        slideHz: -150,
      ),
    };
    await GameAudio.instance.registerAll(clips);
  }
}
