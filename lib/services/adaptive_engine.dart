import 'dart:math';

import '../models/math_fact.dart';
import '../models/training.dart';

class AdaptiveEngine {
  AdaptiveEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  static List<MathFact> buildFactPool() {
    final facts = <MathFact>[];
    for (var a = 0; a <= 10; a++) {
      for (var b = 0; b <= 10; b++) {
        if (a + b <= 10) {
          facts.add(MathFact(a: a, b: b, operation: MathOperation.plus));
        }
        if (a >= b) {
          facts.add(MathFact(a: a, b: b, operation: MathOperation.minus));
        }
      }
    }
    return facts;
  }

  static bool isValid(MathFact fact) =>
      fact.result >= 0 && fact.result <= 10 && fact.a >= 0 && fact.b >= 0;

  double minusTargetShare(Iterable<MathFact> facts) {
    final plus = facts.where((f) => !f.isMinus && f.attempts > 0).toList();
    final minus = facts.where((f) => f.isMinus && f.attempts > 0).toList();
    if (minus.isEmpty) return 0.65;

    double meanMastery(List<MathFact> values) => values.isEmpty
        ? 0.5
        : values.map((e) => e.masteryScore).reduce((a, b) => a + b) /
            values.length;

    final plusMastery = meanMastery(plus);
    final minusMastery = meanMastery(minus);
    final commonSecurity = min(plusMastery, minusMastery);
    final securityProgress =
        ((commonSecurity - 0.55) / 0.35).clamp(0.0, 1.0).toDouble();

    // Start around 65 % Minus. As both operations become secure, drift toward 50/50.
    final base = 0.65 - 0.15 * securityProgress;
    // If Minus lags behind Plus, temporarily push it as high as 75 %.
    final gapBoost = (plusMastery - minusMastery) * 0.35;
    return (base + gapBoost).clamp(0.50, 0.75).toDouble();
  }

  int progressionTier(Iterable<MathFact> facts) {
    final tried = facts.where((f) => f.attempts > 0).toList();
    if (tried.length < 12) return 1;
    final averageMastery = tried
            .map((f) => f.masteryScore)
            .fold<double>(0, (a, b) => a + b) /
        tried.length;
    if (averageMastery < 0.55) return 1;
    if (tried.length < 28 || averageMastery < 0.72) return 2;
    return 3;
  }

  int difficultyTier(MathFact fact) {
    if (fact.isMinus) {
      if (fact.b <= 2 && fact.a <= 6) return 1;
      if (fact.b <= 4 && fact.a <= 8) return 2;
      return 3;
    }
    if (fact.result <= 6) return 1;
    if (fact.result <= 8) return 2;
    return 3;
  }

  MathFact selectNext({
    required List<MathFact> facts,
    required TrainingMode mode,
    String? previousKey,
  }) {
    var candidates = facts.where(isValid).toList();
    if (mode == TrainingMode.minus) {
      candidates = candidates.where((f) => f.isMinus).toList();
    } else if (mode == TrainingMode.numberFriends) {
      candidates = candidates
          .where((f) =>
              f.operation == MathOperation.plus &&
              (f.result == 10 || f.result == 8 || f.result == 7))
          .toList();
    }

    if (mode == TrainingMode.practice ||
        mode == TrainingMode.minus ||
        mode == TrainingMode.speed ||
        mode == TrainingMode.blitz) {
      final tier = progressionTier(facts);
      final progressive =
          candidates.where((f) => difficultyTier(f) <= tier).toList();
      if (progressive.isNotEmpty) candidates = progressive;
    }

    if (candidates.length > 1 && previousKey != null) {
      final withoutPrevious =
          candidates.where((f) => f.key != previousKey).toList();
      if (withoutPrevious.isNotEmpty) candidates = withoutPrevious;
    }

    final minusShare = minusTargetShare(facts);
    if (mode == TrainingMode.practice ||
        mode == TrainingMode.speed ||
        mode == TrainingMode.blitz ||
        mode == TrainingMode.tempo) {
      final wantsMinus = _random.nextDouble() < minusShare;
      final opCandidates =
          candidates.where((f) => f.isMinus == wantsMinus).toList();
      if (opCandidates.isNotEmpty) candidates = opCandidates;
    }

    // Keep most of a training round achievable, but reserve roughly a quarter
    // for facts that are currently genuine weak spots.
    if (mode != TrainingMode.tempo && candidates.length > 4) {
      final challenges = candidates
          .where((f) => f.attempts > 0 && f.masteryScore < 0.55)
          .toList();
      final comfortable = candidates
          .where((f) => f.attempts == 0 || f.masteryScore >= 0.55)
          .toList();
      if (challenges.isNotEmpty && comfortable.isNotEmpty) {
        candidates = _random.nextDouble() < 0.25 ? challenges : comfortable;
      }
    }

    final weights = candidates.map(_weightFor).toList();
    final totalWeight = weights.fold<double>(0, (a, b) => a + b);
    var pick = _random.nextDouble() * totalWeight;
    for (var i = 0; i < candidates.length; i++) {
      pick -= weights[i];
      if (pick <= 0) return candidates[i];
    }
    return candidates.last;
  }

  double _weightFor(MathFact fact) {
    final masteryNeed = 1.15 + (1 - fact.masteryScore) * 4.2;
    final errorBoost = 1 + fact.incorrectAttempts * 0.32;
    final speedBoost = fact.averageResponseMs > 6500 ? 1.45 : 1.0;
    final helpBoost = 1 + fact.helpCount * 0.18;
    final unseenBoost = fact.attempts == 0 ? 1.55 : 1.0;
    final recencyBoost = fact.lastPracticed == null
        ? 1.25
        : DateTime.now().difference(fact.lastPracticed!).inHours > 12
            ? 1.18
            : 1.0;
    return masteryNeed * errorBoost * speedBoost * helpBoost * unseenBoost * recencyBoost;
  }

  String recommendation(Iterable<MathFact> facts) {
    final tried = facts.where((f) => f.attempts > 0).toList();
    if (tried.length < 8) {
      return 'Erst noch etwas ohne Zeitdruck üben. Die App braucht ein paar Antworten, um das Lernmuster sicher zu erkennen.';
    }
    final minus = tried.where((f) => f.isMinus).toList();
    final plus = tried.where((f) => !f.isMinus).toList();
    double mastery(List<MathFact> list) => list.isEmpty
        ? 0.5
        : list.map((e) => e.masteryScore).reduce((a, b) => a + b) /
            list.length;
    final minusM = mastery(minus);
    final plusM = mastery(plus);
    if (minusM + 0.12 < plusM || minusM < 0.58) {
      final hard = minus.toList()..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
      final labels = hard.take(3).map((e) => e.label).join(', ');
      return 'Minus ist momentan noch deutlich unsicherer. Als Nächstes passt Minus-Training${labels.isEmpty ? '' : ', besonders $labels'}.';
    }
    final avg = tried.map((e) => e.averageResponseMs).fold<double>(0, (a, b) => a + b) /
        tried.length;
    if (mastery(tried) > 0.76 && avg > 4500) {
      return 'Dein Kind rechnet schon ziemlich sicher. Jetzt lohnt sich eine kurze Runde „Schnell rechnen“.';
    }
    if (mastery(tried) > 0.78 && avg <= 4500) {
      return 'Sicherheit und Tempo sind gut genug für einen kurzen Tempotest.';
    }
    return 'Noch eine kurze sichere Übungsrunde ist aktuell sinnvoller als zusätzlicher Zeitdruck.';
  }
}
