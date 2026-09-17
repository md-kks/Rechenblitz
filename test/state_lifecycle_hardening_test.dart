import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/support_session_progress.dart';
import 'package:rechenblitz/models/teacher_assignment.dart';
import 'package:rechenblitz/models/teacher_assignment_result.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/assignment_result_scanner_screen.dart';
import 'package:rechenblitz/screens/assignment_result_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'Bundeslandwechsel verwirft Förderentwürfe und aktiven Schulauftrag',
    () async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.hundred;
      await controller.setProfileState(GermanState.bavaria);
      final now = DateTime.now();

      final remediation = _remediationSession(
        competency: MicroCompetencyId.dataReading,
        mode: TrainingMode.dataCharts,
        pattern: ErrorPattern.dataReading,
        now: now,
      );
      final recovery = _stepRecoverySession(
        competency: MicroCompetencyId.dataReading,
        mode: TrainingMode.dataCharts,
        now: now,
      );
      await controller.saveRemediationSession(remediation);
      await controller.saveStepRecoverySession(recovery);
      controller.beginTeacherAssignment(
        const TeacherAssignment(
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          mode: TrainingMode.dataCharts,
          tasks: 5,
          methods: MethodPreferences(),
          state: GermanState.bavaria,
          targetCompetency: MicroCompetencyId.dataReading,
        ),
      );

      expect(controller.remediationSessionProgress, isNotNull);
      expect(controller.stepRecoverySessionProgress, isNotNull);
      expect(controller.hasTeacherAssignment, isTrue);

      await controller.setProfileState(GermanState.hesse);

      expect(controller.activeProfile.state, GermanState.hesse);
      expect(controller.remediationSessionProgress, isNull);
      expect(controller.stepRecoverySessionProgress, isNull);
      expect(controller.hasTeacherAssignment, isFalse);

      final reloaded = AppController();
      await reloaded.load();
      expect(reloaded.activeProfile.state, GermanState.hesse);
      expect(reloaded.remediationSessionProgress, isNull);
      expect(reloaded.stepRecoverySessionProgress, isNull);
    },
  );

  test('Lernstart beendet ebenfalls einen temporären Schulauftrag', () async {
    final controller = AppController();
    await controller.load();
    controller.beginTeacherAssignment(
      const TeacherAssignment(
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        mode: TrainingMode.minus,
        tasks: 5,
        methods: MethodPreferences(),
        state: GermanState.thuringia,
        targetCompetency: MicroCompetencyId.subtractionTenBridge,
      ),
    );
    expect(controller.hasTeacherAssignment, isTrue);

    await controller.saveLearningStartSetup(
      name: 'Kind',
      grade: GradeLevel.second,
      state: GermanState.bavaria,
    );

    expect(controller.hasTeacherAssignment, isFalse);
    expect(controller.activeProfile.state, GermanState.bavaria);
  });

  test(
    'alter landesfremder Förderentwurf wird beim Laden selbst geheilt',
    () async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.hundred;
      await controller.setProfileState(GermanState.bavaria);
      final now = DateTime.now();

      await controller.saveRemediationSession(
        _remediationSession(
          competency: MicroCompetencyId.dataReading,
          mode: TrainingMode.dataCharts,
          pattern: ErrorPattern.dataReading,
          now: now,
        ),
      );
      await controller.saveStepRecoverySession(
        _stepRecoverySession(
          competency: MicroCompetencyId.dataReading,
          mode: TrainingMode.dataCharts,
          now: now,
        ),
      );

      // Simuliert einen Altbestand aus einer Version, die den Landeswechsel
      // noch nicht an die Förderentwürfe gebunden hat.
      final prefs = await SharedPreferences.getInstance();
      final rawProfiles = prefs.getString('learner_profiles_v1')!;
      final profiles = jsonDecode(rawProfiles) as List<dynamic>;
      final first = Map<String, dynamic>.from(
        profiles.first as Map<String, dynamic>,
      );
      first['state'] = GermanState.hesse.name;
      profiles[0] = first;
      await prefs.setString('learner_profiles_v1', jsonEncode(profiles));

      final reloaded = AppController();
      await reloaded.load();

      expect(reloaded.activeProfile.state, GermanState.hesse);
      expect(reloaded.remediationSessionProgress, isNull);
      expect(reloaded.stepRecoverySessionProgress, isNull);
      expect(
        prefs.containsKey('profile:default:remediation_session_v1'),
        isFalse,
      );
      expect(
        prefs.containsKey('profile:default:step_recovery_session_v1'),
        isFalse,
      );
    },
  );

  test(
    'landesunabhängige Förderentwürfe bleiben nach Neustart erhalten',
    () async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.hundred;
      await controller.setProfileState(GermanState.hesse);
      final now = DateTime.now();

      final remediation = _remediationSession(
        competency: MicroCompetencyId.subtractionTenBridge,
        mode: TrainingMode.minus,
        pattern: ErrorPattern.tenBridge,
        now: now,
      );
      final recovery = _stepRecoverySession(
        competency: MicroCompetencyId.subtractionTenBridge,
        mode: TrainingMode.minus,
        now: now,
      );
      await controller.saveRemediationSession(remediation);
      await controller.saveStepRecoverySession(recovery);

      final reloaded = AppController();
      await reloaded.load();

      expect(reloaded.activeProfile.state, GermanState.hesse);
      expect(reloaded.remediationSessionProgress, isNotNull);
      expect(reloaded.stepRecoverySessionProgress, isNotNull);
      expect(
        reloaded.resumableRemediationSession(
          pattern: ErrorPattern.tenBridge,
          mode: TrainingMode.minus,
          reviewOnly: false,
        ),
        isNotNull,
      );
      expect(reloaded.resumableStepRecoverySession(recovery.focus), isNotNull);
    },
  );

  test('Bundeslandwechsel verwirft nur die Einstufungs-Baseline', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.setProfileState(GermanState.bavaria);

    await controller.completeAssessment(
      const <AssessmentModeResult>[
        AssessmentModeResult(
          mode: TrainingMode.dataCharts,
          correct: 1,
          total: 1,
        ),
      ],
      taskResults: const <AssessmentTaskResult>[
        AssessmentTaskResult(
          mode: TrainingMode.dataCharts,
          taskKey: 'data:chart:state-baseline',
          correct: true,
          targetCompetency: MicroCompetencyId.dataReading,
        ),
      ],
    );
    await controller.recordIndependentStepAttempt(
      mode: TrainingMode.minus,
      taskKey: 'minus:14:6',
      stepKey: 'bridgeAmount',
      competencyId: MicroCompetencyId.subtractionTenBridge,
      correct: true,
      usedHelp: false,
      helpLevel: 0,
    );
    await controller.addSession(
      TrainingSessionResult(
        mode: TrainingMode.minus,
        startedAt: DateTime(2026, 9, 18, 8),
        finishedAt: DateTime(2026, 9, 18, 8, 3),
        total: 5,
        correctFirstTry: 5,
        incorrectAttempts: 0,
        plusCorrect: 0,
        plusTotal: 0,
        minusCorrect: 5,
        minusTotal: 5,
        averageResponseMs: 1800,
        numberRange: NumberRangeLevel.hundred,
        gradeLevel: GradeLevel.second,
      ),
    );

    expect(controller.history.where((entry) => entry.isAssessment), isNotEmpty);
    expect(
      controller.microObservations.where(
        (entry) => entry.source == MicroEvidenceSource.assessment,
      ),
      isNotEmpty,
    );
    expect(controller.activeProfile.assessmentCompletedAt, isNotNull);

    await controller.setProfileState(GermanState.hesse);

    expect(controller.history.where((entry) => entry.isAssessment), isEmpty);
    expect(
      controller.history.where((entry) => !entry.isAssessment),
      hasLength(1),
    );
    expect(
      controller.microObservations.where(
        (entry) => entry.source == MicroEvidenceSource.assessment,
      ),
      isEmpty,
    );
    expect(
      controller.microObservations.where(
        (entry) => entry.source == MicroEvidenceSource.independentStep,
      ),
      isNotEmpty,
    );
    expect(controller.activeProfile.assessmentCompletedAt, isNull);
  });

  test('Zahlenraumwechsel verwirft die alte Einstufungs-Baseline', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    await controller.completeAssessment(
      const <AssessmentModeResult>[
        AssessmentModeResult(mode: TrainingMode.practice, correct: 1, total: 1),
      ],
      taskResults: const <AssessmentTaskResult>[
        AssessmentTaskResult(
          mode: TrainingMode.practice,
          taskKey: 'plus:8:7',
          correct: true,
          targetCompetency: MicroCompetencyId.additionTenBridge,
        ),
      ],
    );

    expect(controller.activeProfile.assessmentCompletedAt, isNotNull);
    expect(controller.history.where((entry) => entry.isAssessment), isNotEmpty);

    await controller.setNumberRange(NumberRangeLevel.twenty);

    expect(controller.activeProfile.assessmentCompletedAt, isNull);
    expect(controller.history.where((entry) => entry.isAssessment), isEmpty);
    final retainedAssessmentEvidence = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.assessment)
        .toList();
    expect(retainedAssessmentEvidence, hasLength(1));
    expect(
      retainedAssessmentEvidence.single.numberRange,
      NumberRangeLevel.hundred,
    );
  });

  test('Ergebniscode verwirft unmöglichen Landes-Lehrplan-Kontext', () {
    const impossible = TeacherAssignmentResult(
      assignmentId: 'ABCDEF12',
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      mode: TrainingMode.dataCharts,
      requestedTasks: 5,
      completedTasks: 5,
      correctFirstTry: 4,
      incorrectAttempts: 1,
      averageResponseMs: 1800,
      aidedObservations: 0,
      maxHelpLevel: 0,
      methodsUsed: <String>[],
      state: GermanState.hesse,
      targetCompetency: MicroCompetencyId.dataReading,
    );

    expect(impossible.hasSaneContext, isFalse);
    expect(TeacherAssignmentResult.tryParse(impossible.toPayload()), isNull);
  });

  testWidgets('Ergebnisansichten zeigen den Lehrplan-Kontext sichtbar', (
    tester,
  ) async {
    const result = TeacherAssignmentResult(
      assignmentId: 'ABCDEF12',
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      mode: TrainingMode.dataCharts,
      requestedTasks: 5,
      completedTasks: 5,
      correctFirstTry: 4,
      incorrectAttempts: 1,
      averageResponseMs: 1800,
      aidedObservations: 1,
      maxHelpLevel: 1,
      methodsUsed: <String>[],
      state: GermanState.bavaria,
      targetCompetency: MicroCompetencyId.dataReading,
    );

    await tester.pumpWidget(
      const MaterialApp(home: AssignmentResultScreen(result: result)),
    );
    expect(
      find.byKey(const ValueKey('assignment-completion-context')),
      findsOne,
    );
    expect(find.text('Klasse 2 · Bayern · bis 100'), findsOne);

    await tester.pumpWidget(
      const MaterialApp(home: AssignmentResultScannerScreen()),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), result.toPayload());
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    await tester.tap(find.text('Ergebniscode prüfen'));
    await tester.pump();

    expect(find.byKey(const ValueKey('assignment-result-context')), findsOne);
    expect(find.text('Klasse 2 · Bayern · bis 100'), findsOne);
  });

  testWidgets('älterer Ergebniscode kennzeichnet fehlendes Bundesland', (
    tester,
  ) async {
    const legacy = TeacherAssignmentResult(
      assignmentId: '1234ABCD',
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      mode: TrainingMode.minus,
      requestedTasks: 5,
      completedTasks: 5,
      correctFirstTry: 5,
      incorrectAttempts: 0,
      averageResponseMs: 1500,
      aidedObservations: 0,
      maxHelpLevel: 0,
      methodsUsed: <String>[],
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
    );

    await tester.pumpWidget(
      const MaterialApp(home: AssignmentResultScreen(result: legacy)),
    );

    expect(
      find.text('Klasse 2 · Bundesland nicht enthalten · bis 100'),
      findsOne,
    );
  });
}

