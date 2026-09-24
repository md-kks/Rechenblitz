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
import 'german_task_challenge.dart';
import 'german_task_evidence_priority.dart';
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
    final rankingContext = _GermanRankingContext(
      history: scopedHistory,
      gradeLevel: gradeLevel,
      now: now,
      prioritizeIndependentReading: prioritizeIndependentReading,
    );
    final ranked = _ranked(
      GermanTaskCatalog.forGrade(gradeLevel),
      scopedHistory,
      gradeLevel: gradeLevel,
      now: now,
      prioritizeIndependentReading: prioritizeIndependentReading,
      rankingContext: rankingContext,
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
      final progress = rankingContext.progressFor(task.competencyId);
      if (rankingContext.priorityBucket(task, progress: progress) <= 2) {
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

    // Keep ordinary practice on the child's current grade before using
    // untouched older competencies merely for variety. Prefer a second current
    // competency first, then allow a second task from the same current-grade
    // competency when a domain has only one skill introduced at this grade.
    for (final task in ranked) {
      if (selectedIds.contains(task.id)) continue;
      if (task.recommendedFromGrade != gradeLevel) continue;
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
      if (task.recommendedFromGrade != gradeLevel) continue;
      final domain = GermanCompetencyCatalog.definition(
        task.competencyId,
      ).domain;
      if ((domainCount[domain] ?? 0) >= balancedDomainCap) continue;
      add(task);
      if (selected.length == taskCount) return selected;
    }

    // Fill any remaining non-focus space evenly. This is where older material
    // may enter when the current grade genuinely cannot supply the slot.
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
    bool prioritizeIndependentReading = false,
  }) {
    final scopedHistory = GermanHistoryScope.throughGrade(history, gradeLevel);
    final ranked = _ranked(
      GermanTaskCatalog.forDomain(domain, gradeLevel),
      scopedHistory,
      gradeLevel: gradeLevel,
      now: now,
      prioritizeIndependentReading: prioritizeIndependentReading,
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
    final rankingContext = _GermanRankingContext(
      history: scopedHistory,
      gradeLevel: gradeLevel,
      now: now,
      prioritizeIndependentReading: false,
    );
    final ranked = _ranked(
      source,
      scopedHistory,
      gradeLevel: gradeLevel,
      now: now,
      rankingContext: rankingContext,
    );
    if (ranked.isEmpty) return const <GermanTask>[];
    final selected = List<GermanTask>.generate(
      taskCount,
      (index) => ranked[index % ranked.length],
      growable: false,
    );
    return rankingContext.sequenceCompetencyRound(selected);
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
    _GermanRankingContext? rankingContext,
  }) {
    final result = source.toList();
    final context =
        rankingContext ??
        _GermanRankingContext(
          history: history,
          gradeLevel: gradeLevel,
          now: now,
          prioritizeIndependentReading: prioritizeIndependentReading,
        );
    result.sort((a, b) => _compareTasks(a, b, context));
    return result;
  }

  static int _compareTasks(
    GermanTask a,
    GermanTask b,
    _GermanRankingContext rankingContext,
  ) => rankingContext.compare(a, b);
}

class _GermanRankingContext {
  _GermanRankingContext({
    required Iterable<GermanSessionResult> history,
    required this.gradeLevel,
    required this.now,
    required this.prioritizeIndependentReading,
  }) : history = history.toList(growable: false) {
    for (final session in this.history) {
      for (final result in session.taskResults) {
        final previousCompetency =
            _latestCompetencyPracticeAt[result.competencyId];
        if (previousCompetency == null ||
            session.finishedAt.isAfter(previousCompetency)) {
          _latestCompetencyPracticeAt[result.competencyId] = session.finishedAt;
        }
        final previous = _lastPracticedTaskAt[result.taskId];
        if (previous == null || session.finishedAt.isAfter(previous)) {
          _lastPracticedTaskAt[result.taskId] = session.finishedAt;
          _latestTaskResult[result.taskId] = result;
        }
      }
    }
  }

  final List<GermanSessionResult> history;
  final GradeLevel gradeLevel;
  final DateTime? now;
  final bool prioritizeIndependentReading;

