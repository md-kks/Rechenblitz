import 'cube_net.dart';
import 'curriculum_exercise.dart';
import 'error_diagnosis.dart';
import 'micro_competency.dart';
import 'structured_exercise.dart';
import 'training.dart';

enum CoreTrainingKind { fact, structured, curriculum }

class PendingFactAttempt {
  const PendingFactAttempt({
    required this.id,
    required this.taskKey,
    required this.correct,
    required this.actualAnswer,
    required this.responseMs,
    required this.usedHelp,
  });

  final String id;
  final String taskKey;
  final bool correct;
  final int actualAnswer;
  final int responseMs;
  final bool usedHelp;

  bool get hasSaneState =>
      id.trim().isNotEmpty &&
      taskKey.trim().isNotEmpty &&
      responseMs >= 0 &&
      responseMs <= 30000;

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskKey': taskKey,
        'correct': correct,
        'actualAnswer': actualAnswer,
        'responseMs': responseMs,
        'usedHelp': usedHelp,
      };

  factory PendingFactAttempt.fromJson(Map<String, dynamic> json) =>
      PendingFactAttempt(
        id: json['id'] as String,
        taskKey: json['taskKey'] as String,
        correct: json['correct'] as bool,
        actualAnswer: json['actualAnswer'] as int,
        responseMs: json['responseMs'] as int,
        usedHelp: json['usedHelp'] as bool? ?? false,
      );
}

class PendingFirstAttemptEvidence {
  const PendingFirstAttemptEvidence({
    required this.id,
    required this.taskKey,
    required this.expected,
    required this.actual,
    required this.responseMs,
    required this.usedHelp,
    required this.helpLevel,
    required this.source,
    this.methodKey,
    this.directStepKey,
    this.directStepCompetency,
    this.directStepEvidenceWeight = 0.35,
  });

  final String id;
  final String taskKey;
  final int expected;
  final int actual;
  final int responseMs;
  final bool usedHelp;
  final int helpLevel;
  final String? methodKey;
  final MicroEvidenceSource source;
  final String? directStepKey;
  final MicroCompetencyId? directStepCompetency;
  final double directStepEvidenceWeight;

  bool get hasSaneState =>
      id.trim().isNotEmpty &&
      taskKey.trim().isNotEmpty &&
      responseMs >= 0 &&
      responseMs <= 30000 &&
      helpLevel >= 0 &&
      helpLevel <= 3 &&
      ((directStepKey == null && directStepCompetency == null) ||
          (directStepKey != null &&
              directStepKey!.trim().isNotEmpty &&
              directStepCompetency != null &&
              directStepEvidenceWeight > 0 &&
              directStepEvidenceWeight <= 0.5));

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskKey': taskKey,
        'expected': expected,
        'actual': actual,
        'responseMs': responseMs,
        'usedHelp': usedHelp,
        'helpLevel': helpLevel,
        'methodKey': methodKey,
        'source': source.name,
        'directStepKey': directStepKey,
        'directStepCompetency': directStepCompetency?.name,
        'directStepEvidenceWeight': directStepEvidenceWeight,
      };

  factory PendingFirstAttemptEvidence.fromJson(Map<String, dynamic> json) =>
      PendingFirstAttemptEvidence(
        id: json['id'] as String,
        taskKey: json['taskKey'] as String,
        expected: json['expected'] as int,
        actual: json['actual'] as int,
        responseMs: json['responseMs'] as int,
        usedHelp: json['usedHelp'] as bool? ?? false,
        helpLevel: json['helpLevel'] as int? ?? 0,
        methodKey: json['methodKey'] as String?,
        source: MicroEvidenceSource.values.byName(json['source'] as String),
        directStepKey: json['directStepKey'] as String?,
        directStepCompetency: json['directStepCompetency'] == null
            ? null
            : MicroCompetencyId.values.byName(
                json['directStepCompetency'] as String,
              ),
        directStepEvidenceWeight:
            (json['directStepEvidenceWeight'] as num?)?.toDouble() ?? 0.35,
      );
}

