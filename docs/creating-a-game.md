# Creating a game

Every game in the collection is a self-contained folder under `lib/games/` plus
one line in the registry. Nothing else in the app needs editing: routes,
providers and the overview grid are all generated from `GameRegistry.all`.

`lib/games/ricochet/` is the reference implementation of everything below.

---

## 1. The folder

```
lib/games/<name>/
  config.dart              Game metadata. The only place the id string appears.
  <name>_page.dart         Thin coordinator: frame clock + composition.
  <name>_colors.dart       Optional per-game palette.
  <name>_state.dart        Optional ChangeNotifier for cross-widget state.
  engine/                  The simulation. No widgets, no BuildContext.
  widgets/                 One file per visual component.
```

Widget files always live under `widgets/`. Non-widget code (models, parsers,
codecs) may sit at the game root or in a named subfolder.

---

## 2. `config.dart`

```dart
class MyGame {
  MyGame._();

  static const GameModel config = GameModel(
    id: 'my-game',
    name: 'My Game',
    description: 'What it is, in one line',
    icon: Icons.casino_outlined,
    route: '/my-game',
    accentColor: AppTheme.accentTeal,
    sectionId: 'puzzle',
    createPage: _createPage,
    nameL10n: _name,
    descriptionL10n: _description,
    // Optional: game-scoped ChangeNotifiers, auto-collected in main.dart.
    // stateProviders: _providers,
  );

  static Widget _createPage() => const MyGamePage();
  static String _name(AppLocalizations l10n) => l10n.gameNameMyGame;
  static String _description(AppLocalizations l10n) =>
      l10n.gameDescriptionMyGame;
}
```

Then add one line to `lib/core/game_registry.dart`:

```dart
static const List<GameModel> all = [RicochetGame.config, MyGame.config];
```

`sectionId` must match a key in `GameRegistry.sections`. Add a section there if
the game needs a new one, with a `titleL10n` resolver.

---

## 3. The engine / view split

This is the one rule worth internalising: **the simulation never touches
widgets.**

An engine under `engine/` may import `dart:ui` for `Offset` and `Color`, and
nothing else from Flutter. It owns board state, physics, scoring and saves. It
exposes plain fields and methods; the page reads them.

Why it matters:

- The simulation becomes testable headlessly. `test/ricochet_engine_test.dart`
  runs thirteen behavioural tests — volleys resolving, explosion radius, save
  round-trips — with no widget tree and no database.
- A frame's work stays out of the widget tree.
- Rules stay in one readable place instead of spreading across build methods.

Localised text the engine *paints* (score popups, toasts, a level banner)
arrives as a plain value object built by the page — see
`engine/ricochet_strings.dart`. The engine never asks for a `BuildContext`.

---

## 4. The frame clock — if the game needs one

**First decide whether it does.** A game whose board only changes when the
player moves — 2048, Minesweeper — has no frame clock at all. Its engine is a
plain `ChangeNotifier` that fires once per move, and motion comes from implicit
animations: a keyed `AnimatedPositioned` for a slide, a `TweenAnimationBuilder`
for a pop, a short-lived `AnimationController` for a one-off cascade. Running a
60 Hz ticker to animate a board that changes twice a minute is waste.

For a game that does move on its own, use `FrameClock` from
`lib/core/frame_clock.dart`. It wraps the `Ticker`, hands `update` a delta in
seconds, and clamps a stall:

```dart
late final FrameClock _clock = FrameClock(this, _onTick);

void _onTick(double dt) {
  _engine.update(dt);
  _wakeLock.want(_keepScreenAwake && _engine.turnInProgress);
}
```

Start it once the engine has loaded, and register `_clock.dispose` with
`onDispose`. Do not hand-roll the delta arithmetic — that is what the wrapper is
for.

### Fixed step, smooth presentation

A game that moves on a grid should step on a **fixed** interval so it plays the
same on any refresh rate, and expose how far through the current step it is so
the view can interpolate. `SnakeEngine.stepProgress` is the reference: the
simulation is integers, the presentation is fractional, and a six-steps-a-second
snake reads as continuous motion at 60 Hz.

### Never `setState` per frame

Sixty rebuilds a second re-diffs the whole page. Instead the engine exposes two
separate `Listenable`s:

- `frames` — fires every simulated frame. Passed to the `CustomPainter` as
  `repaint:`, so painting happens without rebuilding a single widget.
- `hud` — fires only when a displayed value changes. The HUD and action buttons
  wrap themselves in an `AnimatedBuilder` on this.

Both come from `FrameBeacon` (`lib/core/frame_beacon.dart`); do not write
another one.

### Background turns

A turn that resolves itself (a volley playing out) must survive the app being
backgrounded, where the `Ticker` is silenced. Keep a coarse `Timer.periodic`
running while `turnInProgress` holds, and stop it on resume. Losing a
half-finished turn to a screen lock is indistinguishable from a crash.

### The wake lock

Use `WakeLockGuard` (`lib/services/wake_lock_guard.dart`). Call `want(...)` every
frame with whether a turn is actually resolving; only a change reaches the
platform. Hold it only while something is moving, and honour
`AppState.keepScreenAwake` — idle aiming must never keep a phone's screen lit.
Register `release` with `onDispose`.

---

## 5. Fixed geometry, any screen

A game with a fixed board defines it in logical units:

```dart
class Board {
  static const double width = 480;
  static const double height = 760;
  static const int columns = 13;
  static const double cell = width / columns;
}
```

The painter scales the canvas to fit, and the input layer maps pointer positions
back through the *same* fit. Physics constants never depend on pixel size, so a
phone and a maximised desktop window play the identical game and a save moves
between them unchanged.

The board scales; the HUD around it reflows. `RicochetPage` puts the HUD in a
row above the board when the room is tall and in a column beside it when
`constraints.canSplit` — the same four readouts either way.

