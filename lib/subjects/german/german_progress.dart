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
    this.lastPracticedAt,
  });

  final GermanCompetencyId competencyId;
  final int attempts;
  final int correctFirstTry;
  final int incorrectAttempts;
  final double averageResponseMs;
  final DateTime? lastPracticedAt;

  double get accuracy => attempts == 0 ? 0 : correctFirstTry / attempts;

  GermanCompetencyState get state {
    if (attempts == 0) return GermanCompetencyState.newSkill;
    if (attempts >= 3 && accuracy >= 0.8) return GermanCompetencyState.secure;
    return GermanCompetencyState.learning;
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
      );
    }

    final correct = matching
        .where((entry) => entry.result.correctFirstTry)
        .length;
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
      lastPracticedAt: lastPracticedAt,
    );
  }
}
