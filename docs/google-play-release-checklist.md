# Google Play Release-Checkliste – Rechenblitz

Stand: 9. September 2026.

Diese Checkliste trennt den technisch verifizierten App-Stand von
manuellen Play-Console-Schritten.

## 1. Technisch bereits erfüllt

- [x] Paketname: de.mdkks.rechenblitz
- [x] Version: 1.0.0, versionCode 1
- [x] targetSdk / compileSdk: API 36
- [x] signierte Release-AAB wird im CI erzeugt
- [x] signierte Release-APK wird zusätzlich geprüft
- [x] Flutter 3.47.2 ist im CI fest gepinnt
- [x] pubspec.lock ist versioniert und wird im CI geprüft
- [x] GitHub-Actions-Schritte sind per Commit-SHA gepinnt
- [x] Android-16-KB-Page-Size-Gate
- [x] keine INTERNET- oder ACCESS_NETWORK_STATE-Berechtigung
- [x] Android-Cloud-Backup und Geräteübertragung lokaler Daten deaktiviert
- [x] Kamera-Hardware für Play-Gerätefilter optional
- [x] QR-Fallback für Geräte ohne Kamera / verweigerte Berechtigung
- [x] keine Werbung, Analytics, Tracking oder In-App-Käufe
- [x] öffentliche Datenschutzerklärung per HTTPS erreichbar

## 2. Store-Haupteintrag

In Play Console unter Store-Haupteintrag eintragen:

- App-Name: **Rechenblitz**
- kurze Beschreibung und Langbeschreibung:
  siehe docs/google-play-store-listing-de.md
- Kategorie: **Bildung**
- Datenschutzerklärung:
  https://md-kks.github.io/Rechenblitz/privacy-policy.html

Grafiken vor Veröffentlichung bereitstellen:
- [x] Play-App-Symbol: 512 × 512 px, 32-Bit-RGBA-PNG, 3.710 Byte
      (`store/google-play/app-icon-512.png`)
- [x] Vorstellungsgrafik: 1.024 × 500 px, RGB-PNG ohne Alpha
      (`store/google-play/feature-graphic-1024x500.png`)
- [ ] mindestens 2 echte App-Screenshots
- [ ] empfohlen: mindestens 4 Smartphone-Screenshots in 1080 × 1920 px
- [ ] Alt-Text für jedes hochgeladene Bild

Screenshot-Regeln:
- JPEG oder 24-Bit-PNG ohne Alpha
- kleinste Kante mindestens 320 px
- größte Kante höchstens 3.840 px
- größte Kante maximal doppelt so lang wie die kleinste
- tatsächliche aktuelle App-Oberfläche zeigen
- keine Benachrichtigungen oder personenbezogenen Inhalte abbilden

## 3. Zielgruppe und Families

In „Zielgruppe und Inhalte“:
- [ ] 6–8 Jahre auswählen
- [ ] 9–12 Jahre auswählen
- [ ] bis 5 Jahre nicht auswählen
- [ ] Angaben zur Kinder-Zielgruppe vollständig bestätigen
- [ ] IARC-Altersfreigabe ausfüllen

Werbung:
- [ ] „Enthält Werbung?“ → **Nein**
- [ ] keine Werbe-SDKs angeben

Die aktuelle App enthält keine Werbung, keine sozialen Funktionen,
keinen anonymen Chat und keine externen Browser-/WebView-Flows.

## 4. App-Zugriff für die Prüfung

Rechenblitz benötigt kein Login und kein Benutzerkonto.

Empfohlener Prüferhinweis:

> Alle Kernfunktionen sind direkt nach dem Start ohne Konto zugänglich.
> Der Elternbereich wird durch zwei Sekunden langes Halten geöffnet.
> Lehreraufträge per QR-Code sind optional; Codes können im
> Scanner-Bereich auch manuell eingegeben werden.

- [ ] App-Zugriff in Play Console als ohne Zugangsdaten nutzbar angeben
- [ ] Elternbereich-Hinweis für Reviewer ergänzen, falls das Formular
      nach eingeschränkten Bereichen fragt

## 5. Data Safety

Ausfüllhilfe:
docs/google-play-data-safety.md

Aktueller technischer Stand:
- [ ] „Werden Nutzerdaten erhoben oder geteilt?“ anhand der aktuellen
      Play-Console-Frage nochmals prüfen; technisch ist **Nein** vorgesehen
- [ ] Kamera-Zweck: lokales Scannen von Lehrer-/Ergebnis-QR-Codes
- [ ] TTS-Hinweis beachten: Rechenblitz selbst hat kein Netzwerkrecht;
      der vom Gerät gewählte System-TTS-Anbieter liegt außerhalb der App

## 6. Harter Blocker vor Veröffentlichung

### Datenschutz-Kontakt

**BLOCKER – noch nicht mit verifizierten öffentlichen Daten gefüllt.**

Vor Production Release muss die Datenschutzerklärung einen eindeutigen
Entwickler-/Datenschutz-Kontakt oder einen konkreten Mechanismus für
Datenschutzanfragen enthalten. Die öffentlich genannte Entwickler-
Identität muss zum Store-Eintrag passen.

Zusätzlich verlangt Google Play in den Store-Einstellungen eine
Support-E-Mail-Adresse.

- [ ] öffentlichen Entwicklernamen festlegen
- [ ] Datenschutz-Ansprechpartner oder Anfrageweg festlegen
- [ ] verpflichtende Support-E-Mail in Play Store-Einstellungen eintragen
- [ ] prüfen, ob dieselbe öffentliche E-Mail als Datenschutz-Kontakt dient

Nicht eintragen:
- erfundene Adresse
- private Adresse aus anderen Quellen
- unbestätigte E-Mail-Adresse

Erst nach Festlegung des öffentlichen Entwicklerkontakts:
- [ ] docs/privacy-policy.html aktualisieren
- [ ] In-App-Datenschutzerklärung bei Bedarf angleichen
- [ ] öffentliche GitHub-Pages-Seite auf HTTP 200 und neuen Kontakt prüfen
- [ ] denselben Kontakt in der Play Console verwenden

## 7. Unmittelbar vor Production Release

- [ ] aktuelles Release-AAB aus einem grünen main-CI-Lauf verwenden
- [ ] main-Commit-SHA dokumentieren
- [ ] VersionCode vor jedem weiteren Upload erhöhen
- [ ] Data-Safety-Angaben gegen aktuelle Dependencies erneut prüfen
- [ ] flutter pub outdated prüfen
- [ ] Privacy-/Backup-/Kamera-/16-KB-CI-Gates grün
- [ ] Store-Texte und Grafiken auf aktuelle App-Version prüfen
- [ ] IARC abgeschlossen
- [ ] Zielgruppe/Families abgeschlossen
- [ ] Datenschutz-Kontakt gelöst
- [ ] Datenschutzerklärungs-URL live
- [ ] Production-Release erst danach einreichen

## Offizielle Referenzen

- Store-Felder und Textlimits:
  https://support.google.com/googleplay/android-developer/answer/9859152
- Vorschauelemente und Bildanforderungen:
  https://support.google.com/googleplay/android-developer/answer/9866151
- Families-Richtlinien:
  https://support.google.com/googleplay/android-developer/answer/9893335
