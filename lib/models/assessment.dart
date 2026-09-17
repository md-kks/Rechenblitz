import 'dart:math';

import 'curriculum_exercise.dart';
import 'math_fact.dart';
import 'micro_competency.dart';
import 'structured_exercise.dart';
import 'training.dart';

class AssessmentTask {
  const AssessmentTask({
    required this.mode,
    required this.taskKey,
    required this.prompt,
    required this.answer,
    required this.maxAnswerValue,
    this.choices,
    this.wallValues,
    this.hiddenWallIndex,
    this.clockHour,
    this.clockMinute,
    this.answerSuffix,
    this.fact,
    this.targetCompetency,
  });

  final TrainingMode mode;
  final String taskKey;
  final String prompt;
  final int answer;
  final int maxAnswerValue;
  final List<String>? choices;
  final List<int>? wallValues;
  final int? hiddenWallIndex;
  final int? clockHour;
  final int? clockMinute;
  final String? answerSuffix;
  final MathFact? fact;
  final MicroCompetencyId? targetCompetency;

  bool get usesChoices => choices != null && choices!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'taskKey': taskKey,
        'prompt': prompt,
        'answer': answer,
        'maxAnswerValue': maxAnswerValue,
        'choices': choices,
        'wallValues': wallValues,
        'hiddenWallIndex': hiddenWallIndex,
        'clockHour': clockHour,
        'clockMinute': clockMinute,
        'answerSuffix': answerSuffix,
        'fact': fact?.toJson(),
        'targetCompetency': targetCompetency?.name,
      };

  factory AssessmentTask.fromJson(Map<String, dynamic> json) => AssessmentTask(
        mode: TrainingMode.values.byName(json['mode'] as String),
        taskKey: json['taskKey'] as String,
        prompt: json['prompt'] as String,
        answer: json['answer'] as int,
        maxAnswerValue: json['maxAnswerValue'] as int,
        choices: (json['choices'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false),
        wallValues: (json['wallValues'] as List<dynamic>?)
            ?.whereType<num>()
            .map((value) => value.toInt())
            .toList(growable: false),
        hiddenWallIndex: (json['hiddenWallIndex'] as num?)?.toInt(),
        clockHour: (json['clockHour'] as num?)?.toInt(),
        clockMinute: (json['clockMinute'] as num?)?.toInt(),
        answerSuffix: json['answerSuffix'] as String?,
        fact: json['fact'] is Map<String, dynamic>
            ? MathFact.fromJson(json['fact'] as Map<String, dynamic>)
            : null,
        targetCompetency: json['targetCompetency'] == null
            ? null
            : MicroCompetencyId.values.byName(
                json['targetCompetency'] as String,
              ),
      );
}

class AssessmentTaskResult {
  const AssessmentTaskResult({
    required this.mode,
    required this.taskKey,
    required this.correct,
    this.fact,
    this.targetCompetency,
  });

  final TrainingMode mode;
  final String taskKey;
  final bool correct;
  final MathFact? fact;
  final MicroCompetencyId? targetCompetency;

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'taskKey': taskKey,
        'correct': correct,
        'fact': fact?.toJson(),
        'targetCompetency': targetCompetency?.name,
      };

  factory AssessmentTaskResult.fromJson(Map<String, dynamic> json) =>
      AssessmentTaskResult(
        mode: TrainingMode.values.byName(json['mode'] as String),
        taskKey: json['taskKey'] as String,
        correct: json['correct'] as bool,
        fact: json['fact'] is Map<String, dynamic>
            ? MathFact.fromJson(json['fact'] as Map<String, dynamic>)
            : null,
        targetCompetency: json['targetCompetency'] == null
            ? null
            : MicroCompetencyId.values.byName(
                json['targetCompetency'] as String,
              ),
      );
}


bool _saneAssessmentTask(AssessmentTask task) {
  if (task.taskKey.trim().isEmpty ||
      task.prompt.trim().isEmpty ||
      task.maxAnswerValue < 0) {
    return false;
  }
  final wallValues = task.wallValues;
  final hiddenIndex = task.hiddenWallIndex;
  if (hiddenIndex != null &&
      (wallValues == null || hiddenIndex < 0 || hiddenIndex >= wallValues.length)) {
    return false;
  }
  if (task.clockHour case final hour?) {
    if (hour < 0 || hour > 23) return false;
  }
  if (task.clockMinute case final minute?) {
    if (minute < 0 || minute > 59) return false;
  }
  return true;
}

