import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_learning_domain.dart';
import 'german_progress.dart';
import 'german_session.dart';
import 'german_task_catalog.dart';
import 'german_task.dart';
import 'german_teacher_assignment.dart';

class GermanPracticePlanner {
  const GermanPracticePlanner._();

  static List<GermanTask> buildDailyRound({
    required GradeLevel gradeLevel,
    required Iterable<GermanSessionResult> history,
    int taskCount = 6,
  }) {
    final ranked = _ranked(
      GermanTaskCatalog.forGrade(gradeLevel),
      history,
      gradeLevel: gradeLevel,
    );
    if (ranked.length <= taskCount) return ranked;

    final selected = <GermanTask>[];
    final domainCount = <GermanLearningDomain, int>{};
    final competencyCount = <GermanCompetencyId, int>{};
    for (final task in ranked) {
      final domain = GermanCompetencyCatalog.definition(
        task.competencyId,
      ).domain;
      if ((domainCount[domain] ?? 0) >= 2) continue;
      if ((competencyCount[task.competencyId] ?? 0) >= 1) continue;
      selected.add(task);
      domainCount[domain] = (domainCount[domain] ?? 0) + 1;
      competencyCount[task.competencyId] =
          (competencyCount[task.competencyId] ?? 0) + 1;
      if (selected.length == taskCount) return selected;
    }
    for (final task in ranked) {
      if (selected.contains(task)) continue;
      selected.add(task);
      if (selected.length == taskCount) break;
    }
    return selected;
  }

  static List<GermanTask> buildDomainRound({
    required GradeLevel gradeLevel,
    required GermanLearningDomain domain,
    required Iterable<GermanSessionResult> history,
    int taskCount = 6,
  }) {
    final ranked = _ranked(
      GermanTaskCatalog.forDomain(domain, gradeLevel),
      history,
      gradeLevel: gradeLevel,
    );
    return ranked.take(taskCount).toList(growable: false);
  }

  static List<GermanTask> buildAssignmentRound({
    required GermanTeacherAssignment assignment,
    required Iterable<GermanSessionResult> history,
  }) {
    final source = assignment.targetCompetency == null
        ? GermanTaskCatalog.forDomain(assignment.domain, assignment.gradeLevel)
        : GermanTaskCatalog.forCompetency(assignment.targetCompetency!);
    final ranked = _ranked(source, history, gradeLevel: assignment.gradeLevel);
    if (ranked.isEmpty) return const <GermanTask>[];
    final selected = <GermanTask>[];
    for (var index = 0; index < assignment.tasks; index++) {
      selected.add(ranked[index % ranked.length]);
    }
    return selected;
  }

  static List<GermanTask> _ranked(
    Iterable<GermanTask> source,
    Iterable<GermanSessionResult> history, {
    required GradeLevel gradeLevel,
  }) {
    final result = source.toList();
    result.sort((a, b) => _compareTasks(a, b, history, gradeLevel: gradeLevel));
    return result;
  }

  static int _compareTasks(
    GermanTask a,
    GermanTask b,
    Iterable<GermanSessionResult> history, {
    required GradeLevel gradeLevel,
  }) {
    final aProgress = GermanProgressAnalyzer.forCompetency(
      a.competencyId,
      history,
    );
    final bProgress = GermanProgressAnalyzer.forCompetency(
      b.competencyId,
      history,
    );
    final aBucket = _priorityBucket(aProgress);
    final bBucket = _priorityBucket(bProgress);
    if (aBucket != bBucket) return aBucket.compareTo(bBucket);

    if (aProgress.state == GermanCompetencyState.learning &&
        bProgress.state == GermanCompetencyState.learning &&
        aProgress.accuracy != bProgress.accuracy) {
      return aProgress.accuracy.compareTo(bProgress.accuracy);
    }

    if (aProgress.state == GermanCompetencyState.newSkill &&
        bProgress.state == GermanCompetencyState.newSkill) {
      final aDistance = gradeLevel.index - a.recommendedFromGrade.index;
      final bDistance = gradeLevel.index - b.recommendedFromGrade.index;
      if (aDistance != bDistance) return aDistance.compareTo(bDistance);
    }

    final aPrerequisites = _unmetPrerequisites(a.competencyId, history);
    final bPrerequisites = _unmetPrerequisites(b.competencyId, history);
    if (aPrerequisites != bPrerequisites) {
      return aPrerequisites.compareTo(bPrerequisites);
    }

    final aLast = aProgress.lastPracticedAt;
    final bLast = bProgress.lastPracticedAt;
    if (aLast != null && bLast != null && aLast != bLast) {
      return aLast.compareTo(bLast);
    }
    if (aLast == null && bLast != null) return -1;
    if (aLast != null && bLast == null) return 1;
    return a.competencyId.index.compareTo(b.competencyId.index);
  }

  static int _priorityBucket(GermanCompetencyProgress progress) =>
      switch (progress.state) {
        GermanCompetencyState.learning => progress.accuracy < 0.8 ? 0 : 2,
        GermanCompetencyState.newSkill => 1,
        GermanCompetencyState.secure => 3,
      };

  static int _unmetPrerequisites(
    GermanCompetencyId competencyId,
    Iterable<GermanSessionResult> history,
  ) {
    final definition = GermanCompetencyCatalog.definition(competencyId);
    var unmet = 0;
    for (final prerequisite in definition.prerequisites) {
      final progress = GermanProgressAnalyzer.forCompetency(
        prerequisite,
        history,
      );
      if (progress.attempts == 0) unmet += 1;
    }
    return unmet;
  }
}