class CheckpointAttemptReview {
  const CheckpointAttemptReview({
    required this.question,
    required this.firstAnswer,
    required this.correctAnswer,
  });

  final String question;
  final String firstAnswer;
  final String correctAnswer;

  static CheckpointAttemptReview? tryFromChoices({
    required String? question,
    required List<String> choices,
    required int firstChoice,
    required int? correctChoice,
  }) {
    if (question == null ||
        question.trim().isEmpty ||
        firstChoice < 0 ||
        firstChoice >= choices.length ||
        correctChoice == null ||
        correctChoice < 0 ||
        correctChoice >= choices.length) {
      return null;
    }
    return CheckpointAttemptReview(
      question: question,
      firstAnswer: choices[firstChoice],
      correctAnswer: choices[correctChoice],
    );
  }

  bool get hasSaneState =>
      question.trim().isNotEmpty &&
      firstAnswer.trim().isNotEmpty &&
      correctAnswer.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'question': question,
        'firstAnswer': firstAnswer,
        'correctAnswer': correctAnswer,
      };

  factory CheckpointAttemptReview.fromJson(Map<String, dynamic> json) =>
      CheckpointAttemptReview(
        question: json['question'] as String,
        firstAnswer: json['firstAnswer'] as String,
        correctAnswer: json['correctAnswer'] as String,
      );
}

class RoundAttemptReview {
  const RoundAttemptReview({
    required this.taskNumber,
    required this.taskKey,
    required this.prompt,
    required this.correctAnswer,
    this.firstAnswer,
    this.checkpointAttempt,
    this.hadCheckpointError = false,
  });

  final int taskNumber;
  final String taskKey;
  final String prompt;
  final String correctAnswer;
  final String? firstAnswer;
  final CheckpointAttemptReview? checkpointAttempt;
  final bool hadCheckpointError;

  bool get hasSaneState =>
      taskNumber > 0 &&
      taskKey.trim().isNotEmpty &&
      prompt.trim().isNotEmpty &&
      correctAnswer.trim().isNotEmpty &&
      (firstAnswer == null || firstAnswer!.trim().isNotEmpty) &&
      (checkpointAttempt == null ||
          (hadCheckpointError && checkpointAttempt!.hasSaneState));

  Map<String, dynamic> toJson() => {
        'taskNumber': taskNumber,
        'taskKey': taskKey,
        'prompt': prompt,
        'correctAnswer': correctAnswer,
        if (firstAnswer != null) 'firstAnswer': firstAnswer,
        if (checkpointAttempt != null)
          'checkpointAttempt': checkpointAttempt!.toJson(),
        'hadCheckpointError': hadCheckpointError,
      };

  factory RoundAttemptReview.fromJson(Map<String, dynamic> json) =>
      RoundAttemptReview(
        taskNumber: json['taskNumber'] as int,
        taskKey: json['taskKey'] as String,
        prompt: json['prompt'] as String,
        correctAnswer: json['correctAnswer'] as String,
        firstAnswer: json['firstAnswer'] as String?,
        checkpointAttempt: json['checkpointAttempt'] is Map<String, dynamic>
            ? CheckpointAttemptReview.fromJson(
                json['checkpointAttempt'] as Map<String, dynamic>,
              )
            : null,
        hadCheckpointError: json['hadCheckpointError'] as bool? ?? false,
      );
}

