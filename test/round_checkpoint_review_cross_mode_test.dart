import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/widgets/independent_step_card.dart';
import 'package:rechenblitz/widgets/number_answer_pad.dart';
import 'package:rechenblitz/widgets/touch_answer_interaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Grundrechnen zeigt konkrete erste falsche Zwischenantwort', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;
    final fact = MathFact(a: 8, b: 7, operation: MathOperation.plus);
    controller.facts = <MathFact>[fact];
    final steps = GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: TrainingMode.practice,
      fact: fact,
      preferences: controller.effectiveMethodPreferences,
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );
    expect(steps, isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.additionTenBridge,
          announceCompletion: false,
        ),
      ),
    );
    await tester.pump();

    await _failFirstCheckpointThenFinish(tester, steps: steps, finalAnswer: 15);
    final first = steps.first;
    final wrongChoice = first.correctChoice == 0 ? 1 : 0;
    expect(find.text('Zwischenschritt: ${first.question}'), findsOneWidget);
    expect(
      find.text(
        'Dein erster Versuch im Schritt: ${first.choices[wrongChoice]}',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Richtig im Schritt: ${first.choices[first.correctChoice!]}'),
      findsOneWidget,
    );
  });

  testWidgets('Lehrplanmodus zeigt konkrete erste falsche Zwischenantwort', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    const task = CurriculumExercise(
      mode: TrainingMode.rounding,
      prompt: 'Runde 153 auf Zehner.',
      answer: 150,
      hint: 'Schau auf die Einerstelle.',
      key: 'round:153:10',
      maxAnswerValue: 1000,
    );
    final steps = GuidedMethodFactory.independentWrittenStepsForTask(
      mode: task.mode,
      taskKey: task.key,
      expected: task.answer,
      preferences: controller.effectiveMethodPreferences,
      targetCompetency: MicroCompetencyId.roundingPlace,
    );
    expect(steps, isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: task.mode,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.roundingPlace,
          announceCompletion: false,
          exerciseGenerator: _FixedCurriculumGenerator(task),
        ),
      ),
    );
    await tester.pump();

    await _failFirstCheckpointThenFinish(
      tester,
      steps: steps,
      finalAnswer: task.answer,
    );

    final first = steps.first;
    final wrongChoice = first.correctChoice == 0 ? 1 : 0;
    expect(find.text('Zwischenschritt: ${first.question}'), findsOneWidget);
    expect(
      find.text(
        'Dein erster Versuch im Schritt: ${first.choices[wrongChoice]}',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Richtig im Schritt: ${first.choices[first.correctChoice!]}'),
      findsOneWidget,
    );
  });
}

Future<void> _failFirstCheckpointThenFinish(
  WidgetTester tester, {
  required List<GuidedMethodStep> steps,
  required int finalAnswer,
}) async {
  final first = steps.first;
  final wrongChoice = first.correctChoice == 0 ? 1 : 0;

  await tester.tap(
    find.widgetWithText(FilledButton, first.choices[wrongChoice]),
  );
  await tester.pump();
  await tester.tap(
    find.widgetWithText(FilledButton, first.choices[first.correctChoice!]),
  );
  await tester.pump(const Duration(milliseconds: 400));

  while (find.byType(IndependentStepCard).evaluate().isNotEmpty) {
    final card = tester.widget<IndependentStepCard>(
      find.byType(IndependentStepCard),
    );
    final step = steps[card.index];
    await tester.tap(
      find.widgetWithText(FilledButton, step.choices[step.correctChoice!]),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
  final touch = find.byType(TouchAnswerInteraction);
  if (touch.evaluate().isNotEmpty) {
    tester.widget<TouchAnswerInteraction>(touch).onAnswer(finalAnswer);
  } else {
    tester
        .widget<NumberAnswerPad>(find.byType(NumberAnswerPad))
        .onAnswer(finalAnswer);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

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
    bool transferEmphasis = false,
  }) => exercise;
}