class AssessmentProgress {
  const AssessmentProgress({
    required this.gradeLevel,
    required this.numberRange,
    required this.tasks,
    required this.taskResults,
    required this.nextIndex,
    required this.startedAt,
    required this.updatedAt,
  });

  final GradeLevel gradeLevel;
  final NumberRangeLevel numberRange;
  final List<AssessmentTask> tasks;
  final List<AssessmentTaskResult> taskResults;
  final int nextIndex;
  final DateTime startedAt;
  final DateTime updatedAt;

  bool hasSaneState({DateTime? now}) {
    final reference = now ?? DateTime.now();
    if (tasks.isEmpty || nextIndex <= 0 || nextIndex >= tasks.length) {
      return false;
    }
    if (startedAt.isAfter(updatedAt) ||
        updatedAt.isAfter(reference.add(const Duration(minutes: 5))) ||
        reference.difference(updatedAt) > const Duration(hours: 24)) {
      return false;
    }
    if (taskResults.length != nextIndex) return false;
    for (final task in tasks) {
      if (!_saneAssessmentTask(task)) return false;
    }
    for (var i = 0; i < taskResults.length; i++) {
      final result = taskResults[i];
      final task = tasks[i];
      if (result.taskKey.trim().isEmpty ||
          result.taskKey != task.taskKey ||
          result.mode != task.mode) {
        return false;
      }
    }
    return true;
  }

