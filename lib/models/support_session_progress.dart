import 'error_diagnosis.dart';
import 'micro_competency.dart';
import 'remediation_path.dart';
import 'training.dart';

Map<String, dynamic> _taskToJson(RemediationTask task) => {
  'stage': task.stage.name,
  'mode': task.mode.name,
  'taskKey': task.taskKey,
  'prompt': task.prompt,
  'answer': task.answer,
  'maxAnswerValue': task.maxAnswerValue,
  'hint': task.hint,
  'choices': task.choices,
  'answerSuffix': task.answerSuffix,
  'wallValues': task.wallValues,
  'hiddenWallIndex': task.hiddenWallIndex,
  'clockHour': task.clockHour,
  'clockMinute': task.clockMinute,
  'targetCompetency': task.targetCompetency?.name,
};

RemediationTask _taskFromJson(Map<String, dynamic> json) => RemediationTask(
  stage: RemediationStage.values.byName(json['stage'] as String),
  mode: TrainingMode.values.byName(json['mode'] as String),
  taskKey: json['taskKey'] as String,
  prompt: json['prompt'] as String,
  answer: json['answer'] as int,
  maxAnswerValue: json['maxAnswerValue'] as int,
  hint: json['hint'] as String,
  choices: (json['choices'] as List<dynamic>?)?.whereType<String>().toList(),
  answerSuffix: json['answerSuffix'] as String?,
  wallValues: (json['wallValues'] as List<dynamic>?)?.whereType<int>().toList(),
  hiddenWallIndex: json['hiddenWallIndex'] as int?,
  clockHour: json['clockHour'] as int?,
  clockMinute: json['clockMinute'] as int?,
  targetCompetency: json['targetCompetency'] == null
      ? null
      : MicroCompetencyId.values.byName(json['targetCompetency'] as String),
);

Map<String, dynamic> _focusToJson(IndependentStepRecoveryFocus focus) => {
  'competencyId': focus.competencyId.name,
  'stepKey': focus.stepKey,
  'label': focus.label,
  'mode': focus.mode.name,
  'lastSeen': focus.lastSeen.toIso8601String(),
  'sourceTaskKey': focus.sourceTaskKey,
};

IndependentStepRecoveryFocus _focusFromJson(Map<String, dynamic> json) =>
    IndependentStepRecoveryFocus(
      competencyId: MicroCompetencyId.values.byName(
        json['competencyId'] as String,
      ),
      stepKey: json['stepKey'] as String,
      label: json['label'] as String,
      mode: TrainingMode.values.byName(json['mode'] as String),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      sourceTaskKey: json['sourceTaskKey'] as String,
    );

bool _sameFocus(
  IndependentStepRecoveryFocus a,
  IndependentStepRecoveryFocus b,
) =>
    a.competencyId == b.competencyId &&
    a.stepKey == b.stepKey &&
    a.mode == b.mode &&
    a.sourceTaskKey == b.sourceTaskKey;

