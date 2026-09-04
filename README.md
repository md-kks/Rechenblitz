# Rechenblitz

**Rechenblitz** ist eine offline arbeitende Flutter-Lernapp für den Mathematikunterricht der **Grundschule Klasse 1–4**. Der Aufbau orientiert sich am Thüringer Lehrplan Mathematik für die Primarstufe und verbindet kurze Übungsrunden mit adaptiver Wiederholung, Lernstandsübersicht und einem druckfreien Belohnungssystem.

## Grundprinzip

Rechenblitz priorisiert Verstehen, richtiges Rechnen, Sicherheit und Automatisierung vor Geschwindigkeit. Bereits vorhandene Lernstände bleiben beim Wechsel der Klassenstufe erhalten. Klassenstufe und Zahlenraum können getrennt gewählt werden, sodass Wiederholung und Förderung mit kleineren Zahlenräumen möglich bleiben.

## Klassenstufen und Zahlenräume

- **Klasse 1:** bis 10 / bis 20
- **Klasse 2:** bis 10 / 20 / 100
- **Klasse 3:** zusätzlich bis 1.000 und 10.000
- **Klasse 4:** zusätzlich bis 1.000.000

Standard beim Wechsel: Klasse 1 → bis 20, Klasse 2 → bis 100, Klasse 3 → bis 1.000, Klasse 4 → bis 1.000.000.

Der adaptive Grundaufgaben-Pool bleibt bewusst kompakt bis 100. Aufgaben mit großen Zahlen werden dynamisch erzeugt, damit kein riesiger Millionen-Aufgabenpool im Speicher aufgebaut werden muss.

## Lernwelten Klasse 1/2

- Plus und Minus
- eigener Minus-Trainer
- Malnehmen und Teilen
- gemischte Grundrechenarten
- Zahlenfreunde
- Zahlenmauern
- Lückenaufgaben
- Nachbarzahlen
- Stellenwert / Zehner und Einer
- Verdoppeln und Halbieren
- Zahlenfolgen
- Rechenfamilien / Umkehraufgaben
- Sachaufgaben
- Geld
- Uhrzeit
- Längen und Größen
- Grundformen und Geometrie
- Blitzrunden, Schnellrechnen und Rechencheck

## Erweiterung Klasse 3/4

### Zahlen und Operationen
- Orientierung in großen Zahlenräumen bis 1 Million
- Stellenwerttafel, Zerlegung, Vergleichen, Vorgänger/Nachfolger
- Runden
- halbschriftliches Addieren und Subtrahieren
- schriftliche Addition und Subtraktion
- schriftliche Multiplikation
- schriftliche Division ohne Rest sowie in Klasse 4 auch mit Rest
- Überschlagsrechnung
- Rechenvorteile und Rechengesetze
- römische Zahlen
- einfache Bruchteile von Mengen und Größen

### Größen, Messen und Sachrechnen
- Längen: mm, cm, m, km
- Massen: g, kg, t
- Volumen: ml, l
- Geld: ct, €
- Zeit: Minuten, Stunden, Tage und Wochen
- Zeitspannen
- einfache proportionale Zuordnungen
- weiterführende Sachaufgaben

### Raum und Form
- Umfang und Flächeninhalt
- geometrische Körper und ihre Eigenschaften
- Würfelnetze
- Achsensymmetrie
- Pläne, Wege und einfache Maßstabsbeziehungen
- Rauminhalt mit Einheitswürfeln

### Muster, Daten und Zufall
- Daten aus Tabellen und Balkendiagrammen lesen und auswerten
- Häufigkeiten vergleichen
- sicher / möglich / unmöglich
- einfache Gewinnchancen
- Kombinatorik und systematisches Finden von Möglichkeiten

## Rechenblitz Lernstart

Neue Installationen beginnen mit einem kurzen, druckfreien Lernstart:

- lokales Lernprofil mit Name/Spitzname, Klassenstufe und Bundesland
- Auswahl der in der Schule verwendeten Rechenwege
- optionaler Einstufungscheck mit 12 Aufgaben aus sechs Kompetenzbereichen
- keine Note, kein Zeitlimit, keine Sterne und keine Abzeichen im Lerncheck
- „Weiß ich noch nicht“ als normale Antwortmöglichkeit
- sichere Startbereiche werden in der Lernlandkarte markiert
- unsichere Startbereiche beeinflussen direkt die erste persönliche „Meine Runde“
- der Lerncheck kann später wiederholt werden und ersetzt dann nur die alte Einstufung

