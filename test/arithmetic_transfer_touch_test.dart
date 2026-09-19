import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/widgets/touch_answer_interaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _maxValueFor(MicroCompetencyDefinition definition) {
  final range = NumberRangeLevel.values.firstWhere(
    (value) =>
        value.index >= definition.minGrade.recommendedRange.index &&
        value.index >= definition.minNumberRange.index,
  );
  return range.maxValue;
}

TouchInteractionPlan? _planFor(
  StructuredExercise exercise,
  MicroCompetencyId id,
) {
  return TouchInteractionPlan.forTask(
    mode: exercise.mode,
    taskKey: exercise.key,
    answer: exercise.answer,
    maxValue: exercise.maxAnswerValue ?? 100,
    wallValues: exercise.wallValues,
    hiddenWallIndex: exercise.hiddenWallIndex,
    choices: exercise.choices,
    clockHour: exercise.clockHour,
    clockMinute: exercise.clockMinute,
    answerSuffix: exercise.answerSuffix,
    targetCompetency: id,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'arithmetische Transfer-Sachaufgaben bleiben über viele Seeds touchfähig',
    () {
      const targets = <MicroCompetencyId>[
        MicroCompetencyId.additionNoBridge,
        MicroCompetencyId.additionTenBridge,
        MicroCompetencyId.subtractionNoBridge,
        MicroCompetencyId.subtractionTenBridge,
        MicroCompetencyId.multiplicationGroups,
        MicroCompetencyId.multiplicationFacts,
        MicroCompetencyId.divisionSharing,
        MicroCompetencyId.divisionFacts,
      ];

      for (final id in targets) {
        final definition = MicroCompetencyCatalog.definition(id);
        final maxValue = _maxValueFor(definition);
        for (var seed = 0; seed < 64; seed++) {
          final exercise =
              StructuredExerciseGenerator(
                random: Random(880000 + id.index * 100 + seed),
              ).generate(
                mode: TrainingMode.wordProblems,
                gradeLevel: definition.minGrade,
                maxValue: maxValue,
                targetCompetency: id,
                transferEmphasis: true,
              );
          final plan = _planFor(exercise, id);
          expect(
            plan,
            isNotNull,
            reason: '${id.name} · seed $seed · ${exercise.key}',
          );

          final expectedKind = switch (id) {
            MicroCompetencyId.additionNoBridge ||
            MicroCompetencyId.additionTenBridge ||
            MicroCompetencyId.subtractionNoBridge ||
            MicroCompetencyId.subtractionTenBridge =>
              TouchInteractionKind.numberLine,
            MicroCompetencyId.multiplicationGroups ||
            MicroCompetencyId.multiplicationFacts =>
              TouchInteractionKind.equalGroupsBuilder,
            MicroCompetencyId.divisionSharing ||
            MicroCompetencyId.divisionFacts =>
              TouchInteractionKind.divisionGroupsBuilder,
            _ => throw StateError('Unerwartetes Transferziel: $id'),
          };
          expect(
            plan!.kind,
            expectedKind,
            reason: '${id.name} · seed $seed · ${exercise.key}',
          );
        }
      }
    },
  );

  test('Plus- und Minus-Transfer übernimmt Start, Schritt und Richtung', () {
    final plus = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:transfer:skill:additionTenBridge:+:stickers:8:7',
      answer: 15,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.additionTenBridge,
    );
    final minus = TouchInteractionPlan.forTask(
      mode: TrainingMode.wordProblems,
      taskKey: 'story:transfer:skill:subtractionTenBridge:-:cards:15:7',
      answer: 8,
      maxValue: 20,
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
    );

    expect(plus?.kind, TouchInteractionKind.numberLine);
    expect(plus?.startValue, 8);
    expect(plus?.dataValues, <int>[8, 7]);
    expect(plus?.dataOperation, '+');
    expect(plus?.expectedAnswer, 15);

    expect(minus?.kind, TouchInteractionKind.numberLine);
    expect(minus?.startValue, 15);
    expect(minus?.dataValues, <int>[15, 7]);
    expect(minus?.dataOperation, '-');
    expect(minus?.expectedAnswer, 8);
  });

  test(
    'Mal-Transfer bewahrt die Gruppenreihenfolge statt Faktoren zu tauschen',
    () {
      final direct = TouchInteractionPlan.forTask(
        mode: TrainingMode.multiply,
        taskKey: 'multiply:7:4',
        answer: 28,
        maxValue: 100,
        targetCompetency: MicroCompetencyId.multiplicationGroups,
      );
      final transfer = TouchInteractionPlan.forTask(
        mode: TrainingMode.wordProblems,
        taskKey: 'story:transfer:skill:multiplicationFacts:x:rows:7:4',
        answer: 28,
        maxValue: 100,
        targetCompetency: MicroCompetencyId.multiplicationFacts,
      );

      expect((direct?.groupCount, direct?.itemsPerGroup), (7, 4));
      expect((transfer?.groupCount, transfer?.itemsPerGroup), (7, 4));

      final tooManyGroups = TouchInteractionPlan.forTask(
        mode: TrainingMode.multiply,
        taskKey: 'multiply:9:4',
        answer: 36,
        maxValue: 100,
        targetCompetency: MicroCompetencyId.multiplicationGroups,
      );
      expect(
        tooManyGroups,
        isNull,
        reason:
            '9 Gruppen dürfen nicht still zu 4 Gruppen à 9 umgebaut werden.',
      );
    },
  );

  test(
    'direkte Mal- und Geteilt-Fakten bleiben bewusst klassische Eingabe',
    () {
      expect(
        TouchInteractionPlan.forTask(
          mode: TrainingMode.multiply,
          taskKey: 'multiply:7:6',
          answer: 42,
          maxValue: 100,
          targetCompetency: MicroCompetencyId.multiplicationFacts,
        ),
        isNull,
      );
      expect(
        TouchInteractionPlan.forTask(
          mode: TrainingMode.divide,
          taskKey: 'divide:42:6',
          answer: 7,
          maxValue: 100,
          targetCompetency: MicroCompetencyId.divisionFacts,
        ),
        isNull,
      );
    },
  );

  test(
    'gezieltes Gruppenlernen erzeugt manipulierbare Faktoren in Reihenfolge',
    () {
      final facts = AdaptiveEngine.buildFactPool(maxValue: 100);
      for (var seed = 0; seed < 64; seed++) {
        final fact = AdaptiveEngine(random: Random(990000 + seed)).selectNext(
          facts: facts,
          mode: TrainingMode.multiply,
          maxValue: 100,
          targetCompetency: MicroCompetencyId.multiplicationGroups,
        );
        expect(fact.operation, MathOperation.multiply);
        expect(fact.a, inInclusiveRange(1, 8));
        expect(fact.b, inInclusiveRange(1, 10));
        expect(fact.result, lessThanOrEqualTo(80));

        final plan = TouchInteractionPlan.forTask(
          mode: TrainingMode.multiply,
          taskKey: fact.key,
          answer: fact.result,
          maxValue: 100,
          targetCompetency: MicroCompetencyId.multiplicationGroups,
        );
        expect(plan?.kind, TouchInteractionKind.equalGroupsBuilder);
        expect((plan?.groupCount, plan?.itemsPerGroup), (fact.a, fact.b));
      }
    },
  );

  testWidgets(
    'Gruppen können rundenweise statt mit Dutzenden Taps gebaut werden',
    (tester) async {
      var answer = -1;
      const plan = TouchInteractionPlan(
        taskKey: 'multiply:6:9',
        kind: TouchInteractionKind.equalGroupsBuilder,
        instruction: 'Baue 6 Gruppen mit jeweils 9 Punkten.',
        groupCount: 6,
        itemsPerGroup: 9,
        totalItems: 54,
        expectedAnswer: 54,
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

      final addRound = find.byKey(
        const ValueKey('touch-equal-groups-round-add'),
      );
      final removeRound = find.byKey(
        const ValueKey('touch-equal-groups-round-remove'),
      );
      expect(addRound, findsOneWidget);
      expect(removeRound, findsOneWidget);

      await tester.tap(addRound);
      await tester.pump();
      await tester.tap(removeRound);
      await tester.pump();

      for (var round = 0; round < 9; round++) {
        await tester.tap(addRound);
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('touch-equal-groups-submit')));
      await tester.pump();

      expect(answer, 54);
    },
  );

  testWidgets('Plus-Transfer öffnet im Training direkt als Touch-Aufgabe', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;

    const exercise = StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt:
          'In einer Mappe sind 8 Sticker. 7 kommen dazu. Wie viele sind es?',
      answer: 15,
      hint: 'Die Menge wird größer.',
      key: 'story:transfer:skill:additionTenBridge:+:stickers:8:7',
      maxAnswerValue: 20,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetTasks: 1,
          targetCompetency: MicroCompetencyId.additionTenBridge,
          transferEmphasis: true,
          exerciseGenerator: _FixedStructuredGenerator(exercise),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('touch-number-line-slider')),
      findsOneWidget,
    );
  });

  testWidgets('große Gruppen bleiben bei 200 Prozent Schrift stabil', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TouchAnswerInteraction(
              plan: TouchInteractionPlan(
                taskKey: 'multiply:8:10',
                kind: TouchInteractionKind.equalGroupsBuilder,
                instruction: 'Baue 8 Gruppen mit jeweils 10 Punkten.',
                groupCount: 8,
                itemsPerGroup: 10,
                totalItems: 80,
                expectedAnswer: 80,
              ),
              onAnswer: _noopAnswer,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('touch-equal-groups-round-add')),
      findsOneWidget,
    );
  });
}

void _noopAnswer(int _) {}

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
