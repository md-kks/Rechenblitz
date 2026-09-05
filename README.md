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
- Zeit: Sekunden, Minuten, Stunden, Tage und Wochen
- Kalender und Datumsangaben
- Zeitspannen
- einfache proportionale Zuordnungen
- weiterführende Sachaufgaben

### Raum und Form
- Umfang und Flächeninhalt
- parallele und senkrechte Geraden
- rechte Winkel
- Dreiecke und Vierecke über Eigenschaften klassifizieren
- Kreisbegriffe: Mittelpunkt, Radius und Durchmesser
- geometrische Körper und ihre Eigenschaften
- Würfelnetze
- Achsensymmetrie
- Pläne, Wege und einfache Maßstabsbeziehungen
- Rauminhalt mit Einheitswürfeln

### Muster, Daten und Zufall
- Daten aus Tabellen, Strichlisten und Balkendiagrammen lesen und auswerten
- passende Datendarstellung auswählen
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

### Fehlerabhängige Hilfen

Bei mathematisch eindeutigen Fehlzahlen kann Rechenblitz inzwischen einen Schritt genauer werden. Beispiele:

- `47 + 38 = 75` → der neue Zehner wurde beim Addieren nicht weitergegeben
- `63 − 28 = 45` → die Einer wurden ziffernweise ohne notwendiges Entbündeln verrechnet
- `63 − 28 = 55` → nur ein Teil der zweiten Zahl wurde verarbeitet
- `6 × 4 = 10` → die Faktoren wurden addiert statt als gleich große Gruppen verstanden
- `24 ÷ 6 = 18` → die Zahlen wurden subtrahiert statt gleichmäßig aufgeteilt

Auch die Modellierungskette von Sachaufgaben bleibt getrennt: unnötige Angaben auswählen, eine passende Rechnung bilden und ein Ergebnis auf die Sachsituation zurückführen erzeugen unterschiedliche Hinweise und Förderpfade.

Nach dem **ersten** falschen Versuch erscheint nur ein kurzer, ursachenspezifischer Denkhinweis. Erst bei einem weiteren Fehlversuch wird die bestehende ausführlichere Hilfe eingeblendet. Wiederkehrende eindeutige Muster führen in den vorhandenen vierstufigen Förderpfad mit Hilfe, weniger Hilfe, Transfer und Kontrolle.

Die Verfeinerung bleibt bewusst konservativ: Passt eine Fehlzahl nicht eindeutig zu einem bekannten Rechenweg, behauptet Rechenblitz keine konkrete Ursache und verwendet weiterhin die gröbere Fehlerkategorie.

Erst wenn ein ähnliches Muster mindestens zweimal auftritt, erscheint es als vorsichtiger Hinweis im Elternbereich und in der Lernlandkarte. Die Diagnose ist regelbasiert und erklärbar; sie behauptet keine medizinische oder lerntherapeutische Diagnose. Diagnosebeobachtungen sind pro Profil, Klassenstufe und Zahlenraum getrennt und bleiben ausschließlich lokal auf dem Gerät.

## Förderpfade und Recovery

Wiederkehrende Fehlermuster können jetzt direkt in einen gezielten Förderpfad überführt werden. Ein Förderpfad besteht standardmäßig aus acht Aufgaben in vier Stufen:

- **Mit Hilfe** – der Rechenweg wird sichtbar begleitet
- **Weniger Hilfe** – nur noch ein kurzer Hinweis bleibt
- **Selbst anwenden** – der Rechenweg wird übertragen
- **Kontrolle** – zwei Aufgaben ohne Starthilfe prüfen die neue Sicherheit

Der gewählte Schul-Rechenweg wird berücksichtigt, z. B. beim Zehnerübergang, Einmaleins oder schriftlichen Entbündeln.

Status eines Fehlermusters:

- **wiederkehrend**
- **wird gefördert**
- **verbessert**
- **stabil**

Ein erfolgreicher Förderpfad setzt ein Muster zunächst auf „verbessert“. Drei weitere passende Erstversuche ohne Rückfall machen es „stabil“. Alternativ wird nach drei Tagen eine kurze Kontrollrunde mit zwei Aufgaben fällig. Ein erneuter gleicher Fehler setzt das Muster wieder auf „wiederkehrend“.

