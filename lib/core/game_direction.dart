/// The four moves a grid game understands.
///
/// Lives in `core` rather than beside the widget that produces it because a
/// game's engine takes it as input, and an engine imports no widgets.
enum GameDirection {
  up,
  down,
  left,
  right;

  bool get isHorizontal =>
      this == GameDirection.left || this == GameDirection.right;

  GameDirection get opposite {
    switch (this) {
      case GameDirection.up:
        return GameDirection.down;
      case GameDirection.down:
        return GameDirection.up;
      case GameDirection.left:
        return GameDirection.right;
      case GameDirection.right:
        return GameDirection.left;
    }
  }
}
