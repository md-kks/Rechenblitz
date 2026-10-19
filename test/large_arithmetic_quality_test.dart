import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/arithmetic_strategy.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/my_round_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('Stellenwertanalyse für große Grundrechenarten', () {
    test('zerlegt Operanden und erkennt mehrere Übergänge', () {
      final plus = MathFact(a: 347, b: 286, operation: MathOperation.plus);
      final minus = MathFact(a: 743, b: 286, operation: MathOperation.minus);

      expect(ArithmeticStrategy.placeValueChunks(286), [200, 80, 6]);
      expect(ArithmeticStrategy.additionCarryPlaces(plus), [10, 100]);
      expect(ArithmeticStrategy.subtractionBorrowPlaces(minus), [10, 100]);
      expect(ArithmeticStrategy.digitwiseAbsoluteSubtraction(minus), 543);
      expect(
        ArithmeticStrategy.difficultyLabel(plus),
        'Addition mit mehreren Stellenübergängen',
      );
      expect(
        ArithmeticStrategy.difficultyLabel(minus),
        'Subtraktion mit mehreren Entbündelungen',
      );
    });

    test('Teilen zerlegt in tatsächlich teilbare Blöcke', () {
      final fact = MathFact(a: 248, b: 4, operation: MathOperation.divide);
      expect(ArithmeticStrategy.divisionQuotientChunks(fact), [60, 2]);
      expect(ArithmeticStrategy.divisionDividendChunks(fact), [240, 8]);
      expect(
        ArithmeticStrategy.divisionDividendChunks(fact)
            .every((chunk) => chunk % fact.b == 0),
        isTrue,
      );
    });
  });

  group('Konkrete Hilfen für große Aufgaben', () {
    const preferences = MethodPreferences();

    GuidedMethodGuide guide(MathFact fact, TrainingMode mode) =>
        GuidedMethodFactory.forTask(
          mode: mode,
          taskKey: fact.key,
          expected: fact.result,
          preferences: preferences,
          fact: fact,
        );

    test('Plus zeigt die echten Stellenwertschritte', () {
      final fact = MathFact(a: 347, b: 286, operation: MathOperation.plus);
      final result = guide(fact, TrainingMode.practice);

      expect(result.methodKey, 'addition:placeValueChunks');
      expect(result.nudge, contains('200 + 80 + 6'));
      expect(result.steps, hasLength(3));
      expect(result.steps[0].instruction, 'Rechne 347 + 200.');
      expect(result.steps[1].instruction, 'Rechne 547 + 80.');
      expect(result.steps[2].instruction, 'Rechne 627 + 6.');
      expect(
        result.steps.first.evidenceCompetency,
        MicroCompetencyId.largeAdditionMultiRegroup,
      );
    });

    test('Malnehmen arbeitet mit Teilprodukten statt riesigen Gruppenbildern', () {
      final fact = MathFact(a: 247, b: 6, operation: MathOperation.multiply);
      final result = guide(fact, TrainingMode.multiply);

      expect(result.methodKey, 'multiplication:placeValueChunks');
      expect(result.nudge, contains('200 + 40 + 7'));
      expect(result.steps[0].instruction, 'Rechne 200 × 6.');
      expect(result.steps[1].instruction, 'Rechne 40 × 6.');
      expect(result.steps[2].instruction, 'Rechne 7 × 6.');
      expect(result.steps.last.instruction, contains('1200 + 240 + 42'));
    });

    test('Teilen verwendet passende Teilquotienten', () {
      final fact = MathFact(a: 248, b: 4, operation: MathOperation.divide);
      final result = guide(fact, TrainingMode.divide);

      expect(result.methodKey, 'division:placeValueChunks');
      expect(result.nudge, contains('240 + 8'));
      expect(result.steps[0].instruction, 'Teile 240 ÷ 4.');
      expect(result.steps[1].instruction, 'Teile 8 ÷ 4.');
      expect(result.steps.last.instruction, contains('60 + 2'));
    });
  });

  group('Fehlerdiagnose für mehrstellige Strategierechnung', () {
    test('erkennt ausgelassenen Stellenwert und vergessenen Übertrag', () {
      final fact = MathFact(a: 347, b: 286, operation: MathOperation.plus);

      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.practice,
          taskKey: fact.key,
          expected: fact.result,
          actual: 433,
          fact: fact,
        ),
        ErrorPattern.partialOperand,
      );
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.practice,
          taskKey: fact.key,
          expected: fact.result,
          actual: 623,
          fact: fact,
        ),
        ErrorPattern.carryOmitted,
      );
    });

    test('erkennt Entbündeln über mehrere Stellen', () {
      final fact = MathFact(a: 743, b: 286, operation: MathOperation.minus);
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.minus,
          taskKey: fact.key,
          expected: fact.result,
          actual: 543,
          fact: fact,
        ),
        ErrorPattern.borrowAvoided,
      );
    });

    test('erkennt fehlendes Teilprodukt und fehlenden Teilquotienten', () {
      final multiply =
          MathFact(a: 247, b: 6, operation: MathOperation.multiply);
      final divide = MathFact(a: 248, b: 4, operation: MathOperation.divide);

      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.multiply,
          taskKey: multiply.key,
          expected: multiply.result,
          actual: 1200,
          fact: multiply,
        ),
        ErrorPattern.partialOperand,
      );
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.divide,
          taskKey: divide.key,
          expected: divide.result,
          actual: 60,
          fact: divide,
        ),
        ErrorPattern.partialOperand,
      );
    });

    test('unspezifischer Fehler bleibt bei der halbschriftlichen Strategie', () {
      final fact = MathFact(a: 247, b: 6, operation: MathOperation.multiply);
      expect(
        ErrorClassifier.classify(
          mode: TrainingMode.multiply,
          taskKey: fact.key,
          expected: fact.result,
          actual: 1111,
          fact: fact,
        ),
        ErrorPattern.mentalStrategy,
      );
    });
  });

  test('große Aufgaben liefern Evidenz für halbschriftliche Strategien', () {
    final plus = MathFact(a: 347, b: 286, operation: MathOperation.plus);
    final multiply =
        MathFact(a: 247, b: 6, operation: MathOperation.multiply);

    final plusTags = MicroCompetencyCatalog.tagsForTask(
      mode: TrainingMode.practice,
      taskKey: plus.key,
      fact: plus,
    );
    final multiplyTags = MicroCompetencyCatalog.tagsForTask(
      mode: TrainingMode.multiply,
      taskKey: multiply.key,
      fact: multiply,
    );

    expect(plusTags.first.id, MicroCompetencyId.largeAdditionMultiRegroup);
    expect(
      plusTags.any((tag) => tag.id == MicroCompetencyId.numberDecomposition),
      isTrue,
    );
    expect(multiplyTags.first.id, MicroCompetencyId.largeMultiplicationPartialProducts);
    expect(
      multiplyTags.any((tag) => tag.id == MicroCompetencyId.multiplicationFacts),
      isTrue,
    );
  });

  group('Touch-Zerlegung großer Aufgaben', () {
    test('Plus ordnet Stellenwertblöcke aktiv', () {
      final plan = TouchInteractionPlan.forTask(
        mode: TrainingMode.practice,
        taskKey: 'plus:347:286',
        answer: 633,
        maxValue: 1000,
      );
      expect(plan?.kind, TouchInteractionKind.mentalChunkPath);
      expect(plan?.dataValues, [347, 286, 200, 80, 6]);
      expect(plan?.dataOperation, '+');
    });

    test('Mal und Geteilt erhalten eigene Zerlegungswege', () {
      final multiply = TouchInteractionPlan.forTask(
        mode: TrainingMode.multiply,
        taskKey: 'multiply:247:6',
        answer: 1482,
        maxValue: 10000,
      );
      final divide = TouchInteractionPlan.forTask(
        mode: TrainingMode.divide,
        taskKey: 'divide:248:4',
        answer: 62,
        maxValue: 1000,
      );

      expect(multiply?.kind, TouchInteractionKind.mentalChunkPath);
      expect(multiply?.dataValues, [247, 6, 200, 40, 7]);
      expect(multiply?.dataOperation, 'multiply');
      expect(divide?.kind, TouchInteractionKind.mentalChunkPath);
      expect(divide?.dataValues, [248, 4, 240, 8]);
      expect(divide?.dataOperation, 'divide');
    });
  });

  group('Schwierigkeit wird innerhalb eines Zahlenraums aufgebaut', () {
    test('erste Plus-Stufe startet mit glatten Stellenwertblöcken', () {
      final generator = CurriculumExerciseGenerator(random: Random(17));
      for (var i = 0; i < 20; i++) {
        final exercise = generator.generateDirectArithmetic(
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.third,
          maxValue: 1000,
          directArithmeticStage: 0,
        );
        final parts = exercise.key.split(':');
        if (parts.first == 'plus') {
          expect(int.parse(parts[2]) % 100, 0);
        } else {
          expect(parts.first, 'minus');
          expect(int.parse(parts[2]) % 100, 0);
        }
      }
    });

    test('spätere Mal-Stufe erzeugt echte mehrstellige Zerlegung', () {
      final generator = CurriculumExerciseGenerator(random: Random(23));
      final seen = <CurriculumExercise>[];
      for (var i = 0; i < 20; i++) {
        seen.add(
          generator.generateDirectArithmetic(
            mode: TrainingMode.multiply,
            gradeLevel: GradeLevel.third,
            maxValue: 1000,
            directArithmeticStage: 2,
          ),
        );
      }
      expect(
        seen.any((exercise) {
          final parts = exercise.key.split(':');
          final value = int.parse(parts[1]);
          return value >= 100 && value % 10 != 0;
        }),
        isTrue,
      );
    });
  });
  group('Förderpfad bleibt bei der betroffenen Rechenart', () {
    test('unvollständige Mal-Strategie übt wieder Teilprodukte', () {
      final plan = RemediationGenerator(random: Random(41)).generate(
        pattern: ErrorPattern.partialOperand,
        preferredMode: TrainingMode.multiply,
        grade: GradeLevel.third,
        range: NumberRangeLevel.thousand,
        methods: const MethodPreferences(),
      );

      expect(plan.tasks.every((task) => task.mode == TrainingMode.multiply), isTrue);
      expect(
        plan.tasks.every(
          (task) => task.taskKey.startsWith('remediation:partialOperand:multiply:'),
        ),
        isTrue,
      );
      expect(plan.tasks.every((task) => task.hint.contains('Teilprodukte')), isTrue);
      for (final task in plan.tasks) {
        expect(task.effectiveTargetCompetency, MicroCompetencyId.largeMultiplicationPartialProducts);
        final touch = TouchInteractionPlan.forTask(
          mode: task.mode,
          taskKey: task.sourceTaskKey,
          answer: task.answer,
          maxValue: task.maxAnswerValue,
          targetCompetency: task.effectiveTargetCompetency,
        );
        expect(touch?.kind, TouchInteractionKind.mentalChunkPath);
        final guide = GuidedMethodFactory.forTask(
          mode: task.mode,
          taskKey: task.sourceTaskKey,
          expected: task.answer,
          preferences: const MethodPreferences(),
        );
        expect(guide.methodKey, 'multiplication:placeValueChunks');
      }
    });

    test('unvollständige Geteilt-Strategie übt wieder Teilquotienten', () {
      final plan = RemediationGenerator(random: Random(42)).generate(
        pattern: ErrorPattern.partialOperand,
        preferredMode: TrainingMode.divide,
        grade: GradeLevel.third,
        range: NumberRangeLevel.thousand,
        methods: const MethodPreferences(),
      );

      expect(plan.tasks.every((task) => task.mode == TrainingMode.divide), isTrue);
      expect(
        plan.tasks.every(
          (task) => task.taskKey.startsWith('remediation:partialOperand:divide:'),
        ),
        isTrue,
      );
      expect(plan.tasks.every((task) => task.hint.contains('Teilquotienten')), isTrue);
      for (final task in plan.tasks) {
        expect(task.effectiveTargetCompetency, MicroCompetencyId.largeDivisionPartialQuotients);
        final guide = GuidedMethodFactory.forTask(
          mode: task.mode,
          taskKey: task.sourceTaskKey,
          expected: task.answer,
          preferences: const MethodPreferences(),
        );
        expect(guide.methodKey, 'division:placeValueChunks');
      }
    });

    test('großes Plus und Minus bleibt im gewählten Zahlenraum', () {
      for (final mode in [TrainingMode.practice, TrainingMode.minus]) {
        final plan = RemediationGenerator(random: Random(43 + mode.index)).generate(
          pattern: ErrorPattern.partialOperand,
          preferredMode: mode,
          grade: GradeLevel.third,
          range: NumberRangeLevel.thousand,
          methods: const MethodPreferences(),
        );
        expect(plan.tasks.every((task) => task.mode == mode), isTrue);
        expect(plan.tasks.every((task) => task.maxAnswerValue == 1000), isTrue);
        expect(plan.tasks.every((task) => task.sourceTaskKey.split(':').length == 3), isTrue);
      }
    });
  });

  group('Aufgabenfamilien werden exakt getrennt', () {
    test('Plus und Minus unterscheiden einzelne und mehrere Übergänge', () {
      final cases = <MathFact, ArithmeticTaskFamily>{
        MathFact(a: 342, b: 156, operation: MathOperation.plus):
            ArithmeticTaskFamily.additionNoRegroup,
        MathFact(a: 347, b: 126, operation: MathOperation.plus):
            ArithmeticTaskFamily.additionOnesRegroup,
        MathFact(a: 342, b: 180, operation: MathOperation.plus):
            ArithmeticTaskFamily.additionHigherRegroup,
        MathFact(a: 347, b: 286, operation: MathOperation.plus):
            ArithmeticTaskFamily.additionMultiRegroup,
        MathFact(a: 786, b: 243, operation: MathOperation.minus):
            ArithmeticTaskFamily.subtractionNoRegroup,
        MathFact(a: 743, b: 126, operation: MathOperation.minus):
            ArithmeticTaskFamily.subtractionOnesBorrow,
        MathFact(a: 743, b: 180, operation: MathOperation.minus):
            ArithmeticTaskFamily.subtractionHigherBorrow,
        MathFact(a: 743, b: 286, operation: MathOperation.minus):
            ArithmeticTaskFamily.subtractionMultiBorrow,
      };

      for (final entry in cases.entries) {
        expect(ArithmeticStrategy.familyFor(entry.key), entry.value);
        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: entry.key.operation == MathOperation.minus
              ? TrainingMode.minus
              : TrainingMode.practice,
          taskKey: entry.key.key,
          fact: entry.key,
        );
        expect(
          tags.first.id,
          MicroCompetencyCatalog.competencyForArithmeticFamily(entry.value),
        );
      }
    });

    test('Mal und Geteilt trennen Stellenwertverschiebung und Zerlegung', () {
      final cases = <MathFact, ArithmeticTaskFamily>{
        MathFact(a: 300, b: 4, operation: MathOperation.multiply):
            ArithmeticTaskFamily.multiplicationPlaceShift,
        MathFact(a: 247, b: 6, operation: MathOperation.multiply):
            ArithmeticTaskFamily.multiplicationPartialProducts,
        MathFact(a: 1200, b: 4, operation: MathOperation.divide):
            ArithmeticTaskFamily.divisionPlaceShift,
        MathFact(a: 248, b: 4, operation: MathOperation.divide):
            ArithmeticTaskFamily.divisionPartialQuotients,
      };

      for (final entry in cases.entries) {
        expect(ArithmeticStrategy.familyFor(entry.key), entry.value);
      }
    });

    test('Familien sind erst ab Klasse 3 und Zahlenraum 1000 Lernziele', () {
      final hundred = MicroCompetencyCatalog.forContext(
        GradeLevel.third,
        NumberRangeLevel.hundred,
      ).map((entry) => entry.id);
      final thousand = MicroCompetencyCatalog.forContext(
        GradeLevel.third,
        NumberRangeLevel.thousand,
      ).map((entry) => entry.id);

      expect(hundred, isNot(contains(MicroCompetencyId.largeAdditionOnesRegroup)));
      expect(thousand, contains(MicroCompetencyId.largeAdditionOnesRegroup));
      expect(thousand, contains(MicroCompetencyId.largeDivisionPartialQuotients));
    });

    test('Familien-Evidenz bleibt zwischen großen Zahlenräumen getrennt', () {
      final controller = AppController();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      final id = MicroCompetencyId.largeAdditionOnesRegroup;
      controller.microObservations = <MicroCompetencyObservation>[
        for (var index = 0; index < 4; index++)
          MicroCompetencyObservation(
            id: id,
            occurredAt: DateTime(2026, 10, 18, 8, index),
            correct: true,
            evidenceWeight: 1,
            source: MicroEvidenceSource.practice,
            usedHelp: false,
            mode: TrainingMode.practice,
            gradeLevel: GradeLevel.third,
            numberRange: NumberRangeLevel.thousand,
            taskKey: 'plus:${347 + index * 100}:126',
          ),
      ];

      expect(controller.microCompetencyProgress(id).observations, 4);
      controller.numberRange = NumberRangeLevel.tenThousand;
      expect(controller.microCompetencyProgress(id).observations, 0);
    });
  });

  group('Generator zielt auf die schwache Aufgabenfamilie', () {
    final targets = <(TrainingMode, MicroCompetencyId, ArithmeticTaskFamily)>[
      (TrainingMode.practice, MicroCompetencyId.largeAdditionNoRegroup,
          ArithmeticTaskFamily.additionNoRegroup),
      (TrainingMode.practice, MicroCompetencyId.largeAdditionOnesRegroup,
          ArithmeticTaskFamily.additionOnesRegroup),
      (TrainingMode.practice, MicroCompetencyId.largeAdditionHigherRegroup,
          ArithmeticTaskFamily.additionHigherRegroup),
      (TrainingMode.practice, MicroCompetencyId.largeAdditionMultiRegroup,
          ArithmeticTaskFamily.additionMultiRegroup),
      (TrainingMode.minus, MicroCompetencyId.largeSubtractionNoRegroup,
          ArithmeticTaskFamily.subtractionNoRegroup),
      (TrainingMode.minus, MicroCompetencyId.largeSubtractionOnesBorrow,
          ArithmeticTaskFamily.subtractionOnesBorrow),
      (TrainingMode.minus, MicroCompetencyId.largeSubtractionHigherBorrow,
          ArithmeticTaskFamily.subtractionHigherBorrow),
      (TrainingMode.minus, MicroCompetencyId.largeSubtractionMultiBorrow,
          ArithmeticTaskFamily.subtractionMultiBorrow),
      (TrainingMode.multiply, MicroCompetencyId.largeMultiplicationPlaceShift,
          ArithmeticTaskFamily.multiplicationPlaceShift),
      (TrainingMode.multiply, MicroCompetencyId.largeMultiplicationPartialProducts,
          ArithmeticTaskFamily.multiplicationPartialProducts),
      (TrainingMode.divide, MicroCompetencyId.largeDivisionPlaceShift,
          ArithmeticTaskFamily.divisionPlaceShift),
      (TrainingMode.divide, MicroCompetencyId.largeDivisionPartialQuotients,
          ArithmeticTaskFamily.divisionPartialQuotients),
    ];

    for (var index = 0; index < targets.length; index++) {
      final target = targets[index];
      test('${target.$3.name} wird gezielt in allen großen Zahlenräumen erzeugt', () {
        final generator = CurriculumExerciseGenerator(random: Random(200 + index));
        for (final maxValue in <int>[1000, 10000, 1000000]) {
          for (var round = 0; round < 8; round++) {
            final exercise = generator.generateDirectArithmetic(
              mode: target.$1,
              gradeLevel: GradeLevel.third,
              maxValue: maxValue,
              directArithmeticStage: round % 3,
              targetCompetency: target.$2,
            );
            final parts = exercise.key.split(':');
            final operation = switch (parts.first) {
              'plus' => MathOperation.plus,
              'minus' => MathOperation.minus,
              'multiply' => MathOperation.multiply,
              'divide' => MathOperation.divide,
              _ => throw StateError('unerwartete Rechenart ${parts.first}'),
            };
            final fact = MathFact(
              a: int.parse(parts[1]),
              b: int.parse(parts[2]),
              operation: operation,
            );
            expect(ArithmeticStrategy.familyFor(fact), target.$3);
            expect(fact.result, lessThanOrEqualTo(maxValue));
          }
        }
      });
    }
  });

  group('Adaptive Runde fokussiert die genaue große Aufgabenfamilie', () {
    test('schwache Mehrfach-Überträge werden eigener Fokus', () async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;

      for (var index = 0; index < 3; index++) {
        final fact = MathFact(
          a: 347 + index * 100,
          b: 286,
          operation: MathOperation.plus,
        );
        await controller.recordDiagnosticAttempt(
          mode: TrainingMode.practice,
          taskKey: fact.key,
          expected: fact.result,
          actual: fact.result - 10,
          fact: fact,
          usedHelp: false,
          numberRangeOverride: NumberRangeLevel.thousand,
        );
      }

      final focus = controller.currentMicroFocus();
      expect(focus?.definition.id, MicroCompetencyId.largeAdditionMultiRegroup);
      final plan = controller.buildMyRound(now: DateTime(2026, 10, 19, 10));
      final focusSegment = plan.firstWhere(
        (segment) => segment.role == GuidedRoundRole.focus,
      );
      expect(focusSegment.mode, TrainingMode.practice);
      expect(
        focusSegment.targetCompetency,
        MicroCompetencyId.largeAdditionMultiRegroup,
      );
      expect(controller.childRecommendationText(), contains('mehreren Stellenübergängen'));
      expect(controller.recommendationText(), contains('genau dieser Familie'));

      final parent = controller.parentInsight(now: DateTime(2026, 10, 19, 10));
      expect(parent.focus, contains('mehreren Überträgen'));
      expect(parent.focus, contains('bis 1.000'));
      expect(parent.action, contains('Übertrag beim Plus vergessen'));
    });

    test('Elternhinweis nennt ohne Diagnose genau die schwache Familie', () {
      final controller = AppController();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      final id = MicroCompetencyId.largeSubtractionHigherBorrow;
      controller.microObservations = List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: id,
          occurredAt: DateTime(2026, 10, 18, 9, index),
          correct: false,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey: 'minus:${743 + index * 100}:180',
        ),
      );

      final parent = controller.parentInsight(now: DateTime(2026, 10, 19, 10));
      expect(parent.focus, contains('Entbündeln an Zehner-/Hunderterstelle'));
      expect(parent.focus, contains('bis 1.000'));
      expect(parent.action, contains('genau diese Aufgabenfamilie'));
    });

    test('Familie plant nach Sicherheit Abstand und Transfer separat', () {
      final controller = AppController();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      final id = MicroCompetencyId.largeMultiplicationPartialProducts;
      final base = DateTime(2026, 10, 1, 10);
      controller.microObservations = List.generate(
        6,
        (index) => MicroCompetencyObservation(
          id: id,
          occurredAt: base.add(Duration(minutes: index)),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.multiply,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey: 'multiply:${121 + index}:6',
        ),
      );

      final progress = controller.microCompetencyProgress(id);
      expect(progress.state, MicroCompetencyState.secure);
      expect(controller.nextReviewDueAt(id), isNotNull);
      expect(controller.nextTransferDueAt(id), isNotNull);
      expect(
        controller.dueReviewMicroCompetency(now: DateTime(2026, 10, 19))
            ?.definition
            .id,
        id,
      );
    });
  });


  test('große Aufgabenfamilien haben operationstreue Step-Recovery', () {
    final cases = <(MicroCompetencyId, String, String)>[
      (
        MicroCompetencyId.largeAdditionMultiRegroup,
        'firstPlaceValueAddition',
        'plus:347:286',
      ),
      (
        MicroCompetencyId.largeSubtractionMultiBorrow,
        'firstPlaceValueSubtraction',
        'minus:743:286',
      ),
      (
        MicroCompetencyId.largeMultiplicationPartialProducts,
        'firstPlaceValueProduct',
        'multiply:247:6',
      ),
      (
        MicroCompetencyId.largeDivisionPartialQuotients,
        'firstPlaceValueQuotient',
        'divide:248:4',
      ),
    ];

    for (var index = 0; index < cases.length; index++) {
      final entry = cases[index];
      final definition = MicroCompetencyCatalog.definition(entry.$1);
      final focus = IndependentStepRecoveryFocus(
        competencyId: entry.$1,
        stepKey: entry.$2,
        label: GuidedStepCatalog.labels[entry.$2]!,
        mode: definition.preferredMode,
        lastSeen: DateTime(2026, 10, 19, 9),
        sourceTaskKey: entry.$3,
      );
      final plan = StepRecoveryGenerator(random: Random(300 + index)).generate(
        focus: focus,
        range: NumberRangeLevel.thousand,
      );
      expect(plan.tasks, hasLength(3));
      expect(plan.tasks.every((task) => task.mode == definition.preferredMode), isTrue);
      expect(plan.tasks.every((task) => task.choices?.length == 4), isTrue);
      expect(
        plan.tasks.every(
          (task) => task.taskKey.contains('large-arithmetic:'),
        ),
        isTrue,
      );
    }
  });

  testWidgets('Meine Runde nutzt über 100 den skalierenden Curriculum-Rechenweg',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    controller.guidedRoundProgress = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[
        GuidedRoundSegment(
          role: GuidedRoundRole.focus,
          mode: TrainingMode.practice,
          tasks: 3,
          reason: 'Gezielte große Addition.',
          targetCompetency: MicroCompetencyId.largeAdditionMultiRegroup,
        ),
      ],
      completedRoles: const <GuidedRoundRole>{},
      completedTaskCounts: const <GuidedRoundRole, int>{},
      gradeLevel: GradeLevel.third,
      numberRange: NumberRangeLevel.thousand,
      startedAt: DateTime(2026, 10, 19, 10),
      updatedAt: DateTime(2026, 10, 19, 10),
      recoveryRequired: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: MyRoundScreen(controller: controller)),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('round-next-button')));
    await tester.pumpAndSettle();

    expect(find.byType(CurriculumTrainingScreen), findsOneWidget);
    expect(find.byType(TrainingScreen), findsNothing);
    expect(
      find.byKey(const ValueKey('curriculum-training-arithmetic-family')),
      findsOneWidget,
    );
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('curriculum-training-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      scrollable.position.maxScrollExtent,
      0,
      reason: 'Eine normale große Rechenaufgabe soll auf 412×915 ohne Scrollen bedienbar sein.',
    );
  });


  group('Aktive Rechenwege großer Aufgaben', () {
    test(
      'glatte Ein-Schritt-Aufgaben verraten die Endlösung nicht im Pflicht-Checkpoint',
      () {
        final plusSteps = GuidedMethodFactory.independentWrittenStepsForTask(
          mode: TrainingMode.practice,
          taskKey: 'plus:347:200',
          expected: 547,
          preferences: const MethodPreferences(),
          targetCompetency: MicroCompetencyId.largeAdditionNoRegroup,
        );
        expect(plusSteps, isEmpty);

        final multiplySteps =
            GuidedMethodFactory.independentWrittenStepsForTask(
              mode: TrainingMode.multiply,
              taskKey: 'multiply:300:3',
              expected: 900,
              preferences: const MethodPreferences(),
              targetCompetency: MicroCompetencyId.largeMultiplicationPlaceShift,
            );
        expect(multiplySteps, hasLength(1));
        expect(
          multiplySteps.single.evidenceKey,
          'placeValueMultiplicationBaseFact',
        );
        expect(multiplySteps.single.question, contains('Grundaufgabe'));
        expect(multiplySteps.single.choices, isNot(contains('900')));
        expect(multiplySteps.single.choices, contains('9'));

        final divideSteps = GuidedMethodFactory.independentWrittenStepsForTask(
          mode: TrainingMode.divide,
          taskKey: 'divide:600:3',
          expected: 200,
          preferences: const MethodPreferences(),
          targetCompetency: MicroCompetencyId.largeDivisionPlaceShift,
        );
        expect(divideSteps, hasLength(1));
        expect(divideSteps.single.evidenceKey, 'placeValueDivisionBaseFact');
        expect(divideSteps.single.choices, isNot(contains('200')));
      },
    );

    test(
      'bereits geprüfter erster Rechenschritt wird im Touch-Pfad nicht doppelt verlangt',
      () {
        final plan = TouchInteractionPlan.forTask(
          mode: TrainingMode.multiply,
          taskKey: 'multiply:247:6',
          answer: 1482,
          maxValue: 10000,
          targetCompetency:
              MicroCompetencyId.largeMultiplicationPartialProducts,
          skipFirstArithmeticStep: true,
        );
        expect(plan?.kind, TouchInteractionKind.mentalChunkPath);
        expect(plan?.dataOperation, 'multiply:skip-first');
        expect(plan?.dataValues, <int>[247, 6, 200, 40, 7]);
      },
    );

    test('alle Prozessschritte besitzen gezielte Recovery-Pfade', () {
      final cases = <(String, MicroCompetencyId, TrainingMode, String)>[
        (
          'placeValueChunkOrder',
          MicroCompetencyId.largeAdditionMultiRegroup,
          TrainingMode.practice,
          'plus:347:286',
        ),
        (
          'nextPlaceValueAddition',
          MicroCompetencyId.largeAdditionMultiRegroup,
          TrainingMode.practice,
          'plus:347:286',
        ),
        (
          'finalPlaceValueAddition',
          MicroCompetencyId.largeAdditionMultiRegroup,
          TrainingMode.practice,
          'plus:347:286',
        ),
        (
          'nextPlaceValueSubtraction',
          MicroCompetencyId.largeSubtractionMultiBorrow,
          TrainingMode.minus,
          'minus:743:286',
        ),
        (
          'finalPlaceValueSubtraction',
          MicroCompetencyId.largeSubtractionMultiBorrow,
          TrainingMode.minus,
          'minus:743:286',
        ),
        (
          'nextPlaceValueProduct',
          MicroCompetencyId.largeMultiplicationPartialProducts,
          TrainingMode.multiply,
          'multiply:247:6',
        ),
        (
          'combinePlaceValueProducts',
          MicroCompetencyId.largeMultiplicationPartialProducts,
          TrainingMode.multiply,
          'multiply:247:6',
        ),
        (
          'placeValueMultiplicationBaseFact',
          MicroCompetencyId.largeMultiplicationPlaceShift,
          TrainingMode.multiply,
          'multiply:300:3',
        ),
        (
          'placeValueMultiplicationResult',
          MicroCompetencyId.largeMultiplicationPlaceShift,
          TrainingMode.multiply,
          'multiply:300:3',
        ),
        (
          'nextPlaceValueQuotient',
          MicroCompetencyId.largeDivisionPartialQuotients,
          TrainingMode.divide,
          'divide:248:4',
        ),
        (
          'combinePlaceValueQuotients',
          MicroCompetencyId.largeDivisionPartialQuotients,
          TrainingMode.divide,
          'divide:248:4',
        ),
        (
          'placeValueDivisionBaseFact',
          MicroCompetencyId.largeDivisionPlaceShift,
          TrainingMode.divide,
          'divide:600:3',
        ),
        (
          'placeValueDivisionResult',
          MicroCompetencyId.largeDivisionPlaceShift,
          TrainingMode.divide,
          'divide:600:3',
        ),
      ];

      for (var index = 0; index < cases.length; index++) {
        final entry = cases[index];
        expect(
          StepRecoveryGenerator.supports(entry.$1),
          isTrue,
          reason: entry.$1,
        );
        final focus = IndependentStepRecoveryFocus(
          competencyId: entry.$2,
          stepKey: entry.$1,
          label: GuidedStepCatalog.labelFor(entry.$1),
          mode: entry.$3,
          lastSeen: DateTime(2026, 10, 19, 12),
          sourceTaskKey: 'independent:${entry.$1}:${entry.$4}:process:test',
        );
        final plan = StepRecoveryGenerator(
          random: Random(900 + index),
        ).generate(focus: focus, range: NumberRangeLevel.thousand);
        expect(plan.tasks, hasLength(3), reason: entry.$1);
        expect(
          plan.tasks.every((task) => task.taskKey.contains(entry.$1)),
          isTrue,
          reason: entry.$1,
        );
      }
    });

    testWidgets(
      'Curriculum speichert den exakten falschen Teilprodukt-Schritt',
      (tester) async {
        final controller = AppController();
        await controller.load();
        controller.gradeLevel = GradeLevel.third;
        controller.numberRange = NumberRangeLevel.thousand;
        const exercise = CurriculumExercise(
          mode: TrainingMode.multiply,
          prompt: 'Wie viel ist 247 × 6?',
          answer: 1482,
          hint: 'Zerlege 247 in Stellenwertblöcke.',
          key: 'multiply:247:6',
          maxAnswerValue: 10000,
          method: 'Malnehmen mit Teilprodukten',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CurriculumTrainingScreen(
              controller: controller,
              mode: TrainingMode.multiply,
              targetTasks: 1,
              targetCompetency:
                  MicroCompetencyId.largeMultiplicationPartialProducts,
              arithmeticMode: TrainingMode.multiply,
              exerciseGenerator: _FixedLargeArithmeticGenerator(exercise),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Wie groß ist dieses Teilprodukt?'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, '1200'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('touch-mental-chunk-200')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('touch-mental-chunk-40')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('touch-mental-chunk-40')));
        await tester.pump();
        expect(find.text('40 × 6 = ?'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('touch-mental-step-244')));
        await tester.pumpAndSettle();

        final processEvidence = controller.microObservations.where(
          (entry) =>
              entry.id ==
                  MicroCompetencyId.largeMultiplicationPartialProducts &&
              entry.source == MicroEvidenceSource.independentStep &&
              entry.taskKey.contains(':process:chunk-40'),
        );
        expect(processEvidence, hasLength(1));
        expect(processEvidence.single.correct, isFalse);
        expect(
          processEvidence.single.taskKey,
          contains('independent:nextPlaceValueProduct:'),
        );
      },
    );

    test('Prozessfehler steuert exakt denselben Zwischenschritt in die Recovery', () {
      final controller = AppController();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      controller.microObservations = <MicroCompetencyObservation>[
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeMultiplicationPartialProducts,
          occurredAt: DateTime(2026, 10, 19, 8),
          correct: false,
          evidenceWeight: 0.22,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.multiply,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:combinePlaceValueProducts:multiply:247:6:process:combine',
        ),
      ];

      final recovery = controller.independentStepRecoveryFocus(
        now: DateTime(2026, 10, 19, 9),
      );
      expect(recovery, isNotNull);
      expect(recovery!.reason, StepRecoveryReason.repair);
      expect(recovery.stepKey, 'combinePlaceValueProducts');
      expect(
        recovery.competencyId,
        MicroCompetencyId.largeMultiplicationPartialProducts,
      );

      final plan = controller.buildMyRound(now: DateTime(2026, 10, 19, 9));
      final focus = plan.firstWhere(
        (segment) => segment.role == GuidedRoundRole.focus,
      );
      expect(
        focus.targetCompetency,
        MicroCompetencyId.largeMultiplicationPartialProducts,
      );
      expect(focus.tasks, 2);
      expect(focus.reason, contains('Teilprodukte vollständig zusammenfügen'));

      final parent = controller.parentInsight(now: DateTime(2026, 10, 19, 9));
      expect(parent.focus, contains('Teilprodukte vollständig zusammenfügen'));
      expect(parent.action, contains('veränderten Zahlen'));
    });

    test('behobener Prozessfehler wird erst nach Abstand erneut fällig', () {
      final controller = AppController();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      controller.microObservations = <MicroCompetencyObservation>[
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeDivisionPartialQuotients,
          occurredAt: DateTime(2026, 10, 16, 9, 11),
          correct: true,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.divide,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:combinePlaceValueQuotients:repair:check:divide:248:4',
        ),
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeDivisionPartialQuotients,
          occurredAt: DateTime(2026, 10, 16, 9, 10),
          correct: true,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.divide,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:combinePlaceValueQuotients:repair:transfer:divide:372:6',
        ),
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeDivisionPartialQuotients,
          occurredAt: DateTime(2026, 10, 16, 9),
          correct: false,
          evidenceWeight: 0.22,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.divide,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:combinePlaceValueQuotients:divide:248:4:process:combine',
        ),
      ];

      expect(
        controller.nextIndependentStepReviewDueAt(
          MicroCompetencyId.largeDivisionPartialQuotients,
          'combinePlaceValueQuotients',
        ),
        DateTime(2026, 10, 18, 9, 11),
      );
      expect(
        controller.independentStepRecoveryFocus(
          now: DateTime(2026, 10, 17, 12),
        ),
        isNull,
      );
      final due = controller.independentStepRecoveryFocus(
        now: DateTime(2026, 10, 18, 9, 12),
      );
      expect(due, isNotNull);
      expect(due!.isSpacingReview, isTrue);
      expect(due.stepKey, 'combinePlaceValueQuotients');
      final trace = controller.guidedRoundDecisionTrace(
        now: DateTime(2026, 10, 18, 9, 12),
      );
      expect(trace.primary?.kind, GuidedRoundDecisionKind.dueReview);
      expect(
        trace.primary?.detail,
        contains('Teilquotienten vollständig zusammenfügen'),
      );
      final parent = controller.parentInsight(
        now: DateTime(2026, 10, 18, 9, 12),
      );
      expect(parent.focus, contains('nach zeitlichem Abstand'));
      expect(parent.action, contains('ohne Starthilfe'));
      expect(parent.stability, contains('nach Abstand fällig'));

      final normalPlan = controller.buildMyRound(
        now: DateTime(2026, 10, 18, 9, 12),
      );
      expect(
        normalPlan.firstWhere((segment) => segment.role == GuidedRoundRole.focus).tasks,
        5,
        reason:
            'Eine fällige Prozess-Abstandskontrolle soll nicht zusätzlich den normalen Fokus auf zwei Aufgaben reduzieren.',
      );
    });

    test('Prozess-Abstandskontrolle nutzt nur neue unabhängige Check-Aufgaben', () {
      final focus = IndependentStepRecoveryFocus(
        competencyId: MicroCompetencyId.largeMultiplicationPartialProducts,
        stepKey: 'combinePlaceValueProducts',
        label: GuidedStepCatalog.labelFor('combinePlaceValueProducts'),
        mode: TrainingMode.multiply,
        lastSeen: DateTime(2026, 10, 17, 10),
        sourceTaskKey:
            'independent:combinePlaceValueProducts:repair:check:multiply:247:6',
        reason: StepRecoveryReason.spacingReview,
      );
      final plan = StepRecoveryGenerator(random: Random(1701)).generate(
        focus: focus,
        range: NumberRangeLevel.thousand,
      );

      expect(plan.tasks, hasLength(3));
      expect(
        plan.tasks.every((task) => task.stage == RemediationStage.check),
        isTrue,
      );
      expect(plan.tasks.map((task) => task.taskKey).toSet().length, greaterThanOrEqualTo(2));
      expect(plan.title, contains('nach Abstand'));
    });

    test('erfolgreiche Abstandskontrollen vergrößern den Prozess-Abstand', () {
      final controller = AppController();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;

      MicroCompetencyObservation observation(
        DateTime at,
        bool correct,
        String marker,
      ) =>
          MicroCompetencyObservation(
            id: MicroCompetencyId.largeAdditionMultiRegroup,
            occurredAt: at,
            correct: correct,
            evidenceWeight: 0.35,
            source: MicroEvidenceSource.independentStep,
            usedHelp: false,
            mode: TrainingMode.practice,
            gradeLevel: GradeLevel.third,
            numberRange: NumberRangeLevel.thousand,
            taskKey: 'independent:finalPlaceValueAddition:$marker',
          );

      controller.microObservations = <MicroCompetencyObservation>[
        observation(DateTime(2026, 10, 19, 9, 2), true, 'spacing-review:check:6'),
        observation(DateTime(2026, 10, 19, 9, 1), true, 'spacing-review:check:5'),
        observation(DateTime(2026, 10, 19, 9), true, 'spacing-review:check:4'),
        observation(DateTime(2026, 10, 12, 9, 2), true, 'spacing-review:check:3'),
        observation(DateTime(2026, 10, 12, 9, 1), true, 'spacing-review:check:2'),
        observation(DateTime(2026, 10, 12, 9), true, 'spacing-review:check:1'),
        observation(DateTime(2026, 10, 10, 9, 11), true, 'repair:check'),
        observation(DateTime(2026, 10, 10, 9, 10), true, 'repair:transfer'),
        observation(DateTime(2026, 10, 10, 9), false, 'process:error'),
      ];

      expect(
        controller.nextIndependentStepReviewDueAt(
          MicroCompetencyId.largeAdditionMultiRegroup,
          'finalPlaceValueAddition',
        ),
        DateTime(2026, 11, 2, 9, 2),
      );
      expect(
        controller.independentStepRecoveryFocus(
          now: DateTime(2026, 10, 26, 12),
        ),
        isNull,
      );
    });

    test('Fehler in der Abstandskontrolle öffnet wieder gezielte Recovery', () {
      final controller = AppController();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      controller.microObservations = <MicroCompetencyObservation>[
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeSubtractionMultiBorrow,
          occurredAt: DateTime(2026, 10, 18, 10),
          correct: false,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:nextPlaceValueSubtraction:spacing-review:check:minus:743:286',
        ),
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeSubtractionMultiBorrow,
          occurredAt: DateTime(2026, 10, 16, 9, 11),
          correct: true,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:nextPlaceValueSubtraction:repair:check:minus:743:286',
        ),
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeSubtractionMultiBorrow,
          occurredAt: DateTime(2026, 10, 16, 9, 10),
          correct: true,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:nextPlaceValueSubtraction:repair:transfer:minus:653:274',
        ),
        MicroCompetencyObservation(
          id: MicroCompetencyId.largeSubtractionMultiBorrow,
          occurredAt: DateTime(2026, 10, 16, 9),
          correct: false,
          evidenceWeight: 0.22,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:nextPlaceValueSubtraction:minus:743:286:process:chunk-80',
        ),
      ];

      final focus = controller.independentStepRecoveryFocus(
        now: DateTime(2026, 10, 18, 10, 1),
      );
      expect(focus, isNotNull);
      expect(focus!.reason, StepRecoveryReason.repair);
      expect(focus.stepKey, 'nextPlaceValueSubtraction');
    });

    test('virtuelle Prozessprofile lösen sich ohne Fokus-Oszillation', () {
      final cases = <(MicroCompetencyId, TrainingMode, String)>[
        (
          MicroCompetencyId.largeAdditionMultiRegroup,
          TrainingMode.practice,
          'nextPlaceValueAddition',
        ),
        (
          MicroCompetencyId.largeSubtractionMultiBorrow,
          TrainingMode.minus,
          'nextPlaceValueSubtraction',
        ),
        (
          MicroCompetencyId.largeMultiplicationPartialProducts,
          TrainingMode.multiply,
          'combinePlaceValueProducts',
        ),
        (
          MicroCompetencyId.largeDivisionPartialQuotients,
          TrainingMode.divide,
          'combinePlaceValueQuotients',
        ),
      ];

      for (final entry in cases) {
        final controller = AppController();
        controller.gradeLevel = GradeLevel.third;
        controller.numberRange = NumberRangeLevel.thousand;
        MicroCompetencyObservation obs(
          DateTime at,
          bool correct,
          String marker,
        ) =>
            MicroCompetencyObservation(
              id: entry.$1,
              occurredAt: at,
              correct: correct,
              evidenceWeight: correct ? 0.35 : 0.22,
              source: MicroEvidenceSource.independentStep,
              usedHelp: false,
              mode: entry.$2,
              gradeLevel: GradeLevel.third,
              numberRange: NumberRangeLevel.thousand,
              taskKey: 'independent:${entry.$3}:$marker',
            );
        controller.microObservations = <MicroCompetencyObservation>[
          obs(DateTime(2026, 10, 10, 9, 11), true, 'repair:check'),
          obs(DateTime(2026, 10, 10, 9, 10), true, 'repair:transfer'),
          obs(DateTime(2026, 10, 10, 9), false, 'process:error'),
        ];

        expect(
          controller.independentStepRecoveryFocus(
            now: DateTime(2026, 10, 11, 9),
          ),
          isNull,
          reason: entry.$3,
        );
        final due = controller.independentStepRecoveryFocus(
          now: DateTime(2026, 10, 12, 9, 12),
        );
        expect(due?.stepKey, entry.$3, reason: entry.$3);
        expect(due?.isSpacingReview, isTrue, reason: entry.$3);

        controller.microObservations.insertAll(0, <MicroCompetencyObservation>[
          obs(DateTime(2026, 10, 12, 9, 3), true, 'spacing-review:check:3'),
          obs(DateTime(2026, 10, 12, 9, 2), true, 'spacing-review:check:2'),
          obs(DateTime(2026, 10, 12, 9, 1), true, 'spacing-review:check:1'),
        ]);
        expect(
          controller.independentStepRecoveryFocus(
            now: DateTime(2026, 10, 15, 9),
          ),
          isNull,
          reason: '${entry.$3} soll nach erfolgreicher Kontrolle nicht sofort zurückspringen',
        );
      }
    });

    test(
      'aktive Prozesspläne bleiben in allen großen Zahlenräumen familiengetreu',
      () {
        const targets = <MicroCompetencyId>[
          MicroCompetencyId.largeAdditionNoRegroup,
          MicroCompetencyId.largeAdditionOnesRegroup,
          MicroCompetencyId.largeAdditionHigherRegroup,
          MicroCompetencyId.largeAdditionMultiRegroup,
          MicroCompetencyId.largeSubtractionNoRegroup,
          MicroCompetencyId.largeSubtractionOnesBorrow,
          MicroCompetencyId.largeSubtractionHigherBorrow,
          MicroCompetencyId.largeSubtractionMultiBorrow,
          MicroCompetencyId.largeMultiplicationPlaceShift,
          MicroCompetencyId.largeMultiplicationPartialProducts,
          MicroCompetencyId.largeDivisionPlaceShift,
          MicroCompetencyId.largeDivisionPartialQuotients,
        ];
        const ranges = <NumberRangeLevel>[
          NumberRangeLevel.thousand,
          NumberRangeLevel.tenThousand,
          NumberRangeLevel.million,
        ];

        var seed = 1200;
        for (final range in ranges) {
          for (final target in targets) {
            final definition = MicroCompetencyCatalog.definition(target);
            final family = MicroCompetencyCatalog.arithmeticFamilyForCompetency(
              target,
            )!;
            final generator = CurriculumExerciseGenerator(
              random: Random(seed++),
            );
            for (var sample = 0; sample < 12; sample++) {
              final exercise = generator.generateDirectArithmetic(
                mode: definition.preferredMode,
                gradeLevel: GradeLevel.third,
                maxValue: range.maxValue,
                directArithmeticStage: 2,
                targetCompetency: target,
              );
              final parts = exercise.key.split(':');
              final operation = switch (parts.first) {
                'plus' => MathOperation.plus,
                'minus' => MathOperation.minus,
                'multiply' => MathOperation.multiply,
                'divide' => MathOperation.divide,
                _ => throw StateError('Unerwartete Rechenart ${parts.first}'),
              };
              final fact = MathFact(
                a: int.parse(parts[1]),
                b: int.parse(parts[2]),
                operation: operation,
              );
              expect(ArithmeticStrategy.matchesFamily(fact, family), isTrue);
              final touch = TouchInteractionPlan.forTask(
                mode: definition.preferredMode,
                taskKey: exercise.key,
                answer: exercise.answer,
                maxValue: range.maxValue,
                targetCompetency: target,
              );
              expect(touch?.kind, TouchInteractionKind.mentalChunkPath);
              expect(touch?.dataValues.length, greaterThanOrEqualTo(3));
            }
          }
        }
      },
    );
  });
}


class _FixedLargeArithmeticGenerator extends CurriculumExerciseGenerator {
  _FixedLargeArithmeticGenerator(this.exercise);

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
