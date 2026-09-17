import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_assessment.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';

void main() {
  test('Lerncheck covers every available German domain', () {
    for (final grade in GradeLevel.values) {
      final tasks = GermanAssessmentPlanner.buildRound(grade);
      expect(tasks, isNotEmpty);
      expect(tasks.length, lessThanOrEqualTo(12));
      final domains = tasks
          .map(
            (task) =>
                GermanCompetencyCatalog.definition(task.competencyId).domain,
          )
          .toSet();
      expect(domains, containsAll(GermanLearningDomain.values));
      expect(
        tasks.every((task) => task.recommendedFromGrade.index <= grade.index),
        isTrue,
      );
    }
  });
  test('assessment summary groups first-try evidence by domain', () {
    final tasks = GermanAssessmentPlanner.buildRound(GradeLevel.second);
    final results = tasks
        .map(
          (task) => GermanTaskResult(
            taskId: task.id,
            competencyId: task.competencyId,
            correctFirstTry: task == tasks.first,
            incorrectAttempts: task == tasks.first ? 0 : 1,
            responseMs: 1000,
          ),
        )
        .toList(growable: false);
    final session = GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 17, 10),
      finishedAt: DateTime(2026, 9, 17, 10, 5),
      taskResults: results,
      kind: GermanSessionKind.assessment,
    );
    final summary = GermanAssessmentSummary.fromSession(session);
    expect(summary.domains.where((value) => value.total > 0).length, 6);
    expect(summary.session.kind, GermanSessionKind.assessment);
    expect(summary.nextDomains, isNotEmpty);
  });
  test('old German session JSON defaults to normal practice', () {
    final session = GermanSessionResult.fromJson(<String, dynamic>{
      'gradeLevel': 'first',
      'startedAt': '2026-09-17T10:00:00.000',
      'finishedAt': '2026-09-17T10:01:00.000',
      'taskResults': <dynamic>[],
    });
    expect(session.kind, GermanSessionKind.practice);
  });
}
