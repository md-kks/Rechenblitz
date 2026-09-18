import 'german_competency.dart';
import 'german_session.dart';

enum GermanCompetencyState { newSkill, learning, secure }

class GermanCompetencyProgress {
  const GermanCompetencyProgress({
    required this.competencyId,
    required this.attempts,
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
  final int correctFirstTry;
  final int incorrectAttempts;
  final double averageResponseMs;
  final int distinctTaskCount;
  final int sessionCount;
  final int recentAttempts;
  final int recentCorrectFirstTry;
  final DateTime? lastPracticedAt;

  double get accuracy => attempts == 0 ? 0 : correctFirstTry / attempts;
  double get recentAccuracy =>
      recentAttempts == 0 ? 0 : recentCorrectFirstTry / recentAttempts;

  GermanCompetencyState get state {
    if (attempts == 0) return GermanCompetencyState.newSkill;
    if (attempts >= 3 &&
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
    final matching = <({GermanTaskResult result, DateTime finishedAt})>[];
    for (final session in history) {
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
    final recent = matching.take(5).toList(growable: false);
    final correct = matching
        .where((entry) => entry.result.correctFirstTry)
        .length;
    final recentCorrect = recent
        .where((entry) => entry.result.correctFirstTry)
        .length;
    final distinctTaskCount = matching
        .map((entry) => entry.result.taskId)
        .toSet()
        .length;
    var sessionCount = 0;
    for (final session in history) {
      if (session.taskResults.any(
        (result) => result.competencyId == competencyId,
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
    final lastPracticedAt = matching
        .map((entry) => entry.finishedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return GermanCompetencyProgress(
      competencyId: competencyId,
      attempts: matching.length,
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