Förderpfade zählen nicht als normale Meisterschaftsrunden und vergeben keine künstlichen Zusatzsterne. Ein stabil gemeistertes Muster kann jedoch das bestehende Abzeichen „Knacknuss geknackt“ auslösen.

## Aufgabenvielfalt und visuelle Rechenhilfen

Rechenblitz besitzt ein profilbezogenes Aufgaben-Gedächtnis. Es verhindert, dass identische Aufgaben oder sehr ähnliche Aufgabenfamilien in kurzen Abständen immer wieder auftauchen.

- Grundrechenarten vermeiden zuletzt verwendete Fakten über mehrere Sitzungen hinweg.
- Schwache Fakten bleiben lernwirksam und dürfen nach einem sinnvollen Abstand wiederkehren.
- Strukturierte Aufgaben und Klasse-3/4-Generatoren erzeugen mehrere Kandidaten und bevorzugen neue Aufgaben sowie neue Aufgabenfamilien.
- Sachaufgaben rotieren über zahlreiche Kontexte und Satzformen.
- Geld, Größen, Wahrscheinlichkeit, Kombinatorik, Zuordnungen und Umfang/Fläche besitzen mehrere unterschiedliche Aufgabentypen und Kontexte.
- Förderpfade vermeiden Dubletten innerhalb derselben Fördersequenz.
- Das Aufgaben-Gedächtnis bleibt pro Kinderprofil getrennt und wird bei einem Lernstands-Reset mit gelöscht.

Ein automatischer Varianz-Audit prüft unter anderem unmittelbare Dubletten, Wiederholungen innerhalb der letzten fünf Aufgaben, Anteil eindeutiger Aufgaben und Vielfalt der Aufgabenfamilien.

Bei passenden Hinweisen zeigt Rechenblitz jetzt zusätzlich visuelle Rechenhilfen, zum Beispiel:

- Zahlenstrahl beim Zehnerübergang
- Punktefeld für Malaufgaben
- Stellenwerttafel
- Einheitenleiter
- Bruchbild
- Zeitlinie
- Umfang-/Flächen-Darstellung
- Entscheidungshilfe für die Rechenart in Sachaufgaben

## Kompetenzmodell 2.0

Rechenblitz bewertet nicht mehr nur ganze Lernmodi, sondern auch kleine mathematische Teilkompetenzen mit stabilen IDs.

Beispiele:

- Zahlen sinnvoll zerlegen
- Plus ohne / mit Zehnerübergang
- Minus ohne / mit Zehnerübergang
- Einmaleins-Fakten und gleich große Gruppen
- Geteilt-Fakten und Umkehraufgaben
- Rechenart in Sachaufgaben erkennen
- Stellenwerte und Zahlzerlegung
- schriftliches Ausrichten sowie Übertrag / Entbündeln
- Rundungsstelle, Überschlag und Rechengesetze
- Einheiten umwandeln, Zeitspannen
- Daten, Wahrscheinlichkeit und Kombinatorik
- Umfang, Fläche, Körper, Symmetrie, Maßstab und Rauminhalt

Eine Aufgabe kann mehrere Kompetenzen berühren. Die primäre Kompetenz erhält volle Evidenz, unterstützende Voraussetzungen nur einen kleineren Anteil. Richtige Antworten mit eingeblendeter Hilfe zählen schwächer als frei gelöste Antworten. Förderpfade liefern bewusst weniger Evidenz als normale Übungsaufgaben.

### Mastery-Evidenz

Rechenblitz trennt für jedes Mikro-Lernziel vier unterschiedliche Aussagen:

- **selbstständig** – gelingt die Kompetenz ohne eingeblendete Hilfe?
- **mit Hilfe** – gelingt sie nach Denkhinweis, Darstellung oder geführtem Rechenweg?
- **nach Abstand** – gelingt sie nach mindestens zwei Tagen ohne gezieltes Vorüben noch selbstständig?
- **Transfer** – gelingt dieselbe Kompetenz selbstständig in einer veränderten Aufgabenform oder Anwendungssituation?