---

## 6. Persistence

Wrap `GameStore` in a small per-game store so the engine depends on a named seam
it can be handed a fake of. `GameStore` already owns the guarded read/write pair,
the JSON encoding and the error logging, so the per-game class is only names:

```dart
class MyGameStore {
  const MyGameStore();

  GameStore get _store => GameStore(MyGame.config.id, 'My Game');

  Future<int> loadBest() => _store.readInt('best');
  Future<void> saveBest(int value) => _store.writeInt('best', value);
  Future<Map<String, dynamic>?> loadSave() => _store.readJson('save');
  Future<void> writeSave(Map<String, dynamic> d) => _store.writeJson('save', d);
  Future<void> clearSave() => _store.delete('save');
}
```

Writes never throw: a save is fire-and-forget from a game loop, and a full disk
or a database closing under a page teardown must cost one save, not an unhandled
error.

The engine takes it as an optional constructor argument, defaulting to the real
one. Tests pass an in-memory implementation and never open a database.

Two rules:

- **Save on a timer while dirty, and once on dispose.** Writing every frame
  hammers storage; writing only on exit loses a run to a crash.
- **Validate on load.** Deserialisation drops what it cannot trust rather than
  trusting the blob. A hand-edited save must not be able to produce an
  impossible board or an unknown tile kind.

---

## 7. Audio

Synthesize the effects; do not ship audio files. `WavBuilder` builds small PCM
clips in memory (`tone`, `noise`, `sequence`), which stay in sync with what the
code says they should sound like and cost nothing to add a variant of.

```dart
await GameAudio.instance.register('mygame_hit', WavBuilder.tone(
  frequency: 300, seconds: 0.05, waveform: Waveform.square, gain: 0.09,
));
GameAudio.instance.play('mygame_hit');
```

Register clips once when the page opens; release them on dispose. Set the volume
from `AppState.effectiveVolume`, which already folds the mute switch into the
slider. Every SoLoud call is guarded, so a machine with no audio backend stays
fully playable and silent.

For a sound that varies (a pitch-jittered impact), ship a handful of fixed
variants and pick one at random. Generating a buffer mid-frame is not an option.

---

## 8. Page chrome

Wrap the page in `GameLayout`. By default it is `fullscreen`: no app bar, the
board owns the safe area, and the back button plus any actions float above it.
Pass `fullscreen: false` for a game that wants ordinary chrome.

Register teardown with the `DisposeCleanup` mixin, in `initState`, next to the
thing that needs it:

```dart
onDispose(_clock.dispose);
onDispose(_wakeLock.release);
onDispose(() => unawaited(_engine.saveNow()));
onDispose(_engine.dispose);
onDispose(() => unawaited(GameAudio.instance.releaseAll()));
```

Never override `dispose()` by hand.

### Build the HUD, do not write one

The readouts-plus-controls bar is `GameHud` with a list of `GameStat`s and
`GameHudAction`s; it owns the row/column switch and the compact density on a
narrow phone. The end-of-run panel is `GameResultOverlay`. Swipe and keyboard
input is `DirectionalInput`, which maps arrows, WASD and swipes onto
`GameDirection` and takes a map of game-specific keys. Writing a fifth copy of
any of these is the copy-paste the playbook forbids — and a layout fix in the
shared one lands for every game at once.

---

## 9. Localisation

Add every user-facing string to **both** `lib/l10n/app_en.arb` and
`lib/l10n/app_de.arb`, including the game's own `gameNameMyGame` and
`gameDescriptionMyGame`. Run `flutter gen-l10n`.

Text the engine paints goes through the game's `*_strings.dart` value object,
rebuilt by the page in `didChangeDependencies` so a locale switch lands without
restarting a run.

---

## 10. An in-game reference page

A game with real mechanics earns one. Build it from the game's own painter, not
from a second set of drawings — then the reference cannot drift from what the
player sees on the board. `TilePainter` takes a throwaway `Brick` and a rect and
nothing else, which is exactly what lets `RicochetHelpPage` render the live art.

Register the page in `app.dart` under the game's own path prefix
(`/ricochet/help`).

---

## 11. Tests

At minimum:

- **Generator / rules tests** — invariants that must hold across many seeds:
  nothing spawns out of bounds, difficulty scales, the same seed reproduces the
  same board.
- **Engine tests** — a turn always resolves, an action does what it claims, a
  save round-trips, a corrupt save is rejected.
- **Registry tests** — ids and routes are unique, every game's section exists,
  every localised name is non-empty in every locale.

Assert what the design promises, not what the current implementation happens to
produce. A bomb caught in a cleared row still explodes and takes neighbours with
it; a test that pins an exact survivor count is testing the seed, not the rule.

---

## Checklist

- [ ] `lib/games/<name>/` with `config.dart`, page, `engine/`, `widgets/`
- [ ] One line added to `GameRegistry.all`
- [ ] `sectionId` exists in `GameRegistry.sections`
- [ ] Engine imports no widgets and holds no `BuildContext`
- [ ] A frame clock only if the game actually moves on its own
- [ ] Separate `frames` and `hud` listenables; no per-frame `setState`
- [ ] HUD, result panel and directional input built from the shared widgets
- [ ] Board scales to any size; input maps back through the same fit
- [ ] Saves go through an injectable store and are validated on load
- [ ] Audio registered on open, released on dispose, volume from `AppState`
- [ ] Wake lock held only while a turn resolves, via `WakeLockGuard`
- [ ] README lists the game and its section, and explains nothing
- [ ] All teardown via `onDispose`
- [ ] Every string in both ARB files; `flutter gen-l10n` run
- [ ] `dart format ./lib ./test`, `flutter analyze`, `flutter test` all clean
