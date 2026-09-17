import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test(
    'Diagnose-Evidence-ID bleibt über Neustart exakt einmal wirksam',
    () async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.hundred;
      await controller.startRemediation(ErrorPattern.tenBridge);
      await controller.completeRemediation(
        ErrorPattern.tenBridge,
        checkCorrect: 2,
        checkTotal: 2,
      );

      const evidenceId = 'evidence:ten-bridge:1';
      Future<void> record(AppController value) => value.recordDiagnosticAttempt(
        mode: TrainingMode.minus,
        taskKey: 'remediation:tenBridge:-:13:5',
        expected: 8,
        actual: 8,
        evidenceId: evidenceId,
      );

      await record(controller);
      final microCount = controller.microObservations
          .where((entry) => entry.evidenceId == evidenceId)
          .length;
      expect(microCount, greaterThan(0));
      expect(
        controller.diagnostics.where((entry) => entry.evidenceId == evidenceId),
        hasLength(1),
      );
      expect(
        controller
            .remediationProgressFor(ErrorPattern.tenBridge)!
            .stabilityCorrect,
        1,
      );

      await record(controller);
      expect(
        controller.microObservations
            .where((entry) => entry.evidenceId == evidenceId)
            .length,
        microCount,
      );
      expect(
        controller
            .remediationProgressFor(ErrorPattern.tenBridge)!
            .stabilityCorrect,
        1,
      );

      final reloaded = AppController();
      await reloaded.load();
      await record(reloaded);
      expect(
        reloaded.diagnostics.where((entry) => entry.evidenceId == evidenceId),
        hasLength(1),
      );
      expect(
        reloaded.microObservations
            .where((entry) => entry.evidenceId == evidenceId)
            .length,
        microCount,
      );
      expect(
        reloaded
            .remediationProgressFor(ErrorPattern.tenBridge)!
            .stabilityCorrect,
        1,
      );
    },
  );

  test('Teil-Schritt-Evidence-ID verhindert doppelte Mikro-Evidenz', () async {
    final controller = AppController();
    await controller.load();
    const evidenceId = 'evidence:step:1';

    Future<void> record() => controller.recordIndependentStepAttempt(
      mode: TrainingMode.practice,
      taskKey: 'plus:8:7',
      stepKey: 'bridgeAmount',
      competencyId: MicroCompetencyId.additionTenBridge,
      correct: true,
      usedHelp: false,
      helpLevel: 0,
      evidenceId: evidenceId,
    );

    await record();
    await record();
    expect(
      controller.microObservations.where(
        (entry) => entry.evidenceId == evidenceId,
      ),
      hasLength(1),
    );
  });

  test(
    'Pending-Erstantwort roundtript auch nach bereits gesicherter Evidenz',
    () {
      final now = DateTime(2026, 9, 17, 18);
      const exercise = StructuredExercise(
        mode: TrainingMode.money,
        prompt: '8 Euro minus 3 Euro?',
        answer: 5,
        hint: 'Es wird weniger.',
        key: 'money:transaction:8:3',
        maxAnswerValue: 10,
      );
      const pending = PendingFirstAttemptEvidence(
        id: 'pending:structured:1',
        taskKey: 'money:transaction:8:3',
        expected: 5,
        actual: 5,
        responseMs: 1400,
        usedHelp: false,
        helpLevel: 0,
        source: MicroEvidenceSource.practice,
      );
      final progress = CoreTrainingSessionProgress(
        kind: CoreTrainingKind.structured,
        mode: TrainingMode.money,
        targetTasks: 2,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        startedAt: now.subtract(const Duration(minutes: 1)),
        updatedAt: now,
        currentTask: encodeStructuredExercise(exercise),
        taskFirstAttemptRecorded: true,
        pendingFirstAttemptEvidence: pending,
      );

      final restored = CoreTrainingSessionProgress.fromJson(progress.toJson());
      expect(restored.pendingFirstAttemptEvidence?.actual, 5);
      expect(restored.taskFirstAttemptRecorded, isTrue);
      expect(restored.hasSaneState(now: now), isTrue);
    },
  );

  testWidgets('Struktur-Erstantwort wird nach Unterbrechung fertig verbucht', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    const exercise = StructuredExercise(
      mode: TrainingMode.money,
      prompt: '8 Euro minus 3 Euro?',
      answer: 5,
      hint: 'Es wird weniger.',
      key: 'money:resume-transaction:8:3',
      maxAnswerValue: 10,
    );
    final now = DateTime.now();
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.structured,
      mode: TrainingMode.money,
      targetTasks: 1,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now.subtract(const Duration(minutes: 1)),
      updatedAt: now,
      currentTask: encodeStructuredExercise(exercise),
      pendingFirstAttemptEvidence: const PendingFirstAttemptEvidence(
        id: 'pending:structured:resume',
        taskKey: 'money:resume-transaction:8:3',
        expected: 5,
        actual: 5,
        responseMs: 1200,
        usedHelp: false,
        helpLevel: 0,
        source: MicroEvidenceSource.practice,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.money,
          targetTasks: 1,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.history, hasLength(1));
    expect(controller.history.single.correctFirstTry, 1);
    expect(controller.coreTrainingSessionProgress, isNull);
    expect(
      controller.diagnostics.where(
        (entry) => entry.evidenceId == 'pending:structured:resume:diagnostic',
      ),
      hasLength(1),
    );
    expect(find.text('Runde geschafft!'), findsOneWidget);
  });

  testWidgets(
    'Curriculum-Erstantwort wird nach Unterbrechung fertig verbucht',
    (tester) async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.fourth;
      controller.numberRange = NumberRangeLevel.million;
      const exercise = CurriculumExercise(
        mode: TrainingMode.rounding,
        prompt: 'Runde 4387 auf Hunderter.',
        answer: 4400,
        hint: 'Schau auf die Zehnerstelle.',
        key: 'round:resume-transaction:4387:100',
        maxAnswerValue: 10000,
      );
      final now = DateTime.now();
      controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
        kind: CoreTrainingKind.curriculum,
        mode: TrainingMode.rounding,
        targetTasks: 1,
        gradeLevel: GradeLevel.fourth,
        numberRange: NumberRangeLevel.million,
        startedAt: now.subtract(const Duration(minutes: 1)),
        updatedAt: now,
        currentTask: encodeCurriculumExercise(exercise),
        pendingFirstAttemptEvidence: const PendingFirstAttemptEvidence(
          id: 'pending:curriculum:resume',
          taskKey: 'round:resume-transaction:4387:100',
          expected: 4400,
          actual: 4400,
          responseMs: 1700,
          usedHelp: false,
          helpLevel: 0,
          source: MicroEvidenceSource.practice,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CurriculumTrainingScreen(
            controller: controller,
            mode: TrainingMode.rounding,
            targetTasks: 1,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.history, hasLength(1));
      expect(controller.history.single.correctFirstTry, 1);
      expect(controller.coreTrainingSessionProgress, isNull);
      expect(
        controller.diagnostics.where(
          (entry) => entry.evidenceId == 'pending:curriculum:resume:diagnostic',
        ),
        hasLength(1),
      );
      expect(find.text('Runde geschafft!'), findsOneWidget);
    },
  );

  testWidgets(
    'Fact-Pending-Antwort stellt Diagnose und Antwort gemeinsam wieder her',
    (tester) async {
      final controller = AppController();
      await controller.load();
      final fact = controller.facts.firstWhere(
        (entry) => entry.key == 'plus:2:3',
      );
      final now = DateTime.now();
      const attemptId = 'pending:fact:evidence:1';
      controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: TrainingMode.practice,
        targetTasks: 2,
        gradeLevel: controller.gradeLevel,
        numberRange: controller.numberRange,
        startedAt: now.subtract(const Duration(minutes: 1)),
        updatedAt: now,
        currentTask: {'key': fact.key},
        factAttemptSequence: 1,
        pendingFactAttempt: PendingFactAttempt(
          id: attemptId,
          taskKey: fact.key,
          correct: false,
          actualAnswer: fact.result + 1,
          responseMs: 900,
          usedHelp: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TrainingScreen(
            controller: controller,
            mode: TrainingMode.practice,
            targetTasks: 2,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(fact.attempts, 1);
      expect(
        controller.coreTrainingSessionProgress?.taskFirstAttemptRecorded,
        isTrue,
      );
      expect(
        controller.coreTrainingSessionProgress?.pendingFactAttempt,
        isNull,
      );
      expect(
        controller.diagnostics.where(
          (entry) => entry.evidenceId == '$attemptId:diagnostic',
        ),
        hasLength(1),
      );
    },
  );
}
