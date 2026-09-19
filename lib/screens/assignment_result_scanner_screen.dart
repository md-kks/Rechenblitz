import 'package:flutter/material.dart';

import '../core/assignments/subject_result_envelope.dart';
import '../models/micro_competency.dart';
import '../models/teacher_assignment_result.dart';
import '../models/training.dart';
import '../subjects/german/german_teacher_assignment_result.dart';
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
  GermanTeacherAssignmentResult? germanResult;
  String? errorText;
  bool handling = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void _handlePayload(String raw) {
    if (handling) return;
    final math = TeacherAssignmentResult.tryParse(raw);
    if (math != null) {
      setState(() {
        handling = true;
        result = math;
        germanResult = null;
        errorText = null;
      });
      return;
    }

    final german = GermanTeacherAssignmentResult.tryParse(raw);
    if (german != null) {
      setState(() {
        handling = true;
        result = null;
        germanResult = german;
        errorText = null;
      });
      return;
    }

    setState(() {
      errorText = 'Das ist kein gültiger Lernergebniscode.';
    });
  }

  void _scanAgain() {
    setState(() {
      result = null;
      germanResult = null;
      errorText = null;
      handling = false;
      codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = result;
    final currentGerman = germanResult;
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
          if (current == null && currentGerman == null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 310,
                child: QrCameraPanel(
                  onPayload: (raw) {
                    if (raw.startsWith(TeacherAssignmentResult.prefix) ||
                        raw.startsWith(SubjectResultEnvelope.prefix)) {
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('assignment-result-code-input'),
              controller: codeController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'RBR1:… oder LBR1:…',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('assignment-result-code-submit'),
              onPressed: () => _handlePayload(codeController.text),
              icon: const Icon(Icons.input_rounded),
              label: const Text('Ergebniscode prüfen'),
            ),
          ] else ...[
            if (current != null)
              _ResultCard(result: current)
            else
              _GermanResultCard(result: currentGerman!),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              result.targetCompetency == null
                  ? result.mode.title
                  : MicroCompetencyCatalog.definition(
                      result.targetCompetency!,
                    ).label,
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
                _Metric('Hilfebeobachtungen', '${result.aidedObservations}'),
              ],
            ),
            if (result.methodsUsed.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Verwendete Rechenwege',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              ...result.methodsUsed.map((method) => Text('• $method')),
            ],
          ],
        ),
      ),
    );
  }
}

class _GermanResultCard extends StatelessWidget {
  const _GermanResultCard({required this.result});

  final GermanTeacherAssignmentResult result;

  @override
  Widget build(BuildContext context) {
    final percent = (result.accuracy * 100).round();
    final percentText = result.independentTasks == 0 ? '–' : '$percent %';
    final seconds = result.averageResponseMs <= 0
        ? '–'
        : '${(result.averageResponseMs / 1000).toStringAsFixed(1)} s';
    final breakdown =
        List<GermanAssignmentCompetencyResult>.from(result.competencyBreakdown)
          ..sort((a, b) {
            final category = _evidenceSortCategory(
              a,
            ).compareTo(_evidenceSortCategory(b));
            if (category != 0) return category;
            final accuracy = a.accuracy.compareTo(b.accuracy);
            if (accuracy != 0) return accuracy;
            final attempts = b.incorrectAttempts.compareTo(a.incorrectAttempts);
            if (attempts != 0) return attempts;
            return a.label.compareTo(b.label);
          });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Deutsch-Auftrag ${result.assignmentId}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(result.targetLabel),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: <Widget>[
                _Metric(
                  'direkt richtig',
                  '${result.correctFirstTry}/${result.completedTasks}',
                ),
                if (result.readAloudAssistedTasks > 0)
                  _Metric(
                    'selbstständig direkt richtig',
                    result.independentTasks == 0
                        ? '–'
                        : '${result.independentCorrectFirstTry}/${result.independentTasks}',
                  ),
                _Metric(
                  result.readAloudAssistedTasks > 0
                      ? 'Selbstständig-Quote'
                      : 'Trefferquote',
                  percentText,
                ),
                if (result.readAloudAssistedTasks > 0)
                  _Metric('mit Vorlesen', '${result.readAloudAssistedTasks}'),
                _Metric('Fehlversuche', '${result.incorrectAttempts}'),
                _Metric('Ø Antwort', seconds),
              ],
            ),
            if (breakdown.length > 1) ...<Widget>[
              const SizedBox(height: 18),
              const Text(
                'Lernziele in dieser Runde',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...breakdown.map((entry) {
                final entryPercent = (entry.accuracy * 100).round();
                final entryPercentText = entry.independentTasks == 0
                    ? '–'
                    : '$entryPercent %';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            entry.label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.readAloudAssistedTasks == 0
                                ? '${entry.correctFirstTry}/${entry.completedTasks} direkt richtig · '
                                      '$entryPercent % · ${entry.incorrectAttempts} Fehlversuche'
                                : entry.independentTasks == 0
                                ? 'noch keine selbstständige Beobachtung · '
                                      '${entry.readAloudAssistedTasks} mit Vorlesen · '
                                      '${entry.incorrectAttempts} Fehlversuche'
                                : '${entry.independentCorrectFirstTry}/${entry.independentTasks} '
                                      'selbstständig direkt richtig · '
                                      '${entry.readAloudAssistedTasks} mit Vorlesen · '
                                      '$entryPercentText · ${entry.incorrectAttempts} Fehlversuche',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

int _evidenceSortCategory(GermanAssignmentCompetencyResult entry) {
  final observedDifficulty =
      entry.incorrectAttempts > 0 ||
      (entry.independentTasks > 0 &&
          entry.independentCorrectFirstTry < entry.independentTasks);
  if (observedDifficulty) return 0;
  if (entry.independentTasks == 0) return 1;
  return 2;
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
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      Text(label),
    ],
  );
}
