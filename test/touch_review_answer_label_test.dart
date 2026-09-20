import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/widgets/number_answer_pad.dart';
import 'package:rechenblitz/widgets/touch_answer_interaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Gruppenfehler meldet die sichtbare Verteilung für die Rückschau',
    (tester) async {
      var answer = -1;
      String? reviewLabel;
      const plan = TouchInteractionPlan(
        taskKey: 'multiply:3:4',
        kind: TouchInteractionKind.equalGroupsBuilder,
        instruction: 'Baue 3 Gruppen mit jeweils 4 Punkten.',
        groupCount: 3,
        itemsPerGroup: 4,
        totalItems: 12,
        expectedAnswer: 12,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TouchAnswerInteraction(
                plan: plan,
                onReviewAnswer: (label) => reviewLabel = label,
                onAnswer: (value) => answer = value,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('touch-equal-group-0-add')));
      final submit = find.byKey(const ValueKey('touch-equal-groups-submit'));
      await tester.tap(submit);
      await tester.pump();

      expect(answer, 1);
      expect(reviewLabel, 'Gruppen: 1, 0, 0 Punkte');
    },
  );
  testWidgets('Diagrammfehler nennt die tatsächlich markierten Balken', (
    tester,
  ) async {
    var answer = -1;
    String? reviewLabel;
    const plan = TouchInteractionPlan(
      taskKey: 'data:max:3-5-2-4',
      kind: TouchInteractionKind.dataChartSelection,
      instruction: 'Markiere den höchsten Balken.',
      dataValues: <int>[3, 5, 2, 4],
      dataLabels: <String>['Rot', 'Blau', 'Grün', 'Gelb'],
      dataOperation: 'max',
      expectedAnswer: 5,
      maxValue: 12,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: plan,
              onReviewAnswer: (label) => reviewLabel = label,
              onAnswer: (value) => answer = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('touch-data-bar-0')));
    await tester.tap(find.byKey(const ValueKey('touch-data-bar-2')));
    await tester.tap(find.byKey(const ValueKey('touch-data-submit')));
    await tester.pump();

    expect(answer, 2);
    expect(reviewLabel, 'Markierte Balken: Rot, Grün');
  });
  testWidgets(
    'strukturierte Runde zeigt menschenlesbaren Touch-Erstversuch im Abschluss',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.twenty;
      const task = StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt: '3 Reihen mit je 4 Punkten. Wie viele Punkte sind es?',
        answer: 12,
        hint: 'Baue gleich große Gruppen.',
        key: 'story:transfer:skill:multiplicationGroups:x:rows:3:4',
        maxAnswerValue: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StructuredTrainingScreen(
            controller: controller,
            mode: TrainingMode.wordProblems,
            targetTasks: 1,
            targetCompetency: MicroCompetencyId.multiplicationGroups,
            transferEmphasis: true,
            announceCompletion: false,
            exerciseGenerator: _FixedStructuredGenerator(task),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('touch-equal-group-0-add')));
      final submit = find.byKey(const ValueKey('touch-equal-groups-submit'));
      await tester.scrollUntilVisible(
        submit,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submit);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final switchToPad = find.byKey(const ValueKey('touch-switch-keypad'));
      await tester.ensureVisible(switchToPad);
      await tester.tap(switchToPad);
      await tester.pump();

      final pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
      pad.onAnswer(12);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Runde geschafft!'), findsOneWidget);
      expect(
        find.text('Dein erster Versuch: Gruppen: 1, 0, 0 Punkte'),
        findsOneWidget,
      );
      final stored = controller.history.single.attemptReviews;
      expect(stored, isNotNull);
      expect(stored!.single.firstAnswer, 'Gruppen: 1, 0, 0 Punkte');
      expect(stored.single.correctAnswer, '12');
    },
  );
}

class _FixedStructuredGenerator extends StructuredExerciseGenerator {
  _FixedStructuredGenerator(this.task);

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
