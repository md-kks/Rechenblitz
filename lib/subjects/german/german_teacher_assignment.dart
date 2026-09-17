import '../../core/assignments/subject_assignment_envelope.dart';
import '../../core/grade_level.dart';
import '../../core/learning_subject.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_learning_domain.dart';

class GermanTeacherAssignment {
  const GermanTeacherAssignment({
    required this.gradeLevel,
    required this.domain,
    required this.tasks,
    this.targetCompetency,
  });

  final GradeLevel gradeLevel;
  final GermanLearningDomain domain;
  final int tasks;
  final GermanCompetencyId? targetCompetency;

  SubjectAssignmentEnvelope toEnvelope() => SubjectAssignmentEnvelope(
    subject: LearningSubject.german,
    data: <String, dynamic>{
      'grade': gradeLevel.name,
      'domain': domain.name,
      'tasks': tasks,
      'target': targetCompetency?.name,
    },
  );

  String toPayload() => toEnvelope().toPayload();

  String get assignmentId => toEnvelope().assignmentId;
  static GermanTeacherAssignment? tryParse(String payload) {
    final envelope = SubjectAssignmentEnvelope.tryParse(payload);
    if (envelope == null || envelope.subject != LearningSubject.german) {
      return null;
    }
    try {
      final grade = GradeLevel.values.byName(envelope.data['grade'] as String);
      final domain = GermanLearningDomain.values.byName(
        envelope.data['domain'] as String,
      );
      final tasks = (envelope.data['tasks'] as num).toInt();
      if (tasks < 1 || tasks > 30) return null;

      final rawTarget = envelope.data['target'] as String?;
      final target = rawTarget == null
          ? null
          : GermanCompetencyId.values.byName(rawTarget);
      if (target != null) {
        final definition = GermanCompetencyCatalog.definition(target);
        if (definition.domain != domain ||
            !definition.isRecommendedFor(grade)) {
          return null;
        }
      }

      return GermanTeacherAssignment(
        gradeLevel: grade,
        domain: domain,
        tasks: tasks,
        targetCompetency: target,
      );
    } catch (_) {
      return null;
    }
  }

  String get summary {
    final target = targetCompetency == null
        ? domain.label
        : GermanCompetencyCatalog.definition(targetCompetency!).label;
    return '${gradeLevel.label} · $target · $tasks Aufgaben';
  }
}
