import 'dart:math';

import 'curriculum_exercise.dart';
import 'structured_exercise.dart';
import 'training.dart';

class AssessmentTask {
  const AssessmentTask({
    required this.mode,
    required this.prompt,
    required this.answer,
    required this.maxAnswerValue,
    this.choices,
    this.answerSuffix,
  });

  final TrainingMode mode;
  final String prompt;
  final int answer;
  final int maxAnswerValue;
  final List<String>? choices;
  final String? answerSuffix;

  bool get usesChoices => choices != null && choices!.isNotEmpty;
}

class AssessmentGenerator {
  AssessmentGenerator({Random? random})
      : _random = random ?? Random(),
        _structured = StructuredExerciseGenerator(
          random: random == null ? Random() : Random(random.nextInt(1 << 31)),
        ),
        _curriculum = CurriculumExerciseGenerator(
          random: random == null ? Random() : Random(random.nextInt(1 << 31)),
        );

  final Random _random;
  final StructuredExerciseGenerator _structured;
  final CurriculumExerciseGenerator _curriculum;

  List<AssessmentTask> generate({
    required GradeLevel grade,
    required NumberRangeLevel range,
  }) {
    final modes = _modesFor(grade);
    final tasks = <AssessmentTask>[];
    for (final mode in modes) {
      tasks.add(_task(mode, grade, range.maxValue));
      tasks.add(_task(mode, grade, range.maxValue));
    }
    return tasks;
  }

  List<TrainingMode> _modesFor(GradeLevel grade) => switch (grade) {
        GradeLevel.first => const [
            TrainingMode.practice,
            TrainingMode.minus,
            TrainingMode.numberFriends,
            TrainingMode.missingNumber,
            TrainingMode.neighbors,
            TrainingMode.doublesHalves,
          ],
        GradeLevel.second => const [
            TrainingMode.practice,
            TrainingMode.minus,
            TrainingMode.multiply,
            TrainingMode.divide,
            TrainingMode.placeValue,
            TrainingMode.wordProblems,
          ],
        GradeLevel.third => const [
            TrainingMode.multiply,
            TrainingMode.divide,
            TrainingMode.largeNumbers,
            TrainingMode.rounding,
            TrainingMode.writtenAddSub,
            TrainingMode.advancedMeasures,
          ],
        GradeLevel.fourth => const [
            TrainingMode.largeNumbers,
            TrainingMode.rounding,
            TrainingMode.writtenAddSub,
            TrainingMode.writtenMultiply,
            TrainingMode.fractions,
            TrainingMode.probability,
          ],
      };

  AssessmentTask _task(
    TrainingMode mode,
    GradeLevel grade,
    int maxValue,
  ) {
    if (mode == TrainingMode.practice) {
      final upper = max(5, min(maxValue, grade == GradeLevel.first ? 20 : 100));
      final a = _between(1, max(1, upper ~/ 2));
      final b = _between(1, max(1, upper - a));
      return AssessmentTask(
        mode: mode,
        prompt: '$a + $b = ?',
        answer: a + b,
        maxAnswerValue: upper,
      );
    }

    if (mode == TrainingMode.minus) {
      final upper = max(5, min(maxValue, grade == GradeLevel.first ? 20 : 100));
      final a = _between(2, upper);
      final b = _between(1, a);
      return AssessmentTask(
        mode: mode,
        prompt: '$a − $b = ?',
        answer: a - b,
        maxAnswerValue: upper,
      );
    }

    if (mode == TrainingMode.multiply) {
      final a = _between(2, grade == GradeLevel.second ? 5 : 10);
      final b = _between(2, 10);
      return AssessmentTask(
        mode: mode,
        prompt: '$a × $b = ?',
        answer: a * b,
        maxAnswerValue: 100,
      );
    }

    if (mode == TrainingMode.divide) {
      final divisor = _between(2, 10);
      final quotient = _between(2, grade == GradeLevel.second ? 5 : 10);
      return AssessmentTask(
        mode: mode,
        prompt: '${divisor * quotient} ÷ $divisor = ?',
        answer: quotient,
        maxAnswerValue: 10,
      );
    }

    if (mode.isStructured) {
      final exercise = _structured.generate(
        mode: mode,
        maxValue: min(maxValue, 100),
      );
      return AssessmentTask(
        mode: mode,
        prompt: exercise.prompt,
        answer: exercise.answer,
        maxAnswerValue:
            exercise.maxAnswerValue ?? max(10, min(maxValue, 100)),
        choices: exercise.choices,
        answerSuffix: exercise.answerSuffix,
      );
    }

    final exercise = _curriculum.generate(
      mode: mode,
      gradeLevel: grade,
      maxValue: maxValue,
    );
    return AssessmentTask(
      mode: mode,
      prompt: exercise.prompt,
      answer: exercise.answer,
      maxAnswerValue: exercise.maxAnswerValue ?? maxValue,
      choices: exercise.choices,
      answerSuffix: exercise.answerSuffix,
    );
  }

  int _between(int low, int high) =>
      high <= low ? low : low + _random.nextInt(high - low + 1);
}

class AssessmentModeResult {
  const AssessmentModeResult({
    required this.mode,
    required this.correct,
    required this.total,
  });

  final TrainingMode mode;
  final int correct;
  final int total;

  double get accuracy => total == 0 ? 0 : correct / total;
}
