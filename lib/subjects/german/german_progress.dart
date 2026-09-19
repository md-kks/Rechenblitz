import 'german_competency.dart';
import 'german_history_scope.dart';
import 'german_session.dart';

enum GermanCompetencyState { newSkill, learning, secure }

enum GermanPracticeAttention { needsPractice, reviewDue, none }

class GermanCompetencyProgress {
  const GermanCompetencyProgress({
    required this.competencyId,
    required this.attempts,
    required this.independentAttempts,
    required this.correctFirstTry,
    required this.incorrectAttempts,
    required this.averageResponseMs,
    required this.distinctTaskCount,
    required this.sessionCount,
    required this.recentAttempts,
    required this.recentCorrectFirstTry,
    this.lastPracticedAt,
  });

  final GermanCompetencyId competencyId;
  final int attempts;
  final int independentAttempts;
  final int correctFirstTry;
  final int incorrectAttempts;
  final double averageResponseMs;
  final int distinctTaskCount;
  final int sessionCount;
  final int recentAttempts;
  final int recentCorrectFirstTry;
  final DateTime? lastPracticedAt;

  double get accuracy =>
      independentAttempts == 0 ? 0 : correctFirstTry / independentAttempts;
  double get recentAccuracy =>
      recentAttempts == 0 ? 0 : recentCorrectFirstTry / recentAttempts;

  int get assistedAttempts => attempts - independentAttempts;

  bool get needsMoreIndependentEvidence =>
      state == GermanCompetencyState.learning &&
      assistedAttempts > 0 &&
      (independentAttempts < 3 || distinctTaskCount < 3 || sessionCount < 2);

  GermanCompetencyState get state {
    if (attempts == 0) return GermanCompetencyState.newSkill;
    if (independentAttempts >= 3 &&
        distinctTaskCount >= 3 &&
        sessionCount >= 2 &&
        accuracy >= 0.8 &&
        recentAccuracy >= 0.75) {
      return GermanCompetencyState.secure;
    }
    return GermanCompetencyState.learning;
  }

  bool needsReview({
    DateTime? now,
    Duration interval = const Duration(days: 14),
  }) {
    final last = lastPracticedAt;
    if (state != GermanCompetencyState.secure || last == null) return false;
    final reference = now ?? DateTime.now();
    return reference.difference(last) >= interval;
  }

  GermanPracticeAttention attention({DateTime? now}) {
    if (state == GermanCompetencyState.learning &&
        independentAttempts > 0 &&
        recentAccuracy < 0.8) {
      return GermanPracticeAttention.needsPractice;
    }
    if (needsReview(now: now)) return GermanPracticeAttention.reviewDue;
    return GermanPracticeAttention.none;
  }

  String get shortLabel => switch (state) {
    GermanCompetencyState.newSkill => 'Neu',
    GermanCompetencyState.learning => 'Im Aufbau',
    GermanCompetencyState.secure => 'Sicher',
  };
}

class GermanProgressAnalyzer {
  const GermanProgressAnalyzer._();

  static GermanCompetencyProgress forCompetency(
    GermanCompetencyId competencyId,
    Iterable<GermanSessionResult> history,
  ) {
    final sessions = GermanHistoryScope.unique(history);
    final matching = <({GermanTaskResult result, DateTime finishedAt})>[];
    for (final session in sessions) {
      for (final result in session.taskResults) {
        if (result.competencyId == competencyId) {
          matching.add((result: result, finishedAt: session.finishedAt));
        }
      }
    }

    if (matching.isEmpty) {
      return GermanCompetencyProgress(
        competencyId: competencyId,
        attempts: 0,
        independentAttempts: 0,
        correctFirstTry: 0,
        incorrectAttempts: 0,
        averageResponseMs: 0,
        distinctTaskCount: 0,
        sessionCount: 0,
        recentAttempts: 0,
        recentCorrectFirstTry: 0,
      );
    }

    matching.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    final independent = matching
        .where((entry) => !entry.result.usedReadAloud)
        .toList(growable: false);
    final recent = independent.take(5).toList(growable: false);
    final correct = independent
        .where((entry) => entry.result.correctFirstTry)
        .length;
    final recentCorrect = recent
        .where((entry) => entry.result.correctFirstTry)
        .length;
    final distinctTaskCount = independent
        .map((entry) => entry.result.taskId)
        .toSet()
        .length;
    var sessionCount = 0;
    for (final session in sessions) {
      if (session.taskResults.any(
        (result) =>
            result.competencyId == competencyId && !result.usedReadAloud,
      )) {
        sessionCount += 1;
      }
    }
    final incorrect = matching.fold<int>(
      0,
      (sum, entry) => sum + entry.result.incorrectAttempts,
    );
    final responseTotal = matching.fold<int>(
      0,
      (sum, entry) => sum + entry.result.responseMs,
    );
    final recencyEvidence = independent.isEmpty ? matching : independent;
    final lastPracticedAt = recencyEvidence
        .map((entry) => entry.finishedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return GermanCompetencyProgress(
      competencyId: competencyId,
      attempts: matching.length,
      independentAttempts: independent.length,
      correctFirstTry: correct,
      incorrectAttempts: incorrect,
      averageResponseMs: responseTotal / matching.length,
      distinctTaskCount: distinctTaskCount,
      sessionCount: sessionCount,
      recentAttempts: recent.length,
      recentCorrectFirstTry: recentCorrect,
      lastPracticedAt: lastPracticedAt,
    );
  }
}
