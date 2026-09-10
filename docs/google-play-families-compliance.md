# Google Play Families – technischer Compliance-Audit

Stand: 10. September 2026

Dieser Audit dokumentiert den technischen App-Stand für die vorgesehenen Google-Play-Zielgruppen 6–8 und 9–12 Jahre. Er ersetzt weder die Play-Console-Erklärungen noch eine rechtliche Prüfung.

## Zielgruppe und Produktverhalten

Rechenblitz ist eine Mathematik-Lernapp für die Grundschule, Klassen 1–4. Für Google Play sind 6–8 Jahre und 9–12 Jahre vorgesehen; bis 5 Jahre ist nicht vorgesehen.

Die aktuelle App enthält:
- keine Werbung oder Werbe-SDKs
- keine In-App-Käufe oder sonstige Monetarisierung
- kein Konto, Login oder eigenes Backend
- keine sozialen Funktionen, Chats oder nutzergenerierte öffentliche Inhalte
- keinen WebView- oder Affiliate-Zweck
- keine Analytics- oder Tracking-SDKs
## Daten, Sensoren und Berechtigungen

Das Android-Release besitzt absichtlich die Kameraberechtigung für Lehrer- und Ergebnis-QR-Codes. Kamerabilder werden lokal verarbeitet, nicht als Foto gespeichert und von Rechenblitz nicht übertragen.

Das Release-CI verbietet unter anderem INTERNET, ACCESS_NETWORK_STATE, AD_ID, Standort, Kontakte, Telefonzugriff, Mikrofon, Medien-/Speicherzugriff und Benachrichtigungsberechtigungen. Android-Cloud-Backup und Geräteübertragung der lokalen Lerndaten sind deaktiviert.

Lernprofile, Antworten, Lernfortschritt, Fehlermuster, Hilfen und Einstellungen bleiben im lokalen App-Speicher. Lehrer-QR-Codes enthalten keine Profilnamen oder Profil-IDs.

Beim Vorlesen wird Text an den vom Gerät ausgewählten System-TTS-Dienst übergeben. Rechenblitz selbst betreibt dafür keinen Sprachserver und besitzt kein Netzwerkrecht; Verhalten und Datenverarbeitung des installierten System-TTS-Anbieters liegen außerhalb des Rechenblitz-Backends.

## Auditierte Laufzeit-SDKs

Direkte Laufzeit-Abhängigkeiten neben Flutter:
- `shared_preferences 2.5.5`: lokale Einstellungen und Lerndaten
- `qr_flutter 4.1.0`: lokale QR-Erzeugung
- `flutter_tts 4.2.5`: Übergabe an System-TTS
- `flutter_zxing 3.0.1`: lokale QR-Erkennung
- `camera 0.12.1`: Kamerazugriff für QR-Scan
`http 1.6.0` ist nur transitiv über `flutter_zxing`/`image_picker`/`file_selector` vorhanden. Rechenblitz importiert `package:http` nicht direkt; das reale Android-Release enthält keine INTERNET- oder ACCESS_NETWORK_STATE-Berechtigung.

Neue direkte Laufzeit-Abhängigkeiten sowie neue Netzwerk-, Analytics-, Ads- oder Auth-Imports lösen den Release-Readiness-Gate aus und erfordern einen erneuten Audit.

## Play-Console-Schritte, die weiterhin manuell bestätigt werden müssen

- Zielgruppen 6–8 und 9–12 auswählen; bis 5 nicht auswählen
- „Enthält Werbung?“ mit Nein beantworten
- App-Zugriff ohne Zugangsdaten angeben; Elternbereich: 2 Sekunden halten
- Data-Safety-Fragen gegen den aktuellen Play-Console-Wortlaut beantworten
- Kamera ausschließlich als lokalen QR-Scanner erklären
- IARC-Fragebogen vollständig und wahrheitsgemäß ausfüllen
- öffentliche Support-E-Mail `mahajana.dasa@gmail.com` eintragen

Diese Punkte gelten erst als abgeschlossen, wenn sie tatsächlich in der Play Console gespeichert wurden.

## Offizielle Referenzen

- Families Policy: https://support.google.com/googleplay/android-developer/answer/9893335
- Zielgruppe und Inhalte: https://support.google.com/googleplay/android-developer/answer/9867159
- Content Ratings / IARC: https://support.google.com/googleplay/android-developer/answer/9898843