  bool isCompatible({
    required GradeLevel grade,
    required NumberRangeLevel range,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    return grade == gradeLevel &&
        range == numberRange &&
        hasSaneState(now: reference);
  }

  Map<String, dynamic> toJson() => {
        'gradeLevel': gradeLevel.name,
        'numberRange': numberRange.name,
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'taskResults': taskResults.map((result) => result.toJson()).toList(),
        'nextIndex': nextIndex,
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AssessmentProgress.fromJson(Map<String, dynamic> json) =>
      AssessmentProgress(
        gradeLevel: GradeLevel.values.byName(json['gradeLevel'] as String),
        numberRange:
            NumberRangeLevel.values.byName(json['numberRange'] as String),
        tasks: (json['tasks'] as List<dynamic>)
            .map(
              (entry) => AssessmentTask.fromJson(
                entry as Map<String, dynamic>,
              ),
            )
            .toList(growable: false),
        taskResults: (json['taskResults'] as List<dynamic>)
            .map(
              (entry) => AssessmentTaskResult.fromJson(
                entry as Map<String, dynamic>,
              ),
            )
            .toList(growable: false),
        nextIndex: (json['nextIndex'] as num).toInt(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
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
    final modes = _modesFor(grade, range);
    final tasks = <AssessmentTask>[];
    for (final mode in modes) {
      final targets = _targetsForMode(mode, grade, range);
      for (final target in <MicroCompetencyId?>[targets.first, targets.last]) {
        AssessmentTask? candidate;
        for (var attempt = 0; attempt < 40; attempt++) {
          candidate = _task(
            mode,
            grade,
            range.maxValue,
            target,
            recentKeys: tasks.map((task) => task.taskKey),
          );
          if (!tasks.any((task) => task.taskKey == candidate!.taskKey)) break;
        }
        tasks.add(candidate!);
      }
    }
    return tasks;
  }

  List<MicroCompetencyId?> _targetsForMode(
    TrainingMode mode,
    GradeLevel grade,
    NumberRangeLevel range,
  ) {
    final available = MicroCompetencyCatalog.forContext(grade, range)
        .where((definition) => definition.preferredMode == mode)
        .map((definition) => definition.id)
        .toList(growable: false);

    List<MicroCompetencyId> preferred;
    switch (mode) {
      case TrainingMode.practice:
        preferred = available
            .where(
              (id) =>
                  id == MicroCompetencyId.additionNoBridge ||
                  id == MicroCompetencyId.additionTenBridge,
            )
            .toList(growable: false);
        break;
      case TrainingMode.minus:
        preferred = available
            .where(
              (id) =>
                  id == MicroCompetencyId.subtractionNoBridge ||
                  id == MicroCompetencyId.subtractionTenBridge,
            )
            .toList(growable: false);
        break;
      case TrainingMode.multiply:
        preferred = available
            .where((id) => id == MicroCompetencyId.multiplicationFacts)
            .toList(growable: false);
        break;
      case TrainingMode.divide:
        preferred = available
            .where((id) => id == MicroCompetencyId.divisionFacts)
            .toList(growable: false);
        break;
      default:
        preferred = available;
    }

    if (preferred.isEmpty) return const <MicroCompetencyId?>[null, null];
    if (preferred.length == 1) {
      return <MicroCompetencyId?>[preferred.first, preferred.first];
    }
    if (preferred.length == 2) {
      return <MicroCompetencyId?>[preferred[0], preferred[1]];
    }
    final sampled = preferred.toList()..shuffle(_random);
    return <MicroCompetencyId?>[sampled[0], sampled[1]];
  }

  List<TrainingMode> _modesFor(
    GradeLevel grade,
    NumberRangeLevel range,
  ) {
    final core = switch (grade) {
      GradeLevel.first => const <TrainingMode>[
          TrainingMode.practice,
          TrainingMode.minus,
          TrainingMode.numberFriends,
        ],
      GradeLevel.second => const <TrainingMode>[
          TrainingMode.practice,
          TrainingMode.minus,
          TrainingMode.multiply,
          TrainingMode.divide,
        ],
      GradeLevel.third => const <TrainingMode>[
          TrainingMode.multiply,
          TrainingMode.divide,
          TrainingMode.largeNumbers,
          TrainingMode.writtenAddSub,
        ],
      GradeLevel.fourth => const <TrainingMode>[
          TrainingMode.largeNumbers,
          TrainingMode.writtenAddSub,
          TrainingMode.writtenMultiply,
          TrainingMode.writtenDivide,
        ],
    };

    final recentGradeFloor = max(0, grade.index - 1);
    final contextModes = MicroCompetencyCatalog.forContext(grade, range)
        .where((definition) => definition.minGrade.index >= recentGradeFloor)
        .map((definition) => definition.preferredMode)
        .toSet();
    final rotating = contextModes.where((mode) => !core.contains(mode)).toList()
      ..shuffle(_random);

    final selected = <TrainingMode>[...core];
    for (final mode in rotating) {
      if (selected.length >= 6) break;
      selected.add(mode);
    }

    if (selected.length < 6) {
      final fallback = MicroCompetencyCatalog.forContext(grade, range)
          .map((definition) => definition.preferredMode)
          .where((mode) => !selected.contains(mode))
          .toSet()
          .toList()
        ..shuffle(_random);
      for (final mode in fallback) {
        if (selected.length >= 6) break;
        selected.add(mode);
      }
    }

    return selected.take(6).toList(growable: false);
  }


  AssessmentTask _task(
    TrainingMode mode,
    GradeLevel grade,
    int maxValue,
    MicroCompetencyId? targetCompetency, {
    Iterable<String> recentKeys = const <String>[],
  }) {
    if (mode == TrainingMode.practice) {
      final upper = max(5, min(maxValue, grade == GradeLevel.first ? 20 : 100));
      final fact = _additionFact(upper, targetCompetency);
      return _factTask(mode, fact, upper, targetCompetency);
    }

    if (mode == TrainingMode.numberFriends) {
      final target = maxValue <= 10 ? 10 : 20;
      final a = _between(0, target);
      final fact = MathFact(
        a: a,
        b: target - a,
        operation: MathOperation.plus,
      );
      return AssessmentTask(
        mode: mode,
        taskKey: fact.key,
        prompt: '$a + ? = $target',
        answer: target - a,
        maxAnswerValue: target,
        fact: fact,
        targetCompetency: MicroCompetencyId.numberDecomposition,
      );
    }

    if (mode == TrainingMode.minus) {
      final upper = max(5, min(maxValue, grade == GradeLevel.first ? 20 : 100));
      final fact = _subtractionFact(upper, targetCompetency);
      return _factTask(mode, fact, upper, targetCompetency);
    }

    if (mode == TrainingMode.multiply) {
      final fact = MathFact(
        a: _between(2, grade == GradeLevel.second ? 5 : 10),
        b: _between(2, 10),
        operation: MathOperation.multiply,
      );
      return _factTask(
        mode,
        fact,
        100,
        MicroCompetencyId.multiplicationFacts,
      );
    }

    if (mode == TrainingMode.divide) {
      final divisor = _between(2, 10);
      final quotient = _between(2, grade == GradeLevel.second ? 5 : 10);
      final fact = MathFact(
        a: divisor * quotient,
        b: divisor,
        operation: MathOperation.divide,
      );
      return _factTask(
        mode,
        fact,
        10,
        MicroCompetencyId.divisionFacts,
      );
    }

    if (mode.isStructured) {
      final assessmentMaxValue = switch (mode) {
        TrainingMode.doublesHalves => min(maxValue, 24),
        TrainingMode.measures => min(maxValue, 30),
        _ => min(maxValue, 100),
      };
      final exercise = _structured.generate(
        mode: mode,
        maxValue: assessmentMaxValue,
        gradeLevel: grade,
        targetCompetency: targetCompetency,
        recentKeys: recentKeys,
      );
      return AssessmentTask(
        mode: mode,
        taskKey: exercise.key,
        prompt: exercise.prompt,
        answer: exercise.answer,
        maxAnswerValue:
            exercise.maxAnswerValue ?? max(10, assessmentMaxValue),
        choices: exercise.choices,
        wallValues: exercise.wallValues,
        hiddenWallIndex: exercise.hiddenWallIndex,
        clockHour: exercise.clockHour,
        clockMinute: exercise.clockMinute,
        answerSuffix: exercise.answerSuffix,
        targetCompetency: _resolvedTarget(
          mode: mode,
          taskKey: exercise.key,
          requested: targetCompetency,
        ),
      );
    }

    final exercise = _curriculum.generate(
      mode: mode,
      gradeLevel: grade,
      maxValue: maxValue,
      targetCompetency: targetCompetency,
      recentKeys: recentKeys,
    );
    return AssessmentTask(
      mode: mode,
      taskKey: exercise.key,
      prompt: exercise.prompt,
      answer: exercise.answer,
      maxAnswerValue: exercise.maxAnswerValue ?? maxValue,
      choices: exercise.choices,
      answerSuffix: exercise.answerSuffix,
      targetCompetency: _resolvedTarget(
        mode: mode,
        taskKey: exercise.key,
        requested: targetCompetency,
      ),
    );
  }

  AssessmentTask _factTask(
    TrainingMode mode,
    MathFact fact,
    int maxAnswerValue,
    MicroCompetencyId? requested,
  ) {
    final symbol = switch (fact.operation) {
      MathOperation.plus => '+',
      MathOperation.minus => '−',
      MathOperation.multiply => '×',
      MathOperation.divide => '÷',
    };
    return AssessmentTask(
      mode: mode,
      taskKey: fact.key,
      prompt: '${fact.a} $symbol ${fact.b} = ?',
      answer: fact.result,
      maxAnswerValue: maxAnswerValue,
      fact: fact,
      targetCompetency: _resolvedTarget(
        mode: mode,
        taskKey: fact.key,
        fact: fact,
        requested: requested,
      ),
    );
  }

  MathFact _additionFact(int upper, MicroCompetencyId? target) {
    for (var attempt = 0; attempt < 80; attempt++) {
      final a = _between(1, max(1, upper - 1));
      final b = _between(1, max(1, upper - a));
      final bridge = needsAdditionTenBridge(a, b);
      if (target == MicroCompetencyId.additionTenBridge && !bridge) continue;
      if (target == MicroCompetencyId.additionNoBridge && bridge) continue;
      return MathFact(a: a, b: b, operation: MathOperation.plus);
    }
    final fallback = upper >= 12 && target == MicroCompetencyId.additionTenBridge
        ? const (7, 5)
        : const (3, 4);
    return MathFact(
      a: fallback.$1,
      b: fallback.$2,
      operation: MathOperation.plus,
    );
  }

  MathFact _subtractionFact(int upper, MicroCompetencyId? target) {
    for (var attempt = 0; attempt < 80; attempt++) {
      final a = _between(2, upper);
      final b = _between(1, a);
      final bridge = needsSubtractionTenBridge(a, b);
      if (target == MicroCompetencyId.subtractionTenBridge && !bridge) continue;
      if (target == MicroCompetencyId.subtractionNoBridge && bridge) continue;
      return MathFact(a: a, b: b, operation: MathOperation.minus);
    }
    final fallback = upper >= 13 && target == MicroCompetencyId.subtractionTenBridge
        ? const (13, 5)
        : const (8, 3);
    return MathFact(
      a: fallback.$1,
      b: fallback.$2,
      operation: MathOperation.minus,
    );
  }

  MicroCompetencyId? _resolvedTarget({
    required TrainingMode mode,
    required String taskKey,
    MathFact? fact,
    MicroCompetencyId? requested,
  }) {
    final tags = MicroCompetencyCatalog.tagsForTask(
      mode: mode,
      taskKey: taskKey,
      fact: fact,
    );
    if (requested != null && tags.any((tag) => tag.id == requested)) {
      return requested;
    }
    return tags.isEmpty ? null : tags.first.id;
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
