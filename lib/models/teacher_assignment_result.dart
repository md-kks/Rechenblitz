import 'dart:convert';

import 'curriculum_audit.dart';
import 'learner_profile.dart';
import 'method_key_label.dart';
import 'micro_competency.dart';
import 'teacher_assignment.dart';
import 'training.dart';

class TeacherAssignmentResult {
  const TeacherAssignmentResult({
    required this.assignmentId,
    required this.gradeLevel,
    required this.numberRange,
    required this.mode,
    required this.requestedTasks,
    required this.completedTasks,
    required this.correctFirstTry,
    required this.incorrectAttempts,
    required this.averageResponseMs,
    required this.aidedObservations,
    required this.maxHelpLevel,
    required this.methodsUsed,
    this.state,
    this.targetCompetency,
  });

  static const prefix = 'RBR1:';

  final String assignmentId;
  final GradeLevel gradeLevel;
  final NumberRangeLevel numberRange;
  final TrainingMode mode;
  final int requestedTasks;
  final int completedTasks;
  final int correctFirstTry;
  final int incorrectAttempts;
  final double averageResponseMs;
  final int aidedObservations;
  final int maxHelpLevel;
  final List<String> methodsUsed;
  final GermanState? state;
  final MicroCompetencyId? targetCompetency;

  double get accuracy =>
      completedTasks == 0 ? 0 : correctFirstTry / completedTasks;

  bool get isComplete => completedTasks >= requestedTasks;

  int get correctedAfterRetry =>
      completedTasks <= correctFirstTry ? 0 : completedTasks - correctFirstTry;

  List<String> get methodLabels {
    final labels = methodsUsed
        .map(MethodKeyLabel.resolve)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return labels;
  }

  bool get hasSaneContext {
    if (assignmentId.trim().isEmpty ||
        requestedTasks < 1 ||
        requestedTasks > 30 ||
        completedTasks < 0 ||
        completedTasks > requestedTasks ||
        correctFirstTry < 0 ||
        correctFirstTry > completedTasks ||
        incorrectAttempts < 0 ||
        !averageResponseMs.isFinite ||
        averageResponseMs < 0 ||
        aidedObservations < 0 ||
        maxHelpLevel < 0 ||
        maxHelpLevel > 3) {
      return false;
    }
    final resultState = state;
    final target = targetCompetency;
    if (resultState != null && target != null) {
      return CurriculumAuditCatalog.definitionsForContext(
        resultState,
        gradeLevel,
        numberRange,
      ).any((definition) => definition.id == target);
    }
    return true;
  }

  String get summary {
    final target = targetCompetency == null
        ? mode.title
        : MicroCompetencyCatalog.definition(targetCompetency!).label;
    final stateText = state == null ? '' : ' · ${state!.label}';
    final progress = isComplete
        ? ''
        : ' · $completedTasks/$requestedTasks bearbeitet';
    return 'Auftrag $assignmentId$stateText · $target · '
        '$correctFirstTry/$completedTasks beim ersten Versuch richtig$progress';
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'assignmentId': assignmentId,
        'grade': gradeLevel.name,
        'range': numberRange.name,
        'mode': mode.name,
        'requestedTasks': requestedTasks,
        'completedTasks': completedTasks,
        'correctFirstTry': correctFirstTry,
        'incorrectAttempts': incorrectAttempts,
        'averageResponseMs': averageResponseMs.round(),
        'aidedObservations': aidedObservations,
        'maxHelpLevel': maxHelpLevel,
        'methodsUsed': methodsUsed,
        'target': targetCompetency?.name,
        if (state != null) 'state': state!.name,
      };

  String toPayload() {
    final raw = utf8.encode(jsonEncode(toJson()));
    return '$prefix${base64Url.encode(raw).replaceAll('=', '')}';
  }

  static TeacherAssignmentResult fromSession({
    required TeacherAssignment assignment,
    required TrainingSessionResult session,
    required Iterable<MicroCompetencyObservation> observations,
  }) {
    final observed = observations.toList();
    final aided = observed.where((entry) => entry.helpLevel > 0).length;
    final maxHelp = observed.fold<int>(
      0,
      (current, entry) =>
          entry.helpLevel > current ? entry.helpLevel : current,
    );
    final methods = observed
        .map((entry) => entry.methodKey)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    return TeacherAssignmentResult(
      assignmentId: assignment.assignmentId,
      gradeLevel: assignment.gradeLevel,
      numberRange: assignment.numberRange,
      mode: assignment.mode,
      requestedTasks: assignment.tasks,
      completedTasks: session.total,
      correctFirstTry: session.correctFirstTry,
      incorrectAttempts: session.incorrectAttempts,
      averageResponseMs: session.averageResponseMs,
      aidedObservations: aided,
      maxHelpLevel: maxHelp,
      methodsUsed: methods,
      state: assignment.state,
      targetCompetency: assignment.targetCompetency,
    );
  }

  static TeacherAssignmentResult? tryParse(String payload) {
    final clean = payload.trim();
    if (!clean.startsWith(prefix)) return null;
    try {
      var body = clean.substring(prefix.length);
      while (body.length % 4 != 0) {
        body += '=';
      }
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(body)),
      ) as Map<String, dynamic>;
      if (decoded['v'] != 1) return null;

      final rawTarget = decoded['target'] as String?;
      MicroCompetencyId? target;
      if (rawTarget != null) {
        target = MicroCompetencyId.values.byName(rawTarget);
      }

      final result = TeacherAssignmentResult(
        assignmentId: decoded['assignmentId'] as String,
        gradeLevel:
            GradeLevel.values.byName(decoded['grade'] as String),
        numberRange:
            NumberRangeLevel.values.byName(decoded['range'] as String),
        mode: TrainingMode.values.byName(decoded['mode'] as String),
        requestedTasks: (decoded['requestedTasks'] as num).toInt(),
        completedTasks: (decoded['completedTasks'] as num).toInt(),
        correctFirstTry: (decoded['correctFirstTry'] as num).toInt(),
        incorrectAttempts: (decoded['incorrectAttempts'] as num).toInt(),
        averageResponseMs:
            (decoded['averageResponseMs'] as num).toDouble(),
        aidedObservations: (decoded['aidedObservations'] as num).toInt(),
        maxHelpLevel: (decoded['maxHelpLevel'] as num).toInt(),
        methodsUsed: (decoded['methodsUsed'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        state: decoded['state'] == null
            ? null
            : GermanState.values.byName(decoded['state'] as String),
        targetCompetency: target,
      );

      if (!result.hasSaneContext) return null;
      return result;
    } catch (_) {
      return null;
    }
  }
}
