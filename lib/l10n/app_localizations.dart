import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @overviewSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search games'**
  String get overviewSearchHint;

  /// No description provided for @overviewNoGamesFound.
  ///
  /// In en, this message translates to:
  /// **'No games found'**
  String get overviewNoGamesFound;

  /// No description provided for @overviewAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get overviewAddFavorite;

  /// No description provided for @overviewRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get overviewRemoveFavorite;

  /// No description provided for @sectionTitleArcade.
  ///
  /// In en, this message translates to:
  /// **'Arcade'**
  String get sectionTitleArcade;

  /// No description provided for @sectionTitlePuzzle.
  ///
  /// In en, this message translates to:
  /// **'Puzzle'**
  String get sectionTitlePuzzle;

  /// No description provided for @settingsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsDialogTitle;

  /// No description provided for @settingsDialogAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, language, layout'**
  String get settingsDialogAppearanceSubtitle;

  /// No description provided for @settingsDialogGameplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sound, screen, saved data'**
  String get settingsDialogGameplaySubtitle;

  /// No description provided for @settingsDialogAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version and licenses'**
  String get settingsDialogAboutSubtitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get settingsLanguageGerman;

  /// No description provided for @settingsCompactView.
  ///
  /// In en, this message translates to:
  /// **'Compact view'**
  String get settingsCompactView;

  /// No description provided for @settingsCompactViewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smaller cards, more games per row'**
  String get settingsCompactViewSubtitle;

  /// No description provided for @settingsSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get settingsSortBy;

  /// No description provided for @settingsSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get settingsSortRecent;

  /// No description provided for @settingsSortDefaultOrder.
  ///
  /// In en, this message translates to:
  /// **'Default order'**
  String get settingsSortDefaultOrder;

  /// No description provided for @settingsSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsSortName;

  /// No description provided for @gameplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Gameplay'**
  String get gameplayTitle;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingsSound;

  /// No description provided for @settingsSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play the in-game sound effects'**
  String get settingsSoundSubtitle;

  /// No description provided for @settingsVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get settingsVolume;

  /// No description provided for @settingsKeepScreenAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep screen awake'**
  String get settingsKeepScreenAwake;

  /// No description provided for @settingsKeepScreenAwakeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold the screen on while a turn plays out'**
  String get settingsKeepScreenAwakeSubtitle;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on impacts and level changes'**
  String get settingsHapticsSubtitle;

  /// No description provided for @settingsResetData.
  ///
  /// In en, this message translates to:
  /// **'Reset all game data'**
  String get settingsResetData;

  /// No description provided for @settingsResetDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deletes every save, high score and preference'**
  String get settingsResetDataSubtitle;

  /// No description provided for @settingsResetDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes every saved run, high score and preference. It cannot be undone.'**
  String get settingsResetDataConfirm;

  /// No description provided for @settingsResetDataDone.
  ///
  /// In en, this message translates to:
  /// **'All game data has been reset'**
  String get settingsResetDataDone;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A collection of casual games for Android, Windows and Linux. Every game runs fully offline — no accounts, no ads, no tracking.'**
  String get aboutDescription;

  /// No description provided for @aboutGamesInstalled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 game installed} other{{count} games installed}}'**
  String aboutGamesInstalled(int count);

  /// No description provided for @aboutLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get aboutLicense;

  /// No description provided for @aboutThirdPartyLicenses.
  ///
  /// In en, this message translates to:
  /// **'Third-party licenses'**
  String get aboutThirdPartyLicenses;

  /// No description provided for @gameNameRicochet.
  ///
  /// In en, this message translates to:
  /// **'Ricochet'**
  String get gameNameRicochet;

  /// No description provided for @gameDescriptionRicochet.
  ///
  /// In en, this message translates to:
  /// **'Aim a volley of bouncing balls and crush numbered bricks across endless self-generating levels.'**
  String get gameDescriptionRicochet;

  /// No description provided for @ricochetScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get ricochetScore;

  /// No description provided for @ricochetBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get ricochetBest;

  /// No description provided for @ricochetLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get ricochetLevel;

  /// No description provided for @ricochetBalls.
  ///
  /// In en, this message translates to:
  /// **'Balls'**
  String get ricochetBalls;

  /// No description provided for @ricochetPowerMenu.
  ///
  /// In en, this message translates to:
  /// **'Power-ups'**
  String get ricochetPowerMenu;

  /// No description provided for @ricochetRestartLevel.
  ///
  /// In en, this message translates to:
  /// **'Replay this level'**
  String get ricochetRestartLevel;

  /// No description provided for @ricochetHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get ricochetHowToPlay;

  /// No description provided for @ricochetRecall.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get ricochetRecall;

  /// No description provided for @ricochetSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get ricochetSpeed;

  /// No description provided for @ricochetSpeedActive.
  ///
  /// In en, this message translates to:
  /// **'Speed ×{multiplier}'**
  String ricochetSpeedActive(int multiplier);

  /// No description provided for @ricochetGameOver.
  ///
  /// In en, this message translates to:
  /// **'GAME OVER'**
  String get ricochetGameOver;

  /// No description provided for @ricochetNewBest.
  ///
  /// In en, this message translates to:
  /// **'New best score!'**
  String get ricochetNewBest;

  /// No description provided for @ricochetBestScore.
  ///
  /// In en, this message translates to:
  /// **'Best: {best}'**
  String ricochetBestScore(int best);

  /// No description provided for @ricochetReachedLevel.
  ///
  /// In en, this message translates to:
  /// **'Reached level {level}'**
  String ricochetReachedLevel(int level);

  /// No description provided for @ricochetRetryLevel.
  ///
  /// In en, this message translates to:
  /// **'Retry level'**
  String get ricochetRetryLevel;

  /// No description provided for @ricochetStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get ricochetStartOver;

  /// No description provided for @ricochetPowerBalls.
  ///
  /// In en, this message translates to:
  /// **'+10 Balls'**
  String get ricochetPowerBalls;

  /// No description provided for @ricochetPowerBallsDesc.
  ///
  /// In en, this message translates to:
  /// **'Adds 10 balls to your stash'**
  String get ricochetPowerBallsDesc;

  /// No description provided for @ricochetPowerPierce.
  ///
  /// In en, this message translates to:
  /// **'Pierce volley'**
  String get ricochetPowerPierce;

  /// No description provided for @ricochetPowerPierceDesc.
  ///
  /// In en, this message translates to:
  /// **'One ball drills straight through bricks'**
  String get ricochetPowerPierceDesc;

  /// No description provided for @ricochetPowerBomb.
  ///
  /// In en, this message translates to:
  /// **'Bomb volley'**
  String get ricochetPowerBomb;

  /// No description provided for @ricochetPowerBombDesc.
  ///
  /// In en, this message translates to:
  /// **'One ball explodes on every impact'**
  String get ricochetPowerBombDesc;

  /// No description provided for @ricochetPowerClearRow.
  ///
  /// In en, this message translates to:
  /// **'Clear row'**
  String get ricochetPowerClearRow;

  /// No description provided for @ricochetPowerClearRowDesc.
  ///
  /// In en, this message translates to:
  /// **'Wipes the lowest brick row'**
  String get ricochetPowerClearRowDesc;

  /// No description provided for @ricochetToastPierceArmed.
  ///
  /// In en, this message translates to:
  /// **'PIERCE ARMED'**
  String get ricochetToastPierceArmed;

  /// No description provided for @ricochetToastBombArmed.
  ///
  /// In en, this message translates to:
  /// **'BOMB ARMED'**
  String get ricochetToastBombArmed;

  /// No description provided for @ricochetToastRecalled.
  ///
  /// In en, this message translates to:
  /// **'RECALLED'**
  String get ricochetToastRecalled;

  /// No description provided for @ricochetToastRowCleared.
  ///
  /// In en, this message translates to:
  /// **'ROW CLEARED'**
  String get ricochetToastRowCleared;

  /// No description provided for @ricochetToastPlusOneBall.
  ///
  /// In en, this message translates to:
  /// **'+1 BALL'**
  String get ricochetToastPlusOneBall;

  /// No description provided for @ricochetHintDragToAim.
  ///
  /// In en, this message translates to:
  /// **'Drag anywhere to aim'**
  String get ricochetHintDragToAim;

  /// No description provided for @ricochetChipPierce.
  ///
  /// In en, this message translates to:
  /// **'PIERCE'**
  String get ricochetChipPierce;

  /// No description provided for @ricochetChipBomb.
  ///
  /// In en, this message translates to:
  /// **'BOMB'**
  String get ricochetChipBomb;

  /// No description provided for @ricochetToastPlusBalls.
  ///
  /// In en, this message translates to:
  /// **'+{count} BALLS'**
  String ricochetToastPlusBalls(int count);

  /// No description provided for @ricochetToastSpeed.
  ///
  /// In en, this message translates to:
  /// **'SPEED ×{multiplier}'**
  String ricochetToastSpeed(int multiplier);

  /// No description provided for @ricochetToastAutoSpeed.
  ///
  /// In en, this message translates to:
  /// **'AUTO SPEED ×{multiplier}'**
  String ricochetToastAutoSpeed(int multiplier);

  /// No description provided for @ricochetBannerLevel.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {level}'**
  String ricochetBannerLevel(int level);

  /// No description provided for @ricochetPopupDoubled.
  ///
  /// In en, this message translates to:
  /// **'+{points} x2!'**
  String ricochetPopupDoubled(int points);

  /// No description provided for @ricochetHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play Ricochet'**
  String get ricochetHelpTitle;

  /// No description provided for @ricochetHelpBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'The basics'**
  String get ricochetHelpBasicsTitle;

  /// No description provided for @ricochetHelpBasicsAim.
  ///
  /// In en, this message translates to:
  /// **'Drag anywhere on the board to aim — a dashed preview shows the trajectory and the first impact.'**
  String get ricochetHelpBasicsAim;

  /// No description provided for @ricochetHelpBasicsFire.
  ///
  /// In en, this message translates to:
  /// **'Release to fire. Up to 100 balls launch per turn, staggered, ricocheting off walls and bricks.'**
  String get ricochetHelpBasicsFire;

  /// No description provided for @ricochetHelpBasicsHp.
  ///
  /// In en, this message translates to:
  /// **'Every brick shows its HP; each hit removes 1. At 0 it shatters for points.'**
  String get ricochetHelpBasicsHp;

  /// No description provided for @ricochetHelpBasicsDrop.
  ///
  /// In en, this message translates to:
  /// **'After every volley the board drops one row. If any brick crosses the red danger line, the run ends.'**
  String get ricochetHelpBasicsDrop;

  /// No description provided for @ricochetHelpBasicsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the whole board to complete the level: a score bonus, +2 balls, and a freshly generated next board.'**
  String get ricochetHelpBasicsClear;

  /// No description provided for @ricochetHelpBasicsPickup.
  ///
  /// In en, this message translates to:
  /// **'Green (+) pickups are collected on touch and permanently add a ball.'**
  String get ricochetHelpBasicsPickup;

  /// No description provided for @ricochetHelpBasicsCharges.
  ///
  /// In en, this message translates to:
  /// **'Banked pierce and bomb charges show as chips just above the launcher — they stay put wherever it slides to. Charges stack: bank several and several balls of your next volley inherit the effect.'**
  String get ricochetHelpBasicsCharges;

  /// No description provided for @ricochetHelpTilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Tile reference'**
  String get ricochetHelpTilesTitle;

  /// No description provided for @ricochetHelpTilesIntro.
  ///
  /// In en, this message translates to:
  /// **'Except the (+) pickup, every tile carries HP and breaks like a normal brick. The effect is what happens in addition.'**
  String get ricochetHelpTilesIntro;

  /// No description provided for @ricochetTileBrick.
  ///
  /// In en, this message translates to:
  /// **'Brick'**
  String get ricochetTileBrick;

  /// No description provided for @ricochetTileBrickEffect.
  ///
  /// In en, this message translates to:
  /// **'Plain target. Points = max HP × 10 + level × 2. The colour tracks how tough it is.'**
  String get ricochetTileBrickEffect;

  /// No description provided for @ricochetTileBomb.
  ///
  /// In en, this message translates to:
  /// **'Bomb'**
  String get ricochetTileBomb;

  /// No description provided for @ricochetTileBombEffect.
  ///
  /// In en, this message translates to:
  /// **'Dies to a single hit regardless of HP and explodes: everything within about two cells takes lethal damage. Chains through other bombs.'**
  String get ricochetTileBombEffect;

  /// No description provided for @ricochetTileGift.
  ///
  /// In en, this message translates to:
  /// **'Gift (?)'**
  String get ricochetTileGift;

  /// No description provided for @ricochetTileGiftEffect.
  ///
  /// In en, this message translates to:
  /// **'On destruction fires one random power-up: +10 balls, a pierce charge, a bomb charge or clear row.'**
  String get ricochetTileGiftEffect;

  /// No description provided for @ricochetTileMult.
  ///
  /// In en, this message translates to:
  /// **'×2 multiplier'**
  String get ricochetTileMult;

  /// No description provided for @ricochetTileMultEffect.
  ///
  /// In en, this message translates to:
  /// **'Pays double points when destroyed, with its own popup.'**
  String get ricochetTileMultEffect;

  /// No description provided for @ricochetTilePierce.
  ///
  /// In en, this message translates to:
  /// **'Pierce'**
  String get ricochetTilePierce;

  /// No description provided for @ricochetTilePierceEffect.
  ///
  /// In en, this message translates to:
  /// **'Banks a pierce charge. One ball of your next volley drills straight through bricks instead of bouncing, damaging each brick it passes once.'**
  String get ricochetTilePierceEffect;

  /// No description provided for @ricochetTileBlast.
  ///
  /// In en, this message translates to:
  /// **'Blast'**
  String get ricochetTileBlast;

  /// No description provided for @ricochetTileBlastEffect.
  ///
  /// In en, this message translates to:
  /// **'Banks a bomb charge. One ball of your next volley explodes on every impact for up to 50 damage in a radius.'**
  String get ricochetTileBlastEffect;

  /// No description provided for @ricochetTileRamp.
  ///
  /// In en, this message translates to:
  /// **'Ramp'**
  String get ricochetTileRamp;

  /// No description provided for @ricochetTileRampEffect.
  ///
  /// In en, this message translates to:
  /// **'A solid triangle filling half its cell. The 45° slope deflects the ball a quarter turn; the two flat legs bounce like an ordinary tile, and the empty half of the cell is air the ball passes straight through.'**
  String get ricochetTileRampEffect;

  /// No description provided for @ricochetTileOrb.
  ///
  /// In en, this message translates to:
  /// **'Orb'**
  String get ricochetTileOrb;

  /// No description provided for @ricochetTileOrbEffect.
  ///
  /// In en, this message translates to:
  /// **'A round bumper: reflects off its curved surface instead of a flat face, so outgoing angles fan out from where it was struck. Being round, the corners of its cell are empty air.'**
  String get ricochetTileOrbEffect;

  /// No description provided for @ricochetTilePickup.
  ///
  /// In en, this message translates to:
  /// **'(+) pickup'**
  String get ricochetTilePickup;

  /// No description provided for @ricochetTilePickupEffect.
  ///
  /// In en, this message translates to:
  /// **'Not a brick — no HP, cannot be shot away. Collected on touch for a permanent +1 ball.'**
  String get ricochetTilePickupEffect;

  /// No description provided for @ricochetHelpDeflectorsTitle.
  ///
  /// In en, this message translates to:
  /// **'What bends a ball'**
  String get ricochetHelpDeflectorsTitle;

  /// No description provided for @ricochetHelpDeflectorsIntro.
  ///
  /// In en, this message translates to:
  /// **'Ramps and orbs are the only tiles that change a ball\'s direction beyond a flat bounce. Both have a short per-ball cooldown, so a ball cannot get stuck rattling inside a cluster of them.'**
  String get ricochetHelpDeflectorsIntro;

  /// No description provided for @ricochetHelpRampA.
  ///
  /// In en, this message translates to:
  /// **'A ‘/’ ramp turns a falling ball to the left.'**
  String get ricochetHelpRampA;

  /// No description provided for @ricochetHelpRampB.
  ///
  /// In en, this message translates to:
  /// **'A ‘\\’ ramp turns the same ball the other way.'**
  String get ricochetHelpRampB;

  /// No description provided for @ricochetHelpOrbDemo.
  ///
  /// In en, this message translates to:
  /// **'An orb fans the ball out from wherever it was struck.'**
  String get ricochetHelpOrbDemo;

  /// No description provided for @ricochetHelpControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get ricochetHelpControlsTitle;

  /// No description provided for @ricochetHelpControlsDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag and release — aim and fire.'**
  String get ricochetHelpControlsDrag;

  /// No description provided for @ricochetHelpControlsRecall.
  ///
  /// In en, this message translates to:
  /// **'Recall — instantly pulls all balls back, so a stuck shot can never trap you.'**
  String get ricochetHelpControlsRecall;

  /// No description provided for @ricochetHelpControlsSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed — each press stacks another boost, up to ×10, until the turn ends. It kicks in on its own at ×3 if a volley drags past six seconds.'**
  String get ricochetHelpControlsSpeed;

  /// No description provided for @ricochetHelpControlsMenu.
  ///
  /// In en, this message translates to:
  /// **'Power-ups — open the menu for unlimited-use charges.'**
  String get ricochetHelpControlsMenu;

  /// No description provided for @ricochetHelpControlsRestart.
  ///
  /// In en, this message translates to:
  /// **'Replay — restarts the current level from its start.'**
  String get ricochetHelpControlsRestart;

  /// No description provided for @ricochetHelpKeyboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get ricochetHelpKeyboardTitle;

  /// No description provided for @ricochetHelpKeyboardAim.
  ///
  /// In en, this message translates to:
  /// **'Left / Right (or A / D) — swing the sight. Hold Shift for fine aim.'**
  String get ricochetHelpKeyboardAim;

  /// No description provided for @ricochetHelpKeyboardFire.
  ///
  /// In en, this message translates to:
  /// **'Space or Enter — fire the shot the sight is holding.'**
  String get ricochetHelpKeyboardFire;

  /// No description provided for @ricochetHelpKeyboardRecall.
  ///
  /// In en, this message translates to:
  /// **'R — recall the balls. F — speed up the volley.'**
  String get ricochetHelpKeyboardRecall;

  /// No description provided for @ricochetHelpKeyboardMenu.
  ///
  /// In en, this message translates to:
  /// **'P — power-ups. H — this page. M — mute.'**
  String get ricochetHelpKeyboardMenu;

  /// No description provided for @ricochetHelpLevelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Level design'**
  String get ricochetHelpLevelsTitle;

  /// No description provided for @ricochetHelpLevelsText.
  ///
  /// In en, this message translates to:
  /// **'Every board is cut from one of nineteen hand-drawn stencils, auto-centred on the 13-column grid and randomly mirrored. A clear zone above the danger line is guaranteed, so every tile is reachable. Tall compositions may start above the top edge and slide into view one row per turn. From level 8 two stencils usually stack into one bigger composition. Brick HP scales forever with the level, and the exotic tiles unlock as you climb: blast at level 3, pierce at 5, orbs at 7, ramps at 10.'**
  String get ricochetHelpLevelsText;

  /// No description provided for @ricochetHelpProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get ricochetHelpProgressTitle;

  /// No description provided for @ricochetHelpProgressText.
  ///
  /// In en, this message translates to:
  /// **'Level, score, ball count and the current board are saved automatically — leave mid-level and resume where you left off. Your best score persists across runs. On game over you can retry the level, restored exactly as it looked when the level began, or start over from level 1.'**
  String get ricochetHelpProgressText;

  /// No description provided for @commonScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get commonScore;

  /// No description provided for @commonBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get commonBest;

  /// No description provided for @commonBestScore.
  ///
  /// In en, this message translates to:
  /// **'Best: {best}'**
  String commonBestScore(int best);

  /// No description provided for @commonNewBest.
  ///
  /// In en, this message translates to:
  /// **'New best!'**
  String get commonNewBest;

  /// No description provided for @commonNewGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get commonNewGame;

  /// No description provided for @commonGameOver.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get commonGameOver;

  /// No description provided for @commonPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get commonPause;

  /// No description provided for @commonResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get commonResume;

  /// No description provided for @commonPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get commonPaused;

  /// No description provided for @commonMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get commonMute;

  /// No description provided for @commonUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get commonUnmute;

  /// No description provided for @gameName2048.
  ///
  /// In en, this message translates to:
  /// **'2048'**
  String get gameName2048;

  /// No description provided for @gameDescription2048.
  ///
  /// In en, this message translates to:
  /// **'Swipe to slide the board, merge equal tiles, and chase a single 2048 out of a grid that keeps filling up.'**
  String get gameDescription2048;

  /// No description provided for @twenty48Moves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get twenty48Moves;

  /// No description provided for @twenty48Highest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get twenty48Highest;

  /// No description provided for @twenty48Undo.
  ///
  /// In en, this message translates to:
  /// **'Undo move'**
  String get twenty48Undo;

  /// No description provided for @twenty48NoMovesLeft.
  ///
  /// In en, this message translates to:
  /// **'No moves left'**
  String get twenty48NoMovesLeft;

  /// No description provided for @twenty48ReachedTile.
  ///
  /// In en, this message translates to:
  /// **'Highest tile: {value}'**
  String twenty48ReachedTile(int value);

  /// No description provided for @twenty48YouWin.
  ///
  /// In en, this message translates to:
  /// **'2048 reached'**
  String get twenty48YouWin;

  /// No description provided for @twenty48WinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You got there with {score} points. Keep going for a higher tile.'**
  String twenty48WinSubtitle(int score);

  /// No description provided for @twenty48KeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get twenty48KeepPlaying;

  /// No description provided for @gameNameSnake.
  ///
  /// In en, this message translates to:
  /// **'Snake'**
  String get gameNameSnake;

  /// No description provided for @gameDescriptionSnake.
  ///
  /// In en, this message translates to:
  /// **'Eat, grow, and keep the tail out of your own way as the board fills and the pace never lets up.'**
  String get gameDescriptionSnake;

  /// No description provided for @snakeLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get snakeLength;

  /// No description provided for @snakeSpeed.
  ///
  /// In en, this message translates to:
  /// **'Cells/s'**
  String get snakeSpeed;

  /// No description provided for @snakeFinalLength.
  ///
  /// In en, this message translates to:
  /// **'Final length: {length}'**
  String snakeFinalLength(int length);

  /// No description provided for @snakeTapToStart.
  ///
  /// In en, this message translates to:
  /// **'Swipe or press an arrow key to start'**
  String get snakeTapToStart;

  /// No description provided for @gameNameMinesweeper.
  ///
  /// In en, this message translates to:
  /// **'Minesweeper'**
  String get gameNameMinesweeper;

  /// No description provided for @gameDescriptionMinesweeper.
  ///
  /// In en, this message translates to:
  /// **'Read the numbers, flag what you can prove, and clear the field without guessing. The first click is always safe.'**
  String get gameDescriptionMinesweeper;

  /// No description provided for @minesweeperMines.
  ///
  /// In en, this message translates to:
  /// **'Mines'**
  String get minesweeperMines;

  /// No description provided for @minesweeperTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get minesweeperTime;

  /// No description provided for @minesweeperBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get minesweeperBeginner;

  /// No description provided for @minesweeperIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get minesweeperIntermediate;

  /// No description provided for @minesweeperExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get minesweeperExpert;

  /// No description provided for @minesweeperFlagModeOn.
  ///
  /// In en, this message translates to:
  /// **'Flag mode on — tap to flag'**
  String get minesweeperFlagModeOn;

  /// No description provided for @minesweeperFlagModeOff.
  ///
  /// In en, this message translates to:
  /// **'Flag mode off — tap to uncover'**
  String get minesweeperFlagModeOff;

  /// No description provided for @minesweeperCleared.
  ///
  /// In en, this message translates to:
  /// **'Field cleared'**
  String get minesweeperCleared;

  /// No description provided for @minesweeperBoom.
  ///
  /// In en, this message translates to:
  /// **'Boom'**
  String get minesweeperBoom;

  /// No description provided for @minesweeperBoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You hit a mine.'**
  String get minesweeperBoomSubtitle;

  /// No description provided for @minesweeperBestTime.
  ///
  /// In en, this message translates to:
  /// **'Best: {time}'**
  String minesweeperBestTime(String time);

  /// No description provided for @minesweeperOnLevel.
  ///
  /// In en, this message translates to:
  /// **'on {level}'**
  String minesweeperOnLevel(String level);

  /// No description provided for @gameNameTetris.
  ///
  /// In en, this message translates to:
  /// **'Tetris'**
  String get gameNameTetris;

  /// No description provided for @gameDescriptionTetris.
  ///
  /// In en, this message translates to:
  /// **'Stack falling blocks into full rows. Modern rules throughout: wall kicks, a hold slot, a ghost drop and a seven-bag shuffle.'**
  String get gameDescriptionTetris;

  /// No description provided for @tetrisLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get tetrisLines;

  /// No description provided for @tetrisLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get tetrisLevel;

  /// No description provided for @tetrisHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get tetrisHold;

  /// No description provided for @tetrisNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tetrisNext;

  /// No description provided for @tetrisMoveLeft.
  ///
  /// In en, this message translates to:
  /// **'Move left'**
  String get tetrisMoveLeft;

  /// No description provided for @tetrisMoveRight.
  ///
  /// In en, this message translates to:
  /// **'Move right'**
  String get tetrisMoveRight;

  /// No description provided for @tetrisRotateLeft.
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get tetrisRotateLeft;

  /// No description provided for @tetrisRotateRight.
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get tetrisRotateRight;

  /// No description provided for @tetrisSoftDrop.
  ///
  /// In en, this message translates to:
  /// **'Soft drop'**
  String get tetrisSoftDrop;

  /// No description provided for @tetrisHardDrop.
  ///
  /// In en, this message translates to:
  /// **'Hard drop'**
  String get tetrisHardDrop;

  /// No description provided for @tetrisClearedLines.
  ///
  /// In en, this message translates to:
  /// **'{lines} lines, level {level}'**
  String tetrisClearedLines(int lines, int level);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
