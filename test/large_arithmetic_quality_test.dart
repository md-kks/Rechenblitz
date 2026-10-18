import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/arithmetic_strategy.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';

void main() {
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
        'Addition mit mehreren Übergängen',
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
        MicroCompetencyId.mentalStrategy,
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
      expect(result.steps[0].instruction, 'Teile zuerst 240 ÷ 4.');
      expect(result.steps[1].instruction, 'Teile zuerst 8 ÷ 4.');
      expect(result.steps.last.instruction, contains('60 + 2 = 62'));
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

    expect(plusTags.first.id, MicroCompetencyId.mentalStrategy);
    expect(
      plusTags.any((tag) => tag.id == MicroCompetencyId.numberDecomposition),
      isTrue,
    );
    expect(multiplyTags.first.id, MicroCompetencyId.mentalStrategy);
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
        expect(task.effectiveTargetCompetency, MicroCompetencyId.mentalStrategy);
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
        expect(task.effectiveTargetCompetency, MicroCompetencyId.mentalStrategy);
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

}