class CoreTrainingSessionProgress {
  const CoreTrainingSessionProgress({
    required this.kind,
    required this.mode,
    required this.targetTasks,
    required this.gradeLevel,
    required this.numberRange,
    required this.startedAt,
    required this.updatedAt,
    required this.currentTask,
    this.targetCompetency,
    this.reviewEmphasis = false,
    this.transferEmphasis = false,
    this.fluencyEmphasis = false,
    this.scaffoldFading = false,
    this.adaptiveLength = false,
    this.teacherAssignmentActive = false,
    this.teacherAssignmentId,
    this.timeLimitMs,
    this.elapsedActiveMs = 0,
    this.completed = 0,
    this.incorrectAttempts = 0,
    this.correctFirstTry = 0,
    this.wrongOnCurrent = 0,
    this.firstWrongAnswer,
    this.segmentUsedHelp = false,
    this.assistanceVisible = false,
    this.usedHelp = false,
    this.useTouchInput = true,
    this.helpLevel = 0,
    this.activeMethodKey,
    this.currentErrorPattern,
    this.checkpointIndex = 0,
    this.checkpointAttempted = const <int>[],
    this.checkpointWrongAttempts = const <int, int>{},
    this.hadCheckpointError = false,
    this.firstCheckpointAttempt,
    this.taskFirstAttemptRecorded = false,
    this.helpCountedForCurrent = false,
    this.factAttemptSequence = 0,
    this.pendingFactAttempt,
    this.pendingFirstAttemptEvidence,
    this.responseTimes = const <int>[],
    this.attemptReviews = const <RoundAttemptReview>[],
    this.plusTotal = 0,
    this.plusCorrect = 0,
    this.minusTotal = 0,
    this.minusCorrect = 0,
    this.multiplyTotal = 0,
    this.multiplyCorrect = 0,
    this.divideTotal = 0,
    this.divideCorrect = 0,
    this.taskResolved = false,
  });

  static const maxAge = Duration(hours: 24);

  final CoreTrainingKind kind;
  final TrainingMode mode;
  final int targetTasks;
  final MicroCompetencyId? targetCompetency;
  final bool reviewEmphasis;
  final bool transferEmphasis;
  final bool fluencyEmphasis;
  final bool scaffoldFading;
  final bool adaptiveLength;
  final GradeLevel gradeLevel;
  final NumberRangeLevel numberRange;
  final bool teacherAssignmentActive;
  final String? teacherAssignmentId;
  final int? timeLimitMs;
  final DateTime startedAt;
  final DateTime updatedAt;
  final Map<String, dynamic> currentTask;
  final int elapsedActiveMs;
  final int completed;
  final int incorrectAttempts;
  final int correctFirstTry;
  final int wrongOnCurrent;
  final int? firstWrongAnswer;
  final bool segmentUsedHelp;
  final bool assistanceVisible;
  final bool usedHelp;
  final bool useTouchInput;
  final int helpLevel;
  final String? activeMethodKey;
  final ErrorPattern? currentErrorPattern;
  final int checkpointIndex;
  final List<int> checkpointAttempted;
  final Map<int, int> checkpointWrongAttempts;
  final bool hadCheckpointError;
  final CheckpointAttemptReview? firstCheckpointAttempt;
  final bool taskFirstAttemptRecorded;
  final bool helpCountedForCurrent;
  final int factAttemptSequence;
  final PendingFactAttempt? pendingFactAttempt;
  final PendingFirstAttemptEvidence? pendingFirstAttemptEvidence;
  final List<int> responseTimes;
  final List<RoundAttemptReview> attemptReviews;
  final int plusTotal;
  final int plusCorrect;
  final int minusTotal;
  final int minusCorrect;
  final int multiplyTotal;
  final int multiplyCorrect;
  final int divideTotal;
  final int divideCorrect;
  final bool taskResolved;

