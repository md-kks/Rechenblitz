import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/grade_level.dart';
import '../../../core/learning_app_theme.dart';
import '../../../core/learning_subject.dart';
import '../../../services/app_controller.dart';
import '../../../screens/assignment_result_scanner_screen.dart';
import '../german_competency.dart';
import '../german_competency_catalog.dart';
import '../german_learning_domain.dart';
import '../german_practice_planner.dart';
import '../german_session.dart';
import '../german_storage_service.dart';
import '../german_teacher_assignment_result.dart';
import '../german_teacher_assignment.dart';
import 'german_assignment_result_screen.dart';
import 'german_training_screen.dart';

class GermanTeacherModeScreen extends StatefulWidget {
  const GermanTeacherModeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<GermanTeacherModeScreen> createState() =>
      _GermanTeacherModeScreenState();
}

class _GermanTeacherModeScreenState extends State<GermanTeacherModeScreen> {
  late GradeLevel grade;
  GermanLearningDomain domain = GermanLearningDomain.reading;
  GermanCompetencyId? target;
  int tasks = 8;

  @override
  void initState() {
    super.initState();
    grade = widget.controller.gradeLevel;
  }

  List<GermanCompetencyDefinition> get _targets =>
      GermanCompetencyCatalog.forDomain(domain, grade);

  GermanTeacherAssignment get _assignment => GermanTeacherAssignment(
    gradeLevel: grade,
    domain: domain,
    tasks: tasks,
    targetCompetency: target,
  );

  ThemeData get _germanTheme => LearningAppTheme.build(
    subject: LearningSubject.german,
    accessibility: widget.controller.accessibilityPreferences,
  );

  void _setGrade(GradeLevel value) {
    setState(() {
      grade = value;
      if (target != null && !_targets.any((item) => item.id == target)) {
        target = null;
      }
    });
  }

  void _setDomain(GermanLearningDomain value) {
    setState(() {
      domain = value;
      target = null;
    });
  }

  Future<void> _testAssignment() async {
    final assignment = _assignment;
    final storage = GermanStorageService(
      profileId: widget.controller.activeProfileId,
    );
    final history = await storage.loadHistory();
    final round = GermanPracticePlanner.buildAssignmentRound(
      assignment: assignment,
      history: history,
    );
    if (!mounted || round.isEmpty) return;
    final session = await Navigator.of(context).push<GermanSessionResult>(
      MaterialPageRoute<GermanSessionResult>(
        builder: (_) => Theme(
          data: _germanTheme,
          child: GermanTrainingScreen(
            gradeLevel: assignment.gradeLevel,
            tasks: round,
            speak: widget.controller.speakOnDemand,
            speakCompletion:
                widget.controller.accessibilityPreferences.spokenRoundFeedback,
            sessionKind: GermanSessionKind.teacherAssignment,
            onComplete: (result) => unawaited(storage.appendSession(result)),
          ),
        ),
      ),
    );
    if (!mounted || session == null) return;
    final assignmentResult = GermanTeacherAssignmentResult.fromSession(
      assignment: assignment,
      session: session,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: _germanTheme,
          child: GermanAssignmentResultScreen(result: assignmentResult),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment;
    final payload = assignment.toPayload();
    return Theme(
      data: _germanTheme,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Deutsch-Auftrag')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
            children: <Widget>[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Der QR-Code enthält nur den Deutsch-Lernauftrag. Kein Name, keine Profil-ID und kein Lernverlauf werden übertragen.',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<GradeLevel>(
                initialValue: grade,
                decoration: const InputDecoration(
                  labelText: 'Klassenstufe',
                  border: OutlineInputBorder(),
                ),
                items: GradeLevel.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) _setGrade(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GermanLearningDomain>(
                initialValue: domain,
                decoration: const InputDecoration(
                  labelText: 'Lernbereich',
                  border: OutlineInputBorder(),
                ),
                items: GermanLearningDomain.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) _setDomain(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GermanCompetencyId>(
                key: ValueKey(
                  'german-teacher-target:${grade.name}:${domain.name}:${target?.name}',
                ),
                initialValue: target,
                decoration: const InputDecoration(
                  labelText: 'Lernziel',
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<GermanCompetencyId>>[
                  const DropdownMenuItem<GermanCompetencyId>(
                    value: null,
                    child: Text('Gesamter Lernbereich'),
                  ),
                  ..._targets.map(
                    (definition) => DropdownMenuItem<GermanCompetencyId>(
                      value: definition.id,
                      child: Text(definition.label),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => target = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: tasks,
                decoration: const InputDecoration(
                  labelText: 'Aufgabenanzahl',
                  border: OutlineInputBorder(),
                ),
                items: const <int>[5, 8, 10, 12, 15, 20]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value Aufgaben'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => tasks = value);
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      Text(
                        assignment.summary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Auftrags-ID: ${assignment.assignmentId}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        label: 'QR-Code für den Deutsch-Lehrerauftrag',
                        child: QrImageView(
                          key: const ValueKey('german-teacher-qr'),
                          data: payload,
                          version: QrVersions.auto,
                          size: 260,
                          gapless: false,
                        ),
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
                    const SnackBar(
                      content: Text('Deutsch-Auftragscode kopiert.'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Auftragscode kopieren'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('german-teacher-scan-result'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AssignmentResultScannerScreen(),
                  ),
                ),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Ergebnis-QR scannen'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: grade == widget.controller.gradeLevel
                    ? _testAssignment
                    : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  grade == widget.controller.gradeLevel
                      ? 'Auftrag auf diesem Profil testen'
                      : 'Zum Testen ein Profil derselben Klasse wählen',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