Bestehende Nutzer werden bei einem Update nicht nachträglich durch das Onboarding gezwungen. Alte lokale Lernstände werden weiterverwendet.

Das Bundesland wird ausschließlich lokal gespeichert. Thüringen ist derzeit vollständig lehrplangeprüft; andere Bundesländer verwenden bis zu einem eigenen Curriculum-Audit zunächst den gemeinsamen Grundschul-Mathematikkern.

## Persönlicher Lernpfad

Für eine Veröffentlichung ist Rechenblitz nicht nur eine Aufgabensammlung, sondern ein lokaler Mathe-Lernbegleiter:

- mehrere getrennte Kinderprofile ohne Konto oder Cloud
- Kompetenzkarte mit **Neu / wird geübt / sicher / gemeistert**
- **Meine Runde**: automatisch 10 Aufgaben aus Grundlagen, aktuellem Lernziel und Transfer
- **So rechnen wir**: auswählbare schulische Rechenwege für Minus, Einmaleins und schriftliche Subtraktion
- Elternhinweise mit **Das klappt / Hier üben / Was hilft / Noch nicht nötig**
- alle Lernstände und Methoden bleiben local first auf dem Gerät

## Erklärbare Fehlerdiagnose

Rechenblitz wertet den ersten Antwortversuch einer Aufgabe lokal aus, um wiederkehrende Fehlermuster zu erkennen. Ein einzelner Fehler wird bewusst noch nicht als Lernproblem gewertet.

Beispiele für erkannte Muster:

- Zehnerübergang
- Rechenart verwechselt
- Stellenwert
- Einmaleins- oder Geteilt-Fakt
- Umkehraufgabe
- Sachaufgabe in eine Rechnung übersetzen
- Größen und Einheiten umwandeln
- Uhrzeit lesen
- Rundungsstelle
- Übertrag / Entbündeln bei schriftlichen Verfahren
- Bruchteile, Daten, Wahrscheinlichkeit, Umfang/Fläche und weitere Curriculum-Muster

Erst wenn ein ähnliches Muster mindestens zweimal auftritt, erscheint es als vorsichtiger Hinweis im Elternbereich und in der Lernlandkarte. Die Diagnose ist regelbasiert und erklärbar; sie behauptet keine medizinische oder lerntherapeutische Diagnose. Diagnosebeobachtungen sind pro Profil, Klassenstufe und Zahlenraum getrennt und bleiben ausschließlich lokal auf dem Gerät.

## Adaptives Lernen

Der bisherige adaptive Kern bleibt erhalten. Schwache oder langsame Grundaufgaben werden häufiger wiederholt. Für Klasse 3/4 ergänzt Rechenblitz dynamische Lehrplan-Aufgaben und empfiehlt zunächst noch nicht bearbeitete Lernbereiche, später die Bereiche mit der geringsten Sicherheit.

## Belohnungssystem

Belohnt werden nicht bloß schnelle Antworten, sondern abgeschlossene Runden, sicheres Rechnen, deutliche Verbesserung, Dranbleiben, neue Lernwelten, sichere Zahlenräume und Rechenarten, gemeisterte Schwachstellen sowie die sichere Bearbeitung mehrerer Lehrplanbereiche einer Klassenstufe. Sterne und Abzeichen werden lokal gespeichert. Es gibt keine verlierbare Daily-Streak.

## Elternbereich

Der Elternbereich zeigt Trefferquoten, Entwicklungen über mehrere Runden, Grundrechenarten, Zahlenräume, Klassenstufen, einzelne Lernwelten, Lehrplanbereiche Klasse 3/4, schwierige und sichere Grundaufgaben, Sterne, Abzeichen und die Empfehlung für die nächste Runde.

## Datenschutz

- vollständig offline
- kein Benutzerkonto
- kein Backend
- keine Werbung
- keine Analyse-Dienste
- Lernfortschritt ausschließlich lokal auf dem Gerät

## Entwicklung

Voraussetzung: aktuelles Flutter Stable mit Dart 3.9 oder neuer.

Zum Starten: flutter pub get, danach flutter run.

Qualitätsprüfung: flutter analyze und flutter test. Dieselben Prüfungen laufen auf GitHub Actions bei Pushes und Pull Requests.
