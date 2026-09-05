import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
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
    final visualChip = tester.widget<ActionChip>(
      find.widgetWithText(ActionChip, '2 Darstellung'),
    );
    expect(visualChip.avatar, isNotNull);
  });



  test('Plus über den Zehner markiert echte unabhängige Zwischenschritte', () {
    final fact = MathFact(
      a: 47,
      b: 38,
      operation: MathOperation.plus,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.practice,
      taskKey: fact.key,
      expected: 85,
      preferences: const MethodPreferences(),
      fact: fact,
    );

    expect(guide.methodKey, 'addition:bridgeToTen');
    expect(guide.steps[0].question, contains('47'));
    expect(guide.steps[0].choices[guide.steps[0].correctChoice!], '3');
    expect(guide.steps[0].evidenceKey, 'bridgeAmount');
    expect(
      guide.steps[0].evidenceCompetency,
      MicroCompetencyId.additionTenBridge,
    );
    expect(guide.steps[1].choices[guide.steps[1].correctChoice!], '35');
    expect(guide.steps[1].evidenceKey, 'remainingAddend');
    expect(
      guide.steps[1].evidenceCompetency,
      MicroCompetencyId.numberDecomposition,
    );
    expect(guide.steps.last.recordsIntermediateEvidence, isFalse);
  });

  test('Exakter Zehner erzeugt keinen künstlichen Rest-Zwischenschritt', () {
    final fact = MathFact(
      a: 17,
      b: 3,
      operation: MathOperation.plus,
    );

    final steps = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: fact,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );

    expect(steps, hasLength(1));
    expect(steps.single.evidenceKey, 'bridgeAmount');
  });

  test('Unabhängige Rechenschritte bleiben gezielt und untimed', () {
    final bridge = MathFact(
      a: 47,
      b: 38,
      operation: MathOperation.plus,
    );
    final noBridge = MathFact(
      a: 42,
      b: 3,
      operation: MathOperation.plus,
    );

    final targeted = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: bridge,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );
    final decompositionOnly =
        GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: bridge,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.numberDecomposition,
    );
    final untargeted = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: bridge,
      preferences: const MethodPreferences(),
    );
    final timed = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.speed,
      fact: bridge,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );
    final simple = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: noBridge,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );

    expect(targeted.map((step) => step.evidenceKey), [
      'bridgeAmount',
      'remainingAddend',
    ]);
    expect(
      decompositionOnly.map((step) => step.evidenceKey),
      ['remainingAddend'],
    );
    expect(untargeted, isEmpty);
    expect(timed, isEmpty);
    expect(simple, isEmpty);
  });

  test('Einmaleins-Teilfragen bleiben methodentreu und mikrogezielt', () {
    final fact = MathFact(
      a: 7,
      b: 6,
      operation: MathOperation.multiply,
    );

    final groups = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.multiply,
      fact: fact,
      preferences: const MethodPreferences(
        multiplication: MultiplicationStrategy.groups,
      ),
      targetCompetency: MicroCompetencyId.multiplicationFacts,
    );
    final decompose = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.multiply,
      fact: fact,
      preferences: const MethodPreferences(
        multiplication: MultiplicationStrategy.decompose,
      ),
      targetCompetency: MicroCompetencyId.multiplicationFacts,
    );
    final neighbor = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.multiply,
      fact: fact,
      preferences: const MethodPreferences(
        multiplication: MultiplicationStrategy.neighborFacts,
      ),
      targetCompetency: MicroCompetencyId.multiplicationFacts,
    );
    final wrongTarget = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.multiply,
      fact: fact,
      preferences: const MethodPreferences(
        multiplication: MultiplicationStrategy.decompose,
      ),
      targetCompetency: MicroCompetencyId.multiplicationGroups,
    );
    final timed = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.speed,
      fact: fact,
      preferences: const MethodPreferences(
        multiplication: MultiplicationStrategy.decompose,
      ),
      targetCompetency: MicroCompetencyId.multiplicationFacts,
    );

    expect(groups.map((step) => step.evidenceKey), ['anchorFact']);
    expect(groups.single.choices[groups.single.correctChoice!], '30');
    expect(
      decompose.map((step) => step.evidenceKey),
      ['firstPartialProduct', 'secondPartialProduct'],
    );
    expect(decompose[0].choices[decompose[0].correctChoice!], '21');
    expect(decompose[1].choices[decompose[1].correctChoice!], '21');
    expect(neighbor.map((step) => step.evidenceKey), ['anchorFact']);
    expect(neighbor.single.choices[neighbor.single.correctChoice!], '35');
    expect(
      [
        ...groups,
        ...decompose,
        ...neighbor,
      ].every(
        (step) =>
            step.evidenceCompetency ==
            MicroCompetencyId.multiplicationFacts,
      ),
      isTrue,
    );
    expect(wrongTarget, isEmpty);
    expect(timed, isEmpty);
  });

  test('Minus nutzt die gewählte Schulmethode und überspringt triviale Dekaden',
      () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );
    final bridge = MathFact(
      a: 63,
      b: 28,
      operation: MathOperation.minus,
    );
    final fullDecade = MathFact(
      a: 20,
      b: 7,
      operation: MathOperation.minus,
    );

    final steps = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.minus,
      fact: bridge,
      preferences: preferences,
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
    );
    final trivial = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.minus,
      fact: fullDecade,
      preferences: preferences,
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
    );

    expect(steps.map((step) => step.evidenceKey), [
      'bridgeAmount',
      'remainingSubtrahend',
    ]);
    expect(steps[0].choices[steps[0].correctChoice!], '3');
    expect(steps[1].choices[steps[1].correctChoice!], '25');
    expect(trivial, isEmpty);
  });

  test('Arithmetische Teilfragen bleiben auf zwei Fokusaufgaben begrenzt', () {
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        0,
        scaffoldFading: false,
      ),
      isTrue,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        1,
        scaffoldFading: false,
      ),
      isTrue,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        2,
        scaffoldFading: false,
      ),
      isFalse,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        1,
        scaffoldFading: true,
      ),
      isFalse,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        2,
        scaffoldFading: true,
      ),
      isTrue,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        3,
        scaffoldFading: true,
      ),
      isTrue,
    );
    expect(
      IndependentArithmeticStepPolicy.shouldProbeTask(
        4,
        scaffoldFading: true,
      ),
      isFalse,
    );
  });

  test('GuidedStepCatalog erkennt auch den Rest des zweiten Summanden', () {
    const key = 'independent:remainingAddend:plus:47:38';

    expect(GuidedStepCatalog.keyFromTaskKey(key), 'remainingAddend');
    expect(
      GuidedStepCatalog.labelFor('remainingAddend'),
      contains('zweiten Summanden'),
    );
  });

  testWidgets(
      'Scaffold-Fading prüft erst nach zwei unterstützten Aufgaben selbstständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.facts = [
      MathFact(
        a: 47,
        b: 38,
        operation: MathOperation.plus,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 3,
          targetCompetency: MicroCompetencyId.additionTenBridge,
          scaffoldFading: true,
        ),
      ),
    );
    await tester.pump();

    Future<void> tapAnswerButton(String label) async {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }

    expect(find.textContaining('Schritt 1 von'), findsNothing);

    for (final label in ['8', '5', 'OK']) {
      await tapAnswerButton(label);
    }
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('Schritt 1 von'), findsNothing);

    await tapAnswerButton('8');
    await tapAnswerButton('5');
    await tapAnswerButton('OK');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Schritt 1 von'), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Schritt 1 von 2'), findsOneWidget);
  });

  testWidgets(
      'Training speichert ersten Zehnerübergangsversuch und direkte Lösung getrennt',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.facts = [
      MathFact(
        a: 47,
        b: 38,
        operation: MathOperation.plus,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.additionTenBridge,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 2'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '2'));
    await tester.pump();

    final failedStep = controller.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.independentStep,
    );
    expect(failedStep.id, MicroCompetencyId.additionTenBridge);
    expect(failedStep.correct, isFalse);
    expect(failedStep.usedHelp, isFalse);
    expect(
      failedStep.taskKey,
      'independent:bridgeAmount:plus:47:38',
    );

    await tester.tap(find.widgetWithText(FilledButton, '3'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Schritt 2 von 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '35'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Antwort eingeben'), findsOneWidget);

    for (final label in ['8', '5', 'OK']) {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('0 davon waren direkt richtig.'), findsOneWidget);
    expect(
      controller
          .recentTaskKeys(TrainingMode.practice)
          .where((key) => key == 'plus:47:38')
          .length,
      1,
    );
  });


  test('Schriftliches Plus beobachtet Ausrichtung und echten Übertrag', () {
    const preferences = MethodPreferences();

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:+:342:381',
      expected: 723,
      preferences: preferences,
    );

    expect(guide.methodKey, 'writtenAddition:standard');
    expect(guide.steps[0].evidenceKey, 'onesAlignment');
    expect(
      guide.steps[0].evidenceCompetency,
      MicroCompetencyId.writtenAlignment,
    );
    expect(guide.steps[0].choices[guide.steps[0].correctChoice!], '1');
    expect(guide.steps[1].question, contains('Zehner-Spalte'));
    expect(guide.steps[1].choices[guide.steps[1].correctChoice!], 'Ja');
    expect(guide.steps[1].evidenceKey, 'carryDecision');
    expect(
      guide.steps[1].evidenceCompetency,
      MicroCompetencyId.writtenRegrouping,
    );
  });

  test('Schriftliche Teilfragen bleiben mikrogezielt und methodentreu', () {
    const standard = MethodPreferences();
    const complement = MethodPreferences(
      writtenSubtraction: WrittenSubtractionStrategy.complement,
    );

    final regrouping = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:+:47:38',
      expected: 85,
      preferences: standard,
      targetCompetency: MicroCompetencyId.writtenRegrouping,
    );
    final alignment = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:+:47:38',
      expected: 85,
      preferences: standard,
      targetCompetency: MicroCompetencyId.writtenAlignment,
    );
    final noCarry = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:+:42:13',
      expected: 55,
      preferences: standard,
      targetCompetency: MicroCompetencyId.writtenRegrouping,
    );
    final complementSteps =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:-:352:168',
      expected: 184,
      preferences: complement,
      targetCompetency: MicroCompetencyId.writtenRegrouping,
    );

    expect(
      regrouping.map((step) => step.evidenceKey),
      ['onesAlignment', 'carryDecision'],
    );
    expect(alignment.map((step) => step.evidenceKey), ['onesAlignment']);
    expect(noCarry, isEmpty);
    expect(
      complementSteps.map((step) => step.evidenceKey),
      ['onesAlignment', 'carryDecision'],
    );
    expect(complementSteps[1].question, contains('über 10 ergänzen'));
  });

  test('GuidedStepCatalog erkennt Übertragsentscheidungen', () {
    const key = 'independent:carryDecision:written:+:47:38';

    expect(GuidedStepCatalog.keyFromTaskKey(key), 'carryDecision');
    expect(GuidedStepCatalog.labelFor('carryDecision'), contains('Übertrag'));
  });

  testWidgets(
      'Curriculum speichert schriftlichen Teilfehler getrennt von der Endlösung',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    const exercise = CurriculumExercise(
      mode: TrainingMode.writtenAddSub,
      prompt: 'Rechne schriftlich:\n47\n+ 38',
      answer: 85,
      hint: 'Achte auf Stellenwerte und Übertrag.',
      key: 'written:+:47:38',
      maxAnswerValue: 100,
      method: 'Schriftliche Addition',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.writtenAddSub,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.writtenRegrouping,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 2'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '7'));
    await tester.pump();

    final failedStep = controller.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.independentStep,
    );
    expect(failedStep.id, MicroCompetencyId.writtenAlignment);
    expect(failedStep.correct, isFalse);
    expect(failedStep.usedHelp, isFalse);
    expect(
      failedStep.taskKey,
      'independent:onesAlignment:written:+:47:38',
    );

    await tester.tap(find.widgetWithText(FilledButton, '8'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Schritt 2 von 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Ja'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Antwort eingeben'), findsOneWidget);

    for (final label in ['8', '5', 'OK']) {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('0 direkt richtig.'), findsOneWidget);
    expect(
      controller
          .recentTaskKeys(TrainingMode.writtenAddSub)
          .where((key) => key == 'written:+:47:38')
          .length,
      1,
    );
  });


  test('Schriftliches Mal beobachtet Spaltenprodukt und Übertrag', () {
    final steps = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenMultiply,
      taskKey: 'written:x:237:4',
      expected: 948,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.writtenMultiplyProcedure,
    );

    expect(steps.map((step) => step.evidenceKey), [
      'firstPartialProduct',
      'multiplicationCarry',
    ]);
    expect(steps[0].choices[steps[0].correctChoice!], '28');
    expect(steps[1].choices[steps[1].correctChoice!], '2');
    expect(
      steps.every(
        (step) =>
            step.evidenceCompetency ==
            MicroCompetencyId.writtenMultiplyProcedure,
      ),
      isTrue,
    );
  });

  test('Mehrstelliger Faktor nutzt Teilprodukt und nächste Faktorstelle', () {
    final steps = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenMultiply,
      taskKey: 'written:x:123:14',
      expected: 1722,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.writtenMultiplyProcedure,
    );

    expect(steps.map((step) => step.evidenceKey), [
      'firstPartialProduct',
      'nextMultiplierDigit',
    ]);
    expect(steps[0].choices[steps[0].correctChoice!], '492');
    expect(steps[1].choices[steps[1].correctChoice!], '1');
  });

  test('Schriftliches Teilen beobachtet erste Quotientenziffer und Rest', () {
    final steps = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenDivide,
      taskKey: 'written:divide:324:6',
      expected: 54,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.writtenDivideProcedure,
    );

    expect(steps.map((step) => step.evidenceKey), [
      'firstQuotientDigit',
      'firstDivisionRemainder',
    ]);
    expect(steps[0].question, contains('6 in 32'));
    expect(steps[0].choices[steps[0].correctChoice!], '5');
    expect(steps[1].choices[steps[1].correctChoice!], '2');
    expect(
      steps.every(
        (step) =>
            step.evidenceCompetency ==
            MicroCompetencyId.writtenDivideProcedure,
      ),
      isTrue,
    );
  });

  test('Schriftliche Mal/Geteilt-Teilfragen bleiben auf ihr Lernziel begrenzt',
      () {
    final wrongTarget = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenMultiply,
      taskKey: 'written:x:237:4',
      expected: 948,
      preferences: const MethodPreferences(),
      targetCompetency: MicroCompetencyId.writtenAlignment,
    );
    final untargetedDivision =
        GuidedMethodFactory.independentWrittenStepsForTask(
      mode: TrainingMode.writtenDivide,
      taskKey: 'written:divide:324:6',
      expected: 54,
      preferences: const MethodPreferences(),
    );

    expect(wrongTarget, isEmpty);
    expect(untargetedDivision, isEmpty);
  });

  test('GuidedStepCatalog kennt schriftliche Mal- und Geteilt-Schritte', () {
    expect(
      GuidedStepCatalog.keyFromTaskKey(
        'independent:multiplicationCarry:written:x:237:4',
      ),
      'multiplicationCarry',
    );
    expect(
      GuidedStepCatalog.labelFor('firstQuotientDigit'),
      contains('Quotientenziffer'),
    );
    expect(
      GuidedStepCatalog.labelFor('firstDivisionRemainder'),
      contains('Divisionsschritt'),
    );
  });

  testWidgets(
      'Curriculum speichert schriftlichen Mal-Teilfehler vor der Endlösung',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;

    const exercise = CurriculumExercise(
      mode: TrainingMode.writtenMultiply,
      prompt: 'Rechne schriftlich:\n237 × 4',
      answer: 948,
      hint: 'Multipliziere Stelle für Stelle.',
      key: 'written:x:237:4',
      maxAnswerValue: 1000,
      method: 'Schriftliche Multiplikation',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.writtenMultiply,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.writtenMultiplyProcedure,
          exerciseGenerator: _FixedCurriculumExerciseGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 2'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '27'));
    await tester.pump();

    final failedStep = controller.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.independentStep,
    );
    expect(failedStep.id, MicroCompetencyId.writtenMultiplyProcedure);
    expect(failedStep.correct, isFalse);
    expect(
      failedStep.taskKey,
      'independent:firstPartialProduct:written:x:237:4',
    );

    await tester.tap(find.widgetWithText(FilledButton, '28'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Schritt 2 von 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '2'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Antwort eingeben'), findsOneWidget);

    for (final label in ['9', '4', '8', 'OK']) {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('0 direkt richtig.'), findsOneWidget);
    expect(
      controller
          .recentTaskKeys(TrainingMode.writtenMultiply)
          .where((key) => key == 'written:x:237:4')
          .length,
      1,
    );
  });

  testWidgets(
      'Training speichert Einmaleins-Ankerfehler getrennt von der Endlösung',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.setMultiplicationStrategy(
      MultiplicationStrategy.neighborFacts,
    );
    controller.facts = [
      MathFact(
        a: 7,
        b: 6,
        operation: MathOperation.multiply,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.multiply,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.multiplicationFacts,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Schritt 1 von 1'), findsOneWidget);
    expect(find.text('Antwort eingeben'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '34'));
    await tester.pump();

    final failedStep = controller.microObservations.firstWhere(
      (entry) => entry.source == MicroEvidenceSource.independentStep,
    );
    expect(failedStep.id, MicroCompetencyId.multiplicationFacts);
    expect(failedStep.correct, isFalse);
    expect(failedStep.usedHelp, isFalse);
    expect(
      failedStep.taskKey,
      'independent:anchorFact:multiply:7:6',
    );

    await tester.tap(find.widgetWithText(FilledButton, '35'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Antwort eingeben'), findsOneWidget);

    for (final label in ['4', '2', 'OK']) {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('0 davon waren direkt richtig.'), findsOneWidget);
    expect(
      controller
          .recentTaskKeys(TrainingMode.multiply)
          .where((key) => key == 'multiply:7:6')
          .length,
      1,
    );
  });

  test('Sachaufgaben-Hilfe beobachtet die fünf Modellierungsschritte getrennt',
      () {
    const cases = [
      (
        taskKey: 'story:info:trip:5:2:3',
        competency: MicroCompetencyId.wordProblemRelevantInformation,
        stepKey: 'storyInfo',
      ),
      (
        taskKey: 'story:operation:-:9:4',
        competency: MicroCompetencyId.wordProblemOperation,
        stepKey: 'storyOperation',
      ),
      (
        taskKey: 'story:equation:+:7:5',
        competency: MicroCompetencyId.wordProblemModel,
        stepKey: 'storyEquation',
      ),
      (
        taskKey: 'story:calc:x:4:3',
        competency: MicroCompetencyId.wordProblemCalculation,
        stepKey: 'storyCalculation',
      ),
      (
        taskKey: 'story:interpret:+:7:5:12',
        competency: MicroCompetencyId.wordProblemInterpretation,
        stepKey: 'storyInterpretation',
      ),
    ];

    for (final item in cases) {
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.wordProblems,
        taskKey: item.taskKey,
        expected: 0,
        preferences: const MethodPreferences(),
        targetCompetency: item.competency,
      );
      final evidenceSteps = guide.steps
          .where((step) => step.recordsIntermediateEvidence)
          .toList();

      expect(evidenceSteps, hasLength(1), reason: item.taskKey);
      expect(evidenceSteps.single.evidenceKey, item.stepKey);
      expect(evidenceSteps.single.evidenceCompetency, item.competency);
      expect(
        evidenceSteps.single.correctChoice,
        inInclusiveRange(0, evidenceSteps.single.choices.length - 1),
      );
      expect(
        GuidedStepCatalog.labelFor(item.stepKey),
        isNot(item.stepKey),
      );
    }
  });

  testWidgets(
      'Structured Training speichert ersten Sachaufgaben-Teilschritt eigenständig',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.twenty;

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.wordProblemOperation,
        ),
      ),
    );
    await tester.pump();

    final answerButtons = find.byType(FilledButton);
    expect(answerButtons, findsWidgets);
    await tester.tap(answerButtons.first);
    await tester.pump();

    final steps = controller.microObservations
        .where((entry) => entry.source == MicroEvidenceSource.independentStep)
        .toList();
    expect(steps, hasLength(1));
    expect(steps.single.id, MicroCompetencyId.wordProblemOperation);
    expect(steps.single.usedHelp, isFalse);
    expect(
      steps.single.taskKey,
      startsWith('independent:storyOperation:story:operation:'),
    );
    await tester.pump(const Duration(milliseconds: 600));
  });

}

class _FixedCurriculumExerciseGenerator extends CurriculumExerciseGenerator {
  _FixedCurriculumExerciseGenerator(this.exercise);

  final CurriculumExercise exercise;

  @override
  CurriculumExercise generate({
    required TrainingMode mode,
    required GradeLevel gradeLevel,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
  }) =>
      exercise;



}
