import 'dart:typed_data';

import '../../../helpers/wav_builder.dart';
import '../../../services/game_audio.dart';

/// Tetris's sound effects. The move and rotate blips are deliberately almost
/// inaudible — they fire many times a second at speed, and anything with a tail
/// would turn a fast board into noise.
class TetrisSfx {
  TetrisSfx._();

  static const String move = 'tet_move';
  static const String rotate = 'tet_rotate';
  static const String lock = 'tet_lock';
  static const String hardDrop = 'tet_harddrop';
  static const String clear = 'tet_clear';
  static const String tetris = 'tet_tetris';
  static const String hold = 'tet_hold';
  static const String levelUp = 'tet_levelup';
  static const String gameOver = 'tet_over';

  static Future<void> load() async {
    final clips = <String, Uint8List>{
      move: WavBuilder.noise(seconds: 0.018, gain: 0.028),
      rotate: WavBuilder.tone(
        frequency: 620,
        seconds: 0.035,
        waveform: Waveform.square,
        gain: 0.06,
      ),
      lock: WavBuilder.tone(
        frequency: 180,
        seconds: 0.07,
        waveform: Waveform.square,
        gain: 0.13,
        slideHz: -60,
      ),
      hardDrop: WavBuilder.tone(
        frequency: 140,
        seconds: 0.1,
        waveform: Waveform.sawtooth,
        gain: 0.17,
        slideHz: -70,
      ),
      clear: WavBuilder.sequence(
        notes: const [
          ToneSpec(frequency: 660, seconds: 0.1, gain: 0.16),
          ToneSpec(frequency: 880, seconds: 0.12, gain: 0.16),
        ],
        gapSeconds: 0.06,
      ),
      tetris: WavBuilder.sequence(
        notes: const [
          ToneSpec(frequency: 523, seconds: 0.11, gain: 0.2),
          ToneSpec(frequency: 659, seconds: 0.11, gain: 0.2),
          ToneSpec(frequency: 880, seconds: 0.11, gain: 0.2),
          ToneSpec(frequency: 1175, seconds: 0.18, gain: 0.2),
        ],
        gapSeconds: 0.07,
      ),
      hold: WavBuilder.tone(
        frequency: 400,
        seconds: 0.07,
        waveform: Waveform.triangle,
        gain: 0.12,
        slideHz: 140,
      ),
      levelUp: WavBuilder.sequence(
        notes: const [
          ToneSpec(frequency: 587, seconds: 0.12, gain: 0.18),
          ToneSpec(frequency: 784, seconds: 0.12, gain: 0.18),
          ToneSpec(frequency: 1047, seconds: 0.18, gain: 0.18),
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
            frequency: 294,
            seconds: 0.22,
            waveform: Waveform.sawtooth,
            gain: 0.2,
          ),
          ToneSpec(
            frequency: 196,
            seconds: 0.3,
            waveform: Waveform.sawtooth,
            gain: 0.2,
          ),
        ],
        gapSeconds: 0.17,
      ),
    };
    await GameAudio.instance.registerAll(clips);
  }
}