  final Map<GermanCompetencyId, GermanCompetencyProgress>
  _progressByCompetency = <GermanCompetencyId, GermanCompetencyProgress>{};
  final Map<GermanCompetencyId, GermanGradeBridgeStatus> _bridgeByCompetency =
      <GermanCompetencyId, GermanGradeBridgeStatus>{};
  final Map<GermanCompetencyId, int> _unmetPrerequisitesByCompetency =
      <GermanCompetencyId, int>{};
  final Map<String, DateTime> _lastPracticedTaskAt = <String, DateTime>{};
  final Map<String, GermanTaskResult> _latestTaskResult =
      <String, GermanTaskResult>{};
  final Map<GermanCompetencyId, DateTime> _latestCompetencyPracticeAt =
      <GermanCompetencyId, DateTime>{};

  GermanCompetencyProgress progressFor(GermanCompetencyId competencyId) =>
      _progressByCompetency.putIfAbsent(
        competencyId,
        () => GermanProgressAnalyzer.forCompetency(competencyId, history),
      );

  GermanGradeBridgeStatus bridgeFor(GermanCompetencyId competencyId) =>
      _bridgeByCompetency.putIfAbsent(
        competencyId,
        () => GermanGradeBridgeAnalyzer.forCompetency(
          competencyId: competencyId,
          currentGrade: gradeLevel,
          history: history,
        ),
      );

  int priorityBucket(GermanTask task, {GermanCompetencyProgress? progress}) {
    final competencyProgress = progress ?? progressFor(task.competencyId);
    final attention = competencyProgress.attention(now: now);
    final bridge = bridgeFor(task.competencyId);
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
        competencyProgress.needsMoreIndependentEvidence;
    if (needsIndependentReading) return 1;

    if (competencyProgress.state == GermanCompetencyState.secure &&
        isBridgeTask) {
      return 1;
    }

    if (attention == GermanPracticeAttention.reviewDue) return 2;
    return switch (competencyProgress.state) {
      GermanCompetencyState.newSkill => 3,
      GermanCompetencyState.learning => 4,
      GermanCompetencyState.secure => 5,
    };
  }

