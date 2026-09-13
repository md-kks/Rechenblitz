import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/main.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _compactLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

AppController _controller() {
  final controller = AppController();
  controller.facts = const [];
  controller.loaded = true;
  return controller;
}

Future<AppController> _controllerWithFacts() async {
  final controller = AppController();
  await controller.load();
  return controller;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Startseite bleibt bei schmalem Display und großer Schrift stabil',
    (tester) async {
      _compactLargeText(tester);
      await tester.pumpWidget(RechenblitzApp(controller: _controller()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Mehr'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Schulauftrag'), findsOneWidget);
    },
  );

  testWidgets(
    'Meine Runde bleibt bei schmalem Display und großer Schrift stabil',
    (tester) async {
      _compactLargeText(tester);
      await tester.pumpWidget(RechenblitzApp(controller: _controller()));
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey('my-round-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Etwa 5–8 Minuten Mathe.'), findsOneWidget);
    },
  );

  testWidgets(
    'Blitzaufgabe bleibt bei schmalem Display und großer Schrift stabil',
    (tester) async {
      _compactLargeText(tester);
      final controller = await _controllerWithFacts();
      await tester.pumpWidget(
        MaterialApp(
          home: TrainingScreen(
            controller: controller,
            mode: TrainingMode.blitz,
            targetTasks: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TrainingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Sachaufgabe bleibt bei schmalem Display und großer Schrift stabil',
    (tester) async {
      _compactLargeText(tester);
      final controller = await _controllerWithFacts();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.twenty;
      await tester.pumpWidget(
        MaterialApp(
          home: StructuredTrainingScreen(
            controller: controller,
            mode: TrainingMode.wordProblems,
            targetTasks: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StructuredTrainingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Klasse-3-Aufgabe bleibt bei schmalem Display und großer Schrift stabil',
    (tester) async {
      _compactLargeText(tester);
      final controller = await _controllerWithFacts();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      await tester.pumpWidget(
        MaterialApp(
          home: CurriculumTrainingScreen(
            controller: controller,
            mode: TrainingMode.largeNumbers,
            targetTasks: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CurriculumTrainingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'normale Rechenaufgabe zeigt komplettes Tastenfeld ohne Scrollen',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppController();
      controller.loaded = true;
      controller.numberRange = NumberRangeLevel.twenty;
      controller.facts = [
        MathFact(a: 7, b: 5, operation: MathOperation.plus),
      ];

      for (final size in const <Size>[
        Size(320, 568),
        Size(360, 640),
        Size(412, 915),
        Size(800, 1280),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: TrainingScreen(
              controller: controller,
              mode: TrainingMode.practice,
              targetTasks: 1,
              reviewEmphasis: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final submit = find.byKey(const ValueKey('number-pad-submit'));
        expect(submit, findsOneWidget, reason: 'Display $size');
        final submitRect = tester.getRect(submit);
        expect(
          submitRect.bottom,
          lessThanOrEqualTo(size.height),
          reason: 'OK muss auf $size sichtbar sein',
        );
        final scrollable = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('training-scroll')),
            matching: find.byType(Scrollable),
          ).first,
        );
        expect(
          scrollable.position.maxScrollExtent,
          0,
          reason: 'Normale Aufgabe darf auf $size nicht scrollen',
        );
      }

    },
  );

  testWidgets(
    'strukturierte einfache Aufgabe braucht auf kleinem Handy keinen Scroll',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;

      final controller = await _controllerWithFacts();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.twenty;
      const exercise = StructuredExercise(
        mode: TrainingMode.missingNumber,
        prompt: '12 + ? = 20',
        answer: 8,
        hint: 'Ergänze bis 20.',
        key: 'layout:structured',
        maxAnswerValue: 20,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: StructuredTrainingScreen(
            controller: controller,
            mode: TrainingMode.missingNumber,
            targetTasks: 1,
            exerciseGenerator: _LayoutStructuredGenerator(exercise),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('structured-compact-help')),
        findsOneWidget,
      );
      final submit = find.byKey(const ValueKey('number-pad-submit'));
      expect(submit, findsOneWidget);
      expect(tester.getRect(submit).bottom, lessThanOrEqualTo(568));
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey('structured-training-scroll')),
          matching: find.byType(Scrollable),
        ).first,
      );
      expect(scrollable.position.maxScrollExtent, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Lehrplan-Aufgabe mit Tastenfeld braucht auf kleinem Handy keinen Scroll',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;

      final controller = await _controllerWithFacts();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      const exercise = CurriculumExercise(
        mode: TrainingMode.largeNumbers,
        prompt: 'Wie viel ist 120 + 30?',
        answer: 150,
        hint: 'Addiere drei Zehner.',
        key: 'layout:plain',
        maxAnswerValue: 1000,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CurriculumTrainingScreen(
            controller: controller,
            mode: TrainingMode.largeNumbers,
            targetTasks: 1,
            exerciseGenerator: _LayoutCurriculumGenerator(exercise),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('curriculum-compact-help')),
        findsOneWidget,
      );
      final submit = find.byKey(const ValueKey('number-pad-submit'));
      expect(submit, findsOneWidget);
      expect(tester.getRect(submit).bottom, lessThanOrEqualTo(568));
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey('curriculum-training-scroll')),
          matching: find.byType(Scrollable),
        ).first,
      );
      expect(scrollable.position.maxScrollExtent, 0);
      expect(tester.takeException(), isNull);
    },
  );

}


class _LayoutCurriculumGenerator extends CurriculumExerciseGenerator {
  _LayoutCurriculumGenerator(this.exercise);

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


class _LayoutStructuredGenerator extends StructuredExerciseGenerator {
  _LayoutStructuredGenerator(this.exercise);

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
