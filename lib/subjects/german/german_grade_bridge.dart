import '../../core/grade_level.dart';
import 'german_competency.dart';
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

    final sessions = history.toList(growable: false);
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

    GradeLevel? sourceGrade;
    for (final session in priorSessions) {
      if (!session.taskResults.any(
        (result) => result.competencyId == competencyId,
      )) {
        continue;
      }
      if (sourceGrade == null || session.gradeLevel.index > sourceGrade.index) {
        sourceGrade = session.gradeLevel;
      }
    }
    if (sourceGrade == null) {
      return _notNeeded(competencyId: competencyId, currentGrade: currentGrade);
    }

    final newerTasks = GermanTaskCatalog.forCompetency(competencyId)
        .where(
          (task) =>
              task.recommendedFromGrade.index > sourceGrade!.index &&
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
