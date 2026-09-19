import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _tinyLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('plain fact pad remains usable at 320x568 and 200 percent', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    _tinyLargeText(tester);

    final controller = AppController();
    controller.loaded = true;
    controller.numberRange = NumberRangeLevel.twenty;
    controller.facts = [MathFact(a: 7, b: 5, operation: MathOperation.plus)];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final submit = find.byKey(const ValueKey('number-pad-submit'));
    expect(submit, findsOneWidget);
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('training-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.maxScrollExtent, 0);
  });

  testWidgets('number-friend task remains usable at 320x568 and 200 percent', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    _tinyLargeText(tester);

    final controller = AppController();
    controller.loaded = true;
    controller.numberRange = NumberRangeLevel.twenty;
    controller.facts = [MathFact(a: 3, b: 17, operation: MathOperation.plus)];

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.numberFriends,
          targetTasks: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('20 = 3 + ?'), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('training-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.maxScrollExtent, 0);

    final keypadSwitch = find.byKey(const ValueKey('touch-switch-keypad'));
    expect(keypadSwitch, findsOneWidget);
    await tester.tap(keypadSwitch);
    await tester.pump();
    expect(find.byKey(const ValueKey('number-pad-grid')), findsOneWidget);
    expect(scrollable.position.maxScrollExtent, 0);

    final touchSwitch = find.byKey(const ValueKey('touch-switch-interaction'));
    expect(touchSwitch, findsOneWidget);
    await tester.tap(touchSwitch);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('touch-number-bond-groups')),
      findsOneWidget,
    );
    expect(scrollable.position.maxScrollExtent, 0);
  });

  testWidgets('structured pad remains usable at 320x568 and 200 percent', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    _tinyLargeText(tester);

    final controller = AppController();
    controller.loaded = true;
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;
    const task = StructuredExercise(
      mode: TrainingMode.missingNumber,
      prompt: '12 + ? = 20',
      answer: 8,
      hint: 'Ergänze bis 20.',
      key: 'small:structured',
      maxAnswerValue: 20,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.missingNumber,
          targetTasks: 1,
          exerciseGenerator: _Structured(task),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('structured-training-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.maxScrollExtent, 0);
  });

  testWidgets('long word problem stays enlarged and scrollable at 200 percent', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    _tinyLargeText(tester);

    final controller = AppController();
    controller.loaded = true;
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    const prompt =
        'In einer Kiste liegen 24 Bausteine. 17 weitere kommen dazu. Wie viele Bausteine liegen danach insgesamt in der Kiste?';
    const task = StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt: prompt,
      answer: 41,
      hint: 'Die Menge wird größer.',
      key: 'small:word-problem',
      maxAnswerValue: 100,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetTasks: 1,
          exerciseGenerator: _Structured(task),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.text(prompt)).height, greaterThan(100));
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('structured-training-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('curriculum pad remains usable at 320x568 and 200 percent', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    _tinyLargeText(tester);

    final controller = AppController();
    controller.loaded = true;
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    const task = CurriculumExercise(
      mode: TrainingMode.largeNumbers,
      prompt: 'Wie viel ist 120 + 30?',
      answer: 150,
      hint: 'Addiere drei Zehner.',
      key: 'small:curriculum',
      maxAnswerValue: 1000,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.largeNumbers,
          targetTasks: 1,
          exerciseGenerator: _Curriculum(task),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('curriculum-training-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.maxScrollExtent, 0);
  });
}

class _Structured extends StructuredExerciseGenerator {
  _Structured(this.task);
  final StructuredExercise task;

  @override
  StructuredExercise generate({
    required TrainingMode mode,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
    GradeLevel gradeLevel = GradeLevel.second,
    bool transferEmphasis = false,
  }) => task;
}

class _Curriculum extends CurriculumExerciseGenerator {
  _Curriculum(this.task);
  final CurriculumExercise task;

  @override
  CurriculumExercise generate({
    required TrainingMode mode,
    required GradeLevel gradeLevel,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
    bool transferEmphasis = false,
  }) => task;
}