  bool hasSaneState({DateTime? now}) {
    final reference = now ?? DateTime.now();
    bool validCounterPair(int total, int correct) =>
        total >= 0 && correct >= 0 && correct <= total;

    if (targetTasks <= 0 || currentTask.isEmpty) return false;
    if (startedAt.isAfter(updatedAt) || updatedAt.isAfter(reference)) return false;
    if (timeLimitMs != null && timeLimitMs! <= 0) return false;
    if (elapsedActiveMs < 0 ||
        completed < 0 ||
        completed > targetTasks ||
        correctFirstTry < 0 ||
        correctFirstTry > completed ||
        incorrectAttempts < 0 ||
        wrongOnCurrent < 0 ||
        helpLevel < 0 ||
        helpLevel > 3 ||
        checkpointIndex < 0 ||
        factAttemptSequence < 0) {
      return false;
    }
    if (checkpointAttempted.any((index) => index < 0) ||
        checkpointWrongAttempts.entries.any(
          (entry) => entry.key < 0 || entry.value < 0,
        ) ||
        (firstCheckpointAttempt != null &&
            (!hadCheckpointError || !firstCheckpointAttempt!.hasSaneState)) ||
        responseTimes.any((value) => value < 0) ||
        attemptReviews.any(
          (review) =>
              !review.hasSaneState ||
              review.taskNumber > completed,
        ) ||
        attemptReviews.map((review) => review.taskNumber).toSet().length !=
            attemptReviews.length) {
      return false;
    }
    if (!validCounterPair(plusTotal, plusCorrect) ||
        !validCounterPair(minusTotal, minusCorrect) ||
        !validCounterPair(multiplyTotal, multiplyCorrect) ||
        !validCounterPair(divideTotal, divideCorrect)) {
      return false;
    }
    final pending = pendingFactAttempt;
    if (pending != null &&
        (kind != CoreTrainingKind.fact ||
            !pending.hasSaneState ||
            factAttemptSequence <= 0 ||
            pending.taskKey != currentTask['key'])) {
      return false;
    }
    if (kind != CoreTrainingKind.fact && factAttemptSequence != 0) return false;
    final pendingEvidence = pendingFirstAttemptEvidence;
    if (pendingEvidence != null &&
        (!pendingEvidence.hasSaneState ||
            pendingEvidence.taskKey != currentTask['key'])) {
      return false;
    }

    try {
      switch (kind) {
        case CoreTrainingKind.fact:
          final key = currentTask['key'];
          if (key is! String || key.trim().isEmpty) return false;
        case CoreTrainingKind.structured:
          if (decodeStructuredExercise(currentTask).mode != mode) return false;
        case CoreTrainingKind.curriculum:
          if (decodeCurriculumExercise(currentTask).mode != mode) return false;
      }
    } catch (_) {
      return false;
    }
    return true;
  }

