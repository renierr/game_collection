import 'dart:typed_data';

import '../../../helpers/wav_builder.dart';
import '../../../services/game_audio.dart';

/// Minesweeper's sound effects. Deliberately quiet and dry — the game is played
/// in long silent stretches punctuated by one loud mistake.
class MinesweeperSfx {
  MinesweeperSfx._();

  static const String reveal = 'mine_reveal';
  static const String flag = 'mine_flag';
  static const String boom = 'mine_boom';
  static const String win = 'mine_win';

  static Future<void> load() async {
    final clips = <String, Uint8List>{
      reveal: WavBuilder.noise(seconds: 0.035, gain: 0.045),
      flag: WavBuilder.tone(
        frequency: 660,
        seconds: 0.05,
        waveform: Waveform.square,
        gain: 0.09,
      ),
      boom: WavBuilder.noise(seconds: 0.5, gain: 0.3),
      win: WavBuilder.sequence(
        notes: const [
          ToneSpec(frequency: 523, seconds: 0.15, gain: 0.18),
          ToneSpec(frequency: 659, seconds: 0.15, gain: 0.18),
          ToneSpec(frequency: 784, seconds: 0.15, gain: 0.18),
          ToneSpec(frequency: 1047, seconds: 0.24, gain: 0.18),
        ],
        gapSeconds: 0.1,
      ),
    };
    await GameAudio.instance.registerAll(clips);
  }
}
