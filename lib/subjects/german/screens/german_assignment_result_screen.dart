import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../german_teacher_assignment_result.dart';

class GermanAssignmentResultScreen extends StatelessWidget {
  const GermanAssignmentResultScreen({super.key, required this.result});

  final GermanTeacherAssignmentResult result;

  @override
  Widget build(BuildContext context) {
    final payload = result.toPayload();
    final percent = (result.accuracy * 100).round();
    final seconds = result.averageResponseMs <= 0
        ? '–'
        : '${(result.averageResponseMs / 1000).toStringAsFixed(1)} s';

    return Scaffold(
      appBar: AppBar(title: const Text('Deutsch-Ergebnis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
        children: <Widget>[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Der Ergebnis-QR enthält nur diese Schulrunde. Bei Aufträgen für einen ganzen Lernbereich kann er zusätzlich anonyme Summen je Lernziel enthalten. Name, Profil-ID und übriger Lernverlauf bleiben auf dem Gerät.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  Text(
                    result.targetLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Auftrag ${result.assignmentId}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'QR-Code mit dem Deutsch-Ergebnis',
                    child: QrImageView(
                      key: const ValueKey('german-assignment-result-qr'),
                      data: payload,
                      version: QrVersions.auto,
                      size: 260,
                      gapless: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 14,
                    children: <Widget>[
                      _Metric(
                        label: 'direkt richtig',
                        value:
                            '${result.correctFirstTry}/${result.completedTasks}',
                      ),
                      _Metric(label: 'Trefferquote', value: '$percent %'),
                      _Metric(
                        label: 'Fehlversuche',
                        value: '${result.incorrectAttempts}',
                      ),
                      _Metric(label: 'Ø Antwort', value: seconds),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: payload));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ergebniscode kopiert.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Ergebniscode kopieren'),
          ),
          const SizedBox(height: 8),
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
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      Text(label),
    ],
  );
}
