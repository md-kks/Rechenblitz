import 'package:flutter/material.dart';

import '../models/micro_competency.dart';
import '../models/teacher_assignment_result.dart';
import '../models/training.dart';
import '../widgets/qr_camera_panel.dart';

class AssignmentResultScannerScreen extends StatefulWidget {
  const AssignmentResultScannerScreen({super.key});

  @override
  State<AssignmentResultScannerScreen> createState() =>
      _AssignmentResultScannerScreenState();
}

class _AssignmentResultScannerScreenState
    extends State<AssignmentResultScannerScreen> {
  final TextEditingController codeController = TextEditingController();
  TeacherAssignmentResult? result;
  String? errorText;
  bool handling = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void _handlePayload(String raw) {
    if (handling) return;
    final parsed = TeacherAssignmentResult.tryParse(raw);
    if (parsed == null) {
      setState(() {
        errorText = 'Das ist kein gültiger Rechenblitz-Ergebniscode.';
      });
      return;
    }

    setState(() {
      handling = true;
      result = parsed;
      errorText = null;
    });
  }

  void _scanAgain() {
    setState(() {
      result = null;
      errorText = null;
      handling = false;
      codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = result;
    return Scaffold(
      appBar: AppBar(title: const Text('Ergebnis scannen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Der Ergebnis-QR enthält nur die Daten der gerade absolvierten Schulrunde. '
                'Es werden keine Namen, Profil-IDs oder sonstigen Lernverläufe übertragen.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (current == null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 310,
                child: QrCameraPanel(
                  onPayload: (raw) {
                    if (raw.startsWith(
                      TeacherAssignmentResult.prefix,
                    )) {
                      _handlePayload(raw);
                    }
                  },
                ),
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Alternativ Ergebniscode einfügen',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'RBR1:…',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _handlePayload(codeController.text),
              icon: const Icon(Icons.input_rounded),
              label: const Text('Ergebniscode prüfen'),
            ),
          ] else ...[
            _ResultCard(result: current),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _scanAgain,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Nächstes Ergebnis scannen'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final TeacherAssignmentResult result;

  @override
  Widget build(BuildContext context) {
    final percent = (result.accuracy * 100).round();
    final seconds = result.averageResponseMs <= 0
        ? '–'
        : '${(result.averageResponseMs / 1000).toStringAsFixed(1)} s';

    return Card(
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
            const SizedBox(height: 6),
            Text(
              result.targetCompetency == null
                  ? result.mode.title
                  : MicroCompetencyCatalog
                      .definition(result.targetCompetency!)
                      .label,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: [
                _Metric(
                  'direkt richtig',
                  '${result.correctFirstTry}/${result.completedTasks}',
                ),
                _Metric('Trefferquote', '$percent %'),
                _Metric('Fehlversuche', '${result.incorrectAttempts}'),
                _Metric('Ø Antwort', seconds),
                _Metric(
                  'Hilfestufe',
                  result.maxHelpLevel == 0
                      ? 'keine'
                      : '${result.maxHelpLevel}/3',
                ),
                _Metric(
                  'Hilfebeobachtungen',
                  '${result.aidedObservations}',
                ),
              ],
            ),
            if (result.methodsUsed.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Verwendete Rechenwege',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              ...result.methodsUsed.map(
                (method) => Text('• $method'),
              ),
            ],
          ],
        ),
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
