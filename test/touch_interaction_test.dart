import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/widgets/number_answer_pad.dart';
import 'package:rechenblitz/widgets/touch_answer_interaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppController> _controller() async {
  final controller = AppController();
  await controller.load();
  controller.gradeLevel = GradeLevel.second;
  controller.numberRange = NumberRangeLevel.twenty;
  return controller;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('touch planner covers active lower-primary task families', () {
    final gap = TouchInteractionPlan.forTask(
      mode: TrainingMode.missingNumber,
      taskKey: 'gap:+:7:5:b',
      answer: 5,
      maxValue: 20,
    );
    final neighbor = TouchInteractionPlan.forTask(
      mode: TrainingMode.neighbors,
      taskKey: 'neighbor:12:before',
      answer: 11,
      maxValue: 20,
    );
    final sequence = TouchInteractionPlan.forTask(
      mode: TrainingMode.sequences,
      taskKey: 'sequence:+:2:5',
      answer: 17,
      maxValue: 20,
    );
    final wall = TouchInteractionPlan.forTask(
      mode: TrainingMode.numberWall,
      taskKey: 'wall:1-3-1-4-4-8:3',
      answer: 4,
      maxValue: 20,
      wallValues: const [1, 3, 1, 4, 4, 8],
      hiddenWallIndex: 3,
    );

    expect(gap?.kind, TouchInteractionKind.numberLine);
    expect(neighbor?.startValue, 12);
    expect(sequence?.startValue, 12);
    expect(wall?.kind, TouchInteractionKind.dragNumberToTarget);
    expect(wall?.hasInteractiveWall, isTrue);
    expect(wall?.minValue, 0);
    expect(wall?.maxValue, 20);
  });

  test('large-number neighbors use a local touch number line', () {
    final plan = TouchInteractionPlan.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:neighbor:123456:true',
      answer: 123457,
      maxValue: 1000000,
    );

    expect(plan, isNotNull);
    expect(plan!.kind, TouchInteractionKind.numberLine);
    expect(plan.minValue, 123453);
    expect(plan.maxValue, 123459);
    expect(plan.startValue, 123456);
  });

  test('touch planner keeps very large number ranges on keypad input', () {
    expect(
      TouchInteractionPlan.forTask(
        mode: TrainingMode.missingNumber,
        taskKey: 'gap:+:123:77:b',
        answer: 77,
        maxValue: 1000,
      ),
      isNull,
    );
  });

  testWidgets('number-line touch input submits the selected value', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'gap:+:7:5:b',
      kind: TouchInteractionKind.numberLine,
      instruction: 'Zieh den Punkt.',
      minValue: 0,
      maxValue: 20,
      startValue: 7,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TouchAnswerInteraction(
            plan: plan,
            onAnswer: (value) => answer = value,
          ),
        ),
      ),
    );

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('touch-number-line-slider')),
    );
    slider.onChanged!(12);
    await tester.pump();
    expect(find.text('12'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('touch-number-line-submit')));
    expect(answer, 12);
  });

  testWidgets('number cards can be dragged into an interactive number wall', (
    tester,
  ) async {
    var answer = -1;
    final plan = TouchInteractionPlan.forTask(
      mode: TrainingMode.numberWall,
      taskKey: 'wall:1-3-1-4-4-8:3',
      answer: 4,
      maxValue: 20,
      wallValues: const [1, 3, 1, 4, 4, 8],
      hiddenWallIndex: 3,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TouchAnswerInteraction(
            plan: plan,
            onAnswer: (value) => answer = value,
          ),
        ),
      ),
    );

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('touch-drag-number-slider')),
    );
    slider.onChanged!(4);
    await tester.pump();

    final card = find.byKey(const ValueKey('touch-number-card-4'));
    final target = find.byKey(const ValueKey('touch-drop-target'));
    final delta = tester.getCenter(target) - tester.getCenter(card);
    await tester.drag(card, delta, touchSlopX: 0, touchSlopY: 0);
    await tester.pumpAndSettle();

    expect(answer, 4);
  });

  testWidgets('structured tasks default to touch and keep keypad fallback', (
    tester,
  ) async {
    final controller = await _controller();

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.missingNumber,
          targetTasks: 2,
          targetCompetency: MicroCompetencyId.numberRelations,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TouchAnswerInteraction), findsOneWidget);
    expect(find.byType(NumberAnswerPad), findsNothing);
    expect(find.byKey(const ValueKey('touch-switch-keypad')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-switch-keypad')));
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);
    expect(find.byType(TouchAnswerInteraction), findsNothing);
    final touchSwitch = find.byKey(const ValueKey('touch-switch-interaction'));
    await tester.scrollUntilVisible(
      touchSwitch,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(touchSwitch, findsOneWidget);
  });

  testWidgets('upper-primary neighbor tasks use the same touch interaction', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.million;

    const exercise = CurriculumExercise(
      mode: TrainingMode.largeNumbers,
      prompt: 'Wie heißt der Nachfolger von 123.456?',
      answer: 123457,
      hint: 'Gehe genau 1 weiter.',
      key: 'large:neighbor:123456:true',
      maxAnswerValue: 1000000,
      method: 'Im Zahlenraum orientieren',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.largeNumbers,
          targetTasks: 2,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    final touch = tester.widget<TouchAnswerInteraction>(
      find.byType(TouchAnswerInteraction),
    );
    expect(touch.plan.startValue, 123456);
    expect(touch.plan.minValue, 123453);
    expect(touch.plan.maxValue, 123459);
    expect(find.byType(NumberAnswerPad), findsNothing);

    final keypadSwitch = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      keypadSwitch,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(keypadSwitch);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);
  });

  test('rich touch planner covers place value, money, and clock', () {
    final place = TouchInteractionPlan.forTask(
      mode: TrainingMode.placeValue,
      taskKey: 'place:47',
      answer: 47,
      maxValue: 100,
    );
    final money = TouchInteractionPlan.forTask(
      mode: TrainingMode.money,
      taskKey: 'money:add:school:5:2',
      answer: 7,
      maxValue: 20,
      answerSuffix: '€',
    );
    final cents = TouchInteractionPlan.forTask(
      mode: TrainingMode.money,
      taskKey: 'money:convert:euro-cent:3',
      answer: 300,
      maxValue: 300,
      answerSuffix: 'ct',
    );
    final clock = TouchInteractionPlan.forTask(
      mode: TrainingMode.clock,
      taskKey: 'clock:3:30',
      answer: 0,
      maxValue: 20,
      choices: const ['3:30 Uhr', '12:00 Uhr', '6:30 Uhr', '3:00 Uhr'],
      clockHour: 3,
      clockMinute: 30,
    );

    expect(place?.kind, TouchInteractionKind.placeValueBuilder);
    expect(place?.maxValue, 100);
    expect(money?.kind, TouchInteractionKind.moneyComposer);
    expect(money?.denominations, containsAll(<int>[1, 2, 5]));
    expect(money?.unitLabel, '€');
    final oneEuroCoins = TouchInteractionPlan.forTask(
      mode: TrainingMode.money,
      taskKey: 'money:coins:one:7',
      answer: 7,
      maxValue: 20,
      answerSuffix: '€',
    );
    expect(oneEuroCoins?.denominations, const <int>[1]);
    expect(cents?.denominations, const <int>[100]);
    expect(cents?.unitLabel, 'ct');
    expect(clock?.kind, TouchInteractionKind.clockSetter);
  });

  testWidgets('place-value touch builder submits tens and ones', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'place:47',
      kind: TouchInteractionKind.placeValueBuilder,
      instruction: 'Baue die Zahl.',
      maxValue: 100,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('touch-place-tens-add')));
      await tester.pump();
    }
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.byKey(const ValueKey('touch-place-ones-add')));
      await tester.pump();
    }
    expect(find.text('4 Zehner + 7 Einer = 47'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-place-submit')));
    expect(answer, 47);
  });

  testWidgets('place-value manipulatives drag only into the matching place', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'place:11',
      kind: TouchInteractionKind.placeValueBuilder,
      instruction: 'Baue die Zahl.',
      maxValue: 100,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    final tenSource = find.byKey(const ValueKey('touch-place-source-10'));
    final oneSource = find.byKey(const ValueKey('touch-place-source-1'));
    final tensTarget = find.byKey(const ValueKey('touch-place-tens-target'));
    final onesTarget = find.byKey(const ValueKey('touch-place-ones-target'));

    await tester.drag(
      tenSource,
      tester.getCenter(tensTarget) - tester.getCenter(tenSource),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      oneSource,
      tester.getCenter(onesTarget) - tester.getCenter(oneSource),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 Zehner + 1 Einer = 11'), findsOneWidget);

    await tester.drag(
      oneSource,
      tester.getCenter(tensTarget) - tester.getCenter(oneSource),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 Zehner + 1 Einer = 11'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-place-submit')));
    expect(answer, 11);
  });

  testWidgets('money touch composer builds and submits an amount', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'money:add:school:5:2',
      kind: TouchInteractionKind.moneyComposer,
      instruction: 'Stelle den Betrag zusammen.',
      maxValue: 20,
      denominations: <int>[1, 2, 5, 10],
      unitLabel: '€',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-money-add-5')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-money-add-2')));
    await tester.pump();
    expect(find.text('7 €'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-money-submit')));
    expect(answer, 7);
  });

  testWidgets('money pieces can be dragged in and dragged back out', (
    tester,
  ) async {
    const plan = TouchInteractionPlan(
      taskKey: 'money:add:school:5:2',
      kind: TouchInteractionKind.moneyComposer,
      instruction: 'Stelle den Betrag zusammen.',
      maxValue: 20,
      denominations: <int>[1, 2, 5, 10],
      unitLabel: '€',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );

    final workspace = find.byKey(const ValueKey('touch-money-workspace'));
    final five = find.byKey(const ValueKey('touch-money-add-5'));
    final two = find.byKey(const ValueKey('touch-money-add-2'));
    await tester.drag(
      five,
      tester.getCenter(workspace) - tester.getCenter(five),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      two,
      tester.getCenter(workspace) - tester.getCenter(two),
    );
    await tester.pumpAndSettle();
    expect(find.text('7 €'), findsOneWidget);

    final placedFive = find.byKey(const ValueKey('touch-money-piece-0'));
    final returnTarget = find.byKey(const ValueKey('touch-money-return'));
    await tester.drag(
      placedFive,
      tester.getCenter(returnTarget) - tester.getCenter(placedFive),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('touch-money-total'))).data,
      '2 €',
    );
    expect(find.byKey(const ValueKey('touch-money-piece-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-money-piece-1')), findsNothing);
  });

  testWidgets('clock touch setter maps the hand setting to the answer choice', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'clock:3:30',
      kind: TouchInteractionKind.clockSetter,
      instruction: 'Stelle die Uhr.',
      answerChoices: <String>['3:30 Uhr', '12:00 Uhr', '6:30 Uhr', '3:00 Uhr'],
      clockHour: 3,
      clockMinute: 30,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    final clock = find.byKey(const ValueKey('touch-clock-drag-surface'));
    final center = tester.getCenter(clock);
    await tester.dragFrom(center, const Offset(70, 0));
    await tester.pump();
    expect(find.text('3:00 Uhr'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-clock-minute-hand')));
    await tester.pump();
    await tester.dragFrom(center, const Offset(0, 70));
    await tester.pump();
    expect(find.text('3:30 Uhr'), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-clock-hour-slider')), findsNothing);
    expect(find.byKey(const ValueKey('touch-clock-minute-slider')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('touch-clock-submit')));
    expect(answer, 0);
  });

  testWidgets('clock hand drag snaps upper-primary minutes to quarter hours', (
    tester,
  ) async {
    const plan = TouchInteractionPlan(
      taskKey: 'clock:7:45',
      kind: TouchInteractionKind.clockSetter,
      instruction: 'Stelle die Uhr.',
      answerChoices: <String>['7:45 Uhr', '7:30 Uhr', '8:00 Uhr', '6:45 Uhr'],
      clockHour: 7,
      clockMinute: 45,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );

    final clock = find.byKey(const ValueKey('touch-clock-drag-surface'));
    final center = tester.getCenter(clock);
    await tester.tap(find.byKey(const ValueKey('touch-clock-minute-hand')));
    await tester.pump();
    await tester.dragFrom(center, const Offset(-70, 0));
    await tester.pump();
    expect(find.text('12:45 Uhr'), findsOneWidget);
  });

  testWidgets(
    'clock tasks default to moving the clock and keep choice fallback',
    (tester) async {
      final controller = await _controller();
      await tester.pumpWidget(
        MaterialApp(
          home: StructuredTrainingScreen(
            controller: controller,
            mode: TrainingMode.clock,
            targetTasks: 2,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TouchAnswerInteraction), findsOneWidget);
      final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
      await tester.scrollUntilVisible(
        fallback,
        320,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(fallback);
      await tester.pumpAndSettle();
      expect(find.text('Lieber auswählen'), findsOneWidget);
      await tester.tap(fallback);
      await tester.pump();
      expect(find.byType(TouchAnswerInteraction), findsNothing);
      expect(
        find.byKey(const ValueKey('touch-switch-interaction')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'rich touch manipulatives stay stable at 200 percent text scale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() async {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.binding.setSurfaceSize(null);
      });

      const plans = <TouchInteractionPlan>[
        TouchInteractionPlan(
          taskKey: 'place:47',
          kind: TouchInteractionKind.placeValueBuilder,
          instruction: 'Baue die Zahl aus Zehnern und Einern zusammen.',
          maxValue: 100,
        ),
        TouchInteractionPlan(
          taskKey: 'money:add:school:5:2',
          kind: TouchInteractionKind.moneyComposer,
          instruction: 'Stelle den Geldbetrag zusammen.',
          maxValue: 20,
          denominations: <int>[1, 2, 5, 10],
          unitLabel: '€',
        ),
        TouchInteractionPlan(
          taskKey: 'clock:3:30',
          kind: TouchInteractionKind.clockSetter,
          instruction: 'Stelle die Uhr ein.',
          answerChoices: <String>[
            '3:30 Uhr',
            '12:00 Uhr',
            '6:30 Uhr',
            '3:00 Uhr',
          ],
          clockHour: 3,
          clockMinute: 30,
        ),
        TouchInteractionPlan(
          taskKey: 'fraction:parts:3:4:20',
          kind: TouchInteractionKind.fractionBuilder,
          instruction: 'Baue gleich große Teile.',
          fractionNumerator: 3,
          fractionDenominator: 4,
          fractionWhole: 20,
          expectedAnswer: 15,
        ),
        TouchInteractionPlan(
          taskKey: 'plan:path:4:3',
          kind: TouchInteractionKind.pathWalker,
          instruction: 'Gehe den Weg.',
          pathRight: 4,
          pathUp: 3,
          expectedAnswer: 7,
        ),
        TouchInteractionPlan(
          taskKey: 'symmetry:Rechteck',
          kind: TouchInteractionKind.symmetryAxes,
          instruction: 'Wähle die Achsen.',
          symmetryShape: 'Rechteck',
          selectionLabels: <String>[
            'Senkrecht',
            'Waagerecht',
            'Diagonal ↘',
            'Diagonal ↙',
          ],
          correctSelectionIndexes: <int>[0, 1],
          expectedAnswer: 2,
        ),
        TouchInteractionPlan(
          taskKey: 'geometry:corners:square',
          kind: TouchInteractionKind.shapeCorners,
          instruction: 'Tippe genau die Ecken an.',
          geometryShape: 'square',
          correctSelectionIndexes: <int>[0, 2, 4, 6],
          expectedAnswer: 4,
        ),
        TouchInteractionPlan(
          taskKey: 'geometry:sides:rectangle',
          kind: TouchInteractionKind.shapeSides,
          instruction: 'Tippe jede gerade Seite an.',
          geometryShape: 'rectangle',
          correctSelectionIndexes: <int>[0, 1, 2, 3],
          expectedAnswer: 4,
        ),
        TouchInteractionPlan(
          taskKey: 'rect:perimeter:beet:8:5',
          kind: TouchInteractionKind.rectanglePerimeterEdges,
          instruction: 'Tippe alle Kanten an.',
          rectangleWidth: 8,
          rectangleHeight: 5,
          correctSelectionIndexes: <int>[0, 1, 2, 3],
          expectedAnswer: 26,
        ),
        TouchInteractionPlan(
          taskKey: 'data:diff:7-3-5-2',
          kind: TouchInteractionKind.dataChartSelection,
          instruction: 'Markiere Rot und Blau.',
          dataValues: <int>[7, 3, 5, 2],
          dataLabels: <String>['Rot', 'Blau', 'Grün', 'Gelb'],
          dataOperation: 'diff',
          expectedAnswer: 4,
          maxValue: 100,
        ),
        TouchInteractionPlan(
          taskKey: 'data:tally:12',
          kind: TouchInteractionKind.tallySelection,
          instruction: 'Zähle die Strichliste.',
          dataValues: <int>[5, 5, 1, 1],
          dataOperation: 'tally',
          expectedAnswer: 12,
        ),
        TouchInteractionPlan(
          taskKey: 'rect:area:beet:20:25',
          kind: TouchInteractionKind.rectangleAreaBuilder,
          instruction: 'Baue die Fläche aus Länge und Breite.',
          rectangleWidth: 20,
          rectangleHeight: 25,
          expectedAnswer: 500,
        ),
      ];

      for (final plan in plans) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TouchAnswerInteraction(
                  plan: plan,
                  onAnswer: _noopAnswer,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: plan.taskKey);
      }
    },
  );

  test('touch planner covers fractions, paths, and symmetry', () {
    final fraction = TouchInteractionPlan.forTask(
      mode: TrainingMode.fractions,
      taskKey: 'fraction:parts:3:4:20',
      answer: 15,
      maxValue: 20,
    );
    final path = TouchInteractionPlan.forTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: 'plan:path:4:3',
      answer: 7,
      maxValue: 40,
    );
    final symmetry = TouchInteractionPlan.forTask(
      mode: TrainingMode.symmetry,
      taskKey: 'symmetry:Rechteck',
      answer: 2,
      maxValue: 6,
    );
    final targetedSymmetry = TouchInteractionPlan.forTask(
      mode: TrainingMode.symmetry,
      taskKey: 'symmetry:target:2:1',
      answer: 3,
      maxValue: 6,
    );
    final corners = TouchInteractionPlan.forTask(
      mode: TrainingMode.geometry,
      taskKey: 'geometry:corners:triangle',
      answer: 3,
      maxValue: 20,
    );
    final sides = TouchInteractionPlan.forTask(
      mode: TrainingMode.geometry,
      taskKey: 'geometry:sides:rectangle',
      answer: 4,
      maxValue: 20,
    );
    final circleSides = TouchInteractionPlan.forTask(
      mode: TrainingMode.geometry,
      taskKey: 'geometry:sides:circle',
      answer: 0,
      maxValue: 20,
    );
    final perimeter = TouchInteractionPlan.forTask(
      mode: TrainingMode.perimeterArea,
      taskKey: 'rect:perimeter:beet:8:5',
      answer: 26,
      maxValue: 2000,
    );
    final area = TouchInteractionPlan.forTask(
      mode: TrainingMode.perimeterArea,
      taskKey: 'rect:area:beet:20:25',
      answer: 500,
      maxValue: 2000,
    );

    expect(fraction?.kind, TouchInteractionKind.fractionBuilder);
    expect(fraction?.fractionNumerator, 3);
    expect(fraction?.fractionDenominator, 4);
    expect(fraction?.fractionWhole, 20);
    expect(path?.kind, TouchInteractionKind.pathWalker);
    expect(path?.pathRight, 4);
    expect(path?.pathUp, 3);
    expect(symmetry?.kind, TouchInteractionKind.symmetryAxes);
    expect(symmetry?.correctSelectionIndexes, const <int>[0, 1]);
    expect(targetedSymmetry?.symmetryShape, 'gleichseitiges Dreieck');
    expect(targetedSymmetry?.correctSelectionIndexes, const <int>[0, 1, 2]);
    expect(corners?.kind, TouchInteractionKind.shapeCorners);
    expect(corners?.geometryShape, 'triangle');
    expect(corners?.correctSelectionIndexes, const <int>[0, 2, 4]);
    expect(sides?.kind, TouchInteractionKind.shapeSides);
    expect(sides?.geometryShape, 'rectangle');
    expect(sides?.correctSelectionIndexes, const <int>[0, 1, 2, 3]);
    expect(circleSides?.kind, TouchInteractionKind.shapeSides);
    expect(circleSides?.correctSelectionIndexes, isEmpty);
    expect(perimeter?.kind, TouchInteractionKind.rectanglePerimeterEdges);
    expect(perimeter?.rectangleWidth, 8);
    expect(perimeter?.rectangleHeight, 5);
    expect(perimeter?.expectedAnswer, 26);
    expect(area?.kind, TouchInteractionKind.rectangleAreaBuilder);
    expect(area?.rectangleWidth, 20);
    expect(area?.rectangleHeight, 25);
    expect(area?.expectedAnswer, 500);
  });

  testWidgets('fraction builder constructs equal parts and submits the result', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'fraction:parts:3:4:20',
      kind: TouchInteractionKind.fractionBuilder,
      instruction: 'Baue gleich große Teile.',
      fractionNumerator: 3,
      fractionDenominator: 4,
      fractionWhole: 20,
      expectedAnswer: 15,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TouchAnswerInteraction(
            plan: plan,
            onAnswer: (value) => answer = value,
          ),
        ),
      ),
    );

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('touch-fraction-part-slider')),
    );
    slider.onChanged!(5);
    await tester.pump();
    expect(find.text('4 × 5 = 20 von 20'), findsOneWidget);
    expect(find.text('3/4 von 20 = 15'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-fraction-piece-0')));
    await tester.tap(find.byKey(const ValueKey('touch-fraction-piece-1')));
    await tester.pump();
    expect(find.text('2 von 4 Teilen markiert'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-fraction-submit')));
    expect(answer, isNot(15));

    await tester.tap(find.byKey(const ValueKey('touch-fraction-piece-2')));
    await tester.pump();
    expect(find.text('3 von 4 Teilen markiert'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-fraction-submit')));
    expect(answer, 15);
  });

  testWidgets('fraction builder rejects a numerically matching wrong marking', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'fraction:half:20',
      kind: TouchInteractionKind.fractionBuilder,
      instruction: 'Baue die Hälfte.',
      fractionNumerator: 1,
      fractionDenominator: 2,
      fractionWhole: 20,
      expectedAnswer: 10,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TouchAnswerInteraction(
            plan: plan,
            onAnswer: (value) => answer = value,
          ),
        ),
      ),
    );

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('touch-fraction-part-slider')),
    );
    slider.onChanged!(5);
    await tester.pump();
    for (final index in <int>[0, 1]) {
      await tester.tap(find.byKey(ValueKey('touch-fraction-piece-$index')));
    }
    await tester.pump();
    expect(find.text('2 von 2 Teilen markiert'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-fraction-submit')));
    expect(answer, isNot(10));

    slider.onChanged!(10);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-fraction-piece-1')));
    await tester.pump();
    expect(find.text('1 von 2 Teilen markiert'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-fraction-submit')));
    expect(answer, 10);
  });

  testWidgets('path walker requires the described route, not only the same sum', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'plan:path:2:1',
      kind: TouchInteractionKind.pathWalker,
      instruction: 'Gehe den Weg.',
      pathRight: 2,
      pathUp: 1,
      expectedAnswer: 3,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-path-right')));
    await tester.tap(find.byKey(const ValueKey('touch-path-right')));
    await tester.tap(find.byKey(const ValueKey('touch-path-up')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-path-submit')));
    expect(answer, 3);

    await tester.tap(find.byKey(const ValueKey('touch-path-reset')));
    await tester.tap(find.byKey(const ValueKey('touch-path-right')));
    await tester.tap(find.byKey(const ValueKey('touch-path-up')));
    await tester.tap(find.byKey(const ValueKey('touch-path-up')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-path-submit')));
    expect(answer, isNot(3));
  });

  testWidgets('symmetry touch validates the selected axes, not only their count', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'symmetry:Rechteck',
      kind: TouchInteractionKind.symmetryAxes,
      instruction: 'Wähle die Achsen.',
      symmetryShape: 'Rechteck',
      selectionLabels: <String>[
        'Senkrecht',
        'Waagerecht',
        'Diagonal ↘',
        'Diagonal ↙',
      ],
      correctSelectionIndexes: <int>[0, 1],
      expectedAnswer: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-symmetry-axis-2')));
    await tester.tap(find.byKey(const ValueKey('touch-symmetry-axis-3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-symmetry-submit')));
    expect(answer, isNot(2));

    await tester.tap(find.byKey(const ValueKey('touch-symmetry-axis-2')));
    await tester.tap(find.byKey(const ValueKey('touch-symmetry-axis-3')));
    await tester.tap(find.byKey(const ValueKey('touch-symmetry-axis-0')));
    await tester.tap(find.byKey(const ValueKey('touch-symmetry-axis-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-symmetry-submit')));
    expect(answer, 2);
  });

  testWidgets('shape corners require exact vertices, not only the same count', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'geometry:corners:triangle',
      kind: TouchInteractionKind.shapeCorners,
      instruction: 'Tippe genau die Ecken an.',
      geometryShape: 'triangle',
      correctSelectionIndexes: <int>[0, 2, 4],
      expectedAnswer: 3,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    for (final index in <int>[1, 3, 5]) {
      await tester.tap(find.byKey(ValueKey('touch-shape-point-$index')));
    }
    await tester.tap(find.byKey(const ValueKey('touch-shape-corners-submit')));
    expect(answer, isNot(3));

    for (final index in <int>[1, 3, 5]) {
      await tester.tap(find.byKey(ValueKey('touch-shape-point-$index')));
    }
    for (final index in <int>[0, 2, 4]) {
      await tester.tap(find.byKey(ValueKey('touch-shape-point-$index')));
    }
    await tester.tap(find.byKey(const ValueKey('touch-shape-corners-submit')));
    expect(answer, 3);
  });

  testWidgets('shape sides are marked directly on the figure', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'geometry:sides:triangle',
      kind: TouchInteractionKind.shapeSides,
      instruction: 'Tippe jede gerade Seite an.',
      geometryShape: 'triangle',
      correctSelectionIndexes: <int>[0, 1, 2],
      expectedAnswer: 3,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-shape-side-0')));
    await tester.tap(find.byKey(const ValueKey('touch-shape-side-1')));
    await tester.pump();
    expect(find.text('2 Seiten markiert'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-shape-sides-submit')));
    expect(answer, isNot(3));

    await tester.tap(find.byKey(const ValueKey('touch-shape-side-2')));
    await tester.pump();
    expect(find.text('3 Seiten markiert'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-shape-sides-submit')));
    expect(answer, 3);
  });

  testWidgets('circle side task submits zero without fake straight edges', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'geometry:sides:circle',
      kind: TouchInteractionKind.shapeSides,
      instruction: 'Prüfe, ob der Kreis gerade Seiten hat.',
      geometryShape: 'circle',
      correctSelectionIndexes: <int>[],
      expectedAnswer: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TouchAnswerInteraction(
            plan: plan,
            onAnswer: (value) => answer = value,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('touch-shape-side-0')), findsNothing);
    expect(find.text('Keine gerade Seite zum Markieren'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-shape-sides-submit')));
    expect(answer, 0);
  });

  testWidgets('perimeter touch adds the four actual rectangle edges', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'rect:perimeter:beet:8:5',
      kind: TouchInteractionKind.rectanglePerimeterEdges,
      instruction: 'Tippe alle Kanten an.',
      rectangleWidth: 8,
      rectangleHeight: 5,
      correctSelectionIndexes: <int>[0, 1, 2, 3],
      expectedAnswer: 26,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    for (final index in <int>[0, 1, 2]) {
      await tester.tap(find.byKey(ValueKey('touch-perimeter-edge-$index')));
    }
    await tester.pump();
    expect(find.text('Markierte Kanten zusammen: 21 cm'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-perimeter-submit')));
    expect(answer, 21);

    await tester.tap(find.byKey(const ValueKey('touch-perimeter-edge-3')));
    await tester.pump();
    expect(find.text('Markierte Kanten zusammen: 26 cm'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-perimeter-submit')));
    expect(answer, 26);
  });

  testWidgets('area builder validates both rectangle factors, not only product', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'rect:area:beet:8:3',
      kind: TouchInteractionKind.rectangleAreaBuilder,
      instruction: 'Baue das Rechteck.',
      rectangleWidth: 8,
      rectangleHeight: 3,
      expectedAnswer: 24,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    tester.widget<Slider>(
      find.byKey(const ValueKey('touch-area-columns-slider')),
    ).onChanged!(6);
    await tester.pump();
    tester.widget<Slider>(
      find.byKey(const ValueKey('touch-area-rows-slider')),
    ).onChanged!(4);
    await tester.pump();
    expect(find.text('6 Spalten × 4 Reihen = 24 cm²'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-area-submit')));
    expect(answer, isNot(24));

    tester.widget<Slider>(
      find.byKey(const ValueKey('touch-area-columns-slider')),
    ).onChanged!(8);
    await tester.pump();
    tester.widget<Slider>(
      find.byKey(const ValueKey('touch-area-rows-slider')),
    ).onChanged!(3);
    await tester.pump();
    expect(find.text('8 Spalten × 3 Reihen = 24 cm²'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-area-submit')));
    expect(answer, 24);
  });

  testWidgets('perimeter curriculum defaults to touch and keeps keypad fallback', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.hundred;
    const exercise = CurriculumExercise(
      mode: TrainingMode.perimeterArea,
      prompt: 'Beet: 8 cm lang und 5 cm breit. Wie groß ist der Umfang?',
      answer: 26,
      hint: 'Addiere alle vier Seiten.',
      key: 'rect:perimeter:beet:8:5',
      answerSuffix: 'cm',
      maxAnswerValue: 2000,
      method: 'Umfang',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.perimeterArea,
          targetTasks: 2,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TouchAnswerInteraction), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-perimeter-preview')), findsOneWidget);
    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      fallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);
  });

  testWidgets('area curriculum defaults to factor builder and keeps keypad fallback', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.hundred;
    const exercise = CurriculumExercise(
      mode: TrainingMode.perimeterArea,
      prompt: 'Beet: 20 cm lang und 25 cm breit. Wie groß ist die Fläche?',
      answer: 500,
      hint: 'Länge mal Breite.',
      key: 'rect:area:beet:20:25',
      answerSuffix: 'cm²',
      maxAnswerValue: 2000,
      method: 'Flächeninhalt',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.perimeterArea,
          targetTasks: 2,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TouchAnswerInteraction), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-area-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-area-columns-slider')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-area-rows-slider')), findsOneWidget);
    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      fallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);
  });

  testWidgets('fraction curriculum task defaults to touch and keeps keypad fallback', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.hundred;
    const exercise = CurriculumExercise(
      mode: TrainingMode.fractions,
      prompt: 'Wie viel sind 3/4 von 20?',
      answer: 15,
      hint: 'Teile zuerst in vier gleich große Teile.',
      key: 'fraction:parts:3:4:20',
      maxAnswerValue: 20,
      method: 'Bruchteile als gleich große Teile',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.fractions,
          targetTasks: 2,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TouchAnswerInteraction), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-fraction-part-slider')), findsOneWidget);
    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      fallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);
  });

  test('data touch planner covers targeted chart reading and tally blocks', () {
    final chart = TouchInteractionPlan.forTask(
      mode: TrainingMode.dataCharts,
      taskKey: 'data:max:3-8-5-2',
      answer: 8,
      maxValue: 100,
      targetCompetency: MicroCompetencyId.dataReading,
    );
    final untargetedChart = TouchInteractionPlan.forTask(
      mode: TrainingMode.dataCharts,
      taskKey: 'data:max:3-8-5-2',
      answer: 8,
      maxValue: 100,
    );
    final tally = TouchInteractionPlan.forTask(
      mode: TrainingMode.dataCharts,
      taskKey: 'data:tally:12',
      answer: 12,
      maxValue: 50,
      targetCompetency: MicroCompetencyId.tallyTableReading,
    );

    expect(chart?.kind, TouchInteractionKind.dataChartSelection);
    expect(chart?.dataValues, const <int>[3, 8, 5, 2]);
    expect(chart?.dataOperation, 'max');
    expect(untargetedChart?.kind, TouchInteractionKind.dataChartSelection);
    expect(tally?.kind, TouchInteractionKind.tallySelection);
    expect(tally?.dataValues, const <int>[5, 5, 1, 1]);
  });

  testWidgets('targeted chart touch requires the relevant bars', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'data:diff:7-3-5-2',
      kind: TouchInteractionKind.dataChartSelection,
      instruction: 'Markiere Rot und Blau.',
      dataValues: <int>[7, 3, 5, 2],
      dataLabels: <String>['Rot', 'Blau', 'Grün', 'Gelb'],
      dataOperation: 'diff',
      expectedAnswer: 4,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-data-bar-0')));
    await tester.tap(find.byKey(const ValueKey('touch-data-bar-2')));
    tester.widget<NumberAnswerPad>(
      find.byKey(const ValueKey('touch-data-number-pad')),
    ).onAnswer(4);
    expect(answer, isNot(4));

    await tester.tap(find.byKey(const ValueKey('touch-data-bar-2')));
    await tester.tap(find.byKey(const ValueKey('touch-data-bar-1')));
    tester.widget<NumberAnswerPad>(
      find.byKey(const ValueKey('touch-data-number-pad')),
    ).onAnswer(4);
    expect(answer, 4);
  });

  testWidgets('chart maximum accepts exactly one highest bar', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'data:max:3-8-5-2',
      kind: TouchInteractionKind.dataChartSelection,
      instruction: 'Markiere den höchsten Balken.',
      dataValues: <int>[3, 8, 5, 2],
      dataLabels: <String>['Rot', 'Blau', 'Grün', 'Gelb'],
      dataOperation: 'max',
      expectedAnswer: 8,
      maxValue: 100,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-data-bar-0')));
    await tester.tap(find.byKey(const ValueKey('touch-data-submit')));
    expect(answer, isNot(8));

    await tester.tap(find.byKey(const ValueKey('touch-data-bar-0')));
    await tester.tap(find.byKey(const ValueKey('touch-data-bar-1')));
    await tester.tap(find.byKey(const ValueKey('touch-data-submit')));
    expect(answer, 8);
  });

  testWidgets('chart sum needs all four bars before numeric answer counts', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'data:sum:3-8-5-2',
      kind: TouchInteractionKind.dataChartSelection,
      instruction: 'Markiere alle Balken.',
      dataValues: <int>[3, 8, 5, 2],
      dataLabels: <String>['Rot', 'Blau', 'Grün', 'Gelb'],
      dataOperation: 'sum',
      expectedAnswer: 18,
      maxValue: 200,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    for (final index in <int>[0, 1, 2]) {
      await tester.tap(find.byKey(ValueKey('touch-data-bar-$index')));
    }
    tester.widget<NumberAnswerPad>(
      find.byKey(const ValueKey('touch-data-number-pad')),
    ).onAnswer(18);
    expect(answer, isNot(18));

    await tester.tap(find.byKey(const ValueKey('touch-data-bar-3')));
    tester.widget<NumberAnswerPad>(
      find.byKey(const ValueKey('touch-data-number-pad')),
    ).onAnswer(18);
    expect(answer, 18);
  });

  testWidgets('tally touch counts five-blocks and remaining strokes', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'data:tally:12',
      kind: TouchInteractionKind.tallySelection,
      instruction: 'Zähle die Strichliste.',
      dataValues: <int>[5, 5, 1, 1],
      dataOperation: 'tally',
      expectedAnswer: 12,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-tally-unit-0')));
    await tester.tap(find.byKey(const ValueKey('touch-tally-unit-1')));
    await tester.pump();
    expect(find.text('Gezählt: 10'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-tally-submit')));
    expect(answer, isNot(12));

    await tester.tap(find.byKey(const ValueKey('touch-tally-unit-2')));
    await tester.tap(find.byKey(const ValueKey('touch-tally-unit-3')));
    await tester.pump();
    expect(find.text('Gezählt: 12'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-tally-submit')));
    expect(answer, 12);
  });

  testWidgets('targeted data curriculum defaults to interactive chart', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    const exercise = CurriculumExercise(
      mode: TrainingMode.dataCharts,
      prompt: 'Um wie viele Stimmen unterscheiden sich Rot und Blau?',
      answer: 4,
      hint: 'Vergleiche die beiden Balken.',
      key: 'data:diff:7-3-5-2',
      maxAnswerValue: 100,
      bars: <CurriculumBar>[
        CurriculumBar('Rot', 7),
        CurriculumBar('Blau', 3),
        CurriculumBar('Grün', 5),
        CurriculumBar('Gelb', 2),
      ],
      method: 'Diagramme vergleichen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.dataCharts,
          targetTasks: 2,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TouchAnswerInteraction), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-data-bar-0')), findsOneWidget);
    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      fallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);
  });

  test('touch planner covers representation sorting and probability outcomes', () {
    final representation = TouchInteractionPlan.forTask(
      mode: TrainingMode.dataCharts,
      taskKey: 'data:representation:2',
      answer: 2,
      maxValue: 100,
      choices: const <String>['Strichliste', 'Tabelle', 'Balkendiagramm'],
    );
    final sure = TouchInteractionPlan.forTask(
      mode: TrainingMode.probability,
      taskKey: 'prob:sure:below:9',
      answer: 0,
      maxValue: 100,
      choices: const <String>['sicher', 'möglich', 'unmöglich'],
    );
    final possible = TouchInteractionPlan.forTask(
      mode: TrainingMode.probability,
      taskKey: 'prob:possible:face:4',
      answer: 1,
      maxValue: 100,
      choices: const <String>['sicher', 'möglich', 'unmöglich'],
    );
    final impossible = TouchInteractionPlan.forTask(
      mode: TrainingMode.probability,
      taskKey: 'prob:impossible:face:9',
      answer: 2,
      maxValue: 100,
      choices: const <String>['sicher', 'möglich', 'unmöglich'],
    );

    expect(representation?.kind, TouchInteractionKind.representationSorter);
    expect(representation?.expectedAnswer, 2);
    expect(sure?.kind, TouchInteractionKind.probabilityOutcomes);
    expect(sure?.correctSelectionIndexes, const <int>[0, 1, 2, 3, 4, 5]);
    expect(possible?.correctSelectionIndexes, const <int>[3]);
    expect(impossible?.correctSelectionIndexes, isEmpty);
  });

  testWidgets('representation situation can be dragged to the matching visual tool', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'data:representation:2',
      kind: TouchInteractionKind.representationSorter,
      instruction: 'Ordne die Situation zu.',
      answerChoices: <String>['Strichliste', 'Tabelle', 'Balkendiagramm'],
      expectedAnswer: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    final source = find.byKey(const ValueKey('touch-representation-source'));
    final target = find.byKey(const ValueKey('touch-representation-target-2'));
    final delta = tester.getCenter(target) - tester.getCenter(source);
    await tester.drag(source, delta);
    await tester.pumpAndSettle();
    expect(answer, 2);
  });

  testWidgets('probability touch validates the dice sample space', (tester) async {
    var answer = -1;
    const possible = TouchInteractionPlan(
      taskKey: 'prob:possible:face:4',
      kind: TouchInteractionKind.probabilityOutcomes,
      instruction: 'Markiere passende Würfelergebnisse.',
      selectionLabels: <String>['1', '2', '3', '4', '5', '6'],
      correctSelectionIndexes: <int>[3],
      expectedAnswer: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: possible,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('touch-probability-face-3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-probability-submit')));
    expect(answer, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    answer = -1;
    const impossible = TouchInteractionPlan(
      taskKey: 'prob:impossible:face:9',
      kind: TouchInteractionKind.probabilityOutcomes,
      instruction: 'Markiere passende Würfelergebnisse.',
      selectionLabels: <String>['1', '2', '3', '4', '5', '6'],
      correctSelectionIndexes: <int>[],
      expectedAnswer: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: impossible,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('touch-probability-none')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-probability-submit')));
    expect(answer, 2);
  });

  testWidgets('choice curriculum defaults to touch and keeps button fallback', (
    tester,
  ) async {
    final controller = await _controller();
    const exercise = CurriculumExercise(
      mode: TrainingMode.dataCharts,
      prompt: 'Welche Darstellung eignet sich zum schnellen Vergleichen?',
      answer: 2,
      hint: 'Vergleiche den Zweck.',
      key: 'data:representation:2',
      choices: <String>['Strichliste', 'Tabelle', 'Balkendiagramm'],
      method: 'Passende Datendarstellung wählen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.dataCharts,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TouchAnswerInteraction), findsOneWidget);
    final fallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(
      fallback,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('Strichliste'), findsOneWidget);
    expect(find.text('Tabelle'), findsOneWidget);
    expect(find.text('Balkendiagramm'), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-switch-interaction')), findsOneWidget);
  });

  testWidgets('probability touch stays stable at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'prob:sure:below:9',
      kind: TouchInteractionKind.probabilityOutcomes,
      instruction: 'Markiere alle passenden Würfelergebnisse.',
      selectionLabels: <String>['1', '2', '3', '4', '5', '6'],
      correctSelectionIndexes: <int>[0, 1, 2, 3, 4, 5],
      expectedAnswer: 0,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('touch-probability-submit')), findsOneWidget);
  });

  test('touch planner covers bag comparison and bounded combination grids', () {
    final bag = TouchInteractionPlan.forTask(
      mode: TrainingMode.probability,
      taskKey: 'prob:bag:kugeln:7:4',
      answer: 0,
      maxValue: 100,
      choices: const ['Rot wahrscheinlicher', 'Blau wahrscheinlicher', 'gleich wahrscheinlich'],
      targetCompetency: MicroCompetencyId.probabilityReasoning,
    );
    final combo = TouchInteractionPlan.forTask(
      mode: TrainingMode.combinatorics,
      taskKey: 'combo:clothes:3:2:2',
      answer: 12,
      maxValue: 100,
      targetCompetency: MicroCompetencyId.combinatoricsSystematic,
    );
    final tooLarge = TouchInteractionPlan.forTask(
      mode: TrainingMode.combinatorics,
      taskKey: 'combo:clothes:6:5:2',
      answer: 60,
      maxValue: 100,
      targetCompetency: MicroCompetencyId.combinatoricsSystematic,
    );

    expect(bag?.kind, TouchInteractionKind.probabilityBagComparison);
    expect(bag?.dataValues, const [7, 4]);
    expect(combo?.kind, TouchInteractionKind.combinatoricsGrid);
    expect(combo?.dataValues, const [3, 2, 2]);
    expect(tooLarge, isNull, reason: 'Zu große Kombinationsräume bleiben beim Zahlenfeld.');
  });

  testWidgets('bag comparison submits the visually larger color', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'prob:bag:kugeln:6:3',
      kind: TouchInteractionKind.probabilityBagComparison,
      instruction: 'Vergleiche die Mengen.',
      dataValues: [6, 3],
      dataLabels: ['Rot', 'Blau'],
      expectedAnswer: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('6 Stück'), findsOneWidget);
    expect(find.text('3 Stück'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('touch-bag-marker')),
      tester.getCenter(find.byKey(const ValueKey('touch-bag-target-0'))) -
          tester.getCenter(find.byKey(const ValueKey('touch-bag-marker'))),
    );
    await tester.pump();
    expect(answer, 0);

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-bag-target-1')));
    await tester.pump();
    expect(answer, 1, reason: 'Die visuell kleinere Menge darf nicht als korrekt gelten.');
  });

  testWidgets('combination grid requires every unique combination', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'combo:icecream:2:2:1',
      kind: TouchInteractionKind.combinatoricsGrid,
      instruction: 'Markiere alle Kombinationen.',
      dataValues: [2, 2, 1],
      dataLabels: ['icecream'],
      expectedAnswer: 4,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-combo-0')));
    await tester.tap(find.byKey(const ValueKey('touch-combo-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-combo-submit')));
    expect(answer, isNot(4));

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-combo-2')));
    await tester.tap(find.byKey(const ValueKey('touch-combo-3')));
    await tester.pump();
    expect(find.text('4 von 4 Kombinationen markiert'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-combo-submit')));
    expect(answer, 4);
  });

  testWidgets('bag choices and combinations default to touch with fallback', (tester) async {
    final controller = await _controller();
    const bag = CurriculumExercise(
      mode: TrainingMode.probability,
      prompt: 'Im Beutel liegen 6 rote und 3 blaue Kugeln. Was stimmt?',
      answer: 0,
      hint: 'Vergleiche die Mengen.',
      key: 'prob:bag:kugeln:6:3',
      choices: ['Rot wahrscheinlicher', 'Blau wahrscheinlicher', 'gleich wahrscheinlich'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.probability,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.probabilityReasoning,
          reviewEmphasis: true,
          exerciseGenerator: _FixedCurriculumGenerator(bag),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-bag-marker')), findsOneWidget);
    final choicesSwitch = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(
      choicesSwitch,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(choicesSwitch);
    await tester.pump();
    expect(find.text('Rot wahrscheinlicher'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    const combo = CurriculumExercise(
      mode: TrainingMode.combinatorics,
      prompt: '2 Sorten und 2 Soßen: Wie viele Kombinationen?',
      answer: 4,
      hint: 'Systematisch kombinieren.',
      key: 'combo:icecream:2:2:1',
      maxAnswerValue: 20,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.combinatorics,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.combinatoricsSystematic,
          reviewEmphasis: true,
          exerciseGenerator: _FixedCurriculumGenerator(combo),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-combo-grid')), findsOneWidget);
    final keypadSwitch = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      keypadSwitch,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(keypadSwitch);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);
  });

  testWidgets('combination touch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'combo:symbols:3:2:1',
      kind: TouchInteractionKind.combinatoricsGrid,
      instruction: 'Markiere alle Kombinationen.',
      dataValues: [3, 2, 1],
      dataLabels: ['symbols'],
      expectedAnswer: 6,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('touch-combo-grid')), findsOneWidget);
  });

  test('touch planner covers rounding estimation and volume structure', () {
    final rounding = TouchInteractionPlan.forTask(
      mode: TrainingMode.rounding,
      taskKey: 'round:347:100',
      answer: 300,
      maxValue: 1000,
    );
    final estimation = TouchInteractionPlan.forTask(
      mode: TrainingMode.estimation,
      taskKey: 'estimate:147:262:100',
      answer: 1,
      maxValue: 1000,
      choices: const <String>['300', '400', '500', '600'],
    );
    final volume = TouchInteractionPlan.forTask(
      mode: TrainingMode.volumeCubes,
      taskKey: 'volume:3:2:4',
      answer: 24,
      maxValue: 300,
    );

    expect(rounding?.kind, TouchInteractionKind.roundingNumberLine);
    expect((rounding?.minValue, rounding?.startValue, rounding?.maxValue), (300, 347, 400));
    expect(estimation?.kind, TouchInteractionKind.estimationRounding);
    expect(estimation?.dataValues, const <int>[147, 262, 100, 100, 300]);
    expect(volume?.kind, TouchInteractionKind.volumeLayerBuilder);
    expect(volume?.dataValues, const <int>[3, 2, 4]);
  });

  testWidgets('rounding touch chooses a neighboring place-value endpoint', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'round:347:100',
      kind: TouchInteractionKind.roundingNumberLine,
      instruction: 'Runde auf Hunderter.',
      minValue: 300,
      maxValue: 400,
      startValue: 347,
      expectedAnswer: 300,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Mitte 350'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-rounding-upper')));
    expect(answer, 400);
    await tester.tap(find.byKey(const ValueKey('touch-rounding-lower')));
    expect(answer, 300);
  });

  testWidgets('estimation requires both rounded summands before the result counts', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'estimate:147:262:100',
      kind: TouchInteractionKind.estimationRounding,
      instruction: 'Runde beide Summanden.',
      dataValues: <int>[147, 262, 100, 100, 300],
      answerChoices: <String>['300', '400', '500', '600'],
      expectedAnswer: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-estimate-a-100')));
    await tester.tap(find.byKey(const ValueKey('touch-estimate-b-200')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-estimate-result-1')));
    expect(answer, isNot(1), reason: 'Ein geratenes Endergebnis darf falsches Runden nicht verdecken.');

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-estimate-b-300')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-estimate-result-1')));
    expect(answer, 1);
  });

  testWidgets('volume touch requires the physical layer count and total', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'volume:3:2:4',
      kind: TouchInteractionKind.volumeLayerBuilder,
      instruction: 'Baue vier Schichten.',
      dataValues: <int>[3, 2, 4],
      expectedAnswer: 24,
      maxValue: 300,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    tester.widget<NumberAnswerPad>(
      find.byKey(const ValueKey('touch-volume-number-pad')),
    ).onAnswer(24);
    expect(answer, isNot(24));

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('touch-volume-layer-plus')));
      await tester.pump();
    }
    expect(find.text('4 Schichten'), findsOneWidget);
    tester.widget<NumberAnswerPad>(
      find.byKey(const ValueKey('touch-volume-number-pad')),
    ).onAnswer(24);
    expect(answer, 24);
  });

  testWidgets('rounding estimation and volume curriculum default to touch with fallback', (tester) async {
    final controller = await _controller();
    const rounding = CurriculumExercise(
      mode: TrainingMode.rounding,
      prompt: 'Runde 347 auf Hunderter.',
      answer: 300,
      hint: 'Schau auf die Zehnerstelle.',
      key: 'round:347:100',
      maxAnswerValue: 1000,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.rounding,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(rounding),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-rounding-position')), findsOneWidget);
    final keypadSwitch = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(keypadSwitch, 240, scrollable: find.byType(Scrollable).first);
    await tester.tap(keypadSwitch);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    const estimation = CurriculumExercise(
      mode: TrainingMode.estimation,
      prompt: 'Welcher Überschlag passt zu 147 + 262?',
      answer: 1,
      hint: 'Runde beide Zahlen.',
      key: 'estimate:147:262:100',
      choices: <String>['300', '400', '500', '600'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.estimation,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(estimation),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-estimate-status')), findsOneWidget);
    final choiceSwitch = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(choiceSwitch, 240, scrollable: find.byType(Scrollable).first);
    await tester.tap(choiceSwitch);
    await tester.pump();
    expect(find.text('400'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    const volume = CurriculumExercise(
      mode: TrainingMode.volumeCubes,
      prompt: 'Quader: 3 lang, 2 breit, 4 hoch.',
      answer: 24,
      hint: 'Denke in Schichten.',
      key: 'volume:3:2:4',
      maxAnswerValue: 300,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.volumeCubes,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(volume),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-volume-base-grid')), findsOneWidget);
  });

  testWidgets('rounding and volume touch stay stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    const rounding = TouchInteractionPlan(
      taskKey: 'round:347:100',
      kind: TouchInteractionKind.roundingNumberLine,
      instruction: 'Runde auf Hunderter.',
      minValue: 300,
      maxValue: 400,
      startValue: 347,
      expectedAnswer: 300,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: rounding, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    const volume = TouchInteractionPlan(
      taskKey: 'volume:3:2:4',
      kind: TouchInteractionKind.volumeLayerBuilder,
      instruction: 'Baue vier Schichten.',
      dataValues: <int>[3, 2, 4],
      expectedAnswer: 24,
      maxValue: 300,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: volume, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('touch groups stay scoped to understanding competencies', () {
    final multiplication = TouchInteractionPlan.forTask(
      mode: TrainingMode.multiply,
      taskKey: 'multiply:3:4',
      answer: 12,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.multiplicationGroups,
    );
    final multiplicationFact = TouchInteractionPlan.forTask(
      mode: TrainingMode.multiply,
      taskKey: 'multiply:3:4',
      answer: 12,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.multiplicationFacts,
    );
    final orderedMultiplication = TouchInteractionPlan.forTask(
      mode: TrainingMode.multiply,
      taskKey: 'multiply:5:2',
      answer: 10,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.multiplicationGroups,
    );
    final transferMultiplication = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:transfer:skill:multiplicationGroups:x:rows:5:2',
      answer: 10,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.multiplicationGroups,
    );
    final sharing = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:sharing:children:12:3',
      answer: 4,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.divisionSharing,
    );
    final grouping = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:grouping:blocks:12:4',
      answer: 3,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.divisionSharing,
    );

    final transferGrouping = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:transfer:skill:divisionSharing:divide:packs:12:4',
      answer: 3,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.divisionSharing,
    );
    final transferSharing = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:transfer:skill:divisionSharing:divide:teams:12:3',
      answer: 4,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.divisionSharing,
    );

    expect(multiplication?.kind, TouchInteractionKind.equalGroupsBuilder);
    expect(
      (
        multiplication?.groupCount,
        multiplication?.itemsPerGroup,
        multiplication?.totalItems,
      ),
      (3, 4, 12),
    );
    expect(multiplicationFact, isNull);
    expect(
      (orderedMultiplication?.groupCount, orderedMultiplication?.itemsPerGroup),
      (5, 2),
      reason: 'Der erste Faktor bleibt die Anzahl der Gruppen.',
    );
    expect(
      (
        transferMultiplication?.groupCount,
        transferMultiplication?.itemsPerGroup,
      ),
      (5, 2),
      reason:
          'Die Gruppenstruktur der Sachaufgabe darf nicht vertauscht werden.',
    );
    expect(sharing?.kind, TouchInteractionKind.divisionGroupsBuilder);
    expect(sharing?.divisionGrouping, isFalse);
    expect((sharing?.groupCount, sharing?.itemsPerGroup), (3, 4));
    expect(grouping?.kind, TouchInteractionKind.divisionGroupsBuilder);
    expect(grouping?.divisionGrouping, isTrue);
    expect((grouping?.groupCount, grouping?.itemsPerGroup), (3, 4));
    expect(transferGrouping?.kind, TouchInteractionKind.divisionGroupsBuilder);
    expect(transferGrouping?.divisionGrouping, isTrue);
    expect(
      (transferGrouping?.groupCount, transferGrouping?.itemsPerGroup),
      (3, 4),
    );
    expect(transferSharing?.kind, TouchInteractionKind.divisionGroupsBuilder);
    expect(transferSharing?.divisionGrouping, isFalse);
    expect(
      (transferSharing?.groupCount, transferSharing?.itemsPerGroup),
      (3, 4),
    );
  });

  testWidgets('equal-groups touch requires the actual group structure', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'multiply:3:2',
      kind: TouchInteractionKind.equalGroupsBuilder,
      instruction: 'Baue drei Zweiergruppen.',
      groupCount: 3,
      itemsPerGroup: 2,
      totalItems: 6,
      expectedAnswer: 6,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    for (var index = 0; index < 3; index++) {
      for (var point = 0; point < 2; point++) {
        await tester.tap(find.byKey(ValueKey('touch-equal-group-$index-add')));
        await tester.pump();
      }
    }
    await tester.tap(find.byKey(const ValueKey('touch-equal-groups-submit')));
    expect(answer, 6);

    await tester.pumpWidget(const SizedBox.shrink());
    answer = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );
    for (var point = 0; point < 4; point++) {
      await tester.tap(find.byKey(const ValueKey('touch-equal-group-0-add')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('touch-equal-group-1-add')));
    await tester.tap(find.byKey(const ValueKey('touch-equal-group-2-add')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-equal-groups-submit')));
    expect(answer, isNot(6), reason: 'Nur die Summe 6 darf nicht genügen.');
  });

  testWidgets('division sharing distributes every item equally', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'story:sharing:children:6:3',
      kind: TouchInteractionKind.divisionGroupsBuilder,
      instruction: 'Verteile sechs Dinge auf drei Gruppen.',
      totalItems: 6,
      groupCount: 3,
      itemsPerGroup: 2,
      expectedAnswer: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    for (var index = 0; index < 3; index++) {
      for (var item = 0; item < 2; item++) {
        await tester.tap(
          find.byKey(ValueKey('touch-sharing-group-$index-add')),
        );
        await tester.pump();
      }
    }
    expect(find.text('Noch zu verteilen: 0 von 6'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-sharing-submit')));
    expect(answer, 2);
  });

  testWidgets('division grouping builds complete equal groups', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'story:grouping:blocks:6:2',
      kind: TouchInteractionKind.divisionGroupsBuilder,
      instruction: 'Bilde Zweiergruppen.',
      totalItems: 6,
      groupCount: 3,
      itemsPerGroup: 2,
      divisionGrouping: true,
      expectedAnswer: 3,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    for (var group = 0; group < 3; group++) {
      await tester.tap(find.byKey(const ValueKey('touch-grouping-add')));
      await tester.pump();
    }
    expect(find.text('Gebildete Gruppen: 3 · übrig: 0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-grouping-submit')));
    expect(answer, 3);
  });

  testWidgets('multiplication understanding defaults to touch, facts do not', (
    tester,
  ) async {
    final controller = await _controller();
    controller.facts = [
      MathFact(a: 3, b: 4, operation: MathOperation.multiply),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.multiply,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.multiplicationGroups,
          reviewEmphasis: true,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('touch-answer-interaction')),
      findsOneWidget,
    );
    final keypadSwitch = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      keypadSwitch,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(keypadSwitch);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.multiply,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.multiplicationFacts,
          reviewEmphasis: true,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('touch-answer-interaction')),
      findsNothing,
    );
    expect(find.byType(NumberAnswerPad), findsOneWidget);
  });

  testWidgets('touch answer stays stable at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    const plan = TouchInteractionPlan(
      taskKey: 'neighbor:12:after',
      kind: TouchInteractionKind.numberLine,
      instruction: 'Zieh den Punkt genau einen Schritt weiter.',
      minValue: 9,
      maxValue: 15,
      startValue: 12,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('touch-number-line-slider')),
      findsOneWidget,
    );
  });
}

void _noopAnswer(int value) {}

class _FixedCurriculumGenerator extends CurriculumExerciseGenerator {
  _FixedCurriculumGenerator(this.exercise);

  final CurriculumExercise exercise;

  @override
  CurriculumExercise generate({
    required TrainingMode mode,
    required GradeLevel gradeLevel,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
  }) => exercise;
}
