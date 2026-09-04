import 'package:flutter/foundation.dart';

import '../models/math_fact.dart';
import '../models/reward_badge.dart';
import '../models/training.dart';
import 'adaptive_engine.dart';
import 'storage_service.dart';

class AppController extends ChangeNotifier {
  AppController({StorageService? storage, AdaptiveEngine? engine})
      : storage = storage ?? StorageService(),
        engine = engine ?? AdaptiveEngine();

  final StorageService storage;
  final AdaptiveEngine engine;
  List<MathFact> facts = [];
  List<TrainingSessionResult> history = [];
  bool soundEnabled = false;
  bool hapticEnabled = true;
  bool loaded = false;
  NumberRangeLevel numberRange = NumberRangeLevel.twenty;
  GradeLevel gradeLevel = GradeLevel.second;
  Set<String> unlockedBadges = <String>{};
  Set<String> recoveredWeakFacts = <String>{};
  final Set<String> _pendingBadgeIds = <String>{};
  List<RewardBadge> lastSessionNewBadges = const [];

  int get maxValue => numberRange.maxValue;

  Future<void> load() async {
    final pool = AdaptiveEngine.buildFactPool(maxValue: 100);
    final saved = await storage.loadFacts();
    facts = pool.map((fresh) => saved[fresh.key] ?? fresh).toList();
    history = await storage.loadHistory();
    soundEnabled = await storage.soundEnabled();
    hapticEnabled = await storage.hapticEnabled();
    numberRange = await storage.numberRange();
    gradeLevel = await storage.gradeLevel();
    if (!availableRanges.contains(numberRange)) {
      numberRange = gradeLevel.recommendedRange;
    }
    unlockedBadges = await storage.rewardBadges();
    recoveredWeakFacts = await storage.recoveredWeakFacts();
    final discovered = <String>{};
    _evaluateAchievements(discovered);
    if (discovered.isNotEmpty) {
      await storage.setRewardBadges(unlockedBadges);
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> recordAttempt(
    MathFact fact, {
    required bool correct,
    required Duration responseTime,
    required bool usedHelp,
  }) async {
    final hasWeakHistory = fact.attempts >= 2 &&
        (fact.masteryScore < 0.45 ||
            fact.incorrectAttempts >= 2 ||
            fact.helpCount >= 2 ||
            fact.accuracy < 0.60);
    fact.registerAttempt(
      correct: correct,
      responseTime: responseTime,
      usedHelp: usedHelp,
    );
    if (hasWeakHistory &&
        fact.masteryScore >= 0.72 &&
        recoveredWeakFacts.add(fact.key)) {
      if (_unlockBadge('weak_spot', _pendingBadgeIds)) {
        await storage.setRewardBadges(unlockedBadges);
      }
      await storage.setRecoveredWeakFacts(recoveredWeakFacts);
    }
    notifyListeners();
    await storage.saveFacts(facts);
  }

  Future<void> addSession(TrainingSessionResult result) async {
    history.insert(0, result);
    if (history.length > 300) history = history.take(300).toList();

    final newlyUnlocked = <String>{..._pendingBadgeIds};
    _pendingBadgeIds.clear();
    _evaluateAchievements(newlyUnlocked);
    lastSessionNewBadges = newlyUnlocked.map(RewardCatalog.fromId).toList()
      ..sort((a, b) => b.stars.compareTo(a.stars));

    notifyListeners();
    await storage.saveHistory(history);
    await storage.setRewardBadges(unlockedBadges);
    await storage.setRecoveredWeakFacts(recoveredWeakFacts);
  }

  Iterable<TrainingSessionResult> get todayHistory {
    final now = DateTime.now();
    return history.where((h) =>
        h.startedAt.year == now.year &&
        h.startedAt.month == now.month &&
        h.startedAt.day == now.day);
  }

  int get todayTasks => todayHistory.fold(0, (sum, e) => sum + e.total);

  int get badgeStars => unlockedBadges
      .map(RewardCatalog.fromId)
      .fold<int>(0, (sum, badge) => sum + badge.stars);

  int get stars =>
      history.fold<int>(0, (sum, e) => sum + e.starsEarned) + badgeStars;

  int get nextStarGoal => ((stars ~/ 10) + 1) * 10;

  List<RewardBadge> get badges => unlockedBadges
      .map(RewardCatalog.fromId)
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));

