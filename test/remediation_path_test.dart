import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/micro_competency.dart';
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

  test('detaillierte Rechenfehler erhalten ursachenspezifische Förderpfade', () {
    final generator = RemediationGenerator(random: Random(77));

    final carry = generator.generate(
      pattern: ErrorPattern.carryOmitted,
      preferredMode: TrainingMode.practice,
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      methods: const MethodPreferences(),
    );
    expect(
      carry.tasks.every(
        (task) => task.taskKey.startsWith('remediation:carryOmitted:+:'),
      ),
      isTrue,
    );
    for (final task in carry.tasks) {
      final numbers = RegExp(r'\d+')
          .allMatches(task.taskKey)
          .map((match) => int.parse(match.group(0)!))
          .toList();
      final a = numbers[numbers.length - 2];
      final b = numbers.last;
      expect((a % 10) + (b % 10), greaterThanOrEqualTo(10));
    }

    final borrow = generator.generate(
      pattern: ErrorPattern.borrowAvoided,
      preferredMode: TrainingMode.minus,
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      methods: const MethodPreferences(),
    );
    expect(
      borrow.tasks.every(
        (task) => task.taskKey.startsWith('remediation:borrowAvoided:-:'),
      ),
      isTrue,
    );

    final partial = generator.generate(
      pattern: ErrorPattern.partialOperand,
      preferredMode: TrainingMode.minus,
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      methods: const MethodPreferences(),
    );
    expect(
      partial.tasks.every(
        (task) => task.taskKey.startsWith('remediation:partialOperand:-:'),
      ),
      isTrue,
    );
    expect(partial.tasks.every((task) => task.hint.contains('Zerlege')), isTrue);
  });

  test('Mal- und Geteilt-Fehlvorstellungen bleiben bis zur Kontrolle erhalten',
      () {
    final generator = RemediationGenerator(random: Random(78));
    final multiplication = generator.generate(
      pattern: ErrorPattern.multiplicationAsAddition,
      preferredMode: TrainingMode.multiply,
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      methods: const MethodPreferences(),
    );
    expect(
      multiplication.tasks.every(
        (task) => task.taskKey
            .startsWith('remediation:multiplicationAsAddition:x:'),
      ),
      isTrue,
    );

    final division = generator.generate(
      pattern: ErrorPattern.divisionAsSubtraction,
      preferredMode: TrainingMode.divide,
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      methods: const MethodPreferences(),
    );
    expect(
      division.tasks.every(
        (task) => task.taskKey
            .startsWith('remediation:divisionAsSubtraction:divide:'),
      ),
      isTrue,
    );
  });

  test('Modellierungsfehler fördern genau den fehlenden Sachaufgaben-Schritt',
      () {
    const cases = [
      (
        pattern: ErrorPattern.wordProblemRelevantInformation,
        competency: MicroCompetencyId.wordProblemRelevantInformation,
        innerPrefix: 'story:info:',
      ),
      (
        pattern: ErrorPattern.wordProblemModel,
        competency: MicroCompetencyId.wordProblemModel,
        innerPrefix: 'story:equation:',
      ),
      (
        pattern: ErrorPattern.wordProblemInterpretation,
        competency: MicroCompetencyId.wordProblemInterpretation,
        innerPrefix: 'story:interpret:',
      ),
    ];

    for (final item in cases) {
      final plan = RemediationGenerator(
        random: Random(100 + item.pattern.index),
      ).generate(
        pattern: item.pattern,
        preferredMode: TrainingMode.wordProblems,
        grade: GradeLevel.second,
        range: NumberRangeLevel.hundred,
        methods: const MethodPreferences(),
      );

      for (final task in plan.tasks) {
        expect(
          task.taskKey,
          startsWith(
            'remediation:${item.pattern.name}:${item.innerPrefix}',
          ),
        );
        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: task.mode,
          taskKey: task.taskKey,
        );
        expect(tags.map((tag) => tag.id), contains(item.competency));
      }
    }
  });

  test('Rechenart-Förderung in Klasse 1 bleibt bei Plus und Minus', () {
    final plan = RemediationGenerator(random: Random(79)).generate(
      pattern: ErrorPattern.operationChoice,
      preferredMode: TrainingMode.wordProblems,
      grade: GradeLevel.first,
      range: NumberRangeLevel.twenty,
      methods: const MethodPreferences(),
    );

    for (final task in plan.tasks) {
      expect(task.choices, hasLength(2));
      expect(task.choices!.toSet(), {'Plus (+)', 'Minus (−)'});
      expect(task.answer, inInclusiveRange(0, 1));
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

  test('Darstellungsfehler erhält einen gezielten Förderpfad', () {
    final plan = RemediationGenerator(random: Random(404)).generate(
      pattern: ErrorPattern.representationTranslation,
      preferredMode: TrainingMode.wordProblems,
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      methods: const MethodPreferences(),
    );

    expect(plan.tasks, hasLength(8));
    for (final task in plan.tasks) {
      expect(
        task.taskKey,
        startsWith(
          'remediation:representationTranslation:process:representation:',
        ),
      );
      expect(task.choices, hasLength(4));
      final tags = MicroCompetencyCatalog.tagsForTask(
        mode: task.mode,
        taskKey: task.taskKey,
      );
      expect(
        tags.map((tag) => tag.id),
        contains(MicroCompetencyId.representationTranslation),
      );
    }
  });


  test('gezielter Rechenschritt-Pfad bleibt auf drei Aufgaben begrenzt', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.writtenMultiplyProcedure,
      stepKey: 'multiplicationCarry',
      label: 'Übertrag beim schriftlichen Multiplizieren bestimmen',
      mode: TrainingMode.writtenMultiply,
      lastSeen: DateTime(2026, 9, 5, 20),
      sourceTaskKey:
          'independent:multiplicationCarry:written:x:237:4',
    );
    final plan = StepRecoveryGenerator(random: Random(140)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );
    expect(
      plan.tasks.every(
        (task) =>
            task.taskKey.startsWith(
              'step-recovery:multiplicationCarry:',
            ) &&
            task.answer >= 0 &&
            task.answer <= task.maxAnswerValue,
      ),
      isTrue,
    );
  });

  test('ein frischer eigenständiger Teilfehler löst sofort Recovery aus', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    final now = DateTime(2026, 9, 5, 20);

    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.writtenMultiplyProcedure,
        occurredAt: now.subtract(const Duration(minutes: 5)),
        correct: false,
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.independentStep,
        usedHelp: false,
        mode: TrainingMode.writtenMultiply,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        taskKey:
            'independent:multiplicationCarry:written:x:237:4',
      ),
    ];

    final focus = controller.independentStepRecoveryFocus(now: now);
    expect(focus, isNotNull);
    expect(
      focus!.competencyId,
      MicroCompetencyId.writtenMultiplyProcedure,
    );
    expect(focus.stepKey, 'multiplicationCarry');
    expect(focus.label, contains('Übertrag'));
  });

  test('Recovery endet erst nach zwei passenden selbstständigen Bestätigungen',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    final now = DateTime(2026, 9, 5, 20);
    final failureAt = now.subtract(const Duration(minutes: 10));

    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.writtenMultiplyProcedure,
        occurredAt: failureAt.add(const Duration(minutes: 3)),
        correct: true,
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.independentStep,
        usedHelp: false,
        mode: TrainingMode.writtenMultiply,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        taskKey:
            'independent:multiplicationCarry:step-recovery:multiplicationCarry:one',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.writtenMultiplyProcedure,
        occurredAt: failureAt.add(const Duration(minutes: 2)),
        correct: true,
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.independentStep,
        usedHelp: true,
        helpLevel: 1,
        mode: TrainingMode.writtenMultiply,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        taskKey:
            'independent:multiplicationCarry:step-recovery:multiplicationCarry:supported',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.writtenMultiplyProcedure,
        occurredAt: failureAt,
        correct: false,
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.independentStep,
        usedHelp: false,
        mode: TrainingMode.writtenMultiply,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        taskKey:
            'independent:multiplicationCarry:written:x:237:4',
      ),
    ];

    expect(controller.independentStepRecoveryFocus(now: now), isNotNull);

    controller.microObservations.insert(
      0,
      MicroCompetencyObservation(
        id: MicroCompetencyId.writtenMultiplyProcedure,
        occurredAt: failureAt.add(const Duration(minutes: 4)),
        correct: true,
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.independentStep,
        usedHelp: false,
        mode: TrainingMode.writtenMultiply,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        taskKey:
            'independent:multiplicationCarry:step-recovery:multiplicationCarry:check',
      ),
    );

    expect(controller.independentStepRecoveryFocus(now: now), isNull);
  });

  test('Bestätigung eines anderen Teilschritts löst Recovery nicht ab', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    final now = DateTime(2026, 9, 5, 20);
    final failureAt = now.subtract(const Duration(minutes: 10));

    controller.microObservations = [
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.writtenMultiplyProcedure,
          occurredAt:
              failureAt.add(Duration(minutes: index + 1)),
          correct: true,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.writtenMultiply,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:firstPartialProduct:written:x:23:${index + 3}',
        ),
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.writtenMultiplyProcedure,
        occurredAt: failureAt,
        correct: false,
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.independentStep,
        usedHelp: false,
        mode: TrainingMode.writtenMultiply,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        taskKey:
            'independent:multiplicationCarry:written:x:237:4',
      ),
    ];

    final focus = controller.independentStepRecoveryFocus(now: now);
    expect(focus, isNotNull);
    expect(focus!.stepKey, 'multiplicationCarry');
  });

  test('Meine Runde kürzt den normalen Fokus bei akutem Teilfehler', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    final now = DateTime(2026, 9, 5, 20);
    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.writtenDivideProcedure,
        occurredAt: now.subtract(const Duration(minutes: 5)),
        correct: false,
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.independentStep,
        usedHelp: false,
        mode: TrainingMode.writtenDivide,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        taskKey:
            'independent:firstQuotientDigit:written:divide:324:6',
      ),
    ];

    final plan = controller.buildMyRound(now: now);

    expect(plan[1].tasks, 2);
    expect(
      plan[1].targetCompetency,
      MicroCompetencyId.writtenDivideProcedure,
    );
    expect(plan[1].reason, contains('erste Quotientenziffer'));
    expect(
      plan.fold<int>(0, (sum, segment) => sum + segment.tasks),
      9,
    );
  });

  testWidgets('Meine Runde priorisiert den exakten Teilfehler vor Knacknüssen',
      (tester) async {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.writtenMultiplyProcedure,
        occurredAt: DateTime.now(),
        correct: false,
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.independentStep,
        usedHelp: false,
        mode: TrainingMode.writtenMultiply,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        taskKey:
            'independent:multiplicationCarry:written:x:237:4',
      ),
    ];
    controller.diagnostics = [
      DiagnosticAttempt(
        occurredAt: DateTime.now(),
        mode: TrainingMode.minus,
        taskKey: 'minus:13:5',
        expected: 8,
        actual: 9,
        correct: false,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        pattern: ErrorPattern.tenBridge,
      ),
      DiagnosticAttempt(
        occurredAt: DateTime.now().subtract(
          const Duration(minutes: 1),
        ),
        mode: TrainingMode.minus,
        taskKey: 'minus:12:4',
        expected: 8,
        actual: 9,
        correct: false,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        pattern: ErrorPattern.tenBridge,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: MyRoundScreen(controller: controller)),
    );

    expect(find.text('Rechenschritt kurz festigen'), findsOneWidget);
    expect(
      find.textContaining('Übertrag beim schriftlichen Multiplizieren'),
      findsWidgets,
    );
    expect(find.byKey(const ValueKey('remediation-button')), findsNothing);

    final button = find.byKey(const ValueKey('step-recovery-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Rechenschritt festigen'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(
      find.text('Übertrag beim schriftlichen Multiplizieren bestimmen'),
      findsOneWidget,
    );
  });


  test('gezielte Recovery respektiert auch Zahlenraum 20', () {
    final focuses = [
      IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.writtenAlignment,
        stepKey: 'onesAlignment',
        label: 'Einer in der richtigen Spalte ausrichten',
        mode: TrainingMode.writtenAddSub,
        lastSeen: DateTime(2026, 9, 5, 20),
        sourceTaskKey: 'independent:onesAlignment:written:+:17:3',
      ),
      IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.writtenRegrouping,
        stepKey: 'carryDecision',
        label: 'notwendigen Übertrag erkennen',
        mode: TrainingMode.writtenAddSub,
        lastSeen: DateTime(2026, 9, 5, 20),
        sourceTaskKey: 'independent:carryDecision:written:+:12:8',
      ),
      IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.writtenMultiplyProcedure,
        stepKey: 'firstPartialProduct',
        label: 'erstes Teilprodukt berechnen',
        mode: TrainingMode.writtenMultiply,
        lastSeen: DateTime(2026, 9, 5, 20),
        sourceTaskKey: 'independent:firstPartialProduct:written:x:12:1',
      ),
      IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.writtenDivideProcedure,
        stepKey: 'firstQuotientDigit',
        label: 'erste Quotientenziffer bestimmen',
        mode: TrainingMode.writtenDivide,
        lastSeen: DateTime(2026, 9, 5, 20),
        sourceTaskKey: 'independent:firstQuotientDigit:written:divide:18:3',
      ),
    ];

    for (var i = 0; i < focuses.length; i++) {
      final plan = StepRecoveryGenerator(random: Random(500 + i)).generate(
        focus: focuses[i],
        range: NumberRangeLevel.twenty,
      );
      for (final task in plan.tasks.where((task) => !task.usesChoices)) {
        expect(task.answer, lessThanOrEqualTo(20));
        expect(task.maxAnswerValue, lessThanOrEqualTo(20));
      }
    }
  });


  test('Einmaleins-Recovery bleibt bei Teilprodukten und Ankern im Kopfrechnen',
      () {
    final generator = StepRecoveryGenerator(random: Random(610));
    const cases = [
      (key: 'firstPartialProduct', expectedText: 'Zerlege'),
      (key: 'secondPartialProduct', expectedText: 'Zerlege'),
      (key: 'anchorFact', expectedText: 'Anker'),
    ];

    for (final item in cases) {
      final focus = IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.multiplicationFacts,
        stepKey: item.key,
        label: GuidedStepCatalog.labelFor(item.key),
        mode: TrainingMode.multiply,
        lastSeen: DateTime(2026, 9, 6, 20),
        sourceTaskKey: 'independent:${item.key}:multiply:7:6',
      );
      final plan = generator.generate(
        focus: focus,
        range: NumberRangeLevel.hundred,
      );

      expect(plan.tasks, hasLength(3), reason: item.key);
      expect(
        plan.tasks.every(
          (task) =>
              task.mode == TrainingMode.multiply &&
              task.prompt.contains(item.expectedText) &&
              !task.prompt.contains('schriftlich') &&
              task.answer >= 0 &&
              task.answer <= task.maxAnswerValue,
        ),
        isTrue,
        reason: item.key,
      );
    }
  });

  test('gleichnamiges Teilprodukt bleibt bei schriftlichem Mal schriftlich', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.writtenMultiplyProcedure,
      stepKey: 'firstPartialProduct',
      label: GuidedStepCatalog.labelFor('firstPartialProduct'),
      mode: TrainingMode.writtenMultiply,
      lastSeen: DateTime(2026, 9, 6, 20),
      sourceTaskKey: 'independent:firstPartialProduct:written:x:237:4',
    );
    final plan = StepRecoveryGenerator(random: Random(611)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    expect(
      plan.tasks.every((task) => task.prompt.contains('schriftlich')),
      isTrue,
    );
  });


  test('Sachaufgaben-Modellierung hat fünf getrennte Recovery-Pfade', () {
    final generator = StepRecoveryGenerator(random: Random(630));
    const cases = [
      (
        competency: MicroCompetencyId.wordProblemRelevantInformation,
        key: 'storyInfo',
        source: 'story:info:trip:5:2:3',
      ),
      (
        competency: MicroCompetencyId.wordProblemOperation,
        key: 'storyOperation',
        source: 'story:operation:divide:18:3',
      ),
      (
        competency: MicroCompetencyId.wordProblemModel,
        key: 'storyEquation',
        source: 'story:equation:x:4:5',
      ),
      (
        competency: MicroCompetencyId.wordProblemCalculation,
        key: 'storyCalculation',
        source: 'story:calc:-:18:7',
      ),
      (
        competency: MicroCompetencyId.wordProblemInterpretation,
        key: 'storyInterpretation',
        source: 'story:interpret:+:8:6:14',
      ),
    ];

    for (final item in cases) {
      final focus = IndependentStepRecoveryFocus(
        competencyId: item.competency,
        stepKey: item.key,
        label: GuidedStepCatalog.labelFor(item.key),
        mode: TrainingMode.wordProblems,
        lastSeen: DateTime(2026, 9, 6, 0, 30),
        sourceTaskKey: 'independent:${item.key}:${item.source}',
      );
      final plan = generator.generate(
        focus: focus,
        range: NumberRangeLevel.twenty,
      );

      expect(plan.tasks, hasLength(3), reason: item.key);
      expect(
        plan.tasks.map((task) => task.stage),
        [
          RemediationStage.supported,
          RemediationStage.transfer,
          RemediationStage.check,
        ],
        reason: item.key,
      );
      expect(
        plan.tasks.every(
          (task) =>
              task.mode == TrainingMode.wordProblems &&
              task.taskKey.startsWith('step-recovery:${item.key}:') &&
              task.answer >= 0 &&
              task.answer <= task.maxAnswerValue,
        ),
        isTrue,
        reason: item.key,
      );
      for (final task in plan.tasks.where((task) => !task.usesChoices)) {
        expect(task.answer, lessThanOrEqualTo(20), reason: item.key);
        expect(task.maxAnswerValue, lessThanOrEqualTo(20), reason: item.key);
      }
    }
  });

  test('frischer Sachaufgaben-Teilfehler löst exakte Recovery aus', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.twenty;
    final now = DateTime(2026, 9, 6, 0, 35);
    controller.microObservations = [
      MicroCompetencyObservation(
        id: MicroCompetencyId.wordProblemOperation,
        occurredAt: now.subtract(const Duration(minutes: 5)),
        correct: false,
        evidenceWeight: 0.35,
        source: MicroEvidenceSource.independentStep,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.first,
        numberRange: NumberRangeLevel.twenty,
        taskKey:
            'independent:storyOperation:story:operation:-:12:4',
      ),
    ];

    final focus = controller.independentStepRecoveryFocus(now: now);

    expect(focus, isNotNull);
    expect(focus!.competencyId, MicroCompetencyId.wordProblemOperation);
    expect(focus.stepKey, 'storyOperation');
    expect(focus.label, contains('Rechenart'));
  });


  test('Folgen-Recovery wechselt die Richtung bei gleicher Schrittweite', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.numberPatterns,
      stepKey: 'sequenceStepSize',
      label: GuidedStepCatalog.labelFor('sequenceStepSize'),
      mode: TrainingMode.sequences,
      lastSeen: DateTime(2026, 9, 6, 14),
      sourceTaskKey:
          'independent:sequenceStepSize:sequence:+:8:2',
    );
    final plan = StepRecoveryGenerator(random: Random(649)).generate(
      focus: focus,
      range: NumberRangeLevel.twenty,
    );

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );
    expect(plan.tasks[0].taskKey, contains(':sequence-rule:+:'));
    expect(plan.tasks[1].taskKey, contains(':sequence-rule:-:'));
    expect(
      plan.tasks[0].choices![plan.tasks[0].answer],
      'immer +2',
    );
    expect(
      plan.tasks[1].choices![plan.tasks[1].answer],
      'immer −2',
    );

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.sequences);
      expect(
        task.taskKey,
        startsWith('step-recovery:sequenceStepSize:sequence-rule:'),
      );
      expect(task.usesChoices, isTrue);
      expect(task.choices, hasLength(4));
      expect(task.choices!.toSet(), hasLength(4));
      expect(task.answer, inInclusiveRange(0, 3));
      expect(task.prompt, contains('Welche Regel'));
      expect(task.hint, contains('größer oder kleiner'));
    }
  });

  test('Uhr-Recovery festigt den Minutenwert des langen Zeigers', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.clockReading,
      stepKey: 'minuteHandMinutes',
      label: GuidedStepCatalog.labelFor('minuteHandMinutes'),
      mode: TrainingMode.clock,
      lastSeen: DateTime(2026, 9, 6, 13, 30),
      sourceTaskKey:
          'independent:minuteHandMinutes:clock:7:30',
    );
    final plan = StepRecoveryGenerator(random: Random(648)).generate(
      focus: focus,
      range: NumberRangeLevel.twenty,
    );

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );
    expect(plan.tasks[0].taskKey, contains(':minute-hand:6:30'));
    expect(plan.tasks[1].taskKey, contains(':minute-hand:12:0'));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.clock);
      expect(
        task.taskKey,
        startsWith('step-recovery:minuteHandMinutes:minute-hand:'),
      );
      expect(task.usesChoices, isTrue);
      expect(task.choices, ['0 Minuten', '30 Minuten']);
      expect(task.answer, inInclusiveRange(0, 1));
      expect(task.prompt, contains('lange Zeiger'));
      expect(task.hint, isNot(contains('15')));
      expect(task.hint, isNot(contains('45')));
    }

    expect(
      plan.tasks[0].choices![plan.tasks[0].answer],
      '30 Minuten',
    );
    expect(
      plan.tasks[1].choices![plan.tasks[1].answer],
      '0 Minuten',
    );
  });

  test('Rundungs-Recovery wechselt die entscheidende Rundungsstelle', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.roundingPlace,
      stepKey: 'roundingDecisionDigit',
      label: GuidedStepCatalog.labelFor('roundingDecisionDigit'),
      mode: TrainingMode.rounding,
      lastSeen: DateTime(2026, 9, 6, 13),
      sourceTaskKey:
          'independent:roundingDecisionDigit:round:467:100',
    );
    final plan = StepRecoveryGenerator(random: Random(647)).generate(
      focus: focus,
      range: NumberRangeLevel.million,
    );

    int place(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('rounding-decision');
      return int.parse(parts[index + 2]);
    }

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );
    expect(place(plan.tasks[0]), 100);
    expect(place(plan.tasks[1]), isNot(100));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.rounding);
      expect(
        task.taskKey,
        startsWith(
          'step-recovery:roundingDecisionDigit:rounding-decision:',
        ),
      );
      expect(task.usesChoices, isFalse);
      expect(task.answer, inInclusiveRange(1, 9));
      expect(task.maxAnswerValue, 9);
      expect(task.prompt, contains('Welche Ziffer entscheidet'));
      expect(task.hint, contains('eine Stelle nach rechts'));
    }
  });

  test('Sekunden-Recovery wechselt gezielt die Umrechnungsrichtung', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.secondsConversion,
      stepKey: 'minuteSecondRelation',
      label: GuidedStepCatalog.labelFor('minuteSecondRelation'),
      mode: TrainingMode.advancedMeasures,
      lastSeen: DateTime(2026, 9, 6, 12, 45),
      sourceTaskKey:
          'independent:minuteSecondRelation:time:seconds:min-to-sec:4',
    );
    final plan = StepRecoveryGenerator(random: Random(646)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );
    expect(plan.tasks[0].taskKey, contains(':min-to-sec'));
    expect(plan.tasks[1].taskKey, contains(':sec-to-min'));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.advancedMeasures);
      expect(
        task.taskKey,
        startsWith(
          'step-recovery:minuteSecondRelation:minute-second-relation:',
        ),
      );
      expect(task.usesChoices, isTrue);
      expect(task.answer, inInclusiveRange(0, task.choices!.length - 1));
      expect(
        task.choices![task.answer],
        '1 min = 60 s',
      );
      expect(task.prompt, contains('Welche Beziehung brauchst du'));
      expect(task.hint, contains('volle Minute'));
    }
  });

  test('Einheiten-Recovery festigt zuerst die feste Beziehung', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.unitConversion,
      stepKey: 'unitRelation',
      label: GuidedStepCatalog.labelFor('unitRelation'),
      mode: TrainingMode.advancedMeasures,
      lastSeen: DateTime(2026, 9, 6, 12, 30),
      sourceTaskKey: 'independent:unitRelation:length:m:7',
    );
    final plan = StepRecoveryGenerator(random: Random(645)).generate(
      focus: focus,
      range: NumberRangeLevel.hundred,
    );

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );
    expect(plan.tasks[0].taskKey, contains(':unit-relation:m-cm'));
    expect(plan.tasks[1].taskKey, isNot(contains(':unit-relation:m-cm')));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.advancedMeasures);
      expect(
        task.taskKey,
        startsWith('step-recovery:unitRelation:unit-relation:'),
      );
      expect(task.usesChoices, isTrue);
      expect(task.answer, inInclusiveRange(0, task.choices!.length - 1));
      expect(task.prompt, contains('Welche Beziehung brauchst du'));
      expect(task.hint, contains('feste Beziehung'));
      expect(task.taskKey, isNot(contains('seconds')));
    }

    expect(
      plan.tasks[0].choices![plan.tasks[0].answer],
      '1 m = 100 cm',
    );
  });







  test('Fehlerstellen-Recovery wechselt gezielt die betroffene Stelle', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.errorChecking,
      stepKey: 'errorPlace',
      label: GuidedStepCatalog.labelFor('errorPlace'),
      mode: TrainingMode.writtenAddSub,
      lastSeen: DateTime(2026, 9, 6, 22, 5),
      sourceTaskKey:
          'independent:errorPlace:process:error:add:place:10:462:337:809',
    );
    final plan = StepRecoveryGenerator(random: Random(863)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    int place(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('error-place');
      return int.parse(parts[index + 1]);
    }

    expect(plan.tasks.map((task) => task.stage), [
      RemediationStage.supported,
      RemediationStage.transfer,
      RemediationStage.check,
    ]);
    expect(place(plan.tasks[0]), 10);
    expect(place(plan.tasks[1]), isNot(10));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.writtenAddSub);
      expect(
        task.taskKey,
        startsWith('step-recovery:errorPlace:error-place:'),
      );
      expect(task.usesChoices, isTrue);
      expect(task.prompt, contains('Welche Stelle'));
      expect(task.answer, inInclusiveRange(0, task.choices!.length - 1));
    }
  });

  test('Plausibilitäts-Recovery festigt den Referenz-Überschlag', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.plausibilityCheck,
      stepKey: 'referenceEstimate',
      label: GuidedStepCatalog.labelFor('referenceEstimate'),
      mode: TrainingMode.estimation,
      lastSeen: DateTime(2026, 9, 6, 21, 45),
      sourceTaskKey:
          'independent:referenceEstimate:process:plausibility:462:337:1200:100',
    );
    final plan = StepRecoveryGenerator(random: Random(851)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    int place(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('plausibility-estimate');
      return int.parse(parts[index + 1]);
    }

    int expectedEstimate(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('plausibility-estimate');
      final p = int.parse(parts[index + 1]);
      final a = int.parse(parts[index + 2]);
      final b = int.parse(parts[index + 3]);
      int rounded(int value) => ((value + p ~/ 2) ~/ p) * p;
      return rounded(a) + rounded(b);
    }

    expect(plan.tasks.map((task) => task.stage), [
      RemediationStage.supported,
      RemediationStage.transfer,
      RemediationStage.check,
    ]);
    expect(place(plan.tasks[0]), 100);
    expect(place(plan.tasks[1]), isNot(100));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.estimation);
      expect(
        task.taskKey,
        startsWith(
          'step-recovery:referenceEstimate:plausibility-estimate:',
        ),
      );
      expect(task.usesChoices, isTrue);
      final chosen = int.parse(
        task.choices![task.answer].replaceAll('.', ''),
      );
      expect(chosen, expectedEstimate(task));
      expect(task.prompt, contains('Überschlag'));
      expect(task.hint, contains('gerundeten Werte'));
    }
  });

  test('Zahlwort-Recovery überträgt die Einer-Zehner-Zuordnung', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.numberWordReading,
      stepKey: 'numberWordTensOnes',
      label: GuidedStepCatalog.labelFor('numberWordTensOnes'),
      mode: TrainingMode.largeNumbers,
      lastSeen: DateTime(2026, 9, 6, 20, 45),
      sourceTaskKey:
          'independent:numberWordTensOnes:large:word:read:347',
    );
    final plan = StepRecoveryGenerator(random: Random(842)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    int suffix(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('number-word-tens-ones');
      return int.parse(parts[index + 1]);
    }

    expect(plan.tasks.map((task) => task.stage), [
      RemediationStage.supported,
      RemediationStage.transfer,
      RemediationStage.check,
    ]);
    expect(suffix(plan.tasks[0]), 47);
    expect(suffix(plan.tasks[1]), isNot(47));

    for (final task in plan.tasks) {
      final value = suffix(task);
      final tens = value ~/ 10;
      final ones = value % 10;
      expect(task.mode, TrainingMode.largeNumbers);
      expect(
        task.taskKey,
        startsWith(
          'step-recovery:numberWordTensOnes:number-word-tens-ones:',
        ),
      );
      expect(task.usesChoices, isTrue);
      expect(
        task.choices![task.answer],
        '$tens Zehner und $ones Einer',
      );
      expect(task.prompt, contains('Zuordnung'));
      expect(task.hint, contains('Einer vor dem Zehner'));
    }
  });



  test('Römische-Zahlen-Recovery überträgt Subtraktionspaare', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.romanNumeral,
      stepKey: 'romanSubtractivePair',
      label: GuidedStepCatalog.labelFor('romanSubtractivePair'),
      mode: TrainingMode.romanNumerals,
      lastSeen: DateTime(2026, 9, 6, 23, 30),
      sourceTaskKey:
          'independent:romanSubtractivePair:roman:read:47:40',
    );
    final plan = StepRecoveryGenerator(random: Random(852)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    int pair(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('roman-subtractive');
      return int.parse(parts[index + 1]);
    }

    expect(plan.tasks.map((task) => task.stage), [
      RemediationStage.supported,
      RemediationStage.transfer,
      RemediationStage.check,
    ]);
    expect(pair(plan.tasks[0]), 40);
    expect(pair(plan.tasks[1]), isNot(40));
    expect(pair(plan.tasks[1]), isNot(90));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.romanNumerals);
      expect(
        task.taskKey,
        startsWith(
          'step-recovery:romanSubtractivePair:roman-subtractive:',
        ),
      );
      expect(task.usesChoices, isTrue);
      expect(task.choices, hasLength(4));
      expect(task.prompt, contains('zusammengehöriges Paar'));
    }
  });

  test('Überschlag-Recovery überträgt das Runden der Summanden', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.estimation,
      stepKey: 'roundedSummands',
      label: GuidedStepCatalog.labelFor('roundedSummands'),
      mode: TrainingMode.estimation,
      lastSeen: DateTime(2026, 9, 6, 23, 10),
      sourceTaskKey:
          'independent:roundedSummands:estimate:672:245:100',
    );
    final plan = StepRecoveryGenerator(random: Random(842)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    int place(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('estimation-rounded');
      return int.parse(parts[index + 1]);
    }

    expect(plan.tasks.map((task) => task.stage), [
      RemediationStage.supported,
      RemediationStage.transfer,
      RemediationStage.check,
    ]);
    expect(place(plan.tasks[0]), 100);
    expect(place(plan.tasks[1]), isNot(100));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.estimation);
      expect(
        task.taskKey,
        startsWith(
          'step-recovery:roundedSummands:estimation-rounded:',
        ),
      );
      expect(task.usesChoices, isTrue);
      expect(task.choices, hasLength(4));
      expect(task.prompt, contains('Auf welche beiden Zahlen'));
      expect(task.hint, contains('jeden Summanden'));
    }
  });

  test('Zahlenordnungs-Recovery festigt zuerst die kleinste Zahl', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.largeNumberOrder,
      stepKey: 'smallestOrderedNumber',
      label: GuidedStepCatalog.labelFor('smallestOrderedNumber'),
      mode: TrainingMode.largeNumbers,
      lastSeen: DateTime(2026, 9, 6, 20, 30),
      sourceTaskKey:
          'independent:smallestOrderedNumber:large:order:418-481-814',
    );
    final plan = StepRecoveryGenerator(random: Random(831)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    int decidingPlace(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('large-smallest');
      return int.parse(parts[index + 1]);
    }

    expect(plan.tasks.map((task) => task.stage), [
      RemediationStage.supported,
      RemediationStage.transfer,
      RemediationStage.check,
    ]);
    expect(decidingPlace(plan.tasks[0]), 10);
    expect(decidingPlace(plan.tasks[1]), isNot(10));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.largeNumbers);
      expect(
        task.taskKey,
        startsWith(
          'step-recovery:smallestOrderedNumber:large-smallest:',
        ),
      );
      expect(task.usesChoices, isTrue);
      expect(task.choices, hasLength(3));
      final values = task.choices!
          .map((choice) => int.parse(choice.replaceAll('.', '')))
          .toList();
      expect(values[task.answer], values.reduce(min));
      expect(task.prompt, contains('kleinste'));
    }
  });

  test('Strategie-Recovery festigt die Ergänzung bis zur glatten Zielzahl',
      () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.strategyChoice,
      stepKey: 'gapToAnchor',
      label: GuidedStepCatalog.labelFor('gapToAnchor'),
      mode: TrainingMode.mentalStrategies,
      lastSeen: DateTime(2026, 9, 6, 23, 45),
      sourceTaskKey:
          'independent:gapToAnchor:process:strategy:Hunderter:672:45:700',
    );
    final plan = StepRecoveryGenerator(random: Random(822)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    int gap(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('strategy-gap');
      final a = int.parse(parts[index + 2]);
      final anchor = int.parse(parts[index + 4]);
      return anchor - a;
    }

    expect(plan.tasks.map((task) => task.stage), [
      RemediationStage.supported,
      RemediationStage.transfer,
      RemediationStage.check,
    ]);
    expect(gap(plan.tasks[0]), 28);
    expect(gap(plan.tasks[1]), isNot(28));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.mentalStrategies);
      expect(
        task.taskKey,
        startsWith('step-recovery:gapToAnchor:strategy-gap:Hunderter:'),
      );
      expect(task.usesChoices, isTrue);
      expect(task.answer, inInclusiveRange(0, task.choices!.length - 1));
      expect(int.parse(task.choices![task.answer]), gap(task));
      expect(task.hint, contains('glatten Zielzahl'));
    }
  });

  test('Stellenwert-Recovery überträgt den Ziffernwert auf eine andere Stelle',
      () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.placeValueDecompose,
      stepKey: 'placeValueContribution',
      label: GuidedStepCatalog.labelFor('placeValueContribution'),
      mode: TrainingMode.largeNumbers,
      lastSeen: DateTime(2026, 9, 6, 23, 30),
      sourceTaskKey:
          'independent:placeValueContribution:large:decompose:724:100',
    );
    final plan = StepRecoveryGenerator(random: Random(813)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    int place(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('place-value-contribution');
      return int.parse(parts[index + 1]);
    }

    expect(plan.tasks.map((task) => task.stage), [
      RemediationStage.supported,
      RemediationStage.transfer,
      RemediationStage.check,
    ]);
    expect(place(plan.tasks[0]), 100);
    expect(place(plan.tasks[1]), isNot(100));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.largeNumbers);
      expect(
        task.taskKey,
        startsWith(
          'step-recovery:placeValueContribution:place-value-contribution:',
        ),
      );
      expect(task.usesChoices, isTrue);
      expect(task.prompt, contains('Welchen Wert trägt sie'));
      expect(task.answer, inInclusiveRange(0, task.choices!.length - 1));
      expect(
        int.parse(task.choices![task.answer]),
        greaterThanOrEqualTo(20),
      );
    }
  });

  test('Zahlenvergleich-Recovery wechselt die entscheidende Stelle', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.largeNumberCompare,
      stepKey: 'decidingPlace',
      label: GuidedStepCatalog.labelFor('decidingPlace'),
      mode: TrainingMode.largeNumbers,
      lastSeen: DateTime(2026, 9, 6, 12),
      sourceTaskKey:
          'independent:decidingPlace:large:compare:722789:723383',
    );
    final plan = StepRecoveryGenerator(random: Random(644)).generate(
      focus: focus,
      range: NumberRangeLevel.million,
    );

    int decidingPlace(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('large-deciding-place');
      return int.parse(parts[index + 1]);
    }

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );
    expect(decidingPlace(plan.tasks[0]), 1000);
    expect(decidingPlace(plan.tasks[1]), isNot(1000));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.largeNumbers);
      expect(
        task.taskKey,
        startsWith('step-recovery:decidingPlace:large-deciding-place:'),
      );
      expect(task.usesChoices, isTrue);
      expect(task.choices, contains('Hunderttausenderstelle'));
      expect(task.choices, contains('Einerstelle'));
      expect(task.answer, inInclusiveRange(0, task.choices!.length - 1));
      expect(task.prompt, contains('Welche Stelle entscheidet'));
      expect(task.hint, contains('von links nach rechts'));
    }
  });

  test('Bruch-Recovery festigt die Größe eines gleich großen Teils', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.fractionEqualParts,
      stepKey: 'equalPartSize',
      label: GuidedStepCatalog.labelFor('equalPartSize'),
      mode: TrainingMode.fractions,
      lastSeen: DateTime(2026, 9, 6, 11),
      sourceTaskKey:
          'independent:equalPartSize:fraction:parts:3:4:20',
    );
    final plan = StepRecoveryGenerator(random: Random(643)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );

    int denominator(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('equal-part');
      return int.parse(parts[index + 2]);
    }

    expect(denominator(plan.tasks[0]), 4);
    expect(denominator(plan.tasks[1]), 2);
    expect(plan.tasks[0].taskKey, contains(':plaettchen:'));
    expect(plan.tasks[1].taskKey, contains(':band:'));

    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.fractions);
      expect(
        task.taskKey,
        startsWith('step-recovery:equalPartSize:equal-part:'),
      );
      expect(task.usesChoices, isFalse);
      expect(task.answer, greaterThanOrEqualTo(2));
      expect(task.answer, lessThanOrEqualTo(task.maxAnswerValue));
      expect(task.prompt, contains('1 Teil'));
      expect(task.hint, contains('gleich groß'));
    }
  });

  test('Zeitspannen-Recovery festigt den ersten Sprung bis zur vollen Stunde',
      () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.timeDuration,
      stepKey: 'minutesToNextHour',
      label: GuidedStepCatalog.labelFor('minutesToNextHour'),
      mode: TrainingMode.timeDurations,
      lastSeen: DateTime(2026, 9, 6, 10),
      sourceTaskKey:
          'independent:minutesToNextHour:duration:875:45',
    );
    final plan = StepRecoveryGenerator(random: Random(642)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );
    expect(plan.tasks[0].answer, 25);
    expect(plan.tasks[1].answer, isNot(25));
    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.timeDurations);
      expect(
        task.taskKey,
        startsWith('step-recovery:minutesToNextHour:time-first-jump:'),
      );
      expect(task.usesChoices, isFalse);
      expect(task.answer, inInclusiveRange(10, 50));
      expect(task.answer % 5, 0);
      expect(task.maxAnswerValue, 60);
      expect(task.prompt, contains('Wie viele Minuten'));
      expect(task.hint, contains('nächsten vollen Stunde'));
    }
  });

  test('Proportionalitäts-Recovery festigt zuerst den Einheitswert', () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.proportionalUnit,
      stepKey: 'unitValue',
      label: GuidedStepCatalog.labelFor('unitValue'),
      mode: TrainingMode.proportionality,
      lastSeen: DateTime(2026, 9, 6, 3),
      sourceTaskKey:
          'independent:unitValue:proportion:notebooks:3:4:7',
    );
    final plan = StepRecoveryGenerator(random: Random(641)).generate(
      focus: focus,
      range: NumberRangeLevel.thousand,
    );

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );
    expect(plan.tasks[0].taskKey, contains(':notebooks:'));
    expect(plan.tasks[1].taskKey, isNot(contains(':notebooks:')));
    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.proportionality);
      expect(task.taskKey, startsWith('step-recovery:unitValue:'));
      expect(task.usesChoices, isFalse);
      expect(task.answer, inInclusiveRange(2, 12));
      expect(task.maxAnswerValue, 12);
    }
  });

  test('Divisionsverständnis-Recovery wechselt von Verteilen zu Gruppieren',
      () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.divisionSharing,
      stepKey: 'divisionTargetQuantity',
      label: GuidedStepCatalog.labelFor('divisionTargetQuantity'),
      mode: TrainingMode.wordProblems,
      lastSeen: DateTime(2026, 9, 6, 1),
      sourceTaskKey:
          'independent:divisionTargetQuantity:story:sharing:children:12:3',
    );
    final plan = StepRecoveryGenerator(random: Random(640)).generate(
      focus: focus,
      range: NumberRangeLevel.twenty,
    );

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );
    expect(plan.tasks[0].taskKey, contains(':sharing:'));
    expect(plan.tasks[1].taskKey, contains(':grouping:'));
    for (final task in plan.tasks) {
      expect(task.mode, TrainingMode.wordProblems);
      expect(
        task.taskKey,
        startsWith('step-recovery:divisionTargetQuantity:'),
      );
      expect(task.usesChoices, isTrue);
      expect(task.choices, hasLength(3));
      expect(task.answer, isIn([0, 1]));
    }
  });

  test('Geteilt-Grundaufgaben-Recovery überträgt die Mal-Umkehraufgabe',
      () {
    final focus = IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.divisionFacts,
      stepKey: 'matchingMultiplicationFact',
      label: GuidedStepCatalog.labelFor('matchingMultiplicationFact'),
      mode: TrainingMode.divide,
      lastSeen: DateTime(2026, 9, 6, 15),
      sourceTaskKey:
          'independent:matchingMultiplicationFact:divide:42:6',
    );
    final plan = StepRecoveryGenerator(random: Random(650)).generate(
      focus: focus,
      range: NumberRangeLevel.hundred,
    );

    expect(plan.tasks, hasLength(3));
    expect(
      plan.tasks.map((task) => task.stage),
      [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ],
    );

    ({int dividend, int divisor}) values(RemediationTask task) {
      final parts = task.taskKey.split(':');
      final index = parts.indexOf('division-inverse');
      return (
        dividend: int.parse(parts[index + 1]),
        divisor: int.parse(parts[index + 2]),
      );
    }

    expect(values(plan.tasks[0]).divisor, 6);
    expect(values(plan.tasks[1]).divisor, isNot(6));

    for (final task in plan.tasks) {
      final pair = values(task);
      expect(task.mode, TrainingMode.divide);
      expect(
        task.taskKey,
        startsWith(
          'step-recovery:matchingMultiplicationFact:division-inverse:',
        ),
      );
      expect(task.usesChoices, isTrue);
      expect(task.choices, hasLength(4));
      expect(task.choices!.toSet(), hasLength(4));
      expect(task.choices!.every((choice) => choice.contains('?')), isTrue);
      expect(
        task.choices![task.answer],
        '${pair.divisor} × ? = ${pair.dividend}',
      );
      expect(task.prompt, contains('Mal-Umkehraufgabe'));
      expect(task.hint, contains('Teiler'));
    }
  });


  test('Umkehroperations-Recovery wechselt innerhalb derselben Operationsfamilie',
      () {
    const cases = [
      (
        source: 'independent:inverseOperationChoice:family:+:7:5',
        supported: '−5',
        transfer: '+5',
        family: 'plus-minus',
      ),
      (
        source: 'independent:inverseOperationChoice:family:x:6:4',
        supported: '÷4',
        transfer: '×4',
        family: 'multiply-divide',
      ),
    ];

    for (var i = 0; i < cases.length; i++) {
      final item = cases[i];
      final focus = IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.inverseRelationship,
        stepKey: 'inverseOperationChoice',
        label: GuidedStepCatalog.labelFor('inverseOperationChoice'),
        mode: TrainingMode.factFamilies,
        lastSeen: DateTime(2026, 9, 6, 16 + i),
        sourceTaskKey: item.source,
      );
      final plan = StepRecoveryGenerator(random: Random(660 + i)).generate(
        focus: focus,
        range: NumberRangeLevel.hundred,
      );

      expect(plan.tasks, hasLength(3));
      expect(
        plan.tasks.map((task) => task.stage),
        [
          RemediationStage.supported,
          RemediationStage.transfer,
          RemediationStage.check,
        ],
      );
      expect(
        plan.tasks[0].choices![plan.tasks[0].answer],
        item.supported,
      );
      expect(
        plan.tasks[1].choices![plan.tasks[1].answer],
        item.transfer,
      );

      for (final task in plan.tasks) {
        expect(task.mode, TrainingMode.factFamilies);
        expect(
          task.taskKey,
          startsWith(
            'step-recovery:inverseOperationChoice:inverse-operation:${item.family}:',
          ),
        );
        expect(task.usesChoices, isTrue);
        expect(task.choices, hasLength(2));
        expect(task.choices!.toSet(), hasLength(2));
        expect(task.prompt, contains('wieder rückgängig'));
      }
    }
  });


  test('Geld-Rechenplan-Recovery wechselt zwischen Gesamtpreis und Restgeld',
      () {
    const cases = [
      (
        source: 'money:add:school:7:5',
        supported: 'Plus (+)',
        transfer: 'Minus (−)',
      ),
      (
        source: 'money:change:kiosk:12:5',
        supported: 'Minus (−)',
        transfer: 'Plus (+)',
      ),
    ];

    for (var i = 0; i < cases.length; i++) {
      final item = cases[i];
      final focus = IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.moneyCalculation,
        stepKey: 'moneyOperationChoice',
        label: GuidedStepCatalog.labelFor('moneyOperationChoice'),
        mode: TrainingMode.money,
        lastSeen: DateTime(2026, 9, 6, 18 + i),
        sourceTaskKey: item.source,
      );
      final plan = StepRecoveryGenerator(random: Random(680 + i)).generate(
        focus: focus,
        range: NumberRangeLevel.twenty,
      );

      expect(plan.tasks, hasLength(3));
      expect(
        plan.tasks.map((task) => task.stage),
        [
          RemediationStage.supported,
          RemediationStage.transfer,
          RemediationStage.check,
        ],
      );
      expect(
        plan.tasks[0].choices![plan.tasks[0].answer],
        item.supported,
      );
      expect(
        plan.tasks[1].choices![plan.tasks[1].answer],
        item.transfer,
      );

      for (final task in plan.tasks) {
        expect(task.mode, TrainingMode.money);
        expect(
          task.taskKey,
          startsWith('step-recovery:moneyOperationChoice:money-plan:'),
        );
        expect(task.usesChoices, isTrue);
        expect(task.choices, hasLength(2));
        expect(task.choices!.toSet(), {'Plus (+)', 'Minus (−)'});
        expect(task.prompt, contains('€'));
        expect(task.hint, contains('Geldbeträge'));
      }
    }
  });


  test('Zahlenmauer-Recovery wechselt zwischen Aufbau und Rückwärtsrechnen',
      () {
    const cases = [
      (
        source: 'wall:2-3-1-5-4-9:4',
        supported: 'Plus (+)',
        transfer: 'Minus (−)',
      ),
      (
        source: 'wall:2-3-1-5-4-9:0',
        supported: 'Minus (−)',
        transfer: 'Plus (+)',
      ),
    ];

    for (var i = 0; i < cases.length; i++) {
      final item = cases[i];
      final focus = IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.numberRelations,
        stepKey: 'wallOperationChoice',
        label: GuidedStepCatalog.labelFor('wallOperationChoice'),
        mode: TrainingMode.numberWall,
        lastSeen: DateTime(2026, 9, 6, 20 + i),
        sourceTaskKey: item.source,
      );
      final plan = StepRecoveryGenerator(random: Random(690 + i)).generate(
        focus: focus,
        range: NumberRangeLevel.twenty,
      );

      expect(plan.tasks, hasLength(3));
      expect(
        plan.tasks.map((task) => task.stage),
        [
          RemediationStage.supported,
          RemediationStage.transfer,
          RemediationStage.check,
        ],
      );
      expect(
        plan.tasks[0].choices![plan.tasks[0].answer],
        item.supported,
      );
      expect(
        plan.tasks[1].choices![plan.tasks[1].answer],
        item.transfer,
      );

      for (final task in plan.tasks) {
        expect(task.mode, TrainingMode.numberWall);
        expect(
          task.taskKey,
          startsWith('step-recovery:wallOperationChoice:wall-direction:'),
        );
        expect(task.usesChoices, isTrue);
        expect(task.choices!.toSet(), {'Plus (+)', 'Minus (−)'});
        expect(task.prompt, contains('Zahlenmauer'));
      }
    }
  });


  test('Längen-Recovery wechselt zwischen Zusammenfügen und Wegnehmen', () {
    const cases = [
      (
        source: 'measure:add:ribbon:7:5',
        supported: 'Plus (+)',
        transfer: 'Minus (−)',
      ),
      (
        source: 'measure:subtract:rope:12:5',
        supported: 'Minus (−)',
        transfer: 'Plus (+)',
      ),
    ];

    for (var i = 0; i < cases.length; i++) {
      final item = cases[i];
      final focus = IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.measurementCalculation,
        stepKey: 'measureOperationChoice',
        label: GuidedStepCatalog.labelFor('measureOperationChoice'),
        mode: TrainingMode.measures,
        lastSeen: DateTime(2026, 9, 6, 22 + i),
        sourceTaskKey: item.source,
      );
      final plan = StepRecoveryGenerator(random: Random(700 + i)).generate(
        focus: focus,
        range: NumberRangeLevel.twenty,
      );

      expect(plan.tasks, hasLength(3));
      expect(
        plan.tasks.map((task) => task.stage),
        [
          RemediationStage.supported,
          RemediationStage.transfer,
          RemediationStage.check,
        ],
      );
      expect(
        plan.tasks[0].choices![plan.tasks[0].answer],
        item.supported,
      );
      expect(
        plan.tasks[1].choices![plan.tasks[1].answer],
        item.transfer,
      );

      for (final task in plan.tasks) {
        expect(task.mode, TrainingMode.measures);
        expect(
          task.taskKey,
          startsWith(
            'step-recovery:measureOperationChoice:measurement-plan:',
          ),
        );
        expect(task.usesChoices, isTrue);
        expect(task.choices!.toSet(), {'Plus (+)', 'Minus (−)'});
        expect(task.prompt, contains('cm'));
        expect(task.hint, contains('Längen'));
      }
    }
  });


  test('Doppeln-Halbieren-Recovery überträgt zwischen beiden Beziehungen', () {
    const cases = [
      (
        source: 'double:7',
        supported: 'zweimal dieselbe Menge zusammen',
        transfer: 'in zwei gleich große Teile teilen',
      ),
      (
        source: 'half:14',
        supported: 'in zwei gleich große Teile teilen',
        transfer: 'zweimal dieselbe Menge zusammen',
      ),
    ];

    for (var i = 0; i < cases.length; i++) {
      final item = cases[i];
      final focus = IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.doublesHalves,
        stepKey: 'doubleHalfMeaning',
        label: GuidedStepCatalog.labelFor('doubleHalfMeaning'),
        mode: TrainingMode.doublesHalves,
        lastSeen: DateTime(2026, 9, 6, 23, i),
        sourceTaskKey: item.source,
      );
      final plan = StepRecoveryGenerator(random: Random(710 + i)).generate(
        focus: focus,
        range: NumberRangeLevel.twenty,
      );

      expect(plan.tasks.map((task) => task.stage), [
        RemediationStage.supported,
        RemediationStage.transfer,
        RemediationStage.check,
      ]);
      expect(plan.tasks[0].choices![plan.tasks[0].answer], item.supported);
      expect(plan.tasks[1].choices![plan.tasks[1].answer], item.transfer);

      for (final task in plan.tasks) {
        expect(task.mode, TrainingMode.doublesHalves);
        expect(
          task.taskKey,
          startsWith(
            'step-recovery:doubleHalfMeaning:double-half-meaning:',
          ),
        );
        expect(task.choices!.toSet(), {
          'zweimal dieselbe Menge zusammen',
          'in zwei gleich große Teile teilen',
        });
      }
    }
  });


}
