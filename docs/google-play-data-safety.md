# Google Play – Data Safety / Families für Rechenblitz

Stand: 9. September 2026.

Diese Datei ist eine Ausfüllhilfe für die Play Console. Vor jeder
Veröffentlichung muss die aktuelle Formulierung der Play-Console-Fragen
noch einmal geprüft werden.

## Zielgruppe

Rechenblitz ist für die deutsche Grundschule, Klassen 1–4, entwickelt.
Damit umfasst die Zielgruppe Kinder und die Google-Play-Families-
Richtlinien sind zu beachten.

Empfohlene Zielaltersgruppen in der Play Console:
- 6–8 Jahre
- 9–12 Jahre

Keine Zielgruppe „bis 5 Jahre“, sofern Produkt und Store-Eintrag nicht
ausdrücklich für Vorschulkinder ausgelegt werden.
## Werbung und Monetarisierung

- Enthält Werbung: **Nein**
- Personalisierte Werbung: **Nein**
- Werbe-SDKs: **Keine**
- In-App-Käufe: derzeit **keine**
- Nutzertracking / Analytics: **keine**

## Datenübertragung außerhalb des Geräts

Rechenblitz betreibt kein Konto, kein eigenes Backend und keine
Analyseplattform. Lern- und Profildaten werden nicht automatisch
außerhalb des Geräts übertragen. Die fertige Android-Release-APK besitzt
keine INTERNET- oder ACCESS_NETWORK_STATE-Berechtigung. Android-Cloud-
Backup ist deaktiviert; alle lokalen App-Datenbereiche sind zusätzlich
von Android-Cloud-Backup und Geräteübertragung ausgeschlossen.

Google Play definiert „Erhebung“ im Data-Safety-Formular als Übertragung
von Daten vom Gerät. Rein lokale Verarbeitung ist dort nicht als
Erhebung anzugeben. Für „Werden Nutzerdaten erhoben oder geteilt?“ ist
nach aktuellem technischen Stand daher **Nein** vorgesehen.

Wichtig: Diese Antwort erneut prüfen, sobald neue SDKs, Cloud-Funktionen,
Crash-Reporting, Analytics, Synchronisation oder Online-Feedback
hinzukommen.
## Lokal verarbeitete Daten

Folgende Daten können lokal im App-Speicher liegen:
- Name oder Spitzname eines Lernprofils
- interne Profil-ID
- Klassenstufe und Bundesland
- Lernverlauf und Antworten
- Bearbeitungszeiten und Fehlermuster
- Hilfen, Kompetenz-Evidenz und Wiederholungsstatus
- Abzeichen und Einstellungen
- freiwilliges Beta-Feedback

Diese Daten werden nicht an den Entwickler übertragen.

## Kamera

Berechtigung: android.permission.CAMERA

Zweck: ausschließlich QR-Codes für Lehreraufträge und Ergebnisrückgabe
scannen.

Rechenblitz verwendet flutter_zxing / ZXing-C++ für die lokale
QR-Erkennung. Es wird kein Google-ML-Kit-Scanner verwendet. Kamerabilder
werden lokal verarbeitet und von Rechenblitz weder als Foto gespeichert
noch übertragen.
## Text-to-Speech

Rechenblitz nutzt flutter_tts und übergibt Vorlesetext an die vom Gerät
gewählte Android-Sprachausgabe.

Rechenblitz selbst sendet den Text nicht an einen eigenen Server.
Ob der installierte System-TTS-Anbieter lokal oder online arbeitet,
liegt außerhalb des Rechenblitz-Backends und muss bei Änderungen der
Plattform-/SDK-Nutzung erneut geprüft werden.

## Dependency-Audit vom 10. September 2026

Geprüft mit Flutter 3.47.2 und Dart 3.13.2. Direkte
Laufzeit-Abhängigkeiten sind ausschließlich:

- `shared_preferences 2.5.5` für lokale Einstellungen und Lerndaten
- `qr_flutter 4.1.0` für lokal erzeugte QR-Codes
- `flutter_tts 4.2.5` für die gewählte System-Sprachausgabe
- `flutter_zxing 3.0.1` für lokale QR-Erkennung
- `camera 0.12.1` für den QR-Kamerazugriff

`flutter pub outdated` meldet alle direkten Laufzeit- und
Entwicklungsabhängigkeiten als aktuell. Neuere Versionen existieren nur
für derzeit nicht auflösbare transitive Pakete (`material_color_utilities`,
`qr`) sowie die transitive Entwicklungsabhängigkeit `test_api`.

`http 1.6.0` ist transitiv über die von `flutter_zxing` eingebrachte
`image_picker`/`file_selector`-Kette vorhanden. Rechenblitz importiert
`package:http` nicht direkt. Entscheidend für den Android-Release bleibt
zudem das CI-geprüfte Release-Manifest: Es enthält weder `INTERNET` noch
`ACCESS_NETWORK_STATE`. Neue direkte Laufzeit-Abhängigkeiten oder direkte
Netzwerk-/Analytics-Imports lassen den Release-Readiness-Test fehlschlagen
und erfordern einen neuen Data-Safety-Audit.

## Kinder-/Families-Prüfpunkte

- keine INTERNET- oder ACCESS_NETWORK_STATE-Berechtigung
- keine AD_ID-Berechtigung
- keine Standortberechtigung
- keine Kontakte
- keine Telefonnummer
- keine Gerätekennungen für Tracking
- keine Werbung
- keine anonymen Chats / sozialen Funktionen
- Kamera nur für die Kernfunktion QR-Scan
- Datenschutzerklärung in der App und öffentlich im Web
## Löschung

- Lernfortschritt: im Elternbereich zurücksetzbar
- zusätzliche Lernprofile: löschbar
- Beta-Feedback: löschbar
- komplette lokale App-Daten: durch Deinstallation nach den Regeln des
  Betriebssystems entfernbar
- kein Serverkonto und keine serverseitigen Kontodaten

## Play-Console-Links

Öffentliche Datenschutzerklärung:
https://md-kks.github.io/Rechenblitz/privacy-policy.html

Projekt:
https://github.com/md-kks/Rechenblitz

## Vor Release erneut prüfen

1. AndroidManifest-Berechtigungen
2. flutter pub outdated
3. alle SDK-/Plugin-Datennutzungsangaben
4. Data-Safety-Fragebogen
5. Zielgruppe und Inhalte
6. IARC-Altersfreigabe
7. Families-Richtlinien
8. Datenschutzerklärungs-URL
