import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/accessibility_preferences.dart';
import '../models/assessment.dart';
import '../models/beta_feedback.dart';
import '../models/error_diagnosis.dart';
import '../models/learner_profile.dart';
import '../models/learning_methods.dart';
import '../models/learning_path.dart';
import '../models/math_fact.dart';
import '../models/micro_competency.dart';
import '../models/remediation_path.dart';
import '../models/reward_badge.dart';
import '../models/training.dart';
import '../models/task_diversity.dart';
import '../models/teacher_assignment.dart';
import 'adaptive_engine.dart';
import 'speech_service.dart';
import 'storage_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    StorageService? storage,
    AdaptiveEngine? engine,
    SpeechService? speech,
  })  : storage = storage ?? StorageService(),
        engine = engine ?? AdaptiveEngine(),
        speech = speech ?? SpeechService();

  final StorageService storage;
  final AdaptiveEngine engine;
  final SpeechService speech;
  List<MathFact> facts = [];
  List<TrainingSessionResult> history = [];
  List<DiagnosticAttempt> diagnostics = [];
  List<RemediationProgress> remediationProgress = [];
  List<MicroCompetencyObservation> microObservations = [];
  Map<String, List<String>> recentTaskKeysByMode = <String, List<String>>{};
  List<LearnerProfile> profiles = [];
  String activeProfileId = 'default';
  MethodPreferences methodPreferences = const MethodPreferences();
  AccessibilityPreferences accessibilityPreferences =
      const AccessibilityPreferences();
  TeacherAssignment? activeTeacherAssignment;
  List<BetaFeedbackEntry> betaFeedbackEntries = [];
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

  GradeLevel get effectiveGradeLevel =>
      activeTeacherAssignment?.gradeLevel ?? gradeLevel;

  NumberRangeLevel get effectiveNumberRange =>
      activeTeacherAssignment?.numberRange ?? numberRange;

  MethodPreferences get effectiveMethodPreferences =>
      activeTeacherAssignment?.methods ?? methodPreferences;

  int get effectiveMaxValue => effectiveNumberRange.maxValue;

  bool get hasTeacherAssignment => activeTeacherAssignment != null;

  void beginTeacherAssignment(TeacherAssignment assignment) {
    activeTeacherAssignment = assignment;
    notifyListeners();
  }

  void endTeacherAssignment() {
    activeTeacherAssignment = null;
    notifyListeners();
  }



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
    accessibilityPreferences = await storage.accessibilityPreferences();
    betaFeedbackEntries = await storage.betaFeedback();
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
    microObservations = await storage.loadMicroCompetencyObservations();
    recentTaskKeysByMode = await storage.loadTaskDiversity();
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

  List<String> recentTaskKeys(
    TrainingMode mode, {
    int? count,
  }) {
    final values = recentTaskKeysByMode[mode.name] ?? const <String>[];
    if (count == null || values.length <= count) return List<String>.from(values);
    return values.take(count).toList();
  }

  Set<String> recentTaskFamilies(
    TrainingMode mode, {
    int? count,
  }) {
    final window = count ?? TaskDiversity.recentFamilyWindow(mode);
    return recentTaskKeys(mode, count: window)
        .map(TaskDiversity.familyForKey)
        .toSet();
  }

  Future<void> rememberPresentedTask(
    TrainingMode mode,
    String key,
  ) async {
    final current = List<String>.from(
      recentTaskKeysByMode[mode.name] ?? const <String>[],
    );
    current.remove(key);
    current.insert(0, key);
    if (current.length > 40) current.removeRange(40, current.length);
    recentTaskKeysByMode = {
      ...recentTaskKeysByMode,
      mode.name: current,
    };
    await storage.saveTaskDiversity(recentTaskKeysByMode);
  }

  TaskDiversityAudit diversityAuditFor(TrainingMode mode) {
    return TaskDiversityAudit.analyze(
      recentTaskKeysByMode[mode.name] ?? const <String>[],
    );
  }

  Future<void> recordDiagnosticAttempt({
    required TrainingMode mode,
    required String taskKey,
    required int expected,
    required int actual,
    MathFact? fact,
    bool usedHelp = false,
    int helpLevel = 0,
    String? methodKey,
    MicroEvidenceSource source = MicroEvidenceSource.practice,
  }) async {
    final pattern = ErrorClassifier.classify(
      mode: mode,
      taskKey: taskKey,
      expected: expected,
      actual: actual,
      fact: fact,
    );
    _recordMicroCompetencies(
      mode: mode,
      taskKey: taskKey,
      correct: actual == expected,
      fact: fact,
      usedHelp: usedHelp || helpLevel > 0,
      helpLevel: helpLevel,
      methodKey: methodKey,
      source: source,
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
        gradeLevel: effectiveGradeLevel,
        numberRange: effectiveNumberRange,
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
    await storage.saveMicroCompetencyObservations(microObservations);
  }

  Future<void> recordMicroSupportResolution({
    required TrainingMode mode,
    required String taskKey,
    MathFact? fact,
    required int helpLevel,
    required String? methodKey,
    MicroEvidenceSource source = MicroEvidenceSource.practice,
  }) async {
    if (helpLevel <= 0) return;
    _recordMicroCompetencies(
      mode: mode,
      taskKey: taskKey,
      correct: true,
      fact: fact,
      usedHelp: true,
      helpLevel: helpLevel,
      methodKey: methodKey,
      source: source,
    );
    notifyListeners();
    await storage.saveMicroCompetencyObservations(microObservations);
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
      TrainingMode.geometryRelations,
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

  void _recordMicroCompetencies({
    required TrainingMode mode,
    required String taskKey,
    required bool correct,
    required bool usedHelp,
    required int helpLevel,
    required String? methodKey,
    required MicroEvidenceSource source,
    MathFact? fact,
  }) {
    final sourceWeight = switch (source) {
      MicroEvidenceSource.remediation => 0.65,
      MicroEvidenceSource.practice ||
      MicroEvidenceSource.review ||
      MicroEvidenceSource.transfer => 1.0,
    };
    final helpWeight = !correct
        ? 1.0
        : switch (helpLevel) {
            >= 3 => 0.50,
            2 => 0.65,
            1 => 0.80,
            _ => usedHelp ? 0.80 : 1.0,
          };
    final now = DateTime.now();

    final observations = MicroCompetencyCatalog.tagsForTask(
      mode: mode,
      taskKey: taskKey,
      fact: fact,
    )
        .map(
          (tag) => MicroCompetencyObservation(
            id: tag.id,
            occurredAt: now,
            correct: correct,
            evidenceWeight: tag.weight * sourceWeight * helpWeight,
            source: source,
            usedHelp: usedHelp,
            helpLevel: helpLevel,
            methodKey: methodKey,
            mode: mode,
            gradeLevel: gradeLevel,
            numberRange: numberRange,
            taskKey: taskKey,
          ),
        )
        .toList();
    microObservations.insertAll(0, observations);

    if (microObservations.length > 1200) {
      microObservations = microObservations.take(1200).toList();
    }
  }

  MicroCompetencyProgress microCompetencyProgress(
    MicroCompetencyId id,
  ) {
    final definition = MicroCompetencyCatalog.definition(id);
    final observations = microObservations
        .where(
          (entry) =>
              entry.id == id &&
              entry.gradeLevel == gradeLevel &&
              entry.numberRange == numberRange,
        )
        .take(24)
        .toList();

    if (observations.isEmpty) {
      return MicroCompetencyProgress(
        definition: definition,
        state: MicroCompetencyState.newSkill,
        accuracy: 0,
        evidence: 0,
        observations: 0,
      );
    }

    var evidence = 0.0;
    var correctEvidence = 0.0;
    var baseEvidence = 0.0;
    var baseCorrectEvidence = 0.0;
    var independentEvidence = 0.0;
    var independentCorrectEvidence = 0.0;
    var aidedEvidence = 0.0;
    var aidedObservations = 0;
    var reviewEvidence = 0.0;
    var reviewCorrectEvidence = 0.0;
    var reviewIndependentEvidence = 0.0;
    var reviewIndependentCorrectEvidence = 0.0;
    var reviewObservations = 0;
    var transferEvidence = 0.0;
    var transferCorrectEvidence = 0.0;
    var transferIndependentEvidence = 0.0;
    var transferIndependentCorrectEvidence = 0.0;
    var transferObservations = 0;
    DateTime? lastReviewSeen;
    DateTime? lastTransferSeen;

    for (final observation in observations) {
      evidence += observation.evidenceWeight;
      if (observation.correct) {
        correctEvidence += observation.evidenceWeight;
      }
      if (observation.usedHelp) {
        aidedEvidence += observation.evidenceWeight;
        aidedObservations += 1;
      }

      switch (observation.source) {
        case MicroEvidenceSource.review:
          reviewEvidence += observation.evidenceWeight;
          reviewObservations += 1;
          if (observation.correct) {
            reviewCorrectEvidence += observation.evidenceWeight;
          }
          if (!observation.usedHelp) {
            reviewIndependentEvidence += observation.evidenceWeight;
            if (observation.correct) {
              reviewIndependentCorrectEvidence += observation.evidenceWeight;
            }
          }
          lastReviewSeen ??= observation.occurredAt;
          break;
        case MicroEvidenceSource.transfer:
          transferEvidence += observation.evidenceWeight;
          transferObservations += 1;
          if (observation.correct) {
            transferCorrectEvidence += observation.evidenceWeight;
          }
          if (!observation.usedHelp) {
            transferIndependentEvidence += observation.evidenceWeight;
            if (observation.correct) {
              transferIndependentCorrectEvidence +=
                  observation.evidenceWeight;
            }
          }
          lastTransferSeen ??= observation.occurredAt;
          break;
        case MicroEvidenceSource.practice:
        case MicroEvidenceSource.remediation:
          baseEvidence += observation.evidenceWeight;
          if (observation.correct) {
            baseCorrectEvidence += observation.evidenceWeight;
          }
          if (!observation.usedHelp) {
            independentEvidence += observation.evidenceWeight;
            if (observation.correct) {
              independentCorrectEvidence += observation.evidenceWeight;
            }
          }
          break;
      }
    }

    final accuracy = evidence == 0 ? 0.0 : correctEvidence / evidence;
    final baseAccuracy =
        baseEvidence == 0 ? 0.0 : baseCorrectEvidence / baseEvidence;
    final independentAccuracy = independentEvidence == 0
        ? 0.0
        : independentCorrectEvidence / independentEvidence;
    final reviewAccuracy =
        reviewEvidence == 0 ? 0.0 : reviewCorrectEvidence / reviewEvidence;
    final reviewIndependentAccuracy = reviewIndependentEvidence == 0
        ? 0.0
        : reviewIndependentCorrectEvidence / reviewIndependentEvidence;
    final transferAccuracy = transferEvidence == 0
        ? 0.0
        : transferCorrectEvidence / transferEvidence;
    final transferIndependentAccuracy = transferIndependentEvidence == 0
        ? 0.0
        : transferIndependentCorrectEvidence / transferIndependentEvidence;

    final state = evidence < 1.5
        ? MicroCompetencyState.discovering
        : independentEvidence >= 6 &&
                independentAccuracy >= 0.88 &&
                reviewIndependentEvidence >= 1.5 &&
                reviewIndependentAccuracy >= 0.80 &&
                transferIndependentEvidence >= 1.5 &&
                transferIndependentAccuracy >= 0.80
            ? MicroCompetencyState.mastered
            : independentEvidence >= 4 && independentAccuracy >= 0.80
                ? MicroCompetencyState.secure
                : MicroCompetencyState.practicing;

    return MicroCompetencyProgress(
      definition: definition,
      state: state,
      accuracy: accuracy,
      evidence: evidence,
      observations: observations.length,
      baseAccuracy: baseAccuracy,
      independentAccuracy: independentAccuracy,
      reviewAccuracy: reviewAccuracy,
      reviewIndependentAccuracy: reviewIndependentAccuracy,
      transferAccuracy: transferAccuracy,
      transferIndependentAccuracy: transferIndependentAccuracy,
      baseEvidence: baseEvidence,
      independentEvidence: independentEvidence,
      aidedEvidence: aidedEvidence,
      reviewEvidence: reviewEvidence,
      reviewIndependentEvidence: reviewIndependentEvidence,
      transferEvidence: transferEvidence,
      transferIndependentEvidence: transferIndependentEvidence,
      aidedObservations: aidedObservations,
      reviewObservations: reviewObservations,
      transferObservations: transferObservations,
      lastSeen: observations.first.occurredAt,
      lastReviewSeen: lastReviewSeen,
      lastTransferSeen: lastTransferSeen,
    );
  }

  List<MicroCompetencyProgress> microCompetenciesForGrade() =>
      MicroCompetencyCatalog.forGrade(gradeLevel)
          .map((definition) => microCompetencyProgress(definition.id))
          .toList();

  List<MicroCompetencyProgress> microCompetenciesForMode(
    TrainingMode mode,
  ) =>
      MicroCompetencyCatalog.forGrade(gradeLevel)
          .where((definition) => definition.preferredMode == mode)
          .map((definition) => microCompetencyProgress(definition.id))
          .toList();

  MicroCompetencyProgress? currentMicroFocus() {
    final candidates = microCompetenciesForGrade()
        .where(
          (progress) =>
              progress.observations > 0 &&
              progress.state != MicroCompetencyState.secure &&
              progress.state != MicroCompetencyState.mastered,
        )
        .toList()
      ..sort((a, b) {
        final accuracyOrder =
            a.independentAccuracy.compareTo(b.independentAccuracy);
        if (accuracyOrder != 0) return accuracyOrder;
        return b.independentEvidence.compareTo(a.independentEvidence);
      });

    if (candidates.isEmpty) return null;
    final candidate = candidates.first;

    for (final prerequisite in candidate.definition.prerequisites) {
      final prerequisiteProgress = microCompetencyProgress(prerequisite);
      if (prerequisiteProgress.observations > 0 &&
          prerequisiteProgress.state != MicroCompetencyState.secure &&
          prerequisiteProgress.state != MicroCompetencyState.mastered) {
        return prerequisiteProgress;
      }
    }
    return candidate;
  }

  MicroCompetencyProgress? strongestMicroCompetency() {
    final candidates = microCompetenciesForGrade()
        .where((progress) => progress.observations > 0)
        .toList()
      ..sort((a, b) {
        final stateOrder = b.state.index.compareTo(a.state.index);
        if (stateOrder != 0) return stateOrder;
        final accuracyOrder =
            b.independentAccuracy.compareTo(a.independentAccuracy);
        if (accuracyOrder != 0) return accuracyOrder;
        return b.independentEvidence.compareTo(a.independentEvidence);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  MicroCompetencyProgress? dueReviewMicroCompetency({
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final secure = microCompetenciesForGrade()
        .where(
          (progress) {
            if (progress.lastSeen == null ||
                (progress.state != MicroCompetencyState.secure &&
                    progress.state != MicroCompetencyState.mastered)) {
              return false;
            }
            final hasStableDelayedEvidence =
                progress.reviewIndependentEvidence >= 1.5 &&
                    progress.reviewIndependentAccuracy >= 0.80;
            final requiredGap = hasStableDelayedEvidence
                ? const Duration(days: 7)
                : const Duration(days: 2);
            return reference.difference(progress.lastSeen!) >= requiredGap;
          },
        )
        .toList()
      ..sort((a, b) => a.lastSeen!.compareTo(b.lastSeen!));
    return secure.isEmpty ? null : secure.first;
  }

  MicroCompetencyProgress? transferCandidateMicroCompetency({
    MicroCompetencyId? excluding,
  }) {
    final candidates = microCompetenciesForGrade()
        .where(
          (progress) =>
              progress.definition.id != excluding &&
              (progress.state == MicroCompetencyState.secure ||
                  progress.state == MicroCompetencyState.mastered),
        )
        .toList()
      ..sort((a, b) {
        final evidenceOrder = a.transferIndependentEvidence
            .compareTo(b.transferIndependentEvidence);
        if (evidenceOrder != 0) return evidenceOrder;
        final accuracyOrder = a.transferIndependentAccuracy
            .compareTo(b.transferIndependentAccuracy);
        if (accuracyOrder != 0) return accuracyOrder;
        if (a.lastTransferSeen == null && b.lastTransferSeen != null) {
          return -1;
        }
        if (a.lastTransferSeen != null && b.lastTransferSeen == null) {
          return 1;
        }
        if (a.lastTransferSeen != null && b.lastTransferSeen != null) {
          final ageOrder =
              a.lastTransferSeen!.compareTo(b.lastTransferSeen!);
          if (ageOrder != 0) return ageOrder;
        }
        return b.baseEvidence.compareTo(a.baseEvidence);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  TrainingMode transferModeFor(MicroCompetencyId id) {
    const contextualArithmetic = {
      MicroCompetencyId.additionNoBridge,
      MicroCompetencyId.additionTenBridge,
      MicroCompetencyId.subtractionNoBridge,
      MicroCompetencyId.subtractionTenBridge,
      MicroCompetencyId.multiplicationGroups,
      MicroCompetencyId.multiplicationFacts,
      MicroCompetencyId.divisionSharing,
      MicroCompetencyId.divisionFacts,
    };
    if (contextualArithmetic.contains(id)) {
      return TrainingMode.wordProblems;
    }
    return MicroCompetencyCatalog.definition(id).preferredMode;
  }

  MicroCompetencyProgress? nextNewMicroCompetency() {
    final preferred = recommendedMode();
    for (final definition in MicroCompetencyCatalog.forGrade(gradeLevel)) {
      final progress = microCompetencyProgress(definition.id);
      if (progress.state == MicroCompetencyState.newSkill &&
          definition.preferredMode == preferred) {
        return progress;
      }
    }
    for (final definition in MicroCompetencyCatalog.forGrade(gradeLevel)) {
      final progress = microCompetencyProgress(definition.id);
      if (progress.state == MicroCompetencyState.newSkill) return progress;
    }
    return null;
  }

  String microFocusReason() {
    final focus = currentMicroFocus();
    if (focus == null) {
      return 'Noch keine einzelne Teilkompetenz ist klar auffällig. '
          'Weitere abwechslungsreiche Aufgaben machen die Lernkarte genauer.';
    }
    final percentage = (focus.independentAccuracy * 100).round();
    return '„${focus.definition.label}“ ist aktuell der sinnvollste '
        'Teilschritt: ${focus.observations} passende Beobachtungen, '
        '$percentage % selbstständig richtig.';
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

  List<GuidedRoundSegment> buildMyRound({
    DateTime? now,
  }) {
    final microFocus = currentMicroFocus();
    final strongMicro = strongestMicroCompetency();
    final reviewMicro = dueReviewMicroCompetency(now: now);
    final transferMicro = transferCandidateMicroCompetency(
      excluding: reviewMicro?.definition.id,
    );
    final newMicro = nextNewMicroCompetency();

    var focus =
        microFocus?.definition.preferredMode ?? recommendedMode();
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

    final reviewTarget = reviewMicro?.definition.id;
    final transferTarget = transferMicro?.definition.id;
    final strongTarget = strongMicro?.definition.id;
    final warmUpTarget =
        strongTarget == transferTarget || strongTarget == reviewTarget
            ? null
            : strongTarget;
    final discoveryTarget =
        transferTarget == null ? newMicro?.definition.id : null;

    return [
      GuidedRoundSegment(
        mode: warmUpTarget == null
            ? warmUp
            : strongMicro!.definition.preferredMode,
        tasks: 2,
        reason: warmUpTarget == null
            ? 'Mit vertrauten Grundlagen ruhig ankommen.'
            : 'Mit einem bereits sicheren Lernschritt ruhig ankommen.',
        targetCompetency: warmUpTarget,
      ),
      GuidedRoundSegment(
        mode: focus,
        tasks: 5,
        reason: microFocus == null
            ? 'Das ist heute das wichtigste Lernziel.'
            : 'Heute üben wir gezielt: ${microFocus.definition.label}.',
        targetCompetency: microFocus?.definition.id,
      ),
      GuidedRoundSegment(
        mode: reviewTarget == null
            ? warmUp
            : reviewMicro!.definition.preferredMode,
        tasks: 3,
        reason: reviewTarget == null
            ? 'Eine wichtige Grundlage wird wiederholt.'
            : 'Dieser sichere Lernschritt wird nach zeitlichem Abstand erneut geprüft.',
        targetCompetency: reviewTarget,
        reviewEmphasis: reviewTarget != null,
      ),
      GuidedRoundSegment(
        mode: transferTarget != null
            ? transferModeFor(transferTarget)
            : discoveryTarget != null
                ? newMicro!.definition.preferredMode
                : transfer,
        tasks: 2,
        reason: transferTarget != null
            ? 'Zum Schluss „${transferMicro!.definition.label}“ in einer veränderten Aufgabe anwenden.'
            : discoveryTarget != null
                ? 'Zum Schluss einen neuen Lernschritt vorsichtig entdecken.'
                : 'Zum Schluss mit einer anderen Aufgabenart abwechslungsreich üben.',
        targetCompetency: transferTarget ?? discoveryTarget,
        transferEmphasis: transferTarget != null,
      ),
    ];
  }

  MicroCompetencyProgress? parentPriorityMicroCompetency({
    DateTime? now,
  }) {
    final focus = currentMicroFocus();
    if (focus != null) return focus;

    final review = dueReviewMicroCompetency(now: now);
    if (review != null) return review;

    final transfer = transferCandidateMicroCompetency(
      excluding: review?.definition.id,
    );
    if (transfer != null) return transfer;

    return nextNewMicroCompetency() ?? strongestMicroCompetency();
  }

  String _masteryMissingText(MicroCompetencyProgress progress) {
    final missing = <String>[];
    if (progress.independentEvidence < 4) {
      missing.add('mehr selbstständige Lösungen');
    } else if (progress.independentAccuracy < 0.80) {
      missing.add('eine stabilere selbstständige Trefferquote');
    } else {
      if (progress.independentEvidence < 6 ||
          progress.independentAccuracy < 0.88) {
        missing.add('eine noch stärkere selbstständige Basis');
      }
      if (progress.reviewIndependentEvidence < 1.5 ||
          progress.reviewIndependentAccuracy < 0.80) {
        missing.add('ein stabiler Nachweis nach zeitlichem Abstand');
      }
      if (progress.transferIndependentEvidence < 1.5 ||
          progress.transferIndependentAccuracy < 0.80) {
        missing.add('ein stabiler selbstständiger Transfer');
      }
    }
    if (missing.isEmpty) return 'kein weiterer Mastery-Nachweis';
    if (missing.length == 1) return missing.first;
    return '${missing.take(missing.length - 1).join(', ')} und ${missing.last}';
  }

  String _parentMasteryText(MicroCompetencyProgress progress) {
    final label = progress.definition.label;
    return switch (progress.state) {
      MicroCompetencyState.newSkill =>
        '„$label“ ist noch neu. Für eine belastbare Einschätzung fehlen noch passende Aufgabenbeobachtungen.',
      MicroCompetencyState.discovering =>
        '„$label“ wird gerade erst eingeordnet. Einzelne Lösungen reichen noch nicht für „Sicher“.',
      MicroCompetencyState.practicing =>
        '„$label“ wird noch geübt. Für „Sicher“ fehlt ${_masteryMissingText(progress)}.',
      MicroCompetencyState.secure =>
        '„$label“ ist „Sicher“: die Kompetenz gelingt in den bisherigen Aufgaben ausreichend selbstständig. Für „Gemeistert“ fehlt noch ${_masteryMissingText(progress)}.',
      MicroCompetencyState.mastered =>
        '„$label“ ist „Gemeistert“: selbstständige Basis, erneutes Können nach Abstand und selbstständiger Transfer sind im aktuellen Zahlenraum belegt.',
    };
  }

  String _parentEvidenceText(MicroCompetencyProgress progress) {
    final relevant = microObservations
        .where(
          (entry) =>
              entry.id == progress.definition.id &&
              entry.gradeLevel == gradeLevel &&
              entry.numberRange == numberRange,
        )
        .take(24)
        .toList();
    if (relevant.isEmpty) {
      return 'Zu diesem Teilschritt liegen noch keine passenden Beobachtungen vor.';
    }

    final independentCount =
        relevant.where((entry) => !entry.usedHelp).length;
    final aidedCount = relevant.where((entry) => entry.usedHelp).length;
    final reviewCount = relevant
        .where((entry) => entry.source == MicroEvidenceSource.review)
        .length;
    final transferCount = relevant
        .where((entry) => entry.source == MicroEvidenceSource.transfer)
        .length;
    final independentPercent =
        (progress.independentAccuracy * 100).round();

    final parts = <String>[
      '${relevant.length} passende Beobachtungen',
      '$independentCount ohne Hilfe',
    ];
    if (aidedCount > 0) {
      parts.add('$aidedCount mit Hilfe');
    }
    if (reviewCount > 0) {
      parts.add('$reviewCount nach Abstand');
    }
    if (transferCount > 0) {
      parts.add('$transferCount im Transfer');
    }

    return '${parts.join(' · ')}. '
        'Bei selbstständigen Basisaufgaben liegt die gewichtete Sicherheit bei $independentPercent %. '
        'Die Einschätzung bezieht sich nur auf die in Rechenblitz bearbeiteten Aufgaben im aktuellen Profil, in ${gradeLevel.label} und im Zahlenraum ${numberRange.label}.';
  }

  String _parentSelectionText({
    DateTime? now,
  }) {
    final plan = buildMyRound(now: now);
    final focus = plan[1];
    final review = plan[2];
    final transfer = plan[3];
    final parts = <String>[];

    if (focus.targetCompetency != null) {
      final label =
          MicroCompetencyCatalog.definition(focus.targetCompetency!).label;
      parts.add('${focus.tasks} Aufgaben fokussieren „$label“');
    } else {
      parts.add('${focus.tasks} Aufgaben bearbeiten das wichtigste aktuelle Lernziel');
    }

    if (review.reviewEmphasis && review.targetCompetency != null) {
      final label =
          MicroCompetencyCatalog.definition(review.targetCompetency!).label;
      parts.add(
        '${review.tasks} Aufgaben prüfen „$label“ nach zeitlichem Abstand',
      );
    }

    if (transfer.transferEmphasis && transfer.targetCompetency != null) {
      final label =
          MicroCompetencyCatalog.definition(transfer.targetCompetency!).label;
      parts.add(
        '${transfer.tasks} Aufgaben prüfen „$label“ in veränderter Form',
      );
    }

    return '${parts.join('; ')}. '
        'So übt Rechenblitz nicht einfach den Bereich mit der niedrigsten Gesamtquote, sondern den konkreten Teilschritt und die noch fehlende Evidenzart.';
  }

  ParentLearningInsight parentInsight({
    DateTime? now,
  }) {
    final priority = parentPriorityMicroCompetency(now: now);
    final strongestMicro = strongestMicroCompetency();
    final hasCurrentMicroEvidence = microObservations.any(
      (entry) =>
          entry.gradeLevel == gradeLevel &&
          entry.numberRange == numberRange,
    );

    if (priority != null &&
        (hasCurrentMicroEvidence || history.isEmpty)) {
      final currentFocus = currentMicroFocus();
      final dueReview = dueReviewMicroCompetency(now: now);
      final transfer = transferCandidateMicroCompetency(
        excluding: dueReview?.definition.id,
      );

      final good = strongestMicro == null
          ? 'Noch nicht genug Daten – die ersten kurzen Runden bauen die Lernkarte auf.'
          : switch (strongestMicro.state) {
              MicroCompetencyState.mastered =>
                '„${strongestMicro.definition.label}“ ist bereits gemeistert: selbstständige Basis, Abstand und Transfer sind belegt.',
              MicroCompetencyState.secure =>
                '„${strongestMicro.definition.label}“ ist aktuell sicher und gelingt in den bisherigen Aufgaben überwiegend selbstständig.',
              _ =>
                'Am stabilsten zeigt sich derzeit „${strongestMicro.definition.label}“ mit ${(strongestMicro.independentAccuracy * 100).round()} % gewichteter selbstständiger Sicherheit.',
            };

      late final String focusText;
      if (currentFocus != null &&
          currentFocus.definition.id == priority.definition.id) {
        focusText =
            'Der konkrete Teilschritt „${priority.definition.label}“ braucht aktuell am meisten Übung. '
            'Status: ${priority.state.label}; selbstständig ${(priority.independentAccuracy * 100).round()} %.';
      } else if (dueReview != null &&
          dueReview.definition.id == priority.definition.id) {
        focusText =
            '„${priority.definition.label}“ ist bereits sicher. Jetzt soll geprüft werden, ob der Teilschritt nach zeitlichem Abstand noch selbstständig gelingt.';
      } else if (transfer != null &&
          transfer.definition.id == priority.definition.id) {
        focusText =
            '„${priority.definition.label}“ ist bereits sicher. Als Nächstes soll geprüft werden, ob das Wissen auch in einer veränderten Aufgabe selbstständig angewendet wird.';
      } else {
        focusText =
            '„${priority.definition.label}“ ist der nächste sinnvolle Teilschritt in der Lernkarte.';
      }

      final diagnostic = topDiagnosticForMode(
        priority.definition.preferredMode,
      );
      final diagnosticStatus = diagnostic == null
          ? null
          : remediationStatusFor(diagnostic.pattern);
      final diagnosticIsActive = diagnostic != null &&
          diagnosticStatus != RemediationStatus.improved &&
          diagnosticStatus != RemediationStatus.stable;

      late final String action;
      if (diagnosticIsActive) {
        action =
            'Das Muster „${diagnostic.pattern.label}“ ist wiederholt aufgefallen. '
            '${diagnostic.pattern.action}';
      } else if (dueReview != null &&
          dueReview.definition.id == priority.definition.id) {
        action =
            'Eine kurze Abstandskontrolle ohne Starthilfe reicht. Entscheidend ist, ob der Rechenweg noch selbstständig abrufbar ist.';
      } else if (transfer != null &&
          transfer.definition.id == priority.definition.id) {
        action =
            'Zwei kurze Aufgaben in veränderter Form prüfen, ob dieselbe mathematische Idee übertragen werden kann.';
      } else if (priority.state == MicroCompetencyState.newSkill) {
        action =
            'Den Teilschritt zunächst mit wenigen Aufgaben vorsichtig kennenlernen; daraus entsteht erst die Beobachtungsbasis.';
      } else {
        action =
            '3–5 Minuten gezielt „${priority.definition.label}“ üben und dabei den gewählten Schul-Rechenweg nutzen.';
      }

      final notYet = switch (priority.state) {
        MicroCompetencyState.mastered =>
          'Für diesen Teilschritt fehlt aktuell kein Mastery-Nachweis. Wiederholungen dienen nur dem langfristigen Erhalt.',
        MicroCompetencyState.secure =>
          'Noch nicht „Gemeistert“: Es fehlt ${_masteryMissingText(priority)}.',
        MicroCompetencyState.newSkill =>
          'Noch keine belastbare Aussage: Erst einige passende Aufgaben zeigen, wie selbstständig der Teilschritt gelingt.',
        _ =>
          'Noch nicht „Sicher“: Es fehlt ${_masteryMissingText(priority)}. Tempo ist deshalb noch zweitrangig.',
      };

      return ParentLearningInsight(
        good: good,
        focus: focusText,
        action: action,
        notYet: notYet,
        trend: _weeklyTrendText(),
        mastery: _parentMasteryText(priority),
        evidence: _parentEvidenceText(priority),
        selection: _parentSelectionText(now: now),
      );
    }

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
      mastery:
          'Noch liegen nicht genug Mikro-Beobachtungen vor, um „Sicher“ und „Gemeistert“ für einen konkreten Teilschritt zu erklären.',
      evidence:
          'Die aktuelle Empfehlung stützt sich deshalb vorerst auf abgeschlossene Übungsrunden und Trefferquoten.',
      selection:
          'Mit weiteren kurzen Runden wechselt Rechenblitz automatisch von Bereichsdaten zu konkreten Mikro-Kompetenzen.',
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

  Future<void> setMethodSelectionPreference(
    MethodSelectionPreference value,
  ) async {
    methodPreferences =
        methodPreferences.copyWith(selectionPreference: value);
    notifyListeners();
    await storage.setMethodPreferences(methodPreferences);
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

  Future<void> addBetaFeedback(BetaFeedbackEntry entry) async {
    betaFeedbackEntries = [entry, ...betaFeedbackEntries].take(200).toList();
    notifyListeners();
    await storage.setBetaFeedback(betaFeedbackEntries);
  }

  Future<void> clearBetaFeedback() async {
    betaFeedbackEntries = [];
    notifyListeners();
    await storage.setBetaFeedback(betaFeedbackEntries);
  }

  String betaFeedbackExport() => const JsonEncoder.withIndent('  ').convert({
        'format': 'rechenblitz-beta-feedback-v1',
        'attachesProfileOrLearningData': false,
        'freeTextMayContainUserEnteredPersonalData': true,
        'entries': betaFeedbackEntries.map((entry) => entry.toJson()).toList(),
      });

  Future<void> setAccessibilityPreferences(
    AccessibilityPreferences value,
  ) async {
    accessibilityPreferences = value;
    notifyListeners();
    await storage.setAccessibilityPreferences(value);
    if (!value.readAloud) await speech.stop();
  }

  Future<void> speak(String text) async {
    if (!accessibilityPreferences.readAloud) return;
    await speech.speak(
      text,
      rate: accessibilityPreferences.speechRate,
    );
  }

  Future<void> speakOnDemand(String text) async {
    await speech.speak(
      text,
      rate: accessibilityPreferences.speechRate,
    );
  }

  String? methodSupportInsight(MicroCompetencyId id) {
    final observations = microObservations
        .where(
          (entry) =>
              entry.id == id &&
              entry.gradeLevel == gradeLevel &&
              entry.numberRange == numberRange &&
              entry.methodKey != null,
        )
        .take(80)
        .toList();
    final grouped = <String, List<MicroCompetencyObservation>>{};
    for (final entry in observations) {
      grouped.putIfAbsent(entry.methodKey!, () => []).add(entry);
    }
    final eligible = grouped.entries
        .where((entry) => entry.value.length >= 3)
        .map((entry) {
          final correct =
              entry.value.where((observation) => observation.correct).length;
          return (
            key: entry.key,
            total: entry.value.length,
            accuracy: correct / entry.value.length,
          );
        })
        .toList()
      ..sort((a, b) => b.accuracy.compareTo(a.accuracy));
    if (eligible.isEmpty) return null;
    final best = eligible.first;
    final label = best.key
        .split(':')
        .last
        .replaceAll('bridgeToTen', 'Erst zum Zehner')
        .replaceAll('takeAway', 'Schrittweise wegnehmen')
        .replaceAll('complement', 'Ergänzen')
        .replaceAll('groups', 'Gleich große Gruppen')
        .replaceAll('decompose', 'Zerlegen')
        .replaceAll('neighborFacts', 'Nachbaraufgaben');
    return 'Mit „$label“ wurden ${(best.accuracy * 100).round()} % der '
        '${best.total} beobachteten Aufgaben direkt richtig gelöst. '
        'Das ist eine Lernbeobachtung und ändert die Schulmethode nicht automatisch.';
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
    microObservations = [];
    recentTaskKeysByMode = <String, List<String>>{};
    unlockedBadges = <String>{};
    recoveredWeakFacts = <String>{};
    _pendingBadgeIds.clear();
    lastSessionNewBadges = const [];
    notifyListeners();
  }
}
