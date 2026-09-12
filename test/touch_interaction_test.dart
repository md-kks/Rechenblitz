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

    final hourSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('touch-clock-hour-slider')),
    );
    hourSlider.onChanged!(3);
    await tester.pump();
    final minuteSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('touch-clock-minute-slider')),
    );
    minuteSlider.onChanged!(1);
    await tester.pump();
    expect(find.text('3:30 Uhr'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-clock-submit')));
    expect(answer, 0);
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
        240,
        scrollable: find.byType(Scrollable).first,
      );
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
