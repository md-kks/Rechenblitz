import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
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

}
