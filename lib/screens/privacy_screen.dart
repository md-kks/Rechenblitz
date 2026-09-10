import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const publicPolicyUrl =
      'https://md-kks.github.io/Rechenblitz/privacy-policy.html';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Datenschutzerklärung')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      children: const [
        _PrivacyIntro(),
        SizedBox(height: 16),
        _PrivacySection(
          title: '1. Grundprinzip',
          body:
              'Rechenblitz ist local first. Die App hat kein Benutzerkonto, '
              'kein eigenes Backend, keine Werbung und keine Analyse- oder '
              'Tracking-Dienste. Lern- und Profildaten werden nicht an den '
              'Entwickler oder an einen Rechenblitz-Server übertragen.',
        ),
        _PrivacySection(
          title: '2. Lokal gespeicherte Daten',
          body:
              'Auf dem Gerät können Name oder Spitzname des Lernprofils, '
              'Profil-ID, Klassenstufe, Bundesland, Lernfortschritt, '
              'Antworten, Bearbeitungszeiten, Fehlermuster, Hilfen, '
              'Kompetenz-Evidenz, Abzeichen, Einstellungen und freiwilliges '
              'Beta-Feedback gespeichert werden. Diese Daten liegen im '
              'lokalen App-Speicher und sind für den Entwickler nicht '
              'einsehbar. Android-Cloud-Backup ist für Rechenblitz deaktiviert; '
              'die App schließt ihre lokalen Daten zusätzlich von Android-'
              'Cloud-Backup und Geräteübertragung aus.',
        ),
        _PrivacySection(
          title: '3. Kamera und QR-Codes',
          body:
              'Die Kameraberechtigung wird ausschließlich zum Scannen von '
              'Rechenblitz-QR-Codes verwendet. Kamerabilder werden auf dem '
              'Gerät verarbeitet, nicht als Foto gespeichert und nicht von '
              'Rechenblitz übertragen. Lehrer- und Ergebnis-QR-Codes '
              'enthalten keine Profilnamen, Profil-IDs oder vollständigen '
              'Lernverläufe.',
        ),
        _PrivacySection(
          title: '4. Vorlesen über System-TTS',
          body:
              'Beim Vorlesen übergibt Rechenblitz den angezeigten Text an '
              'die auf dem Gerät ausgewählte Android-Sprachausgabe. '
              'Rechenblitz betreibt dafür keinen eigenen Sprachserver. '
              'Ob eine Systemstimme lokal oder online arbeitet, richtet '
              'sich nach dem installierten TTS-Dienst und dessen '
              'Einstellungen.',
        ),
        _PrivacySection(
          title: '5. Beta-Feedback und Zwischenablage',
          body:
              'Beta-Feedback bleibt zunächst lokal. Ein Export wird nur '
              'nach ausdrücklicher Aktion in die Zwischenablage kopiert. '
              'Rechenblitz versendet diesen Text nicht automatisch. '
              'Freitext sollte keine Namen oder anderen persönlichen '
              'Angaben enthalten.',
        ),
        _PrivacySection(
          title: '6. Kinder und Tracking',
          body:
              'Rechenblitz ist für Kinder im Grundschulalter entwickelt. '
              'Die App enthält keine Werbung, keine personalisierte '
              'Werbung, kein Nutzertracking und fragt weder Standort noch '
              'Kontakte, Telefonnummer oder Werbe-ID ab.',
        ),
        _PrivacySection(
          title: '7. Löschen lokaler Daten',
          body:
              'Lernfortschritt kann im Elternbereich zurückgesetzt werden. '
              'Zusätzliche Lernprofile und Beta-Feedback können in der App '
              'gelöscht werden. Durch Deinstallation der App werden die '
              'lokalen App-Daten nach den Regeln des Betriebssystems '
              'entfernt.',
        ),
        _PrivacySection(
          title: '8. Anbieter und Kontakt',
          body:
              'Projekt/Entwickler: md-kks · Rechenblitz. '
              'Datenschutz- und Supportanfragen: '
              'mahajana.dasa@gmail.com. Allgemeine technische Anfragen: '
              'github.com/md-kks/Rechenblitz. Die öffentliche Fassung '
              'dieser Datenschutzerklärung steht unter $publicPolicyUrl.',
        ),
        _PrivacySection(
          title: '9. Änderungen',
          body:
              'Diese Erklärung wird angepasst, wenn sich Funktionen oder '
              'Datenflüsse von Rechenblitz ändern. Stand: 10. September 2026.',
        ),
      ],
    ),
  );
}

class _PrivacyIntro extends StatelessWidget {
  const _PrivacyIntro();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datenschutz bei Rechenblitz',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Die wichtigsten Punkte: Lernprofile bleiben auf dem Gerät, '
            'es gibt kein Rechenblitz-Konto und keine automatische '
            'Übertragung des Lernverlaufs.',
          ),
        ],
      ),
    ),
  );
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.body});

  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            SelectableText(body),
          ],
        ),
      ),
    ),
  );
}
