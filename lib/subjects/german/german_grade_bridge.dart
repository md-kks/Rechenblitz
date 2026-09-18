import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_history_scope.dart';
import 'german_progress.dart';
import 'german_session.dart';
import 'german_task_catalog.dart';

enum GermanGradeBridgeState { notNeeded, pending, confirmed }

class GermanGradeBridgeStatus {
  const GermanGradeBridgeStatus({
    required this.competencyId,
    required this.currentGrade,
    required this.state,
    required this.bridgeTaskCount,
    required this.currentGradeAttempts,
    required this.currentGradeCorrectFirstTry,
    required this.currentGradeDistinctTasks,
    this.sourceGrade,
    this.bridgeTaskGrade,
  });

  final GermanCompetencyId competencyId;
  final GradeLevel currentGrade;
  final GermanGradeBridgeState state;
  final GradeLevel? sourceGrade;

  /// Highest newer difficulty level that still needs confirmation.
  ///
  /// This can be below [currentGrade] when a learner skips a grade and the
  /// competency has no newer task set on the current grade itself.
  final GradeLevel? bridgeTaskGrade;
  final int bridgeTaskCount;

  /// Evidence completed while the learner is currently assigned to
  /// [currentGrade], using tasks from [bridgeTaskGrade].
  final int currentGradeAttempts;
  final int currentGradeCorrectFirstTry;
  final int currentGradeDistinctTasks;

  bool get isPending => state == GermanGradeBridgeState.pending;
  bool get isConfirmed => state == GermanGradeBridgeState.confirmed;

  int get requiredDistinctTasks => bridgeTaskCount < 2 ? 1 : 2;

  double get currentGradeAccuracy => currentGradeAttempts == 0
      ? 0
      : currentGradeCorrectFirstTry / currentGradeAttempts;
}

class GermanGradeBridgeAnalyzer {
  const GermanGradeBridgeAnalyzer._();

  static GermanGradeBridgeStatus forCompetency({
    required GermanCompetencyId competencyId,
    required GradeLevel currentGrade,
    required Iterable<GermanSessionResult> history,
  }) {
    if (currentGrade == GradeLevel.first) {
      return _notNeeded(competencyId: competencyId, currentGrade: currentGrade);
    }

    final sessions = GermanHistoryScope.unique(history);
    final priorSessions = sessions
        .where((session) => session.gradeLevel.index < currentGrade.index)
        .toList(growable: false);
    final priorProgress = GermanProgressAnalyzer.forCompetency(
      competencyId,
      priorSessions,
    );
    if (priorProgress.state != GermanCompetencyState.secure) {
      return _notNeeded(competencyId: competencyId, currentGrade: currentGrade);
    }

    final competencyTasks = GermanTaskCatalog.forCompetency(competencyId);
    if (competencyTasks.isEmpty) {
      return _notNeeded(competencyId: competencyId, currentGrade: currentGrade);
    }

    var sourceGrade = competencyTasks.first.recommendedFromGrade;
    for (final task in competencyTasks.skip(1)) {
      if (task.recommendedFromGrade.index < sourceGrade.index) {
        sourceGrade = task.recommendedFromGrade;
      }
    }

    for (final grade in GradeLevel.values) {
      if (grade.index <= sourceGrade.index) continue;
      if (grade.index >= currentGrade.index) break;
      final extensionTasks = competencyTasks
          .where((task) => task.recommendedFromGrade == grade)
          .toList(growable: false);
      if (extensionTasks.isEmpty) {
        sourceGrade = grade;
        continue;
      }
      if (_extensionConfirmed(
        competencyId: competencyId,
        taskIds: extensionTasks.map((task) => task.id).toSet(),
        taskCount: extensionTasks.length,
        sessions: priorSessions,
        minimumSessionGrade: grade,
      )) {
        sourceGrade = grade;
      }
    }

    final newerTasks = competencyTasks
        .where(
          (task) =>
              task.recommendedFromGrade.index > sourceGrade.index &&
              task.recommendedFromGrade.index <= currentGrade.index,
        )
        .toList(growable: false);
    if (newerTasks.isEmpty) {
      return _notNeeded(
        competencyId: competencyId,
        currentGrade: currentGrade,
        sourceGrade: sourceGrade,
      );
    }

    var bridgeTaskGrade = newerTasks.first.recommendedFromGrade;
    for (final task in newerTasks.skip(1)) {
      if (task.recommendedFromGrade.index > bridgeTaskGrade.index) {
        bridgeTaskGrade = task.recommendedFromGrade;
      }
    }
    final bridgeTasks = newerTasks
        .where((task) => task.recommendedFromGrade == bridgeTaskGrade)
        .toList(growable: false);
    final bridgeTaskIds = bridgeTasks.map((task) => task.id).toSet();

    final currentResults = <GermanTaskResult>[];
    for (final session in sessions) {
      if (session.gradeLevel != currentGrade) continue;
      for (final result in session.taskResults) {
        if (result.competencyId == competencyId &&
            bridgeTaskIds.contains(result.taskId)) {
          currentResults.add(result);
        }
      }
    }

    final attempts = currentResults.length;
    final correct = currentResults
        .where((result) => result.correctFirstTry)
        .length;
    final distinct = currentResults
        .map((result) => result.taskId)
        .toSet()
        .length;
    final requiredDistinct = bridgeTasks.length < 2 ? 1 : 2;
    final accuracy = attempts == 0 ? 0 : correct / attempts;
    final confirmed =
        attempts >= 2 && distinct >= requiredDistinct && accuracy >= 0.75;

    return GermanGradeBridgeStatus(
      competencyId: competencyId,
      currentGrade: currentGrade,
      state: confirmed
          ? GermanGradeBridgeState.confirmed
          : GermanGradeBridgeState.pending,
      sourceGrade: sourceGrade,
      bridgeTaskGrade: bridgeTaskGrade,
      bridgeTaskCount: bridgeTasks.length,
      currentGradeAttempts: attempts,
      currentGradeCorrectFirstTry: correct,
      currentGradeDistinctTasks: distinct,
    );
  }

  static bool _extensionConfirmed({
    required GermanCompetencyId competencyId,
    required Set<String> taskIds,
    required int taskCount,
    required Iterable<GermanSessionResult> sessions,
    required GradeLevel minimumSessionGrade,
  }) {
    final results = <GermanTaskResult>[];
    for (final session in sessions) {
      if (session.gradeLevel.index < minimumSessionGrade.index) continue;
      for (final result in session.taskResults) {
        if (result.competencyId == competencyId &&
            taskIds.contains(result.taskId)) {
          results.add(result);
        }
      }
    }
    if (results.length < 2) return false;
    final distinct = results.map((result) => result.taskId).toSet().length;
    final requiredDistinct = taskCount < 2 ? 1 : 2;
    if (distinct < requiredDistinct) return false;
    final correct = results.where((result) => result.correctFirstTry).length;
    return correct / results.length >= 0.75;
  }

  static GermanGradeBridgeStatus _notNeeded({
    required GermanCompetencyId competencyId,
    required GradeLevel currentGrade,
    GradeLevel? sourceGrade,
  }) => GermanGradeBridgeStatus(
    competencyId: competencyId,
    currentGrade: currentGrade,
    state: GermanGradeBridgeState.notNeeded,
    sourceGrade: sourceGrade,
    bridgeTaskCount: 0,
    currentGradeAttempts: 0,
    currentGradeCorrectFirstTry: 0,
    currentGradeDistinctTasks: 0,
  );
}
