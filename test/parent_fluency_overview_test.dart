import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/accessibility_preferences.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/parent_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppController> _controller() async {
  final controller = AppController();
  await controller.load();
  controller.gradeLevel = GradeLevel.second;
  controller.numberRange = NumberRangeLevel.hundred;
  return controller;
}

Future<void> _showFluencySection(
  WidgetTester tester,
  AppController controller,
) async {
  await tester.pumpWidget(MaterialApp(home: ParentScreen(controller: controller)));
  await tester.pump();
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('parent-fluency-overview')),
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fluency-faehige Kompetenz startet als noch nicht gemessen', () async {
    final controller = await _controller();
    final arithmetic = controller.microCompetencyProgress(
      MicroCompetencyId.additionNoBridge,
    );
    final language = controller.microCompetencyProgress(
      MicroCompetencyId.wordProblemModel,
    );

    expect(arithmetic.fluencyState, MicroFluencyState.notMeasured);
    expect(language.fluencyState, MicroFluencyState.notApplicable);
  });

  testWidgets('Elternbereich trennt Automatisierung von allgemeiner Antwortzeit', (
    tester,
  ) async {
    final controller = await _controller();
    await _showFluencySection(tester, controller);

    expect(find.text('Automatisierung'), findsOneWidget);
    expect(find.text('noch offen'), findsOneWidget);
    expect(find.text('Ø Antwort'), findsNothing);
    expect(find.textContaining('ohne Countdown'), findsWidgets);
    expect(
      find.textContaining('Tempo- und Schnellrechen-Modi'),
      findsOneWidget,
    );
  });

  testWidgets('Elternbereich zeigt den fachlich sicheren Fluency-Fokus', (
    tester,
  ) async {
    final controller = await _controller();
    controller.microObservations = List.generate(
      4,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 16, 9, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:${12 + index}:3',
        responseMs: 9000,
      ),
    );

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionNoBridge,
    );
    expect(progress.state, MicroCompetencyState.secure);
    expect(progress.fluencyState, MicroFluencyState.building);

    await _showFluencySection(tester, controller);
    final label = MicroCompetencyCatalog.definition(
      MicroCompetencyId.additionNoBridge,
    ).label;
    expect(find.text(label), findsWidgets);
    expect(find.textContaining('100 % richtig'), findsWidgets);
    expect(find.textContaining('typisch 9.0 s'), findsWidgets);
    expect(
      find.byKey(const ValueKey('parent-fluency-additionNoBridge')),
      findsOneWidget,
    );
    expect(find.textContaining('ohne Countdown automatisiert'), findsOneWidget);
  });


  testWidgets('Elternstart uebernimmt Fluency-Fokus ohne Countdown', (tester) async {
    final controller = await _controller();
    final base = DateTime.now().subtract(const Duration(minutes: 10));
    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 4; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: base.add(Duration(minutes: index)),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:${12 + index}:3',
          responseMs: 9000,
        ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: base.add(const Duration(minutes: 4)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.review,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:31:4:review',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: base.add(const Duration(minutes: 5)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.transfer,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'story:+:books:24:3:transfer',
      ),
    ];
    final decision = controller.guidedRoundDecisionTrace().primary;
    expect(decision?.kind.name, 'fluency');
    expect(decision?.competencyId, MicroCompetencyId.additionNoBridge);

    await tester.pumpWidget(MaterialApp(home: ParentScreen(controller: controller)));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('parent-fluency-start')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Ohne Zeitdruck automatisieren'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('parent-fluency-start')));
    await tester.pumpAndSettle();

    final screen = tester.widget<TrainingScreen>(find.byType(TrainingScreen));
    expect(screen.mode, TrainingMode.practice);
    expect(screen.targetCompetency, MicroCompetencyId.additionNoBridge);
    expect(screen.fluencyEmphasis, isTrue);
    expect(screen.timeLimit, isNull);
    expect(find.byKey(const ValueKey('fluency-no-pressure')), findsOneWidget);
    expect(find.textContaining('Kein Countdown'), findsOneWidget);
  });

  testWidgets('fachliche Unsicherheit sperrt den Fluency-Schnellstart', (
    tester,
  ) async {
    final controller = await _controller();
    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 4; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: DateTime(2026, 9, 16, 8, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:${12 + index}:3',
          responseMs: 9000,
        ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 16, 8, 5),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.review,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:31:4:review',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 16, 8, 6),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.transfer,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'story:+:books:24:3:transfer',
      ),
      for (var index = 0; index < 3; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.subtractionNoBridge,
          occurredAt: DateTime(2026, 9, 16, 9, index),
          correct: index == 0,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'minus:${18 + index}:3',
          responseMs: 4000,
        ),
    ];

    expect(
      controller.fluencyFocusMicroCompetency()?.definition.id,
      MicroCompetencyId.additionNoBridge,
    );
    expect(
      controller.parentPriorityMicroCompetency()?.definition.id,
      MicroCompetencyId.subtractionNoBridge,
    );

    await _showFluencySection(tester, controller);
    expect(find.byKey(const ValueKey('parent-fluency-start')), findsNothing);
  });

  testWidgets('Vorlesen pausiert nur die Automatisierungsmessung', (tester) async {
    final controller = await _controller();
    controller.accessibilityPreferences =
        const AccessibilityPreferences(readAloud: true);

    await _showFluencySection(tester, controller);

    expect(find.text('Messung pausiert'), findsWidgets);
    expect(
      find.textContaining('fachliche Lernstand läuft davon unabhängig weiter'),
      findsOneWidget,
    );
  });

  testWidgets('Automatisierungsuebersicht bleibt bei 200 Prozent lesbar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    final controller = await _controller();

    await _showFluencySection(tester, controller);

    expect(
      find.byKey(const ValueKey('parent-fluency-overview')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('gesamter Elternbereich bleibt bei 200 Prozent ohne Overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    final controller = await _controller();
    await tester.pumpWidget(MaterialApp(home: ParentScreen(controller: controller)));
    await tester.pump();
    expect(tester.takeException(), isNull);

    final list = find.byType(ListView).first;
    for (var i = 0; i < 28; i++) {
      await tester.drag(list, const Offset(0, -360));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'scroll step $i');
    }
  });

}
