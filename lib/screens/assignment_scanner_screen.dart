import 'dart:async';

import 'package:flutter/material.dart';

import '../core/assignments/subject_assignment_envelope.dart';
import '../core/learning_app_theme.dart';
import '../core/learning_subject.dart';
import '../models/teacher_assignment.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../services/assignment_launcher.dart';
import '../subjects/german/german_practice_planner.dart';
import '../subjects/german/german_round_draft.dart';
import '../subjects/german/german_session.dart';
import '../subjects/german/german_storage_service.dart';
import '../subjects/german/german_teacher_assignment_result.dart';
import '../subjects/german/german_teacher_assignment.dart';
import '../subjects/german/screens/german_assignment_result_screen.dart';
import '../subjects/german/screens/german_training_screen.dart';
import '../widgets/qr_camera_panel.dart';

class AssignmentScannerScreen extends StatefulWidget {
  const AssignmentScannerScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AssignmentScannerScreen> createState() =>
      _AssignmentScannerScreenState();
}

class _AssignmentScannerScreenState extends State<AssignmentScannerScreen> {
  final TextEditingController codeController = TextEditingController();
  bool handling = false;
  String? errorText;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> _handlePayload(String raw) async {
    if (handling) return;
    final mathAssignment = TeacherAssignment.tryParse(raw);
    if (mathAssignment != null) {
      await _handleMathAssignment(mathAssignment);
      return;
    }

    final germanAssignment = GermanTeacherAssignment.tryParse(raw);
    if (germanAssignment != null) {
      await _handleGermanAssignment(germanAssignment);
      return;
    }

    setState(() {
      errorText = 'Das ist kein gültiger Lernauftrag.';
    });
  }

  Future<void> _handleMathAssignment(TeacherAssignment assignment) async {
    setState(() {
      handling = true;
      errorText = null;
    });

    final accepted = await _confirmAssignment(
      summary: assignment.summary,
      gradeLevel: assignment.gradeLevel,
      subjectLabel: 'Mathematik',
    );
    if (!mounted) return;
    if (accepted == true) {
      await launchTeacherAssignment(context, widget.controller, assignment);
    }
    if (mounted) setState(() => handling = false);
  }

  Future<void> _handleGermanAssignment(
    GermanTeacherAssignment assignment,
  ) async {
    setState(() {
      handling = true;
      errorText = null;
    });

    final accepted = await _confirmAssignment(
      summary: assignment.summary,
      gradeLevel: assignment.gradeLevel,
      subjectLabel: 'Deutsch',
    );
    if (!mounted) return;
    if (accepted == true) {
      final storage = GermanStorageService(
        profileId: widget.controller.activeProfileId,
      );
      final history = await storage.loadHistory();
      final tasks = GermanPracticePlanner.buildAssignmentRound(
        assignment: assignment,
        history: history,
      );
      if (tasks.isEmpty) {
        setState(() {
          handling = false;
          errorText = 'Für diesen Deutsch-Auftrag fehlen noch Aufgaben.';
        });
        return;
      }
      if (!mounted) return;
      final draft = GermanRoundDraft(
        gradeLevel: assignment.gradeLevel,
        taskIds: tasks.map((task) => task.id).toList(growable: false),
        currentIndex: 0,
        startedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        completedResults: const <GermanTaskResult>[],
        assignmentPayload: assignment.toPayload(),
        sessionKind: GermanSessionKind.teacherAssignment,
      );
      await storage.saveRoundDraft(draft);
      if (!mounted) return;
      final germanTheme = LearningAppTheme.build(
        subject: LearningSubject.german,
        accessibility: widget.controller.accessibilityPreferences,
      );
      final session = await Navigator.of(context).push<GermanSessionResult>(
        MaterialPageRoute<GermanSessionResult>(
          builder: (_) => Theme(
            data: germanTheme,
            child: GermanTrainingScreen(
              gradeLevel: assignment.gradeLevel,
              tasks: tasks,
              speak: widget.controller.speakOnDemand,
              autoSpeak: widget.controller.speak,
              speakCompletion: widget
                  .controller
                  .accessibilityPreferences
                  .spokenRoundFeedback,
              sessionKind: GermanSessionKind.teacherAssignment,
              draft: draft,
              onDraftChanged: (value) =>
                  unawaited(storage.saveRoundDraft(value)),
              onComplete: (result) => unawaited(
                Future.wait<void>(<Future<void>>[
                  storage.appendSession(result),
                  storage.clearRoundDraft(),
                ]),
              ),
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
            data: germanTheme,
            child: GermanAssignmentResultScreen(result: assignmentResult),
          ),
        ),
      );
    }
    if (mounted) setState(() => handling = false);
  }

  Future<bool?> _confirmAssignment({
    required String summary,
    required GradeLevel gradeLevel,
    required String subjectLabel,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$subjectLabel-Auftrag erkannt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(
            gradeLevel == widget.controller.gradeLevel
                ? 'Der Auftrag passt zur Klassenstufe dieses Profils.'
                : 'Der Auftrag ist für ${gradeLevel.label}, dieses Profil aber für ${widget.controller.gradeLevel.label}. Er wird nicht in das Profil übernommen.',
          ),
          const SizedBox(height: 10),
          const Text('Der QR-Code enthält keine persönlichen Schülerdaten.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: gradeLevel == widget.controller.gradeLevel
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Auftrag starten'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Schulauftrag scannen')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Scanne den QR-Code der Lehrkraft. Der Auftrag wird nur für diese Runde verwendet und verändert deine persönlichen Profileinstellungen nicht.',
            ),
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 310,
            child: handling
                ? const ColoredBox(color: Colors.black)
                : QrCameraPanel(
                    onPayload: (raw) {
                      if (raw.startsWith(TeacherAssignment.prefix) ||
                          raw.startsWith(SubjectAssignmentEnvelope.prefix)) {
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
          'Alternativ Auftragscode einfügen',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('assignment-code-input'),
          controller: codeController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'RB1:… oder LB1:…',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('assignment-code-submit'),
          onPressed: () => _handlePayload(codeController.text),
          icon: const Icon(Icons.input_rounded),
          label: const Text('Code prüfen'),
        ),
      ],
    ),
  );
}
