import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/widgets/number_answer_pad.dart';
import 'package:rechenblitz/widgets/touch_answer_interaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('gezieltes Plus und Minus nutzt einen lokalen Zahlenstrahl', () {
    final plus = TouchInteractionPlan.forTask(
      mode: TrainingMode.practice,
      taskKey: 'plus:9:8',
      answer: 17,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );
    final minus = TouchInteractionPlan.forTask(
      mode: TrainingMode.minus,
      taskKey: 'minus:15:7',
      answer: 8,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
    );
    expect(plus?.kind, TouchInteractionKind.numberLine);
    expect(plus?.startValue, 9);
    expect(plus?.dataValues, <int>[9, 8]);
    expect(plus?.dataOperation, '+');
    expect(plus?.minValue, 7);
    expect(plus?.maxValue, 19);
    expect(plus?.instruction, contains('nach rechts'));

    expect(minus?.kind, TouchInteractionKind.numberLine);
    expect(minus?.startValue, 15);
    expect(minus?.dataValues, <int>[15, 7]);
    expect(minus?.dataOperation, '-');
    expect(minus?.minValue, 6);
    expect(minus?.maxValue, 17);
    expect(minus?.instruction, contains('nach rechts'));
  });

  test('Lerncheck und Faktenabruf bleiben bewusst klassisch', () {
    final assessmentLike = TouchInteractionPlan.forTask(
      mode: TrainingMode.practice,
      taskKey: 'plus:9:8',
      answer: 17,
      maxValue: 20,
    );
    final multiplyFact = TouchInteractionPlan.forTask(
      mode: TrainingMode.multiply,
      taskKey: 'multiply:3:4',
      answer: 12,
      maxValue: 100,
      targetCompetency: MicroCompetencyId.multiplicationFacts,
    );
    final divideFact = TouchInteractionPlan.forTask(
      mode: TrainingMode.divide,
      taskKey: 'divide:12:3',
      answer: 4,
      maxValue: 100,
      targetCompetency: MicroCompetencyId.divisionFacts,
    );

    expect(assessmentLike, isNull);
    expect(multiplyFact, isNull);
    expect(divideFact, isNull);
  });

  testWidgets(
    'gezieltes Plus startet interaktiv und erlaubt Tastatur-Fallback',
    (tester) async {
      final controller = AppController()
        ..gradeLevel = GradeLevel.second
        ..numberRange = NumberRangeLevel.twenty
        ..facts = <MathFact>[
          MathFact(a: 5, b: 4, operation: MathOperation.plus),
        ];

      await tester.pumpWidget(
        MaterialApp(
          home: TrainingScreen(
            controller: controller,
            mode: TrainingMode.practice,
            targetTasks: 1,
            targetCompetency: MicroCompetencyId.additionNoBridge,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('touch-answer-interaction')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('touch-number-line-slider')),
        findsOneWidget,
      );

      final keypadSwitch = find.byKey(const ValueKey('touch-switch-keypad'));
      await tester.scrollUntilVisible(
        keypadSwitch,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(keypadSwitch);
      await tester.pump();

      expect(find.byType(NumberAnswerPad), findsOneWidget);
      expect(
        find.byKey(const ValueKey('touch-answer-interaction')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Minus-Rechenweg läuft von der großen Zahl links zum Ergebnis rechts',
    (tester) async {
      final plan = TouchInteractionPlan.forTask(
        mode: TrainingMode.minus,
        taskKey: 'minus:15:7',
        answer: 8,
        maxValue: 20,
        targetCompetency: MicroCompetencyId.subtractionTenBridge,
      );
      expect(plan, isNotNull);
      var answer = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchAnswerInteraction(
              plan: plan!,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      );
      await tester.pump();

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('touch-number-line-slider')),
      );
      expect(slider.value, 8);
      expect(find.text('15'), findsOneWidget);

      slider.onChanged!(15);
      await tester.pump();
      final selected = tester.widget<Text>(
        find.byKey(const ValueKey('touch-number-line-value')),
      );
      expect(selected.data, '8');

      await tester.tap(find.byKey(const ValueKey('touch-number-line-submit')));
      expect(answer, 8);
    },
  );

  testWidgets('Fluency-Fokus bleibt direkte Eingabe ohne Touch-Gerüst', (
    tester,
  ) async {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.twenty
      ..facts = <MathFact>[MathFact(a: 5, b: 4, operation: MathOperation.plus)];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.additionNoBridge,
          fluencyEmphasis: true,
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
}
