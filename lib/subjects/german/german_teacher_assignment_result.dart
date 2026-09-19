import '../../core/assignments/subject_result_envelope.dart';
import '../../core/grade_level.dart';
import '../../core/learning_subject.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_learning_domain.dart';
import 'german_session.dart';
import 'german_teacher_assignment.dart';

class GermanAssignmentCompetencyResult {
  const GermanAssignmentCompetencyResult({
    required this.competencyId,
    required this.completedTasks,
    required this.correctFirstTry,
    required this.incorrectAttempts,
    int? independentCorrectFirstTry,
    this.readAloudAssistedTasks = 0,
  }) : independentCorrectFirstTry =
           independentCorrectFirstTry ?? correctFirstTry;

  final GermanCompetencyId competencyId;
  final int completedTasks;
  final int correctFirstTry;
  final int independentCorrectFirstTry;
  final int readAloudAssistedTasks;
  final int incorrectAttempts;

  int get independentTasks => completedTasks - readAloudAssistedTasks;

  double get accuracy =>
      independentTasks == 0 ? 0 : independentCorrectFirstTry / independentTasks;

  String get label => GermanCompetencyCatalog.definition(competencyId).label;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': competencyId.name,
    'n': completedTasks,
    'c': correctFirstTry,
    's': independentCorrectFirstTry,
    'r': readAloudAssistedTasks,
    'i': incorrectAttempts,
  };

  static GermanAssignmentCompetencyResult fromJson(Map<String, dynamic> json) =>
      GermanAssignmentCompetencyResult(
        competencyId: GermanCompetencyId.values.byName(json['id'] as String),
        completedTasks: (json['n'] as num).toInt(),
        correctFirstTry: (json['c'] as num).toInt(),
        independentCorrectFirstTry:
            (json['s'] as num?)?.toInt() ?? (json['c'] as num).toInt(),
        readAloudAssistedTasks: (json['r'] as num?)?.toInt() ?? 0,
        incorrectAttempts: (json['i'] as num).toInt(),
      );
}

class GermanTeacherAssignmentResult {
  const GermanTeacherAssignmentResult({
    required this.assignmentId,
    required this.gradeLevel,
    required this.domain,
    required this.requestedTasks,
    required this.completedTasks,
    required this.correctFirstTry,
    required this.incorrectAttempts,
    required this.averageResponseMs,
    int? independentCorrectFirstTry,
    this.readAloudAssistedTasks = 0,
    this.targetCompetency,
    this.competencyBreakdown = const <GermanAssignmentCompetencyResult>[],
  }) : independentCorrectFirstTry =
           independentCorrectFirstTry ?? correctFirstTry;

  final String assignmentId;
  final GradeLevel gradeLevel;
  final GermanLearningDomain domain;
  final int requestedTasks;
  final int completedTasks;
  final int correctFirstTry;
  final int independentCorrectFirstTry;
  final int readAloudAssistedTasks;
  final int incorrectAttempts;
  final double averageResponseMs;
  final GermanCompetencyId? targetCompetency;
  final List<GermanAssignmentCompetencyResult> competencyBreakdown;

  int get independentTasks => completedTasks - readAloudAssistedTasks;

  double get accuracy =>
      independentTasks == 0 ? 0 : independentCorrectFirstTry / independentTasks;

  String get targetLabel => targetCompetency == null
      ? domain.label
      : GermanCompetencyCatalog.definition(targetCompetency!).label;

  String get summary {
    final evidence = independentTasks == 0
        ? 'noch keine selbstständige Beobachtung'
        : '$independentCorrectFirstTry/$independentTasks '
              'selbstständig direkt richtig';
    final base = 'Auftrag $assignmentId · $targetLabel · $evidence';
    return readAloudAssistedTasks == 0
        ? base
        : '$base · $readAloudAssistedTasks mit Vorlesen';
  }

  SubjectResultEnvelope toEnvelope() => SubjectResultEnvelope(
    subject: LearningSubject.german,
    data: <String, dynamic>{
      'kind': 'assignmentResult',
      'assignmentId': assignmentId,
      'grade': gradeLevel.name,
      'domain': domain.name,
      'requestedTasks': requestedTasks,
      'completedTasks': completedTasks,
      'correctFirstTry': correctFirstTry,
      'independentCorrectFirstTry': independentCorrectFirstTry,
      'readAloudAssistedTasks': readAloudAssistedTasks,
      'incorrectAttempts': incorrectAttempts,
      'averageResponseMs': averageResponseMs.round(),
      'target': targetCompetency?.name,
      if (competencyBreakdown.isNotEmpty)
        'breakdown': competencyBreakdown
            .map((entry) => entry.toJson())
            .toList(growable: false),
    },
  );

  String toPayload() => toEnvelope().toPayload();

  static GermanTeacherAssignmentResult fromSession({
    required GermanTeacherAssignment assignment,
    required GermanSessionResult session,
  }) {
    final grouped = <GermanCompetencyId, List<GermanTaskResult>>{};
    for (final taskResult in session.taskResults) {
      grouped
          .putIfAbsent(taskResult.competencyId, () => <GermanTaskResult>[])
          .add(taskResult);
    }
    final breakdown =
        grouped.entries
            .map((entry) {
              final values = entry.value;
              return GermanAssignmentCompetencyResult(
                competencyId: entry.key,
                completedTasks: values.length,
                correctFirstTry: values
                    .where((value) => value.correctFirstTry)
                    .length,
                independentCorrectFirstTry: values
                    .where((value) => value.independentCorrectFirstTry)
                    .length,
                readAloudAssistedTasks: values
                    .where((value) => value.usedReadAloud)
                    .length,
                incorrectAttempts: values.fold<int>(
                  0,
                  (sum, value) => sum + value.incorrectAttempts,
                ),
              );
            })
            .toList(growable: false)
          ..sort(
            (a, b) => a.competencyId.index.compareTo(b.competencyId.index),
          );

    return GermanTeacherAssignmentResult(
      assignmentId: assignment.assignmentId,
      gradeLevel: assignment.gradeLevel,
      domain: assignment.domain,
      requestedTasks: assignment.tasks,
      completedTasks: session.total,
      correctFirstTry: session.correctFirstTry,
      independentCorrectFirstTry: session.independentCorrectFirstTry,
      readAloudAssistedTasks: session.readAloudAssistedAttempts,
      incorrectAttempts: session.incorrectAttempts,
      averageResponseMs: session.averageResponseMs,
      targetCompetency: assignment.targetCompetency,
      competencyBreakdown: breakdown,
    );
  }

