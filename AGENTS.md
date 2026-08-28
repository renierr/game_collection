# AI Developer Guidelines & Project Playbook (AGENTS.md)

Welcome, AI Developer. This playbook holds the technical rules, architectural
guardrails and design aesthetics for maintaining and growing the **Game
Collection** codebase — a collection of casual games for Android, Windows and
Linux.

---

## Priority Model

- `ALWAYS`: Hard constraints. Do not violate.
- `PREFER`: Default behaviour. Use unless there is a clear reason not to.

---

## ALWAYS

- **Caveman style**: Short, direct answers. No filler.
- Do not run production compilation or release builds unless explicitly
  requested.
- **Git Write Consent**: Never run git write operations (`git add`,
  `git commit`, `git push`) without fresh explicit approval. A direct "commit"
  request authorises staging and creating one commit for the current work only;
  it does not authorise future commits. A direct "push" request authorises one
  push only. "Fix it" or "proceed" is not approval to commit or push.
- Never mention AI agents in commit messages or code. This includes
  `Co-Authored-By: Claude ...` trailers and any "Generated with Claude Code"
  attribution — omit them entirely.
- **Resilience to Rejected Commands**: If a command is rejected or stopped,
  continue the task and provide the alternative result or plan. A rejected
  command must not abort the overall execution.
- **Game Logic Never Touches Widgets**: A game's simulation lives under
  `lib/games/<name>/engine/` and must not import `package:flutter/material.dart`,
  hold a `BuildContext`, or build a widget. It may use `dart:ui` for `Offset`
  and `Color`. This is what makes the simulation testable headlessly (see
  `test/ricochet_engine_test.dart`) and what keeps a frame's work out of the
  widget tree. Localised text the engine paints arrives through a plain value
  object built by the page — see `engine/ricochet_strings.dart`.
- **State Management & Data Flow**: Global state goes through
  `lib/providers/app_state.dart`. Game-specific state goes in a standalone
  `ChangeNotifier` at `lib/games/<name>/<name>_state.dart`, registered via
  `stateProviders` in the game's `GameModel`. Never keep persistent data in a
  widget's local `setState` fields.
- **Never Rebuild the Widget Tree Per Frame**: A game loop runs at 60 Hz; a
  `setState` on every tick would rebuild and re-diff the whole page sixty times
  a second. Drive painting with a `CustomPainter` whose `repaint:` is a
  frame-level `Listenable`, and give the HUD a *separate* `Listenable` that only
  fires when a displayed value actually changed. `RicochetEngine.frames` and
  `RicochetEngine.hud` are the reference implementation.
- **Resolution-Independent Boards**: A game with fixed geometry defines its
  board in logical units (`lib/games/ricochet/engine/geometry.dart`) and scales
  the whole board to fit. Never make physics constants depend on the widget's
  pixel size — a phone and a maximised desktop window must play the identical
  game, and a save must move between them unchanged. Map pointer positions back
  through the same fit, so aiming lands where the player expects at every scale.
- **Small Screen Fitting**: Always use responsive layouts (`Wrap` rather than a
  horizontal `Row` for action clusters, scrollable metric columns) in dialogs,
  sheets and cards so nothing overflows on a phone.
- **Ask the Right Widget How Much Room There Is**: Three different questions
  look alike at the call site — pick the mechanism by the question, not by habit.
  1. *"How much room do I have?"* — a widget choosing its own layout. Use
     `LayoutBuilder` plus the `BoxConstraints` extension in
     `lib/widgets/responsive_layout.dart`: `constraints.isCompact` / `isMedium` /
     `isExpanded` for device tiers, `constraints.canSplit` for "two panes side
     by side", `constraints.isLandscape` for "which side is the leftover room
     on". Never `MediaQuery` here — inside a pane or a split view the window is
     not the space available.
  2. *"How big is the window?"* — chrome and overlays only: app bar height,
     dialog max height, safe-area padding. Use the aspect accessors —
     `MediaQuery.sizeOf(context)`, `orientationOf`, `paddingOf` — never
     `MediaQuery.of(context)`, which subscribes to every MediaQuery change.
  3. *"Does my own content fit?"* — a toolbar or card row asking whether its own
     children still fit. Use `LayoutBuilder` with a local literal named for the
     reason (`isNarrow`, `cramped`), not a device tier. A card at `< 200` is not
     asking about phones.
  Two decisions taken from the same measurement must share one measurement.