  int rewardStarsForSession(TrainingSessionResult result) {
    if (result.total == 0) return 0;
    var value = 1;
    if (result.total >= 5 && result.accuracy >= 0.80) value += 1;
    if (!history.any((entry) => entry.mode == result.mode)) value += 1;
    if (_isMeaningfulProgress(result)) value += 1;
    if (_isCourageRound(result)) value += 1;
    return value.clamp(1, 5).toInt();
  }

  String rewardReasonForSession(TrainingSessionResult result) {
    final reasons = <String>[];
    if (!history.any((entry) => entry.mode == result.mode)) {
      reasons.add('Neue Lernwelt entdeckt');
    }
    if (result.accuracy >= 0.80) reasons.add('sicher gerechnet');
    if (_isMeaningfulProgress(result)) reasons.add('deutlich verbessert');
    if (_isCourageRound(result)) reasons.add('trotz Knacknüssen drangeblieben');
    if (reasons.isEmpty) return 'Runde konzentriert abgeschlossen.';
    return '${reasons.join(' · ')}.';
  }

  bool _isMeaningfulProgress(TrainingSessionResult result) {
    final prior = history
        .where((entry) =>
            entry.mode == result.mode &&
            entry.numberRange == result.numberRange &&
            entry.gradeLevel == result.gradeLevel &&
            entry.total > 0)
        .take(3)
        .toList();
    if (prior.isEmpty || result.total < 5) return false;
    final priorAccuracy = prior
            .map((entry) => entry.accuracy)
            .fold<double>(0, (sum, value) => sum + value) /
        prior.length;
    return result.accuracy >= priorAccuracy + 0.10;
  }

  bool _isCourageRound(TrainingSessionResult result) =>
      result.total >= 5 &&
      result.incorrectAttempts >= 2 &&
      result.accuracy >= 0.60;

  bool _unlockBadge(String id, Set<String> newlyUnlocked) {
    if (!unlockedBadges.add(id)) return false;
    newlyUnlocked.add(id);
    return true;
  }

  void _evaluateAchievements(Set<String> newlyUnlocked) {
    final learningModes = history
        .where((entry) =>
            entry.total > 0 &&
            entry.mode != TrainingMode.speed &&
            entry.mode != TrainingMode.tempo &&
            entry.mode != TrainingMode.blitz)
        .map((entry) => entry.mode)
        .toSet();
    if (learningModes.length >= 5) {
      _unlockBadge('explorer', newlyUnlocked);
    }

    if (history.any(_isCourageRound)) {
      _unlockBadge('courage', newlyUnlocked);
    }

    for (final grade in GradeLevel.values) {
      final sessions = history
          .where((entry) => entry.gradeLevel == grade && entry.total > 0)
          .toList();
      final total = sessions.fold<int>(0, (sum, entry) => sum + entry.total);
      final correct = sessions.fold<int>(
          0, (sum, entry) => sum + entry.correctFirstTry);
      final distinctModes = sessions.map((entry) => entry.mode).toSet().length;
      final accuracy = total == 0 ? 0.0 : correct / total;
      final requiredModes = grade.index < GradeLevel.third.index ? 4 : 6;
      final requiredTasks = grade.index < GradeLevel.third.index ? 30 : 50;
      if (total >= requiredTasks &&
          distinctModes >= requiredModes &&
          accuracy >= 0.82) {
        _unlockBadge('grade:${grade.name}', newlyUnlocked);
      }
    }

    for (final range in NumberRangeLevel.values) {
      final sessions = history
          .where((entry) =>
              entry.numberRange == range && entry.total > 0)
          .toList();
      final total = sessions.fold<int>(0, (sum, entry) => sum + entry.total);
      final correct = sessions.fold<int>(
          0, (sum, entry) => sum + entry.correctFirstTry);
      final distinctModes = sessions.map((entry) => entry.mode).toSet().length;
      final accuracy = total == 0 ? 0.0 : correct / total;
      if (sessions.length >= 3 &&
          total >= 25 &&
          distinctModes >= 2 &&
          accuracy >= 0.85) {
        _unlockBadge('range:${range.name}', newlyUnlocked);
      }
    }

    for (final operation in MathOperation.values) {
      final tried = facts.where((fact) =>
          fact.operation == operation && fact.attempts > 0);
      final attempts = tried.fold<int>(0, (sum, fact) => sum + fact.attempts);
      final correct =
          tried.fold<int>(0, (sum, fact) => sum + fact.correctAttempts);
      final accuracy = attempts == 0 ? 0.0 : correct / attempts;
      if (attempts >= 20 && accuracy >= 0.85) {
        _unlockBadge('operation:${operation.name}', newlyUnlocked);
      }
    }

    for (final range in NumberRangeLevel.values) {
      for (final mode in TrainingMode.values) {
        if (mode == TrainingMode.speed ||
            mode == TrainingMode.tempo ||
            mode == TrainingMode.blitz) {
          continue;
        }
        final sessions = history
            .where((entry) =>
                entry.mode == mode &&
                entry.numberRange == range &&
                entry.total > 0)
            .take(3)
            .toList();
        if (sessions.length < 3) continue;
        final total =
            sessions.fold<int>(0, (sum, entry) => sum + entry.total);
        final correct = sessions.fold<int>(
            0, (sum, entry) => sum + entry.correctFirstTry);
        if (total >= 15 && correct / total >= 0.85) {
          _unlockBadge('mastery:${mode.name}:${range.name}', newlyUnlocked);
        }
      }
    }
  }