bool _saneSupportTask(RemediationTask task) {
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

bool _saneRecoveryFocus(IndependentStepRecoveryFocus focus) =>
    focus.stepKey.trim().isNotEmpty &&
    focus.label.trim().isNotEmpty &&
    focus.sourceTaskKey.trim().isNotEmpty;

class RemediationSessionProgress {
  const RemediationSessionProgress({
    required this.pattern,
    required this.mode,
    required this.gradeLevel,
    required this.numberRange,
    required this.reviewOnly,
    required this.tasks,
    required this.index,
    required this.wrongOnCurrent,
    required this.firstAttemptRecorded,
    required this.checkCorrect,
    required this.checkTotal,
    required this.showHint,
    required this.updatedAt,
  });

  static const maxAge = Duration(days: 2);

  final ErrorPattern pattern;
  final TrainingMode mode;
  final GradeLevel gradeLevel;
  final NumberRangeLevel numberRange;
  final bool reviewOnly;
  final List<RemediationTask> tasks;
  final int index;
  final int wrongOnCurrent;
  final bool firstAttemptRecorded;
  final int checkCorrect;
  final int checkTotal;
  final bool showHint;
  final DateTime updatedAt;

  bool hasSaneState({DateTime? now}) {
    final age = (now ?? DateTime.now()).difference(updatedAt);
    if (tasks.isEmpty ||
        index < 0 ||
        index > tasks.length ||
        wrongOnCurrent < 0 ||
        checkCorrect < 0 ||
        checkTotal < 0 ||
        checkCorrect > checkTotal ||
        checkTotal > index ||
        age.isNegative ||
        age > maxAge) {
      return false;
    }
    if (tasks.any((task) => !_saneSupportTask(task))) return false;
    if (wrongOnCurrent > 0 && !firstAttemptRecorded) return false;
    if (index == tasks.length &&
        (wrongOnCurrent != 0 || firstAttemptRecorded || showHint)) {
      return false;
    }
    return true;
  }

  bool isCompatible({
    required ErrorPattern pattern,
    required TrainingMode mode,
    required GradeLevel grade,
    required NumberRangeLevel range,
    required bool reviewOnly,
    DateTime? now,
  }) {
    return this.pattern == pattern &&
        this.mode == mode &&
        gradeLevel == grade &&
        numberRange == range &&
        this.reviewOnly == reviewOnly &&
        hasSaneState(now: now);
  }

  Map<String, dynamic> toJson() => {
    'pattern': pattern.name,
    'mode': mode.name,
    'gradeLevel': gradeLevel.name,
    'numberRange': numberRange.name,
    'reviewOnly': reviewOnly,
    'tasks': tasks.map(_taskToJson).toList(),
    'index': index,
    'wrongOnCurrent': wrongOnCurrent,
    'firstAttemptRecorded': firstAttemptRecorded,
    'checkCorrect': checkCorrect,
    'checkTotal': checkTotal,
    'showHint': showHint,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory RemediationSessionProgress.fromJson(Map<String, dynamic> json) =>
      RemediationSessionProgress(
        pattern: ErrorPattern.values.byName(json['pattern'] as String),
        mode: TrainingMode.values.byName(json['mode'] as String),
        gradeLevel: GradeLevel.values.byName(json['gradeLevel'] as String),
        numberRange: NumberRangeLevel.values.byName(
          json['numberRange'] as String,
        ),
        reviewOnly: json['reviewOnly'] as bool? ?? false,
        tasks: (json['tasks'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(_taskFromJson)
            .toList(),
        index: json['index'] as int? ?? 0,
        wrongOnCurrent: json['wrongOnCurrent'] as int? ?? 0,
        firstAttemptRecorded: json['firstAttemptRecorded'] as bool? ?? false,
        checkCorrect: json['checkCorrect'] as int? ?? 0,
        checkTotal: json['checkTotal'] as int? ?? 0,
        showHint: json['showHint'] as bool? ?? false,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class StepRecoverySessionProgress {
  const StepRecoverySessionProgress({
    required this.focus,
    required this.numberRange,
    required this.tasks,
    required this.index,
    required this.wrongOnCurrent,
    required this.firstAttemptRecorded,
    required this.showHint,
    required this.updatedAt,
  });

  static const maxAge = Duration(days: 2);

  final IndependentStepRecoveryFocus focus;
  final NumberRangeLevel numberRange;
  final List<RemediationTask> tasks;
  final int index;
  final int wrongOnCurrent;
  final bool firstAttemptRecorded;
  final bool showHint;
  final DateTime updatedAt;

  bool hasSaneState({DateTime? now}) {
    final age = (now ?? DateTime.now()).difference(updatedAt);
    if (!_saneRecoveryFocus(focus) ||
        tasks.isEmpty ||
        index < 0 ||
        index > tasks.length ||
        wrongOnCurrent < 0 ||
        age.isNegative ||
        age > maxAge) {
      return false;
    }
    if (tasks.any((task) => !_saneSupportTask(task))) return false;
    if (wrongOnCurrent > 0 && !firstAttemptRecorded) return false;
    if (index == tasks.length &&
        (wrongOnCurrent != 0 || firstAttemptRecorded || showHint)) {
      return false;
    }
    return true;
  }

  bool isCompatible({
    required IndependentStepRecoveryFocus focus,
    required NumberRangeLevel range,
    DateTime? now,
  }) {
    return _sameFocus(this.focus, focus) &&
        numberRange == range &&
        hasSaneState(now: now);
  }

  Map<String, dynamic> toJson() => {
    'focus': _focusToJson(focus),
    'numberRange': numberRange.name,
    'tasks': tasks.map(_taskToJson).toList(),
    'index': index,
    'wrongOnCurrent': wrongOnCurrent,
    'firstAttemptRecorded': firstAttemptRecorded,
    'showHint': showHint,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory StepRecoverySessionProgress.fromJson(Map<String, dynamic> json) =>
      StepRecoverySessionProgress(
        focus: _focusFromJson(json['focus'] as Map<String, dynamic>),
        numberRange: NumberRangeLevel.values.byName(
          json['numberRange'] as String,
        ),
        tasks: (json['tasks'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(_taskFromJson)
            .toList(),
        index: json['index'] as int? ?? 0,
        wrongOnCurrent: json['wrongOnCurrent'] as int? ?? 0,
        firstAttemptRecorded: json['firstAttemptRecorded'] as bool? ?? false,
        showHint: json['showHint'] as bool? ?? false,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
