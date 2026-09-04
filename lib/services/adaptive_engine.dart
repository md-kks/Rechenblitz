import 'dart:math';

import '../models/math_fact.dart';
import '../models/micro_competency.dart';
import '../models/training.dart';
import '../models/task_diversity.dart';

class AdaptiveEngine {
  AdaptiveEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  static List<MathFact> buildFactPool({int maxValue = 100}) {
    final facts = <MathFact>[];

    for (var a = 0; a <= maxValue; a++) {
      for (var b = 0; b <= maxValue; b++) {
        if (a + b <= maxValue) {
          facts.add(MathFact(a: a, b: b, operation: MathOperation.plus));
        }
        if (a >= b) {
          facts.add(MathFact(a: a, b: b, operation: MathOperation.minus));
        }
      }
    }

    for (var a = 0; a <= 10; a++) {
      for (var b = 0; b <= 10; b++) {
        final product = a * b;
        if (product <= maxValue) {
          facts.add(MathFact(a: a, b: b, operation: MathOperation.multiply));
        }
        if (b > 0 && product <= maxValue) {
          facts.add(MathFact(a: product, b: b, operation: MathOperation.divide));
        }
      }
    }

    final unique = <String, MathFact>{};
    for (final fact in facts) {
      unique[fact.key] = fact;
    }
    return unique.values.toList();
  }

  static bool isValid(MathFact fact, {int maxValue = 100}) {
    if (fact.a < 0 || fact.b < 0 || fact.result < 0 || fact.result > maxValue) {
      return false;
    }
    if (fact.operation == MathOperation.minus && fact.a < fact.b) return false;
    if (fact.operation == MathOperation.divide) {
      return fact.b > 0 && fact.a <= maxValue && fact.a % fact.b == 0;
    }
    if (fact.operation == MathOperation.plus) return fact.a + fact.b <= maxValue;
    if (fact.operation == MathOperation.multiply) return fact.a * fact.b <= maxValue;
    return fact.a <= maxValue && fact.b <= maxValue;
  }

  double minusTargetShare(Iterable<MathFact> facts) {
    final plus = facts
        .where((f) => f.operation == MathOperation.plus && f.attempts > 0)
        .toList();
    final minus = facts
        .where((f) => f.operation == MathOperation.minus && f.attempts > 0)
        .toList();
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
    final base = 0.65 - 0.15 * securityProgress;
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
    if (fact.operation == MathOperation.multiply ||
        fact.operation == MathOperation.divide) {
      final quotient = fact.operation == MathOperation.divide ? fact.result : 0;
      final smallFactor = fact.operation == MathOperation.multiply
          ? max(fact.a, fact.b)
          : max(fact.b, quotient);
      if (fact.a <= 10 && fact.result <= 10 && smallFactor <= 5) return 1;
      if (fact.a <= 20 &&
          (fact.operation == MathOperation.divide || fact.result <= 20)) {
        return 2;
      }
      return 3;
    }

    final largest = max(max(fact.a, fact.b), fact.result);
    if (largest <= 10) return 1;
    if (largest <= 20) return 2;
    return 3;
  }

