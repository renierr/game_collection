<div align="center">

<img src="assets/logo/logo.png" width="120" alt="Game Collection">

# Game Collection

**A collection of casual games for Android, Windows and Linux.**

Built with Flutter. Fully offline — no accounts, no ads, no network, no tracking.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20Windows%20%7C%20Linux-lightgrey)](#building)

</div>

---

## What's in it

The app opens on a searchable overview of every game, grouped into sections,
with favourites pinned on top. Settings cover theme, language (English and
German), sound and volume, the screen wake lock, and a full data reset.

| Game | Section |
| --- | --- |
| **Ricochet** | Arcade |
| **Snake** | Arcade |
| **Tetris** | Arcade |
| **2048** | Puzzle |
| **Minesweeper** | Puzzle |

Each game explains itself in the app. More to come — the architecture is built
so a new game is a folder plus one line in the registry.

---

## Building

Requires the Flutter SDK (stable channel) and the toolchain for your target
platform. Then:

```sh
flutter pub get
flutter run -d windows      # or -d linux, or an attached Android device
```

Release builds and packaging go through `build.sh`:

```sh
./build.sh help             # list every target
./build.sh apk              # universal Android APK
./build.sh apks             # split per ABI
./build.sh bundle           # Android App Bundle
./build.sh windows package  # Windows release + zip with installer
./build.sh linux package    # Linux release + zip with installer
./build.sh clean windows    # clean first
```

Artifacts land in `dist/`. A packaged zip contains the build plus an installer:
`install.sh` on Linux, `install.bat` / `install.ps1` on Windows. Both install
per-user with no root or admin rights, register a launcher entry, and support
`--uninstall` / `-Uninstall`. Neither touches your saved games.

### Verifying a change

```sh
dart format ./lib ./test
flutter analyze
flutter test
```

### Regenerating the icon

The logo is drawn in code so it can be tweaked in a diff rather than swapped as
an opaque binary:

```sh
dart run tool/generate_logo.dart
dart run flutter_launcher_icons
```

---

## Architecture

```
lib/
  app.dart                 Router — game routes generated from the registry
  main.dart                Bootstrap: splash first, startup I/O behind it
  core/
    game_model.dart        GameModel / GameSection metadata
    game_registry.dart     The one list everything else is generated from
    game_page_state.dart   DisposeCleanup mixin
    game_store.dart        Guarded per-game key/value persistence
    frame_clock.dart       Ticker wrapper handing engines a delta in seconds
    frame_beacon.dart      Repaint / HUD-rebuild signal
    game_direction.dart    The four grid moves, shared by engines and input
  games/<name>/
    config.dart            Metadata. The only place the game's id appears
    <name>_page.dart       Thin coordinator: frame clock + composition
    engine/                The simulation — no widgets, no BuildContext
    widgets/               One file per visual component
  helpers/wav_builder.dart In-memory PCM WAV synthesis
  l10n/                    ARB sources (en, de) + generated localisations
  pages/                   Overview and settings screens
  providers/app_state.dart Global state
  services/                Database, settings, audio
  theme/, widgets/         Theme and shared widgets
```

The load-bearing rule is the **engine/view split**: a game's simulation lives
under `engine/` and never imports a widget or holds a `BuildContext`. That makes
it testable headlessly — the suites exercise volleys and explosion radii, SRS
wall kicks, merge rules, first-click-safe mine placement and save round-trips
with no widget tree and no database — and keeps a frame's work out of the widget
tree.

Nothing rebuilds per frame. A realtime engine exposes two separate listenables:
one that fires every frame and drives the `CustomPainter` directly, and one that
fires only when a number the HUD shows actually changed. A turn-based game has
no frame clock at all — its engine is a `ChangeNotifier` that fires once per
move — which is the other half of the proof that the shell is not built for one
kind of game.

Presentation is shared, not copied. `GameHud`, `GameStat`, `GameResultOverlay`
and `DirectionalInput` in `lib/widgets/` are what every game's readouts,
controls, end panel and swipe/keyboard mapping are built from, so a layout fix
lands once for all of them.

Boards are **resolution-independent**. Each defines itself in logical units —
Ricochet 480×760, Tetris 10×20 cells — and scales to fit whatever room it gets,
with pointer input mapped back through the same transform. A phone and a
maximised desktop window play the identical game, and a save moves between them
unchanged.

**Saves survive a hand edit.** Deserialisation validates and drops what it
cannot trust rather than trusting the blob, so an edited file cannot seed a 2048
tile that legal play could never make, a mine count that does not match the
level, or a tetromino buried inside the stack.

Sound effects are **synthesized, not shipped**. `WavBuilder` renders small PCM
clips in memory that SoLoud plays from memory — a few kilobytes each, always in
sync with the code, and free to add a variant of. If a machine has no working
audio backend, the game stays fully playable and silent.

Adding a game is a folder under `lib/games/` plus one line in
`GameRegistry.all`; routes, providers and the overview grid follow automatically.
See [`docs/creating-a-game.md`](docs/creating-a-game.md) for the walkthrough and
[`AGENTS.md`](AGENTS.md) for the full conventions.

---

## Credits

Ricochet is a Flutter port of [Ricochet](https://renierr.github.io/brick-game/),
originally a vanilla HTML5 Canvas browser game. The Flutter version keeps the
physics, the level generator and all nineteen stencils intact, and adds
localisation, persistent settings, a responsive HUD and a native audio engine.

## License

[GNU AGPL-3.0-or-later](LICENSE)