RemediationTask _task({
  required MicroCompetencyId competency,
  required TrainingMode mode,
}) => RemediationTask(
  stage: RemediationStage.guided,
  mode: mode,
  taskKey: 'state-hardening:${competency.name}',
  prompt: 'Teste den Lernschritt.',
  answer: 1,
  maxAnswerValue: 10,
  hint: 'Kurzer Hinweis.',
  targetCompetency: competency,
);

RemediationSessionProgress _remediationSession({
  required MicroCompetencyId competency,
  required TrainingMode mode,
  required ErrorPattern pattern,
  required DateTime now,
}) => RemediationSessionProgress(
  pattern: pattern,
  mode: mode,
  gradeLevel: GradeLevel.second,
  numberRange: NumberRangeLevel.hundred,
  reviewOnly: false,
  tasks: <RemediationTask>[_task(competency: competency, mode: mode)],
  index: 0,
  wrongOnCurrent: 0,
  firstAttemptRecorded: false,
  checkCorrect: 0,
  checkTotal: 0,
  showHint: false,
  updatedAt: now,
);

StepRecoverySessionProgress _stepRecoverySession({
  required MicroCompetencyId competency,
  required TrainingMode mode,
  required DateTime now,
}) {
  final focus = IndependentStepRecoveryFocus(
    competencyId: competency,
    stepKey: 'state-hardening-step',
    label: 'Lernschritt prüfen',
    mode: mode,
    lastSeen: now.subtract(const Duration(minutes: 1)),
    sourceTaskKey: 'state-hardening:${competency.name}',
  );
  return StepRecoverySessionProgress(
    focus: focus,
    numberRange: NumberRangeLevel.hundred,
    tasks: <RemediationTask>[_task(competency: competency, mode: mode)],
    index: 0,
    wrongOnCurrent: 0,
    firstAttemptRecorded: false,
    showHint: false,
    updatedAt: now,
  );
}