  MathFact selectNext({
    required List<MathFact> facts,
    required TrainingMode mode,
    int maxValue = 10,
    String? previousKey,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
  }) {
    var candidates =
        facts.where((f) => isValid(f, maxValue: maxValue)).toList();

    candidates = switch (mode) {
      TrainingMode.minus =>
        candidates.where((f) => f.operation == MathOperation.minus).toList(),
      TrainingMode.multiply => candidates
          .where((f) => f.operation == MathOperation.multiply)
          .toList(),
      TrainingMode.divide =>
        candidates.where((f) => f.operation == MathOperation.divide).toList(),
      TrainingMode.numberFriends => candidates
          .where((f) =>
              f.operation == MathOperation.plus &&
              _numberFriendTargets(maxValue).contains(f.result))
          .toList(),
      TrainingMode.mixed => candidates,
      _ => candidates
          .where((f) =>
              f.operation == MathOperation.plus ||
              f.operation == MathOperation.minus)
          .toList(),
    };

    if (targetCompetency != null && candidates.length > 1) {
      final targeted = candidates.where((fact) {
        return MicroCompetencyCatalog.tagsForTask(
          mode: mode,
          taskKey: fact.key,
          fact: fact,
        ).any((tag) => tag.id == targetCompetency);
      }).toList();
      if (targeted.isNotEmpty) candidates = targeted;
    }

    if (mode == TrainingMode.practice ||
        mode == TrainingMode.minus ||
        mode == TrainingMode.speed ||
        mode == TrainingMode.blitz ||
        mode == TrainingMode.multiply ||
        mode == TrainingMode.divide ||
        mode == TrainingMode.mixed) {
      final rangeTier = maxValue <= 10
          ? 1
          : maxValue <= 20
              ? 2
              : 3;
      final tier = min(rangeTier, progressionTier(facts));
      final progressive =
          candidates.where((f) => difficultyTier(f) <= tier).toList();
      if (progressive.isNotEmpty) candidates = progressive;
    }

    final recent = recentKeys.toList();
    final exactWindow = TaskDiversity.recentExactWindow(
      mode: mode,
      maxValue: maxValue,
    );
    final exactAvoid = recent.take(exactWindow).toSet();

    if (candidates.length > 1 && previousKey != null) {
      exactAvoid.add(previousKey);
    }

    if (exactAvoid.isNotEmpty && candidates.length > 1) {
      final withoutRecent =
          candidates.where((fact) => !exactAvoid.contains(fact.key)).toList();
      if (withoutRecent.isNotEmpty) candidates = withoutRecent;
    }

    if (candidates.length > 4 && recent.isNotEmpty) {
      final familyWindow = TaskDiversity.recentFamilyWindow(mode);
      final familyAvoid = recent
          .take(familyWindow)
          .map((key) {
            final match = facts.where((fact) => fact.key == key);
            return match.isEmpty ? key : TaskDiversity.factFamily(match.first);
          })
          .toSet();
      final withoutRecentFamily = candidates
          .where((fact) => !familyAvoid.contains(TaskDiversity.factFamily(fact)))
          .toList();
      if (withoutRecentFamily.isNotEmpty) {
        candidates = withoutRecentFamily;
      }
    }

    if (mode == TrainingMode.practice ||
        mode == TrainingMode.speed ||
        mode == TrainingMode.blitz ||
        mode == TrainingMode.tempo) {
      final wantsMinus = _random.nextDouble() < minusTargetShare(facts);
      final opCandidates = candidates
          .where((f) =>
              f.operation ==
              (wantsMinus ? MathOperation.minus : MathOperation.plus))
          .toList();
      if (opCandidates.isNotEmpty) candidates = opCandidates;
    }

    if (mode == TrainingMode.mixed && maxValue >= 20) {
      final roll = _random.nextDouble();
      final operation = roll < 0.30
          ? MathOperation.plus
          : roll < 0.60
              ? MathOperation.minus
              : roll < 0.80
                  ? MathOperation.multiply
                  : MathOperation.divide;
      final opCandidates =
          candidates.where((f) => f.operation == operation).toList();
      if (opCandidates.isNotEmpty) candidates = opCandidates;
    }

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

    if (candidates.isEmpty) {
      throw StateError('Keine Aufgabe für $mode im Zahlenraum $maxValue.');
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

  static Set<int> _numberFriendTargets(int maxValue) {
    if (maxValue <= 10) return {7, 8, 10};
    if (maxValue <= 20) return {10, 15, 20};
    return {10, 20, 50, 100};
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
    return masteryNeed *
        errorBoost *
        speedBoost *
        helpBoost *
        unseenBoost *
        recencyBoost;
  }

  String recommendation(Iterable<MathFact> facts, {int maxValue = 10}) {
    final tried = facts
        .where((f) =>
            f.attempts > 0 &&
            (f.operation == MathOperation.plus ||
                f.operation == MathOperation.minus) &&
            isValid(f, maxValue: maxValue))
        .toList();
    if (tried.length < 8) {
      return 'Eine kurze Runde ohne Zeitdruck ist ein guter Einstieg. Danach kann Rechenblitz gezielter passende Aufgaben auswählen.';
    }

    final minus = tried.where((f) => f.isMinus).toList();
    final plus = tried.where((f) => f.isPlus).toList();
    double mastery(List<MathFact> list) => list.isEmpty
        ? 0.5
        : list.map((e) => e.masteryScore).reduce((a, b) => a + b) /
            list.length;
    final minusM = mastery(minus);
    final plusM = mastery(plus);
    if (minusM + 0.12 < plusM || minusM < 0.58) {
      final hard = minus.toList()
        ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
      final labels = hard.take(3).map((e) => e.label).join(', ');
      return 'Minus ist aktuell noch unsicherer. Eine Minus-Runde passt gut${labels.isEmpty ? '' : ', besonders zu $labels'}.';
    }

    final avg = tried
            .map((e) => e.averageResponseMs)
            .fold<double>(0, (a, b) => a + b) /
        tried.length;
    if (mastery(tried) > 0.76 && avg > 4500) {
      return 'Die Grundlagen sind schon recht sicher. Eine kurze Runde „Schnell rechnen“ kann die Automatisierung stärken.';
    }
    if (mastery(tried) > 0.78 && avg <= 4500) {
      return 'Sicherheit und Tempo passen gut zusammen. Ein kurzer Rechencheck ist jetzt sinnvoll.';
    }
    return 'Eine weitere sichere Übungsrunde ist aktuell sinnvoller als zusätzlicher Zeitdruck.';
  }
}
