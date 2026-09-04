import 'package:flutter/foundation.dart';

import '../models/assessment.dart';
import '../models/error_diagnosis.dart';
import '../models/learner_profile.dart';
import '../models/learning_methods.dart';
import '../models/learning_path.dart';
import '../models/math_fact.dart';
import '../models/remediation_path.dart';
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
  List<DiagnosticAttempt> diagnostics = [];
  List<RemediationProgress> remediationProgress = [];
  List<LearnerProfile> profiles = [];
  String activeProfileId = 'default';
  MethodPreferences methodPreferences = const MethodPreferences();
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
    profiles = await storage.initializeProfiles();
    activeProfileId = storage.activeProfileId;
    final profile = profiles.firstWhere(
      (value) => value.id == activeProfileId,
      orElse: () => profiles.first,
    );
    gradeLevel = profile.gradeLevel;
    soundEnabled = await storage.soundEnabled();
    hapticEnabled = await storage.hapticEnabled();
    await _loadActiveProfileData();
    loaded = true;
    notifyListeners();
  }

  Future<void> _loadActiveProfileData() async {
    final pool = AdaptiveEngine.buildFactPool(maxValue: 100);
    final saved = await storage.loadFacts();
    facts = pool.map((fresh) => saved[fresh.key] ?? fresh).toList();
    history = await storage.loadHistory();
    diagnostics = await storage.loadDiagnostics();
    remediationProgress = await storage.loadRemediationProgress();
    numberRange =
        await storage.numberRange() ?? gradeLevel.recommendedRange;
    if (!availableRanges.contains(numberRange)) {
      numberRange = gradeLevel.recommendedRange;
      await storage.setNumberRange(numberRange);
    }
    methodPreferences = await storage.methodPreferences();
    unlockedBadges = await storage.rewardBadges();
    recoveredWeakFacts = await storage.recoveredWeakFacts();
    _pendingBadgeIds.clear();
    lastSessionNewBadges = const [];
    final discovered = <String>{};
    _evaluateAchievements(discovered);
    if (discovered.isNotEmpty) {
      await storage.setRewardBadges(unlockedBadges);
    }
  }

  LearnerProfile get activeProfile {
    if (profiles.isEmpty) {
      return LearnerProfile(
        id: activeProfileId,
        name: 'Lernprofil',
        gradeLevel: gradeLevel,
        createdAt: DateTime(2026, 1, 1),
      );
    }
    return profiles.firstWhere(
      (value) => value.id == activeProfileId,
      orElse: () => profiles.first,
    );
  }

  String get activeProfileName => activeProfile.name;

  bool get needsOnboarding => !activeProfile.onboardingComplete;

  Future<void> recordDiagnosticAttempt({
    required TrainingMode mode,
    required String taskKey,
    required int expected,
    required int actual,
    MathFact? fact,
  }) async {
    final pattern = ErrorClassifier.classify(
      mode: mode,
      taskKey: taskKey,
      expected: expected,
      actual: actual,
      fact: fact,
    );
    diagnostics.insert(
      0,
      DiagnosticAttempt(
        occurredAt: DateTime.now(),
        mode: mode,
        taskKey: taskKey,
        expected: expected,
        actual: actual,
        correct: actual == expected,
        gradeLevel: gradeLevel,
        numberRange: numberRange,
        pattern: pattern,
      ),
    );
    if (diagnostics.length > 500) {
      diagnostics = diagnostics.take(500).toList();
    }
    var becameStable = false;
    if (pattern != null) {
      becameStable = _updateRemediationRecovery(
        pattern,
        correct: actual == expected,
      );
      if (becameStable &&
          _unlockBadge('weak_spot', _pendingBadgeIds)) {
        await storage.setRewardBadges(unlockedBadges);
      }
    }
    notifyListeners();
    await storage.saveDiagnostics(diagnostics);
    await storage.saveRemediationProgress(remediationProgress);
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
        !h.isAssessment &&
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
    if (!history.any((entry) =>
        !entry.isAssessment && entry.mode == result.mode)) {
      value += 1;
    }
    if (_isMeaningfulProgress(result)) value += 1;
    if (_isCourageRound(result)) value += 1;
    return value.clamp(1, 5).toInt();
  }

  String rewardReasonForSession(TrainingSessionResult result) {
    final reasons = <String>[];
    if (!history.any((entry) =>
        !entry.isAssessment && entry.mode == result.mode)) {
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
            !entry.isAssessment &&
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
            !entry.isAssessment &&
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
          .where((entry) =>
              entry.gradeLevel == grade &&
              !entry.isAssessment &&
              entry.total > 0)
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
              entry.numberRange == range &&
              !entry.isAssessment &&
              entry.total > 0)
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
                !entry.isAssessment &&
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

  RemediationProgress? remediationProgressFor(ErrorPattern pattern) {
    for (final progress in remediationProgress) {
      if (progress.pattern == pattern &&
          progress.gradeLevel == gradeLevel &&
          progress.numberRange == numberRange) {
        return progress;
      }
    }
    return null;
  }

  RemediationStatus? remediationStatusFor(ErrorPattern pattern) {
    final progress = remediationProgressFor(pattern);
    if (progress != null) return progress.status;
    final recurring = diagnosticSummaries(recurringOnly: true)
        .any((summary) => summary.pattern == pattern);
    return recurring ? RemediationStatus.recurring : null;
  }

  DiagnosticSummary? remediationCandidate({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    for (final summary in diagnosticSummaries(recurringOnly: true)) {
      final progress = remediationProgressFor(summary.pattern);
      if (progress == null ||
          progress.status == RemediationStatus.recurring ||
          progress.status == RemediationStatus.inProgress) {
        return summary;
      }
      if (progress.status == RemediationStatus.improved &&
          progress.nextReviewAt != null &&
          !progress.nextReviewAt!.isAfter(currentTime)) {
        return summary;
      }
    }
    return null;
  }

  bool remediationReviewOnly(ErrorPattern pattern, {DateTime? now}) {
    final progress = remediationProgressFor(pattern);
    if (progress == null || progress.status != RemediationStatus.improved) {
      return false;
    }
    final currentTime = now ?? DateTime.now();
    return progress.nextReviewAt != null &&
        !progress.nextReviewAt!.isAfter(currentTime);
  }

  Future<void> startRemediation(
    ErrorPattern pattern, {
    bool reviewOnly = false,
  }) async {
    final existing = remediationProgressFor(pattern);
    if (reviewOnly && existing != null) {
      return;
    }
    final next = RemediationProgress(
      pattern: pattern,
      gradeLevel: gradeLevel,
      numberRange: numberRange,
      status: RemediationStatus.inProgress,
      startedAt: existing?.startedAt ?? DateTime.now(),
      completedAt: existing?.completedAt,
      nextReviewAt: existing?.nextReviewAt,
      checkCorrect: 0,
      checkTotal: 0,
      stabilityCorrect: reviewOnly ? existing?.stabilityCorrect ?? 0 : 0,
    );
    _replaceRemediation(next);
    notifyListeners();
    await storage.saveRemediationProgress(remediationProgress);
  }

  Future<RemediationProgress> completeRemediation(
    ErrorPattern pattern, {
    required int checkCorrect,
    required int checkTotal,
    bool reviewOnly = false,
  }) async {
    final existing = remediationProgressFor(pattern);
    final accuracy = checkTotal == 0 ? 0.0 : checkCorrect / checkTotal;
    final passed = accuracy >= 0.75;
    final now = DateTime.now();

    final status = reviewOnly && passed
        ? RemediationStatus.stable
        : passed
            ? RemediationStatus.improved
            : RemediationStatus.recurring;

    final next = RemediationProgress(
      pattern: pattern,
      gradeLevel: gradeLevel,
      numberRange: numberRange,
      status: status,
      startedAt: existing?.startedAt ?? now,
      completedAt: now,
      nextReviewAt: status == RemediationStatus.improved
          ? now.add(const Duration(days: 3))
          : null,
      checkCorrect: checkCorrect,
      checkTotal: checkTotal,
      stabilityCorrect:
          status == RemediationStatus.stable ? 3 : 0,
    );
    _replaceRemediation(next);
    if (status == RemediationStatus.stable) {
      if (_unlockBadge('weak_spot', _pendingBadgeIds)) {
        await storage.setRewardBadges(unlockedBadges);
      }
    }
    notifyListeners();
    await storage.saveRemediationProgress(remediationProgress);
    return next;
  }

  bool _updateRemediationRecovery(
    ErrorPattern pattern, {
    required bool correct,
  }) {
    final progress = remediationProgressFor(pattern);
    if (progress == null ||
        (progress.status != RemediationStatus.improved &&
            progress.status != RemediationStatus.stable)) {
      return false;
    }

    if (!correct) {
      _replaceRemediation(
        progress.copyWith(
          status: RemediationStatus.recurring,
          stabilityCorrect: 0,
        ),
      );
      return false;
    }

    if (progress.status == RemediationStatus.stable) return false;

    final stableCorrect = progress.stabilityCorrect + 1;
    final becameStable = stableCorrect >= 3;
    _replaceRemediation(
      progress.copyWith(
        status: becameStable
            ? RemediationStatus.stable
            : RemediationStatus.improved,
        stabilityCorrect: stableCorrect,
      ),
    );
    return becameStable;
  }

  void _replaceRemediation(RemediationProgress value) {
    remediationProgress = [
      value,
      ...remediationProgress.where(
        (entry) =>
            entry.pattern != value.pattern ||
            entry.gradeLevel != value.gradeLevel ||
            entry.numberRange != value.numberRange,
      ),
    ];
  }

  List<DiagnosticSummary> diagnosticSummaries({
    int maxAttempts = 120,
    bool recurringOnly = false,
  }) {
    final recent = diagnostics
        .where((entry) =>
            entry.gradeLevel == gradeLevel &&
            entry.numberRange == numberRange)
        .take(maxAttempts)
        .where(
          (entry) => !entry.correct && entry.pattern != null,
        );
    final grouped = <ErrorPattern, List<DiagnosticAttempt>>{};
    for (final entry in recent) {
      grouped.putIfAbsent(entry.pattern!, () => []).add(entry);
    }

    final summaries = grouped.entries
        .map(
          (entry) => DiagnosticSummary(
            pattern: entry.key,
            errors: entry.value.length,
            lastSeen: entry.value
                .map((value) => value.occurredAt)
                .reduce((a, b) => a.isAfter(b) ? a : b),
            modes: entry.value.map((value) => value.mode).toSet(),
          ),
        )
        .where((summary) => !recurringOnly || summary.isRecurring)
        .toList()
      ..sort((a, b) {
        final byErrors = b.errors.compareTo(a.errors);
        if (byErrors != 0) return byErrors;
        return b.lastSeen.compareTo(a.lastSeen);
      });
    return summaries;
  }

  DiagnosticSummary? topDiagnosticForMode(TrainingMode mode) {
    final grouped = <ErrorPattern, List<DiagnosticAttempt>>{};
    for (final entry in diagnostics
        .where((entry) =>
            entry.gradeLevel == gradeLevel &&
            entry.numberRange == numberRange &&
            entry.mode == mode &&
            !entry.correct &&
            entry.pattern != null)
        .take(80)) {
      grouped.putIfAbsent(entry.pattern!, () => []).add(entry);
    }
    if (grouped.isEmpty) return null;

    final summaries = grouped.entries
        .map(
          (entry) => DiagnosticSummary(
            pattern: entry.key,
            errors: entry.value.length,
            lastSeen: entry.value.first.occurredAt,
            modes: {mode},
          ),
        )
        .where((summary) => summary.isRecurring)
        .toList()
      ..sort((a, b) => b.errors.compareTo(a.errors));
    return summaries.isEmpty ? null : summaries.first;
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

  List<TrainingMode> learningModesForGrade(GradeLevel grade) {
    if (grade == GradeLevel.first) {
      return const [
        TrainingMode.practice,
        TrainingMode.minus,
        TrainingMode.numberFriends,
        TrainingMode.missingNumber,
        TrainingMode.neighbors,
        TrainingMode.doublesHalves,
        TrainingMode.sequences,
        TrainingMode.money,
        TrainingMode.clock,
        TrainingMode.geometry,
      ];
    }
    if (grade == GradeLevel.second) {
      return const [
        TrainingMode.practice,
        TrainingMode.minus,
        TrainingMode.multiply,
        TrainingMode.divide,
        TrainingMode.numberWall,
        TrainingMode.missingNumber,
        TrainingMode.placeValue,
        TrainingMode.doublesHalves,
        TrainingMode.sequences,
        TrainingMode.factFamilies,
        TrainingMode.wordProblems,
        TrainingMode.money,
        TrainingMode.clock,
        TrainingMode.measures,
        TrainingMode.geometry,
      ];
    }
    return [
      TrainingMode.multiply,
      TrainingMode.divide,
      TrainingMode.wordProblems,
      ...curriculumModesForGrade(grade),
    ];
  }

  CompetencyProgress competencyProgress(TrainingMode mode) {
    final sessions = history
        .where((entry) =>
            entry.gradeLevel == gradeLevel &&
            entry.mode == mode &&
            entry.total > 0)
        .take(8)
        .toList();
    final tasks = sessions.fold<int>(0, (sum, entry) => sum + entry.total);
    final correct =
        sessions.fold<int>(0, (sum, entry) => sum + entry.correctFirstTry);
    final accuracy = tasks == 0 ? 0.0 : correct / tasks;

    final practiceSessions =
        sessions.where((entry) => !entry.isAssessment).toList();
    final practiceTasks =
        practiceSessions.fold<int>(0, (sum, entry) => sum + entry.total);
    final practiceCorrect = practiceSessions.fold<int>(
      0,
      (sum, entry) => sum + entry.correctFirstTry,
    );
    final practiceAccuracy =
        practiceTasks == 0 ? 0.0 : practiceCorrect / practiceTasks;

    final assessmentSessions =
        sessions.where((entry) => entry.isAssessment).toList();
    final assessmentTasks =
        assessmentSessions.fold<int>(0, (sum, entry) => sum + entry.total);
    final assessmentCorrect = assessmentSessions.fold<int>(
      0,
      (sum, entry) => sum + entry.correctFirstTry,
    );
    final assessmentAccuracy =
        assessmentTasks == 0 ? 0.0 : assessmentCorrect / assessmentTasks;

    final state = tasks == 0
        ? CompetencyState.newSkill
        : practiceSessions.length >= 3 &&
                practiceTasks >= 15 &&
                practiceAccuracy >= 0.85
            ? CompetencyState.mastered
            : practiceTasks >= 8 && practiceAccuracy >= 0.78
                ? CompetencyState.secure
                : assessmentTasks >= 2 && assessmentAccuracy >= 1.0
                    ? CompetencyState.secure
                    : CompetencyState.learning;

    return CompetencyProgress(
      mode: mode,
      state: state,
      accuracy: accuracy,
      tasks: tasks,
    );
  }

  List<GuidedRoundSegment> buildMyRound() {
    var focus = recommendedMode();
    final warmUp = gradeLevel.index >= GradeLevel.third.index
        ? TrainingMode.mixed
        : TrainingMode.practice;
    if (focus == warmUp ||
        focus == TrainingMode.speed ||
        focus == TrainingMode.tempo ||
        focus == TrainingMode.blitz) {
      for (final candidate in learningModesForGrade(gradeLevel)) {
        if (candidate == warmUp) continue;
        final alreadyTried = history.any(
          (entry) =>
              entry.gradeLevel == gradeLevel && entry.mode == candidate,
        );
        if (!alreadyTried) {
          focus = candidate;
          break;
        }
      }
    }

    final transferCandidates = gradeLevel.index >= GradeLevel.third.index
        ? <TrainingMode>[
            TrainingMode.wordProblems,
            TrainingMode.dataCharts,
            TrainingMode.advancedMeasures,
            TrainingMode.perimeterArea,
            TrainingMode.probability,
          ]
        : <TrainingMode>[
            TrainingMode.wordProblems,
            TrainingMode.numberWall,
            TrainingMode.money,
            TrainingMode.geometry,
            TrainingMode.factFamilies,
          ];

    TrainingMode transfer = transferCandidates.first;
    var lowestScore = 2.0;
    for (final mode in transferCandidates) {
      if (mode == focus || mode == warmUp) continue;
      final progress = competencyProgress(mode);
      final score = progress.tasks == 0 ? -1.0 : progress.accuracy;
      if (score < lowestScore) {
        lowestScore = score;
        transfer = mode;
      }
    }

    return [
      GuidedRoundSegment(
        mode: warmUp,
        tasks: 3,
        reason: 'Mit vertrauten Grundlagen ruhig ankommen.',
      ),
      GuidedRoundSegment(
        mode: focus,
        tasks: 4,
        reason: 'Das ist heute das wichtigste Lernziel.',
      ),
      GuidedRoundSegment(
        mode: transfer,
        tasks: 3,
        reason: 'Zum Schluss Wissen in einem anderen Zusammenhang anwenden.',
      ),
    ];
  }

  ParentLearningInsight parentInsight() {
    final modes = learningModesForGrade(gradeLevel);
    final progress = modes.map(competencyProgress).toList();
    final attempted = progress.where((item) => item.tasks > 0).toList();

    CompetencyProgress? strongest;
    CompetencyProgress? weakest;
    for (final item in attempted) {
      if (strongest == null || item.accuracy > strongest.accuracy) {
        strongest = item;
      }
      if (weakest == null || item.accuracy < weakest.accuracy) {
        weakest = item;
      }
    }

    final focus = weakest ?? competencyProgress(recommendedMode());
    final good = strongest == null
        ? 'Noch nicht genug Daten – die ersten kurzen Runden bauen die Lernkarte auf.'
        : '${strongest.mode.title} klappt aktuell am sichersten '
            '(${(strongest.accuracy * 100).round()} % direkt richtig).';

    final focusText = focus.tasks == 0
        ? '${focus.mode.title} wurde noch nicht geübt und ist ein sinnvoller nächster Bereich.'
        : '${focus.mode.title} ist aktuell noch unsicher '
            '(${(focus.accuracy * 100).round()} % direkt richtig).';

    final diagnostic = topDiagnosticForMode(focus.mode);
    final diagnosticStatus = diagnostic == null
        ? null
        : remediationStatusFor(diagnostic.pattern);
    final diagnosticIsActive = diagnostic != null &&
        diagnosticStatus != RemediationStatus.improved &&
        diagnosticStatus != RemediationStatus.stable;
    final action = diagnosticIsActive
        ? '${diagnostic.pattern.label}: ${diagnostic.pattern.action}'
        : focus.tasks == 0
            ? 'Eine kurze Runde „${focus.mode.title}“ reicht als Einstieg.'
            : focus.accuracy < 0.70
                ? '3–5 Minuten gezielt „${focus.mode.title}“ üben und dabei den gewählten Schul-Rechenweg nutzen.'
                : 'Den Bereich in kurzen Abständen wiederholen, bis er über mehrere Runden stabil bleibt.';

    final notYet = focus.tasks > 0 && focus.accuracy < 0.75
        ? 'Noch nicht nötig: auf Tempo trainieren. Zuerst sollte der Rechenweg sicher werden.'
        : 'Tempo bleibt zweitrangig; als Nächstes zählt sichere Anwendung in unterschiedlichen Aufgaben.';

    return ParentLearningInsight(
      good: good,
      focus: focusText,
      action: action,
      notYet: notYet,
      trend: _weeklyTrendText(),
    );
  }

  String _weeklyTrendText() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    double accuracyBetween(DateTime start, DateTime end) {
      final sessions = history.where(
        (entry) =>
            !entry.isAssessment &&
            !entry.finishedAt.isBefore(start) &&
            entry.finishedAt.isBefore(end) &&
            entry.total > 0,
      );
      final total = sessions.fold<int>(0, (sum, entry) => sum + entry.total);
      final correct = sessions.fold<int>(
        0,
        (sum, entry) => sum + entry.correctFirstTry,
      );
      return total == 0 ? -1 : correct / total;
    }

    final recent = accuracyBetween(sevenDaysAgo, now.add(const Duration(days: 1)));
    final previous = accuracyBetween(fourteenDaysAgo, sevenDaysAgo);
    if (recent < 0) return 'Diese Woche liegen noch nicht genug Übungsdaten vor.';
    if (previous < 0) {
      return 'Diese Woche: ${(recent * 100).round()} % der Aufgaben direkt richtig.';
    }
    final delta = ((recent - previous) * 100).round();
    if (delta.abs() < 3) {
      return 'Die Sicherheit ist gegenüber der Vorwoche weitgehend stabil.';
    }
    return delta > 0
        ? 'Gegenüber der Vorwoche ist die Trefferquote um etwa $delta Prozentpunkte gestiegen.'
        : 'Die Trefferquote liegt etwa ${delta.abs()} Prozentpunkte unter der Vorwoche – kurze Wiederholungen sind sinnvoll.';
  }

  TrainingMode? _assessmentFocusFor(List<TrainingMode> modes) {
    TrainingMode? focus;
    var lowest = 2.0;
    for (final mode in modes) {
      final sessions = history
          .where((entry) =>
              entry.isAssessment &&
              entry.gradeLevel == gradeLevel &&
              entry.mode == mode &&
              entry.total > 0)
          .toList();
      if (sessions.isEmpty) continue;
      final total = sessions.fold<int>(0, (sum, entry) => sum + entry.total);
      final correct = sessions.fold<int>(
        0,
        (sum, entry) => sum + entry.correctFirstTry,
      );
      final accuracy = total == 0 ? 0.0 : correct / total;
      if (accuracy < lowest) {
        lowest = accuracy;
        focus = mode;
      }
    }
    return lowest < 0.80 ? focus : null;
  }

  TrainingMode _upperPrimaryRecommendation() {
    final modes = curriculumModesForGrade(gradeLevel);
    final assessmentFocus =
        _assessmentFocusFor(learningModesForGrade(gradeLevel));
    if (assessmentFocus != null) return assessmentFocus;

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
    final mode = recommendedMode();
    if (gradeLevel.index >= GradeLevel.third.index) {
      final accuracy = modeAccuracy(mode);
      if (accuracy == 0) {
        return 'Für ${gradeLevel.label} passt als Nächstes „${mode.title}“. '
            'Damit wird ein weiterer Lehrplanbereich erschlossen.';
      }
      return 'Im Bereich „${mode.title}“ liegt aktuell noch das größte '
          'Übungspotenzial. Eine kurze Runde dazu passt gut.';
    }
    if (mode != TrainingMode.practice &&
        mode != TrainingMode.minus &&
        mode != TrainingMode.speed &&
        mode != TrainingMode.tempo) {
      return 'Als nächster Lernschritt passt „${mode.title}“. '
          'Die Grundaufgaben bleiben dabei weiterhin in der Wiederholung.';
    }
    return engine.recommendation(facts, maxValue: maxValue);
  }

  TrainingMode recommendedMode() {
    final remediation = remediationCandidate();
    if (remediation != null && remediation.modes.isNotEmpty) {
      return remediation.modes.first;
    }

    if (gradeLevel.index >= GradeLevel.third.index) {
      return _upperPrimaryRecommendation();
    }

    final modes = learningModesForGrade(gradeLevel);
    final assessmentFocus = _assessmentFocusFor(modes);
    if (assessmentFocus != null) return assessmentFocus;

    final coreText = engine.recommendation(facts, maxValue: maxValue);
    if (coreText.contains('Minus-Runde')) return TrainingMode.minus;
    final untried = modes.where(
      (mode) => !history.any(
        (entry) => entry.gradeLevel == gradeLevel && entry.mode == mode,
      ),
    );
    if (history.length >= 2 && untried.isNotEmpty) return untried.first;

    if (coreText.contains('Schnell rechnen')) return TrainingMode.speed;
    if (coreText.contains('Rechencheck')) return TrainingMode.tempo;
    return TrainingMode.practice;
  }

  Future<void> setGradeLevel(GradeLevel value) async {
    final gradeChanged = value != gradeLevel;
    gradeLevel = value;
    numberRange = value.recommendedRange;

    if (gradeChanged) {
      history = history.where((entry) => !entry.isAssessment).toList();
      await storage.saveHistory(history);
    }

    if (profiles.isNotEmpty) {
      profiles = profiles
          .map(
            (profile) => profile.id == activeProfileId
                ? profile.copyWith(
                    gradeLevel: value,
                    clearAssessment: gradeChanged,
                  )
                : profile,
          )
          .toList();
      await storage.saveProfiles(profiles);
    }
    notifyListeners();
    await storage.setGradeLevel(value);
    await storage.setNumberRange(numberRange);
  }

  Future<void> createProfile({
    required String name,
    required GradeLevel grade,
  }) async {
    final cleanName = name.trim().isEmpty ? 'Lernprofil' : name.trim();
    final id = 'p_${DateTime.now().microsecondsSinceEpoch}';
    final profile = LearnerProfile(
      id: id,
      name: cleanName,
      gradeLevel: grade,
      createdAt: DateTime.now(),
      state: profiles.isEmpty
          ? GermanState.thuringia
          : activeProfile.state,
      onboardingComplete: false,
    );
    profiles = [...profiles, profile];
    await storage.saveProfiles(profiles);
    await switchProfile(id);
    await setGradeLevel(grade);
  }

  Future<void> renameActiveProfile(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || profiles.isEmpty) return;
    profiles = profiles
        .map(
          (profile) => profile.id == activeProfileId
              ? profile.copyWith(name: cleanName)
              : profile,
        )
        .toList();
    await storage.saveProfiles(profiles);
    notifyListeners();
  }

  Future<void> switchProfile(String id) async {
    if (id == activeProfileId && profiles.isNotEmpty) return;
    final matches = profiles.where((profile) => profile.id == id).toList();
    if (matches.isEmpty) return;
    activeProfileId = id;
    gradeLevel = matches.first.gradeLevel;
    await storage.setActiveProfileId(id);
    await _loadActiveProfileData();
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    if (profiles.length <= 1) return;
    final wasActive = id == activeProfileId;
    final remaining = profiles.where((profile) => profile.id != id).toList();
    profiles = remaining;
    await storage.saveProfiles(profiles);
    await storage.deleteProfileData(id);
    if (wasActive) {
      activeProfileId = remaining.first.id;
      gradeLevel = remaining.first.gradeLevel;
      await storage.setActiveProfileId(activeProfileId);
      await _loadActiveProfileData();
    }
    notifyListeners();
  }

  Future<void> setSubtractionStrategy(SubtractionStrategy value) async {
    methodPreferences = methodPreferences.copyWith(subtraction: value);
    notifyListeners();
    await storage.setMethodPreferences(methodPreferences);
  }

  Future<void> setMultiplicationStrategy(MultiplicationStrategy value) async {
    methodPreferences = methodPreferences.copyWith(multiplication: value);
    notifyListeners();
    await storage.setMethodPreferences(methodPreferences);
  }

  Future<void> setWrittenSubtractionStrategy(
    WrittenSubtractionStrategy value,
  ) async {
    methodPreferences =
        methodPreferences.copyWith(writtenSubtraction: value);
    notifyListeners();
    await storage.setMethodPreferences(methodPreferences);
  }

  Future<void> saveLearningStartSetup({
    required String name,
    required GradeLevel grade,
    required GermanState state,
    required MethodPreferences methods,
  }) async {
    final cleanName = name.trim().isEmpty ? 'Lernprofil' : name.trim();
    gradeLevel = grade;
    numberRange = grade.recommendedRange;
    methodPreferences = methods;

    profiles = profiles
        .map(
          (profile) => profile.id == activeProfileId
              ? profile.copyWith(
                  name: cleanName,
                  gradeLevel: grade,
                  state: state,
                )
              : profile,
        )
        .toList();

    await storage.saveProfiles(profiles);
    await storage.setGradeLevel(grade);
    await storage.setNumberRange(numberRange);
    await storage.setMethodPreferences(methodPreferences);
    notifyListeners();
  }

  Future<void> completeAssessment(
    List<AssessmentModeResult> results,
  ) async {
    final now = DateTime.now();
    history = history.where((entry) => !entry.isAssessment).toList();

    for (final result in results.reversed) {
      history.insert(
        0,
        TrainingSessionResult(
          mode: result.mode,
          startedAt: now,
          finishedAt: now,
          total: result.total,
          correctFirstTry: result.correct,
          incorrectAttempts: result.total - result.correct,
          plusCorrect: 0,
          plusTotal: 0,
          minusCorrect: 0,
          minusTotal: 0,
          averageResponseMs: 0,
          numberRange: numberRange,
          gradeLevel: gradeLevel,
          starsEarned: 0,
          isAssessment: true,
        ),
      );
    }

    if (history.length > 300) history = history.take(300).toList();
    _markOnboardingComplete(assessmentCompletedAt: now);
    await storage.saveHistory(history);
    await storage.saveProfiles(profiles);
    notifyListeners();
  }

  Future<void> completeOnboardingWithoutAssessment() async {
    _markOnboardingComplete();
    await storage.saveProfiles(profiles);
    notifyListeners();
  }

  void _markOnboardingComplete({DateTime? assessmentCompletedAt}) {
    profiles = profiles
        .map(
          (profile) => profile.id == activeProfileId
              ? profile.copyWith(
                  onboardingComplete: true,
                  assessmentCompletedAt: assessmentCompletedAt,
                )
              : profile,
        )
        .toList();
  }

  Future<void> setProfileState(GermanState value) async {
    if (profiles.isEmpty) return;
    profiles = profiles
        .map(
          (profile) => profile.id == activeProfileId
              ? profile.copyWith(state: value)
              : profile,
        )
        .toList();
    notifyListeners();
    await storage.saveProfiles(profiles);
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
    diagnostics = [];
    remediationProgress = [];
    unlockedBadges = <String>{};
    recoveredWeakFacts = <String>{};
    _pendingBadgeIds.clear();
    lastSessionNewBadges = const [];
    notifyListeners();
  }
}