Die Mikro-Lernkarte unterscheidet weiterhin **Neu / Entdecken / Wird geübt / Sicher / Gemeistert**, aber die Schwellen sind strenger interpretierbar:

- **Sicher** verlangt genügend selbstständige Evidenz mit mindestens 80 % gewichteter Sicherheit.
- **Gemeistert** verlangt zusätzlich stärkere selbstständige Basisevidenz, eine erfolgreiche selbstständige Abstandskontrolle und erfolgreiche selbstständige Transfer-Evidenz.
- Hilfe bleibt wertvolle Lerninformation, kann allein aber weder „Sicher“ noch „Gemeistert“ erzeugen.

Die erste echte Abstandskontrolle wird frühestens nach **zwei Tagen** fällig. Nach stabiler selbstständiger Abstandsevidenz wird der nächste Abstand auf **sieben Tage** erweitert. Eine unsichere Abstandskontrolle führt dagegen nicht zu einer siebentägigen Pause, sondern kann nach zwei Tagen erneut geprüft werden.

„Meine Runde“ setzt den fälligen Abstandstest in den vorhandenen Wiederholungsslot. Dasselbe Ziel wird in dieser Runde weder als Warm-up noch gleichzeitig als Transferziel vorgeübt. Wenn noch keine Kompetenz für Abstand oder Transfer bereit ist, bleiben die Slots normale Wiederholung beziehungsweise vorsichtige Entdeckung.

Im Elternbereich erklärt **„Warum gerade diese Aufgaben?“**, welcher Teilschritt derzeit fokussiert wird und auf welcher Beobachtungsbasis diese Auswahl beruht.

### Erklärbarkeit für Eltern

Der Elternbereich leitet seine Empfehlung jetzt vorrangig aus denselben Mikro-Kompetenzen und Mastery-Schwellen ab, die auch „Meine Runde“ steuern. Dadurch werden nicht nur Trefferquoten gezeigt, sondern vier konkrete Fragen beantwortet:

- **Was klappt bereits?** – die aktuell stabilste beobachtete Mikro-Kompetenz wird benannt.
- **Was fehlt konkret?** – Rechenblitz unterscheidet fehlende selbstständige Sicherheit, Abstandskontrolle und Transfer.
- **Warum hat der Teilschritt diesen Status?** – „Sicher“ und „Gemeistert“ werden aus genau denselben Evidenzschwellen erklärt, die der adaptive Kern verwendet.
- **Warum kommen gerade diese Aufgaben?** – der Elternbereich beschreibt Fokus-, Abstand- und Transferanteile der nächsten Runde direkt aus dem tatsächlich erzeugten Rundenplan.

Die Beobachtungsbasis wird in verständlicher Form offengelegt: Anzahl passender Beobachtungen, Aufgaben ohne Hilfe, Aufgaben mit Hilfe sowie vorhandene Abstand- und Transferbeobachtungen. Die Texte beziehen sich ausdrücklich nur auf die in Rechenblitz bearbeiteten Aufgaben im aktuellen Profil, der aktuellen Klassenstufe und dem aktuellen Zahlenraum.

Wiederkehrende Fehlermuster werden vorsichtig formuliert. Ein Muster aus demselben Übungsbereich ist ein zusätzlicher Hinweis, aber kein Beweis dafür, dass genau dieses Muster die Ursache einer Mikro-Schwäche ist. Rechenblitz leitet daraus weiterhin keine medizinische, psychologische oder lerntherapeutische Diagnose ab.

Für ältere lokale Profile, die bereits Sitzungsverlauf besitzen, aber noch keine Mikro-Evidenz aus dem neueren Kompetenzmodell, bleibt die bisherige Bereichsauswertung als Fallback erhalten. Erst mit passenden neuen Mikro-Beobachtungen wechselt die Eltern-Erklärung automatisch auf die feinere Teilschritt-Ebene.

## Methoden-Engine, Schulmodus und Barrierearmut