  static GermanTeacherAssignmentResult? tryParse(String payload) {
    final envelope = SubjectResultEnvelope.tryParse(payload);
    if (envelope == null || envelope.subject != LearningSubject.german) {
      return null;
    }
    try {
      final data = envelope.data;
      if (data['kind'] != 'assignmentResult') return null;
      final targetRaw = data['target'] as String?;
      final rawBreakdown = data['breakdown'];
      final breakdown = <GermanAssignmentCompetencyResult>[];
      if (rawBreakdown != null) {
        if (rawBreakdown is! List<dynamic>) return null;
        for (final raw in rawBreakdown) {
          if (raw is! Map<String, dynamic>) return null;
          breakdown.add(GermanAssignmentCompetencyResult.fromJson(raw));
        }
      }
      final result = GermanTeacherAssignmentResult(
        assignmentId: data['assignmentId'] as String,
        gradeLevel: GradeLevel.values.byName(data['grade'] as String),
        domain: GermanLearningDomain.values.byName(data['domain'] as String),
        requestedTasks: (data['requestedTasks'] as num).toInt(),
        completedTasks: (data['completedTasks'] as num).toInt(),
        correctFirstTry: (data['correctFirstTry'] as num).toInt(),
        independentCorrectFirstTry:
            (data['independentCorrectFirstTry'] as num?)?.toInt() ??
            (data['correctFirstTry'] as num).toInt(),
        readAloudAssistedTasks:
            (data['readAloudAssistedTasks'] as num?)?.toInt() ?? 0,
        incorrectAttempts: (data['incorrectAttempts'] as num).toInt(),
        averageResponseMs: (data['averageResponseMs'] as num).toDouble(),
        targetCompetency: targetRaw == null
            ? null
            : GermanCompetencyId.values.byName(targetRaw),
        competencyBreakdown:
            List<GermanAssignmentCompetencyResult>.unmodifiable(breakdown),
      );
      if (result.assignmentId.trim().isEmpty ||
          result.requestedTasks < 1 ||
          result.requestedTasks > 30 ||
          result.completedTasks < 0 ||
          result.completedTasks > result.requestedTasks ||
          result.correctFirstTry < 0 ||
          result.correctFirstTry > result.completedTasks ||
          result.independentCorrectFirstTry < 0 ||
          result.independentCorrectFirstTry > result.correctFirstTry ||
          result.independentCorrectFirstTry > result.independentTasks ||
          result.readAloudAssistedTasks < 0 ||
          result.readAloudAssistedTasks > result.completedTasks ||
          result.correctFirstTry - result.independentCorrectFirstTry >
              result.readAloudAssistedTasks ||
          result.incorrectAttempts < 0 ||
          result.averageResponseMs < 0) {
        return null;
      }
      final target = result.targetCompetency;
      if (target != null) {
        final definition = GermanCompetencyCatalog.definition(target);
        if (definition.domain != result.domain ||
            !definition.isRecommendedFor(result.gradeLevel)) {
          return null;
        }
      }

      if (result.competencyBreakdown.isNotEmpty) {
        final seen = <GermanCompetencyId>{};
        var completed = 0;
        var correct = 0;
        var independentCorrect = 0;
        var readAloudAssisted = 0;
        var incorrect = 0;
        for (final entry in result.competencyBreakdown) {
          if (!seen.add(entry.competencyId) ||
              entry.completedTasks < 1 ||
              entry.correctFirstTry < 0 ||
              entry.correctFirstTry > entry.completedTasks ||
              entry.independentCorrectFirstTry < 0 ||
              entry.independentCorrectFirstTry > entry.correctFirstTry ||
              entry.independentCorrectFirstTry > entry.independentTasks ||
              entry.readAloudAssistedTasks < 0 ||
              entry.readAloudAssistedTasks > entry.completedTasks ||
              entry.correctFirstTry - entry.independentCorrectFirstTry >
                  entry.readAloudAssistedTasks ||
              entry.incorrectAttempts < 0) {
            return null;
          }
          final definition = GermanCompetencyCatalog.definition(
            entry.competencyId,
          );
          if (definition.domain != result.domain ||
              !definition.isRecommendedFor(result.gradeLevel) ||
              (target != null && entry.competencyId != target)) {
            return null;
          }
          completed += entry.completedTasks;
          correct += entry.correctFirstTry;
          independentCorrect += entry.independentCorrectFirstTry;
          readAloudAssisted += entry.readAloudAssistedTasks;
          incorrect += entry.incorrectAttempts;
        }
        if (completed != result.completedTasks ||
            correct != result.correctFirstTry ||
            independentCorrect != result.independentCorrectFirstTry ||
            readAloudAssisted != result.readAloudAssistedTasks ||
            incorrect != result.incorrectAttempts) {
          return null;
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}
