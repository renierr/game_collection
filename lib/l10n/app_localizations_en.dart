// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonSettings => 'Settings';

  @override
  String get overviewSearchHint => 'Search games';

  @override
  String get overviewNoGamesFound => 'No games found';

  @override
  String get overviewAddFavorite => 'Add to favorites';

  @override
  String get overviewRemoveFavorite => 'Remove from favorites';

  @override
  String get sectionTitleArcade => 'Arcade';

  @override
  String get sectionTitlePuzzle => 'Puzzle';

  @override
  String get settingsDialogTitle => 'Settings';

  @override
  String get settingsDialogAppearanceSubtitle => 'Theme, language, layout';

  @override
  String get settingsDialogGameplaySubtitle => 'Sound, screen, saved data';

  @override
  String get settingsDialogAboutSubtitle => 'Version and licenses';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageGerman => 'German';

  @override
  String get settingsCompactView => 'Compact view';

  @override
  String get settingsCompactViewSubtitle => 'Smaller cards, more games per row';

  @override
  String get settingsSortBy => 'Sort by';

  @override
  String get settingsSortRecent => 'Recently played';

  @override
  String get settingsSortDefaultOrder => 'Default order';

  @override
  String get settingsSortName => 'Name';

  @override
  String get gameplayTitle => 'Gameplay';

  @override
  String get settingsSound => 'Sound effects';

  @override
  String get settingsSoundSubtitle => 'Play the in-game sound effects';

  @override
  String get settingsVolume => 'Volume';

  @override
  String get settingsKeepScreenAwake => 'Keep screen awake';

  @override
  String get settingsKeepScreenAwakeSubtitle =>
      'Hold the screen on while a turn plays out';

  @override
  String get settingsHaptics => 'Haptic feedback';

  @override
  String get settingsHapticsSubtitle => 'Vibrate on impacts and level changes';

  @override
  String get settingsResetData => 'Reset all game data';

  @override
  String get settingsResetDataSubtitle =>
      'Deletes every save, high score and preference';

  @override
  String get settingsResetDataConfirm =>
      'This permanently deletes every saved run, high score and preference. It cannot be undone.';

  @override
  String get settingsResetDataDone => 'All game data has been reset';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'A collection of casual games for Android, Windows and Linux. Every game runs fully offline — no accounts, no ads, no tracking.';

  @override
  String aboutGamesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games installed',
      one: '1 game installed',
    );
    return '$_temp0';
  }

  @override
  String get aboutLicense => 'License';

  @override
  String get aboutThirdPartyLicenses => 'Third-party licenses';

  @override
  String get gameNameRicochet => 'Ricochet';

  @override
  String get gameDescriptionRicochet =>
      'Aim a volley of bouncing balls and crush numbered bricks across endless self-generating levels.';

  @override
  String get ricochetScore => 'Score';

  @override
  String get ricochetBest => 'Best';

  @override
  String get ricochetLevel => 'Level';

  @override
  String get ricochetBalls => 'Balls';

  @override
  String get ricochetPowerMenu => 'Power-ups';

  @override
  String get ricochetRestartLevel => 'Replay this level';

  @override
  String get ricochetHowToPlay => 'How to play';

  @override
  String get ricochetRecall => 'Recall';

  @override
  String get ricochetSpeed => 'Speed';

  @override
  String ricochetSpeedActive(int multiplier) {
    return 'Speed ×$multiplier';
  }

  @override
  String get ricochetGameOver => 'GAME OVER';

  @override
  String get ricochetNewBest => 'New best score!';

  @override
  String ricochetBestScore(int best) {
    return 'Best: $best';
  }

  @override
  String ricochetReachedLevel(int level) {
    return 'Reached level $level';
  }

  @override
  String get ricochetRetryLevel => 'Retry level';

  @override
  String get ricochetStartOver => 'Start over';

  @override
  String get ricochetPowerBalls => '+10 Balls';

  @override
  String get ricochetPowerBallsDesc => 'Adds 10 balls to your stash';

  @override
  String get ricochetPowerPierce => 'Pierce volley';

  @override
  String get ricochetPowerPierceDesc =>
      'One ball drills straight through bricks';

  @override
  String get ricochetPowerBomb => 'Bomb volley';

  @override
  String get ricochetPowerBombDesc => 'One ball explodes on every impact';

  @override
  String get ricochetPowerClearRow => 'Clear row';

  @override
  String get ricochetPowerClearRowDesc => 'Wipes the lowest brick row';

  @override
  String get ricochetToastPierceArmed => 'PIERCE ARMED';

  @override
  String get ricochetToastBombArmed => 'BOMB ARMED';

  @override
  String get ricochetToastRecalled => 'RECALLED';

  @override
  String get ricochetToastRowCleared => 'ROW CLEARED';

  @override
  String get ricochetToastPlusOneBall => '+1 BALL';

  @override
  String get ricochetHintDragToAim => 'Drag anywhere to aim';

  @override
  String get ricochetChipPierce => 'PIERCE';

  @override
  String get ricochetChipBomb => 'BOMB';

  @override
  String ricochetToastPlusBalls(int count) {
    return '+$count BALLS';
  }

  @override
  String ricochetToastSpeed(int multiplier) {
    return 'SPEED ×$multiplier';
  }

  @override
  String ricochetToastAutoSpeed(int multiplier) {
    return 'AUTO SPEED ×$multiplier';
  }

  @override
  String ricochetBannerLevel(int level) {
    return 'LEVEL $level';
  }

  @override
  String ricochetPopupDoubled(int points) {
    return '+$points x2!';
  }

  @override
  String get ricochetHelpTitle => 'How to play Ricochet';

  @override
  String get ricochetHelpBasicsTitle => 'The basics';

  @override
  String get ricochetHelpBasicsAim =>
      'Drag anywhere on the board to aim — a dashed preview shows the trajectory and the first impact.';

  @override
  String get ricochetHelpBasicsFire =>
      'Release to fire. Up to 100 balls launch per turn, staggered, ricocheting off walls and bricks.';

  @override
  String get ricochetHelpBasicsHp =>
      'Every brick shows its HP; each hit removes 1. At 0 it shatters for points.';

  @override
  String get ricochetHelpBasicsDrop =>
      'After every volley the board drops one row. If any brick crosses the red danger line, the run ends.';

  @override
  String get ricochetHelpBasicsClear =>
      'Clear the whole board to complete the level: a score bonus, +2 balls, and a freshly generated next board.';

  @override
  String get ricochetHelpBasicsPickup =>
      'Green (+) pickups are collected on touch and permanently add a ball.';

  @override
  String get ricochetHelpBasicsCharges =>
      'Banked pierce and bomb charges show as chips just above the launcher — they stay put wherever it slides to. Charges stack: bank several and several balls of your next volley inherit the effect.';

  @override
  String get ricochetHelpTilesTitle => 'Tile reference';

  @override
  String get ricochetHelpTilesIntro =>
      'Except the (+) pickup, every tile carries HP and breaks like a normal brick. The effect is what happens in addition.';

  @override
  String get ricochetTileBrick => 'Brick';

  @override
  String get ricochetTileBrickEffect =>
      'Plain target. Points = max HP × 10 + level × 2. The colour tracks how tough it is.';

  @override
  String get ricochetTileBomb => 'Bomb';

  @override
  String get ricochetTileBombEffect =>
      'Dies to a single hit regardless of HP and explodes: everything within about two cells takes lethal damage. Chains through other bombs.';

  @override
  String get ricochetTileGift => 'Gift (?)';

  @override
  String get ricochetTileGiftEffect =>
      'On destruction fires one random power-up: +10 balls, a pierce charge, a bomb charge or clear row.';

  @override
  String get ricochetTileMult => '×2 multiplier';

  @override
  String get ricochetTileMultEffect =>
      'Pays double points when destroyed, with its own popup.';

  @override
  String get ricochetTilePierce => 'Pierce';

  @override
  String get ricochetTilePierceEffect =>
      'Banks a pierce charge. One ball of your next volley drills straight through bricks instead of bouncing, damaging each brick it passes once.';

  @override
  String get ricochetTileBlast => 'Blast';

  @override
  String get ricochetTileBlastEffect =>
      'Banks a bomb charge. One ball of your next volley explodes on every impact for up to 50 damage in a radius.';

  @override
  String get ricochetTileRamp => 'Ramp';

  @override
  String get ricochetTileRampEffect =>
      'A solid triangle filling half its cell. The 45° slope deflects the ball a quarter turn; the two flat legs bounce like an ordinary tile, and the empty half of the cell is air the ball passes straight through.';

  @override
  String get ricochetTileOrb => 'Orb';

  @override
  String get ricochetTileOrbEffect =>
      'A round bumper: reflects off its curved surface instead of a flat face, so outgoing angles fan out from where it was struck. Being round, the corners of its cell are empty air.';

  @override
  String get ricochetTilePickup => '(+) pickup';

  @override
  String get ricochetTilePickupEffect =>
      'Not a brick — no HP, cannot be shot away. Collected on touch for a permanent +1 ball.';

  @override
  String get ricochetHelpDeflectorsTitle => 'What bends a ball';

  @override
  String get ricochetHelpDeflectorsIntro =>
      'Ramps and orbs are the only tiles that change a ball\'s direction beyond a flat bounce. Both have a short per-ball cooldown, so a ball cannot get stuck rattling inside a cluster of them.';

  @override
  String get ricochetHelpRampA =>
      'A ‘/’ ramp turns a falling ball to the left.';

  @override
  String get ricochetHelpRampB =>
      'A ‘\\’ ramp turns the same ball the other way.';

  @override
  String get ricochetHelpOrbDemo =>
      'An orb fans the ball out from wherever it was struck.';

  @override
  String get ricochetHelpControlsTitle => 'Controls';

  @override
  String get ricochetHelpControlsDrag => 'Drag and release — aim and fire.';

  @override
  String get ricochetHelpControlsRecall =>
      'Recall — instantly pulls all balls back, so a stuck shot can never trap you.';

  @override
  String get ricochetHelpControlsSpeed =>
      'Speed — each press stacks another boost, up to ×10, until the turn ends. It kicks in on its own at ×3 if a volley drags past six seconds.';

  @override
  String get ricochetHelpControlsMenu =>
      'Power-ups — open the menu for unlimited-use charges.';

  @override
  String get ricochetHelpControlsRestart =>
      'Replay — restarts the current level from its start.';

  @override
  String get ricochetHelpKeyboardTitle => 'Keyboard';

  @override
  String get ricochetHelpKeyboardAim =>
      'Left / Right (or A / D) — swing the sight. Hold Shift for fine aim.';

  @override
  String get ricochetHelpKeyboardFire =>
      'Space or Enter — fire the shot the sight is holding.';

  @override
  String get ricochetHelpKeyboardRecall =>
      'R — recall the balls. F — speed up the volley.';

  @override
  String get ricochetHelpKeyboardMenu =>
      'P — power-ups. H — this page. M — mute.';

  @override
  String get ricochetHelpLevelsTitle => 'Level design';

  @override
  String get ricochetHelpLevelsText =>
      'Every board is cut from one of nineteen hand-drawn stencils, auto-centred on the 13-column grid and randomly mirrored. A clear zone above the danger line is guaranteed, so every tile is reachable. Tall compositions may start above the top edge and slide into view one row per turn. From level 8 two stencils usually stack into one bigger composition. Brick HP scales forever with the level, and the exotic tiles unlock as you climb: blast at level 3, pierce at 5, orbs at 7, ramps at 10.';

  @override
  String get ricochetHelpProgressTitle => 'Progress';

  @override
  String get ricochetHelpProgressText =>
      'Level, score, ball count and the current board are saved automatically — leave mid-level and resume where you left off. Your best score persists across runs. On game over you can retry the level, restored exactly as it looked when the level began, or start over from level 1.';

  @override
  String get commonScore => 'Score';

  @override
  String get commonBest => 'Best';

  @override
  String commonBestScore(int best) {
    return 'Best: $best';
  }

  @override
  String get commonNewBest => 'New best!';

  @override
  String get commonNewGame => 'New game';

  @override
  String get commonGameOver => 'Game over';

  @override
  String get commonPause => 'Pause';

  @override
  String get commonResume => 'Resume';

  @override
  String get commonPaused => 'Paused';

  @override
  String get commonMute => 'Mute';

  @override
  String get commonUnmute => 'Unmute';

  @override
  String get gameName2048 => '2048';

  @override
  String get gameDescription2048 =>
      'Swipe to slide the board, merge equal tiles, and chase a single 2048 out of a grid that keeps filling up.';

  @override
  String get twenty48Moves => 'Moves';

  @override
  String get twenty48Highest => 'Highest';

  @override
  String get twenty48Undo => 'Undo move';

  @override
  String get twenty48NoMovesLeft => 'No moves left';

  @override
  String twenty48ReachedTile(int value) {
    return 'Highest tile: $value';
  }

  @override
  String get twenty48YouWin => '2048 reached';

  @override
  String twenty48WinSubtitle(int score) {
    return 'You got there with $score points. Keep going for a higher tile.';
  }

  @override
  String get twenty48KeepPlaying => 'Keep playing';

  @override
  String get gameNameSnake => 'Snake';

  @override
  String get gameDescriptionSnake =>
      'Eat, grow, and keep the tail out of your own way as the board fills and the pace never lets up.';

  @override
  String get snakeLength => 'Length';

  @override
  String get snakeSpeed => 'Cells/s';

  @override
  String snakeFinalLength(int length) {
    return 'Final length: $length';
  }

  @override
  String get snakeTapToStart => 'Swipe or press an arrow key to start';

  @override
  String get gameNameMinesweeper => 'Minesweeper';

  @override
  String get gameDescriptionMinesweeper =>
      'Read the numbers, flag what you can prove, and clear the field without guessing. The first click is always safe.';

  @override
  String get minesweeperMines => 'Mines';

  @override
  String get minesweeperTime => 'Time';

  @override
  String get minesweeperBeginner => 'Beginner';

  @override
  String get minesweeperIntermediate => 'Intermediate';

  @override
  String get minesweeperExpert => 'Expert';

  @override
  String get minesweeperFlagModeOn => 'Flag mode on — tap to flag';

  @override
  String get minesweeperFlagModeOff => 'Flag mode off — tap to uncover';

  @override
  String get minesweeperCleared => 'Field cleared';

  @override
  String get minesweeperBoom => 'Boom';

  @override
  String get minesweeperBoomSubtitle => 'You hit a mine.';

  @override
  String minesweeperBestTime(String time) {
    return 'Best: $time';
  }

  @override
  String minesweeperOnLevel(String level) {
    return 'on $level';
  }

  @override
  String get gameNameTetris => 'Tetris';

  @override
  String get gameDescriptionTetris =>
      'Stack falling blocks into full rows. Modern rules throughout: wall kicks, a hold slot, a ghost drop and a seven-bag shuffle.';

  @override
  String get tetrisLines => 'Lines';

  @override
  String get tetrisLevel => 'Level';

  @override
  String get tetrisHold => 'Hold';

  @override
  String get tetrisNext => 'Next';

  @override
  String get tetrisMoveLeft => 'Move left';

  @override
  String get tetrisMoveRight => 'Move right';

  @override
  String get tetrisRotateLeft => 'Rotate left';

  @override
  String get tetrisRotateRight => 'Rotate right';

  @override
  String get tetrisSoftDrop => 'Soft drop';

  @override
  String get tetrisHardDrop => 'Hard drop';

  @override
  String tetrisClearedLines(int lines, int level) {
    return '$lines lines, level $level';
  }
}
