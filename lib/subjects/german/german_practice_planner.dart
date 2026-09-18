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
    int taskCount = 12,
    DateTime? now,
  }) {
    if (taskCount < 1) return const <GermanTask>[];
    final ranked = _ranked(
      GermanTaskCatalog.forGrade(gradeLevel),
      history,
      gradeLevel: gradeLevel,
      now: now,
    );
    if (ranked.length <= taskCount) return ranked;

    final domains = ranked
        .map(
          (task) =>
              GermanCompetencyCatalog.definition(task.competencyId).domain,
        )
        .toSet();
    final evenShare = (taskCount / domains.length).ceil();
    final domainCap = evenShare < 2 ? 2 : evenShare;
    final selected = <GermanTask>[];
    final selectedIds = <String>{};
    final domainCount = <GermanLearningDomain, int>{};
    final competencyCount = <GermanCompetencyId, int>{};

    void add(GermanTask task) {
      final domain = GermanCompetencyCatalog.definition(
        task.competencyId,
      ).domain;
      selected.add(task);
      selectedIds.add(task.id);
      domainCount[domain] = (domainCount[domain] ?? 0) + 1;
      competencyCount[task.competencyId] =
          (competencyCount[task.competencyId] ?? 0) + 1;
    }

    for (final task in ranked) {
      final domain = GermanCompetencyCatalog.definition(
        task.competencyId,
      ).domain;
      if ((domainCount[domain] ?? 0) >= domainCap) continue;
      if ((competencyCount[task.competencyId] ?? 0) >= 1) continue;
      add(task);
      if (selected.length == taskCount) return selected;
    }

    for (final task in ranked) {
      if (selectedIds.contains(task.id)) continue;
      final domain = GermanCompetencyCatalog.definition(
        task.competencyId,
      ).domain;
      if ((domainCount[domain] ?? 0) >= domainCap) continue;
      add(task);
      if (selected.length == taskCount) return selected;
    }

    for (final task in ranked) {
      if (selectedIds.contains(task.id)) continue;
      add(task);
      if (selected.length == taskCount) break;
    }
    return selected;
  }

  static List<GermanTask> buildDomainRound({
    required GradeLevel gradeLevel,
    required GermanLearningDomain domain,
    required Iterable<GermanSessionResult> history,
    int taskCount = 6,
    DateTime? now,
  }) {
    final ranked = _ranked(
      GermanTaskCatalog.forDomain(domain, gradeLevel),
      history,
      gradeLevel: gradeLevel,
      now: now,
    );
    return ranked.take(taskCount).toList(growable: false);
  }

  static List<GermanTask> buildCompetencyRound({
    required GradeLevel gradeLevel,
    required GermanCompetencyId competencyId,
    required Iterable<GermanSessionResult> history,
    int taskCount = 6,
    DateTime? now,
  }) {
    final source = GermanTaskCatalog.forCompetency(
      competencyId,
    ).where((task) => task.recommendedFromGrade.index <= gradeLevel.index);
    final ranked = _ranked(source, history, gradeLevel: gradeLevel, now: now);
    if (ranked.isEmpty) return const <GermanTask>[];
    return List<GermanTask>.generate(
      taskCount,
      (index) => ranked[index % ranked.length],
      growable: false,
    );
  }

  static List<GermanTask> buildAssignmentRound({
    required GermanTeacherAssignment assignment,
    required Iterable<GermanSessionResult> history,
    DateTime? now,
  }) {
    final source = assignment.targetCompetency == null
        ? GermanTaskCatalog.forDomain(assignment.domain, assignment.gradeLevel)
        : GermanTaskCatalog.forCompetency(assignment.targetCompetency!);
    final ranked = _ranked(
      source,
      history,
      gradeLevel: assignment.gradeLevel,
      now: now,
    );
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
    DateTime? now,
  }) {
    final result = source.toList();
    result.sort(
      (a, b) => _compareTasks(a, b, history, gradeLevel: gradeLevel, now: now),
    );
    return result;
  }

  static int _compareTasks(
    GermanTask a,
    GermanTask b,
    Iterable<GermanSessionResult> history, {
    required GradeLevel gradeLevel,
    DateTime? now,
  }) {
    final aProgress = GermanProgressAnalyzer.forCompetency(
      a.competencyId,
      history,
    );
    final bProgress = GermanProgressAnalyzer.forCompetency(
      b.competencyId,
      history,
    );
    final aBucket = _priorityBucket(aProgress, now: now);
    final bBucket = _priorityBucket(bProgress, now: now);
    if (aBucket != bBucket) return aBucket.compareTo(bBucket);

    if (aProgress.state == GermanCompetencyState.learning &&
        bProgress.state == GermanCompetencyState.learning &&
        aProgress.recentAccuracy != bProgress.recentAccuracy) {
      return aProgress.recentAccuracy.compareTo(bProgress.recentAccuracy);
    }

    if (aProgress.state == GermanCompetencyState.newSkill &&
        bProgress.state == GermanCompetencyState.newSkill) {
      final aDistance = gradeLevel.index - a.recommendedFromGrade.index;
      final bDistance = gradeLevel.index - b.recommendedFromGrade.index;
      if (aDistance != bDistance) return aDistance.compareTo(bDistance);

      final aCompetencyGrade = GermanCompetencyCatalog.definition(
        a.competencyId,
      ).recommendedFromGrade;
      final bCompetencyGrade = GermanCompetencyCatalog.definition(
        b.competencyId,
      ).recommendedFromGrade;
      final aCompetencyDistance = gradeLevel.index - aCompetencyGrade.index;
      final bCompetencyDistance = gradeLevel.index - bCompetencyGrade.index;
      if (aCompetencyDistance != bCompetencyDistance) {
        return aCompetencyDistance.compareTo(bCompetencyDistance);
      }
    }

    final aPrerequisites = _unmetPrerequisites(a.competencyId, history);
    final bPrerequisites = _unmetPrerequisites(b.competencyId, history);
    if (aPrerequisites != bPrerequisites) {
      return aPrerequisites.compareTo(bPrerequisites);
    }

    if (a.competencyId == b.competencyId) {
      final aTaskLast = _lastPracticedTaskAt(a.id, history);
      final bTaskLast = _lastPracticedTaskAt(b.id, history);
      if (aTaskLast == null && bTaskLast != null) return -1;
      if (aTaskLast != null && bTaskLast == null) return 1;
      if (aTaskLast != null && bTaskLast != null && aTaskLast != bTaskLast) {
        return aTaskLast.compareTo(bTaskLast);
      }

      final domain = GermanCompetencyCatalog.definition(a.competencyId).domain;
      if (domain == GermanLearningDomain.writing) {
        final interaction = _writingInteractionPriority(
          a.interaction,
        ).compareTo(_writingInteractionPriority(b.interaction));
        if (interaction != 0) return interaction;
      }
      final idOrder = a.id.compareTo(b.id);
      if (idOrder != 0) return idOrder;
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

  static int _priorityBucket(
    GermanCompetencyProgress progress, {
    DateTime? now,
  }) {
    if (progress.state == GermanCompetencyState.learning &&
        progress.recentAccuracy < 0.8) {
      return 0;
    }
    if (progress.needsReview(now: now)) return 1;
    return switch (progress.state) {
      GermanCompetencyState.newSkill => 2,
      GermanCompetencyState.learning => 3,
      GermanCompetencyState.secure => 4,
    };
  }

  static int _writingInteractionPriority(GermanTaskInteraction interaction) =>
      switch (interaction) {
        GermanTaskInteraction.typedText => 0,
        GermanTaskInteraction.wordOrder => 1,
        GermanTaskInteraction.singleChoice => 2,
        GermanTaskInteraction.listeningChoice => 3,
      };

  static DateTime? _lastPracticedTaskAt(
    String taskId,
    Iterable<GermanSessionResult> history,
  ) {
    DateTime? latest;
    for (final session in history) {
      if (!session.taskResults.any((result) => result.taskId == taskId)) {
        continue;
      }
      if (latest == null || session.finishedAt.isAfter(latest)) {
        latest = session.finishedAt;
      }
    }
    return latest;
  }

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
      if (progress.state != GermanCompetencyState.secure) unmet += 1;
    }
    return unmet;
  }
}
