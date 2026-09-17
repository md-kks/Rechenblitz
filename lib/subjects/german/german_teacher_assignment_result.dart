import '../../core/assignments/subject_result_envelope.dart';
import '../../core/grade_level.dart';
import '../../core/learning_subject.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_learning_domain.dart';
import 'german_session.dart';
import 'german_teacher_assignment.dart';

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
    this.targetCompetency,
  });

  final String assignmentId;
  final GradeLevel gradeLevel;
  final GermanLearningDomain domain;
  final int requestedTasks;
  final int completedTasks;
  final int correctFirstTry;
  final int incorrectAttempts;
  final double averageResponseMs;
  final GermanCompetencyId? targetCompetency;

  double get accuracy =>
      completedTasks == 0 ? 0 : correctFirstTry / completedTasks;

  String get targetLabel => targetCompetency == null
      ? domain.label
      : GermanCompetencyCatalog.definition(targetCompetency!).label;

  String get summary =>
      'Auftrag $assignmentId · $targetLabel · $correctFirstTry/$completedTasks direkt richtig';

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
      'incorrectAttempts': incorrectAttempts,
      'averageResponseMs': averageResponseMs.round(),
      'target': targetCompetency?.name,
    },
  );

  String toPayload() => toEnvelope().toPayload();

  static GermanTeacherAssignmentResult fromSession({
    required GermanTeacherAssignment assignment,
    required GermanSessionResult session,
  }) => GermanTeacherAssignmentResult(
    assignmentId: assignment.assignmentId,
    gradeLevel: assignment.gradeLevel,
    domain: assignment.domain,
    requestedTasks: assignment.tasks,
    completedTasks: session.total,
    correctFirstTry: session.correctFirstTry,
    incorrectAttempts: session.incorrectAttempts,
    averageResponseMs: session.averageResponseMs,
    targetCompetency: assignment.targetCompetency,
  );

  static GermanTeacherAssignmentResult? tryParse(String payload) {
    final envelope = SubjectResultEnvelope.tryParse(payload);
    if (envelope == null || envelope.subject != LearningSubject.german) {
      return null;
    }
    try {
      final data = envelope.data;
      if (data['kind'] != 'assignmentResult') return null;
      final targetRaw = data['target'] as String?;
      final result = GermanTeacherAssignmentResult(
        assignmentId: data['assignmentId'] as String,
        gradeLevel: GradeLevel.values.byName(data['grade'] as String),
        domain: GermanLearningDomain.values.byName(data['domain'] as String),
        requestedTasks: (data['requestedTasks'] as num).toInt(),
        completedTasks: (data['completedTasks'] as num).toInt(),
        correctFirstTry: (data['correctFirstTry'] as num).toInt(),
        incorrectAttempts: (data['incorrectAttempts'] as num).toInt(),
        averageResponseMs: (data['averageResponseMs'] as num).toDouble(),
        targetCompetency: targetRaw == null
            ? null
            : GermanCompetencyId.values.byName(targetRaw),
      );
      if (result.assignmentId.trim().isEmpty ||
          result.requestedTasks < 1 ||
          result.requestedTasks > 30 ||
          result.completedTasks < 0 ||
          result.completedTasks > result.requestedTasks ||
          result.correctFirstTry < 0 ||
          result.correctFirstTry > result.completedTasks ||
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
      return result;
    } catch (_) {
      return null;
    }
  }
}
