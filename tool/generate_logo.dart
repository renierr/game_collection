// Regenerates `assets/logo/logo.png`, the source image for the app icon on
// every platform.
//
// The logo is drawn in code rather than committed as an opaque binary so it can
// be tweaked in a diff and reproduced exactly. Run it with:
//
//     dart run tool/generate_logo.dart
//
// then regenerate the platform icons with `dart run flutter_launcher_icons`.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const double size = 512;

void main() {
  final canvas = _Canvas(size.toInt(), size.toInt());

  // Ricochet's board, as the icon's ground.
  canvas.roundedRect(0, 0, size, size, 96, 0xFF10121C);

  // Three rows of bricks, coloured the way the board colours HP: orange for
  // soft, sweeping toward violet for tough.
  const columns = 4;
  const brick = 84.0;
  const gap = 14.0;
  const totalWidth = columns * brick + (columns - 1) * gap;
  const startX = (size - totalWidth) / 2;
  const rowColors = [0xFFEF6C2B, 0xFFE0B63C, 0xFF7C5CE0];
  for (var row = 0; row < rowColors.length; row++) {
    for (var col = 0; col < columns; col++) {
      // Stagger the top row into a shallow arch so it reads as a board, not a
      // grid of squares.
      if (row == 0 && (col == 0 || col == columns - 1)) continue;
      canvas.roundedRect(
        startX + col * (brick + gap),
        96 + row * (brick + gap),
        brick,
        brick,
        18,
        rowColors[row],
      );
    }
  }

  // The ball, mid-flight, with its trail.
  for (var i = 0; i < 5; i++) {
    canvas.circle(
      168 + i * 22.0,
      408 - i * 16.0,
      6 + i * 1.5,
      0xFFF8FAFC,
      alpha: 0.16 + i * 0.14,
    );
  }
  canvas.circle(280, 336, 18, 0xFFF8FAFC);

  // The launcher.
  canvas.circle(150, 432, 42, 0xFF38BDF8, alpha: 0.25);
  canvas.circle(150, 432, 28, 0xFF38BDF8);

  final file = File('assets/logo/logo.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(canvas.toPng());
  stdout.writeln('Wrote ${file.path} (${file.lengthSync()} bytes)');
}

/// A tiny software rasterizer — enough for flat shapes with antialiased edges,
/// which is all the logo needs.
class _Canvas {
  final int width;
  final int height;
  final Uint8List pixels;

  _Canvas(this.width, this.height) : pixels = Uint8List(width * height * 4);

  void _blend(int x, int y, int color, double alpha) {
    if (x < 0 || y < 0 || x >= width || y >= height || alpha <= 0) return;
    final i = (y * width + x) * 4;
    final srcA = ((color >> 24) & 0xFF) / 255 * alpha.clamp(0.0, 1.0);
    if (srcA <= 0) return;
    final srcR = (color >> 16) & 0xFF;
    final srcG = (color >> 8) & 0xFF;
    final srcB = color & 0xFF;
    final dstA = pixels[i + 3] / 255;
    final outA = srcA + dstA * (1 - srcA);
    if (outA <= 0) return;
    int mix(int src, int dst) =>
        ((src * srcA + dst * dstA * (1 - srcA)) / outA).round().clamp(0, 255);
    pixels[i] = mix(srcR, pixels[i]);
    pixels[i + 1] = mix(srcG, pixels[i + 1]);
    pixels[i + 2] = mix(srcB, pixels[i + 2]);
    pixels[i + 3] = (outA * 255).round();
  }

  /// Coverage is sampled on a 3×3 grid per pixel, which is enough to keep the
  /// rounded corners and circles from looking stepped at icon sizes.
  void _fill(
    double left,
    double top,
    double right,
    double bottom,
    int color,
    double alpha,
    bool Function(double x, double y) inside,
  ) {
    for (var y = left.isNaN ? 0 : top.floor(); y <= bottom.ceil(); y++) {
      for (var x = left.floor(); x <= right.ceil(); x++) {
        var hits = 0;
        for (var sy = 0; sy < 3; sy++) {
          for (var sx = 0; sx < 3; sx++) {
            if (inside(x + (sx + 0.5) / 3, y + (sy + 0.5) / 3)) hits++;
          }
        }
        if (hits > 0) _blend(x, y, color, alpha * hits / 9);
      }
    }
  }

  void roundedRect(
    double x,
    double y,
    double w,
    double h,
    double radius,
    int color, {
    double alpha = 1,
  }) {
    final r = math.min(radius, math.min(w, h) / 2);
    _fill(x, y, x + w, y + h, color, alpha, (px, py) {
      if (px < x || py < y || px > x + w || py > y + h) return false;
      final cx = px.clamp(x + r, x + w - r);
      final cy = py.clamp(y + r, y + h - r);
      final dx = px - cx;
      final dy = py - cy;
      return dx * dx + dy * dy <= r * r;
    });
  }

  void circle(double cx, double cy, double r, int color, {double alpha = 1}) {
    _fill(cx - r, cy - r, cx + r, cy + r, color, alpha, (px, py) {
      final dx = px - cx;
      final dy = py - cy;
      return dx * dx + dy * dy <= r * r;
    });
  }

  Uint8List toPng() {
    // One filter byte (0 = none) in front of every scanline.
    final raw = Uint8List(height * (width * 4 + 1));
    var offset = 0;
    for (var y = 0; y < height; y++) {
      raw[offset++] = 0;
      raw.setRange(offset, offset + width * 4, pixels, y * width * 4);
      offset += width * 4;
    }

    final ihdr = BytesBuilder()
      ..add(_uint32(width))
      ..add(_uint32(height))
      ..add([8, 6, 0, 0, 0]); // 8-bit depth, RGBA, no interlace

    return Uint8List.fromList([
      137, 80, 78, 71, 13, 10, 26, 10, // PNG signature
      ..._chunk('IHDR', ihdr.takeBytes()),
      ..._chunk('IDAT', Uint8List.fromList(ZLibCodec(level: 9).encode(raw))),
      ..._chunk('IEND', Uint8List(0)),
    ]);
  }

  static List<int> _uint32(int value) => [
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ];

  static List<int> _chunk(String type, Uint8List data) {
    final body = <int>[...type.codeUnits, ...data];
    return [..._uint32(data.length), ...body, ..._uint32(_crc32(body))];
  }

  static final List<int> _crcTable = List<int>.generate(256, (n) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    return c;
  });

  static int _crc32(List<int> bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
    }
    return crc ^ 0xFFFFFFFF;
  }
}
