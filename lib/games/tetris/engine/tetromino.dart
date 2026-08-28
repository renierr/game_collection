/// The seven pieces, their rotation geometry, and the SRS wall-kick tables.
///
/// Rotation is computed rather than tabulated: each piece is defined once in
/// its spawn orientation inside a square box, and a clockwise turn maps a cell
/// at `(x, y)` in an `n`-box to `(n - 1 - y, x)`. Four applications return the
/// original, so the four states cost no data.
///
/// The kick tables are the standard Super Rotation System offsets, with the
/// vertical component negated because this board's y grows downward while the
/// published tables assume it grows upward. Getting these right is what makes
/// a T-spin into a gap possible at all, so they are transcribed rather than
/// invented.
library;

/// Which piece. The order is the canonical one, and the index is what a save
/// stores, so it must not be reordered.
enum TetrominoKind {
  i(4, [(0, 1), (1, 1), (2, 1), (3, 1)]),
  j(3, [(0, 0), (0, 1), (1, 1), (2, 1)]),
  l(3, [(2, 0), (0, 1), (1, 1), (2, 1)]),
  o(2, [(0, 0), (1, 0), (0, 1), (1, 1)]),
  s(3, [(1, 0), (2, 0), (0, 1), (1, 1)]),
  t(3, [(1, 0), (0, 1), (1, 1), (2, 1)]),
  z(3, [(0, 0), (1, 0), (1, 1), (2, 1)]);

  /// Side of the square box the piece rotates inside.
  final int box;

  /// The four filled cells in the spawn orientation, as box coordinates.
  final List<(int, int)> spawnCells;

  const TetrominoKind(this.box, this.spawnCells);

  /// The filled cells in rotation state [rotation] (0 = spawn, then clockwise).
  List<(int, int)> cellsAt(int rotation) {
    // O never changes shape, and rotating it would only shuffle which corner
    // its box is anchored to.
    if (this == TetrominoKind.o) return spawnCells;
    var cells = spawnCells;
    for (var turn = 0; turn < (rotation % 4 + 4) % 4; turn++) {
      cells = [for (final (x, y) in cells) (box - 1 - y, x)];
    }
    return cells;
  }

  static TetrominoKind? byIndex(int index) =>
      index >= 0 && index < values.length ? values[index] : null;
}

/// The SRS kick offsets to try, in order, when rotating.
///
/// The first entry is always the plain rotation with no shift; a piece that
/// fits there never kicks. If none of the five fit, the rotation is refused.
class WallKicks {
  WallKicks._();

  /// J, L, S, T and Z all share one table.
  static const Map<int, List<(int, int)>> _jlstzClockwise = {
    0: [(0, 0), (-1, 0), (-1, -1), (0, 2), (-1, 2)],
    1: [(0, 0), (1, 0), (1, 1), (0, -2), (1, -2)],
    2: [(0, 0), (1, 0), (1, -1), (0, 2), (1, 2)],
    3: [(0, 0), (-1, 0), (-1, 1), (0, -2), (-1, -2)],
  };

  static const Map<int, List<(int, int)>> _jlstzCounter = {
    0: [(0, 0), (1, 0), (1, -1), (0, 2), (1, 2)],
    1: [(0, 0), (1, 0), (1, 1), (0, -2), (1, -2)],
    2: [(0, 0), (-1, 0), (-1, -1), (0, 2), (-1, 2)],
    3: [(0, 0), (-1, 0), (-1, 1), (0, -2), (-1, -2)],
  };

  /// I kicks differently, and by up to two cells — this is the table that lets
  /// a vertical I slot into a one-wide well against a wall.
  static const Map<int, List<(int, int)>> _iClockwise = {
    0: [(0, 0), (-2, 0), (1, 0), (-2, 1), (1, -2)],
    1: [(0, 0), (-1, 0), (2, 0), (-1, -2), (2, 1)],
    2: [(0, 0), (2, 0), (-1, 0), (2, -1), (-1, 2)],
    3: [(0, 0), (1, 0), (-2, 0), (1, 2), (-2, -1)],
  };

  static const Map<int, List<(int, int)>> _iCounter = {
    0: [(0, 0), (-1, 0), (2, 0), (-1, -2), (2, 1)],
    1: [(0, 0), (2, 0), (-1, 0), (2, -1), (-1, 2)],
    2: [(0, 0), (1, 0), (-2, 0), (1, 2), (-2, -1)],
    3: [(0, 0), (-2, 0), (1, 0), (-2, 1), (1, -2)],
  };

  /// Offsets to try when turning [kind] from [from], clockwise or not.
  static List<(int, int)> forRotation({
    required TetrominoKind kind,
    required int from,
    required bool clockwise,
  }) {
    if (kind == TetrominoKind.o) return const [(0, 0)];
    final table = kind == TetrominoKind.i
        ? (clockwise ? _iClockwise : _iCounter)
        : (clockwise ? _jlstzClockwise : _jlstzCounter);
    return table[from % 4] ?? const [(0, 0)];
  }
}