  bool isCompatible({
    required CoreTrainingKind kind,
    required TrainingMode mode,
    required int targetTasks,
    required MicroCompetencyId? targetCompetency,
    required bool reviewEmphasis,
    required bool transferEmphasis,
    required bool fluencyEmphasis,
    required bool scaffoldFading,
    required bool adaptiveLength,
    required GradeLevel gradeLevel,
    required NumberRangeLevel numberRange,
    required bool teacherAssignmentActive,
    String? teacherAssignmentId,
    required Duration? timeLimit,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    return hasSaneState(now: reference) &&
        this.kind == kind &&
        this.mode == mode &&
        this.targetTasks == targetTasks &&
        this.targetCompetency == targetCompetency &&
        this.reviewEmphasis == reviewEmphasis &&
        this.transferEmphasis == transferEmphasis &&
        this.fluencyEmphasis == fluencyEmphasis &&
        this.scaffoldFading == scaffoldFading &&
        this.adaptiveLength == adaptiveLength &&
        this.gradeLevel == gradeLevel &&
        this.numberRange == numberRange &&
        this.teacherAssignmentActive == teacherAssignmentActive &&
        this.teacherAssignmentId == teacherAssignmentId &&
        timeLimitMs == timeLimit?.inMilliseconds &&
        completed <= targetTasks &&
        !updatedAt.isAfter(reference) &&
        reference.difference(updatedAt) <= maxAge;
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'mode': mode.name,
    'targetTasks': targetTasks,
    'targetCompetency': targetCompetency?.name,
    'reviewEmphasis': reviewEmphasis,
    'transferEmphasis': transferEmphasis,
    'fluencyEmphasis': fluencyEmphasis,
    'scaffoldFading': scaffoldFading,
    'adaptiveLength': adaptiveLength,
    'gradeLevel': gradeLevel.name,
    'numberRange': numberRange.name,
    'teacherAssignmentActive': teacherAssignmentActive,
    if (teacherAssignmentId != null) 'teacherAssignmentId': teacherAssignmentId,
    'timeLimitMs': timeLimitMs,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'currentTask': currentTask,
    'elapsedActiveMs': elapsedActiveMs,
    'completed': completed,
    'incorrectAttempts': incorrectAttempts,
    'correctFirstTry': correctFirstTry,
    'wrongOnCurrent': wrongOnCurrent,
    if (firstWrongAnswer != null) 'firstWrongAnswer': firstWrongAnswer,
    'segmentUsedHelp': segmentUsedHelp,
    'assistanceVisible': assistanceVisible,
    'usedHelp': usedHelp,
    'useTouchInput': useTouchInput,
    'helpLevel': helpLevel,
    'activeMethodKey': activeMethodKey,
    'currentErrorPattern': currentErrorPattern?.name,
    'checkpointIndex': checkpointIndex,
    'checkpointAttempted': checkpointAttempted,
    'checkpointWrongAttempts': checkpointWrongAttempts.map(
      (key, value) => MapEntry(key.toString(), value),
    ),
    'hadCheckpointError': hadCheckpointError,
    if (firstCheckpointAttempt != null)
      'firstCheckpointAttempt': firstCheckpointAttempt!.toJson(),
    'taskFirstAttemptRecorded': taskFirstAttemptRecorded,
    'helpCountedForCurrent': helpCountedForCurrent,
    'factAttemptSequence': factAttemptSequence,
    'pendingFactAttempt': pendingFactAttempt?.toJson(),
    'pendingFirstAttemptEvidence': pendingFirstAttemptEvidence?.toJson(),
    'responseTimes': responseTimes,
    'attemptReviews':
        attemptReviews.map((review) => review.toJson()).toList(growable: false),
    'plusTotal': plusTotal,
    'plusCorrect': plusCorrect,
    'minusTotal': minusTotal,
    'minusCorrect': minusCorrect,
    'multiplyTotal': multiplyTotal,
    'multiplyCorrect': multiplyCorrect,
    'divideTotal': divideTotal,
    'divideCorrect': divideCorrect,
    'taskResolved': taskResolved,
  };

  factory CoreTrainingSessionProgress.fromJson(Map<String, dynamic> json) {
    final wrongAttempts = <int, int>{};
    final rawWrong = json['checkpointWrongAttempts'];
    if (rawWrong is Map<String, dynamic>) {
      for (final entry in rawWrong.entries) {
        final index = int.tryParse(entry.key);
        final value = entry.value;
        if (index != null && value is int) wrongAttempts[index] = value;
      }
    }
    return CoreTrainingSessionProgress(
      kind: CoreTrainingKind.values.byName(json['kind'] as String),
      mode: TrainingMode.values.byName(json['mode'] as String),
      targetTasks: json['targetTasks'] as int,
      targetCompetency: json['targetCompetency'] == null
          ? null
          : MicroCompetencyId.values.byName(json['targetCompetency'] as String),
      reviewEmphasis: json['reviewEmphasis'] as bool? ?? false,
      transferEmphasis: json['transferEmphasis'] as bool? ?? false,
      fluencyEmphasis: json['fluencyEmphasis'] as bool? ?? false,
      scaffoldFading: json['scaffoldFading'] as bool? ?? false,
      adaptiveLength: json['adaptiveLength'] as bool? ?? false,
      gradeLevel: GradeLevel.values.byName(json['gradeLevel'] as String),
      numberRange: NumberRangeLevel.values.byName(
        json['numberRange'] as String,
      ),
      teacherAssignmentActive:
          json['teacherAssignmentActive'] as bool? ?? false,
      teacherAssignmentId: json['teacherAssignmentId'] as String?,
      timeLimitMs: json['timeLimitMs'] as int?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      currentTask: Map<String, dynamic>.from(
        json['currentTask'] as Map<dynamic, dynamic>,
      ),
      elapsedActiveMs: json['elapsedActiveMs'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      incorrectAttempts: json['incorrectAttempts'] as int? ?? 0,
      correctFirstTry: json['correctFirstTry'] as int? ?? 0,
      wrongOnCurrent: json['wrongOnCurrent'] as int? ?? 0,
      firstWrongAnswer: json['firstWrongAnswer'] as int?,
      segmentUsedHelp: json['segmentUsedHelp'] as bool? ?? false,
      assistanceVisible: json['assistanceVisible'] as bool? ?? false,
      usedHelp: json['usedHelp'] as bool? ?? false,
      useTouchInput: json['useTouchInput'] as bool? ?? true,
      helpLevel: json['helpLevel'] as int? ?? 0,
      activeMethodKey: json['activeMethodKey'] as String?,
      currentErrorPattern: json['currentErrorPattern'] == null
          ? null
          : ErrorPattern.values.byName(json['currentErrorPattern'] as String),
      checkpointIndex: json['checkpointIndex'] as int? ?? 0,
      checkpointAttempted:
          (json['checkpointAttempted'] as List<dynamic>? ?? const [])
              .cast<int>(),
      checkpointWrongAttempts: wrongAttempts,
      hadCheckpointError: json['hadCheckpointError'] as bool? ?? false,
      firstCheckpointAttempt:
          json['firstCheckpointAttempt'] is Map<String, dynamic>
              ? CheckpointAttemptReview.fromJson(
                  json['firstCheckpointAttempt'] as Map<String, dynamic>,
                )
              : null,
      taskFirstAttemptRecorded:
          json['taskFirstAttemptRecorded'] as bool? ?? false,
      helpCountedForCurrent: json['helpCountedForCurrent'] as bool? ?? false,
      factAttemptSequence: json['factAttemptSequence'] as int? ?? 0,
      pendingFactAttempt: json['pendingFactAttempt'] is Map<String, dynamic>
          ? PendingFactAttempt.fromJson(
              json['pendingFactAttempt'] as Map<String, dynamic>,
            )
          : null,
      pendingFirstAttemptEvidence:
          json['pendingFirstAttemptEvidence'] is Map<String, dynamic>
              ? PendingFirstAttemptEvidence.fromJson(
                  json['pendingFirstAttemptEvidence'] as Map<String, dynamic>,
                )
              : null,
      responseTimes: (json['responseTimes'] as List<dynamic>? ?? const [])
          .cast<int>(),
      attemptReviews:
          (json['attemptReviews'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(RoundAttemptReview.fromJson)
              .toList(growable: false),
      plusTotal: json['plusTotal'] as int? ?? 0,
      plusCorrect: json['plusCorrect'] as int? ?? 0,
      minusTotal: json['minusTotal'] as int? ?? 0,
      minusCorrect: json['minusCorrect'] as int? ?? 0,
      multiplyTotal: json['multiplyTotal'] as int? ?? 0,
      multiplyCorrect: json['multiplyCorrect'] as int? ?? 0,
      divideTotal: json['divideTotal'] as int? ?? 0,
      divideCorrect: json['divideCorrect'] as int? ?? 0,
      taskResolved: json['taskResolved'] as bool? ?? false,
    );
  }
}

Map<String, dynamic> encodeStructuredExercise(StructuredExercise exercise) => {
  'mode': exercise.mode.name,
  'prompt': exercise.prompt,
  'answer': exercise.answer,
  'hint': exercise.hint,
  'key': exercise.key,
  'wallValues': exercise.wallValues,
  'hiddenWallIndex': exercise.hiddenWallIndex,
  'choices': exercise.choices,
  'clockHour': exercise.clockHour,
  'clockMinute': exercise.clockMinute,
  'shape': exercise.shape?.name,
  'moneyPartsCents': exercise.moneyPartsCents,
  'answerSuffix': exercise.answerSuffix,
  'maxAnswerValue': exercise.maxAnswerValue,
  'representation': exercise.representation?.name,
  'representationA': exercise.representationA,
  'representationB': exercise.representationB,
  'checkpoints': exercise.checkpoints
      .map(
        (checkpoint) => {
          'key': checkpoint.key,
          'question': checkpoint.question,
          'choices': checkpoint.choices,
          'correctChoice': checkpoint.correctChoice,
          'competencyId': checkpoint.competencyId.name,
          'evidenceWeight': checkpoint.evidenceWeight,
        },
      )
      .toList(),
};

StructuredExercise decodeStructuredExercise(Map<String, dynamic> json) =>
    StructuredExercise(
      mode: TrainingMode.values.byName(json['mode'] as String),
      prompt: json['prompt'] as String,
      answer: json['answer'] as int,
      hint: json['hint'] as String,
      key: json['key'] as String,
      wallValues: (json['wallValues'] as List<dynamic>?)?.cast<int>(),
      hiddenWallIndex: json['hiddenWallIndex'] as int?,
      choices: (json['choices'] as List<dynamic>?)?.cast<String>(),
      clockHour: json['clockHour'] as int?,
      clockMinute: json['clockMinute'] as int?,
      shape: json['shape'] == null
          ? null
          : ExerciseShape.values.byName(json['shape'] as String),
      moneyPartsCents: (json['moneyPartsCents'] as List<dynamic>?)?.cast<int>(),
      answerSuffix: json['answerSuffix'] as String?,
      maxAnswerValue: json['maxAnswerValue'] as int?,
      representation: json['representation'] == null
          ? null
          : ExerciseRepresentation.values.byName(
              json['representation'] as String,
            ),
      representationA: json['representationA'] as int?,
      representationB: json['representationB'] as int?,
      checkpoints: (json['checkpoints'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (checkpoint) => ExerciseCheckpoint(
              key: checkpoint['key'] as String,
              question: checkpoint['question'] as String,
              choices: (checkpoint['choices'] as List<dynamic>).cast<String>(),
              correctChoice: checkpoint['correctChoice'] as int,
              competencyId: MicroCompetencyId.values.byName(
                checkpoint['competencyId'] as String,
              ),
              evidenceWeight:
                  (checkpoint['evidenceWeight'] as num?)?.toDouble() ?? 0.35,
            ),
          )
          .toList(growable: false),
    );

Map<String, dynamic> encodeCurriculumExercise(CurriculumExercise exercise) => {
  'mode': exercise.mode.name,
  'prompt': exercise.prompt,
  'answer': exercise.answer,
  'hint': exercise.hint,
  'key': exercise.key,
  'choices': exercise.choices,
  'answerSuffix': exercise.answerSuffix,
  'maxAnswerValue': exercise.maxAnswerValue,
  'method': exercise.method,
  'bars': exercise.bars
      ?.map((bar) => {'label': bar.label, 'value': bar.value})
      .toList(),
  'cubeNetCells': exercise.cubeNetCells
      ?.map((cell) => {'x': cell.x, 'y': cell.y})
      .toList(),
  'cubeNetLabels': exercise.cubeNetLabels?.entries
      .map(
        (entry) => {'x': entry.key.x, 'y': entry.key.y, 'label': entry.value},
      )
      .toList(),
};

CurriculumExercise decodeCurriculumExercise(Map<String, dynamic> json) {
  final labels = <GridCell, String>{};
  for (final entry
      in (json['cubeNetLabels'] as List<dynamic>? ?? const <dynamic>[])) {
    if (entry is! Map<String, dynamic>) continue;
    labels[GridCell(entry['x'] as int, entry['y'] as int)] =
        entry['label'] as String;
  }
  return CurriculumExercise(
    mode: TrainingMode.values.byName(json['mode'] as String),
    prompt: json['prompt'] as String,
    answer: json['answer'] as int,
    hint: json['hint'] as String,
    key: json['key'] as String,
    choices: (json['choices'] as List<dynamic>?)?.cast<String>(),
    answerSuffix: json['answerSuffix'] as String?,
    maxAnswerValue: json['maxAnswerValue'] as int?,
    method: json['method'] as String?,
    bars: (json['bars'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map(
          (bar) => CurriculumBar(bar['label'] as String, bar['value'] as int),
        )
        .toList(growable: false),
    cubeNetCells: (json['cubeNetCells'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map((cell) => GridCell(cell['x'] as int, cell['y'] as int))
        .toList(growable: false),
    cubeNetLabels: labels.isEmpty ? null : labels,
  );
}
