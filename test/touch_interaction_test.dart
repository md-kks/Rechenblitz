import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
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
          taskKey: 'rect:perimeter:beet:8:5',
          kind: TouchInteractionKind.rectanglePerimeterEdges,
          instruction: 'Tippe alle Kanten an.',
          rectangleWidth: 8,
          rectangleHeight: 5,
          correctSelectionIndexes: <int>[0, 1, 2, 3],
          expectedAnswer: 26,
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
    expect(perimeter?.kind, TouchInteractionKind.rectanglePerimeterEdges);
    expect(perimeter?.rectangleWidth, 8);
    expect(perimeter?.rectangleHeight, 5);
    expect(perimeter?.expectedAnswer, 26);
    expect(area, isNull);
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
    await tester.tap(find.byKey(const ValueKey('touch-fraction-submit')));
    expect(answer, 15);
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