Rechenblitz verwendet Hilfen jetzt in drei Stufen:

1. **Denkhinweis** – nur ein Einstieg in den Rechenweg
2. **Darstellung** – passende visuelle Hilfe
3. **Gemeinsam lösen** – geführte, teilweise interaktive Rechenschritte

Die tatsächlich benötigte Hilfestufe wird in der Mikro-Kompetenz-Evidenz berücksichtigt. Eine richtige Lösung ohne Hilfe zählt stärker als dieselbe Lösung nach einem vollständig geführten Rechenweg. Ebenso wird gespeichert, welcher schulische Rechenweg verwendet wurde.

Unter **So rechnen wir** gibt es zwei Modi:

- **Schulmethode** – die hinterlegte Methode wird konsequent genutzt.
- **Automatisch / weiß ich nicht** – Rechenblitz darf verschiedene schulübliche Darstellungen vergleichen, ändert die gespeicherte Schulmethode aber niemals automatisch.

### Darstellungskompetenz

Rechenblitz beobachtet jetzt auch den prozessbezogenen **Darstellungswechsel** als eigenes Mikro-Lernziel. Dabei wird nicht nur gerechnet, sondern geprüft, ob dieselbe mathematische Idee in unterschiedlichen Formen wiedererkannt wird.

Gezielte Aufgaben verbinden unter anderem:

- Zahl ↔ Stellenwertdarstellung
- Stellenwertdarstellung ↔ Zerlegung
- Punktefeld bzw. gleich große Gruppen ↔ Malaufgabe
- Malaufgabe ↔ sprachliche Gruppenbeschreibung

Die Stellenwertdarstellung skaliert bis zum Millionenraum. Gleich große Gruppen werden ab Klasse 2 eingesetzt; Klasse 1 bleibt bei Zahl-, Stellenwert- und Zerlegungsdarstellungen.

Darstellungsfehler erhalten eigene Mikro-Evidenz, einen passenden ersten Denkhinweis, visuelle Hilfe und bei wiederholtem Auftreten den bestehenden vierstufigen Förderpfad. Vorgegebene Darstellungen zuordnen und ineinander übertragen ist digital prüfbar. Eigene Darstellungen entwickeln, auswählen, zeichnen und begründen bleibt bewusst als praktisch zu ergänzende Unterrichtskompetenz gekennzeichnet.

### Modellierungskette in Sachaufgaben

Sachaufgaben werden nicht mehr nur als Gesamtaufgabe bewertet. Rechenblitz kann die zentralen Modellierungsschritte gezielt und getrennt beobachten:

1. wichtige Angaben erkennen und Unwichtiges ausblenden
2. passende Rechenart erkennen
3. die Sachsituation in eine passende Rechnung übersetzen
4. die Rechnung korrekt ausführen
5. das Ergebnis auf Frage und Situation zurückbeziehen

Für gezielte Lernrunden entstehen dafür isolierte Aufgaben, zum Beispiel Auswahl der benötigten Angaben, Auswahl der Rechenart, Auswahl der passenden Rechnung oder Auswahl eines passenden Antwortsatzes. Normale Sachaufgaben liefern weiterhin gewichtete Evidenz für mehrere zusammenhängende Teilschritte.

Damit wird digitales Üben diagnostischer, ohne mehr vorzutäuschen als die App prüfen kann: Eigene Sachkontexte formulieren, frei gewählte Modelle erläutern und Lösungswege im Gespräch verteidigen bleiben praktische Unterrichtsaufgaben.

### Systematischer Transfer

Transfer ist jetzt eine eigene Evidenzquelle im Mikro-Kompetenzmodell und nicht nur ein Aufgabentitel. **Meine Runde** wählt für den letzten Transfer-Slot bevorzugt eine bereits sichere Teilkompetenz mit wenig oder älterer Transfer-Evidenz.

Bei Grundrechenarten wird die Darstellungsform bewusst verändert:

- Plus ohne / mit Zehnerübergang → Anwendung in einem neuen Sachkontext
- Minus ohne / mit Zehnerübergang → Anwendung in einem neuen Sachkontext
- Mal-Fakten bzw. gleich große Gruppen → Gruppen in Tischen, Reihen oder Päckchen
- Geteilt-Fakten bzw. Verteilen → gleichmäßiges Verteilen auf Teams, Beutel oder Teller