  int compare(GermanTask a, GermanTask b) {
    final aProgress = progressFor(a.competencyId);
    final bProgress = progressFor(b.competencyId);
    final aBucket = priorityBucket(a, progress: aProgress);
    final bBucket = priorityBucket(b, progress: bProgress);
    final aHasAdaptivePriority = aBucket <= 2;
    final bHasAdaptivePriority = bBucket <= 2;

    // Proven weakness, independent-reading follow-up, grade bridges and due
    // reviews may intentionally pull older material forward. In ordinary
    // practice, however, current-grade work must outrank merely unseen older
    // tasks. Otherwise a successful upper-primary round immediately regresses
    // into lower-primary content just because it has not been attempted yet.
    if (aHasAdaptivePriority || bHasAdaptivePriority) {
      if (aBucket != bBucket) return aBucket.compareTo(bBucket);
    } else {
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
      if (aBucket != bBucket) return aBucket.compareTo(bBucket);
    }

    if (aProgress.state == GermanCompetencyState.learning &&
        bProgress.state == GermanCompetencyState.learning &&
        aProgress.recentAccuracy != bProgress.recentAccuracy) {
      return aProgress.recentAccuracy.compareTo(bProgress.recentAccuracy);
    }

    final aPrerequisites = unmetPrerequisitesFor(a.competencyId);
    final bPrerequisites = unmetPrerequisitesFor(b.competencyId);
    if (aPrerequisites != bPrerequisites) {
      return aPrerequisites.compareTo(bPrerequisites);
    }

    if (a.competencyId == b.competencyId) {
      final aTaskLast = _lastPracticedTaskAt[a.id];
      final bTaskLast = _lastPracticedTaskAt[b.id];
      if (aTaskLast == null && bTaskLast != null) {
        if (_taskFollowUpIsDue(b)) return 1;
        return -1;
      }
      if (aTaskLast != null && bTaskLast == null) {
        if (_taskFollowUpIsDue(a)) return -1;
        return 1;
      }
      if (aTaskLast != null && bTaskLast != null) {
        final aFollowUp = _taskFollowUpPriority(a.id);
        final bFollowUp = _taskFollowUpPriority(b.id);
        if (aFollowUp != bFollowUp) {
          return aFollowUp.compareTo(bFollowUp);
        }
        if (aTaskLast != bTaskLast) {
          return aTaskLast.compareTo(bTaskLast);
        }
      }

      final interaction = GermanTaskEvidencePriority.rank(
        a,
      ).compareTo(GermanTaskEvidencePriority.rank(b));
      if (interaction != 0) return interaction;
      if (a.recommendedFromGrade == b.recommendedFromGrade) {
        final challenge = _compareChallenge(a, b, aProgress);
        if (challenge != 0) return challenge;
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

  List<GermanTask> sequenceCompetencyRound(List<GermanTask> tasks) {
    if (tasks.length < 2) return tasks;

    final priority = <GermanTask>[];
    final ramp = <GermanTask>[];
    for (final task in tasks) {
      final bridge = bridgeFor(task.competencyId);
      final isBridgeTask =
          bridge.isPending &&
          bridge.bridgeTaskGrade != null &&
          task.recommendedFromGrade == bridge.bridgeTaskGrade;
      final isDueFollowUp =
          _taskFollowUpPriority(task.id) <= 1 && _taskFollowUpIsDue(task);
      (isBridgeTask || isDueFollowUp ? priority : ramp).add(task);
    }

    priority.sort(compare);
    ramp.sort((a, b) {
      final aDistance = gradeLevel.index - a.recommendedFromGrade.index;
      final bDistance = gradeLevel.index - b.recommendedFromGrade.index;
      if (aDistance != bDistance) return aDistance.compareTo(bDistance);

      final evidence = GermanTaskEvidencePriority.rank(
        a,
      ).compareTo(GermanTaskEvidencePriority.rank(b));
      if (evidence != 0) return evidence;

      final challenge = GermanTaskChallenge.score(
        a,
      ).compareTo(GermanTaskChallenge.score(b));
      if (challenge != 0) return challenge;
      return a.id.compareTo(b.id);
    });
    return <GermanTask>[...priority, ...ramp];
  }

  int _compareChallenge(
    GermanTask a,
    GermanTask b,
    GermanCompetencyProgress progress,
  ) {
    final aScore = GermanTaskChallenge.score(a);
    final bScore = GermanTaskChallenge.score(b);
    if (aScore == bScore) return 0;

    final attention = progress.attention(now: now);
    final prefersHigherChallenge =
        progress.state == GermanCompetencyState.secure ||
        (progress.state == GermanCompetencyState.learning &&
            attention != GermanPracticeAttention.needsPractice &&
            progress.recentAttempts >= 2 &&
            progress.recentAccuracy >= 0.8);
    return prefersHigherChallenge
        ? bScore.compareTo(aScore)
        : aScore.compareTo(bScore);
  }

  bool _taskFollowUpIsDue(GermanTask task) {
    if (_taskFollowUpPriority(task.id) >= 2) return false;
    final taskLast = _lastPracticedTaskAt[task.id];
    final competencyLast = _latestCompetencyPracticeAt[task.competencyId];
    if (taskLast == null || competencyLast == null) return false;
    return competencyLast.isAfter(taskLast);
  }

  int _taskFollowUpPriority(String taskId) {
    final result = _latestTaskResult[taskId];
    if (result == null) return 3;
    if (!result.correctFirstTry || result.incorrectAttempts > 0) return 0;
    if (result.usedReadAloud) return 1;
    return 2;
  }

  int unmetPrerequisitesFor(GermanCompetencyId competencyId) =>
      _unmetPrerequisitesByCompetency.putIfAbsent(competencyId, () {
        final definition = GermanCompetencyCatalog.definition(competencyId);
        var unmet = 0;
        for (final prerequisite in definition.prerequisites) {
          if (progressFor(prerequisite).state != GermanCompetencyState.secure) {
            unmet += 1;
          }
        }
        return unmet;
      });
}
