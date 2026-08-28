import 'dart:math' as math;
import 'dart:typed_data';

/// Waveform shapes, matching the Web Audio `OscillatorNode` types the browser
/// games were originally written against.
enum Waveform { sine, square, triangle, sawtooth }

/// Builds small 16-bit mono PCM WAV clips in memory.
///
/// Games synthesize their sound effects rather than shipping audio files: the
/// clips are a few kilobytes each, stay in sync with whatever the code says
/// they should sound like, and cost nothing to add a variant of. SoLoud plays
/// the resulting bytes straight from memory via `loadMem`.
class WavBuilder {
  WavBuilder._();

  static const int sampleRate = 44100;

  /// A single decaying tone.
  ///
  /// [gain] is the peak amplitude and the clip fades exponentially to silence
  /// over its whole length, which is what makes a bare oscillator read as a
  /// blip rather than a beep. [slideHz] bends the pitch by that many hertz
  /// across the clip — negative for the downward chirp of something breaking.
  static Uint8List tone({
    required double frequency,
    required double seconds,
    Waveform waveform = Waveform.sine,
    double gain = 0.3,
    double slideHz = 0,
  }) {
    final count = (sampleRate * seconds).round();
    final samples = Float64List(count);
    var phase = 0.0;
    for (var i = 0; i < count; i++) {
      final t = i / count;
      final hz = math.max(30.0, frequency + slideHz * t);
      phase += 2 * math.pi * hz / sampleRate;
      // Exponential decay to ~0.1% — the same shape as the browser original's
      // `gain.exponentialRampToValueAtTime(0.0001, ...)`.
      samples[i] = _wave(waveform, phase) * gain * math.exp(-6.9 * t);
    }
    return _encode(samples);
  }

  /// White noise with a linear fade-out — impacts, explosions, shatters.
  static Uint8List noise({
    required double seconds,
    double gain = 0.3,
    int seed = 0x5eed,
  }) {
    final count = (sampleRate * seconds).round();
    final samples = Float64List(count);
    final random = math.Random(seed);
    for (var i = 0; i < count; i++) {
      samples[i] = (random.nextDouble() * 2 - 1) * gain * (1 - i / count);
    }
    return _encode(samples);
  }

  /// Several tones played one after another — arpeggios and jingles.
  /// Each entry is a [tone] spec; [gapSeconds] is the delay between onsets, so
  /// a gap shorter than a note's length overlaps them.
  static Uint8List sequence({
    required List<ToneSpec> notes,
    required double gapSeconds,
  }) {
    if (notes.isEmpty) return _encode(Float64List(0));
    final totalSeconds = gapSeconds * (notes.length - 1) + notes.last.seconds;
    final total = (sampleRate * totalSeconds).round();
    final mix = Float64List(total);
    for (var n = 0; n < notes.length; n++) {
      final spec = notes[n];
      final offset = (sampleRate * gapSeconds * n).round();
      final count = (sampleRate * spec.seconds).round();
      var phase = 0.0;
      for (var i = 0; i < count && offset + i < total; i++) {
        final t = i / count;
        final hz = math.max(30.0, spec.frequency + spec.slideHz * t);
        phase += 2 * math.pi * hz / sampleRate;
        mix[offset + i] +=
            _wave(spec.waveform, phase) * spec.gain * math.exp(-6.9 * t);
      }
    }
    return _encode(mix);
  }

  static double _wave(Waveform waveform, double phase) {
    switch (waveform) {
      case Waveform.sine:
        return math.sin(phase);
      case Waveform.square:
        return math.sin(phase) >= 0 ? 1.0 : -1.0;
      case Waveform.triangle:
        final x = (phase / (2 * math.pi)) % 1.0;
        return 4 * (x < 0.5 ? x : 1 - x) - 1;
      case Waveform.sawtooth:
        return 2 * ((phase / (2 * math.pi)) % 1.0) - 1;
    }
  }

  /// Wraps float samples in a 44-byte canonical WAV header. Samples are hard
  /// clipped, so a mixed [sequence] that overshoots distorts rather than wraps.
  static Uint8List _encode(Float64List samples) {
    const headerBytes = 44;
    final dataBytes = samples.length * 2;
    final bytes = ByteData(headerBytes + dataBytes);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataBytes, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little); // PCM chunk size
    bytes.setUint16(20, 1, Endian.little); // format: PCM
    bytes.setUint16(22, 1, Endian.little); // channels: mono
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    bytes.setUint16(32, 2, Endian.little); // block align
    bytes.setUint16(34, 16, Endian.little); // bits per sample
    writeAscii(36, 'data');
    bytes.setUint32(40, dataBytes, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      bytes.setInt16(
        headerBytes + i * 2,
        (clamped * 32767).round(),
        Endian.little,
      );
    }
    return bytes.buffer.asUint8List();
  }
}

/// One note in a [WavBuilder.sequence].
class ToneSpec {
  final double frequency;
  final double seconds;
  final Waveform waveform;
  final double gain;
  final double slideHz;

  const ToneSpec({
    required this.frequency,
    required this.seconds,
    this.waveform = Waveform.sine,
    this.gain = 0.3,
    this.slideHz = 0,
  });
}
