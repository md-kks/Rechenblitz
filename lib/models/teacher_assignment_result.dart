import 'dart:convert';

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
  final MicroCompetencyId? targetCompetency;

  double get accuracy =>
      completedTasks == 0 ? 0 : correctFirstTry / completedTasks;

  String get summary {
    final target = targetCompetency == null
        ? mode.title
        : MicroCompetencyCatalog.definition(targetCompetency!).label;
    return 'Auftrag $assignmentId · $target · $correctFirstTry/$completedTasks direkt richtig';
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
        targetCompetency: target,
      );

      if (result.requestedTasks < 1 ||
          result.requestedTasks > 30 ||
          result.completedTasks < 0 ||
          result.completedTasks > result.requestedTasks ||
          result.correctFirstTry < 0 ||
          result.correctFirstTry > result.completedTasks ||
          result.maxHelpLevel < 0 ||
          result.maxHelpLevel > 3) {
        return null;
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}