- **Cross-Platform Checks**: Check the platform before using platform-specific
  APIs. Audio and the wake lock must degrade to a no-op rather than throw — a
  Linux VM with no audio backend must stay fully playable and silent
  (`lib/services/game_audio.dart`).
- **Platform Scope**: Android, Windows and Linux. iOS, macOS and web are NOT
  supported and need no handling.
- **Prevent Duplicated UI Code**: Extract dialogs, overlays and recurring
  visual elements to `lib/widgets/` immediately. Never copy-paste presentation
  logic between games.
- **Use Existing Shared Widgets**: Reuse what is in `lib/widgets/` (`GameLayout`,
  `GameCard`, `ReadableWidth`, `SectionHeader`, `ConfirmActionDialog`,
  `FloatingBackButton` — check the directory) rather than writing from scratch.
  Any widget used by two or more games moves to `lib/widgets/`; a game's own
  private components stay under `lib/games/<name>/widgets/`.
- **Page Cleanup on Dispose**: Every game page uses the `DisposeCleanup` mixin
  (`lib/core/game_page_state.dart`) and registers all teardown via `onDispose()`
  in `initState` — tickers, timers, wake locks, audio clips, controllers,
  observers. Never override `dispose()` by hand.
- **No Useless Comments**: Do not add comments that restate the code. Comment
  only what standard code reading would not reveal — a *why*, a caveat, a subtle
  constraint. Never narrate a change, a decision history, or a prompt.
- **Comments Stay Minimal**: Keep every comment as short as it can be. When a
  comment grows past a line or two the fix is almost always to shorten it.
- **Debug Logging**: Use `debugLog()` from `lib/helpers/debug_log.dart` for
  debug-only diagnostics and `errorLog()` for errors that must stay visible
  outside debug builds. Never call `debugPrint()` directly in app code. Never log
  from inside a frame's hot path.
- **Latest Dependencies & Modern APIs**: Use the latest version of a dependency
  available when adding it. Avoid deprecated calls — always
  `.withValues(alpha: ...)` rather than `.withOpacity(...)`.
- **Database Test Isolation**: Database tests must never touch the real
  database. Set `dbPathOverride` to `inMemoryDatabasePath` on
  `DatabaseService.instance` and `close()` in `tearDownAll`. Better still, inject
  a fake store the way `test/ricochet_engine_test.dart` does — then the test
  needs no database at all.
- **Saves Must Survive a Hand Edit**: Deserialisation validates and drops what
  it cannot trust rather than trusting the blob — a save must never be able to
  spawn a brick past the danger line or an unknown tile kind. See
  `RicochetEngine._hydrate`.
- **Temporary Files & Plans**: Use `.agents/temp/` (create if missing) for
  plans, scratch files and agent notes. Never commit that folder.
- **Game ID Single Source of Truth**: Never hardcode a game id string
  (`'ricochet'`) outside its `config.dart`. Reference it via
  `MyGame.config.id` — pages, stores, routes, everywhere.
