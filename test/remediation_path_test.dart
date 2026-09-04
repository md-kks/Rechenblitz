import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/screens/my_round_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Förderpfad hat vier Stufen mit je zwei Aufgaben', () {
    final plan = RemediationGenerator(random: Random(42)).generate(
      pattern: ErrorPattern.tenBridge,
      preferredMode: TrainingMode.minus,
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      methods: const MethodPreferences(),
    );

    expect(plan.tasks, hasLength(8));
    for (final stage in RemediationStage.values) {
      expect(
        plan.tasks.where((task) => task.stage == stage),
        hasLength(2),
      );
    }
    expect(plan.tasks.every((task) => task.answer >= 0), isTrue);
  });

  test('Kontrollrunde enthält nur zwei Kontrollaufgaben', () {
    final plan = RemediationGenerator(random: Random(12)).generate(
      pattern: ErrorPattern.multiplicationFact,
      preferredMode: TrainingMode.multiply,
      grade: GradeLevel.third,
      range: NumberRangeLevel.thousand,
      methods: const MethodPreferences(),
      reviewOnly: true,
    );

    expect(plan.tasks, hasLength(2));
    expect(
      plan.tasks.every((task) => task.stage == RemediationStage.check),
      isTrue,
    );
  });

  test('Förderpfade respektieren kleinen Förder-Zahlenraum', () {
    for (final pattern in [
      ErrorPattern.tenBridge,
      ErrorPattern.placeValue,
      ErrorPattern.writtenRegrouping,
      ErrorPattern.roundingPlace,
    ]) {
      final plan = RemediationGenerator(random: Random(pattern.index + 7))
          .generate(
        pattern: pattern,
        preferredMode: pattern == ErrorPattern.writtenRegrouping
            ? TrainingMode.writtenAddSub
            : TrainingMode.minus,
        grade: GradeLevel.third,
        range: NumberRangeLevel.twenty,
        methods: const MethodPreferences(),
      );

      for (final task in plan.tasks.where((task) => !task.usesChoices)) {
        expect(
          task.answer,
          lessThanOrEqualTo(task.maxAnswerValue),
          reason: pattern.name,
        );
        expect(
          task.maxAnswerValue,
          lessThanOrEqualTo(20),
          reason: pattern.name,
        );
      }
    }
  });

  test('erfolgreicher Förderpfad setzt Muster auf verbessert', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    await controller.startRemediation(ErrorPattern.tenBridge);
    expect(
      controller.remediationProgressFor(ErrorPattern.tenBridge)!.status,
      RemediationStatus.inProgress,
    );

    final result = await controller.completeRemediation(
      ErrorPattern.tenBridge,
      checkCorrect: 2,
      checkTotal: 2,
    );

    expect(result.status, RemediationStatus.improved);
    expect(result.nextReviewAt, isNotNull);
    expect(controller.stars, 0);
  });

  test('drei sichere Folgebeobachtungen machen Verbesserung stabil', () async {
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

    for (var i = 0; i < 3; i++) {
      await controller.recordDiagnosticAttempt(
        mode: TrainingMode.minus,
        taskKey: 'remediation:tenBridge:-:13:5',
        expected: 8,
        actual: 8,
      );
    }

    final progress =
        controller.remediationProgressFor(ErrorPattern.tenBridge)!;
    expect(progress.status, RemediationStatus.stable);
    expect(progress.stabilityCorrect, 3);
    expect(controller.unlockedBadges, contains('weak_spot'));
  });

  test('erneuter gleicher Fehler nach Stabilität setzt Muster zurück', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    controller.remediationProgress = [
      RemediationProgress(
        pattern: ErrorPattern.tenBridge,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        status: RemediationStatus.stable,
        startedAt: DateTime(2026, 9, 1),
        completedAt: DateTime(2026, 9, 2),
        stabilityCorrect: 3,
      ),
    ];

    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: 'remediation:tenBridge:-:13:5',
      expected: 8,
      actual: 9,
    );

    expect(
      controller.remediationProgressFor(ErrorPattern.tenBridge)!.status,
      RemediationStatus.recurring,
    );
  });

  test('unsichere Kontrolle hält Muster wiederkehrend', () async {
    final controller = AppController();
    await controller.load();

    await controller.startRemediation(ErrorPattern.numberBond);
    final result = await controller.completeRemediation(
      ErrorPattern.numberBond,
      checkCorrect: 1,
      checkTotal: 2,
    );

    expect(result.status, RemediationStatus.recurring);
    expect(result.nextReviewAt, isNull);
  });

  test('verbessertes Muster wird nach drei Tagen zur Kontroll-Kandidatin', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final now = DateTime(2026, 9, 10);

    controller.diagnostics = [
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 9, 4),
        mode: TrainingMode.minus,
        taskKey: 'minus:13:5',
        expected: 8,
        actual: 9,
        correct: false,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.tenBridge,
      ),
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 9, 3),
        mode: TrainingMode.minus,
        taskKey: 'minus:12:4',
        expected: 8,
        actual: 9,
        correct: false,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.tenBridge,
      ),
    ];
    controller.remediationProgress = [
      RemediationProgress(
        pattern: ErrorPattern.tenBridge,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        status: RemediationStatus.improved,
        startedAt: DateTime(2026, 9, 5),
        completedAt: DateTime(2026, 9, 5),
        nextReviewAt: DateTime(2026, 9, 8),
      ),
    ];

    final candidate = controller.remediationCandidate(now: now);
    expect(candidate, isNotNull);
    expect(candidate!.pattern, ErrorPattern.tenBridge);
    expect(
      controller.remediationReviewOnly(
        ErrorPattern.tenBridge,
        now: now,
      ),
      isTrue,
    );
  });

  testWidgets('Meine Runde bietet wiederkehrende Knacknuss direkt an',
      (tester) async {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.diagnostics = [
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 9, 4, 20, 2),
        mode: TrainingMode.minus,
        taskKey: 'minus:13:5',
        expected: 8,
        actual: 9,
        correct: false,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.tenBridge,
      ),
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 9, 4, 20),
        mode: TrainingMode.minus,
        taskKey: 'minus:12:4',
        expected: 8,
        actual: 9,
        correct: false,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.tenBridge,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: MyRoundScreen(controller: controller)),
    );

    expect(find.text('Knacknuss zuerst'), findsOneWidget);
    final button = find.byKey(const ValueKey('remediation-button'));
    expect(button, findsOneWidget);

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Förderpfad'), findsOneWidget);
    expect(find.text('Mit Hilfe'), findsOneWidget);
    expect(find.text('Zehnerübergang'), findsOneWidget);
  });


  test('abgebrochene Kontrollrunde bleibt eine kurze Kontrolle', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.remediationProgress = [
      RemediationProgress(
        pattern: ErrorPattern.tenBridge,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        status: RemediationStatus.improved,
        startedAt: DateTime(2026, 9, 1),
        completedAt: DateTime(2026, 9, 2),
        nextReviewAt: DateTime(2026, 9, 3),
      ),
    ];

    await controller.startRemediation(
      ErrorPattern.tenBridge,
      reviewOnly: true,
    );

    expect(
      controller.remediationProgressFor(ErrorPattern.tenBridge)!.status,
      RemediationStatus.improved,
    );
    expect(
      controller.remediationReviewOnly(
        ErrorPattern.tenBridge,
        now: DateTime(2026, 9, 4),
      ),
      isTrue,
    );
  });

}
