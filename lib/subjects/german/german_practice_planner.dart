import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_grade_bridge.dart';
import 'german_history_scope.dart';
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
    bool prioritizeIndependentReading = false,
  }) {
    if (taskCount < 1) return const <GermanTask>[];
    final scopedHistory = GermanHistoryScope.throughGrade(history, gradeLevel);
    final ranked = _ranked(
      GermanTaskCatalog.forGrade(gradeLevel),
      scopedHistory,
      gradeLevel: gradeLevel,
      now: now,
      prioritizeIndependentReading: prioritizeIndependentReading,
    );
    if (ranked.length <= taskCount) return ranked;

    final domains = ranked
        .map(
          (task) =>
              GermanCompetencyCatalog.definition(task.competencyId).domain,
        )
        .toSet();
    final evenShare = (taskCount / domains.length).ceil();
    final balancedDomainCap = evenShare < 1 ? 1 : evenShare;
    final focusedDomains = <GermanLearningDomain>{};
    for (final task in ranked) {
      final progress = GermanProgressAnalyzer.forCompetency(
        task.competencyId,
        scopedHistory,
      );
      if (_taskPriorityBucket(
            task,
            progress,
            scopedHistory,
            gradeLevel: gradeLevel,
            now: now,
            prioritizeIndependentReading: prioritizeIndependentReading,
          ) <=
          2) {
        focusedDomains.add(
          GermanCompetencyCatalog.definition(task.competencyId).domain,
        );
      }
    }
    final hasAdaptiveFocus = focusedDomains.isNotEmpty;
    final adaptiveDomainCap = balancedDomainCap + 1;
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

    // First guarantee broad subject coverage before adding adaptive extras.
    for (final task in ranked) {
      final domain = GermanCompetencyCatalog.definition(
        task.competencyId,
      ).domain;
      if ((domainCount[domain] ?? 0) > 0) continue;
      add(task);
      if (selected.length == taskCount) return selected;
    }

    if (hasAdaptiveFocus) {
      for (final task in ranked) {
        if (selectedIds.contains(task.id)) continue;
        final domain = GermanCompetencyCatalog.definition(
          task.competencyId,
        ).domain;
        if (!focusedDomains.contains(domain)) continue;
        if ((domainCount[domain] ?? 0) >= adaptiveDomainCap) continue;
        if ((competencyCount[task.competencyId] ?? 0) >= 3) continue;
        add(task);
        if (selected.length == taskCount) return selected;
      }
    }

    // Fill non-focus space evenly so adaptivity does not crowd out whole areas.
    for (final task in ranked) {
      if (selectedIds.contains(task.id)) continue;
      final domain = GermanCompetencyCatalog.definition(
        task.competencyId,
      ).domain;
      if ((domainCount[domain] ?? 0) >= balancedDomainCap) continue;
      if ((competencyCount[task.competencyId] ?? 0) >= 1) continue;
      add(task);
      if (selected.length == taskCount) return selected;
    }

    for (final task in ranked) {
      if (selectedIds.contains(task.id)) continue;
      final domain = GermanCompetencyCatalog.definition(
        task.competencyId,
      ).domain;
      if ((domainCount[domain] ?? 0) >= balancedDomainCap) continue;
      add(task);
      if (selected.length == taskCount) return selected;
    }

    if (hasAdaptiveFocus) {
      for (final task in ranked) {
        if (selectedIds.contains(task.id)) continue;
        final domain = GermanCompetencyCatalog.definition(
          task.competencyId,
        ).domain;
        if ((domainCount[domain] ?? 0) >= adaptiveDomainCap) continue;
        add(task);
        if (selected.length == taskCount) return selected;
      }
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
    final scopedHistory = GermanHistoryScope.throughGrade(history, gradeLevel);
    final ranked = _ranked(
      GermanTaskCatalog.forDomain(domain, gradeLevel),
      scopedHistory,
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
    final scopedHistory = GermanHistoryScope.throughGrade(history, gradeLevel);
    final source = GermanTaskCatalog.forCompetency(
      competencyId,
    ).where((task) => task.recommendedFromGrade.index <= gradeLevel.index);
    final ranked = _ranked(
      source,
      scopedHistory,
      gradeLevel: gradeLevel,
      now: now,
    );
    if (ranked.isEmpty) return const <GermanTask>[];
    return List<GermanTask>.generate(
      taskCount,
      (index) => ranked[index % ranked.length],
      growable: false,
    );
  }

  static List<GermanTask> buildGradeBridgeRound({
    required GradeLevel gradeLevel,
    required GermanCompetencyId competencyId,
    required Iterable<GermanSessionResult> history,
    int taskCount = 2,
    DateTime? now,
  }) {
    if (taskCount < 1) return const <GermanTask>[];
    final scopedHistory = GermanHistoryScope.throughGrade(history, gradeLevel);
    final bridge = GermanGradeBridgeAnalyzer.forCompetency(
      competencyId: competencyId,
      currentGrade: gradeLevel,
      history: scopedHistory,
    );
    final bridgeTaskGrade = bridge.bridgeTaskGrade;
    if (!bridge.isPending || bridgeTaskGrade == null) {
      return const <GermanTask>[];
    }
    final source = GermanTaskCatalog.forCompetency(
      competencyId,
    ).where((task) => task.recommendedFromGrade == bridgeTaskGrade);
    final ranked = _ranked(
      source,
      scopedHistory,
      gradeLevel: gradeLevel,
      now: now,
    );
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
    final scopedHistory = GermanHistoryScope.throughGrade(
      history,
      assignment.gradeLevel,
    );
    final target = assignment.targetCompetency;
    if (target != null) {
      final source = GermanTaskCatalog.forCompetency(target).where(
        (task) =>
            task.recommendedFromGrade.index <= assignment.gradeLevel.index,
      );
      final ranked = _ranked(
        source,
        scopedHistory,
        gradeLevel: assignment.gradeLevel,
        now: now,
      );
      return _takeBalancedAssignmentTasks(
        rankedByCompetency: <GermanCompetencyId, List<GermanTask>>{
          target: ranked,
        },
        competencyOrder: <GermanCompetencyId>[target],
        taskCount: assignment.tasks,
      );
    }

    final ranked = _ranked(
      GermanTaskCatalog.forDomain(assignment.domain, assignment.gradeLevel),
      scopedHistory,
      gradeLevel: assignment.gradeLevel,
      now: now,
    );
    if (ranked.isEmpty) return const <GermanTask>[];

    final competencyOrder = <GermanCompetencyId>[];
    final rankedByCompetency = <GermanCompetencyId, List<GermanTask>>{};
    for (final task in ranked) {
      if (!rankedByCompetency.containsKey(task.competencyId)) {
        competencyOrder.add(task.competencyId);
        rankedByCompetency[task.competencyId] = <GermanTask>[];
      }
      rankedByCompetency[task.competencyId]!.add(task);
    }

    final activeCompetencies = competencyOrder
        .take(
          assignment.tasks < competencyOrder.length
              ? assignment.tasks
              : competencyOrder.length,
        )
        .toList(growable: false);
    return _takeBalancedAssignmentTasks(
      rankedByCompetency: rankedByCompetency,
      competencyOrder: activeCompetencies,
      taskCount: assignment.tasks,
    );
  }

  static List<GermanTask> _takeBalancedAssignmentTasks({
    required Map<GermanCompetencyId, List<GermanTask>> rankedByCompetency,
    required List<GermanCompetencyId> competencyOrder,
    required int taskCount,
  }) {
    if (taskCount < 1 || competencyOrder.isEmpty) {
      return const <GermanTask>[];
    }

    final selected = <GermanTask>[];
    final offsets = <GermanCompetencyId, int>{
      for (final competency in competencyOrder) competency: 0,
    };

    // Use every distinct task before repeating any task.
    while (selected.length < taskCount) {
      var added = false;
      for (final competency in competencyOrder) {
        final tasks = rankedByCompetency[competency] ?? const <GermanTask>[];
        final offset = offsets[competency] ?? 0;
        if (offset >= tasks.length) continue;
        selected.add(tasks[offset]);
        offsets[competency] = offset + 1;
        added = true;
        if (selected.length == taskCount) return selected;
      }
      if (!added) break;
    }

    // Very large assignments may exceed the curated unique pool. Repeat only
    // after all selected competencies have exhausted their distinct tasks.
    var repeatRound = 0;
    while (selected.length < taskCount) {
      var added = false;
      for (final competency in competencyOrder) {
        final tasks = rankedByCompetency[competency] ?? const <GermanTask>[];
        if (tasks.isEmpty) continue;
        selected.add(tasks[repeatRound % tasks.length]);
        added = true;
        if (selected.length == taskCount) return selected;
      }
      if (!added) break;
      repeatRound += 1;
    }
    return selected;
  }

  static List<GermanTask> _ranked(
    Iterable<GermanTask> source,
    Iterable<GermanSessionResult> history, {
    required GradeLevel gradeLevel,
    DateTime? now,
    bool prioritizeIndependentReading = false,
  }) {
    final result = source.toList();
    result.sort(
      (a, b) => _compareTasks(
        a,
        b,
        history,
        gradeLevel: gradeLevel,
        now: now,
        prioritizeIndependentReading: prioritizeIndependentReading,
      ),
    );
    return result;
  }

  static int _compareTasks(
    GermanTask a,
    GermanTask b,
    Iterable<GermanSessionResult> history, {
    required GradeLevel gradeLevel,
    DateTime? now,
    bool prioritizeIndependentReading = false,
  }) {
    final aProgress = GermanProgressAnalyzer.forCompetency(
      a.competencyId,
      history,
    );
    final bProgress = GermanProgressAnalyzer.forCompetency(
      b.competencyId,
      history,
    );
    final aBucket = _taskPriorityBucket(
      a,
      aProgress,
      history,
      gradeLevel: gradeLevel,
      now: now,
      prioritizeIndependentReading: prioritizeIndependentReading,
    );
    final bBucket = _taskPriorityBucket(
      b,
      bProgress,
      history,
      gradeLevel: gradeLevel,
      now: now,
      prioritizeIndependentReading: prioritizeIndependentReading,
    );
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

  static int _taskPriorityBucket(
    GermanTask task,
    GermanCompetencyProgress progress,
    Iterable<GermanSessionResult> history, {
    required GradeLevel gradeLevel,
    DateTime? now,
    bool prioritizeIndependentReading = false,
  }) {
    final attention = progress.attention(now: now);
    final bridge = GermanGradeBridgeAnalyzer.forCompetency(
      competencyId: task.competencyId,
      currentGrade: gradeLevel,
      history: history,
    );
    final isBridgeTask =
        bridge.isPending &&
        bridge.bridgeTaskGrade != null &&
        task.recommendedFromGrade == bridge.bridgeTaskGrade;

    if (attention == GermanPracticeAttention.needsPractice) {
      if (bridge.isPending) return isBridgeTask ? 0 : 4;
      return 0;
    }

    final needsIndependentReading =
        prioritizeIndependentReading &&
        GermanCompetencyCatalog.definition(task.competencyId).domain ==
            GermanLearningDomain.reading &&
        progress.needsMoreIndependentEvidence;
    if (needsIndependentReading) return 1;

    if (progress.state == GermanCompetencyState.secure && isBridgeTask) {
      return 1;
    }

    if (attention == GermanPracticeAttention.reviewDue) return 2;
    return switch (progress.state) {
      GermanCompetencyState.newSkill => 3,
      GermanCompetencyState.learning => 4,
      GermanCompetencyState.secure => 5,
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