- **Localise User-Facing Strings**: Never hardcode UI text. Add a key to both
  `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb` and read it via
  `AppLocalizations.of(context).<key>`. See [Core Guardrails §4](#4-localisation-i18n).

---

## PREFER

- Keep answers extremely short and concise. English for code and docs.
- Use explicit return types for methods.
- **Colour Strategy — 3 layers**:
  1. **Per-game palette**: a game with a strong visual identity defines
     `lib/games/<name>/<name>_colors.dart` with `static const` values. These are
     deliberately not theme-abstracted — an arcade board should read the same in
     light and dark mode.
  2. **Semantic status colours in `AppTheme`**: cross-game indicators use
     `AppTheme.statusGreen` / `statusAmber` / `statusRed` in `lib/theme/theme.dart`.
  3. **`Theme.of(context)`**: structural UI — surfaces, text, dividers — uses
     `theme.colorScheme.*` and `theme.textTheme.*`. Never a hardcoded
     `Colors.grey[200]` for chrome.
- **Private Widgets over Helpers**: A method that *builds a subtree* — anything
  beyond a single constructor call — must be a `StatelessWidget` class, not a
  `Widget _buildFoo(...)` method. A helper method has no element of its own, so
  it cannot be `const`, cannot stop a rebuild at its boundary, and re-diffs its
  whole subtree on every enclosing `build()`. Its own file under `widgets/` when
  reused or wide-API; a private `class _Foo extends StatelessWidget` at the
  bottom of the same file is fine for a single-use component.
  - **Not covered**: methods returning `List<Widget>` for a `children:` spread
    (wrapping them would add a container element and change the layout), and
    one-expression delegators that just forward fields.
- **Const Constructors**: prefer `const` widgets wherever possible.
- **Lazy Lists**: prefer `ListView.builder` or slivers for dynamic lists.
- Bind UI to state with `context.watch<T>()` in `build` and `context.read<T>()`
  in callbacks and lifecycle methods. Never `context.watch` outside `build`.
- Cache a settings flag read every frame into a field updated in `build`, rather
  than doing a provider lookup per tick.
- Synthesize sound effects with `lib/helpers/wav_builder.dart` rather than
  shipping audio files. The clips are a few kilobytes, cannot drift from what
  the code says they should sound like, and cost nothing to add a variant of.

---

## Game Architecture

### 1. Game Structure

Each game lives in its own folder under `lib/games/<name>/`:

```
lib/games/<name>/
  config.dart              - Game metadata (GameModel). Owns the id string.
  <name>_page.dart         - Thin coordinator page: drives the engine, composes widgets
  <name>_colors.dart       - Optional per-game palette
  <name>_state.dart        - Optional ChangeNotifier for cross-widget game state
  engine/                  - The simulation. No Flutter widgets, no BuildContext
    geometry.dart
    <name>_engine.dart
    <name>_store.dart      - Persistence, injectable so tests can fake it
    <name>_strings.dart    - Localised text the engine paints
  widgets/                 - REQUIRED for component widgets: one file each
    <name>_board.dart
    <name>_board_painter.dart
    <name>_hud.dart
```

- **`config.dart`** — metadata only. Exports a `static const GameModel config`.
- **`<name>_page.dart`** — must be a thin coordinator: state, the frame clock,
  and a `build` that composes extracted widgets. No inline `_buildFoo` methods.
- **`engine/`** — pure Dart simulation. See the ALWAYS rule *Game Logic Never
  Touches Widgets*.
- **`widgets/`** — ALWAYS place game-specific components here, never inline in
  the page and never scattered at the game root. Non-widget files (models,
  parsers, codecs) may sit at the game root or in a descriptively named
  subfolder.

### 2. Creating a Game

See [`docs/creating-a-game.md`](docs/creating-a-game.md) for the step-by-step
walkthrough: the folder layout, the `GameModel` config, wiring the frame clock,
the engine/view split, persistence, audio and localisation.

### 3. Game Config Pattern

```dart
class MyGame {
  MyGame._();

  static const GameModel config = GameModel(
    id: 'my-game',
    name: 'My Game',
    description: 'What it is',
    icon: Icons.casino_outlined,
    route: '/my-game',
    accentColor: AppTheme.accentTeal,
    sectionId: 'puzzle',
    createPage: _createPage,
    nameL10n: _name,
    descriptionL10n: _description,
  );

  static Widget _createPage() => const MyGamePage();
  static String _name(AppLocalizations l10n) => l10n.gameNameMyGame;
  static String _description(AppLocalizations l10n) => l10n.gameDescriptionMyGame;
}
```

### 4. Routing

Routes are generated from `GameRegistry.all` in `lib/app.dart` — a game's
`route` becomes a `GoRouter` path and its `createPage` builds the page. No
manual switch. A page a game pushes on top of itself (a help screen) is listed
explicitly in `app.dart` under the game's own path prefix.

Game state providers declared via `stateProviders` are auto-collected into
`main.dart`'s `MultiProvider` — no manual registration either.

### 5. Storage

- **Per-game data** (saves, high scores, options): `DatabaseService.instance`
  (`lib/services/database_service.dart`) — `setSetting` / `getSetting` /
  `getAllSettings`, keyed by game id. Wrap it in a small per-game store class so
  the engine depends on an injectable seam rather than on the database.
- **Global settings** (theme, locale, sound, wake lock): go through `AppState`,
  which persists via `SettingsService` into the same table under the `_app` id.
- A game that needs a real table adds it in `DatabaseService._onCreate` and
  bumps `_dbVersion` with a migration.

### 6. Audio

- `GameAudio.instance` (`lib/services/game_audio.dart`) owns SoLoud. Register
  clips by key once when the page opens, then fire them by key; release them on
  dispose. Every call is guarded, so no-audio machines stay playable.
- Build clips with `WavBuilder` (`lib/helpers/wav_builder.dart`): `tone`,
  `noise`, `sequence`.
- Volume comes from `AppState.effectiveVolume`, which folds the mute switch into
  the slider — never read the two separately.

---

## Core Guardrails

### 1. State Management & UI Binding

- Standard: `provider` + `ChangeNotifier` (`AppState` in
  `lib/providers/app_state.dart`).
- Game-specific state: a standalone `ChangeNotifier`, registered via
  `stateProviders` in `GameModel`.
- A game's per-frame state is *not* provider state — see the ALWAYS rule *Never
  Rebuild the Widget Tree Per Frame*.

### 2. Styling & Layouts

- Theme values from `AppTheme` in `lib/theme/theme.dart`. No hardcoded hex in
  chrome; a game's own board palette is the documented exception.
- Breakpoints and tiers live in `lib/widgets/responsive_layout.dart`:
  `Breakpoints.mobile` (600), `.tablet` (900), `.split` (720),
  `.readableContent` (900), the `LayoutSizeClass` enum and the `BoxConstraints`
  extension. Never hardcode a device-tier number in a game.
- **Cap or reflow on wide screens.** Wrap a *scrollable* — not its rows, which
  would strand the scrollbar — in `ReadableWidth` for settings columns and text
  pages; use a grid delegate instead when items are card-shaped and extra width
  should become more columns. A game board wants the room and stays uncapped.
- A game board scales; it does not reflow by tier. The HUD around it does.

### 3. Navigation

- Standard: `go_router` for declarative routing. A fullscreen game page gets its
  back affordance from `GameLayout`.

### 4. Localisation (i18n)

- English (`en`) and German (`de`) via Flutter's `gen_l10n`. ARB sources are
  `lib/l10n/app_en.arb` (template) and `lib/l10n/app_de.arb`; config is
  `l10n.yaml`.
- **All new user-facing strings must be localised.** Add the key to **both** ARB
  files and read it via `AppLocalizations.of(context).<key>`. `en` is the
  template — every key added there must also exist in `de`.
- Regenerate with `flutter gen-l10n` (also runs on `flutter pub get` and builds,
  since `generate: true`). `lib/l10n/app_localizations*.dart` is generated —
  never edit it by hand.
- The active locale is driven by `AppState.locale` (`null` follows the system)
  and set in the Appearance settings page.
- `GameModel` names/descriptions and `GameSection` titles are localised
  per-game: set `nameL10n` / `descriptionL10n` (and `titleL10n` on a section) in
  `config.dart`. These take `AppLocalizations`, never a `BuildContext`. The raw
  `name` / `description` stay as fallbacks. Display code reads
  `game.localizedName(l10n)` — never `.name` directly for UI. There is no
  central id→string switch: a new game edits only its own `config.dart` and the
  ARB files.
- Text the engine paints goes through the game's `*_strings.dart` value object,
  rebuilt by the page in `didChangeDependencies` so a locale switch lands
  without restarting a run.

---

## Dependencies

Declared in `pubspec.yaml`. Check there before adding a package.

---

## Verification Procedures

*Formatting and static analysis are only required when Dart source changes. They
are unnecessary for markdown, images or static assets.*

1. **Formatting**: `dart format ./lib ./test`
2. **Analysis**: `flutter analyze`
3. **Tests**: `flutter test`

`./build.sh help` lists the release build and packaging targets.
