# Rechenblitz

Kindgerechte, adaptive Flutter-Lernapp für Mathematik in der Grundschule. Rechenblitz unterstützt die Zahlenräume **bis 10, bis 20 und bis 100** und baut neue Inhalte auf bereits sicheren Grundlagen auf.

## Lernbereiche

- Addition und Subtraktion
- Multiplikation und Division
- adaptives Plus-/Minus-Training
- Minus-Trainer mit visuellen und rückwärts gerichteten Rechenhilfen
- Zahlenfreunde und Zahlzerlegungen
- Zahlenmauern
- Lückenaufgaben
- Nachbarzahlen
- Stellenwert: Zehner und Einer
- Verdoppeln und Halbieren
- Zahlenfolgen
- Rechenfamilien und Umkehraufgaben
- gemischte Grundrechenarten
- kurze Blitzrunden, Schnellrechnen und konfigurierbarer Rechencheck

## Zahlenräume

Der aktive Zahlenraum kann jederzeit zwischen **bis 10**, **bis 20** und **bis 100** gewechselt werden. Im größeren Zahlenraum bleiben die Grundlagen erhalten: Die adaptive Progression beginnt mit sicheren Beziehungen bis 10, erweitert auf bis 20 und öffnet anschließend Aufgaben bis 100.

## Lernlogik

Die App priorisiert **Sicherheit vor Tempo**. Aufgaben mit niedriger Trefferquote, langen Antwortzeiten oder Hilfebedarf werden häufiger ausgewählt. Bereits sichere Aufgaben bleiben im Mix, erscheinen aber seltener.

Antwortzeiten über 30 Sekunden werden für die Statistik begrenzt, damit Unterbrechungen keine Durchschnittswerte zerstören.

## Elternbereich

Der Elternbereich öffnet durch zweisekündiges Halten des Elternsymbols. Er zeigt unter anderem:

- Trefferquoten der vier Grundrechenarten
- Trefferquoten weiterer Lernwelten
- schwierigste und sicherste Rechenfakten
- Lernempfehlungen
- Verlauf der Trefferquote als Diagramm
- gesammelte Sterne und die Logik des Belohnungssystems

## Belohnungssystem

Sterne belohnen nicht bloß Geschwindigkeit. Eine abgeschlossene Runde gibt einen Basisstern. Zusätzliche Sterne können für eine sichere Runde und beim ersten Abschluss einer neuen Lernwelt entstehen.

## Datenschutz

- vollständig offline
- kein Konto
- keine Werbung
- kein Backend
- Lernfortschritt bleibt lokal auf dem Gerät

## Starten

Voraussetzung: aktuelles Flutter Stable.

```bash
flutter pub get
flutter run
```

Web:

```bash
flutter run -d chrome
```

## Qualität

```bash
flutter analyze
flutter test
```

Dieselben Prüfungen laufen per GitHub Actions bei Pushes und Pull Requests.
