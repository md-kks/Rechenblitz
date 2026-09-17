import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/support_session_progress.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/remediation_screen.dart';
import 'package:rechenblitz/screens/step_recovery_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:rechenblitz/widgets/number_answer_pad.dart';
import 'package:rechenblitz/widgets/touch_answer_interaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const remediationTasks = <RemediationTask>[
    RemediationTask(
      stage: RemediationStage.guided,
      mode: TrainingMode.symmetry,
      taskKey: 'remediation:symmetry:symmetry:Quadrat',
      prompt: 'Wie viele Symmetrieachsen hat ein Quadrat?',
      answer: 4,
      maxAnswerValue: 6,
      hint: 'Prüfe die möglichen Faltlinien.',
      targetCompetency: MicroCompetencyId.symmetryAxes,
    ),
    RemediationTask(
      stage: RemediationStage.supported,
      mode: TrainingMode.symmetry,
      taskKey: 'remediation:symmetry:symmetry:Rechteck',
      prompt: 'Wie viele Symmetrieachsen hat ein Rechteck?',
      answer: 2,
      maxAnswerValue: 6,
      hint: 'Prüfe senkrecht und waagerecht.',
      targetCompetency: MicroCompetencyId.symmetryAxes,
    ),
  ];

  final focus = IndependentStepRecoveryFocus(
    competencyId: MicroCompetencyId.additionTenBridge,
    stepKey: 'bridgeAmount',
    label: 'Bis zum nächsten Zehner ergänzen',
    mode: TrainingMode.practice,
    lastSeen: DateTime(2026, 9, 17, 8),
    sourceTaskKey: 'practice:+:8:5',
  );

  final stepTasks = <RemediationTask>[
    const RemediationTask(
      stage: RemediationStage.supported,
      mode: TrainingMode.practice,
      taskKey: 'step-recovery:bridgeAmount:first',
      prompt: 'Wie viel fehlt von 8 bis 10?',
      answer: 2,
      maxAnswerValue: 10,
      hint: 'Ergänze zuerst bis 10.',
    ),
    const RemediationTask(
      stage: RemediationStage.transfer,
      mode: TrainingMode.practice,
      taskKey: 'step-recovery:bridgeAmount:second',
      prompt: 'Wie viel fehlt von 7 bis 10?',
      answer: 3,
      maxAnswerValue: 10,
      hint: 'Denke an den Abstand bis 10.',
    ),
    const RemediationTask(
      stage: RemediationStage.check,
      mode: TrainingMode.practice,
      taskKey: 'step-recovery:bridgeAmount:check',
      prompt: 'Wie viel fehlt von 6 bis 10?',
      answer: 4,
      maxAnswerValue: 10,
      hint: 'Prüfe den Zehnerabstand.',
    ),
  ];

  test('Fördersitzung round-tript Aufgaben und Fortschritt verlustfrei', () {
    final progress = RemediationSessionProgress(
      pattern: ErrorPattern.symmetry,
      mode: TrainingMode.symmetry,
      gradeLevel: GradeLevel.fourth,
      numberRange: NumberRangeLevel.million,
      reviewOnly: false,
      tasks: remediationTasks,
      index: 1,
      wrongOnCurrent: 1,
      firstAttemptRecorded: true,
      checkCorrect: 1,
      checkTotal: 1,
      showHint: true,
      updatedAt: DateTime(2026, 9, 17, 8, 15),
    );

    final restored = RemediationSessionProgress.fromJson(
      jsonDecode(jsonEncode(progress.toJson())) as Map<String, dynamic>,
    );

    expect(restored.index, 1);
    expect(restored.wrongOnCurrent, 1);
    expect(restored.firstAttemptRecorded, isTrue);
    expect(restored.showHint, isTrue);
    expect(restored.tasks[1].taskKey, remediationTasks[1].taskKey);
    expect(restored.tasks[1].targetCompetency, MicroCompetencyId.symmetryAxes);
    expect(
      restored.isCompatible(
        pattern: ErrorPattern.symmetry,
        mode: TrainingMode.symmetry,
        grade: GradeLevel.fourth,
        range: NumberRangeLevel.million,
        reviewOnly: false,
        now: DateTime(2026, 9, 18, 8),
      ),
      isTrue,
    );
    expect(
      restored.isCompatible(
        pattern: ErrorPattern.symmetry,
        mode: TrainingMode.symmetry,
        grade: GradeLevel.fourth,
        range: NumberRangeLevel.million,
        reviewOnly: false,
        now: DateTime(2026, 9, 20, 8, 16),
      ),
      isFalse,
    );
  });

  test(
    'Vollständig beantwortete Fördersitzung bleibt als Abschluss-Pending gültig',
    () {
      final progress = RemediationSessionProgress(
        pattern: ErrorPattern.symmetry,
        mode: TrainingMode.symmetry,
        gradeLevel: GradeLevel.fourth,
        numberRange: NumberRangeLevel.million,
        reviewOnly: false,
        tasks: remediationTasks,
        index: remediationTasks.length,
        wrongOnCurrent: 0,
        firstAttemptRecorded: false,
        checkCorrect: 0,
        checkTotal: 0,
        showHint: false,
        updatedAt: DateTime(2026, 9, 17, 8, 15),
      );

      expect(
        progress.isCompatible(
          pattern: ErrorPattern.symmetry,
          mode: TrainingMode.symmetry,
          grade: GradeLevel.fourth,
          range: NumberRangeLevel.million,
          reviewOnly: false,
          now: DateTime(2026, 9, 17, 9),
        ),
        isTrue,
      );
    },
  );

  test('Recovery-Sitzung bindet sich an exakt denselben Teilfehler', () {
    final progress = StepRecoverySessionProgress(
      focus: focus,
      numberRange: NumberRangeLevel.hundred,
      tasks: stepTasks,
      index: 1,
      wrongOnCurrent: 0,
      firstAttemptRecorded: true,
      showHint: false,
      updatedAt: DateTime(2026, 9, 17, 8, 20),
    );
    final restored = StepRecoverySessionProgress.fromJson(
      jsonDecode(jsonEncode(progress.toJson())) as Map<String, dynamic>,
    );

    expect(
      restored.isCompatible(
        focus: focus,
        range: NumberRangeLevel.hundred,
        now: DateTime(2026, 9, 17, 12),
      ),
      isTrue,
    );
    final otherFocus = IndependentStepRecoveryFocus(
      competencyId: focus.competencyId,
      stepKey: focus.stepKey,
      label: focus.label,
      mode: focus.mode,
      lastSeen: focus.lastSeen,
      sourceTaskKey: 'practice:+:9:4',
    );
    expect(
      restored.isCompatible(
        focus: otherFocus,
        range: NumberRangeLevel.hundred,
        now: DateTime(2026, 9, 17, 12),
      ),
      isFalse,
    );
  });

  test('Support-Sitzungen bleiben strikt profilbezogen', () async {
    final storage = StorageService();
    await storage.initializeProfiles();
    final progress = RemediationSessionProgress(
      pattern: ErrorPattern.symmetry,
      mode: TrainingMode.symmetry,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      reviewOnly: false,
      tasks: remediationTasks,
      index: 1,
      wrongOnCurrent: 0,
      firstAttemptRecorded: false,
      checkCorrect: 0,
      checkTotal: 0,
      showHint: false,
      updatedAt: DateTime.now(),
    );
    await storage.saveRemediationSession(progress);

    await storage.setActiveProfileId('other');
    expect(await storage.loadRemediationSession(), isNull);
    await storage.saveStepRecoverySession(
      StepRecoverySessionProgress(
        focus: focus,
        numberRange: NumberRangeLevel.hundred,
        tasks: stepTasks,
        index: 0,
        wrongOnCurrent: 0,
        firstAttemptRecorded: false,
        showHint: false,
        updatedAt: DateTime.now(),
      ),
    );

    await storage.setActiveProfileId('default');
    expect((await storage.loadRemediationSession())?.index, 1);
    expect(await storage.loadStepRecoverySession(), isNull);
  });

  test('Zahlenraumwechsel verwirft angefangene Support-Sitzungen', () async {
    final storage = StorageService();
    await storage.initializeProfiles();
    await storage.saveRemediationSession(
      RemediationSessionProgress(
        pattern: ErrorPattern.symmetry,
        mode: TrainingMode.symmetry,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        reviewOnly: false,
        tasks: remediationTasks,
        index: 1,
        wrongOnCurrent: 0,
        firstAttemptRecorded: false,
        checkCorrect: 0,
        checkTotal: 0,
        showHint: false,
        updatedAt: DateTime.now(),
      ),
    );
    await storage.saveStepRecoverySession(
      StepRecoverySessionProgress(
        focus: focus,
        numberRange: NumberRangeLevel.hundred,
        tasks: stepTasks,
        index: 1,
        wrongOnCurrent: 0,
        firstAttemptRecorded: false,
        showHint: false,
        updatedAt: DateTime.now(),
      ),
    );

    final controller = AppController(storage: storage);
    await controller.load();
    expect(controller.remediationSessionProgress, isNotNull);
    expect(controller.stepRecoverySessionProgress, isNotNull);

    await controller.setNumberRange(NumberRangeLevel.twenty);
    expect(controller.remediationSessionProgress, isNull);
    expect(controller.stepRecoverySessionProgress, isNull);
    expect(await storage.loadRemediationSession(), isNull);
    expect(await storage.loadStepRecoverySession(), isNull);
  });

  test('Abgelaufene Support-Sitzungen werden beim Laden bereinigt', () async {
    final storage = StorageService();
    await storage.initializeProfiles();
    await storage.saveRemediationSession(
      RemediationSessionProgress(
        pattern: ErrorPattern.symmetry,
        mode: TrainingMode.symmetry,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        reviewOnly: false,
        tasks: remediationTasks,
        index: 1,
        wrongOnCurrent: 0,
        firstAttemptRecorded: false,
        checkCorrect: 0,
        checkTotal: 0,
        showHint: false,
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    );

    final controller = AppController(storage: storage);
    await controller.load();

    expect(controller.remediationSessionProgress, isNull);
    expect(await storage.loadRemediationSession(), isNull);
  });

  testWidgets('Förderbildschirm setzt exakt die gespeicherte Aufgabe fort', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.million;
    controller.remediationSessionProgress = RemediationSessionProgress(
      pattern: ErrorPattern.symmetry,
      mode: TrainingMode.symmetry,
      gradeLevel: GradeLevel.fourth,
      numberRange: NumberRangeLevel.million,
      reviewOnly: false,
      tasks: remediationTasks,
      index: 1,
      wrongOnCurrent: 1,
      firstAttemptRecorded: true,
      checkCorrect: 0,
      checkTotal: 0,
      showHint: true,
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RemediationScreen(
          controller: controller,
          pattern: ErrorPattern.symmetry,
          preferredMode: TrainingMode.symmetry,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Aufgabe 2 von 2 · fortgesetzt'), findsOneWidget);
    expect(find.text(remediationTasks[1].prompt), findsOneWidget);
    expect(find.text(remediationTasks[1].hint), findsOneWidget);
  });

  testWidgets(
    'Nach Neustart wird ein bereits beantworteter Förderpfad nur abgeschlossen',
    (tester) async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.fourth;
      controller.numberRange = NumberRangeLevel.million;
      controller.remediationSessionProgress = RemediationSessionProgress(
        pattern: ErrorPattern.symmetry,
        mode: TrainingMode.symmetry,
        gradeLevel: GradeLevel.fourth,
        numberRange: NumberRangeLevel.million,
        reviewOnly: false,
        tasks: remediationTasks,
        index: remediationTasks.length,
        wrongOnCurrent: 0,
        firstAttemptRecorded: false,
        checkCorrect: 2,
        checkTotal: 2,
        showHint: false,
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RemediationScreen(
            controller: controller,
            pattern: ErrorPattern.symmetry,
            preferredMode: TrainingMode.symmetry,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Das wird sicherer'), findsOneWidget);
      expect(controller.remediationSessionProgress, isNull);
      expect(
        controller.remediationStatusFor(ErrorPattern.symmetry),
        RemediationStatus.improved,
      );
    },
  );

  testWidgets(
    'Fortgesetzte Förderaufgabe zählt den ersten Versuch nicht doppelt',
    (tester) async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.fourth;
      controller.numberRange = NumberRangeLevel.million;
      controller.remediationSessionProgress = RemediationSessionProgress(
        pattern: ErrorPattern.symmetry,
        mode: TrainingMode.symmetry,
        gradeLevel: GradeLevel.fourth,
        numberRange: NumberRangeLevel.million,
        reviewOnly: false,
        tasks: remediationTasks,
        index: 0,
        wrongOnCurrent: 0,
        firstAttemptRecorded: true,
        checkCorrect: 0,
        checkTotal: 0,
        showHint: false,
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RemediationScreen(
            controller: controller,
            pattern: ErrorPattern.symmetry,
            preferredMode: TrainingMode.symmetry,
          ),
        ),
      );
      await tester.pump();
      expect(controller.diagnostics, isEmpty);

      final interaction = tester.widget<TouchAnswerInteraction>(
        find.byType(TouchAnswerInteraction),
      );
      interaction.onAnswer(remediationTasks.first.answer);
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();

      expect(controller.diagnostics, isEmpty);
      expect(find.text('Aufgabe 2 von 2 · fortgesetzt'), findsOneWidget);
    },
  );

  testWidgets('Manuell geöffnete Hilfe bleibt für Resume als Hilfe markiert', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.numberRange = NumberRangeLevel.hundred;
    controller.stepRecoverySessionProgress = StepRecoverySessionProgress(
      focus: focus,
      numberRange: NumberRangeLevel.hundred,
      tasks: stepTasks,
      index: 1,
      wrongOnCurrent: 0,
      firstAttemptRecorded: false,
      showHint: false,
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StepRecoveryScreen(controller: controller, focus: focus),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Hinweis anzeigen'));
    await tester.pump();

    expect(controller.stepRecoverySessionProgress?.showHint, isTrue);
    expect(find.text(stepTasks[1].hint), findsOneWidget);
  });

  testWidgets('Fortgesetzte Teilfehler-Aufgabe verdoppelt keine Evidenz', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.numberRange = NumberRangeLevel.hundred;
    controller.stepRecoverySessionProgress = StepRecoverySessionProgress(
      focus: focus,
      numberRange: NumberRangeLevel.hundred,
      tasks: stepTasks,
      index: 0,
      wrongOnCurrent: 0,
      firstAttemptRecorded: true,
      showHint: false,
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StepRecoveryScreen(controller: controller, focus: focus),
      ),
    );
    await tester.pump();
    expect(controller.microObservations, isEmpty);

    final pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
    pad.onAnswer(stepTasks.first.answer);
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump();

    expect(controller.microObservations, isEmpty);
    expect(find.text('Aufgabe 2 von 3 · fortgesetzt'), findsOneWidget);
  });

  testWidgets('Teilfehler-Recovery setzt exakt die gespeicherte Aufgabe fort', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.numberRange = NumberRangeLevel.hundred;
    controller.stepRecoverySessionProgress = StepRecoverySessionProgress(
      focus: focus,
      numberRange: NumberRangeLevel.hundred,
      tasks: stepTasks,
      index: 1,
      wrongOnCurrent: 0,
      firstAttemptRecorded: true,
      showHint: false,
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StepRecoveryScreen(controller: controller, focus: focus),
      ),
    );
    await tester.pump();

    expect(find.text('Aufgabe 2 von 3 · fortgesetzt'), findsOneWidget);
    expect(find.text(stepTasks[1].prompt), findsOneWidget);
  });
}
