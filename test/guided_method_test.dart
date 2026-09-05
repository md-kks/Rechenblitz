import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/widgets/guided_method_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Schulmethode bleibt bei geführtem Minus verbindlich', () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );
    final fact = MathFact(
      a: 13,
      b: 5,
      operation: MathOperation.minus,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 8,
      preferences: preferences,
      fact: fact,
    );

    expect(guide.methodKey, 'subtraction:bridgeToTen');
    expect(guide.methodLabel, 'Erst zum Zehner');
    expect(guide.steps.length, greaterThanOrEqualTo(3));
    expect(guide.steps.where((step) => step.isInteractive), isNotEmpty);
  });

  test('Automatisch vergleicht Methoden ohne gespeicherte Schulmethode zu ändern',
      () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.complement,
      selectionPreference: MethodSelectionPreference.automatic,
    );
    final selected =
        preferences.effectiveSubtraction(taskKey: 'minus:13:5');

    expect(SubtractionStrategy.values, contains(selected));
    expect(preferences.subtraction, SubtractionStrategy.complement);
    expect(
      preferences.selectionPreference,
      MethodSelectionPreference.automatic,
    );
  });

  test('Hilfestufen gewichten Mikro-Evidenz abgestuft', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    final fact1 = MathFact(a: 13, b: 5, operation: MathOperation.minus);
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: fact1.key,
      expected: 8,
      actual: 8,
      fact: fact1,
      helpLevel: HelpLevel.none.value,
      methodKey: 'subtraction:bridgeToTen',
    );
    final noHelp = controller.microObservations.firstWhere(
      (entry) => entry.id == MicroCompetencyId.subtractionTenBridge,
    );

    final fact2 = MathFact(a: 14, b: 6, operation: MathOperation.minus);
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: fact2.key,
      expected: 8,
      actual: 8,
      fact: fact2,
      helpLevel: HelpLevel.guided.value,
      methodKey: 'subtraction:bridgeToTen',
    );
    final guided = controller.microObservations.firstWhere(
      (entry) =>
          entry.id == MicroCompetencyId.subtractionTenBridge &&
          entry.taskKey == fact2.key,
    );

    expect(noHelp.evidenceWeight, closeTo(1.0, 0.001));
    expect(guided.evidenceWeight, closeTo(0.50, 0.001));
    expect(guided.helpLevel, 3);
    expect(guided.methodKey, 'subtraction:bridgeToTen');
  });

  test('Methodenbeobachtung ändert Schulmethode nicht', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.methodPreferences = const MethodPreferences(
      subtraction: SubtractionStrategy.complement,
      selectionPreference: MethodSelectionPreference.automatic,
    );

    controller.microObservations = List.generate(
      4,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        occurredAt: DateTime(2026, 9, 5, 10, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        helpLevel: 0,
        methodKey: 'subtraction:bridgeToTen',
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:${13 + index}:5',
      ),
    );

    final insight = controller.methodSupportInsight(
      MicroCompetencyId.subtractionTenBridge,
    );

    expect(insight, contains('Erst zum Zehner'));
    expect(
      controller.methodPreferences.subtraction,
      SubtractionStrategy.complement,
    );
  });
  test('Darstellungshilfe bleibt auch im Förderpfad darstellungsspezifisch', () {
    const preferences = MethodPreferences();

    final direct = GuidedMethodFactory.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'process:representation:groups:3:4',
      expected: 0,
      preferences: preferences,
      targetCompetency: MicroCompetencyId.representationTranslation,
    );
    expect(direct.methodKey, 'representation:equalGroups');
    expect(direct.methodLabel, 'Gleiche Gruppen lesen');
    expect(direct.steps, hasLength(3));
    expect(direct.steps.last.instruction, contains('3 × 4'));

    final remediation = GuidedMethodFactory.forTask(
      mode: TrainingMode.wordProblems,
      taskKey:
          'remediation:representationTranslation:process:representation:place:407',
      expected: 0,
      preferences: preferences,
      targetCompetency: MicroCompetencyId.representationTranslation,
    );
    expect(remediation.methodKey, 'representation:placeValue');
    expect(remediation.methodLabel, 'Stellenwerte lesen');
    expect(remediation.steps[1].instruction, contains('407'));
  });

  test('Minus über den Zehner markiert echte Zwischenschritte', () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );
    final fact = MathFact(
      a: 13,
      b: 5,
      operation: MathOperation.minus,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 8,
      preferences: preferences,
      fact: fact,
    );

    expect(guide.steps[0].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[0].evidenceCompetency,
      MicroCompetencyId.subtractionTenBridge,
    );
    expect(guide.steps[0].evidenceKey, 'bridgeAmount');
    expect(guide.steps[1].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[1].evidenceCompetency,
      MicroCompetencyId.numberDecomposition,
    );
    expect(guide.steps.last.recordsIntermediateEvidence, isFalse);
  });

  test('Darstellungswechsel zerlegt Gruppenlesen in beobachtbare Teilfragen', () {
    const preferences = MethodPreferences();

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'process:representation:groups:3:4',
      expected: 0,
      preferences: preferences,
      targetCompetency: MicroCompetencyId.representationTranslation,
    );

    expect(guide.steps[0].question, contains('Gruppen'));
    expect(guide.steps[0].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[0].evidenceCompetency,
      MicroCompetencyId.multiplicationGroups,
    );
    expect(guide.steps[1].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[1].evidenceCompetency,
      MicroCompetencyId.multiplicationGroups,
    );
    expect(guide.steps[2].recordsIntermediateEvidence, isFalse);
  });

  test('Schriftliches Minus beobachtet Ausrichtung und Entbündelentscheidung',
      () {
    const preferences = MethodPreferences(
      writtenSubtraction: WrittenSubtractionStrategy.regroup,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:-:402:187',
      expected: 215,
      preferences: preferences,
    );

    expect(guide.steps[0].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[0].evidenceCompetency,
      MicroCompetencyId.writtenAlignment,
    );
    expect(guide.steps[1].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps[1].evidenceCompetency,
      MicroCompetencyId.writtenRegrouping,
    );
    expect(guide.steps[1].choices[guide.steps[1].correctChoice!], 'Ja');
  });

  test('Zerlegte Multiplikation beobachtet Teilprodukte statt nur Endergebnis',
      () {
    const preferences = MethodPreferences(
      multiplication: MultiplicationStrategy.decompose,
    );
    final fact = MathFact(
      a: 6,
      b: 7,
      operation: MathOperation.multiply,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.multiply,
      taskKey: fact.key,
      expected: 42,
      preferences: preferences,
      fact: fact,
    );

    expect(guide.steps[0].recordsIntermediateEvidence, isTrue);
    expect(guide.steps[1].recordsIntermediateEvidence, isTrue);
    expect(
      guide.steps.take(2).every(
            (step) =>
                step.evidenceCompetency ==
                MicroCompetencyId.multiplicationFacts,
          ),
      isTrue,
    );
    expect(guide.steps.last.recordsIntermediateEvidence, isFalse);
  });

  testWidgets('Geführtes Panel meldet nur den ersten Versuch eines Schritts',
      (tester) async {
    const step = GuidedMethodStep(
      title: 'Teilfrage',
      instruction: 'Löse zuerst diesen Zwischenschritt.',
      question: 'Was ist richtig?',
      choices: ['3', '4'],
      correctChoice: 1,
      evidenceKey: 'firstStep',
      evidenceCompetency: MicroCompetencyId.numberDecomposition,
    );
    const guide = GuidedMethodGuide(
      methodKey: 'test:guided',
      methodLabel: 'Testweg',
      nudge: 'Ein kleiner Hinweis.',
      steps: [step],
    );
    final attempts = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuidedMethodPanel(
            guide: guide,
            pattern: ErrorPattern.numberBond,
            taskKey: 'test:task',
            expected: 4,
            onHelpLevelChanged: (_) {},
            onStepAttempt: (_, correct) async {
              attempts.add(correct);
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('3 Gemeinsam lösen'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ChoiceChip, '3'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '4'));
    await tester.pump();

    expect(attempts, [false]);
    expect(find.text('Genau. Dieser Schritt stimmt.'), findsOneWidget);
  });


  test('GuidedStepCatalog erkennt gespeicherte Teilsschlüssel zuverlässig', () {
    const taskKey =
        'guided:subtraction:bridgeToTen:remainingSubtrahend:minus:13:5';

    expect(
      GuidedStepCatalog.keyFromTaskKey(taskKey),
      'remainingSubtrahend',
    );
    expect(
      GuidedStepCatalog.labelFor('remainingSubtrahend'),
      contains('Subtrahenden'),
    );
    expect(GuidedStepCatalog.keyFromTaskKey('minus:13:5'), isNull);
  });


  test('Scaffold-Fading reduziert Darstellung zu Hinweis und dann ohne Hilfe',
      () {
    expect(
      ScaffoldFadingPolicy.initialLevelForTask(0, enabled: true),
      HelpLevel.visual,
    );
    expect(
      ScaffoldFadingPolicy.initialLevelForTask(1, enabled: true),
      HelpLevel.nudge,
    );
    expect(
      ScaffoldFadingPolicy.initialLevelForTask(2, enabled: true),
      isNull,
    );
    expect(
      ScaffoldFadingPolicy.initialLevelForTask(4, enabled: true),
      isNull,
    );
    expect(
      ScaffoldFadingPolicy.initialLevelForTask(0, enabled: false),
      isNull,
    );
  });

  testWidgets('Geführtes Panel kann direkt mit Darstellung starten',
      (tester) async {
    const guide = GuidedMethodGuide(
      methodKey: 'test:fading',
      methodLabel: 'Fading',
      nudge: 'Ein kurzer Hinweis.',
      steps: [],
    );
    final levels = <HelpLevel>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuidedMethodPanel(
            guide: guide,
            pattern: ErrorPattern.numberBond,
            taskKey: 'test:fading',
            expected: 10,
            initialLevel: HelpLevel.visual,
            onHelpLevelChanged: levels.add,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(levels, [HelpLevel.visual]);
    final visualChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '2 Darstellung'),
    );
    expect(visualChip.selected, isTrue);
  });


}
