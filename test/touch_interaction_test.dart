import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/cube_net.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
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

  test('touch planner covers fraction measures and proportional unit value', () {
    final time = TouchInteractionPlan.forTask(
      mode: TrainingMode.fractions,
      taskKey: 'fraction:time',
      answer: 2,
      maxValue: 100,
      choices: const <String>['15 min', '30 min', '45 min', '60 min'],
    );
    final volume = TouchInteractionPlan.forTask(
      mode: TrainingMode.fractions,
      taskKey: 'fraction:volume',
      answer: 0,
      maxValue: 1000,
      choices: const <String>['250 ml', '500 ml', '750 ml', '1000 ml'],
    );
    final proportion = TouchInteractionPlan.forTask(
      mode: TrainingMode.proportionality,
      taskKey: 'proportion:notebooks:3:4:6',
      answer: 18,
      maxValue: 100,
      targetCompetency: MicroCompetencyId.proportionalUnit,
    );

    expect(time?.kind, TouchInteractionKind.fractionMeasure);
    expect(time?.dataValues, const <int>[3, 4, 60, 15]);
    expect(time?.dataOperation, 'time');
    expect(volume?.kind, TouchInteractionKind.fractionMeasure);
    expect(volume?.dataValues, const <int>[1, 4, 1000, 250]);
    expect(volume?.dataOperation, 'volume');
    expect(proportion?.kind, TouchInteractionKind.proportionalUnitBuilder);
    expect(proportion?.dataValues, const <int>[3, 4, 6, 12]);
  });

  testWidgets('fraction measure needs the requested quarters and matching value', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'fraction:time',
      kind: TouchInteractionKind.fractionMeasure,
      instruction: 'Markiere drei Viertel und bestimme die Minuten.',
      answerChoices: <String>['15 min', '30 min', '45 min', '60 min'],
      dataValues: <int>[3, 4, 60, 15],
      dataOperation: 'time',
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

    await tester.tap(find.byKey(const ValueKey('touch-fraction-measure-choice-2')));
    final submit = find.byKey(const ValueKey('touch-fraction-measure-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(answer, isNot(2), reason: 'Nur die richtige Antwortoption darf ohne drei Viertel nicht genügen.');

    answer = -1;
    for (var index = 0; index < 3; index++) {
      final part = find.byKey(ValueKey('touch-fraction-measure-part-$index'));
      await tester.ensureVisible(part);
      await tester.tap(part);
    }
    await tester.pump();
    expect(find.text('3 von 4 Teilen markiert'), findsOneWidget);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(answer, 2);
  });

  testWidgets('proportional touch requires correct unit value before total counts', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'proportion:notebooks:3:4:5',
      kind: TouchInteractionKind.proportionalUnitBuilder,
      instruction: 'Bestimme zuerst eine Einheit.',
      dataValues: <int>[3, 4, 5, 12],
      dataLabels: <String>['notebooks'],
      expectedAnswer: 15,
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

    tester.widget<Slider>(find.byKey(const ValueKey('touch-proportion-unit-slider'))).onChanged!(2);
    await tester.pump();
    tester.widget<NumberAnswerPad>(find.byKey(const ValueKey('touch-proportion-number-pad'))).onAnswer(15);
    expect(answer, isNot(15));

    answer = -1;
    tester.widget<Slider>(find.byKey(const ValueKey('touch-proportion-unit-slider'))).onChanged!(3);
    await tester.pump();
    expect(find.text('Wert für 1 Einheit: 3 €'), findsOneWidget);
    tester.widget<NumberAnswerPad>(find.byKey(const ValueKey('touch-proportion-number-pad'))).onAnswer(15);
    expect(answer, 15);
  });

  testWidgets('fraction measure and proportionality default to touch with fallback', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.hundred;
    const fraction = CurriculumExercise(
      mode: TrainingMode.fractions,
      prompt: 'Wie lange sind 3/4 Stunde?',
      answer: 2,
      hint: 'Eine Stunde hat 60 Minuten.',
      key: 'fraction:time',
      choices: <String>['15 min', '30 min', '45 min', '60 min'],
      method: 'Bruchteile bei Größen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.fractions,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(fraction),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-fraction-measure-part-0')), findsOneWidget);
    final choicesFallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(
      choicesFallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(choicesFallback);
    await tester.pump();
    expect(find.text('45 min'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    const proportion = CurriculumExercise(
      mode: TrainingMode.proportionality,
      prompt: '4 Hefte kosten 12 €. Was kosten 5 Hefte?',
      answer: 15,
      hint: 'Bestimme zuerst den Wert für 1 Einheit.',
      key: 'proportion:notebooks:3:4:5',
      answerSuffix: '€',
      maxAnswerValue: 100,
      method: 'Einfache Zuordnung',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.proportionality,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(proportion),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-proportion-unit-slider')), findsOneWidget);
    final keypadFallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      keypadFallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(keypadFallback);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);
  });

  testWidgets('fraction measure and proportional touch stay stable at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const fraction = TouchInteractionPlan(
      taskKey: 'fraction:volume',
      kind: TouchInteractionKind.fractionMeasure,
      instruction: 'Teile einen Liter in vier gleiche Viertel.',
      answerChoices: <String>['250 ml', '500 ml', '750 ml', '1000 ml'],
      dataValues: <int>[1, 4, 1000, 250],
      dataOperation: 'volume',
      expectedAnswer: 0,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: fraction, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    const proportion = TouchInteractionPlan(
      taskKey: 'proportion:tickets:4:5:8',
      kind: TouchInteractionKind.proportionalUnitBuilder,
      instruction: 'Bestimme zuerst den Wert einer Karte.',
      dataValues: <int>[4, 5, 8, 20],
      dataLabels: <String>['tickets'],
      expectedAnswer: 32,
      maxValue: 100,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: proportion, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
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

  test('touch planner covers observed experiments and relative frequency', () {
    final compare = TouchInteractionPlan.forTask(
      mode: TrainingMode.probability,
      taskKey: 'prob:experiment:compare:30:18:12',
      answer: 0,
      maxValue: 100,
      choices: const <String>[
        'Rot kam häufiger vor',
        'Blau kam häufiger vor',
        'beide gleich oft',
      ],
      targetCompetency: MicroCompetencyId.probabilityExperiment,
    );
    final relative = TouchInteractionPlan.forTask(
      mode: TrainingMode.probability,
      taskKey: 'prob:experiment:relative:40:11',
      answer: 0,
      maxValue: 100,
      choices: const <String>['28 %', '33 %', '23 %', '48 %'],
      targetCompetency: MicroCompetencyId.probabilityExperiment,
    );

    expect(compare?.kind, TouchInteractionKind.probabilityExperimentComparison);
    expect(compare?.dataValues, const <int>[30, 18, 12]);
    expect(relative?.kind, TouchInteractionKind.probabilityRelativeHundredGrid);
    expect(relative?.dataValues, const <int>[40, 11, 28]);
  });

  testWidgets('observed experiment compares frequencies without predicting', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'prob:experiment:compare:30:18:12',
      kind: TouchInteractionKind.probabilityExperimentComparison,
      instruction: 'Vergleiche nur die beobachteten Häufigkeiten.',
      dataValues: <int>[30, 18, 12],
      answerChoices: <String>[
        'Rot kam häufiger vor',
        'Blau kam häufiger vor',
        'beide gleich oft',
      ],
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

    expect(find.text('18 von 30'), findsOneWidget);
    expect(find.text('12 von 30'), findsOneWidget);
    final source = find.byKey(const ValueKey('touch-experiment-marker'));
    final target = find.byKey(const ValueKey('touch-experiment-target-0'));
    await tester.drag(source, tester.getCenter(target) - tester.getCenter(source));
    await tester.pumpAndSettle();
    expect(answer, 0);

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-experiment-target-1')));
    await tester.pump();
    expect(answer, 1);
  });

  testWidgets('relative frequency must match the hundred grid percentage', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'prob:experiment:relative:40:11',
      kind: TouchInteractionKind.probabilityRelativeHundredGrid,
      instruction: 'Übertrage den Anteil auf 100.',
      dataValues: <int>[40, 11, 28],
      answerChoices: <String>['28 %', '33 %', '23 %', '48 %'],
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

    final cell27 = find.byKey(const ValueKey('touch-relative-cell-26'));
    final cell28 = find.byKey(const ValueKey('touch-relative-cell-27'));
    final submit = find.byKey(const ValueKey('touch-relative-submit'));
    await tester.ensureVisible(cell27);
    await tester.tap(cell27);
    await tester.pump();
    expect(find.text('Auf 100 übertragen: 27 von 100'), findsOneWidget);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(answer, isNot(0), reason: '27,5 Prozent darf nicht auf 27 Prozent abgeschnitten werden.');

    answer = -1;
    await tester.ensureVisible(cell28);
    await tester.tap(cell28);
    await tester.pump();
    expect(find.text('Auf 100 übertragen: 28 von 100'), findsOneWidget);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(answer, 0);
  });

  testWidgets('relative-frequency curriculum defaults to touch and keeps choices', (tester) async {
    final controller = await _controller();
    const exercise = CurriculumExercise(
      mode: TrainingMode.probability,
      prompt: 'Bei 40 Versuchen trat Rot 11-mal auf. Welcher Prozentwert passt am besten?',
      answer: 0,
      hint: 'Übertrage den Anteil auf 100.',
      key: 'prob:experiment:relative:40:11',
      choices: <String>['28 %', '33 %', '23 %', '48 %'],
      method: 'Relative Häufigkeit beobachten',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.probability,
          targetTasks: 1,
          reviewEmphasis: true,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-relative-grid')), findsOneWidget);
    final fallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(
      fallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('28 %'), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-switch-interaction')), findsOneWidget);
  });

  testWidgets('experiment touch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    const relative = TouchInteractionPlan(
      taskKey: 'prob:experiment:relative:40:11',
      kind: TouchInteractionKind.probabilityRelativeHundredGrid,
      instruction: 'Übertrage den Anteil auf 100.',
      dataValues: <int>[40, 11, 28],
      answerChoices: <String>['28 %', '33 %', '23 %', '48 %'],
      expectedAnswer: 0,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: relative, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    const compare = TouchInteractionPlan(
      taskKey: 'prob:experiment:compare:30:18:12',
      kind: TouchInteractionKind.probabilityExperimentComparison,
      instruction: 'Vergleiche die beobachteten Häufigkeiten.',
      dataValues: <int>[30, 18, 12],
      answerChoices: <String>[
        'Rot kam häufiger vor',
        'Blau kam häufiger vor',
        'beide gleich oft',
      ],
      expectedAnswer: 0,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: compare, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
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

    final independentSharing = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:sharing:children:12:3',
      answer: 4,
      maxValue: 20,
    );
    final independentGrouping = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:grouping:blocks:12:4',
      answer: 3,
      maxValue: 20,
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
    expect(independentSharing?.kind, TouchInteractionKind.divisionGroupsBuilder);
    expect(independentSharing?.divisionGrouping, isFalse);
    expect((independentSharing?.groupCount, independentSharing?.itemsPerGroup), (3, 4));
    expect(independentGrouping?.kind, TouchInteractionKind.divisionGroupsBuilder);
    expect(independentGrouping?.divisionGrouping, isTrue);
    expect((independentGrouping?.groupCount, independentGrouping?.itemsPerGroup), (3, 4));
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

  test('touch planner covers unit conversion duration and calendar structure', () {
    final metres = TouchInteractionPlan.forTask(
      mode: TrainingMode.advancedMeasures,
      taskKey: 'length:m:3',
      answer: 300,
      maxValue: 5000,
      answerSuffix: 'cm',
    );
    final seconds = TouchInteractionPlan.forTask(
      mode: TrainingMode.advancedMeasures,
      taskKey: 'time:seconds:sec-to-min:180',
      answer: 3,
      maxValue: 20,
      answerSuffix: 'min',
    );
    final weeks = TouchInteractionPlan.forTask(
      mode: TrainingMode.timeDurations,
      taskKey: 'duration:weeks:4',
      answer: 28,
      maxValue: 50,
      answerSuffix: 'Tage',
    );
    final duration = TouchInteractionPlan.forTask(
      mode: TrainingMode.timeDurations,
      taskKey: 'duration:465:90',
      answer: 90,
      maxValue: 240,
      answerSuffix: 'min',
    );
    final calendar = TouchInteractionPlan.forTask(
      mode: TrainingMode.timeDurations,
      taskKey: 'calendar:add:April:10:7',
      answer: 0,
      maxValue: 100,
      choices: const <String>['17. April', '16. April', '18. April', '10. April'],
    );

    expect(metres?.kind, TouchInteractionKind.unitConversionMachine);
    expect(metres?.dataValues, const <int>[3, 100]);
    expect(metres?.dataLabels, const <String>['m', 'cm']);
    expect(metres?.correctSelectionIndexes, const <int>[2]);
    expect(seconds?.kind, TouchInteractionKind.unitConversionMachine);
    expect(seconds?.dataOperation, 'divide');
    expect(seconds?.correctSelectionIndexes, const <int>[0]);
    expect(weeks?.kind, TouchInteractionKind.unitConversionMachine);
    expect(weeks?.correctSelectionIndexes, const <int>[2]);
    expect(duration?.kind, TouchInteractionKind.durationTimeline);
    expect(duration?.dataValues, const <int>[465, 555]);
    expect(calendar?.kind, TouchInteractionKind.calendarStepper);
    expect(calendar?.dataValues, const <int>[10, 7, 30]);
  });

  testWidgets('unit conversion needs the correct relation before the result counts', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'length:m:3',
      kind: TouchInteractionKind.unitConversionMachine,
      instruction: 'Wähle die Umrechnung.',
      dataValues: <int>[3, 100],
      dataLabels: <String>['m', 'cm'],
      dataOperation: 'multiply',
      answerChoices: <String>['÷ 100', '× 10', '× 100'],
      correctSelectionIndexes: <int>[2],
      expectedAnswer: 300,
      maxValue: 5000,
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

    await tester.tap(find.byKey(const ValueKey('touch-conversion-choice-0')));
    await tester.pump();
    tester.widget<NumberAnswerPad>(
      find.byKey(const ValueKey('touch-conversion-pad')),
    ).onAnswer(300);
    expect(answer, isNot(300));

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-conversion-choice-2')));
    await tester.pump();
    tester.widget<NumberAnswerPad>(
      find.byKey(const ValueKey('touch-conversion-pad')),
    ).onAnswer(300);
    expect(answer, 300);
  });

  testWidgets('duration timeline must reach the end with the counted minutes', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'duration:465:90',
      kind: TouchInteractionKind.durationTimeline,
      instruction: 'Gehe vom Start zum Ende.',
      dataValues: <int>[465, 555],
      expectedAnswer: 90,
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

    await tester.tap(find.byKey(const ValueKey('touch-duration-step-60')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-duration-submit')));
    expect(answer, isNot(90));

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-duration-reset')));
    await tester.tap(find.byKey(const ValueKey('touch-duration-step-60')));
    await tester.tap(find.byKey(const ValueKey('touch-duration-step-30')));
    await tester.pump();
    expect(find.text('Gezählte Dauer: 90 min'), findsOneWidget);
    expect(find.textContaining('09:15'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('touch-duration-submit')));
    expect(answer, 90);
  });

  testWidgets('calendar stepper checks the actual number of advanced days', (
    tester,
  ) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'calendar:add:April:10:10',
      kind: TouchInteractionKind.calendarStepper,
      instruction: 'Gehe zehn Tage weiter.',
      dataValues: <int>[10, 10, 30],
      dataLabels: <String>['April'],
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

    await tester.tap(find.byKey(const ValueKey('touch-calendar-step-7')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-calendar-submit')));
    expect(answer, isNot(2));

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-calendar-reset')));
    await tester.tap(find.byKey(const ValueKey('touch-calendar-step-7')));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('touch-calendar-step-1')));
    }
    await tester.pump();
    expect(find.text('20. April'), findsOneWidget);
    expect(find.text('10 von 10 Tagen weitergegangen'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-calendar-submit')));
    expect(answer, 2);
  });

  testWidgets('measure time and calendar curriculum default to touch', (
    tester,
  ) async {
    final controller = await _controller();
    const conversion = CurriculumExercise(
      mode: TrainingMode.advancedMeasures,
      prompt: '3 m sind wie viele cm?',
      answer: 300,
      hint: '1 m = 100 cm.',
      key: 'length:m:3',
      answerSuffix: 'cm',
      maxAnswerValue: 5000,
      method: 'Größen umwandeln',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.advancedMeasures,
          targetTasks: 1,
          reviewEmphasis: true,
          exerciseGenerator: _FixedCurriculumGenerator(conversion),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-conversion-relation')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    const duration = CurriculumExercise(
      mode: TrainingMode.timeDurations,
      prompt: 'Beginn: 07:45 Uhr\nEnde: 09:15 Uhr\nWie viele Minuten dauert es?',
      answer: 90,
      hint: 'Rechne in Etappen.',
      key: 'duration:465:90',
      answerSuffix: 'min',
      maxAnswerValue: 240,
      method: 'Zeitdauer berechnen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.timeDurations,
          targetTasks: 1,
          reviewEmphasis: true,
          exerciseGenerator: _FixedCurriculumGenerator(duration),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-duration-current')), findsOneWidget);
    expect(find.byType(TouchAnswerInteraction), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    const calendar = CurriculumExercise(
      mode: TrainingMode.timeDurations,
      prompt: 'Heute ist der 10. April. Welches Datum ist 7 Tage später?',
      answer: 0,
      hint: 'Gehe 7 Tage weiter.',
      key: 'calendar:add:April:10:7',
      choices: <String>['17. April', '16. April', '18. April', '10. April'],
      method: 'Mit Datum und Kalender rechnen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.timeDurations,
          targetTasks: 1,
          reviewEmphasis: true,
          exerciseGenerator: _FixedCurriculumGenerator(calendar),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-calendar-current')), findsOneWidget);
    expect(find.byType(TouchAnswerInteraction), findsOneWidget);
  });

  testWidgets('measure and time touch stay stable at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    const duration = TouchInteractionPlan(
      taskKey: 'duration:465:90',
      kind: TouchInteractionKind.durationTimeline,
      instruction: 'Gehe auf der Zeitlinie bis zum Ende.',
      dataValues: <int>[465, 555],
      expectedAnswer: 90,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: duration, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('touch-duration-submit')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    const calendar = TouchInteractionPlan(
      taskKey: 'calendar:add:April:10:10',
      kind: TouchInteractionKind.calendarStepper,
      instruction: 'Gehe zehn Tage weiter.',
      dataValues: <int>[10, 10, 30],
      dataLabels: <String>['April'],
      expectedAnswer: 0,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: calendar, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('touch-calendar-submit')), findsOneWidget);
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

  test('basic shape name planner keeps shuffled choice indexes', () {
    const choices = <String>['Kreis', 'Dreieck', 'Rechteck', 'Quadrat'];
    final plan = TouchInteractionPlan.forTask(
      mode: TrainingMode.geometry,
      taskKey: 'geometry:name:triangle',
      answer: 1,
      maxValue: 20,
      choices: choices,
    );

    expect(plan?.kind, TouchInteractionKind.geometryRelationChoice);
    expect(plan?.dataOperation, 'basic-shape');
    expect(plan?.answerChoices, choices);
    expect(plan?.correctSelectionIndexes, const <int>[1]);
  });

  testWidgets('basic shape diagrams follow shuffled answer order', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'geometry:name:triangle',
      kind: TouchInteractionKind.geometryRelationChoice,
      instruction: 'Tippe die Form an, die du oben siehst.',
      answerChoices: <String>['Kreis', 'Dreieck', 'Rechteck', 'Quadrat'],
      correctSelectionIndexes: <int>[1],
      dataOperation: 'basic-shape',
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
    await tester.pump();

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .where((painter) => painter?.runtimeType.toString() == '_GeometryChoicePainter')
        .toList();
    expect(painters.length, 4);
    expect((painters[0] as dynamic).label, 'Kreis');
    expect((painters[1] as dynamic).label, 'Dreieck');
    expect((painters[2] as dynamic).label, 'Rechteck');
    expect((painters[3] as dynamic).label, 'Quadrat');
    expect(find.text('Dreieck'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('touch-geometry-option-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-geometry-submit')));
    expect(answer, 0);

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-geometry-option-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-geometry-submit')));
    expect(answer, 1);
  });

  testWidgets('basic geometry names default to diagrams and keep choice fallback', (
    tester,
  ) async {
    final controller = await _controller();
    const exercise = StructuredExercise(
      mode: TrainingMode.geometry,
      prompt: 'Welche Form siehst du?',
      answer: 3,
      hint: 'Achte auf die Begrenzung.',
      key: 'geometry:name:circle',
      choices: <String>['Dreieck', 'Quadrat', 'Rechteck', 'Kreis'],
      shape: ExerciseShape.circle,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.geometry,
          targetTasks: 1,
          exerciseGenerator: _FixedStructuredGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-geometry-options')), findsOneWidget);
    expect(find.text('Dreieck'), findsNothing);
    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      fallback,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('Dreieck'), findsOneWidget);
    expect(find.text('Kreis'), findsOneWidget);
  });

  testWidgets('basic shape diagrams stay stable at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'geometry:name:square',
      kind: TouchInteractionKind.geometryRelationChoice,
      instruction: 'Tippe die Form an, die du oben siehst.',
      answerChoices: <String>['Kreis', 'Dreieck', 'Quadrat', 'Rechteck'],
      correctSelectionIndexes: <int>[2],
      dataOperation: 'basic-shape',
      expectedAnswer: 2,
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

    expect(find.byKey(const ValueKey('touch-geometry-options')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('touch planner covers all geometry relation families', () {
    final cases = <(String, int, List<String>, String)>[
      ('geomrel:lines:parallel:third', 0, const ['parallel', 'senkrecht', 'weder noch'], 'lines'),
      ('geomrel:angle:smaller:reference:third', 1, const ['rechter Winkel', 'spitzer Winkel', 'stumpfer Winkel'], 'angle'),
      ('geomrel:figure:2:third', 2, const ['Quadrat', 'Rechteck', 'gleichseitiges Dreieck', 'gleichschenkliges Dreieck'], 'figure'),
      ('geomrel:circle:diameter:third', 1, const ['Radius', 'Durchmesser', 'Mittelpunkt'], 'circle'),
    ];

    for (final entry in cases) {
      final plan = TouchInteractionPlan.forTask(
        mode: TrainingMode.geometryRelations,
        taskKey: entry.$1,
        answer: entry.$2,
        maxValue: 100,
        choices: entry.$3,
      );
      expect(plan?.kind, TouchInteractionKind.geometryRelationChoice, reason: entry.$1);
      expect(plan?.dataOperation, entry.$4, reason: entry.$1);
      expect(plan?.correctSelectionIndexes, <int>[entry.$2], reason: entry.$1);
    }
  });

  testWidgets('geometry relation submits the tapped diagram rather than a text label', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'geomrel:circle:diameter:third',
      kind: TouchInteractionKind.geometryRelationChoice,
      instruction: 'Tippe die passende Kreiszeichnung an.',
      answerChoices: <String>['Radius', 'Durchmesser', 'Mittelpunkt'],
      correctSelectionIndexes: <int>[1],
      dataOperation: 'circle',
      expectedAnswer: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );

    expect(find.text('Radius'), findsNothing);
    expect(find.text('Durchmesser'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('touch-geometry-option-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-geometry-submit')));
    expect(answer, 0);

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-geometry-option-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-geometry-submit')));
    expect(answer, 1);
  });

  testWidgets('geometry relation curriculum defaults to diagrams and keeps choice fallback', (tester) async {
    final controller = await _controller();
    const exercise = CurriculumExercise(
      mode: TrainingMode.geometryRelations,
      prompt: 'Zwei Geraden haben überall den gleichen Abstand. Wie liegen sie zueinander?',
      answer: 0,
      hint: 'Prüfe den Abstand.',
      key: 'geomrel:lines:parallel:third',
      choices: <String>['parallel', 'senkrecht', 'weder noch'],
      method: 'Lagebeziehungen erkennen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.geometryRelations,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-geometry-options')), findsOneWidget);
    expect(find.text('gleicher Abstand'), findsNothing);
    final fallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(fallback, 240, scrollable: find.byType(Scrollable).first);
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('parallel'), findsOneWidget);
    expect(find.text('senkrecht'), findsOneWidget);
  });

  testWidgets('geometry relation diagrams stay stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'geomrel:figure:3:fourth',
      kind: TouchInteractionKind.geometryRelationChoice,
      instruction: 'Prüfe die Eigenschaften und tippe die passende Figur an.',
      answerChoices: <String>['Quadrat', 'Rechteck', 'gleichseitiges Dreieck', 'gleichschenkliges Dreieck'],
      correctSelectionIndexes: <int>[3],
      dataOperation: 'figure',
      expectedAnswer: 3,
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
    expect(find.byKey(const ValueKey('touch-geometry-option-3')), findsOneWidget);
  });

  test('body property planner covers all bodies and properties', () {
    const counts = <String, Map<String, int>>{
      'Würfel': <String, int>{'Ecken': 8, 'Kanten': 12, 'Flächen': 6},
      'Quader': <String, int>{'Ecken': 8, 'Kanten': 12, 'Flächen': 6},
      'Kugel': <String, int>{'Ecken': 0, 'Kanten': 0, 'Flächen': 1},
      'Zylinder': <String, int>{'Ecken': 0, 'Kanten': 2, 'Flächen': 3},
      'Kegel': <String, int>{'Ecken': 1, 'Kanten': 1, 'Flächen': 2},
      'Pyramide': <String, int>{'Ecken': 5, 'Kanten': 8, 'Flächen': 5},
    };

    for (final bodyEntry in counts.entries) {
      for (final propertyEntry in bodyEntry.value.entries) {
        final plan = TouchInteractionPlan.forTask(
          mode: TrainingMode.geometryBodies,
          taskKey: 'body:${bodyEntry.key}:${propertyEntry.key}',
          answer: propertyEntry.value,
          maxValue: 20,
        );
        expect(
          plan?.kind,
          TouchInteractionKind.bodyPropertySelector,
          reason: '${bodyEntry.key}:${propertyEntry.key}',
        );
        expect(plan?.geometryShape, bodyEntry.key);
        expect(plan?.dataOperation, propertyEntry.key);
        expect(plan?.correctSelectionIndexes, hasLength(propertyEntry.value));
      }
    }

    final cubeNetFaces = TouchInteractionPlan.forTask(
      mode: TrainingMode.geometryBodies,
      taskKey: 'body:cube-net:faces',
      answer: 6,
      maxValue: 20,
    );
    expect(cubeNetFaces?.kind, TouchInteractionKind.cubeNetFaceCounter);
    expect(cubeNetFaces?.dataLabels, hasLength(6));
  });

  testWidgets('all body property touch diagrams expose the real feature count', (
    tester,
  ) async {
    const counts = <String, Map<String, int>>{
      'Würfel': <String, int>{'Ecken': 8, 'Kanten': 12, 'Flächen': 6},
      'Quader': <String, int>{'Ecken': 8, 'Kanten': 12, 'Flächen': 6},
      'Kugel': <String, int>{'Ecken': 0, 'Kanten': 0, 'Flächen': 1},
      'Zylinder': <String, int>{'Ecken': 0, 'Kanten': 2, 'Flächen': 3},
      'Kegel': <String, int>{'Ecken': 1, 'Kanten': 1, 'Flächen': 2},
      'Pyramide': <String, int>{'Ecken': 5, 'Kanten': 8, 'Flächen': 5},
    };

    for (final bodyEntry in counts.entries) {
      for (final propertyEntry in bodyEntry.value.entries) {
        final indexes = List<int>.generate(
          propertyEntry.value,
          (index) => index,
        );
        final plan = TouchInteractionPlan(
          taskKey: 'body:${bodyEntry.key}:${propertyEntry.key}',
          kind: TouchInteractionKind.bodyPropertySelector,
          instruction: 'Prüfe den Körper.',
          geometryShape: bodyEntry.key,
          dataOperation: propertyEntry.key,
          correctSelectionIndexes: indexes,
          expectedAnswer: propertyEntry.value,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TouchAnswerInteraction(plan: plan, onAnswer: _noopAnswer),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull, reason: plan.taskKey);
        expect(find.byKey(const ValueKey('touch-body-preview')), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) => widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                      'touch-body-feature-',
                    ),
          ),
          findsNWidgets(propertyEntry.value),
          reason: plan.taskKey,
        );
      }
    }
  });

  testWidgets('body edges require every actual cube edge', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'body:Würfel:Kanten',
      kind: TouchInteractionKind.bodyPropertySelector,
      instruction: 'Tippe jede Kante an.',
      geometryShape: 'Würfel',
      dataOperation: 'Kanten',
      correctSelectionIndexes: <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
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
    await tester.pump();

    for (var index = 0; index < 11; index++) {
      await tester.tap(find.byKey(ValueKey('touch-body-feature-$index')));
    }
    await tester.tap(find.byKey(const ValueKey('touch-body-submit')));
    expect(answer, 11);

    await tester.tap(find.byKey(const ValueKey('touch-body-feature-11')));
    await tester.tap(find.byKey(const ValueKey('touch-body-submit')));
    expect(answer, 12);
  });

  testWidgets('body surfaces use the unfolded cylinder surfaces', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'body:Zylinder:Flächen',
      kind: TouchInteractionKind.bodyPropertySelector,
      instruction: 'Tippe jede Fläche an.',
      geometryShape: 'Zylinder',
      dataOperation: 'Flächen',
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
    await tester.pump();

    expect(find.text('Zylinder · Flächenmodell'), findsOneWidget);
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(ValueKey('touch-body-feature-$index')));
    }
    await tester.tap(find.byKey(const ValueKey('touch-body-submit')));
    expect(answer, 3);
  });

  testWidgets('zero body properties need an explicit none decision', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'body:Kugel:Ecken',
      kind: TouchInteractionKind.bodyPropertySelector,
      instruction: 'Prüfe die Ecken.',
      geometryShape: 'Kugel',
      dataOperation: 'Ecken',
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
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('touch-body-submit')));
    expect(answer, 1);
    await tester.tap(find.byKey(const ValueKey('touch-body-none')));
    await tester.tap(find.byKey(const ValueKey('touch-body-submit')));
    expect(answer, 0);
  });

  testWidgets('body property curriculum defaults to touch and keeps keypad fallback', (
    tester,
  ) async {
    final controller = await _controller();
    const exercise = CurriculumExercise(
      mode: TrainingMode.geometryBodies,
      prompt: 'Wie viele Flächen hat ein Quader?',
      answer: 6,
      hint: 'Untersuche den Körper.',
      key: 'body:Quader:Flächen',
      maxAnswerValue: 20,
      method: 'Körper und Eigenschaften',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.geometryBodies,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-body-preview')), findsOneWidget);
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

  testWidgets('body property touch stays stable at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'body:Pyramide:Kanten',
      kind: TouchInteractionKind.bodyPropertySelector,
      instruction: 'Tippe jede Kante der Pyramide genau einmal an.',
      geometryShape: 'Pyramide',
      dataOperation: 'Kanten',
      correctSelectionIndexes: <int>[0, 1, 2, 3, 4, 5, 6, 7],
      expectedAnswer: 8,
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
    expect(find.byKey(const ValueKey('touch-body-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-body-feature-7')), findsOneWidget);
  });

  test('cube-net foldability gets a direct touch plan from the encoded net', () {
    final plan = TouchInteractionPlan.forTask(
      mode: TrainingMode.geometryBodies,
      taskKey: 'body:cube-net:fold:yes:local:opposite:1,0;0,1;1,1;2,1;3,1;1,2',
      answer: 0,
      maxValue: 20,
      choices: const <String>['Ja, es lässt sich falten', 'Nein, es lässt sich nicht falten'],
    );

    expect(plan?.kind, TouchInteractionKind.cubeNetFoldChoice);
    expect(plan?.dataLabels, hasLength(6));
    expect(plan?.dataLabels, contains('3,1'));
    expect(plan?.expectedAnswer, 0);
  });

  testWidgets('cube-net touch shows six squares and submits the fold decision', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'body:cube-net:fold:yes:local:opposite:1,0;0,1;1,1;2,1;3,1;1,2',
      kind: TouchInteractionKind.cubeNetFoldChoice,
      instruction: 'Prüfe das Netz.',
      dataLabels: <String>['1,0', '0,1', '1,1', '2,1', '3,1', '1,2'],
      answerChoices: <String>['Ja, es lässt sich falten', 'Nein, es lässt sich nicht falten'],
      expectedAnswer: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-cube-net-grid')), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('touch-cube-net-yes')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-cube-net-submit')));
    expect(answer, 0);
  });

  testWidgets('cube-net curriculum defaults to direct net and keeps choice fallback', (tester) async {
    final controller = await _controller();
    const cells = <GridCell>[
      GridCell(1, 0), GridCell(0, 1), GridCell(1, 1),
      GridCell(2, 1), GridCell(3, 1), GridCell(1, 2),
    ];
    final exercise = CurriculumExercise(
      mode: TrainingMode.geometryBodies,
      prompt: 'Kann dieses Netz zu einem Würfel gefaltet werden?',
      answer: 0,
      hint: 'Prüfe die sechs Flächen.',
      key: 'body:cube-net:fold:yes:local:opposite:1,0;0,1;1,1;2,1;3,1;1,2',
      choices: <String>['Ja, es lässt sich falten', 'Nein, es lässt sich nicht falten'],
      cubeNetCells: cells,
      cubeNetLabels: <GridCell, String>{
        GridCell(0, 1): 'A', GridCell(1, 1): 'B', GridCell(2, 1): 'C',
      },
      method: 'Würfelnetz gedanklich falten',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.geometryBodies,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-cube-net-grid')), findsOneWidget);
    expect(find.text('A'), findsNothing);
    final fallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(fallback, 240, scrollable: find.byType(Scrollable).first);
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Ja, es lässt sich falten'), findsOneWidget);
  });

  testWidgets('cube-net touch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'body:cube-net:fold:no:local:adjacent:0,0;1,0;2,0;0,1;1,1;2,1',
      kind: TouchInteractionKind.cubeNetFoldChoice,
      instruction: 'Prüfe das Netz selbst.',
      dataLabels: <String>['0,0', '1,0', '2,0', '0,1', '1,1', '2,1'],
      answerChoices: <String>['Ja, es lässt sich falten', 'Nein, es lässt sich nicht falten'],
      expectedAnswer: 1,
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
    expect(find.byKey(const ValueKey('touch-cube-net-grid')), findsOneWidget);
  });

  test('large-number touch planner covers compare order decompose and place', () {
    final compare = TouchInteractionPlan.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:compare:54321:54299',
      answer: 1,
      maxValue: 100000,
      choices: const <String>['<', '>', '='],
    );
    expect(compare?.kind, TouchInteractionKind.largeNumberCompare);
    expect(compare?.dataValues, <int>[54321, 54299, 100]);

    final order = TouchInteractionPlan.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:order:120-450-900',
      answer: 2,
      maxValue: 1000,
      choices: const <String>[
        '900 < 450 < 120',
        '450 < 120 < 900',
        '120 < 450 < 900',
      ],
    );
    expect(order?.kind, TouchInteractionKind.largeNumberOrder);
    expect(order?.dataValues, isNot(<int>[120, 450, 900]));
    expect(
      order!.correctSelectionIndexes.map((index) => order.dataValues[index]),
      <int>[120, 450, 900],
    );

    final decompose = TouchInteractionPlan.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:decompose:3042:1000',
      answer: 3042,
      maxValue: 10000,
    );
    expect(decompose?.kind, TouchInteractionKind.largeNumberDecompose);

    final place = TouchInteractionPlan.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:place:58341:1000',
      answer: 8,
      maxValue: 100000,
    );
    expect(place?.kind, TouchInteractionKind.largeNumberPlaceDigit);
    expect(place?.dataValues, <int>[58341, 1000]);
  });

  testWidgets('large compare requires the first differing place and relation', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'large:compare:54321:54299',
      kind: TouchInteractionKind.largeNumberCompare,
      instruction: 'Vergleiche die Stellen.',
      dataValues: <int>[54321, 54299, 100],
      answerChoices: <String>['<', '>', '='],
      expectedAnswer: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-large-compare-place-1000')));
    await tester.tap(find.byKey(const ValueKey('touch-large-compare-relation-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-large-compare-submit')));
    expect(answer, isNot(1));

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-large-compare-place-100')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-large-compare-submit')));
    expect(answer, 1);
  });

  testWidgets('large order validates the complete tapped sequence', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'large:order:120-450-900',
      kind: TouchInteractionKind.largeNumberOrder,
      instruction: 'Ordne.',
      dataValues: <int>[450, 900, 120],
      correctSelectionIndexes: <int>[2, 0, 1],
      answerChoices: <String>['a', 'b', 'c'],
      expectedAnswer: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-large-order-card-0')));
    await tester.tap(find.byKey(const ValueKey('touch-large-order-card-2')));
    await tester.tap(find.byKey(const ValueKey('touch-large-order-card-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-large-order-submit')));
    expect(answer, isNot(2));

    await tester.tap(find.byKey(const ValueKey('touch-large-order-reset')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-large-order-card-2')));
    await tester.tap(find.byKey(const ValueKey('touch-large-order-card-0')));
    await tester.tap(find.byKey(const ValueKey('touch-large-order-card-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-large-order-submit')));
    expect(answer, 2);
  });

  testWidgets('large decompose builds the number from place-value digits', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'large:decompose:3042:1000',
      kind: TouchInteractionKind.largeNumberDecompose,
      instruction: 'Baue die Zahl.',
      dataValues: <int>[3042],
      expectedAnswer: 3042,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('touch-large-digit-plus-1000')));
    }
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('touch-large-digit-plus-10')));
    }
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('touch-large-digit-plus-1')));
    }
    await tester.pump();
    expect(find.text('Gebaut: 3042'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-large-decompose-submit')));
    expect(answer, 3042);
  });

  testWidgets('large place digit requires tapping the requested column', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'large:place:58341:1000',
      kind: TouchInteractionKind.largeNumberPlaceDigit,
      instruction: 'Finde die Stelle.',
      dataValues: <int>[58341, 1000],
      expectedAnswer: 8,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-large-place-100')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-large-place-submit')));
    expect(answer, isNot(8));
    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-large-place-1000')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-large-place-submit')));
    expect(answer, 8);
  });

  testWidgets('large number curriculum defaults to touch and keeps classic fallback', (tester) async {
    final controller = await _controller();
    const exercise = CurriculumExercise(
      mode: TrainingMode.largeNumbers,
      prompt: 'Welches Zeichen passt? 54321 ? 54299',
      answer: 1,
      hint: 'Vergleiche von links.',
      key: 'large:compare:54321:54299',
      choices: <String>['<', '>', '='],
      method: 'Zahlen vergleichen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.largeNumbers,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-large-compare-table')), findsOneWidget);
    final fallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(fallback, 240, scrollable: find.byType(Scrollable).first);
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('>'), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-switch-interaction')), findsOneWidget);
  });

  testWidgets('large number place-value touch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'large:decompose:583041:10000',
      kind: TouchInteractionKind.largeNumberDecompose,
      instruction: 'Baue die Zahl in der Stellenwerttafel.',
      dataValues: <int>[583041],
      expectedAnswer: 583041,
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
    expect(find.byKey(const ValueKey('touch-large-decompose-table')), findsOneWidget);
  });

  test('number-word reading uses a place-value builder but writing stays linguistic', () {
    final read = TouchInteractionPlan.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:word:read:347',
      answer: 1,
      maxValue: 1000,
      choices: const <String>['374', '347', '437', '743'],
    );
    final targeted = TouchInteractionPlan.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:word:read:347',
      answer: 1,
      maxValue: 1000,
      choices: const <String>['374', '347', '437', '743'],
      targetCompetency: MicroCompetencyId.numberWordReading,
    );
    final write = TouchInteractionPlan.forTask(
      mode: TrainingMode.largeNumbers,
      taskKey: 'large:word:write:347',
      answer: 1,
      maxValue: 1000,
      choices: const <String>[
        'dreihundertsiebenundvierzig',
        'dreihundertsiebenundvierzig',
        'vierhundertsiebenunddreißig',
        'siebenhundertdreiundvierzig',
      ],
    );

    expect(read?.kind, TouchInteractionKind.numberWordPlaceValueBuilder);
    expect(read?.dataValues, <int>[347]);
    expect(read?.dataOperation, 'read');
    expect(targeted?.dataOperation, 'read:skip-tens-ones');
    expect(write, isNull);
  });

  testWidgets('number-word builder requires every place including an internal zero', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'large:word:read:305',
      kind: TouchInteractionKind.numberWordPlaceValueBuilder,
      instruction: 'Entschlüssle das Zahlwort.',
      dataValues: <int>[305],
      dataOperation: 'read',
      answerChoices: <String>['350', '305', '503', '35'],
      expectedAnswer: 1,
      maxValue: 1000,
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
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-number-word-submit')), findsOneWidget);
    var submit = tester.widget<FilledButton>(
      find.byKey(const ValueKey('touch-number-word-submit')),
    );
    expect(submit.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('touch-number-word-choice-3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-number-word-choice-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-number-word-choice-4')));
    await tester.pump();
    submit = tester.widget<FilledButton>(
      find.byKey(const ValueKey('touch-number-word-submit')),
    );
    expect(submit.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('touch-number-word-submit')));
    expect(answer, isNot(1));

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-number-word-place-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-number-word-choice-5')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-number-word-submit')));
    expect(answer, 1);
  });

  testWidgets('targeted number-word task reuses checked tens and ones', (tester) async {
    final controller = await _controller();
    const exercise = CurriculumExercise(
      mode: TrainingMode.largeNumbers,
      prompt: 'Welche Zahl bedeutet das Zahlwort? dreihundertsiebenundvierzig',
      answer: 1,
      hint: 'Lies die Stellenwertgruppen.',
      key: 'large:word:read:347',
      choices: <String>['374', '347', '437', '743'],
      method: 'Zahlwort lesen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.largeNumbers,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.numberWordReading,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('4 Zehner und 7 Einer'), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-number-word-table')), findsNothing);
    await tester.tap(find.text('4 Zehner und 7 Einer'));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byKey(const ValueKey('touch-number-word-table')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-number-word-checked-suffix')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('touch-number-word-digit-10'))).data,
      '4',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('touch-number-word-digit-1'))).data,
      '7',
    );

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('touch-number-word-digit-100'))).data,
      '?',
    );
  });

  testWidgets('number-word curriculum defaults to place values and keeps choice fallback', (tester) async {
    final controller = await _controller();
    const exercise = CurriculumExercise(
      mode: TrainingMode.largeNumbers,
      prompt: 'Welche Zahl bedeutet das Zahlwort? dreihundertfünf',
      answer: 1,
      hint: 'Lies die Stellenwertgruppen.',
      key: 'large:word:read:305',
      choices: <String>['350', '305', '503', '35'],
      method: 'Zahlwort lesen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.largeNumbers,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-number-word-table')), findsOneWidget);
    expect(find.text('350'), findsNothing);
    final fallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(
      fallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('350'), findsOneWidget);
    expect(find.text('305'), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-switch-interaction')), findsOneWidget);
  });

  testWidgets('number-word place-value builder stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'large:word:read:583041',
      kind: TouchInteractionKind.numberWordPlaceValueBuilder,
      instruction: 'Entschlüssle das Zahlwort Stelle für Stelle.',
      dataValues: <int>[583041],
      dataOperation: 'read',
      answerChoices: <String>['583401', '583041', '538041', '580341'],
      expectedAnswer: 1,
      maxValue: 1000000,
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
    expect(find.byKey(const ValueKey('touch-number-word-table')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-number-word-choice-9')), findsOneWidget);
  });

  test('written add/sub planner uses a column procedure', () {
    final plus = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:+:47:38',
      answer: 85,
      maxValue: 100,
    );
    final minus = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'written:-:402:187',
      answer: 215,
      maxValue: 1000,
    );

    expect(plus?.kind, TouchInteractionKind.writtenColumnProcedure);
    expect(plus?.dataValues, <int>[47, 38]);
    expect(plus?.dataOperation, '+');
    expect(minus?.kind, TouchInteractionKind.writtenColumnProcedure);
    expect(minus?.dataValues, <int>[402, 187]);
    expect(minus?.dataOperation, '-');
  });

  testWidgets('written addition requires result digit and carry in each column',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'written:+:47:38',
      kind: TouchInteractionKind.writtenColumnProcedure,
      instruction: 'Rechne spaltenweise.',
      dataValues: <int>[47, 38],
      dataOperation: '+',
      expectedAnswer: 85,
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
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('touch-written-digit-5')));
    await tester.tap(find.byKey(const ValueKey('touch-written-regroup-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-column-submit')));
    await tester.pump();
    expect(answer, isNot(85));
    expect(find.textContaining('Übertrag'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('touch-written-regroup-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-column-submit')));
    await tester.pump();
    expect(find.textContaining('Z: 4 + 3 + Übertrag 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-written-digit-8')));
    await tester.tap(find.byKey(const ValueKey('touch-written-regroup-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-column-submit')));
    expect(answer, 85);
  });

  testWidgets('written subtraction carries a borrow across zero columns',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'written:-:402:187',
      kind: TouchInteractionKind.writtenColumnProcedure,
      instruction: 'Rechne spaltenweise.',
      dataValues: <int>[402, 187],
      dataOperation: '-',
      expectedAnswer: 215,
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
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('touch-written-digit-5')));
    await tester.tap(find.byKey(const ValueKey('touch-written-regroup-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-column-submit')));
    await tester.pump();
    expect(answer, isNot(215));

    await tester.tap(find.byKey(const ValueKey('touch-written-regroup-1')));
    await tester.pump();
    expect(find.text('E: 12 − 7'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-written-column-submit')));
    await tester.pump();
    expect(find.text('Z: 9 − 8'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-written-digit-1')));
    await tester.tap(find.byKey(const ValueKey('touch-written-regroup-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-column-submit')));
    await tester.pump();
    expect(find.text('H: 3 − 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-written-digit-2')));
    await tester.tap(find.byKey(const ValueKey('touch-written-regroup-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-column-submit')));
    expect(answer, 215);
  });

  testWidgets('written curriculum defaults to columns and keeps keypad fallback',
      (tester) async {
    final controller = await _controller();
    const exercise = CurriculumExercise(
      mode: TrainingMode.writtenAddSub,
      prompt: 'Rechne schriftlich:\n42\n+ 13',
      answer: 55,
      hint: 'Rechne Stelle für Stelle.',
      key: 'written:+:42:13',
      maxAnswerValue: 100,
      method: 'Schriftliche Addition',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.writtenAddSub,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-written-table')), findsOneWidget);
    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      fallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('Antwort eingeben'), findsOneWidget);
  });

  testWidgets('written column touch stays stable at 200 percent text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'written:+:999:888',
      kind: TouchInteractionKind.writtenColumnProcedure,
      instruction: 'Rechne spaltenweise.',
      dataValues: <int>[999, 888],
      dataOperation: '+',
      expectedAnswer: 1887,
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
    expect(find.byKey(const ValueKey('touch-written-table')), findsOneWidget);
  });

  test('written multiplication and division planners use procedures', () {
    final single = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenMultiply,
      taskKey: 'written:x:237:4',
      answer: 948,
      maxValue: 1000,
    );
    final partial = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenMultiply,
      taskKey: 'written:x:123:14',
      answer: 1722,
      maxValue: 2000,
    );
    final division = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenDivide,
      taskKey: 'written:divide:324:6',
      answer: 54,
      maxValue: 100,
    );
    final rest = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenDivide,
      taskKey: 'written:divide-rest:325:6',
      answer: 0,
      maxValue: 100,
      choices: const <String>[
        '54 Rest 1',
        '55 Rest 1',
        '54 Rest 2',
        '53 Rest 1',
      ],
    );

    expect(single?.kind, TouchInteractionKind.writtenMultiplicationProcedure);
    expect(single?.dataOperation, 'single');
    expect(partial?.kind, TouchInteractionKind.writtenMultiplicationProcedure);
    expect(partial?.dataOperation, 'partial');
    expect(division?.kind, TouchInteractionKind.writtenDivisionProcedure);
    expect(division?.dataOperation, 'exact');
    expect(rest?.kind, TouchInteractionKind.writtenDivisionProcedure);
    expect(rest?.dataOperation, 'rest');
  });

  testWidgets('written multiplication requires each digit and carry',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'written:x:237:4',
      kind: TouchInteractionKind.writtenMultiplicationProcedure,
      instruction: 'Multipliziere spaltenweise.',
      dataValues: <int>[237, 4],
      dataOperation: 'single',
      expectedAnswer: 948,
      maxValue: 1000,
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
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-digit-8')));
    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-carry-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-step-submit')));
    await tester.pump();
    expect(answer, isNot(948));

    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-carry-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-step-submit')));
    await tester.pump();
    expect(find.textContaining('3 × 4 + Übertrag 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-digit-4')));
    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-carry-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-step-submit')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-digit-9')));
    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-carry-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-multiply-step-submit')));
    expect(answer, 948);
  });

  testWidgets('two-digit multiplier builds shifted partial products',
      (tester) async {
    const plan = TouchInteractionPlan(
      taskKey: 'written:x:123:14',
      kind: TouchInteractionKind.writtenMultiplicationProcedure,
      instruction: 'Baue Teilprodukte.',
      dataValues: <int>[123, 14],
      dataOperation: 'partial',
      expectedAnswer: 1722,
      maxValue: 2000,
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

    Future<void> step(int digit, int carry) async {
      await tester.tap(find.byKey(ValueKey('touch-written-multiply-digit-$digit')));
      await tester.tap(find.byKey(ValueKey('touch-written-multiply-carry-$carry')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('touch-written-multiply-step-submit')));
      await tester.pump();
    }

    await step(2, 1);
    await step(9, 0);
    await step(4, 0);
    expect(find.text('Teilprodukt 1: 492'), findsOneWidget);
    await step(3, 0);
    await step(2, 0);
    await step(1, 0);
    expect(find.text('Teilprodukt 2: 1230'), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-written-multiply-total-pad')), findsOneWidget);
  });

  testWidgets('written division validates quotient digit and remainder',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'written:divide:324:6',
      kind: TouchInteractionKind.writtenDivisionProcedure,
      instruction: 'Teile schrittweise.',
      dataValues: <int>[324, 6],
      dataOperation: 'exact',
      expectedAnswer: 54,
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
    await tester.pump();

    expect(find.text('32 ÷ 6'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-written-division-q-5')));
    await tester.tap(find.byKey(const ValueKey('touch-written-division-r-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-division-step-submit')));
    await tester.pump();
    expect(answer, isNot(54));

    await tester.tap(find.byKey(const ValueKey('touch-written-division-r-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-division-step-submit')));
    await tester.pump();
    expect(find.text('24 ÷ 6'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-written-division-q-4')));
    await tester.tap(find.byKey(const ValueKey('touch-written-division-r-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-written-division-step-submit')));
    expect(answer, 54);
  });

  testWidgets('written division preserves a zero quotient digit',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'written:divide:1005:5',
      kind: TouchInteractionKind.writtenDivisionProcedure,
      instruction: 'Teile schrittweise.',
      dataValues: <int>[1005, 5],
      dataOperation: 'exact',
      expectedAnswer: 201,
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
    await tester.pump();

    for (final pair in <(int, int)>[(2, 0), (0, 0), (1, 0)]) {
      await tester.tap(find.byKey(ValueKey('touch-written-division-q-${pair.$1}')));
      await tester.tap(find.byKey(ValueKey('touch-written-division-r-${pair.$2}')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('touch-written-division-step-submit')));
      await tester.pump();
    }
    expect(answer, 201);
  });

  testWidgets('division with rest submits the encoded answer choice',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'written:divide-rest:325:6',
      kind: TouchInteractionKind.writtenDivisionProcedure,
      instruction: 'Teile schrittweise.',
      dataValues: <int>[325, 6],
      dataOperation: 'rest',
      answerChoices: <String>['54 Rest 1', '55 Rest 1', '54 Rest 2'],
      expectedAnswer: 0,
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
    await tester.pump();

    for (final pair in <(int, int)>[(5, 2), (4, 1)]) {
      await tester.tap(find.byKey(ValueKey('touch-written-division-q-${pair.$1}')));
      await tester.tap(find.byKey(ValueKey('touch-written-division-r-${pair.$2}')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('touch-written-division-step-submit')));
      await tester.pump();
    }
    expect(answer, 0);
  });

  testWidgets('written multiply and divide curriculum keep classic fallback',
      (tester) async {
    final controller = await _controller();
    const multiply = CurriculumExercise(
      mode: TrainingMode.writtenMultiply,
      prompt: 'Rechne: 237 × 4',
      answer: 948,
      hint: 'Stelle für Stelle.',
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
          exerciseGenerator: _FixedCurriculumGenerator(multiply),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-written-multiply-table')), findsOneWidget);
    var fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(fallback, 240, scrollable: find.byType(Scrollable).first);
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('Antwort eingeben'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    const division = CurriculumExercise(
      mode: TrainingMode.writtenDivide,
      prompt: 'Rechne schriftlich: 325 ÷ 6',
      answer: 0,
      hint: 'Teile von links nach rechts.',
      key: 'written:divide-rest:325:6',
      choices: <String>['54 Rest 1', '55 Rest 1', '54 Rest 2'],
      method: 'Schriftliche Division mit Rest',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.writtenDivide,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(division),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-written-division-table')), findsOneWidget);
    fallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(fallback, 240, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(fallback);
    await tester.pump();
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('54 Rest 1'), findsOneWidget);
  });

  testWidgets('written multiplication and division stay stable at 200 percent text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'written:divide:1005:5',
      kind: TouchInteractionKind.writtenDivisionProcedure,
      instruction: 'Teile schrittweise.',
      dataValues: <int>[1005, 5],
      dataOperation: 'exact',
      expectedAnswer: 201,
      maxValue: 200,
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
    expect(find.byKey(const ValueKey('touch-written-division-table')), findsOneWidget);
  });

  test('mental strategy planner covers chunks anchor jumps and arithmetic laws', () {
    final mental = TouchInteractionPlan.forTask(
      mode: TrainingMode.mentalStrategies,
      taskKey: 'mental:+:583:247',
      answer: 830,
      maxValue: 1000,
    );
    final targetedMental = TouchInteractionPlan.forTask(
      mode: TrainingMode.mentalStrategies,
      taskKey: 'mental:-:583:247',
      answer: 336,
      maxValue: 1000,
      targetCompetency: MicroCompetencyId.mentalStrategy,
    );
    final strategy = TouchInteractionPlan.forTask(
      mode: TrainingMode.mentalStrategies,
      taskKey: 'process:strategy:Hunderter:196:9:200',
      answer: 0,
      maxValue: 1000,
      choices: const <String>['196 + 4 + 5', '196 + 5 + 4'],
    );
    final associate = TouchInteractionPlan.forTask(
      mode: TrainingMode.arithmeticLaws,
      taskKey: 'law:associate:40:17:60',
      answer: 0,
      maxValue: 1000,
      choices: const <String>[
        'erste und dritte Zahl',
        'erste und zweite Zahl',
        'zweite und dritte Zahl',
      ],
    );
    final commute = TouchInteractionPlan.forTask(
      mode: TrainingMode.arithmeticLaws,
      taskKey: 'law:commute:7:4',
      answer: 7,
      maxValue: 100,
    );
    final distribute = TouchInteractionPlan.forTask(
      mode: TrainingMode.arithmeticLaws,
      taskKey: 'law:distribute:6:47',
      answer: 18,
      maxValue: 1000,
    );

    expect(mental?.kind, TouchInteractionKind.mentalChunkPath);
    expect(mental?.dataValues, <int>[583, 247, 200, 40, 7]);
    expect(targetedMental?.dataOperation, '-:skip-first');
    expect(strategy?.kind, TouchInteractionKind.strategyAnchorJump);
    expect(strategy?.dataValues, <int>[196, 9, 200, 4, 5]);
    expect(associate?.kind, TouchInteractionKind.arithmeticLawStructure);
    expect(associate?.dataOperation, 'associate');
    expect(commute?.dataOperation, 'commute');
    expect(distribute?.dataValues, <int>[6, 47, 50, 3]);
  });

  testWidgets('mental chunks require the correct order before the final result counts',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'mental:+:583:247',
      kind: TouchInteractionKind.mentalChunkPath,
      instruction: 'Rechne in Stellenwertblöcken.',
      dataValues: <int>[583, 247, 200, 40, 7],
      dataOperation: '+',
      expectedAnswer: 830,
      maxValue: 1000,
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
    await tester.pump();

    for (final chunk in <int>[40, 200, 7]) {
      await tester.tap(find.byKey(ValueKey('touch-mental-chunk-$chunk')));
      await tester.pump();
    }
    for (final label in <String>['8', '3', '0', 'OK']) {
      await tester.tap(find.widgetWithText(FilledButton, label));
      await tester.pump();
    }
    expect(answer, isNot(830));

    await tester.tap(find.byKey(const ValueKey('touch-mental-reset')));
    await tester.pump();
    for (final chunk in <int>[200, 40, 7]) {
      await tester.tap(find.byKey(ValueKey('touch-mental-chunk-$chunk')));
      await tester.pump();
    }
    for (final label in <String>['8', '3', '0', 'OK']) {
      await tester.tap(find.widgetWithText(FilledButton, label));
      await tester.pump();
    }
    expect(answer, 830);
  });

  testWidgets('anchor strategy requires the exact jump to the smooth target',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'process:strategy:Hunderter:196:9:200',
      kind: TouchInteractionKind.strategyAnchorJump,
      instruction: 'Finde den ersten Sprung.',
      dataValues: <int>[196, 9, 200, 4, 5],
      expectedAnswer: 2,
      maxValue: 1000,
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
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('touch-strategy-jump-5')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-strategy-submit')));
    expect(answer, isNot(2));

    await tester.tap(find.byKey(const ValueKey('touch-strategy-jump-4')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-strategy-submit')));
    expect(answer, 2);
  });

  testWidgets('associative law requires the advantageous pair', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'law:associate:40:17:60',
      kind: TouchInteractionKind.arithmeticLawStructure,
      instruction: 'Wähle das günstige Paar.',
      dataValues: <int>[40, 17, 60],
      dataOperation: 'associate',
      correctSelectionIndexes: <int>[0, 2],
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
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-law-term-0')));
    await tester.tap(find.byKey(const ValueKey('touch-law-term-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-law-associate-submit')));
    expect(answer, 0);
  });

  testWidgets('commutative law validates the reversed factor order', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'law:commute:7:4',
      kind: TouchInteractionKind.arithmeticLawStructure,
      instruction: 'Vertausche die Faktoren.',
      dataValues: <int>[7, 4],
      dataOperation: 'commute',
      correctSelectionIndexes: <int>[1, 0],
      expectedAnswer: 7,
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
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-law-factor-0')));
    await tester.tap(find.byKey(const ValueKey('touch-law-factor-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-law-commute-submit')));
    expect(answer, isNot(7));

    await tester.tap(find.byKey(const ValueKey('touch-law-commute-reset')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-law-factor-1')));
    await tester.tap(find.byKey(const ValueKey('touch-law-factor-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-law-commute-submit')));
    expect(answer, 7);
  });

  testWidgets('distributive law needs the correct gap and product correction',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'law:distribute:6:47',
      kind: TouchInteractionKind.arithmeticLawStructure,
      instruction: 'Nutze die glatte Zahl.',
      dataValues: <int>[6, 47, 50, 3],
      dataOperation: 'distribute',
      expectedAnswer: 18,
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
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('touch-law-gap-2')));
    await tester.pump();
    for (final label in <String>['1', '2', 'OK']) {
      await tester.tap(find.widgetWithText(FilledButton, label));
      await tester.pump();
    }
    expect(answer, isNot(18));

    await tester.tap(find.byKey(const ValueKey('touch-law-gap-3')));
    await tester.pump();
    for (final label in <String>['1', '8', 'OK']) {
      await tester.tap(find.widgetWithText(FilledButton, label));
      await tester.pump();
    }
    expect(answer, 18);
  });

  testWidgets('mental strategies and laws default to touch and keep fallbacks',
      (tester) async {
    final controller = await _controller();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    const strategy = CurriculumExercise(
      mode: TrainingMode.mentalStrategies,
      prompt: '196 + 9',
      answer: 0,
      hint: 'Erst zur 200.',
      key: 'process:strategy:Hunderter:196:9:200',
      choices: <String>['196 + 4 + 5', '196 + 5 + 4'],
      method: 'Rechenweg auswählen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.mentalStrategies,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(strategy),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-strategy-anchor')), findsOneWidget);
    var fallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(fallback, 220, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(fallback);
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('196 + 4 + 5'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    const law = CurriculumExercise(
      mode: TrainingMode.arithmeticLaws,
      prompt: '6 × 47 = 6 × 50 − ?',
      answer: 18,
      hint: 'Nutze das Distributivgesetz.',
      key: 'law:distribute:6:47',
      maxAnswerValue: 1000,
      method: 'Distributivgesetz',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.arithmeticLaws,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(law),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-law-distribute-structure')), findsOneWidget);
    fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(fallback, 220, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(fallback);
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('Antwort eingeben'), findsOneWidget);
  });

  testWidgets('mental strategy touch stays stable at 200 percent text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'mental:+:583:247',
      kind: TouchInteractionKind.mentalChunkPath,
      instruction: 'Rechne in Stellenwertblöcken.',
      dataValues: <int>[583, 247, 200, 40, 7],
      dataOperation: '+',
      expectedAnswer: 830,
      maxValue: 1000,
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
    expect(find.byKey(const ValueKey('touch-mental-path')), findsOneWidget);
  });

  test('fact-family planner builds additive and multiplicative inverse machines', () {
    final add = TouchInteractionPlan.forTask(
      mode: TrainingMode.factFamilies,
      taskKey: 'family:+:7:5',
      answer: 7,
      maxValue: 20,
    );
    final multiply = TouchInteractionPlan.forTask(
      mode: TrainingMode.factFamilies,
      taskKey: 'family:x:6:4',
      answer: 6,
      maxValue: 100,
    );
    final targeted = TouchInteractionPlan.forTask(
      mode: TrainingMode.factFamilies,
      taskKey: 'family:+:7:5',
      answer: 7,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.inverseRelationship,
    );

    expect(add?.kind, TouchInteractionKind.inverseFamilyMachine);
    expect(add?.dataValues, <int>[7, 5, 12]);
    expect(add?.dataOperation, 'add');
    expect(multiply?.dataValues, <int>[6, 4, 24]);
    expect(multiply?.dataOperation, 'multiply');
    expect(targeted?.dataOperation, 'add:skip-operation');
  });

  testWidgets('fact-family machine rejects a correct number with the wrong inverse operation',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'family:+:7:5',
      kind: TouchInteractionKind.inverseFamilyMachine,
      instruction: 'Drehe die Maschine um.',
      dataValues: <int>[7, 5, 12],
      dataOperation: 'add',
      expectedAnswer: 7,
      maxValue: 20,
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
    await tester.pump();

    var target = find.byKey(const ValueKey('touch-family-operation-0'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    target = find.widgetWithText(FilledButton, '7');
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    target = find.byKey(const ValueKey('number-pad-submit'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    expect(answer, isNot(7));

    target = find.byKey(const ValueKey('touch-family-operation-1'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    target = find.widgetWithText(FilledButton, '7');
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    target = find.byKey(const ValueKey('number-pad-submit'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    expect(answer, 7);
  });

  testWidgets('multiplication fact family uses division as the inverse operation',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'family:x:6:4',
      kind: TouchInteractionKind.inverseFamilyMachine,
      instruction: 'Drehe die Maschine um.',
      dataValues: <int>[6, 4, 24],
      dataOperation: 'multiply',
      expectedAnswer: 6,
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
    await tester.pump();
    var target = find.byKey(const ValueKey('touch-family-operation-1'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    target = find.widgetWithText(FilledButton, '6');
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    target = find.byKey(const ValueKey('number-pad-submit'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    expect(answer, 6);
  });

  testWidgets('targeted fact family shows touch machine only after the independent checkpoint',
      (tester) async {
    final controller = await _controller();
    const exercise = StructuredExercise(
      mode: TrainingMode.factFamilies,
      prompt: 'Wenn 7 + 5 = 12: Mit der passenden Umkehroperation kommst du von 12 zurück zu welcher Zahl?',
      answer: 7,
      hint: 'Suche die Gegenrechenart.',
      key: 'family:+:7:5',
      checkpoints: <ExerciseCheckpoint>[
        ExerciseCheckpoint(
          key: 'inverseOperationChoice',
          question: 'Welche Rechenoperation macht +5 wieder rückgängig?',
          choices: <String>['+5', '−5'],
          correctChoice: 1,
          competencyId: MicroCompetencyId.inverseRelationship,
          evidenceWeight: 0.40,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.factFamilies,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.inverseRelationship,
          exerciseGenerator: _FixedStructuredGenerator(exercise),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-family-backward')), findsNothing);
    await tester.tap(find.text('−5'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('touch-family-backward')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-family-operation-checked')), findsOneWidget);

    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      fallback,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(fallback);
    await tester.tap(fallback);
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-family-backward')), findsNothing);
    expect(find.text('Antwort eingeben'), findsOneWidget);
  });

  testWidgets('fact-family touch stays stable at 200 percent text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'family:x:6:4',
      kind: TouchInteractionKind.inverseFamilyMachine,
      instruction: 'Drehe die Rechenmaschine um.',
      dataValues: <int>[6, 4, 24],
      dataOperation: 'multiply',
      expectedAnswer: 6,
      maxValue: 100,
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
    expect(find.byKey(const ValueKey('touch-family-backward')), findsOneWidget);
  });


  test('route planner preserves direction order and can skip a checked first segment', () {
    final full = TouchInteractionPlan.forTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: 'plan:route:left:2:down:3',
      answer: 1,
      maxValue: 1000,
      choices: const <String>['A', 'B', 'C'],
    );
    final targeted = TouchInteractionPlan.forTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: 'plan:route:right:3:up:2',
      answer: 0,
      maxValue: 1000,
      choices: const <String>['A', 'B', 'C'],
      targetCompetency: MicroCompetencyId.planDirections,
    );

    expect(full?.kind, TouchInteractionKind.routeSequenceWalker);
    expect(full?.dataLabels, const <String>['left', 'down']);
    expect(full?.dataValues, const <int>[2, 3]);
    expect(full?.dataOperation, 'full');
    expect(targeted?.kind, TouchInteractionKind.routeSequenceWalker);
    expect(targeted?.dataOperation, 'skip-first');
  });

  testWidgets('route walker rejects the same endpoint in the wrong section order',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'plan:route:right:2:up:1',
      kind: TouchInteractionKind.routeSequenceWalker,
      instruction: 'Laufe die Route.',
      dataLabels: <String>['right', 'up'],
      dataValues: <int>[2, 1],
      dataOperation: 'full',
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
    await tester.pump();

    for (final direction in <String>['right', 'up', 'right']) {
      final button = find.byKey(ValueKey('touch-route-$direction'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }
    final submit = find.byKey(const ValueKey('touch-route-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(answer, isNot(2));

    final reset = find.byKey(const ValueKey('touch-route-reset'));
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pump();
    for (final direction in <String>['right', 'right', 'up']) {
      final button = find.byKey(ValueKey('touch-route-$direction'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(answer, 2);
  });

  testWidgets('route walker supports left and down directions', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'plan:route:left:2:down:3',
      kind: TouchInteractionKind.routeSequenceWalker,
      instruction: 'Laufe die Route.',
      dataLabels: <String>['left', 'down'],
      dataValues: <int>[2, 3],
      dataOperation: 'full',
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
    await tester.pump();

    for (final direction in <String>['left', 'left', 'down', 'down', 'down']) {
      final button = find.byKey(ValueKey('touch-route-$direction'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }
    final submit = find.byKey(const ValueKey('touch-route-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(answer, 1);
  });

  testWidgets('targeted route continues only after the independent first segment',
      (tester) async {
    final controller = await _controller();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    const exercise = CurriculumExercise(
      mode: TrainingMode.plansAndOrientation,
      prompt: 'Lies den Weg im Pfeilplan: → → → | ↑ ↑',
      answer: 0,
      hint: 'Lies beide Blöcke.',
      key: 'plan:route:right:3:up:2',
      choices: <String>[
        '3 Felder nach rechts, dann 2 Felder nach oben',
        '3 Felder nach oben, dann 2 Felder nach rechts',
        '2 Felder nach rechts, dann 3 Felder nach oben',
      ],
      method: 'Pfeilpläne und Wegabschnitte lesen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.plansAndOrientation,
          targetCompetency: MicroCompetencyId.planDirections,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-route-grid')), findsNothing);
    final firstSegment = find.widgetWithText(
      FilledButton,
      '3 Felder nach rechts',
    );
    await tester.ensureVisible(firstSegment);
    await tester.tap(firstSegment);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('touch-route-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-route-prefix-checked')), findsOneWidget);
    expect(find.text('Abschnitt 1 geprüft: 3 × →'), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-route-undo')), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.byKey(const ValueKey('touch-route-undo'))).onPressed,
      isNull,
    );
  });

  testWidgets('route touch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'plan:route:left:4:down:3',
      kind: TouchInteractionKind.routeSequenceWalker,
      instruction: 'Laufe den Pfeilplan in Reihenfolge ab.',
      dataLabels: <String>['left', 'down'],
      dataValues: <int>[4, 3],
      dataOperation: 'full',
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
    expect(find.byKey(const ValueKey('touch-route-grid')), findsOneWidget);
  });

  test('scale planner maps plan centimeters to equal real-distance blocks', () {
    final regular = TouchInteractionPlan.forTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: 'plan:scale:100:6',
      answer: 600,
      maxValue: 10000,
    );
    final targeted = TouchInteractionPlan.forTask(
      mode: TrainingMode.plansAndOrientation,
      taskKey: 'plan:scale:1000:4',
      answer: 4000,
      maxValue: 10000,
      targetCompetency: MicroCompetencyId.scale,
    );

    expect(regular, isNotNull);
    expect(regular!.kind, TouchInteractionKind.scaleDistanceBuilder);
    expect(regular.dataValues, <int>[100, 6]);
    expect(regular.dataOperation, 'full');
    expect(targeted, isNotNull);
    expect(targeted!.kind, TouchInteractionKind.scaleDistanceBuilder);
    expect(targeted.dataValues, <int>[1000, 4]);
    expect(targeted.dataOperation, 'operation-checked');
    expect(targeted.instruction, contains('schon geprüft'));
  });

  testWidgets('scale builder needs the correct block structure before the total counts',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'plan:scale:100:6',
      kind: TouchInteractionKind.scaleDistanceBuilder,
      instruction: 'Übertrage die Maßstabszuordnung.',
      dataValues: <int>[100, 6],
      expectedAnswer: 600,
      maxValue: 10000,
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
    await tester.pump();

    tester
        .widget<NumberAnswerPad>(
          find.byKey(const ValueKey('touch-scale-number-pad')),
        )
        .onAnswer(600);
    await tester.pump();
    expect(answer, isNot(600));

    final add = find.byKey(const ValueKey('touch-scale-add'));
    for (var index = 0; index < 5; index++) {
      tester.widget<FilledButton>(add).onPressed!();
      await tester.pump();
    }
    tester
        .widget<NumberAnswerPad>(
          find.byKey(const ValueKey('touch-scale-number-pad')),
        )
        .onAnswer(600);
    await tester.pump();
    expect(answer, isNot(600));

    tester.widget<FilledButton>(add).onPressed!();
    await tester.pump();
    expect(find.text('Realstrecke: 6 Blöcke gebaut'), findsOneWidget);
    tester
        .widget<NumberAnswerPad>(
          find.byKey(const ValueKey('touch-scale-number-pad')),
        )
        .onAnswer(600);
    await tester.pump();
    expect(answer, 600);
  });

  testWidgets('targeted scale shows the builder only after operation evidence',
      (tester) async {
    final controller = await _controller();
    controller.gradeLevel = GradeLevel.fourth;
    controller.numberRange = NumberRangeLevel.million;
    const exercise = CurriculumExercise(
      mode: TrainingMode.plansAndOrientation,
      prompt:
          'Im Plan entsprechen 1 cm genau 100 m. Eine Strecke ist 6 cm lang. Wie viele Meter sind das?',
      answer: 600,
      hint: 'Nutze die Zuordnung pro Zentimeter.',
      key: 'plan:scale:100:6',
      answerSuffix: 'm',
      maxAnswerValue: 10000,
      method: 'Pläne und Maßstabsbeziehungen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.plansAndOrientation,
          targetCompetency: MicroCompetencyId.scale,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-scale-ratio')), findsNothing);
    final operation = find.widgetWithText(
      FilledButton,
      'Planlänge × Meter pro Zentimeter',
    );
    await tester.ensureVisible(operation);
    await tester.tap(operation);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('touch-scale-ratio')), findsOneWidget);
    expect(find.text('1 cm im Plan = 100 m in Wirklichkeit'), findsOneWidget);
    expect(find.textContaining('schon geprüft'), findsOneWidget);
  });

  testWidgets('scale touch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'plan:scale:1000:8',
      kind: TouchInteractionKind.scaleDistanceBuilder,
      instruction: 'Baue die Maßstabszuordnung.',
      dataValues: <int>[1000, 8],
      expectedAnswer: 8000,
      maxValue: 10000,
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
    expect(find.byKey(const ValueKey('touch-scale-ratio')), findsOneWidget);
  });

  test('doubles and halves reuse equal-group manipulatives for small quantities', () {
    final doublePlan = TouchInteractionPlan.forTask(
      mode: TrainingMode.doublesHalves,
      taskKey: 'double:7',
      answer: 14,
      maxValue: 20,
    );
    final halfPlan = TouchInteractionPlan.forTask(
      mode: TrainingMode.doublesHalves,
      taskKey: 'half:14',
      answer: 7,
      maxValue: 20,
    );

    expect(doublePlan, isNotNull);
    expect(doublePlan!.kind, TouchInteractionKind.equalGroupsBuilder);
    expect(doublePlan.groupCount, 2);
    expect(doublePlan.itemsPerGroup, 7);
    expect(doublePlan.totalItems, 14);

    expect(halfPlan, isNotNull);
    expect(halfPlan!.kind, TouchInteractionKind.divisionGroupsBuilder);
    expect(halfPlan.groupCount, 2);
    expect(halfPlan.totalItems, 14);
    expect(halfPlan.divisionGrouping, isFalse);
  });

  test('large doubles and halves keep the classic input instead of click-heavy grids', () {
    expect(
      TouchInteractionPlan.forTask(
        mode: TrainingMode.doublesHalves,
        taskKey: 'double:20',
        answer: 40,
        maxValue: 100,
      ),
      isNull,
    );
    expect(
      TouchInteractionPlan.forTask(
        mode: TrainingMode.doublesHalves,
        taskKey: 'half:40',
        answer: 20,
        maxValue: 100,
      ),
      isNull,
    );
  });

  testWidgets('targeted double shows two-group touch only after meaning checkpoint',
      (tester) async {
    final controller = await _controller();
    const exercise = StructuredExercise(
      mode: TrainingMode.doublesHalves,
      prompt: 'Was ist das Doppelte von 4?',
      answer: 8,
      hint: 'Doppelt bedeutet: 4 + 4.',
      key: 'double:4',
      checkpoints: <ExerciseCheckpoint>[
        ExerciseCheckpoint(
          key: 'doubleHalfMeaning',
          question: 'Was bedeutet „das Doppelte“?',
          choices: <String>[
            'zweimal dieselbe Menge zusammen',
            'in zwei gleich große Teile teilen',
          ],
          correctChoice: 0,
          competencyId: MicroCompetencyId.doublesHalves,
          evidenceWeight: 0.40,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.doublesHalves,
          targetCompetency: MicroCompetencyId.doublesHalves,
          targetTasks: 1,
          exerciseGenerator: _FixedStructuredGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-equal-group-0')), findsNothing);
    final meaning = find.widgetWithText(
      FilledButton,
      'zweimal dieselbe Menge zusammen',
    );
    await tester.ensureVisible(meaning);
    await tester.tap(meaning);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('touch-equal-group-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-equal-group-1')), findsOneWidget);
    expect(find.textContaining('Bedeutung von „doppelt“ wurde schon geprüft'), findsOneWidget);
  });

  testWidgets('double-half group touch stays stable at 200 percent text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'half:12',
      kind: TouchInteractionKind.divisionGroupsBuilder,
      instruction: 'Verteile alle 12 Punkte fair auf zwei Gruppen.',
      totalItems: 12,
      groupCount: 2,
      itemsPerGroup: 6,
      divisionGrouping: false,
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
    expect(find.byKey(const ValueKey('touch-sharing-group-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-sharing-group-1')), findsOneWidget);
  });


  test('number friends use a bond composer only for child-sized targets', () {
    final small = TouchInteractionPlan.forTask(
      mode: TrainingMode.numberFriends,
      taskKey: 'plus:6:4',
      answer: 4,
      maxValue: 20,
    );
    final large = TouchInteractionPlan.forTask(
      mode: TrainingMode.numberFriends,
      taskKey: 'plus:30:20',
      answer: 20,
      maxValue: 100,
    );

    expect(small, isNotNull);
    expect(small!.kind, TouchInteractionKind.numberBondComposer);
    expect(small.dataValues, <int>[10, 6]);
    expect(small.expectedAnswer, 4);
    expect(large, isNull);
  });

  testWidgets('number bond requires the exact missing part', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'plus:6:4',
      kind: TouchInteractionKind.numberBondComposer,
      instruction: 'Baue den fehlenden Teil.',
      dataValues: <int>[10, 6],
      expectedAnswer: 4,
      maxValue: 10,
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

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('touch-number-bond-add')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('touch-number-bond-submit')));
    await tester.pump();
    expect(answer, isNot(4));

    await tester.tap(find.byKey(const ValueKey('touch-number-bond-add')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-number-bond-submit')));
    await tester.pump();
    expect(answer, 4);
  });

  testWidgets('number friends default to decomposition touch and keep keypad fallback',
      (tester) async {
    final controller = await _controller();
    controller.numberRange = NumberRangeLevel.twenty;
    controller.facts = <MathFact>[
      MathFact(a: 6, b: 4, operation: MathOperation.plus),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.numberFriends,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.numberDecomposition,
          reviewEmphasis: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('10 = 6 + ?'), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-number-bond-groups')), findsOneWidget);
    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.ensureVisible(fallback);
    await tester.tap(fallback);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);
  });

  testWidgets('number bond stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'plus:11:9',
      kind: TouchInteractionKind.numberBondComposer,
      instruction: 'Baue den fehlenden Teil.',
      dataValues: <int>[20, 11],
      expectedAnswer: 9,
      maxValue: 20,
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
    expect(find.byKey(const ValueKey('touch-number-bond-missing')), findsOneWidget);
  });


  test('lower-primary measures use ruler and conversion touch where useful', () {
    final add = TouchInteractionPlan.forTask(
      mode: TrainingMode.measures,
      taskKey: 'measure:add:ribbon:7:5',
      answer: 12,
      maxValue: 20,
      answerSuffix: 'cm',
    );
    final subtract = TouchInteractionPlan.forTask(
      mode: TrainingMode.measures,
      taskKey: 'measure:subtract:rope:12:5',
      answer: 7,
      maxValue: 20,
      answerSuffix: 'cm',
    );
    final dmToCm = TouchInteractionPlan.forTask(
      mode: TrainingMode.measures,
      taskKey: 'measure:convert:dm-cm:4',
      answer: 40,
      maxValue: 40,
      answerSuffix: 'cm',
    );
    final cmToM = TouchInteractionPlan.forTask(
      mode: TrainingMode.measures,
      taskKey: 'measure:convert:cm-m:300',
      answer: 3,
      maxValue: 3,
      answerSuffix: 'm',
    );

    expect(add?.kind, TouchInteractionKind.lengthRulerOperation);
    expect(add?.dataValues, <int>[7, 5]);
    expect(add?.startValue, 7);
    expect(add?.maxValue, 12);
    expect(subtract?.kind, TouchInteractionKind.lengthRulerOperation);
    expect(subtract?.dataOperation, 'subtract');
    expect(subtract?.startValue, 12);
    expect(dmToCm?.kind, TouchInteractionKind.unitConversionMachine);
    expect(dmToCm?.dataLabels, <String>['dm', 'cm']);
    expect(dmToCm?.dataValues, <int>[4, 10]);
    expect(cmToM?.kind, TouchInteractionKind.unitConversionMachine);
    expect(cmToM?.dataOperation, 'divide');
    expect(cmToM?.dataValues, <int>[300, 100]);

    expect(
      TouchInteractionPlan.forTask(
        mode: TrainingMode.measures,
        taskKey: 'measure:add:ribbon:20:20',
        answer: 40,
        maxValue: 100,
        answerSuffix: 'cm',
      ),
      isNull,
    );
  });

  testWidgets('length ruler requires the exact measured endpoint', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'measure:add:ribbon:7:5',
      kind: TouchInteractionKind.lengthRulerOperation,
      instruction: 'Lege beide Längen aneinander.',
      minValue: 0,
      maxValue: 12,
      startValue: 7,
      dataValues: <int>[7, 5],
      dataOperation: 'add',
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
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('touch-length-ruler-submit')));
    await tester.pump();
    expect(answer, isNot(12));

    tester
        .widget<Slider>(find.byKey(const ValueKey('touch-length-ruler-slider')))
        .onChanged!(12);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-length-ruler-submit')));
    await tester.pump();
    expect(answer, 12);
  });

  testWidgets('targeted measurement shows ruler only after operation checkpoint',
      (tester) async {
    final controller = await _controller();
    const exercise = StructuredExercise(
      mode: TrainingMode.measures,
      prompt: 'Ein Band ist 7 cm lang. Ein zweites Stück ist 5 cm lang. Wie lang sind beide zusammen?',
      answer: 12,
      hint: 'Beide Längen kommen zusammen.',
      key: 'measure:add:ribbon:7:5',
      answerSuffix: 'cm',
      checkpoints: <ExerciseCheckpoint>[
        ExerciseCheckpoint(
          key: 'measureOperationChoice',
          question: 'Welche Rechenart passt zu dieser Längensituation?',
          choices: <String>['Plus (+)', 'Minus (−)'],
          correctChoice: 0,
          competencyId: MicroCompetencyId.measurementCalculation,
          evidenceWeight: 0.40,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.measures,
          targetCompetency: MicroCompetencyId.measurementCalculation,
          targetTasks: 1,
          exerciseGenerator: _FixedStructuredGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('touch-length-ruler-model')), findsNothing);
    final plus = find.widgetWithText(FilledButton, 'Plus (+)');
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('touch-length-ruler-model')), findsOneWidget);
  });

  testWidgets('lower measure touch stays stable at 200 percent text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'measure:subtract:rope:18:7',
      kind: TouchInteractionKind.lengthRulerOperation,
      instruction: 'Stelle den Rest auf dem Lineal ein.',
      minValue: 0,
      maxValue: 18,
      startValue: 18,
      dataValues: <int>[18, 7],
      dataOperation: 'subtract',
      expectedAnswer: 11,
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
    expect(find.byKey(const ValueKey('touch-length-ruler-slider')), findsOneWidget);
  });

  test('word-problem modeling planner covers facts operation and equation', () {
    final facts = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:info:trip:6:2:3',
      answer: 2,
      maxValue: 20,
      choices: const <String>[
        '6 Kinder und 3 Bälle',
        'Nur die 3 Bälle',
        '6 Kinder und 2 Erwachsene',
        '2 Erwachsene und 3 Bälle',
      ],
    );
    final operation = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:operation:x:4:3',
      answer: 2,
      maxValue: 20,
      choices: const <String>[
        'Geteilt (÷)',
        'Plus (+)',
        'Mal (×)',
        'Minus (−)',
      ],
    );
    final equation = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:equation:-:9:4',
      answer: 1,
      maxValue: 20,
      choices: const <String>['9 + 4', '9 − 4', '4 − 9', '9 − 3'],
    );

    expect(facts?.kind, TouchInteractionKind.storyRelevantFacts);
    expect(facts?.selectionLabels, <String>['6 Kinder', '2 Erwachsene', '3 Bälle']);
    expect(facts?.correctSelectionIndexes, <int>[0, 1]);
    expect(operation?.kind, TouchInteractionKind.storyOperationRelation);
    expect(operation?.dataOperation, 'x');
    expect(operation?.dataLabels, containsAll(<String>['+', '-', 'x', 'divide']));
    expect(equation?.kind, TouchInteractionKind.storyEquationBuilder);
    expect(equation?.dataValues, <int>[9, 4]);
    expect(equation?.dataOperation, '-');
  });

  testWidgets('relevant facts require the exact information set', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'story:info:trip:6:2:3',
      kind: TouchInteractionKind.storyRelevantFacts,
      instruction: 'Markiere wichtige Angaben.',
      selectionLabels: <String>['6 Kinder', '2 Erwachsene', '3 Bälle'],
      correctSelectionIndexes: <int>[0, 1],
      expectedAnswer: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('touch-story-fact-0')));
    await tester.tap(find.byKey(const ValueKey('touch-story-fact-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-story-facts-submit')));
    expect(answer, isNot(2), reason: 'Gleiche Anzahl markierter Angaben darf nicht genügen.');

    await tester.tap(find.byKey(const ValueKey('touch-story-fact-2')));
    await tester.tap(find.byKey(const ValueKey('touch-story-fact-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-story-facts-submit')));
    expect(answer, 2);
  });

  testWidgets('story operation uses the mathematical relation', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'story:operation:x:4:3',
      kind: TouchInteractionKind.storyOperationRelation,
      instruction: 'Wähle die Beziehung.',
      dataLabels: <String>['+', '-', 'x', 'divide'],
      correctSelectionIndexes: <int>[2],
      expectedAnswer: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('touch-story-operation-0')));
    await tester.tap(find.byKey(const ValueKey('touch-story-operation-submit')));
    expect(answer, isNot(1));
    await tester.tap(find.byKey(const ValueKey('touch-story-operation-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-story-operation-submit')));
    expect(answer, 1);
  });

  testWidgets('story equation checks operation and operand order', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'story:equation:-:9:4',
      kind: TouchInteractionKind.storyEquationBuilder,
      instruction: 'Baue die Rechnung.',
      dataValues: <int>[9, 4],
      dataLabels: <String>['+', '-'],
      dataOperation: '-',
      expectedAnswer: 3,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('touch-story-equation-left-1')));
    await tester.tap(find.byKey(const ValueKey('touch-story-equation-op-1')));
    await tester.tap(find.byKey(const ValueKey('touch-story-equation-right-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-story-equation-submit')));
    expect(answer, isNot(3), reason: 'Bei Minus muss die Reihenfolge der Größen stimmen.');

    await tester.tap(find.byKey(const ValueKey('touch-story-equation-left-0')));
    await tester.tap(find.byKey(const ValueKey('touch-story-equation-right-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-story-equation-submit')));
    expect(answer, 3);
  });

  testWidgets('word-problem modeling defaults to touch and keeps text fallback', (tester) async {
    final controller = await _controller();
    const exercise = StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt: 'Zu einem Ausflug fahren 6 Kinder und 2 Erwachsene mit. Außerdem werden 3 Bälle eingepackt. Welche Angaben brauchst du?',
      answer: 2,
      hint: 'Achte auf Personen.',
      key: 'story:info:trip:6:2:3',
      choices: <String>[
        '6 Kinder und 3 Bälle',
        'Nur die 3 Bälle',
        '6 Kinder und 2 Erwachsene',
        '2 Erwachsene und 3 Bälle',
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetCompetency: MicroCompetencyId.wordProblemRelevantInformation,
          targetTasks: 1,
          exerciseGenerator: _FixedStructuredGenerator(exercise),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-story-facts')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('structured-training-scroll')),
      const Offset(0, -520),
    );
    await tester.pump();
    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    expect(fallback, findsOneWidget);
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('6 Kinder und 2 Erwachsene'), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-switch-interaction')), findsOneWidget);
  });

  testWidgets('story modeling stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'story:equation:divide:12:3',
      kind: TouchInteractionKind.storyEquationBuilder,
      instruction: 'Baue die passende Rechnung.',
      dataValues: <int>[12, 3],
      dataLabels: <String>['+', '-', 'divide'],
      dataOperation: 'divide',
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
    expect(find.byKey(const ValueKey('touch-story-equation-builder')), findsOneWidget);
  });


  test('story interpretation planner separates meaning and quantity type', () {
    final plus = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:interpret:+:7:5:12',
      answer: 2,
      maxValue: 20,
      choices: const <String>[
        'Im Raum sind 12 Kinder.',
        'Es kommen noch 12 Sticker dazu.',
        'Mara hat jetzt 12 Sticker.',
        'Mara hat 12 Sticker abgegeben.',
      ],
    );
    final minus = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:interpret:-:9:4:5',
      answer: 1,
      maxValue: 20,
      choices: const <String>[
        'Am Anfang lagen 5 Karten dort.',
        'Es bleiben 5 Karten übrig.',
        'Es wurden 5 Karten weggenommen.',
        'Es kommen 5 Karten dazu.',
      ],
    );
    final calculation = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:calc:+:7:5',
      answer: 12,
      maxValue: 20,
    );

    expect(plus?.kind, TouchInteractionKind.storyInterpretationBuilder);
    expect(plus?.dataValues, <int>[7, 5, 12]);
    expect(
      plus?.dataLabels[plus.correctSelectionIndexes[0]],
      contains('Endbestand'),
    );
    expect(
      plus?.selectionLabels[plus.correctSelectionIndexes[1]],
      'Sticker',
    );
    expect(minus?.kind, TouchInteractionKind.storyInterpretationBuilder);
    expect(
      minus?.dataLabels[minus.correctSelectionIndexes[0]],
      contains('Restbestand'),
    );
    expect(
      minus?.selectionLabels[minus.correctSelectionIndexes[1]],
      'Karten',
    );
    expect(
      calculation,
      isNull,
      reason: 'Das reine Ausrechnen bleibt bewusst bei der Zahleneingabe.',
    );
  });

  testWidgets('story interpretation needs correct meaning and quantity type',
      (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'story:interpret:+:7:5:12',
      kind: TouchInteractionKind.storyInterpretationBuilder,
      instruction: 'Deute das Ergebnis.',
      dataValues: <int>[7, 5, 12],
      dataLabels: <String>[
        'Zuwachs – so viele kommen noch dazu',
        'Endbestand – so viele sind jetzt da',
        'Abgabe – so viele wurden weggegeben',
      ],
      selectionLabels: <String>['Kinder', 'Karten', 'Sticker'],
      correctSelectionIndexes: <int>[1, 2],
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

    await tester.tap(
      find.byKey(const ValueKey('touch-story-interpretation-meaning-1')),
    );
    await tester.tap(
      find.byKey(const ValueKey('touch-story-interpretation-unit-0')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('touch-story-interpretation-submit')),
    );
    expect(answer, isNot(3), reason: 'Die richtige Bedeutung mit falscher Größe reicht nicht.');

    await tester.tap(
      find.byKey(const ValueKey('touch-story-interpretation-meaning-0')),
    );
    await tester.tap(
      find.byKey(const ValueKey('touch-story-interpretation-unit-2')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('touch-story-interpretation-submit')),
    );
    expect(answer, isNot(3), reason: 'Die richtige Größe mit falscher Bedeutung reicht nicht.');

    await tester.tap(
      find.byKey(const ValueKey('touch-story-interpretation-meaning-1')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('touch-story-interpretation-submit')),
    );
    expect(answer, 3);
  });

  testWidgets('story interpretation defaults to touch and keeps sentence fallback',
      (tester) async {
    final controller = await _controller();
    const exercise = StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt:
          'Mara hat 7 Sticker und bekommt 5 dazu. Die Rechnung 7 + 5 = 12 ist schon gelöst. Welche Antwort passt?',
      answer: 2,
      hint: 'Beziehe die 12 auf die Sticker.',
      key: 'story:interpret:+:7:5:12',
      choices: <String>[
        'Im Raum sind 12 Kinder.',
        'Es kommen noch 12 Sticker dazu.',
        'Mara hat jetzt 12 Sticker.',
        'Mara hat 12 Sticker abgegeben.',
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetCompetency: MicroCompetencyId.wordProblemInterpretation,
          targetTasks: 1,
          exerciseGenerator: _FixedStructuredGenerator(exercise),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('touch-story-interpretation-result')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('structured-training-scroll')),
      const Offset(0, -620),
    );
    await tester.pump();
    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    expect(fallback, findsOneWidget);
    await tester.tap(fallback);
    await tester.pump();
    expect(find.text('Mara hat jetzt 12 Sticker.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('touch-switch-interaction')),
      findsOneWidget,
    );
  });

  testWidgets('story interpretation stays stable at 200 percent text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'story:interpret:-:9:4:5',
      kind: TouchInteractionKind.storyInterpretationBuilder,
      instruction: 'Deute das Ergebnis.',
      dataValues: <int>[9, 4, 5],
      dataLabels: <String>[
        'Restbestand – so viele bleiben übrig',
        'Abgabe – so viele wurden weggenommen',
        'Anfangsbestand – so viele waren vorher da',
      ],
      selectionLabels: <String>['Karten', 'Sticker', 'Kinder'],
      correctSelectionIndexes: <int>[0, 0],
      expectedAnswer: 1,
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
      find.byKey(const ValueKey('touch-story-interpretation-meanings')),
      findsOneWidget,
    );
  });

  test('control-check planner covers written errors and plausibility', () {
    final targetedError = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'process:error:add:place:10:462:337:809',
      answer: 1,
      maxValue: 1000,
      choices: const <String>[
        'Die Rechnung stimmt.',
        'Das Ergebnis ist um 10 zu groß.',
        'Das Ergebnis ist um 10 zu klein.',
        'Die Zahlen dürfen so nicht addiert werden.',
      ],
    );
    final plainError = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'process:error:add:462:337:789',
      answer: 2,
      maxValue: 1000,
      choices: const <String>[
        'Die Rechnung stimmt.',
        'Das Ergebnis ist um 10 zu groß.',
        'Das Ergebnis ist um 10 zu klein.',
        'Die Zahlen dürfen so nicht addiert werden.',
      ],
    );
    final plausibility = TouchInteractionPlan.forTask(
      mode: TrainingMode.estimation,
      taskKey: 'process:plausibility:462:337:1200:100',
      answer: 1,
      maxValue: 1000,
      choices: const <String>['plausibel', 'nicht plausibel'],
    );
    final targetedErrorAfterCheckpoint = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'process:error:add:place:10:462:337:809',
      answer: 1,
      maxValue: 1000,
      choices: const <String>[
        'Die Rechnung stimmt.',
        'Das Ergebnis ist um 10 zu groß.',
        'Das Ergebnis ist um 10 zu klein.',
        'Die Zahlen dürfen so nicht addiert werden.',
      ],
      targetCompetency: MicroCompetencyId.errorChecking,
    );
    final targetedPlausibilityAfterCheckpoint = TouchInteractionPlan.forTask(
      mode: TrainingMode.estimation,
      taskKey: 'process:plausibility:462:337:1200:100',
      answer: 1,
      maxValue: 1000,
      choices: const <String>['plausibel', 'nicht plausibel'],
      targetCompetency: MicroCompetencyId.plausibilityCheck,
    );

    expect(targetedError?.kind, TouchInteractionKind.writtenErrorInspector);
    expect(targetedError?.dataValues.take(5), <int>[462, 337, 809, 10, 799]);
    expect(targetedError?.dataOperation, 'too-large');
    expect(plainError?.kind, TouchInteractionKind.writtenErrorInspector);
    expect(plainError?.dataOperation, 'too-small');
    expect(plausibility?.kind, TouchInteractionKind.estimationRounding);
    expect(plausibility?.dataOperation, 'plausibility');
    expect(plausibility?.dataValues, <int>[462, 337, 100, 500, 300, 1200]);
    expect(targetedErrorAfterCheckpoint?.dataOperation, 'too-large:skip-place');
    expect(
      targetedPlausibilityAfterCheckpoint?.dataOperation,
      'plausibility:skip-estimate',
    );
  });

  testWidgets('written error inspector needs place and direction', (tester) async {
    var answer = -1;
    final plan = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'process:error:add:place:10:462:337:809',
      answer: 1,
      maxValue: 1000,
      choices: const <String>[
        'Die Rechnung stimmt.',
        'Das Ergebnis ist um 10 zu groß.',
        'Das Ergebnis ist um 10 zu klein.',
        'Die Zahlen dürfen so nicht addiert werden.',
      ],
    )!;
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

    await tester.tap(find.byKey(const ValueKey('touch-error-place-100')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-error-too-large')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('touch-error-submit')));
    await tester.tap(find.byKey(const ValueKey('touch-error-submit')));
    expect(answer, isNot(1), reason: 'Die richtige Richtung allein darf nicht genügen.');

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-error-place-10')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-error-too-small')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('touch-error-submit')));
    await tester.tap(find.byKey(const ValueKey('touch-error-submit')));
    expect(answer, isNot(1), reason: 'Der richtige Stellenwert allein darf nicht genügen.');

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-error-too-large')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('touch-error-submit')));
    await tester.tap(find.byKey(const ValueKey('touch-error-submit')));
    expect(answer, 1);
  });

  testWidgets('plausibility requires correct rounding before the verdict', (tester) async {
    var answer = -1;
    final plan = TouchInteractionPlan.forTask(
      mode: TrainingMode.estimation,
      taskKey: 'process:plausibility:462:337:1200:100',
      answer: 1,
      maxValue: 2000,
      choices: const <String>['plausibel', 'nicht plausibel'],
    )!;
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

    await tester.tap(find.byKey(const ValueKey('touch-estimate-a-400')));
    await tester.tap(find.byKey(const ValueKey('touch-estimate-b-300')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-estimate-result-1')));
    expect(answer, isNot(1), reason: 'Ein richtig geratenes Urteil darf falsches Runden nicht verdecken.');

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-estimate-a-500')));
    await tester.pump();
    expect(find.textContaining('Überschlag: 500 + 300 = 800'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-estimate-result-1')));
    expect(answer, 1);
  });

  testWidgets('control checks default to touch and keep choice fallback', (tester) async {
    final controller = await _controller();
    controller.gradeLevel = GradeLevel.third;
    const error = CurriculumExercise(
      mode: TrainingMode.writtenAddSub,
      prompt: 'Prüfe die Rechnung:\n462 + 337 = 809\nWelche Aussage beschreibt den Fehler?',
      answer: 1,
      hint: 'Prüfe Stelle für Stelle.',
      key: 'process:error:add:place:10:462:337:809',
      choices: <String>[
        'Die Rechnung stimmt.',
        'Das Ergebnis ist um 10 zu groß.',
        'Das Ergebnis ist um 10 zu klein.',
        'Die Zahlen dürfen so nicht addiert werden.',
      ],
      method: 'Fehler finden und begründen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.writtenAddSub,
          targetCompetency: MicroCompetencyId.errorChecking,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(error),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-error-calculation')), findsNothing);
    final errorCheckpoint = find.widgetWithText(FilledButton, 'Zehnerstelle');
    expect(errorCheckpoint, findsOneWidget);
    await tester.tap(errorCheckpoint);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('touch-error-calculation')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-error-place-checked')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-error-places')), findsNothing);
    final errorFallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(
      errorFallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(errorFallback);
    await tester.pump();
    expect(find.text('Das Ergebnis ist um 10 zu groß.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    const plausibility = CurriculumExercise(
      mode: TrainingMode.estimation,
      prompt: '462 + 337 soll 1200 ergeben. Ist dieses Ergebnis nach einem Überschlag plausibel?',
      answer: 1,
      hint: 'Runde beide Ausgangszahlen grob.',
      key: 'process:plausibility:462:337:1200:100',
      choices: <String>['plausibel', 'nicht plausibel'],
      method: 'Ergebnis kontrollieren',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.estimation,
          targetCompetency: MicroCompetencyId.plausibilityCheck,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(plausibility),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-estimate-status')), findsNothing);
    final estimateCheckpoint = find.widgetWithText(FilledButton, '800');
    expect(estimateCheckpoint, findsOneWidget);
    await tester.tap(estimateCheckpoint);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('touch-estimate-status')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('touch-estimate-reference-checked')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('touch-estimate-a-500')), findsNothing);
  });

  testWidgets('control-check touch stays stable at 200 percent text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    final plan = TouchInteractionPlan.forTask(
      mode: TrainingMode.writtenAddSub,
      taskKey: 'process:error:add:place:100:1462:337:1899',
      answer: 1,
      maxValue: 2000,
      choices: const <String>[
        'Die Rechnung stimmt.',
        'Das Ergebnis ist um 100 zu groß.',
        'Das Ergebnis ist um 100 zu klein.',
        'Die Zahlen dürfen so nicht addiert werden.',
      ],
    )!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('touch-error-places')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-error-directions')), findsOneWidget);
  });


  test('transfer-story planner covers irrelevant difference and reverse', () {
    final irrelevant = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:transfer:irrelevant:24:4:7',
      answer: 0,
      maxValue: 100,
      choices: const <String>['24 + 4', '24 + 7', '4 + 7', '24 − 4'],
    );
    final difference = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:transfer:difference:73:48',
      answer: 25,
      maxValue: 100,
    );
    final reverse = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:transfer:reverse:18:7',
      answer: 25,
      maxValue: 100,
    );

    expect(irrelevant?.kind, TouchInteractionKind.storyRelevantFacts);
    expect(irrelevant?.selectionLabels, <String>['24 Kinder', '4 Erwachsene', '7 Bälle']);
    expect(irrelevant?.correctSelectionIndexes, <int>[0, 1]);
    expect(difference?.kind, TouchInteractionKind.storyDifferenceGap);
    expect(difference?.dataValues, <int>[73, 48]);
    expect(reverse?.kind, TouchInteractionKind.inverseFamilyMachine);
    expect(reverse?.dataValues, <int>[25, 7, 18]);
    expect(reverse?.dataOperation, 'subtract-story');
  });

  testWidgets('transfer irrelevant information needs the exact facts', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'story:transfer:irrelevant:24:4:7',
      kind: TouchInteractionKind.storyRelevantFacts,
      instruction: 'Markiere nur Personen.',
      selectionLabels: <String>['24 Kinder', '4 Erwachsene', '7 Bälle'],
      correctSelectionIndexes: <int>[0, 1],
      expectedAnswer: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('touch-story-fact-0')));
    await tester.tap(find.byKey(const ValueKey('touch-story-fact-2')));
    await tester.tap(find.byKey(const ValueKey('touch-story-facts-submit')));
    expect(answer, isNot(0));

    await tester.tap(find.byKey(const ValueKey('touch-story-fact-2')));
    await tester.tap(find.byKey(const ValueKey('touch-story-fact-1')));
    await tester.tap(find.byKey(const ValueKey('touch-story-facts-submit')));
    expect(answer, 0);
  });

  testWidgets('transfer difference requires the exact comparison gap', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'story:transfer:difference:73:48',
      kind: TouchInteractionKind.storyDifferenceGap,
      instruction: 'Stelle den Unterschied ein.',
      minValue: 0,
      maxValue: 73,
      startValue: 0,
      dataValues: <int>[73, 48],
      expectedAnswer: 25,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );
    tester.widget<Slider>(
      find.byKey(const ValueKey('touch-story-difference-slider')),
    ).onChanged!(24);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-story-difference-submit')));
    expect(answer, isNot(25));

    tester.widget<Slider>(
      find.byKey(const ValueKey('touch-story-difference-slider')),
    ).onChanged!(25);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-story-difference-submit')));
    expect(answer, 25);
  });

  testWidgets('reverse transfer needs the inverse operation and start value', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'story:transfer:reverse:18:7',
      kind: TouchInteractionKind.inverseFamilyMachine,
      instruction: 'Gehe rückwärts.',
      dataValues: <int>[25, 7, 18],
      dataOperation: 'subtract-story',
      expectedAnswer: 25,
      maxValue: 100,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
          ),
        ),
      ),
    );
    expect(find.text('?'), findsWidgets, reason: 'Die Anfangsmenge darf nicht verraten werden.');
    await tester.tap(find.byKey(const ValueKey('touch-family-operation-0')));
    await tester.pump();
    tester.widget<NumberAnswerPad>(
      find.byKey(const ValueKey('touch-family-result-pad')),
    ).onAnswer(25);
    expect(answer, isNot(25), reason: 'Die richtige Zahl mit falscher Gegenoperation darf nicht zählen.');

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-family-operation-1')));
    await tester.pump();
    tester.widget<NumberAnswerPad>(
      find.byKey(const ValueKey('touch-family-result-pad')),
    ).onAnswer(25);
    expect(answer, 25);
  });

  testWidgets('transfer stories default to touch and keep classic fallback', (tester) async {
    final controller = await _controller();
    const exercise = StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt: 'Eine Klasse sammelt 73 Kastanien, eine andere 48. Um wie viele mehr?',
      answer: 25,
      hint: 'Vergleiche beide Mengen.',
      key: 'story:transfer:difference:73:48',
      maxAnswerValue: 100,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetTasks: 1,
          exerciseGenerator: _FixedStructuredGenerator(exercise),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-story-difference-bars')), findsOneWidget);
    final fallback = find.byKey(const ValueKey('touch-switch-keypad'));
    await tester.scrollUntilVisible(
      fallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(find.byType(NumberAnswerPad), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-switch-interaction')), findsOneWidget);
  });

  testWidgets('transfer-story touch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const difference = TouchInteractionPlan(
      taskKey: 'story:transfer:difference:73:48',
      kind: TouchInteractionKind.storyDifferenceGap,
      instruction: 'Vergleiche beide Mengen.',
      minValue: 0,
      maxValue: 73,
      dataValues: <int>[73, 48],
      expectedAnswer: 25,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: difference, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('touch-story-difference-slider')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    const reverse = TouchInteractionPlan(
      taskKey: 'story:transfer:reverse:18:7',
      kind: TouchInteractionKind.inverseFamilyMachine,
      instruction: 'Gehe rückwärts.',
      dataValues: <int>[25, 7, 18],
      dataOperation: 'subtract-story',
      expectedAnswer: 25,
      maxValue: 100,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: reverse, onAnswer: _noopAnswer),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('touch-family-forward')), findsOneWidget);
  });


  test('reasoning planner covers compensate commute and distribute', () {
    final compensate = TouchInteractionPlan.forTask(
      mode: TrainingMode.arithmeticLaws,
      taskKey: 'process:reasoning:compensate:27:35:2',
      answer: 1,
      maxValue: 100,
      choices: const <String>['a', 'b', 'c', 'd'],
    );
    final targeted = TouchInteractionPlan.forTask(
      mode: TrainingMode.arithmeticLaws,
      taskKey: 'process:reasoning:commute:6:8',
      answer: 2,
      maxValue: 100,
      choices: const <String>['a', 'b', 'c', 'd'],
      targetCompetency: MicroCompetencyId.reasoningJustification,
    );
    final distribute = TouchInteractionPlan.forTask(
      mode: TrainingMode.arithmeticLaws,
      taskKey: 'process:reasoning:distribute:7:38:40:2',
      answer: 0,
      maxValue: 100,
      choices: const <String>['a', 'b', 'c', 'd'],
    );

    expect(compensate?.kind, TouchInteractionKind.reasoningJustificationBuilder);
    expect(compensate?.dataValues, <int>[27, 35, 2, 25, 37]);
    expect(compensate?.dataOperation, 'compensate');
    expect(targeted?.kind, TouchInteractionKind.reasoningJustificationBuilder);
    expect(targeted?.dataOperation, 'commute:skip-relation');
    expect(distribute?.kind, TouchInteractionKind.reasoningJustificationBuilder);
    expect(distribute?.dataValues, <int>[7, 38, 40, 2]);
  });

  testWidgets('reasoning builder requires relation and causal reason', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'process:reasoning:compensate:27:35:2',
      kind: TouchInteractionKind.reasoningJustificationBuilder,
      instruction: 'Baue die Begründung.',
      dataValues: <int>[27, 35, 2, 25, 37],
      dataOperation: 'compensate',
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

    await tester.tap(find.byKey(const ValueKey('touch-reasoning-relation-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-cause-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-submit')));
    expect(answer, isNot(2));

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-relation-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-cause-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-submit')));
    expect(answer, isNot(2));

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-cause-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-submit')));
    expect(answer, 2);
  });

  testWidgets('distributive reasoning keeps factor in the correction', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'process:reasoning:distribute:7:38:40:2',
      kind: TouchInteractionKind.reasoningJustificationBuilder,
      instruction: 'Begründe den Rechenweg.',
      dataValues: <int>[7, 38, 40, 2],
      dataOperation: 'distribute',
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

    expect(find.text('7 × 38 = 7 × 40 − 14'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-relation-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-cause-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-submit')));
    expect(answer, isNot(3));

    answer = -1;
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-cause-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-reasoning-submit')));
    expect(answer, 3);
  });

  testWidgets('targeted reasoning continues after relation checkpoint', (tester) async {
    final controller = await _controller();
    const exercise = CurriculumExercise(
      mode: TrainingMode.arithmeticLaws,
      prompt: '27 + 35 = 25 + 37. Welche Begründung passt?',
      answer: 0,
      hint: 'Vergleiche beide Summanden.',
      key: 'process:reasoning:compensate:27:35:2',
      choices: <String>[
        'Ein Summand wird um 2 kleiner, der andere um 2 größer. Deshalb bleibt die Summe gleich.',
        'Beide Summanden werden um 2 kleiner.',
        'Die Summanden werden nur vertauscht.',
        'Man darf immer 2 von beiden Summanden abziehen.',
      ],
      method: 'Rechenbeziehung begründen',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.arithmeticLaws,
          targetCompetency: MicroCompetencyId.reasoningJustification,
          targetTasks: 1,
          exerciseGenerator: _FixedCurriculumGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Welche Rechenbeziehung liegt hier vor?'), findsOneWidget);
    await tester.tap(find.text('ein Summand kleiner, der andere gleich viel größer'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('touch-reasoning-relation-checked')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('touch-reasoning-relations')), findsNothing);

    final fallback = find.byKey(const ValueKey('touch-switch-choices'));
    await tester.scrollUntilVisible(
      fallback,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fallback);
    await tester.pump();
    expect(
      find.text('Ein Summand wird um 2 kleiner, der andere um 2 größer. Deshalb bleibt die Summe gleich.'),
      findsOneWidget,
    );
  });

  testWidgets('reasoning touch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'process:reasoning:commute:6:8',
      kind: TouchInteractionKind.reasoningJustificationBuilder,
      instruction: 'Begründe den Rechenweg.',
      dataValues: <int>[6, 8],
      dataOperation: 'commute:skip-relation',
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
    expect(
      find.byKey(const ValueKey('touch-reasoning-relation-checked')),
      findsOneWidget,
    );
  });

  test('representation translation planner covers all four directions', () {
    final place = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'process:representation:place:47',
      answer: 2,
      maxValue: 100,
      choices: const ['46', '48', '47', '37'],
      targetCompetency: MicroCompetencyId.representationTranslation,
    );
    final decompose = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'process:representation:decompose:47',
      answer: 1,
      maxValue: 100,
      choices: const ['30 + 7', '40 + 7', '40 + 8', '4 + 7'],
      targetCompetency: MicroCompetencyId.representationTranslation,
    );
    final groups = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'process:representation:groups:3:4',
      answer: 0,
      maxValue: 20,
      choices: const ['3 × 4', '3 + 4', '4 × 4', '3 × 5'],
      targetCompetency: MicroCompetencyId.representationTranslation,
    );
    final equation = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'process:representation:equation:3:4',
      answer: 0,
      maxValue: 20,
      choices: const [
        '3 Gruppen mit je 4 Punkten',
        '4 Gruppen mit je 4 Punkten',
        '3 Gruppen mit je 5 Punkten',
        '3 Gruppen mit je 3 Punkten',
      ],
      targetCompetency: MicroCompetencyId.representationTranslation,
    );
    expect(place?.kind, TouchInteractionKind.largeNumberDecompose);
    expect(place?.dataOperation, 'representation-choice');
    expect(decompose?.kind, TouchInteractionKind.largeNumberDecompose);
    expect(groups?.kind, TouchInteractionKind.storyEquationBuilder);
    expect(groups?.dataOperation, 'x');
    expect(equation?.kind, TouchInteractionKind.equalGroupsBuilder);
    expect(equation?.dataOperation, 'representation-choice');
  });

  testWidgets('place-value representation submits the original choice only after exact build', (tester) async {
    final answers = <int>[];
    const plan = TouchInteractionPlan(
      taskKey: 'process:representation:place:23',
      kind: TouchInteractionKind.largeNumberDecompose,
      instruction: 'Baue die Zahl.',
      dataValues: <int>[23],
      dataOperation: 'representation-choice',
      expectedAnswer: 2,
      maxValue: 100,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: answers.add),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('touch-large-digit-plus-10')));
    await tester.tap(find.byKey(const ValueKey('touch-large-digit-plus-10')));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('touch-large-digit-plus-1')));
    }
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-large-decompose-submit')));
    expect(answers.single, 2);
  });

  testWidgets('representation groups translate to equation and back to groups', (tester) async {
    final equationAnswers = <int>[];
    const groupsPlan = TouchInteractionPlan(
      taskKey: 'process:representation:groups:3:4',
      kind: TouchInteractionKind.storyEquationBuilder,
      instruction: 'Übersetze.',
      dataValues: <int>[3, 4],
      dataLabels: <String>['+', 'x'],
      dataOperation: 'x',
      expectedAnswer: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: groupsPlan, onAnswer: equationAnswers.add),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('touch-story-equation-left-0')));
    await tester.tap(find.byKey(const ValueKey('touch-story-equation-op-1')));
    await tester.tap(find.byKey(const ValueKey('touch-story-equation-right-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-story-equation-submit')));
    expect(equationAnswers.single, 1);

    final groupAnswers = <int>[];
    const equationPlan = TouchInteractionPlan(
      taskKey: 'process:representation:equation:2:3',
      kind: TouchInteractionKind.equalGroupsBuilder,
      instruction: 'Baue das Gruppenbild.',
      groupCount: 2,
      itemsPerGroup: 3,
      totalItems: 6,
      dataOperation: 'representation-choice',
      expectedAnswer: 3,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: equationPlan, onAnswer: groupAnswers.add),
          ),
        ),
      ),
    );
    for (var group = 0; group < 2; group++) {
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(ValueKey('touch-equal-group-$group-add')));
      }
    }
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-equal-groups-submit')));
    expect(groupAnswers.single, 3);
  });

  testWidgets('cube-net face counter needs every actual square', (tester) async {
    final answers = <int>[];
    const plan = TouchInteractionPlan(
      taskKey: 'body:cube-net:faces',
      kind: TouchInteractionKind.cubeNetFaceCounter,
      instruction: 'Markiere die Quadrate.',
      dataLabels: <String>['1,0', '0,1', '1,1', '2,1', '3,1', '1,2'],
      expectedAnswer: 6,
      maxValue: 6,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(plan: plan, onAnswer: answers.add),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(ValueKey('touch-cube-net-face-$i')));
    }
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-cube-net-face-submit')));
    expect(answers.last, 5);
    await tester.tap(find.byKey(const ValueKey('touch-cube-net-face-5')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-cube-net-face-submit')));
    expect(answers.last, 6);
  });

  test('targeted multiplication groups select manipulable positive facts', () {
    final engine = AdaptiveEngine(random: Random(26091551));
    final facts = AdaptiveEngine.buildFactPool(maxValue: 20);
    for (var i = 0; i < 60; i++) {
      final fact = engine.selectNext(
        facts: facts,
        mode: TrainingMode.multiply,
        maxValue: 20,
        targetCompetency: MicroCompetencyId.multiplicationGroups,
      );
      expect(fact.a, greaterThan(0));
      expect(fact.b, greaterThan(0));
      expect(min(fact.a, fact.b), lessThanOrEqualTo(6));
      expect(fact.result, lessThanOrEqualTo(48));
      final plan = TouchInteractionPlan.forTask(
        mode: TrainingMode.multiply,
        taskKey: fact.key,
        answer: fact.result,
        maxValue: 20,
        targetCompetency: MicroCompetencyId.multiplicationGroups,
      );
      expect(plan?.kind, TouchInteractionKind.equalGroupsBuilder);
    }
  });

  testWidgets('new representation touch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'body:cube-net:faces',
      kind: TouchInteractionKind.cubeNetFaceCounter,
      instruction: 'Tippe jedes Quadrat genau einmal an.',
      dataLabels: <String>['1,0', '0,1', '1,1', '2,1', '3,1', '1,2'],
      expectedAnswer: 6,
      maxValue: 6,
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
    expect(find.byKey(const ValueKey('touch-cube-net-face-grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
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


class _FixedStructuredGenerator extends StructuredExerciseGenerator {
  _FixedStructuredGenerator(this.exercise);

  final StructuredExercise exercise;

  @override
  StructuredExercise generate({
    required TrainingMode mode,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
    GradeLevel gradeLevel = GradeLevel.second,
    bool transferEmphasis = false,
  }) => exercise;


}
