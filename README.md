# Rechenblitz

Kindgerechte, adaptive Flutter-Lernapp für **Addition und Subtraktion im Zahlenraum 0–10**. Der Schwerpunkt liegt auf Sicherheit bei Minusaufgaben und anschließendem behutsamen Aufbau von Rechengeschwindigkeit.

## Funktionen

- Sicher üben ohne sichtbaren Zeitdruck
- eigener Minus-Trainer mit visueller Hilfe und Ergänzungsstrategie
- 5 Blitzaufgaben
- Schnell-rechnen-Runden
- konfigurierbarer Tempotest (10/20/30 Aufgaben, 1/2/3 Minuten oder ohne Limit)
- Zahlenfreunde / Zahlzerlegung
- adaptive Aufgabenauswahl anhand Fehlern, Antwortzeit, Hilfebedarf und Mastery
- dynamische Minus-Gewichtung zwischen 50 % und 75 %
- lokale Speicherung von Lernfortschritt und Einstellungen
- Elternbereich über langes Drücken des Zahnrads
- regelbasierte Empfehlung für die nächste passende Runde
- dezentes Sterne-System
- kein Konto, keine Werbung, kein Backend
- Android und Flutter Web

## Starten

Voraussetzung: aktuelles Flutter Stable mit Dart 3.9 oder neuer.

```bash
flutter pub get
flutter run
```

Web:

```bash
flutter run -d chrome
```

Android-Gerät:

```bash
flutter devices
flutter run -d <device-id>
```

## Qualität

```bash
flutter analyze
flutter test
```

Zusätzlich läuft dieselbe Prüfung per GitHub Actions bei Pushes und Pull Requests.

## Lernlogik

Die App priorisiert **Sicherheit vor Tempo**. Aufgaben mit niedriger Trefferquote, langen Antwortzeiten oder Hilfebedarf werden häufiger ausgewählt. Bereits sichere Aufgaben bleiben im Mix, erscheinen aber seltener. Subtraktion startet mit höherem Gewicht und wird bei anhaltender Unsicherheit weiter priorisiert.

Antwortzeiten über 30 Sekunden werden für die Statistik begrenzt, damit Unterbrechungen keine Durchschnittswerte zerstören.

## Datenschutz

Alle Daten bleiben lokal auf dem jeweiligen Gerät. Es gibt keine Anmeldung, Cloud-Synchronisierung oder Analyse-Dienste.

### Hinweis zur Android-Gradle-Hülle

Dieses Repository ist vollständig textbasiert erzeugt. Falls die übliche binäre `gradle-wrapper.jar` nicht vorhanden ist, bootstrappen `android/gradlew` bzw. `gradlew.bat` automatisch die offizielle Gradle-8.10.2-Distribution von `services.gradle.org`. Es wird keine fremde Downloadquelle verwendet.