  double averageMsFor(MathOperation operation) {
    final tried = facts
        .where((f) =>
            f.operation == operation &&
            f.attempts > 0 &&
            AdaptiveEngine.isValid(f, maxValue: maxValue))
        .toList();
    if (tried.isEmpty) return 0;
    return tried.map((e) => e.averageResponseMs).reduce((a, b) => a + b) /
        tried.length;
  }

  double accuracyFor(MathOperation operation) {
    final tried = facts.where((f) =>
        f.operation == operation &&
        f.attempts > 0 &&
        AdaptiveEngine.isValid(f, maxValue: maxValue));
    final attempts = tried.fold<int>(0, (s, f) => s + f.attempts);
    final correct = tried.fold<int>(0, (s, f) => s + f.correctAttempts);
    return attempts == 0 ? 0 : correct / attempts;
  }

  double modeAccuracy(TrainingMode mode) {
    final sessions = history
        .where((h) =>
            h.mode == mode &&
            h.total > 0 &&
            h.numberRange == numberRange &&
            h.gradeLevel == gradeLevel)
        .take(12);
    final total = sessions.fold<int>(0, (sum, e) => sum + e.total);
    final correct =
        sessions.fold<int>(0, (sum, e) => sum + e.correctFirstTry);
    return total == 0 ? 0 : correct / total;
  }

  double gradeAccuracy(GradeLevel grade) {
    final sessions = history
        .where((h) => h.total > 0 && h.gradeLevel == grade)
        .take(50);
    final total = sessions.fold<int>(0, (sum, e) => sum + e.total);
    final correct =
        sessions.fold<int>(0, (sum, e) => sum + e.correctFirstTry);
    return total == 0 ? 0 : correct / total;
  }

  double rangeAccuracy(NumberRangeLevel range) {
    final sessions = history
        .where((h) =>
            h.total > 0 &&
            h.numberRange == range &&
            h.gradeLevel == gradeLevel)
        .take(30);
    final total = sessions.fold<int>(0, (sum, e) => sum + e.total);
    final correct =
        sessions.fold<int>(0, (sum, e) => sum + e.correctFirstTry);
    return total == 0 ? 0 : correct / total;
  }

  List<MathFact> hardest({int count = 5}) {
    final tried = facts
        .where((f) =>
            f.attempts > 0 && AdaptiveEngine.isValid(f, maxValue: maxValue))
        .toList()
      ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
    return tried.take(count).toList();
  }

  List<MathFact> safest({int count = 5}) {
    final tried = facts
        .where((f) =>
            f.attempts > 0 && AdaptiveEngine.isValid(f, maxValue: maxValue))
        .toList()
      ..sort((a, b) => b.masteryScore.compareTo(a.masteryScore));
    return tried.take(count).toList();
  }

  List<NumberRangeLevel> get availableRanges => switch (gradeLevel) {
        GradeLevel.first => const [
            NumberRangeLevel.ten,
            NumberRangeLevel.twenty,
          ],
        GradeLevel.second => const [
            NumberRangeLevel.ten,
            NumberRangeLevel.twenty,
            NumberRangeLevel.hundred,
          ],
        GradeLevel.third => const [
            NumberRangeLevel.ten,
            NumberRangeLevel.twenty,
            NumberRangeLevel.hundred,
            NumberRangeLevel.thousand,
            NumberRangeLevel.tenThousand,
          ],
        GradeLevel.fourth => NumberRangeLevel.values,
      };