Die Transferaufgabe bleibt auf dieselbe Mikro-Kompetenz getaggt. Ein Fehler im neuen Kontext verliert daher nicht die bereits vorhandene feine Fehlerdiagnose: Ein vergessener Übertrag, Mal-als-Plus oder Geteilt-als-Minus wird weiterhin als solcher erkannt.

Für Klasse 3/4 bleiben zusätzlich die vorhandenen anspruchsvolleren Sachaufgaben erhalten:

- zwei Rechenschritte nacheinander
- unnötige Informationen erkennen
- passende Rechnung auswählen
- Unterschiedsaufgaben
- Rückwärtsaufgaben
- Kombination aus Multiplikation und anschließendem Weiterrechnen

Transfer-Evidenz wird lokal getrennt von normaler Übungs-, Förder- und Abstandsevidenz gespeichert. Eine richtige Lösung mit Hilfe bleibt auch im Transfer als Hilfsevidenz sichtbar und erfüllt die selbstständige Transfer-Bedingung nicht. Lehreraufträge können Transfer ausdrücklich aktivieren; bei passenden Grundrechen-Kompetenzen wird der Auftrag dann ebenfalls in den Sachkontext verschoben.

### Lehrplantiefe Klasse 3/4

Die oberen Klassenstufen decken nun zusätzlich Bereiche ab, die zuvor nur teilweise vorhanden waren:

- Lagebeziehungen von Geraden: parallel und senkrecht
- rechte Winkel sowie Eigenschaften ausgewählter Dreiecke und Vierecke
- Mittelpunkt, Radius und Durchmesser am Kreis
- Sekundenumrechnung sowie einfache Datums- und Kalenderaufgaben
- Strichlisten auswerten und situationsgerecht zwischen Strichliste, Tabelle und Balkendiagramm wählen

- deutsche Zahlwörter bis **1.000.000** lesen und Zifferndarstellungen zuordnen
- mehrere große Zahlen der Größe nach ordnen
- wiederholte Zufallsexperimente anhand beobachteter Häufigkeiten auswerten
- beobachtete relative Häufigkeiten als Prozentwert einordnen
- Würfelnetze grafisch auf ihre tatsächliche Faltbarkeit prüfen

Für Würfelnetze wird nicht mit einer festen Liste „richtiger Bilder“ gearbeitet. Ein geometrischer Falt-Validator propagiert die räumliche Orientierung der sechs Quadrate und akzeptiert ein Netz nur, wenn genau sechs unterschiedliche Würfelflächen ohne Orientierungskonflikt entstehen.

### Automatischer Generator-Audit

Die CI erzeugt zusätzlich mehrere tausend Aufgaben aus allen Klasse-3/4-Lernwelten und prüft unter anderem:

- nichtleere Aufgabe, Schlüssel und Hinweis
- gültige Antwortindizes bei Auswahlaufgaben
- keine doppelten Antwortoptionen
- numerische Antworten innerhalb des erlaubten Antwortbereichs
- sechs unterschiedliche Quadrate bei Würfelnetzen
- Übereinstimmung zwischen QR-/Generator-Klassifikation und Würfelnetz-Validator
- gezielte Generierbarkeit und Mikro-Tagging neuer Lernziele

### Prozesskompetenzen

Klasse 3/4 enthält zusätzlich eigene Mikro-Lernziele für mathematisches Denken:

- **günstigen Rechenweg auswählen**
- **Rechenfehler erkennen**
- **Ergebnisse per Überschlag auf Plausibilität prüfen**
- **Rechenbeziehungen mathematisch begründen**
- **zwischen mathematischen Darstellungen wechseln**

Auch Begründungs- und Darstellungsaufgaben erhalten eigene Mikro-Lernziele. Rechenblitz kann dabei digital prüfen, ob ein Kind eine passende mathematische Begründung erkennt und nachvollzieht. Das freie Formulieren, Austauschen und Verteidigen eigener Begründungen bleibt bewusst als praktisch zu ergänzende Unterrichtskompetenz gekennzeichnet.

