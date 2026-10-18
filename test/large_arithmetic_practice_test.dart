import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/services/app_controller.dart';

MathFact factFromExercise(CurriculumExercise exercise) {
  final parts = exercise.key.split(':');
  expect(parts, hasLength(3));
  final operation = switch (parts[0]) {
    'plus' => MathOperation.plus,
    'minus' => MathOperation.minus,
    'multiply' => MathOperation.multiply,
    'divide' => MathOperation.divide,
    _ => throw StateError('Unerwarteter Aufgabenschlüssel: ${exercise.key}'),
  };
  return MathFact(
    a: int.parse(parts[1]),
    b: int.parse(parts[2]),
    operation: operation,
  );
}

void main() {
  test('direkte Plus- und Minusaufgaben skalieren bis eine Million', () {
    for (final maxValue in [1000, 10000, 1000000]) {
      final generator = CurriculumExerciseGenerator(random: Random(maxValue));
      var sawLargeOperand = false;
      for (final mode in [TrainingMode.practice, TrainingMode.minus]) {
        for (var i = 0; i < 120; i++) {
          final exercise = generator.generate(
            mode: mode,
            gradeLevel: maxValue >= 1000000
                ? GradeLevel.fourth
                : GradeLevel.third,
            maxValue: maxValue,
          );
          final fact = factFromExercise(exercise);
          expect(fact.result, inInclusiveRange(0, maxValue));
          expect(exercise.answer, fact.result);
          expect(fact.a, inInclusiveRange(0, maxValue));
          expect(fact.b, inInclusiveRange(0, maxValue));
          if (fact.a > 100 || fact.b > 100) sawLargeOperand = true;
          if (mode == TrainingMode.minus) {
            expect(fact.operation, MathOperation.minus);
            expect(fact.a, greaterThanOrEqualTo(fact.b));
          } else {
            expect(
              fact.operation,
              anyOf(MathOperation.plus, MathOperation.minus),
            );
          }
        }
      }
      expect(
        sawLargeOperand,
        isTrue,
        reason: 'Im Zahlenraum $maxValue müssen echte größere Aufgaben vorkommen.',
      );
    }
  });

  test('Malnehmen und Teilen erzeugen größere halbschriftliche Aufgaben', () {
    for (final maxValue in [1000, 10000, 1000000]) {
      final generator = CurriculumExerciseGenerator(random: Random(maxValue + 7));
      for (final mode in [TrainingMode.multiply, TrainingMode.divide]) {
        var sawBeyondBasicFacts = false;
        for (var i = 0; i < 160; i++) {
          final exercise = generator.generate(
            mode: mode,
            gradeLevel: maxValue >= 1000000
                ? GradeLevel.fourth
                : GradeLevel.third,
            maxValue: maxValue,
          );
          final fact = factFromExercise(exercise);
          expect(fact.result, inInclusiveRange(0, maxValue));
          expect(exercise.answer, fact.result);
          if (mode == TrainingMode.multiply) {
            expect(fact.operation, MathOperation.multiply);
            expect(fact.b, inInclusiveRange(2, 9));
            if (fact.a > 10) sawBeyondBasicFacts = true;
          } else {
            expect(fact.operation, MathOperation.divide);
            expect(fact.b, inInclusiveRange(2, 9));
            expect(fact.a % fact.b, 0);
            if (fact.result > 10) sawBeyondBasicFacts = true;
          }
        }
        expect(
          sawBeyondBasicFacts,
          isTrue,
          reason: '$mode im Zahlenraum $maxValue darf nicht beim Einmaleins enden.',
        );
      }
    }
  });

  test('gemischte große Runde deckt alle vier Rechenarten ab', () {
    final generator = CurriculumExerciseGenerator(random: Random(41));
    final operations = <MathOperation>{};
    for (var i = 0; i < 240; i++) {
      final exercise = generator.generate(
        mode: TrainingMode.mixed,
        gradeLevel: GradeLevel.fourth,
        maxValue: 10000,
      );
      final fact = factFromExercise(exercise);
      operations.add(fact.operation);
      expect(fact.result, inInclusiveRange(0, 10000));
    }
    expect(operations, MathOperation.values.toSet());
  });

  test('Zeitmetrik und Rechenfokus bleiben im Ergebnis erhalten', () {
    final original = TrainingSessionResult(
      mode: TrainingMode.speed,
      arithmeticMode: TrainingMode.multiply,
      startedAt: DateTime(2026, 10, 18, 10),
      finishedAt: DateTime(2026, 10, 18, 10, 1),
      total: 18,
      correctFirstTry: 16,
      incorrectAttempts: 2,
      plusCorrect: 0,
      plusTotal: 0,
      minusCorrect: 0,
      minusTotal: 0,
      multiplyCorrect: 16,
      multiplyTotal: 18,
      averageResponseMs: 3100,
      numberRange: NumberRangeLevel.thousand,
      gradeLevel: GradeLevel.third,
      activeDurationMs: 60000,
    );

    final restored = TrainingSessionResult.fromJson(original.toJson());
    expect(restored.activeDurationMs, 60000);
    expect(restored.arithmeticMode, TrainingMode.multiply);
    expect(restored.numberRange, NumberRangeLevel.thousand);
  });

  test('große Zeitrunde ist als Curriculum-Sitzung exakt fortsetzbar', () {
    final now = DateTime(2026, 10, 18, 12);
    final exercise = CurriculumExerciseGenerator(random: Random(8)).generate(
      mode: TrainingMode.multiply,
      gradeLevel: GradeLevel.third,
      maxValue: 1000,
    );
    final progress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.curriculum,
      mode: TrainingMode.speed,
      arithmeticMode: TrainingMode.multiply,
      targetTasks: 30,
      gradeLevel: GradeLevel.third,
      numberRange: NumberRangeLevel.thousand,
      timeLimitMs: 60000,
      startedAt: now.subtract(const Duration(seconds: 20)),
      updatedAt: now,
      currentTask: encodeCurriculumExercise(exercise),
      elapsedActiveMs: 20000,
      completed: 5,
      correctFirstTry: 5,
      multiplyTotal: 5,
      multiplyCorrect: 5,
    );

    final restored = CoreTrainingSessionProgress.fromJson(progress.toJson());
    expect(restored.arithmeticMode, TrainingMode.multiply);
    expect(restored.elapsedActiveMs, 20000);
    expect(
      restored.isCompatible(
        kind: CoreTrainingKind.curriculum,
        mode: TrainingMode.speed,
        targetTasks: 30,
        targetCompetency: null,
        reviewEmphasis: false,
        transferEmphasis: false,
        fluencyEmphasis: false,
        scaffoldFading: false,
        adaptiveLength: false,
        gradeLevel: GradeLevel.third,
        numberRange: NumberRangeLevel.thousand,
        teacherAssignmentActive: false,
        timeLimit: const Duration(minutes: 1),
        arithmeticMode: TrainingMode.multiply,
        now: now,
      ),
      isTrue,
    );
  });

  test('Zeit-Auswertung vergleicht nur passende frühere Runden', () {
    final controller = AppController();
    final earlier = TrainingSessionResult(
      mode: TrainingMode.speed,
      arithmeticMode: TrainingMode.multiply,
      startedAt: DateTime(2026, 10, 17, 10),
      finishedAt: DateTime(2026, 10, 17, 10, 1),
      total: 12,
      correctFirstTry: 10,
      incorrectAttempts: 2,
      plusCorrect: 0,
      plusTotal: 0,
      minusCorrect: 0,
      minusTotal: 0,
      multiplyCorrect: 10,
      multiplyTotal: 12,
      averageResponseMs: 4500,
      numberRange: NumberRangeLevel.thousand,
      gradeLevel: GradeLevel.third,
      activeDurationMs: 60000,
    );
    controller.history = [earlier];

    final current = TrainingSessionResult(
      mode: TrainingMode.speed,
      arithmeticMode: TrainingMode.multiply,
      startedAt: DateTime(2026, 10, 18, 10),
      finishedAt: DateTime(2026, 10, 18, 10, 1),
      total: 18,
      correctFirstTry: 16,
      incorrectAttempts: 2,
      plusCorrect: 0,
      plusTotal: 0,
      minusCorrect: 0,
      minusTotal: 0,
      multiplyCorrect: 16,
      multiplyTotal: 18,
      averageResponseMs: 3100,
      numberRange: NumberRangeLevel.thousand,
      gradeLevel: GradeLevel.third,
      activeDurationMs: 60000,
    );

    expect(controller.timedRoundSummary(current), contains('16 direkt richtig'));
    expect(controller.timedRoundSummary(current), contains('16,0 richtige/min'));
    expect(controller.timedRoundComparisonText(current), contains('+6,0'));
    expect(
      controller.timedRoundComparisonText(current),
      contains('nicht als Grundaufgaben-Automatisierung'),
    );
  });
}