  List<TrainingMode> curriculumModesForGrade(GradeLevel grade) {
    if (grade.index < GradeLevel.third.index) return const [];
    final common = <TrainingMode>[
      TrainingMode.largeNumbers,
      TrainingMode.rounding,
      TrainingMode.mentalStrategies,
      TrainingMode.writtenAddSub,
      TrainingMode.writtenMultiply,
      TrainingMode.writtenDivide,
      TrainingMode.estimation,
      TrainingMode.arithmeticLaws,
      TrainingMode.advancedMeasures,
      TrainingMode.timeDurations,
      TrainingMode.dataCharts,
      TrainingMode.probability,
      TrainingMode.combinatorics,
      TrainingMode.perimeterArea,
      TrainingMode.geometryBodies,
      TrainingMode.symmetry,
      TrainingMode.plansAndOrientation,
      TrainingMode.romanNumerals,
      TrainingMode.fractions,
      TrainingMode.proportionality,
      TrainingMode.volumeCubes,
    ];
    return common;
  }

  TrainingMode _upperPrimaryRecommendation() {
    final modes = curriculumModesForGrade(gradeLevel);
    for (final mode in modes) {
      final attempted = history.any(
        (entry) => entry.gradeLevel == gradeLevel && entry.mode == mode,
      );
      if (!attempted) return mode;
    }
    var best = modes.first;
    var lowest = 2.0;
    for (final mode in modes) {
      final sessions = history
          .where((entry) =>
              entry.gradeLevel == gradeLevel &&
              entry.mode == mode &&
              entry.total > 0)
          .take(5)
          .toList();
      if (sessions.isEmpty) return mode;
      final total = sessions.fold<int>(0, (sum, e) => sum + e.total);
      final correct =
          sessions.fold<int>(0, (sum, e) => sum + e.correctFirstTry);
      final accuracy = total == 0 ? 0.0 : correct / total;
      if (accuracy < lowest) {
        lowest = accuracy;
        best = mode;
      }
    }
    return best;
  }

  String recommendationText() {
    if (gradeLevel.index >= GradeLevel.third.index) {
      final mode = _upperPrimaryRecommendation();
      final accuracy = modeAccuracy(mode);
      if (accuracy == 0) {
        return 'Für ${gradeLevel.label} passt als Nächstes „${mode.title}“. '
            'Damit wird ein weiterer Lehrplanbereich erschlossen.';
      }
      return 'Im Bereich „${mode.title}“ liegt aktuell noch das größte '
          'Übungspotenzial. Eine kurze Runde dazu passt gut.';
    }
    return engine.recommendation(facts, maxValue: maxValue);
  }

  TrainingMode recommendedMode() {
    if (gradeLevel.index >= GradeLevel.third.index) {
      return _upperPrimaryRecommendation();
    }
    final text = engine.recommendation(facts, maxValue: maxValue);
    if (text.contains('Minus-Runde')) return TrainingMode.minus;
    if (text.contains('Schnell rechnen')) return TrainingMode.speed;
    if (text.contains('Rechencheck')) return TrainingMode.tempo;
    return TrainingMode.practice;
  }

  Future<void> setGradeLevel(GradeLevel value) async {
    gradeLevel = value;
    numberRange = value.recommendedRange;
    notifyListeners();
    await storage.setGradeLevel(value);
    await storage.setNumberRange(numberRange);
  }

  Future<void> setNumberRange(NumberRangeLevel value) async {
    numberRange = value;
    notifyListeners();
    await storage.setNumberRange(value);
  }

  Future<void> setSound(bool value) async {
    soundEnabled = value;
    notifyListeners();
    await storage.setSoundEnabled(value);
  }

  Future<void> setHaptic(bool value) async {
    hapticEnabled = value;
    notifyListeners();
    await storage.setHapticEnabled(value);
  }

  Future<void> resetProgress() async {
    await storage.clear();
    facts = AdaptiveEngine.buildFactPool(maxValue: 100);
    history = [];
    unlockedBadges = <String>{};
    recoveredWeakFacts = <String>{};
    _pendingBadgeIds.clear();
    lastSessionNewBadges = const [];
    notifyListeners();
  }
}
