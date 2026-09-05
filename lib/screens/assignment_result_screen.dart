import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/teacher_assignment_result.dart';

class AssignmentResultScreen extends StatelessWidget {
  const AssignmentResultScreen({
    super.key,
    required this.result,
  });

  final TeacherAssignmentResult result;

  @override
  Widget build(BuildContext context) {
    final payload = result.toPayload();
    final percent = (result.accuracy * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Schulauftrag abgeschlossen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auftrag ${result.assignmentId}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(result.summary),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 22,
                    runSpacing: 14,
                    children: [
                      _Metric(
                        'direkt richtig',
                        '${result.correctFirstTry}/${result.completedTasks}',
                      ),
                      _Metric('Trefferquote', '$percent %'),
                      _Metric('Fehlversuche', '${result.incorrectAttempts}'),
                      _Metric(
                        'Hilfestufe',
                        result.maxHelpLevel == 0
                            ? 'keine'
                            : '${result.maxHelpLevel}/3',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'Ergebnis an die Lehrkraft zurückgeben',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Der QR-Code enthält nur das Ergebnis dieses Schulauftrags. '
                    'Kein Name, keine Profil-ID und kein sonstiger Lernverlauf werden übertragen.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    label: 'Ergebnis-QR für Auftrag ${result.assignmentId}',
                    child: QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 260,
                      gapless: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: payload));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ergebniscode kopiert.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Ergebniscode kopieren'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label),
        ],
      );
}
