// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonConfirm => 'Bestätigen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonClear => 'Löschen';

  @override
  String get commonReset => 'Zurücksetzen';

  @override
  String get commonSettings => 'Einstellungen';

  @override
  String get overviewSearchHint => 'Spiele suchen';

  @override
  String get overviewNoGamesFound => 'Keine Spiele gefunden';

  @override
  String get overviewAddFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get overviewRemoveFavorite => 'Aus Favoriten entfernen';

  @override
  String get sectionTitleArcade => 'Arcade';

  @override
  String get sectionTitlePuzzle => 'Puzzle';

  @override
  String get settingsDialogTitle => 'Einstellungen';

  @override
  String get settingsDialogAppearanceSubtitle => 'Design, Sprache, Layout';

  @override
  String get settingsDialogGameplaySubtitle =>
      'Ton, Bildschirm, gespeicherte Daten';

  @override
  String get settingsDialogAboutSubtitle => 'Version und Lizenzen';

  @override
  String get appearanceTitle => 'Darstellung';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageEnglish => 'Englisch';

  @override
  String get settingsLanguageGerman => 'Deutsch';

  @override
  String get settingsCompactView => 'Kompakte Ansicht';

  @override
  String get settingsCompactViewSubtitle =>
      'Kleinere Karten, mehr Spiele pro Zeile';

  @override
  String get settingsSortBy => 'Sortieren nach';

  @override
  String get settingsSortRecent => 'Zuletzt gespielt';

  @override
  String get settingsSortDefaultOrder => 'Standardreihenfolge';

  @override
  String get settingsSortName => 'Name';

  @override
  String get gameplayTitle => 'Spielverhalten';

  @override
  String get settingsSound => 'Soundeffekte';

  @override
  String get settingsSoundSubtitle => 'Soundeffekte im Spiel abspielen';

  @override
  String get settingsVolume => 'Lautstärke';

  @override
  String get settingsKeepScreenAwake => 'Bildschirm anlassen';

  @override
  String get settingsKeepScreenAwakeSubtitle =>
      'Bildschirm anlassen, solange ein Zug läuft';

  @override
  String get settingsHaptics => 'Haptisches Feedback';

  @override
  String get settingsHapticsSubtitle =>
      'Bei Treffern und Levelwechseln vibrieren';

  @override
  String get settingsResetData => 'Alle Spieldaten zurücksetzen';

  @override
  String get settingsResetDataSubtitle =>
      'Löscht jeden Spielstand, Highscore und jede Einstellung';

  @override
  String get settingsResetDataConfirm =>
      'Dies löscht dauerhaft jeden gespeicherten Durchlauf, alle Highscores und Einstellungen. Das lässt sich nicht rückgängig machen.';

  @override
  String get settingsResetDataDone => 'Alle Spieldaten wurden zurückgesetzt';

  @override
  String get aboutTitle => 'Über';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'Eine Sammlung von Gelegenheitsspielen für Android, Windows und Linux. Jedes Spiel läuft vollständig offline — ohne Konto, ohne Werbung, ohne Tracking.';

  @override
  String aboutGamesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spiele installiert',
      one: '1 Spiel installiert',
    );
    return '$_temp0';
  }

  @override
  String get aboutLicense => 'Lizenz';

  @override
  String get aboutThirdPartyLicenses => 'Lizenzen von Drittanbietern';

  @override
  String get gameNameRicochet => 'Ricochet';

  @override
  String get gameDescriptionRicochet =>
      'Ziele mit einer Salve springender Bälle und zerlege nummerierte Steine über endlos generierte Level.';

  @override
  String get ricochetScore => 'Punkte';

  @override
  String get ricochetBest => 'Rekord';

  @override
  String get ricochetLevel => 'Level';

  @override
  String get ricochetBalls => 'Bälle';

  @override
  String get ricochetPowerMenu => 'Power-ups';

  @override
  String get ricochetRestartLevel => 'Level neu starten';

  @override
  String get ricochetHowToPlay => 'Spielanleitung';

  @override
  String get ricochetMute => 'Stumm schalten';

  @override
  String get ricochetUnmute => 'Ton einschalten';

  @override
  String get ricochetRecall => 'Zurückrufen';

  @override
  String get ricochetSpeed => 'Tempo';

  @override
  String ricochetSpeedActive(int multiplier) {
    return 'Tempo ×$multiplier';
  }

  @override
  String get ricochetGameOver => 'SPIEL VORBEI';

  @override
  String get ricochetNewBest => 'Neuer Rekord!';

  @override
  String ricochetBestScore(int best) {
    return 'Rekord: $best';
  }

  @override
  String ricochetReachedLevel(int level) {
    return 'Level $level erreicht';
  }

  @override
  String get ricochetRetryLevel => 'Level wiederholen';

  @override
  String get ricochetStartOver => 'Neu beginnen';

  @override
  String get ricochetPowerBalls => '+10 Bälle';

  @override
  String get ricochetPowerBallsDesc => 'Fügt deinem Vorrat 10 Bälle hinzu';

  @override
  String get ricochetPowerPierce => 'Durchschlag-Salve';

  @override
  String get ricochetPowerPierceDesc =>
      'Ein Ball bohrt sich geradewegs durch Steine';

  @override
  String get ricochetPowerBomb => 'Bomben-Salve';

  @override
  String get ricochetPowerBombDesc => 'Ein Ball explodiert bei jedem Treffer';

  @override
  String get ricochetPowerClearRow => 'Reihe räumen';

  @override
  String get ricochetPowerClearRowDesc => 'Löscht die unterste Steinreihe';

  @override
  String get ricochetToastPierceArmed => 'DURCHSCHLAG BEREIT';

  @override
  String get ricochetToastBombArmed => 'BOMBE BEREIT';

  @override
  String get ricochetToastRecalled => 'ZURÜCKGERUFEN';

  @override
  String get ricochetToastRowCleared => 'REIHE GERÄUMT';

  @override
  String get ricochetToastPlusOneBall => '+1 BALL';

  @override
  String get ricochetHintDragToAim => 'Zum Zielen ziehen';

  @override
  String get ricochetChipPierce => 'DURCHSCHLAG';

  @override
  String get ricochetChipBomb => 'BOMBE';

  @override
  String ricochetToastPlusBalls(int count) {
    return '+$count BÄLLE';
  }

  @override
  String ricochetToastSpeed(int multiplier) {
    return 'TEMPO ×$multiplier';
  }

  @override
  String ricochetToastAutoSpeed(int multiplier) {
    return 'AUTO-TEMPO ×$multiplier';
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
  String get ricochetHelpTitle => 'Ricochet spielen';

  @override
  String get ricochetHelpBasicsTitle => 'Grundlagen';

  @override
  String get ricochetHelpBasicsAim =>
      'Ziehe irgendwo auf dem Spielfeld, um zu zielen — eine gestrichelte Vorschau zeigt die Flugbahn und den ersten Aufprall.';

  @override
  String get ricochetHelpBasicsFire =>
      'Loslassen zum Feuern. Pro Zug starten bis zu 100 Bälle nacheinander und prallen von Wänden und Steinen ab.';

  @override
  String get ricochetHelpBasicsHp =>
      'Jeder Stein zeigt seine Trefferpunkte; jeder Treffer zieht 1 ab. Bei 0 zerspringt er und bringt Punkte.';

  @override
  String get ricochetHelpBasicsDrop =>
      'Nach jeder Salve rückt das Feld eine Reihe nach unten. Überquert ein Stein die rote Gefahrenlinie, endet der Durchlauf.';

  @override
  String get ricochetHelpBasicsClear =>
      'Räume das ganze Feld, um das Level abzuschließen: Punktebonus, +2 Bälle und ein frisch generiertes nächstes Feld.';

  @override
  String get ricochetHelpBasicsPickup =>
      'Grüne (+)-Aufsammler werden bei Berührung eingesammelt und geben dauerhaft einen Ball extra.';

  @override
  String get ricochetHelpBasicsCharges =>
      'Gebunkerte Durchschlag- und Bombenladungen erscheinen als Chips direkt über dem Abschuss — sie bleiben an ihrem Platz, wohin er auch rutscht. Ladungen stapeln sich: bunkere mehrere, und mehrere Bälle deiner nächsten Salve erben den Effekt.';

  @override
  String get ricochetHelpTilesTitle => 'Steinübersicht';

  @override
  String get ricochetHelpTilesIntro =>
      'Bis auf den (+)-Aufsammler hat jeder Stein Trefferpunkte und zerbricht wie ein normaler Stein. Der Effekt ist das, was zusätzlich passiert.';

  @override
  String get ricochetTileBrick => 'Stein';

  @override
  String get ricochetTileBrickEffect =>
      'Normales Ziel. Punkte = max. TP × 10 + Level × 2. Die Farbe zeigt, wie zäh er ist.';

  @override
  String get ricochetTileBomb => 'Bombe';

  @override
  String get ricochetTileBombEffect =>
      'Geht bei einem einzigen Treffer hoch, egal wie viele Trefferpunkte sie hat: alles im Umkreis von rund zwei Feldern nimmt tödlichen Schaden. Kettet über andere Bomben weiter.';

  @override
  String get ricochetTileGift => 'Geschenk (?)';

  @override
  String get ricochetTileGiftEffect =>
      'Löst beim Zerstören ein zufälliges Power-up aus: +10 Bälle, eine Durchschlag-Ladung, eine Bomben-Ladung oder Reihe räumen.';

  @override
  String get ricochetTileMult => '×2-Multiplikator';

  @override
  String get ricochetTileMultEffect =>
      'Zahlt beim Zerstören doppelte Punkte, mit eigener Anzeige.';

  @override
  String get ricochetTilePierce => 'Durchschlag';

  @override
  String get ricochetTilePierceEffect =>
      'Bunkert eine Durchschlag-Ladung. Ein Ball deiner nächsten Salve bohrt sich geradewegs durch die Steine, statt abzuprallen, und beschädigt jeden Stein auf seinem Weg einmal.';

  @override
  String get ricochetTileBlast => 'Sprengsatz';

  @override
  String get ricochetTileBlastEffect =>
      'Bunkert eine Bomben-Ladung. Ein Ball deiner nächsten Salve explodiert bei jedem Aufprall für bis zu 50 Schaden im Umkreis.';

  @override
  String get ricochetTileRamp => 'Rampe';

  @override
  String get ricochetTileRampEffect =>
      'Ein massives Dreieck, das eine Hälfte seines Feldes füllt. Die 45°-Schräge lenkt den Ball um eine Vierteldrehung ab; die beiden geraden Seiten prallen wie ein gewöhnlicher Stein, und die leere Hälfte des Feldes ist Luft, durch die der Ball glatt hindurchfliegt.';

  @override
  String get ricochetTileOrb => 'Kugel';

  @override
  String get ricochetTileOrbEffect =>
      'Ein runder Prallkörper: er reflektiert an seiner gewölbten Oberfläche statt an einer flachen Fläche, sodass die Ausfallwinkel vom Treffpunkt aus auffächern. Da er rund ist, sind die Ecken seines Feldes leere Luft.';

  @override
  String get ricochetTilePickup => '(+)-Aufsammler';

  @override
  String get ricochetTilePickupEffect =>
      'Kein Stein — keine Trefferpunkte, nicht wegschießbar. Wird bei Berührung eingesammelt und gibt dauerhaft +1 Ball.';

  @override
  String get ricochetHelpDeflectorsTitle => 'Was einen Ball ablenkt';

  @override
  String get ricochetHelpDeflectorsIntro =>
      'Rampen und Kugeln sind die einzigen Steine, die die Richtung eines Balls über ein flaches Abprallen hinaus verändern. Beide haben eine kurze Abklingzeit pro Ball, sodass ein Ball in einer Ansammlung davon nicht hängen bleiben kann.';

  @override
  String get ricochetHelpRampA =>
      'Eine „/“-Rampe lenkt einen fallenden Ball nach links.';

  @override
  String get ricochetHelpRampB =>
      'Eine „\\“-Rampe lenkt denselben Ball in die andere Richtung.';

  @override
  String get ricochetHelpOrbDemo =>
      'Eine Kugel fächert den Ball vom Treffpunkt aus auf.';

  @override
  String get ricochetHelpControlsTitle => 'Steuerung';

  @override
  String get ricochetHelpControlsDrag =>
      'Ziehen und loslassen — zielen und feuern.';

  @override
  String get ricochetHelpControlsRecall =>
      'Zurückrufen — holt sofort alle Bälle zurück, damit ein feststeckender Schuss dich nie blockiert.';

  @override
  String get ricochetHelpControlsSpeed =>
      'Tempo — jeder Druck legt einen weiteren Schub drauf, bis ×10, bis der Zug endet. Ab sechs Sekunden Salve springt es von allein auf ×3.';

  @override
  String get ricochetHelpControlsMenu =>
      'Power-ups — öffnet das Menü mit unbegrenzt nutzbaren Ladungen.';

  @override
  String get ricochetHelpControlsRestart =>
      'Neu starten — spielt das aktuelle Level von vorn.';

  @override
  String get ricochetHelpLevelsTitle => 'Leveldesign';

  @override
  String get ricochetHelpLevelsText =>
      'Jedes Feld wird aus einer von neunzehn handgezeichneten Schablonen geschnitten, automatisch auf dem 13-Spalten-Raster zentriert und zufällig gespiegelt. Über der Gefahrenlinie ist eine freie Zone garantiert, damit jeder Stein erreichbar bleibt. Hohe Kompositionen können über dem oberen Rand beginnen und pro Zug eine Reihe einfahren. Ab Level 8 stapeln sich meist zwei Schablonen zu einer größeren Komposition. Die Trefferpunkte steigen endlos mit dem Level, und die exotischen Steine schalten sich nach und nach frei: Sprengsatz ab Level 3, Durchschlag ab 5, Kugeln ab 7, Rampen ab 10.';

  @override
  String get ricochetHelpProgressTitle => 'Fortschritt';

  @override
  String get ricochetHelpProgressText =>
      'Level, Punkte, Ballanzahl und das aktuelle Feld werden automatisch gespeichert — brich mitten im Level ab und mach später dort weiter. Dein Rekord bleibt über alle Durchläufe erhalten. Bei Spielende kannst du das Level wiederholen, exakt so wiederhergestellt, wie es zu Levelbeginn aussah, oder von Level 1 neu beginnen.';
}
