import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_collection/helpers/wav_builder.dart';

void main() {
  String ascii(Uint8List bytes, int offset, int length) =>
      String.fromCharCodes(bytes.sublist(offset, offset + length));

  test('produces a canonical 16-bit mono WAV header', () {
    final wav = WavBuilder.tone(frequency: 440, seconds: 0.05);
    final view = ByteData.sublistView(wav);

    expect(ascii(wav, 0, 4), 'RIFF');
    expect(ascii(wav, 8, 4), 'WAVE');
    expect(ascii(wav, 12, 4), 'fmt ');
    expect(ascii(wav, 36, 4), 'data');
    expect(view.getUint16(20, Endian.little), 1, reason: 'PCM');
    expect(view.getUint16(22, Endian.little), 1, reason: 'mono');
    expect(view.getUint32(24, Endian.little), WavBuilder.sampleRate);
    expect(view.getUint16(34, Endian.little), 16, reason: 'bits per sample');
    expect(view.getUint32(4, Endian.little), wav.length - 8);
    expect(view.getUint32(40, Endian.little), wav.length - 44);
  });

  test('clip length follows the requested duration', () {
    final wav = WavBuilder.tone(frequency: 200, seconds: 0.1);
    expect((wav.length - 44) ~/ 2, (WavBuilder.sampleRate * 0.1).round());
  });

  test('every waveform stays inside 16-bit range', () {
    for (final waveform in Waveform.values) {
      final wav = WavBuilder.tone(
        frequency: 300,
        seconds: 0.02,
        waveform: waveform,
        gain: 1.0,
      );
      final view = ByteData.sublistView(wav);
      for (var i = 44; i < wav.length; i += 2) {
        final sample = view.getInt16(i, Endian.little);
        expect(sample, inInclusiveRange(-32768, 32767));
      }
    }
  });

  test('the envelope decays to near silence', () {
    final wav = WavBuilder.tone(frequency: 440, seconds: 0.1, gain: 1.0);
    final view = ByteData.sublistView(wav);
    var peakStart = 0;
    var peakEnd = 0;
    final samples = (wav.length - 44) ~/ 2;
    for (var i = 0; i < samples; i++) {
      final value = view.getInt16(44 + i * 2, Endian.little).abs();
      if (i < samples ~/ 10) peakStart = value > peakStart ? value : peakStart;
      if (i > samples - samples ~/ 10) {
        peakEnd = value > peakEnd ? value : peakEnd;
      }
    }
    expect(peakStart, greaterThan(1000));
    expect(peakEnd, lessThan(peakStart ~/ 100));
  });

  test('a sequence spans all its notes', () {
    final wav = WavBuilder.sequence(
      notes: const [
        ToneSpec(frequency: 440, seconds: 0.1),
        ToneSpec(frequency: 660, seconds: 0.1),
        ToneSpec(frequency: 880, seconds: 0.1),
      ],
      gapSeconds: 0.05,
    );
    // Two gaps plus the final note's own length.
    final expected = (WavBuilder.sampleRate * (0.05 * 2 + 0.1)).round();
    expect((wav.length - 44) ~/ 2, expected);
  });

  test('noise is not silence', () {
    final wav = WavBuilder.noise(seconds: 0.05, gain: 0.8);
    final view = ByteData.sublistView(wav);
    var peak = 0;
    for (var i = 44; i < wav.length; i += 2) {
      final value = view.getInt16(i, Endian.little).abs();
      if (value > peak) peak = value;
    }
    expect(peak, greaterThan(5000));
  });
}