Diese Aufgaben sind nicht nur Multiple-Choice-Zusätze: Sie erhalten eigene Mikro-Evidenz, eigene Hilfestufen und – wo passend – konkrete visuelle Darstellungen. Wenn ein Kind nach einem ersten Fehler eine Hilfe nutzt und anschließend löst, wird diese Unterstützungs-Evidenz separat und schwächer gewichtet gespeichert, ohne die Direkt-richtig-Quote zu erhöhen.

### Visuelle Rechenwege

Die Hilfestufe „Darstellung“ zeigt inzwischen aufgabenspezifische Mathematik statt generischer Symbole, darunter:

- Zahlenstrahl mit Übergang
- Punktefelder für Multiplikation
- Stellenwerttafel bis zur Million
- schriftliche Addition/Subtraktion stellenrichtig untereinander
- Bruchbilder mit tatsächlich markiertem Anteil
- Einheitenleiter mit Start- und Zieleinheit
- Zeitlinien mit echten Uhrzeiten und Teilstrecken
- Rechtecke mit Maßen für Umfang und Fläche
- Visualisierung von Rechenvorteil, Fehlerprüfung und Überschlag
- Stellenwertdarstellungen und gleich große Punktgruppen für Darstellungswechsel

### Lokaler Lehrer-QR-Modus

Lehrkräfte können einen Lernauftrag aus:

- Klassenstufe
- Zahlenraum
- Mikro-Lernziel
- Aufgabenanzahl
- Rechenweg
- optionalem Transfer-Schwerpunkt

erzeugen. Der QR-Code enthält **keinen Namen, keine Profil-ID und keinen Lernverlauf**. Beim Scannen wird der Auftrag nur als temporärer Sitzungsrahmen verwendet; persönliche Profileinstellungen werden danach wiederhergestellt. Aufträge für eine andere Klassenstufe werden nicht still in das Profil übernommen.

Nach einer vollständig bearbeiteten Schulrunde erzeugt Rechenblitz zusätzlich einen **Ergebnis-QR**. Dieser enthält nur:

- eine stabile Auftrags-ID
- Lernziel und Zahlenraum des Auftrags
- bearbeitete Aufgaben
- direkt richtige Antworten und Fehlversuche
- durchschnittliche Antwortzeit
- aggregierte Hilfestufe und in dieser Runde verwendete Rechenwege

Die Lehrkraft kann den Ergebnis-QR direkt wieder scannen. Auch dieser Rückkanal benötigt kein Konto und überträgt keinen Namen, keine Profil-ID und keinen sonstigen Lernverlauf.

### Lehrplan-Audit

Der interne Thüringen-Audit ordnet jede Mikro-Kompetenz einem Lernbereich und einer stabilen Lernziel-ID zu. Er unterscheidet zwischen:

- **digital üb- und prüfbar**
- **digital unterstützt – praktisch ergänzen**

- **prozessbezogen** – z. B. Rechenweg wählen, Fehler erkennen und Plausibilität prüfen

Reales Messen, Zeichnen, Falten, Bauen und Orientieren wird bewusst nicht als vollständig digital prüfbar dargestellt. Der Audit ist eine interne Abdeckungsprüfung und keine amtliche Zertifizierung.

### Lesen & Darstellung

Geräteweite Accessibility-Optionen:

- größere Schrift
- hoher Kontrast
- reduzierte Animationen
- deutsches Vorlesen per System-TTS
- einstellbare Sprechgeschwindigkeit
- Vorlesen auf Knopfdruck auch dann, wenn automatisches Vorlesen deaktiviert ist

### Beta-Test

Rechenblitz kann strukturiertes lokales Testfeedback nach Rolle und Bereich erfassen. Der Export hängt automatisch keine Profil- oder Lerndaten an. Freitext kann jedoch persönliche Angaben enthalten, wenn Testpersonen diese selbst eintragen; die Oberfläche weist deshalb ausdrücklich darauf hin.

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
