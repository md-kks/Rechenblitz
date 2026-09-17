import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/accessibility_preferences.dart';
import '../models/assessment.dart';
import '../models/beta_feedback.dart';
import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import '../models/help_preferences.dart';
import '../models/learner_profile.dart';
import '../models/learning_methods.dart';
import '../models/learning_path.dart';
import '../models/math_fact.dart';
import '../models/method_key_label.dart';
import '../models/micro_competency.dart';
import '../models/remediation_path.dart';
import '../models/reward_badge.dart';
import '../models/support_session_progress.dart';
import '../models/training_session_progress.dart';
import '../models/training.dart';
import '../models/task_diversity.dart';
import '../models/teacher_assignment.dart';
import 'adaptive_engine.dart';
import 'micro_evidence_retention.dart';
import 'speech_service.dart';
import 'storage_service.dart';

class AppController extends ChangeNotifier {
  static const double _secureIndependentEvidence = 4.0;
  static const double _secureIndependentAccuracy = 0.80;
  static const double _masteredIndependentEvidence = 6.0;
  static const double _masteredIndependentAccuracy = 0.88;
  static const double _masteredReviewEvidence = 1.5;
  static const double _masteredReviewAccuracy = 0.80;
  static const double _masteredTransferEvidence = 1.5;
  static const double _masteredTransferAccuracy = 0.80;
  static const int _secureIndependentTaskVariety = 3;
  static const int _masteredIndependentTaskVariety = 4;
  static const int _masteredReviewTaskVariety = 2;
  static const int _masteredTransferTaskVariety = 2;
  static const double _evidenceEpsilon = 1e-9;
  static const int _fluencyMinimumAttempts = 4;
  static const int _fluencyMinimumSamples = 3;
  static const int _fluencyMinimumTaskVariety = 3;
  static const double _fluencyMinimumAccuracy = 0.85;
  static const int _fluencyWindow = 8;
  static const int _fluencyTargetMs = 5000;
  // Fluency wird nur im normalen Übungsfluss im Hintergrund bewertet.
  // Explizite Zeitdruck-Modi bleiben Training, aber keine diagnostische
  // Zeitmessung, damit Countdown/Stress die Lernlandkarte nicht verzerren.
  static const Set<TrainingMode> _fluencyModes = <TrainingMode>{
    TrainingMode.practice,
    TrainingMode.minus,
    TrainingMode.multiply,
    TrainingMode.divide,
    TrainingMode.mixed,
  };
  static const Set<MicroCompetencyId> _fluencyCompetencies = <MicroCompetencyId>{
    MicroCompetencyId.additionNoBridge,
    MicroCompetencyId.additionTenBridge,
    MicroCompetencyId.subtractionNoBridge,
    MicroCompetencyId.subtractionTenBridge,
    MicroCompetencyId.multiplicationFacts,
    MicroCompetencyId.divisionFacts,
  };
  static const int _guidedStepWindow = 8;
  static const int _guidedStepMinIncorrect = 2;
  static const double _guidedStepFocusMaxAccuracy = 0.60;
  static const int _guidedStepIndependentConfirmations = 2;
  static const int _stepRecoveryIndependentConfirmations = 2;
  static const Duration _stepRecoveryFreshness = Duration(days: 2);
  static const Duration _unstableReviewRetryGap = Duration(days: 1);
  static const Duration _initialReviewGap = Duration(days: 2);
  static const Duration _reinforcedReviewGap = Duration(days: 7);
  static const Duration _masteredReviewGap = Duration(days: 14);
  static const Duration _reinforcedTransferGap = Duration(days: 5);
  static const Duration _masteredTransferGap = Duration(days: 14);
  static const Set<TrainingMode> _rangeReadinessModes = <TrainingMode>{
    TrainingMode.practice,
    TrainingMode.minus,
    TrainingMode.numberFriends,
    TrainingMode.multiply,
    TrainingMode.divide,
    TrainingMode.numberWall,
    TrainingMode.missingNumber,
    TrainingMode.neighbors,
    TrainingMode.placeValue,
    TrainingMode.doublesHalves,
    TrainingMode.sequences,
    TrainingMode.factFamilies,
    TrainingMode.largeNumbers,
    TrainingMode.mentalStrategies,
  };

  static bool _evidenceAtLeast(double value, double threshold) =>
      value + _evidenceEpsilon >= threshold;

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
  GuidedRoundProgress? guidedRoundProgress;
  AssessmentProgress? assessmentProgress;
  RemediationSessionProgress? remediationSessionProgress;
  StepRecoverySessionProgress? stepRecoverySessionProgress;
  CoreTrainingSessionProgress? coreTrainingSessionProgress;

  int get maxValue => numberRange.maxValue;

  GradeLevel get effectiveGradeLevel =>
      activeTeacherAssignment?.gradeLevel ?? gradeLevel;

  NumberRangeLevel get effectiveNumberRange =>
      activeTeacherAssignment?.numberRange ?? numberRange;

  MethodPreferences get effectiveMethodPreferences =>
      activeTeacherAssignment?.methods ?? methodPreferences;

  int get effectiveMaxValue => effectiveNumberRange.maxValue;

  bool get hasTeacherAssignment => activeTeacherAssignment != null;

  GuidedRoundProgress? resumableGuidedRound({DateTime? now}) {
    final progress = guidedRoundProgress;
    if (progress == null) return null;
    return progress.isCompatible(
      grade: gradeLevel,
      range: numberRange,
      now: now,
    )
        ? progress
        : null;
  }

  Future<void> saveGuidedRoundProgress(GuidedRoundProgress progress) async {
    guidedRoundProgress = progress;
    await storage.saveGuidedRoundProgress(progress);
  }

  Future<void> clearGuidedRoundProgress() async {
    guidedRoundProgress = null;
    await storage.clearGuidedRoundProgress();
  }

  AssessmentProgress? resumableAssessment({DateTime? now}) {
    final progress = assessmentProgress;
    if (progress == null) return null;
    return progress.isCompatible(
      grade: gradeLevel,
      range: numberRange,
      now: now,
    )
        ? progress
        : null;
  }

  Future<void> saveAssessmentProgress(AssessmentProgress progress) async {
    assessmentProgress = progress;
    await storage.saveAssessmentProgress(progress);
  }

  Future<void> clearAssessmentProgress() async {
    assessmentProgress = null;
    await storage.clearAssessmentProgress();
  }

  RemediationSessionProgress? resumableRemediationSession({
    required ErrorPattern pattern,
    required TrainingMode mode,
    required bool reviewOnly,
    DateTime? now,
  }) {
    final progress = remediationSessionProgress;
    if (progress == null) return null;
    return progress.isCompatible(
      pattern: pattern,
      mode: mode,
      grade: gradeLevel,
      range: numberRange,
      reviewOnly: reviewOnly,
      now: now,
    )
        ? progress
        : null;
  }

  Future<void> saveRemediationSession(
    RemediationSessionProgress progress,
  ) async {
    remediationSessionProgress = progress;
    await storage.saveRemediationSession(progress);
  }

  Future<void> clearRemediationSession() async {
    remediationSessionProgress = null;
    await storage.clearRemediationSession();
  }

  StepRecoverySessionProgress? resumableStepRecoverySession(
    IndependentStepRecoveryFocus focus, {
    DateTime? now,
  }) {
    final progress = stepRecoverySessionProgress;
    if (progress == null) return null;
    return progress.isCompatible(
      focus: focus,
      range: numberRange,
      now: now,
    )
        ? progress
        : null;
  }

  Future<void> saveStepRecoverySession(
    StepRecoverySessionProgress progress,
  ) async {
    stepRecoverySessionProgress = progress;
    await storage.saveStepRecoverySession(progress);
  }

  Future<void> clearStepRecoverySession() async {
    stepRecoverySessionProgress = null;
    await storage.clearStepRecoverySession();
  }

  Future<void> clearSupportSessionProgress() async {
    remediationSessionProgress = null;
    stepRecoverySessionProgress = null;
    await Future.wait([
      storage.clearRemediationSession(),
      storage.clearStepRecoverySession(),
    ]);
  }

  CoreTrainingSessionProgress? resumableCoreTrainingSession({
    required CoreTrainingKind kind,
    required TrainingMode mode,
    required int targetTasks,
    required MicroCompetencyId? targetCompetency,
    required bool reviewEmphasis,
    required bool transferEmphasis,
    required bool fluencyEmphasis,
    required bool scaffoldFading,
    required bool adaptiveLength,
    required Duration? timeLimit,
    DateTime? now,
  }) {
    final progress = coreTrainingSessionProgress;
    if (progress == null) return null;
    return progress.isCompatible(
      kind: kind,
      mode: mode,
      targetTasks: targetTasks,
      targetCompetency: targetCompetency,
      reviewEmphasis: reviewEmphasis,
      transferEmphasis: transferEmphasis,
      fluencyEmphasis: fluencyEmphasis,
      scaffoldFading: scaffoldFading,
      adaptiveLength: adaptiveLength,
      gradeLevel: effectiveGradeLevel,
      numberRange: effectiveNumberRange,
      teacherAssignmentActive: hasTeacherAssignment,
      timeLimit: timeLimit,
      now: now,
    )
        ? progress
        : null;
  }

  Future<void> saveCoreTrainingSession(
    CoreTrainingSessionProgress progress,
  ) async {
    coreTrainingSessionProgress = progress;
    await storage.saveCoreTrainingSession(progress);
  }

  Future<void> clearCoreTrainingSession() async {
    coreTrainingSessionProgress = null;
    await storage.clearCoreTrainingSession();
  }

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
    microObservations = MicroEvidenceRetention.compact(
      await storage.loadMicroCompetencyObservations(),
    );
    recentTaskKeysByMode = await storage.loadTaskDiversity();
    numberRange =
        await storage.numberRange() ?? gradeLevel.recommendedRange;
    if (!availableRanges.contains(numberRange)) {
      numberRange = gradeLevel.recommendedRange;
      await storage.setNumberRange(numberRange);
    }
    guidedRoundProgress = await storage.loadGuidedRoundProgress();
    if (guidedRoundProgress != null &&
        !guidedRoundProgress!.isCompatible(
          grade: gradeLevel,
          range: numberRange,
        )) {
      guidedRoundProgress = null;
      await storage.clearGuidedRoundProgress();
    }
    assessmentProgress = await storage.loadAssessmentProgress();
    if (assessmentProgress != null &&
        !assessmentProgress!.isCompatible(
          grade: gradeLevel,
          range: numberRange,
        )) {
      assessmentProgress = null;
      await storage.clearAssessmentProgress();
    }
    final progressNow = DateTime.now();
    remediationSessionProgress = await storage.loadRemediationSession();
    final remediationSession = remediationSessionProgress;
    if (remediationSession != null &&
        (!remediationSession.hasSaneState(now: progressNow) ||
            remediationSession.gradeLevel != gradeLevel ||
            remediationSession.numberRange != numberRange)) {
      remediationSessionProgress = null;
      await storage.clearRemediationSession();
    }
    stepRecoverySessionProgress = await storage.loadStepRecoverySession();
    final stepRecoverySession = stepRecoverySessionProgress;
    if (stepRecoverySession != null &&
        (!stepRecoverySession.hasSaneState(now: progressNow) ||
            stepRecoverySession.numberRange != numberRange)) {
      stepRecoverySessionProgress = null;
      await storage.clearStepRecoverySession();
    }
    coreTrainingSessionProgress = await storage.loadCoreTrainingSession();
    final coreTrainingSession = coreTrainingSessionProgress;
    if (coreTrainingSession != null &&
        (!coreTrainingSession.hasSaneState() ||
            coreTrainingSession.gradeLevel != gradeLevel ||
            coreTrainingSession.numberRange != numberRange ||
            coreTrainingSession.teacherAssignmentActive ||
            DateTime.now().difference(coreTrainingSession.updatedAt) >
                CoreTrainingSessionProgress.maxAge)) {
      coreTrainingSessionProgress = null;
      await storage.clearCoreTrainingSession();
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

  HelpPreferences get helpPreferences => activeProfile.helpPreferences;

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

  int? _fairFluencyResponseMs(Duration? responseTime) {
    if (responseTime == null || accessibilityPreferences.readAloud) return null;
    final milliseconds = responseTime.inMilliseconds;
    if (milliseconds <= 0 || milliseconds > 30000) return null;
    return milliseconds;
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
    Duration? responseTime,
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
      responseMs: _fairFluencyResponseMs(responseTime),
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
      responseMs: null,
    );
    notifyListeners();
    await storage.saveMicroCompetencyObservations(microObservations);
  }

  Future<void> recordIndependentStepAttempt({
    required TrainingMode mode,
    required String taskKey,
    required String stepKey,
    required MicroCompetencyId competencyId,
    required bool correct,
    required bool usedHelp,
    required int helpLevel,
    String? methodKey,
    double evidenceWeight = 0.35,
  }) async {
    if (evidenceWeight <= 0) return;
    final helpWeight = !correct
        ? 1.0
        : switch (helpLevel) {
            >= 3 => 0.50,
            2 => 0.65,
            1 => 0.80,
            _ => usedHelp ? 0.80 : 1.0,
          };
    microObservations.insert(
      0,
      MicroCompetencyObservation(
        id: competencyId,
        occurredAt: DateTime.now(),
        correct: correct,
        evidenceWeight:
            evidenceWeight.clamp(0.10, 0.50).toDouble() * helpWeight,
        source: MicroEvidenceSource.independentStep,
        usedHelp: usedHelp,
        helpLevel: helpLevel,
        methodKey: methodKey,
        mode: mode,
        gradeLevel: gradeLevel,
        numberRange: numberRange,
        taskKey: 'independent:$stepKey:$taskKey',
      ),
    );
    _compactMicroObservations();
    notifyListeners();
    await storage.saveMicroCompetencyObservations(microObservations);
  }

  Future<void> recordGuidedStepAttempt({
    required TrainingMode mode,
    required String taskKey,
    required String methodKey,
    required String stepKey,
    required MicroCompetencyId competencyId,
    required bool correct,
    double evidenceWeight = 0.35,
  }) async {
    if (evidenceWeight <= 0) return;
    microObservations.insert(
      0,
      MicroCompetencyObservation(
        id: competencyId,
        occurredAt: DateTime.now(),
        correct: correct,
        evidenceWeight: evidenceWeight.clamp(0.05, 0.50).toDouble(),
        source: MicroEvidenceSource.guidedStep,
        usedHelp: true,
        helpLevel: HelpLevel.guided.value,
        methodKey: methodKey,
        mode: mode,
        gradeLevel: gradeLevel,
        numberRange: numberRange,
        taskKey: 'guided:$methodKey:$stepKey:$taskKey',
      ),
    );
    _compactMicroObservations();
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
    int? responseMs,
    MicroCompetencyId? onlyCompetency,
  }) {
    final sourceWeight = switch (source) {
      MicroEvidenceSource.assessment => 0.75,
      MicroEvidenceSource.remediation => 0.65,
      MicroEvidenceSource.independentStep => 0.45,
      MicroEvidenceSource.guidedStep => 0.35,
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

    final tags = MicroCompetencyCatalog.tagsForTask(
      mode: mode,
      taskKey: taskKey,
      fact: fact,
    );
    final selectedTags = onlyCompetency == null
        ? tags
        : tags.where((tag) => tag.id == onlyCompetency).toList(growable: false);
    final observations = selectedTags
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
            responseMs: responseMs,
          ),
        )
        .toList();
    microObservations.insertAll(0, observations);

    _compactMicroObservations();
  }

  void _compactMicroObservations() {
    microObservations = MicroEvidenceRetention.compact(microObservations);
  }

  List<MicroCompetencyObservation> _sortedMicroObservationsFor(
    MicroCompetencyId id,
  ) {
    final matching = microObservations
        .where(
          (entry) =>
              entry.id == id &&
              entry.gradeLevel == gradeLevel &&
              entry.numberRange == numberRange,
        )
        .toList();
    matching.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return matching;
  }

  String _microEvidenceTaskKey(MicroCompetencyObservation observation) {
    final key = observation.taskKey;
    if (key.startsWith('independent:')) {
      final parts = key.split(':');
      if (parts.length >= 3) return parts.sublist(2).join(':');
    }
    return key;
  }


  MathFact? _basicFluencyFactFor(MicroCompetencyObservation observation) {
    final parts = _microEvidenceTaskKey(observation).split(':');
    if (parts.length != 3) return null;
    final a = int.tryParse(parts[1]);
    final b = int.tryParse(parts[2]);
    if (a == null || b == null) return null;
    final operation = switch (parts[0]) {
      'plus' => MathOperation.plus,
      'minus' => MathOperation.minus,
      'multiply' => MathOperation.multiply,
      'divide' => MathOperation.divide,
      _ => null,
    };
    if (operation == null) return null;
    final fact = MathFact(a: a, b: b, operation: operation);
    if (!fact.isBasicFluencyFact) return null;
    final matchesCompetency = MicroCompetencyCatalog.tagsForTask(
      mode: observation.mode,
      taskKey: fact.key,
      fact: fact,
    ).any((tag) => tag.id == observation.id);
    return matchesCompetency ? fact : null;
  }

  MicroCompetencyObservation? _latestMicroObservationForSource(
    MicroCompetencyId id,
    MicroEvidenceSource source,
  ) {
    for (final observation in _sortedMicroObservationsFor(id)) {
      if (observation.source == source) return observation;
    }
    return null;
  }

  bool _latestSourceEvidenceIsIndependentCorrect(
    MicroCompetencyId id,
    MicroEvidenceSource source,
  ) {
    final latest = _latestMicroObservationForSource(id, source);
    return latest != null && latest.correct && !latest.usedHelp;
  }

  bool _latestSourceEvidenceIsUnstable(
    MicroCompetencyId id,
    MicroEvidenceSource source,
  ) {
    final latest = _latestMicroObservationForSource(id, source);
    return latest != null && (!latest.correct || latest.usedHelp);
  }

  MicroCompetencyObservation? _latestBasisObservation(
    MicroCompetencyId id,
  ) {
    for (final observation in _sortedMicroObservationsFor(id)) {
      if (observation.source == MicroEvidenceSource.assessment ||
          observation.source == MicroEvidenceSource.practice ||
          observation.source == MicroEvidenceSource.remediation) {
        return observation;
      }
    }
    return null;
  }

  bool _latestBasisEvidenceIsIndependentCorrect(MicroCompetencyId id) {
    final latest = _latestBasisObservation(id);
    return latest != null && latest.correct && !latest.usedHelp;
  }

  bool _latestBasisEvidenceIsUnstable(MicroCompetencyId id) {
    final latest = _latestBasisObservation(id);
    return latest != null && (!latest.correct || latest.usedHelp);
  }

  MicroCompetencyProgress microCompetencyProgress(
    MicroCompetencyId id,
  ) {
    final definition = MicroCompetencyCatalog.definition(id);
    final matchingObservations = _sortedMicroObservationsFor(id);
    final observations = <MicroCompetencyObservation>[
      ...matchingObservations
          .where(
            (entry) =>
                entry.source != MicroEvidenceSource.independentStep &&
                entry.source != MicroEvidenceSource.guidedStep,
          )
          .take(24),
      ...matchingObservations
          .where((entry) => entry.source == MicroEvidenceSource.independentStep)
          .take(12),
      ...matchingObservations
          .where((entry) => entry.source == MicroEvidenceSource.guidedStep)
          .take(12),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    if (observations.isEmpty) {
      return MicroCompetencyProgress(
        definition: definition,
        state: MicroCompetencyState.newSkill,
        accuracy: 0,
        evidence: 0,
        observations: 0,
        fluencyState: _fluencyCompetencies.contains(id)
            ? MicroFluencyState.notMeasured
            : MicroFluencyState.notApplicable,
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
    var independentStepEvidence = 0.0;
    var independentStepCorrectEvidence = 0.0;
    var independentStepObservations = 0;
    var guidedStepEvidence = 0.0;
    var guidedStepCorrectEvidence = 0.0;
    var guidedStepObservations = 0;
    DateTime? lastReviewSeen;
    DateTime? lastTransferSeen;
    final independentTaskKeys = <String>{};
    final reviewIndependentTaskKeys = <String>{};
    final transferIndependentTaskKeys = <String>{};
    final fluencyAttempts = <MicroCompetencyObservation>[];
    final fluencyResponseMs = <int>[];
    final fluencyTaskKeys = <String>{};

    for (final observation in observations) {
      evidence += observation.evidenceWeight;
      if (observation.correct) {
        correctEvidence += observation.evidenceWeight;
      }
      if (observation.usedHelp) {
        aidedEvidence += observation.evidenceWeight;
        aidedObservations += 1;
      }

      if (_fluencyCompetencies.contains(id) &&
          _fluencyModes.contains(observation.mode) &&
          _basicFluencyFactFor(observation) != null &&
          fluencyAttempts.length < _fluencyWindow &&
          !observation.usedHelp &&
          observation.responseMs != null &&
          observation.responseMs! > 0 &&
          observation.source != MicroEvidenceSource.guidedStep &&
          observation.source != MicroEvidenceSource.independentStep &&
          observation.source != MicroEvidenceSource.remediation &&
          observation.source != MicroEvidenceSource.assessment) {
        fluencyAttempts.add(observation);
        if (observation.correct) {
          fluencyResponseMs.add(observation.responseMs!);
          fluencyTaskKeys.add(_microEvidenceTaskKey(observation));
        }
      }

      switch (observation.source) {
        case MicroEvidenceSource.review:
          reviewEvidence += observation.evidenceWeight;
          reviewObservations += 1;
          if (observation.correct) {
            reviewCorrectEvidence += observation.evidenceWeight;
          }
          if (!observation.usedHelp) {
            reviewIndependentTaskKeys.add(_microEvidenceTaskKey(observation));
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
            transferIndependentTaskKeys.add(_microEvidenceTaskKey(observation));
            transferIndependentEvidence += observation.evidenceWeight;
            if (observation.correct) {
              transferIndependentCorrectEvidence +=
                  observation.evidenceWeight;
            }
          }
          lastTransferSeen ??= observation.occurredAt;
          break;
        case MicroEvidenceSource.independentStep:
          independentStepEvidence += observation.evidenceWeight;
          independentStepObservations += 1;
          baseEvidence += observation.evidenceWeight;
          if (observation.correct) {
            independentStepCorrectEvidence += observation.evidenceWeight;
            baseCorrectEvidence += observation.evidenceWeight;
          }
          if (!observation.usedHelp) {
            independentTaskKeys.add(_microEvidenceTaskKey(observation));
            independentEvidence += observation.evidenceWeight;
            if (observation.correct) {
              independentCorrectEvidence += observation.evidenceWeight;
            }
          }
          break;
        case MicroEvidenceSource.guidedStep:
          guidedStepEvidence += observation.evidenceWeight;
          guidedStepObservations += 1;
          if (observation.correct) {
            guidedStepCorrectEvidence += observation.evidenceWeight;
          }
          break;
        case MicroEvidenceSource.assessment:
        case MicroEvidenceSource.practice:
        case MicroEvidenceSource.remediation:
          baseEvidence += observation.evidenceWeight;
          if (observation.correct) {
            baseCorrectEvidence += observation.evidenceWeight;
          }
          if (!observation.usedHelp) {
            independentTaskKeys.add(_microEvidenceTaskKey(observation));
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
    final independentStepAccuracy = independentStepEvidence == 0
        ? 0.0
        : independentStepCorrectEvidence / independentStepEvidence;
    final guidedStepAccuracy = guidedStepEvidence == 0
        ? 0.0
        : guidedStepCorrectEvidence / guidedStepEvidence;

    final fluencyCorrectAttempts =
        fluencyAttempts.where((observation) => observation.correct).length;
    final fluencyAccuracy = fluencyAttempts.isEmpty
        ? 0.0
        : fluencyCorrectAttempts / fluencyAttempts.length;
    final averageFluencyResponseMs = fluencyResponseMs.isEmpty
        ? 0.0
        : fluencyResponseMs.reduce((a, b) => a + b) / fluencyResponseMs.length;
    final sortedFluencyResponseMs = [...fluencyResponseMs]..sort();
    final typicalFluencyResponseMs = sortedFluencyResponseMs.isEmpty
        ? 0.0
        : sortedFluencyResponseMs.length.isOdd
            ? sortedFluencyResponseMs[sortedFluencyResponseMs.length ~/ 2].toDouble()
            : (sortedFluencyResponseMs[sortedFluencyResponseMs.length ~/ 2 - 1] +
                    sortedFluencyResponseMs[sortedFluencyResponseMs.length ~/ 2]) /
                2;
    final fluencyMeasurementReady =
        fluencyAttempts.length >= _fluencyMinimumAttempts &&
            fluencyResponseMs.length >= _fluencyMinimumSamples &&
            fluencyTaskKeys.length >= _fluencyMinimumTaskVariety;
    final fluencyState = !_fluencyCompetencies.contains(id)
        ? MicroFluencyState.notApplicable
        : !fluencyMeasurementReady
            ? MicroFluencyState.notMeasured
            : fluencyAccuracy >= _fluencyMinimumAccuracy &&
                    typicalFluencyResponseMs <= _fluencyTargetMs
                ? MicroFluencyState.fluent
                : MicroFluencyState.building;

    final latestBasisStable = _latestBasisEvidenceIsIndependentCorrect(id);
    final latestReviewStable =
        _latestSourceEvidenceIsIndependentCorrect(id, MicroEvidenceSource.review);
    final latestTransferStable = _latestSourceEvidenceIsIndependentCorrect(
      id,
      MicroEvidenceSource.transfer,
    );

    final state = evidence < 1.5
        ? MicroCompetencyState.discovering
        : _evidenceAtLeast(
                  independentEvidence,
                  _masteredIndependentEvidence,
                ) &&
                independentAccuracy >= _masteredIndependentAccuracy &&
                independentTaskKeys.length >= _masteredIndependentTaskVariety &&
                latestBasisStable &&
                _evidenceAtLeast(
                  reviewIndependentEvidence,
                  _masteredReviewEvidence,
                ) &&
                reviewIndependentAccuracy >= _masteredReviewAccuracy &&
                reviewIndependentTaskKeys.length >= _masteredReviewTaskVariety &&
                latestReviewStable &&
                _evidenceAtLeast(
                  transferIndependentEvidence,
                  _masteredTransferEvidence,
                ) &&
                transferIndependentAccuracy >= _masteredTransferAccuracy &&
                transferIndependentTaskKeys.length >= _masteredTransferTaskVariety &&
                latestTransferStable
            ? MicroCompetencyState.mastered
            : _evidenceAtLeast(
                      independentEvidence,
                      _secureIndependentEvidence,
                    ) &&
                    independentAccuracy >= _secureIndependentAccuracy &&
                    independentTaskKeys.length >= _secureIndependentTaskVariety
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
      independentStepAccuracy: independentStepAccuracy,
      guidedStepAccuracy: guidedStepAccuracy,
      baseEvidence: baseEvidence,
      independentEvidence: independentEvidence,
      aidedEvidence: aidedEvidence,
      reviewEvidence: reviewEvidence,
      reviewIndependentEvidence: reviewIndependentEvidence,
      transferEvidence: transferEvidence,
      transferIndependentEvidence: transferIndependentEvidence,
      independentStepEvidence: independentStepEvidence,
      guidedStepEvidence: guidedStepEvidence,
      aidedObservations: aidedObservations,
      reviewObservations: reviewObservations,
      transferObservations: transferObservations,
      independentStepObservations: independentStepObservations,
      guidedStepObservations: guidedStepObservations,
      independentTaskVariety: independentTaskKeys.length,
      reviewIndependentTaskVariety: reviewIndependentTaskKeys.length,
      transferIndependentTaskVariety: transferIndependentTaskKeys.length,
      fluencyState: fluencyState,
      fluencyAttempts: fluencyAttempts.length,
      fluencySamples: fluencyResponseMs.length,
      fluencyCorrectAttempts: fluencyCorrectAttempts,
      fluencyTaskVariety: fluencyTaskKeys.length,
      fluencyAccuracy: fluencyAccuracy,
      averageFluencyResponseMs: averageFluencyResponseMs,
      typicalFluencyResponseMs: typicalFluencyResponseMs,
      basisNeedsReconfirmation: _latestBasisEvidenceIsUnstable(id),
      reviewNeedsReconfirmation: _latestSourceEvidenceIsUnstable(
        id,
        MicroEvidenceSource.review,
      ),
      transferNeedsReconfirmation: _latestSourceEvidenceIsUnstable(
        id,
        MicroEvidenceSource.transfer,
      ),
      lastSeen: matchingObservations.first.occurredAt,
      lastReviewSeen: lastReviewSeen,
      lastTransferSeen: lastTransferSeen,
    );
  }

  List<MicroCompetencyProgress> microCompetenciesForGrade() =>
      MicroCompetencyCatalog.forContext(gradeLevel, numberRange)
          .map((definition) => microCompetencyProgress(definition.id))
          .toList();

  List<MicroCompetencyProgress> microCompetenciesForMode(
    TrainingMode mode,
  ) =>
      MicroCompetencyCatalog.forContext(gradeLevel, numberRange)
          .where((definition) => definition.preferredMode == mode)
          .map((definition) => microCompetencyProgress(definition.id))
          .toList();

  String? _independentStepKeyFromTaskKey(String taskKey) {
    final parts = taskKey.split(':');
    if (parts.length < 3 || parts.first != 'independent') return null;
    return parts[1];
  }

  bool _independentStepRecovered(
    MicroCompetencyId competencyId,
    String stepKey,
    DateTime after,
  ) {
    final confirmations = microObservations
        .where(
          (entry) =>
              entry.id == competencyId &&
              entry.gradeLevel == gradeLevel &&
              entry.numberRange == numberRange &&
              entry.source == MicroEvidenceSource.independentStep &&
              !entry.usedHelp &&
              entry.evidenceWeight >= 0.25 &&
              entry.occurredAt.isAfter(after) &&
              GuidedStepCatalog.keyFromTaskKey(entry.taskKey) == stepKey,
        )
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final latest = confirmations
        .take(_stepRecoveryIndependentConfirmations)
        .toList();
    return latest.length >= _stepRecoveryIndependentConfirmations &&
        latest.every((entry) => entry.correct);
  }

  IndependentStepRecoveryFocus? independentStepRecoveryFocus({
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final candidates = microObservations
        .where(
          (entry) =>
              entry.source == MicroEvidenceSource.independentStep &&
              !entry.correct &&
              entry.gradeLevel == gradeLevel &&
              entry.numberRange == numberRange &&
              !entry.occurredAt.isAfter(reference) &&
              reference.difference(entry.occurredAt) <=
                  _stepRecoveryFreshness,
        )
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    for (final observation in candidates) {
      final stepKey = GuidedStepCatalog.keyFromTaskKey(observation.taskKey);
      if (stepKey == null || !StepRecoveryGenerator.supports(stepKey)) {
        continue;
      }
      if (_independentStepRecovered(
        observation.id,
        stepKey,
        observation.occurredAt,
      )) {
        continue;
      }
      return IndependentStepRecoveryFocus(
        competencyId: observation.id,
        stepKey: stepKey,
        label: GuidedStepCatalog.labelFor(stepKey),
        mode: observation.mode,
        lastSeen: observation.occurredAt,
        sourceTaskKey: observation.taskKey,
      );
    }
    return null;
  }

  bool _guidedStepRecoveredIndependently(
    MicroCompetencyId competencyId,
    String stepKey,
    DateTime after,
  ) {
    final independent = microObservations
        .where(
          (entry) {
            if (entry.id != competencyId ||
                entry.gradeLevel != gradeLevel ||
                entry.numberRange != numberRange ||
                entry.usedHelp ||
                !entry.occurredAt.isAfter(after)) {
              return false;
            }
            if (entry.source == MicroEvidenceSource.practice) {
              return entry.evidenceWeight >= 0.80;
            }
            if (entry.source == MicroEvidenceSource.independentStep) {
              return entry.evidenceWeight >= 0.25 &&
                  _independentStepKeyFromTaskKey(entry.taskKey) == stepKey;
            }
            return false;
          },
        )
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final latest =
        independent.take(_guidedStepIndependentConfirmations).toList();
    return latest.length >= _guidedStepIndependentConfirmations &&
        latest.every((entry) => entry.correct);
  }

  GuidedStepFocus? guidedStepFocus() {
    final grouped = <String, List<MicroCompetencyObservation>>{};

    for (final observation in microObservations) {
      if (observation.source != MicroEvidenceSource.guidedStep ||
          observation.gradeLevel != gradeLevel ||
          observation.numberRange != numberRange) {
        continue;
      }
      final stepKey = GuidedStepCatalog.keyFromTaskKey(observation.taskKey);
      if (stepKey == null) continue;
      final groupKey = '${observation.id.name}|$stepKey';
      grouped
          .putIfAbsent(groupKey, () => <MicroCompetencyObservation>[])
          .add(observation);
    }

    final candidates = <GuidedStepFocus>[];
    for (final entries in grouped.values) {
      entries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      final recent = entries.take(_guidedStepWindow).toList();
      if (recent.length < 2) continue;

      final incorrect = recent.where((entry) => !entry.correct).length;
      final accuracy =
          recent.where((entry) => entry.correct).length / recent.length;
      final competencyId = recent.first.id;
      final progress = microCompetencyProgress(competencyId);
      final stepKey =
          GuidedStepCatalog.keyFromTaskKey(recent.first.taskKey);
      if (stepKey == null) continue;

      if (incorrect < _guidedStepMinIncorrect ||
          accuracy >= _guidedStepFocusMaxAccuracy ||
          progress.state == MicroCompetencyState.secure ||
          progress.state == MicroCompetencyState.mastered ||
          _guidedStepRecoveredIndependently(
            competencyId,
            stepKey,
            recent.first.occurredAt,
          )) {
        continue;
      }
      candidates.add(
        GuidedStepFocus(
          competencyId: competencyId,
          stepKey: stepKey,
          label: GuidedStepCatalog.labelFor(stepKey),
          observations: recent.length,
          incorrectFirstAttempts: incorrect,
          accuracy: accuracy,
          lastSeen: recent.first.occurredAt,
        ),
      );
    }

    candidates.sort((a, b) {
      final accuracyOrder = a.accuracy.compareTo(b.accuracy);
      if (accuracyOrder != 0) return accuracyOrder;
      final incorrectOrder =
          b.incorrectFirstAttempts.compareTo(a.incorrectFirstAttempts);
      if (incorrectOrder != 0) return incorrectOrder;
      return b.lastSeen.compareTo(a.lastSeen);
    });
    return candidates.isEmpty ? null : candidates.first;
  }

  MicroCompetencyProgress? currentMicroFocus() {
    final guidedFocus = guidedStepFocus();
    final candidates = microCompetenciesForGrade()
        .where(
          (progress) =>
              progress.baseEvidence > 0 &&
              ((progress.state != MicroCompetencyState.secure &&
                      progress.state != MicroCompetencyState.mastered) ||
                  _latestBasisEvidenceIsUnstable(progress.definition.id)),
        )
        .toList()
      ..sort((a, b) {
        final aBasisUnstable = _latestBasisEvidenceIsUnstable(a.definition.id);
        final bBasisUnstable = _latestBasisEvidenceIsUnstable(b.definition.id);
        if (aBasisUnstable != bBasisUnstable) return aBasisUnstable ? -1 : 1;
        final accuracyOrder = a.independentAccuracy.compareTo(b.independentAccuracy);
        if (accuracyOrder != 0) return accuracyOrder;
        final varietyOrder =
            a.independentTaskVariety.compareTo(b.independentTaskVariety);
        if (varietyOrder != 0) return varietyOrder;
        return b.independentEvidence.compareTo(a.independentEvidence);
      });

    MicroCompetencyProgress resolvePrerequisite(MicroCompetencyProgress progress) {
      final unlock = microCompetencyUnlockStatus(progress.definition.id);
      return unlock.nextRequired == null
          ? progress
          : microCompetencyProgress(unlock.nextRequired!.id);
    }

    if (candidates.isEmpty) {
      return guidedFocus == null
          ? null
          : resolvePrerequisite(microCompetencyProgress(guidedFocus.competencyId));
    }

    var candidate = resolvePrerequisite(candidates.first);
    if (guidedFocus != null) {
      final guided = resolvePrerequisite(
        microCompetencyProgress(guidedFocus.competencyId),
      );
      if (candidate.definition.id == guidedFocus.competencyId ||
          candidate.definition.id == guided.definition.id ||
          candidate.definition.prerequisites.contains(guidedFocus.competencyId)) {
        candidate = guided;
      }
    }
    return candidate;
  }

  MicroCompetencyProgress? _blockedDependentWaitingFor(
    MicroCompetencyId prerequisite,
  ) {
    final candidates = microCompetenciesForGrade()
        .where(
          (progress) =>
              progress.definition.id != prerequisite &&
              progress.baseEvidence > 0 &&
              microCompetencyUnlockStatus(progress.definition.id)
                      .nextRequired
                      ?.id ==
                  prerequisite,
        )
        .toList()
      ..sort((a, b) {
        final unstableOrder =
            (_latestBasisEvidenceIsUnstable(b.definition.id) ? 1 : 0) -
                (_latestBasisEvidenceIsUnstable(a.definition.id) ? 1 : 0);
        if (unstableOrder != 0) return unstableOrder;
        final accuracyOrder =
            a.independentAccuracy.compareTo(b.independentAccuracy);
        if (accuracyOrder != 0) return accuracyOrder;
        return b.baseEvidence.compareTo(a.baseEvidence);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  MicroCompetencyProgress? strongestMicroCompetency() {
    final candidates = microCompetenciesForGrade()
        .where(
          (progress) =>
              progress.independentEvidence > 0 &&
              _microCompetencyIsUnlocked(progress.definition.id),
        )
        .toList()
      ..sort((a, b) {
        final stateOrder = b.state.index.compareTo(a.state.index);
        if (stateOrder != 0) return stateOrder;
        final accuracyOrder =
            b.independentAccuracy.compareTo(a.independentAccuracy);
        if (accuracyOrder != 0) return accuracyOrder;
        final varietyOrder =
            b.independentTaskVariety.compareTo(a.independentTaskVariety);
        if (varietyOrder != 0) return varietyOrder;
        return b.independentEvidence.compareTo(a.independentEvidence);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  MicroCompetencyProgress? warmUpMicroCompetency({
    Iterable<MicroCompetencyId> excluding = const <MicroCompetencyId>[],
  }) {
    final blocked = excluding.toSet();
    final candidates = microCompetenciesForGrade()
        .where(
          (progress) =>
              !blocked.contains(progress.definition.id) &&
              _microCompetencyIsUnlocked(progress.definition.id) &&
              progress.independentEvidence > 0 &&
              (progress.state == MicroCompetencyState.secure ||
                  progress.state == MicroCompetencyState.mastered) &&
              !_latestBasisEvidenceIsUnstable(progress.definition.id),
        )
        .toList()
      ..sort((a, b) {
        if (a.lastSeen == null && b.lastSeen != null) return -1;
        if (a.lastSeen != null && b.lastSeen == null) return 1;
        if (a.lastSeen != null && b.lastSeen != null) {
          final ageOrder = a.lastSeen!.compareTo(b.lastSeen!);
          if (ageOrder != 0) return ageOrder;
        }
        final stateOrder = b.state.index.compareTo(a.state.index);
        if (stateOrder != 0) return stateOrder;
        return b.independentAccuracy.compareTo(a.independentAccuracy);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  MicroCompetencyProgress? maintenanceMicroCompetency({
    Iterable<MicroCompetencyId> excluding = const <MicroCompetencyId>[],
  }) {
    final blocked = excluding.toSet();
    final candidates = microCompetenciesForGrade()
        .where(
          (progress) =>
              !blocked.contains(progress.definition.id) &&
              _microCompetencyIsUnlocked(progress.definition.id) &&
              progress.independentEvidence > 0 &&
              (progress.state == MicroCompetencyState.secure ||
                  progress.state == MicroCompetencyState.mastered) &&
              !_latestBasisEvidenceIsUnstable(progress.definition.id),
        )
        .toList()
      ..sort((a, b) {
        final aAnchor = a.lastReviewSeen ?? a.lastSeen;
        final bAnchor = b.lastReviewSeen ?? b.lastSeen;
        if (aAnchor == null && bAnchor != null) return -1;
        if (aAnchor != null && bAnchor == null) return 1;
        if (aAnchor != null && bAnchor != null) {
          final ageOrder = aAnchor.compareTo(bAnchor);
          if (ageOrder != 0) return ageOrder;
        }
        return a.reviewIndependentEvidence.compareTo(b.reviewIndependentEvidence);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  MicroCompetencyProgress? fluencyFocusMicroCompetency({
    Iterable<MicroCompetencyId> excluding = const <MicroCompetencyId>[],
  }) {
    if (accessibilityPreferences.readAloud) return null;
    final blocked = excluding.toSet();
    final candidates = microCompetenciesForGrade()
        .where(
          (progress) =>
              !blocked.contains(progress.definition.id) &&
              _microCompetencyIsUnlocked(progress.definition.id) &&
              (progress.state == MicroCompetencyState.secure ||
                  progress.state == MicroCompetencyState.mastered) &&
              !progress.basisNeedsReconfirmation &&
              (progress.fluencyState == MicroFluencyState.building ||
                  progress.fluencyState == MicroFluencyState.notMeasured),
        )
        .toList()
      ..sort((a, b) {
        final aBuilding = a.fluencyState == MicroFluencyState.building;
        final bBuilding = b.fluencyState == MicroFluencyState.building;
        if (aBuilding != bBuilding) return aBuilding ? -1 : 1;
        if (aBuilding && bBuilding) {
          final accuracyOrder = a.fluencyAccuracy.compareTo(b.fluencyAccuracy);
          if (accuracyOrder != 0) return accuracyOrder;
          final speedOrder = b.typicalFluencyResponseMs
              .compareTo(a.typicalFluencyResponseMs);
          if (speedOrder != 0) return speedOrder;
        } else {
          final attemptOrder = b.fluencyAttempts.compareTo(a.fluencyAttempts);
          if (attemptOrder != 0) return attemptOrder;
          final varietyOrder = b.fluencyTaskVariety.compareTo(a.fluencyTaskVariety);
          if (varietyOrder != 0) return varietyOrder;
        }
        if (a.lastSeen == null && b.lastSeen != null) return -1;
        if (a.lastSeen != null && b.lastSeen == null) return 1;
        if (a.lastSeen != null && b.lastSeen != null) {
          final ageOrder = a.lastSeen!.compareTo(b.lastSeen!);
          if (ageOrder != 0) return ageOrder;
        }
        return a.definition.id.index.compareTo(b.definition.id.index);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  DateTime? nextReviewDueAt(MicroCompetencyId id) {
    final progress = microCompetencyProgress(id);
    if (progress.lastSeen == null ||
        (progress.state != MicroCompetencyState.secure &&
            progress.state != MicroCompetencyState.mastered)) {
      return null;
    }
    final latestReview = _latestMicroObservationForSource(
      id,
      MicroEvidenceSource.review,
    );
    final latestReviewUnstable = _latestSourceEvidenceIsUnstable(
      id,
      MicroEvidenceSource.review,
    );
    final hasStableDelayedEvidence = _evidenceAtLeast(
          progress.reviewIndependentEvidence,
          _masteredReviewEvidence,
        ) &&
        progress.reviewIndependentAccuracy >= _masteredReviewAccuracy &&
        !latestReviewUnstable;
    final requiredGap = latestReviewUnstable
        ? _unstableReviewRetryGap
        : progress.state == MicroCompetencyState.mastered
            ? _masteredReviewGap
            : hasStableDelayedEvidence
                ? _reinforcedReviewGap
                : _initialReviewGap;
    final basisAnchor =
        _latestBasisObservation(id)?.occurredAt ?? progress.lastSeen!;
    final anchor = latestReview?.occurredAt ?? basisAnchor;
    return anchor.add(requiredGap);
  }

  DateTime? nextTransferDueAt(MicroCompetencyId id) {
    final progress = microCompetencyProgress(id);
    if (progress.lastSeen == null ||
        (progress.state != MicroCompetencyState.secure &&
            progress.state != MicroCompetencyState.mastered)) {
      return null;
    }
    final latestTransfer = _latestMicroObservationForSource(
      id,
      MicroEvidenceSource.transfer,
    );
    if (latestTransfer == null) return progress.lastSeen;
    final unstable = _latestSourceEvidenceIsUnstable(
      id,
      MicroEvidenceSource.transfer,
    );
    final gap = unstable
        ? _unstableReviewRetryGap
        : progress.state == MicroCompetencyState.mastered
            ? _masteredTransferGap
            : _reinforcedTransferGap;
    return latestTransfer.occurredAt.add(gap);
  }

  MicroEvidenceConfidence microEvidenceConfidence(
    MicroCompetencyId id, {
    DateTime? now,
  }) {
    final progress = microCompetencyProgress(id);
    final reference = now ?? DateTime.now();

    if (progress.independentEvidence <= _evidenceEpsilon) {
      final detail = progress.aidedEvidence > _evidenceEpsilon
          ? 'Es gibt bereits Beobachtungen mit Hilfe, aber noch keinen selbstständigen Basisnachweis.'
          : progress.evidence > _evidenceEpsilon
              ? 'Es gibt erste Beobachtungen, aber noch keinen belastbaren selbstständigen Basisnachweis.'
              : 'Für diesen Teilschritt liegen noch keine auswertbaren Beobachtungen vor.';
      return MicroEvidenceConfidence(
        level: MicroEvidenceConfidenceLevel.insufficient,
        detail: detail,
      );
    }

    final reconfirm = <String>[];
    if (progress.basisNeedsReconfirmation) {
      reconfirm.add('die letzte Basisaufgabe');
    }
    if (progress.reviewNeedsReconfirmation) {
      reconfirm.add('die letzte Abstandskontrolle');
    }
    if (progress.transferNeedsReconfirmation) {
      reconfirm.add('der letzte Transfer');
    }
    if (reconfirm.isNotEmpty) {
      return MicroEvidenceConfidence(
        level: MicroEvidenceConfidenceLevel.reconfirmationNeeded,
        detail:
            '${reconfirm.join(', ')} war falsch oder brauchte Hilfe. Der bisherige Stand bleibt sichtbar, wird aber erst nach einer neuen selbstständigen Bestätigung wieder als aktuell belastbar gewertet.',
      );
    }

    if (progress.state != MicroCompetencyState.secure &&
        progress.state != MicroCompetencyState.mastered) {
      final percent = (progress.independentAccuracy * 100).round();
      return MicroEvidenceConfidence(
        level: MicroEvidenceConfidenceLevel.building,
        detail:
            'Es gibt selbstständige Evidenz ($percent % gewichtet richtig, ${progress.independentTaskVariety} unterschiedliche Aufgaben), aber noch nicht genug stabile und vielfältige Nachweise für eine belastbare Erhaltungsprognose.',
      );
    }

    final reviewDueAt = nextReviewDueAt(id);
    final transferDueAt = nextTransferDueAt(id);
    final reviewDue = reviewDueAt != null && !reviewDueAt.isAfter(reference);
    final transferDue = transferDueAt != null && !transferDueAt.isAfter(reference);
    if (reviewDue || transferDue) {
      final due = <String>[];
      if (reviewDue) due.add('Abstandskontrolle');
      if (transferDue) due.add('Transfer');
      return MicroEvidenceConfidence(
        level: MicroEvidenceConfidenceLevel.maintenanceDue,
        detail:
            '${due.join(' und ')} ${due.length == 1 ? 'ist' : 'sind'} jetzt fällig. Das ist kein automatischer Rückschritt, sondern eine gezielte Aktualitätsprüfung.',
      );
    }

    return MicroEvidenceConfidence(
      level: MicroEvidenceConfidenceLevel.current,
      detail: progress.state == MicroCompetencyState.mastered
          ? 'Selbstständige Basis, Abstand und Transfer sind aktuell belastbar belegt.'
          : 'Die selbstständige Basis ist aktuell belastbar; geplante Bestätigungen sind noch nicht fällig.',
    );
  }

  String microStabilityScheduleText(
    MicroCompetencyId id, {
    DateTime? now,
  }) {
    final progress = microCompetencyProgress(id);
    if (progress.state != MicroCompetencyState.secure &&
        progress.state != MicroCompetencyState.mastered) {
      return 'Noch kein Erhaltungsplan: Erst wenn der Teilschritt sicher ist, plant Rechenblitz Abstand und Transfer gezielt ein.';
    }
    final reference = now ?? DateTime.now();
    String dueText(DateTime? due, String noun) {
      if (due == null) return '$noun noch nicht planbar';
      if (!due.isAfter(reference)) return '$noun jetzt fällig';
      final referenceDay = DateTime(reference.year, reference.month, reference.day);
      final dueDay = DateTime(due.year, due.month, due.day);
      final days = dueDay.difference(referenceDay).inDays;
      if (days <= 0) return '$noun später heute';
      if (days == 1) return '$noun morgen';
      return '$noun in $days Tagen';
    }

    final review = dueText(nextReviewDueAt(id), 'Abstandskontrolle');
    final transfer = dueText(nextTransferDueAt(id), 'Transfer');
    return '$review · $transfer. Fehler oder Hilfebedarf verkürzen den Abstand automatisch.';
  }

  MicroCompetencyProgress? dueReviewMicroCompetency({
    DateTime? now,
    Iterable<MicroCompetencyId> excluding = const <MicroCompetencyId>[],
  }) {
    final blocked = excluding.toSet();
    final reference = now ?? DateTime.now();
    final secure = microCompetenciesForGrade()
        .where(
          (progress) {
            if (blocked.contains(progress.definition.id) ||
                !_microCompetencyIsUnlocked(progress.definition.id) ||
                progress.lastSeen == null ||
                (progress.state != MicroCompetencyState.secure &&
                    progress.state != MicroCompetencyState.mastered)) {
              return false;
            }
            final dueAt = nextReviewDueAt(progress.definition.id);
            return dueAt != null && !dueAt.isAfter(reference);
          },
        )
        .toList()
      ..sort((a, b) {
        final aUnstable = _latestSourceEvidenceIsUnstable(
          a.definition.id,
          MicroEvidenceSource.review,
        );
        final bUnstable = _latestSourceEvidenceIsUnstable(
          b.definition.id,
          MicroEvidenceSource.review,
        );
        if (aUnstable != bUnstable) return aUnstable ? -1 : 1;
        final varietyOrder = a.reviewIndependentTaskVariety
            .compareTo(b.reviewIndependentTaskVariety);
        if (varietyOrder != 0) return varietyOrder;
        return a.lastSeen!.compareTo(b.lastSeen!);
      });
    return secure.isEmpty ? null : secure.first;
  }

  MicroCompetencyProgress? transferCandidateMicroCompetency({
    DateTime? now,
    bool respectSchedule = false,
    MicroCompetencyId? excluding,
    Iterable<MicroCompetencyId> excludingAny = const <MicroCompetencyId>[],
  }) {
    final blocked = <MicroCompetencyId>{...excludingAny};
    if (excluding != null) blocked.add(excluding);
    final reference = now ?? DateTime.now();
    final candidates = microCompetenciesForGrade()
        .where(
          (progress) {
            if (blocked.contains(progress.definition.id) ||
                !_microCompetencyIsUnlocked(progress.definition.id) ||
                (progress.state != MicroCompetencyState.secure &&
                    progress.state != MicroCompetencyState.mastered)) {
              return false;
            }
            if (!respectSchedule) return true;
            final dueAt = nextTransferDueAt(progress.definition.id);
            return dueAt != null && !dueAt.isAfter(reference);
          },
        )
        .toList()
      ..sort((a, b) {
        final aUnstable = _latestSourceEvidenceIsUnstable(
          a.definition.id,
          MicroEvidenceSource.transfer,
        );
        final bUnstable = _latestSourceEvidenceIsUnstable(
          b.definition.id,
          MicroEvidenceSource.transfer,
        );
        if (aUnstable != bUnstable) return aUnstable ? -1 : 1;
        final varietyOrder = a.transferIndependentTaskVariety
            .compareTo(b.transferIndependentTaskVariety);
        if (varietyOrder != 0) return varietyOrder;
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

  bool _prerequisiteIsReady(MicroCompetencyId id) {
    final progress = microCompetencyProgress(id);
    return (progress.state == MicroCompetencyState.secure ||
            progress.state == MicroCompetencyState.mastered) &&
        !_latestBasisEvidenceIsUnstable(id);
  }

  bool _hasStrongIndependentHistory(MicroCompetencyId id) {
    final progress = microCompetencyProgress(id);
    return _evidenceAtLeast(
          progress.independentEvidence,
          _secureIndependentEvidence,
        ) &&
        progress.independentAccuracy >= _secureIndependentAccuracy;
  }

  bool _prerequisiteTreeHasExplicitWeakEvidence(
    MicroCompetencyId id, [
    Set<MicroCompetencyId>? visiting,
  ]) {
    final path = visiting ?? <MicroCompetencyId>{};
    if (!path.add(id)) return true;
    final progress = microCompetencyProgress(id);
    if (progress.evidence > _evidenceEpsilon && !_prerequisiteIsReady(id)) {
      path.remove(id);
      return true;
    }
    final definition = MicroCompetencyCatalog.definition(id);
    for (final prerequisite in definition.prerequisites) {
      if (_prerequisiteTreeHasExplicitWeakEvidence(prerequisite, path)) {
        path.remove(id);
        return true;
      }
    }
    path.remove(id);
    return false;
  }

  bool _competencyAndPrerequisitesReady(
    MicroCompetencyId id, [
    Set<MicroCompetencyId>? visiting,
  ]) {
    final path = visiting ?? <MicroCompetencyId>{};
    if (!path.add(id)) return false;
    if (!_prerequisiteIsReady(id)) {
      path.remove(id);
      return false;
    }
    final definition = MicroCompetencyCatalog.definition(id);
    for (final prerequisite in definition.prerequisites) {
      if (_competencyAndPrerequisitesReady(prerequisite, path)) continue;
      if (_prerequisiteTreeHasExplicitWeakEvidence(prerequisite)) {
        path.remove(id);
        return false;
      }
    }
    path.remove(id);
    return true;
  }

  bool _discoveryPrerequisitesReady(MicroCompetencyDefinition definition) =>
      definition.prerequisites.every(
        (id) => _competencyAndPrerequisitesReady(id),
      );

  bool _legacyEvidenceUnlocks(MicroCompetencyId id) {
    final definition = MicroCompetencyCatalog.definition(id);
    if (definition.prerequisites.isEmpty || !_hasStrongIndependentHistory(id)) {
      return false;
    }
    return definition.prerequisites.every(
      (prerequisite) =>
          !_prerequisiteTreeHasExplicitWeakEvidence(prerequisite),
    );
  }

  bool _microCompetencyIsUnlocked(MicroCompetencyId id) {
    final definition = MicroCompetencyCatalog.definition(id);
    return _discoveryPrerequisitesReady(definition) ||
        _legacyEvidenceUnlocks(id);
  }

  MicroCompetencyId? _nextUnmetPrerequisite(
    MicroCompetencyId id,
    Set<MicroCompetencyId> visiting,
  ) {
    if (!visiting.add(id)) return null;
    final definition = MicroCompetencyCatalog.definition(id);
    for (final prerequisite in definition.prerequisites) {
      if (_competencyAndPrerequisitesReady(prerequisite)) continue;
      final deeper = _nextUnmetPrerequisite(prerequisite, visiting);
      if (deeper != null) {
        visiting.remove(id);
        return deeper;
      }
      visiting.remove(id);
      return prerequisite;
    }
    visiting.remove(id);
    return null;
  }

  MicroCompetencyUnlockStatus microCompetencyUnlockStatus(
    MicroCompetencyId id,
  ) {
    final definition = MicroCompetencyCatalog.definition(id);
    final prerequisites = definition.prerequisites
        .map(MicroCompetencyCatalog.definition)
        .toList(growable: false);
    final strictPrerequisitesReady = _discoveryPrerequisitesReady(definition);
    final legacyUnlocked = !strictPrerequisitesReady && _legacyEvidenceUnlocks(id);
    final unmetIds = legacyUnlocked
        ? const <MicroCompetencyId>[]
        : definition.prerequisites
            .where(
              (prerequisite) =>
                  !_competencyAndPrerequisitesReady(prerequisite),
            )
            .toList(growable: false);
    final unmet = unmetIds
        .map(MicroCompetencyCatalog.definition)
        .toList(growable: false);
    final nextId = legacyUnlocked
        ? null
        : _nextUnmetPrerequisite(id, <MicroCompetencyId>{});
    final next = nextId == null ? null : MicroCompetencyCatalog.definition(nextId);

    final reason = prerequisites.isEmpty
        ? 'Dieser Lernschritt hat keine vorgelagerten Pflicht-Grundlagen.'
        : legacyUnlocked
            ? 'Dieser Lernschritt wurde bereits mehrfach selbstständig sicher gezeigt. Ältere, noch nicht separat protokollierte Grundlagen gelten deshalb hier als bestätigt.'
            : unmet.isEmpty
                ? 'Alle ${prerequisites.length} benötigten Grundlagen sind aktuell sicher.'
                : next == null
                    ? 'Vor diesem Lernschritt müssen zuerst die benötigten Grundlagen sicher werden.'
                    : unmet.length == 1
                        ? 'Vor „${definition.label}“ braucht es zuerst „${unmet.first.label}“. Als Nächstes üben wir „${next.label}“.'
                        : 'Vor „${definition.label}“ fehlen noch ${unmet.length} Grundlagen. Als Nächstes üben wir „${next.label}“.';

    return MicroCompetencyUnlockStatus(
      definition: definition,
      prerequisites: prerequisites,
      unmetPrerequisites: unmet,
      nextRequired: next,
      reason: reason,
    );
  }

  MicroCompetencyProgress? nextNewMicroCompetency({
    Iterable<MicroCompetencyId> excluding = const <MicroCompetencyId>[],
  }) {
    final blocked = excluding.toSet();
    final preferred = recommendedMode();
    final definitions =
        MicroCompetencyCatalog.forContext(gradeLevel, numberRange).where(
      (definition) =>
          !blocked.contains(definition.id) &&
          _discoveryPrerequisitesReady(definition),
    );
    for (final definition in definitions) {
      final progress = microCompetencyProgress(definition.id);
      if (progress.state == MicroCompetencyState.newSkill &&
          definition.preferredMode == preferred) {
        return progress;
      }
    }
    for (final definition in definitions) {
      final progress = microCompetencyProgress(definition.id);
      if (progress.state == MicroCompetencyState.newSkill) return progress;
    }
    return null;
  }

  String microFocusReason() {
    final focus = currentMicroFocus();
    if (focus == null) {
      final fluency = fluencyFocusMicroCompetency();
      if (fluency != null) {
        return fluency.fluencyState == MicroFluencyState.building
            ? '„${fluency.definition.label}“ ist fachlich bereits sicher. Als nächstes lohnt sich kurze Automatisierung ohne Zeitdruck; die Zeitmessung läuft nur im Hintergrund.'
            : '„${fluency.definition.label}“ ist fachlich bereits sicher. Für die Automatisierung fehlen noch einige unverzerrte Zeitmessungen.';
      }
      return 'Noch keine einzelne Teilkompetenz ist klar auffällig. '
          'Weitere abwechslungsreiche Aufgaben machen die Lernkarte genauer.';
    }
    final guided = guidedStepFocus();
    if (guided != null && guided.competencyId == focus.definition.id) {
      return 'In der geführten Hilfe war „${guided.label}“ wiederholt unsicher: '
          '${guided.incorrectFirstAttempts} von ${guided.observations} ersten Versuchen waren falsch. '
          'Deshalb übt Rechenblitz gezielt „${focus.definition.label}“.';
    }
    if (!focus.hasIndependentBasisEvidence) {
      final blockedDependent =
          _blockedDependentWaitingFor(focus.definition.id);
      if (blockedDependent != null) {
        return '„${focus.definition.label}“ kommt zuerst, weil „${blockedDependent.definition.label}“ darauf aufbaut und dort bereits Unsicherheit sichtbar war. '
            'Rechenblitz stärkt deshalb zunächst diese Voraussetzung.';
      }
      return '„${focus.definition.label}“ ist aktuell der sinnvollste '
          'Teilschritt: ${focus.observations} passende Beobachtungen, '
          'aber noch keine selbstständige Basisbeobachtung.';
    }
    if (_latestBasisEvidenceIsUnstable(focus.definition.id)) {
      return '„${focus.definition.label}“ war bereits weiter, brauchte aber '
          'in der letzten Gesamtaufgabe Hilfe oder war dort noch falsch. '
          'Deshalb prüft Rechenblitz diesen Lernschritt jetzt erneut selbstständig.';
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
    final stepRecovery = independentStepRecoveryFocus(now: now);
    final learningFocus = stepRecovery == null
        ? currentMicroFocus()
        : microCompetencyProgress(stepRecovery.competencyId);
    final preFocusReview = learningFocus == null
        ? dueReviewMicroCompetency(now: now)
        : null;
    final preFocusTransfer = learningFocus == null
        ? transferCandidateMicroCompetency(
            now: now,
            respectSchedule: true,
            excluding: preFocusReview?.definition.id,
          )
        : null;
    final fluencyFocus = stepRecovery == null && learningFocus == null
        ? fluencyFocusMicroCompetency(
            excluding: <MicroCompetencyId>[
              ?preFocusReview?.definition.id,
              ?preFocusTransfer?.definition.id,
            ],
          )
        : null;
    final microFocus = learningFocus ?? fluencyFocus;
    final isFluencyFocus = learningFocus == null && fluencyFocus != null;
    final guidedFocus = guidedStepFocus();
    final focusTarget = microFocus?.definition.id;

    final reviewMicro = dueReviewMicroCompetency(
      now: now,
      excluding: <MicroCompetencyId>[?focusTarget],
    );
    final reviewTarget = reviewMicro?.definition.id;

    final protectedBeforeTransfer = <MicroCompetencyId>{
      ?focusTarget,
      ?reviewTarget,
    };
    final transferMicro = transferCandidateMicroCompetency(
      now: now,
      respectSchedule: true,
      excludingAny: protectedBeforeTransfer,
    );
    final transferTarget = transferMicro?.definition.id;

    final protectedBeforeWarmUp = <MicroCompetencyId>{
      ...protectedBeforeTransfer,
      ?transferTarget,
    };
    final gradeBridgeMicro = gradeBridgeCandidateMicroCompetency(
      excludingAny: protectedBeforeWarmUp,
    );
    final rangeBridgeMicro = gradeBridgeMicro == null
        ? rangeBridgeCandidateMicroCompetency(
            excludingAny: protectedBeforeWarmUp,
          )
        : null;
    final bridgeMicro = gradeBridgeMicro ?? rangeBridgeMicro;
    final warmUpMicro = bridgeMicro ?? warmUpMicroCompetency(
      excluding: protectedBeforeWarmUp,
    );
    final warmUpTarget = warmUpMicro?.definition.id;

    final protectedBeforeMaintenance = <MicroCompetencyId>{
      ...protectedBeforeWarmUp,
      ?warmUpTarget,
    };
    final maintenanceMicro = reviewMicro == null
        ? maintenanceMicroCompetency(excluding: protectedBeforeMaintenance)
        : null;
    final maintenanceTarget = maintenanceMicro?.definition.id;

    final protectedBeforeDiscovery = <MicroCompetencyId>{
      ...protectedBeforeMaintenance,
      ?maintenanceTarget,
    };
    final newMicro = transferTarget == null
        ? nextNewMicroCompetency(excluding: protectedBeforeDiscovery)
        : null;
    final discoveryTarget = newMicro?.definition.id;

    var focus =
        microFocus?.definition.preferredMode ?? recommendedMode();
    final genericWarmUp = gradeLevel.index >= GradeLevel.third.index
        ? TrainingMode.mixed
        : TrainingMode.practice;
    if (!isFluencyFocus &&
        (focus == genericWarmUp ||
            focus == TrainingMode.speed ||
            focus == TrainingMode.tempo ||
            focus == TrainingMode.blitz)) {
      for (final candidate in learningModesForGrade(gradeLevel)) {
        if (candidate == genericWarmUp ||
            !_modeHasUnlockedMicroCompetency(candidate)) {
          continue;
        }
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

    final warmUpMode = warmUpMicro?.definition.preferredMode ?? genericWarmUp;
    final reviewMode = reviewMicro?.definition.preferredMode ??
        maintenanceMicro?.definition.preferredMode ??
        genericWarmUp;

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

    final eligibleTransferCandidates = transferCandidates
        .where(_modeHasUnlockedMicroCompetency)
        .toList(growable: false);
    final fallbackTransferCandidates = eligibleTransferCandidates.isEmpty
        ? <TrainingMode>[genericWarmUp]
        : eligibleTransferCandidates;
    final blockedFallbackModes = <TrainingMode>{
      focus,
      warmUpMode,
      reviewMode,
    };
    TrainingMode transfer = fallbackTransferCandidates.first;
    var lowestScore = 2.0;
    var foundDistinctFallback = false;
    for (final mode in fallbackTransferCandidates) {
      if (blockedFallbackModes.contains(mode)) continue;
      final progress = competencyProgress(mode);
      final score = progress.tasks == 0 ? -1.0 : progress.accuracy;
      if (!foundDistinctFallback || score < lowestScore) {
        foundDistinctFallback = true;
        lowestScore = score;
        transfer = mode;
      }
    }
    if (!foundDistinctFallback) {
      for (final mode in fallbackTransferCandidates) {
        if (mode == focus) continue;
        final progress = competencyProgress(mode);
        final score = progress.tasks == 0 ? -1.0 : progress.accuracy;
        if (score < lowestScore) {
          lowestScore = score;
          transfer = mode;
        }
      }
    }

    final effectiveReviewTarget = reviewTarget ?? maintenanceTarget;

    return [
      GuidedRoundSegment(
        role: GuidedRoundRole.warmUp,
        mode: warmUpMode,
        tasks: 2,
        reason: gradeBridgeMicro != null
            ? '„${gradeBridgeMicro.definition.label}“ war in ${gradeBridgeStatus().previousGrade!.label} stabil. Zwei Aufgaben prüfen jetzt, ob die Grundlage auch in ${gradeLevel.label} selbstständig trägt.'
            : rangeBridgeMicro != null
                ? '„${rangeBridgeMicro.definition.label}“ war im vorherigen Zahlenraum stabil. Zwei Aufgaben prüfen jetzt, ob die Grundlage auch im Zahlenraum ${numberRange.label} selbstständig trägt.'
                : warmUpTarget == null
                    ? 'Mit vertrauten Grundlagen ruhig ankommen.'
                    : 'Mit „${warmUpMicro!.definition.label}“ ruhig ankommen; diese sichere Kompetenz war länger nicht im Mittelpunkt.',
        targetCompetency: warmUpTarget,
        rangeBridge: rangeBridgeMicro != null,
        gradeBridge: gradeBridgeMicro != null,
      ),
      GuidedRoundSegment(
        role: GuidedRoundRole.focus,
        mode: focus,
        tasks: stepRecovery == null ? 5 : 2,
        reason: stepRecovery != null
            ? 'Nach der kurzen Arbeit an „${stepRecovery.label}“ reichen zwei passende Gesamtaufgaben, damit die Runde kompakt bleibt.'
            : isFluencyFocus
                ? fluencyFocus.fluencyState == MicroFluencyState.building
                    ? '„${fluencyFocus.definition.label}“ ist fachlich sicher. Jetzt folgen echte Grundaufgaben ohne Zeitdruck, damit die Automatisierung weiterwächst.'
                    : '„${fluencyFocus.definition.label}“ ist fachlich sicher. Einige Grundaufgaben erfassen jetzt erstmals die Automatisierung; die Zeit läuft nur im Hintergrund.'
                : microFocus == null
                    ? 'Das ist heute das wichtigste Lernziel.'
                    : guidedFocus != null &&
                        guidedFocus.competencyId == microFocus.definition.id
                    ? 'In der Hilfe war „${guidedFocus.label}“ wiederholt unsicher. Deshalb üben wir gezielt „${microFocus.definition.label}“ und nehmen die Hilfe schrittweise zurück.'
                    : _blockedDependentWaitingFor(microFocus.definition.id) !=
                            null
                        ? '„${microFocus.definition.label}“ kommt zuerst, weil ein bereits auffälliger nächster Lernschritt darauf aufbaut.'
                        : 'Heute üben wir gezielt: ${microFocus.definition.label}.',
        targetCompetency: focusTarget,
        fluencyEmphasis: isFluencyFocus,
        scaffoldFading: stepRecovery == null &&
            guidedFocus != null &&
            microFocus != null &&
            guidedFocus.competencyId == microFocus.definition.id,
      ),
      GuidedRoundSegment(
        role: GuidedRoundRole.review,
        mode: reviewMode,
        tasks: 3,
        reason: reviewTarget != null
            ? '„${reviewMicro!.definition.label}“ wird nach zeitlichem Abstand erneut geprüft.'
            : maintenanceTarget != null
                ? '„${maintenanceMicro!.definition.label}“ ist sicher und wird zur Erhaltung abwechslungsreich aufgefrischt.'
                : 'Eine wichtige Grundlage wird wiederholt.',
        targetCompetency: effectiveReviewTarget,
        reviewEmphasis: reviewTarget != null,
      ),
      GuidedRoundSegment(
        role: GuidedRoundRole.apply,
        mode: transferTarget != null
            ? transferModeFor(transferTarget)
            : discoveryTarget != null
                ? newMicro!.definition.preferredMode
                : transfer,
        tasks: 2,
        reason: transferTarget != null
            ? 'Zum Schluss „${transferMicro!.definition.label}“ in einer veränderten Aufgabe anwenden.'
            : discoveryTarget != null
                ? 'Zum Schluss „${newMicro!.definition.label}“ vorsichtig entdecken; die nötigen Grundlagen sind bereits stabil.'
                : 'Zum Schluss mit einer anderen Aufgabenart abwechslungsreich üben.',
        targetCompetency: transferTarget ?? discoveryTarget,
        transferEmphasis: transferTarget != null,
      ),
    ];
  }

  GuidedRoundAdaptation adaptMyRoundAfterSegment({
    required List<GuidedRoundSegment> current,
    required Set<GuidedRoundRole> completedRoles,
    Map<GuidedRoundRole, int> completedTaskCounts = const <GuidedRoundRole, int>{},
    required GuidedRoundSegment completedSegment,
    required TrainingSessionResult result,
    DateTime? now,
  }) {
    final updated = buildMyRound(now: now);
    var merged = GuidedRoundOrchestrator.mergeRemaining(
      current: current,
      updated: updated,
      completedRoles: completedRoles,
      completedTaskCounts: completedTaskCounts,
    );

    GuidedRoundSegment? nextOpen(List<GuidedRoundSegment> source) {
      for (final segment in source) {
        if (!completedRoles.contains(segment.role)) return segment;
      }
      return null;
    }

    final previousNext = nextOpen(current);
    final updatedNext = nextOpen(merged);
    final completedTasks = current
        .where((segment) => completedRoles.contains(segment.role))
        .fold<int>(
          0,
          (sum, segment) =>
              sum + (completedTaskCounts[segment.role] ?? segment.tasks),
        );
    final struggling = result.total >= 2 &&
        (result.accuracy < 0.60 ||
            (result.incorrectAttempts >= 2 && result.accuracy < 0.75));

    if (struggling) {
      final budget = completedTasks >= 9 ? completedTasks : 9;
      merged = GuidedRoundOrchestrator.mergeRemaining(
        current: current,
        updated: updated,
        completedRoles: completedRoles,
        completedTaskCounts: completedTaskCounts,
        regularTaskBudget: budget,
      );
      return GuidedRoundAdaptation(
        plan: merged,
        kind: GuidedRoundAdaptationKind.support,
        message:
            'Der letzte Abschnitt war gerade anspruchsvoll (${(result.accuracy * 100).round()} % direkt richtig). Rechenblitz hält alle wichtigen Teile der Runde, verteilt die restlichen Aufgaben aber kompakter.',
      );
    }

    final target = completedSegment.targetCompetency;
    if (target != null &&
        result.total >= 2 &&
        result.accuracy >= 0.90 &&
        result.incorrectAttempts == 0) {
      final progress = microCompetencyProgress(target);
      final confidence = microEvidenceConfidence(target, now: now);
      final stableState = progress.state == MicroCompetencyState.secure ||
          progress.state == MicroCompetencyState.mastered;
      if (stableState &&
          confidence.level == MicroEvidenceConfidenceLevel.current) {
        final beforeTasks = merged.fold<int>(0, (sum, segment) => sum + segment.tasks);
        final trimmed = GuidedRoundOrchestrator.trimOptionalRepetition(
          plan: merged,
          completedRoles: completedRoles,
        );
        final afterTasks = trimmed.fold<int>(0, (sum, segment) => sum + segment.tasks);
        if (afterTasks < beforeTasks) {
          return GuidedRoundAdaptation(
            plan: trimmed,
            kind: GuidedRoundAdaptationKind.confirmed,
            message:
                '„${progress.definition.label}“ wurde gerade sicher und ohne Fehlversuch bestätigt. Eine nicht fällige Wiederholungsaufgabe entfällt; Abstandskontrollen und Transfer bleiben geschützt.',
          );
        }
      }
    }

    final priorityChanged = previousNext != null &&
        updatedNext != null &&
        (previousNext.targetCompetency != updatedNext.targetCompetency ||
            previousNext.mode != updatedNext.mode);
    if (priorityChanged) {
      return GuidedRoundAdaptation(
        plan: merged,
        kind: GuidedRoundAdaptationKind.reprioritized,
        message:
            'Die neuen Antworten verändern die Priorität. Als Nächstes ist jetzt „${updatedNext.mode.title}“ sinnvoller; bereits erledigte Teile bleiben unverändert.',
      );
    }

    return GuidedRoundAdaptation(
      plan: merged,
      kind: GuidedRoundAdaptationKind.steady,
      message:
          'Die neuen Antworten wurden eingerechnet. Der bisherige nächste Schritt bleibt weiterhin die sinnvollste Wahl.',
    );
  }

  GuidedRoundDecisionTrace guidedRoundDecisionTrace({
    DateTime? now,
  }) {
    final plan = buildMyRound(now: now);
    final warmUp = plan.firstWhere((segment) => segment.role == GuidedRoundRole.warmUp);
    final focus = plan.firstWhere((segment) => segment.role == GuidedRoundRole.focus);
    final review = plan.firstWhere((segment) => segment.role == GuidedRoundRole.review);
    final apply = plan.firstWhere((segment) => segment.role == GuidedRoundRole.apply);
    final selectedReviewId =
        review.reviewEmphasis ? review.targetCompetency : null;
    final selectedTransferId =
        apply.transferEmphasis ? apply.targetCompetency : null;
    final selectedDiscoveryId = apply.targetCompetency != null &&
            !apply.transferEmphasis
        ? apply.targetCompetency
        : null;
    final items = <GuidedRoundDecisionItem>[];

    if (focus.targetCompetency != null) {
      final id = focus.targetCompetency!;
      final recovery = independentStepRecoveryFocus(now: now);
      final blockedDependent = _blockedDependentWaitingFor(id);
      final kind = recovery != null && recovery.competencyId == id
          ? GuidedRoundDecisionKind.recovery
          : blockedDependent != null
              ? GuidedRoundDecisionKind.prerequisite
              : focus.fluencyEmphasis
                  ? GuidedRoundDecisionKind.fluency
                  : GuidedRoundDecisionKind.focus;
      items.add(GuidedRoundDecisionItem(
        kind: kind,
        detail: focus.reason,
        priority: 100,
        selected: true,
        competencyId: id,
      ));
    } else {
      items.add(GuidedRoundDecisionItem(
        kind: GuidedRoundDecisionKind.fallback,
        detail: focus.reason,
        priority: 100,
        selected: true,
      ));
    }

    if (review.targetCompetency != null) {
      items.add(GuidedRoundDecisionItem(
        kind: review.reviewEmphasis
            ? GuidedRoundDecisionKind.dueReview
            : GuidedRoundDecisionKind.maintenance,
        detail: review.reason,
        priority: review.reviewEmphasis ? 80 : 45,
        selected: true,
        competencyId: review.targetCompetency,
      ));
    }

    if (apply.targetCompetency != null) {
      items.add(GuidedRoundDecisionItem(
        kind: apply.transferEmphasis
            ? GuidedRoundDecisionKind.dueTransfer
            : GuidedRoundDecisionKind.discovery,
        detail: apply.reason,
        priority: apply.transferEmphasis ? 70 : 40,
        selected: true,
        competencyId: apply.targetCompetency,
      ));
    }

    if (warmUp.targetCompetency != null) {
      items.add(GuidedRoundDecisionItem(
        kind: warmUp.gradeBridge
            ? GuidedRoundDecisionKind.gradeBridge
            : warmUp.rangeBridge
                ? GuidedRoundDecisionKind.rangeBridge
                : GuidedRoundDecisionKind.maintenance,
        detail: warmUp.reason,
        priority: warmUp.gradeBridge ? 65 : warmUp.rangeBridge ? 60 : 30,
        selected: true,
        competencyId: warmUp.targetCompetency,
      ));
    }

    final dueReview = dueReviewMicroCompetency(now: now);
    if (dueReview != null && dueReview.definition.id != selectedReviewId) {
      items.add(GuidedRoundDecisionItem(
        kind: GuidedRoundDecisionKind.dueReview,
        detail: '„${dueReview.definition.label}“ wäre ebenfalls für eine Abstandskontrolle fällig, wurde aber von einer höheren oder bereits belegten Rundenpriorität verdrängt.',
        priority: 80,
        selected: false,
        competencyId: dueReview.definition.id,
      ));
    }

    final dueTransfer = transferCandidateMicroCompetency(
      now: now,
      respectSchedule: true,
    );
    if (dueTransfer != null && dueTransfer.definition.id != selectedTransferId) {
      items.add(GuidedRoundDecisionItem(
        kind: GuidedRoundDecisionKind.dueTransfer,
        detail: '„${dueTransfer.definition.label}“ wäre für Transfer geeignet, bleibt aber zugunsten dringenderer Evidenz in dieser Runde zurückgestellt.',
        priority: 70,
        selected: false,
        competencyId: dueTransfer.definition.id,
      ));
    }

    final fluency = fluencyFocusMicroCompetency();
    if (fluency != null && fluency.definition.id != focus.targetCompetency) {
      items.add(GuidedRoundDecisionItem(
        kind: GuidedRoundDecisionKind.fluency,
        detail: fluency.fluencyState == MicroFluencyState.building
            ? '„${fluency.definition.label}“ ist fachlich sicher, braucht aber noch flüssigeren Abruf bei Grundaufgaben. Die Automatisierung wartet hinter dringenderem Verständnis, fälliger Wiederholung oder Transfer.'
            : '„${fluency.definition.label}“ ist fachlich sicher, hat aber noch zu wenige unverzerrte Grundaufgaben aus normalen Übungsrunden. Die Automatisierung wird später im Hintergrund ergänzt.',
        priority: 50,
        selected: false,
        competencyId: fluency.definition.id,
      ));
    }

    final discovery = nextNewMicroCompetency();
    if (discovery != null && discovery.definition.id != selectedDiscoveryId) {
      items.add(GuidedRoundDecisionItem(
        kind: GuidedRoundDecisionKind.discovery,
        detail: '„${discovery.definition.label}“ könnte als neuer Teilschritt beginnen, wartet aber bis Fokus, Erhaltung oder fällige Nachweise bedient sind.',
        priority: 40,
        selected: false,
        competencyId: discovery.definition.id,
      ));
    }

    items.sort((a, b) {
      final selectedOrder = (b.selected ? 1 : 0).compareTo(a.selected ? 1 : 0);
      if (selectedOrder != 0) return selectedOrder;
      return b.priority.compareTo(a.priority);
    });
    return GuidedRoundDecisionTrace(items: items);
  }

  MicroCompetencyProgress? parentPriorityMicroCompetency({
    DateTime? now,
  }) {
    final hasCurrentMicroEvidence = microObservations.any(
      (entry) =>
          entry.gradeLevel == gradeLevel &&
          entry.numberRange == numberRange,
    );
    final hasCurrentHistory = history.any(
      (entry) =>
          entry.gradeLevel == gradeLevel &&
          entry.numberRange == numberRange,
    );
    if (!hasCurrentMicroEvidence && hasCurrentHistory) return null;

    final focus = currentMicroFocus();
    if (focus != null) return focus;

    final review = dueReviewMicroCompetency(now: now);
    if (review != null) return review;

    final transfer = transferCandidateMicroCompetency(
      now: now,
      respectSchedule: true,
      excluding: review?.definition.id,
    );
    if (transfer != null) return transfer;

    final fluency = fluencyFocusMicroCompetency();
    if (fluency != null) return fluency;

    return nextNewMicroCompetency() ?? strongestMicroCompetency();
  }

  String _masteryMissingText(MicroCompetencyProgress progress) {
    final missing = <String>[];
    if (!_evidenceAtLeast(
      progress.independentEvidence,
      _secureIndependentEvidence,
    )) {
      missing.add('mehr selbstständige Lösungen');
    } else if (progress.independentTaskVariety < _secureIndependentTaskVariety) {
      missing.add('mindestens $_secureIndependentTaskVariety unterschiedliche selbstständige Aufgaben');
    } else if (progress.independentAccuracy < _secureIndependentAccuracy) {
      missing.add('eine stabilere selbstständige Trefferquote');
    } else {
      final basisUnstable =
          _latestBasisEvidenceIsUnstable(progress.definition.id);
      if (basisUnstable) {
        missing.add(
          'eine erneute selbstständige Gesamtaufgabe nach dem letzten unsicheren Versuch',
        );
      } else if (!_evidenceAtLeast(
            progress.independentEvidence,
            _masteredIndependentEvidence,
          ) ||
          progress.independentAccuracy < _masteredIndependentAccuracy ||
          progress.independentTaskVariety < _masteredIndependentTaskVariety) {
        missing.add('eine noch stärkere und vielfältigere selbstständige Basis');
      }
      final reviewUnstable = _latestSourceEvidenceIsUnstable(
        progress.definition.id,
        MicroEvidenceSource.review,
      );
      if (reviewUnstable) {
        missing.add(
          'eine erneute selbstständige Abstandskontrolle nach dem letzten unsicheren Versuch',
        );
      } else if (!_evidenceAtLeast(
            progress.reviewIndependentEvidence,
            _masteredReviewEvidence,
          ) ||
          progress.reviewIndependentAccuracy < _masteredReviewAccuracy ||
          progress.reviewIndependentTaskVariety < _masteredReviewTaskVariety) {
        missing.add('ein stabiler Nachweis nach zeitlichem Abstand mit unterschiedlichen Aufgaben');
      }
      final transferUnstable = _latestSourceEvidenceIsUnstable(
        progress.definition.id,
        MicroEvidenceSource.transfer,
      );
      if (transferUnstable) {
        missing.add(
          'eine erneute selbstständige Transferaufgabe nach dem letzten unsicheren Versuch',
        );
      } else if (!_evidenceAtLeast(
            progress.transferIndependentEvidence,
            _masteredTransferEvidence,
          ) ||
          progress.transferIndependentAccuracy < _masteredTransferAccuracy ||
          progress.transferIndependentTaskVariety < _masteredTransferTaskVariety) {
        missing.add('ein stabiler selbstständiger Transfer in unterschiedlichen Aufgaben');
      }
    }
    if (missing.isEmpty) return 'kein weiterer Mastery-Nachweis';
    if (missing.length == 1) return missing.first;
    return '${missing.take(missing.length - 1).join(', ')} und ${missing.last}';
  }

  String _parentMasteryText(MicroCompetencyProgress progress) {
    final label = progress.definition.label;
    if (progress.state == MicroCompetencyState.secure &&
        _latestBasisEvidenceIsUnstable(progress.definition.id)) {
      return '„$label“ war bereits „Sicher“, brauchte aber in der letzten '
          'Gesamtaufgabe Hilfe oder war dort noch falsch. Für „Gemeistert“ '
          'braucht es jetzt wieder eine selbstständige Bestätigung.';
    }
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
        '„$label“ ist „Gemeistert“: eine vielfältige selbstständige Basis, erneutes Können mit unterschiedlichen Aufgaben nach Abstand und selbstständiger Transfer sind im aktuellen Zahlenraum belegt.',
    };
  }

  String _parentEvidenceText(MicroCompetencyProgress progress) {
    final matching = _sortedMicroObservationsFor(progress.definition.id);
    final relevant = <MicroCompetencyObservation>[
      ...matching
          .where(
            (entry) =>
                entry.source != MicroEvidenceSource.independentStep &&
                entry.source != MicroEvidenceSource.guidedStep,
          )
          .take(24),
      ...matching
          .where((entry) => entry.source == MicroEvidenceSource.independentStep)
          .take(12),
      ...matching
          .where((entry) => entry.source == MicroEvidenceSource.guidedStep)
          .take(12),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
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
    final independentStepCount = relevant
        .where((entry) => entry.source == MicroEvidenceSource.independentStep)
        .length;
    final guidedStepCount = relevant
        .where((entry) => entry.source == MicroEvidenceSource.guidedStep)
        .length;
    final independentPercent =
        (progress.independentAccuracy * 100).round();
    final guidedFocus = guidedStepFocus();

    final parts = <String>[
      '${relevant.length} passende Beobachtungen',
      '$independentCount ohne Hilfe',
      '${progress.independentTaskVariety} unterschiedliche Basisaufgaben',
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
    if (independentStepCount > 0) {
      parts.add('$independentStepCount Teilfragen im Aufgabenfluss');
    }
    if (guidedStepCount > 0) {
      parts.add('$guidedStepCount geführte Zwischenschritte');
    }

    final guidedDetail = guidedFocus != null &&
            guidedFocus.competencyId == progress.definition.id
        ? ' Beim geführten Zwischenschritt „${guidedFocus.label}“ waren ${guidedFocus.incorrectFirstAttempts} von ${guidedFocus.observations} ersten Versuchen falsch.'
        : '';

    final independentDetail = progress.independentEvidence <= _evidenceEpsilon
        ? 'Für selbstständige Basisaufgaben liegt noch keine auswertbare Beobachtung vor.'
        : 'Bei selbstständigen Basisaufgaben liegt die gewichtete Sicherheit bei $independentPercent %.';
    final fluencyDetail = progress.fluencyState == MicroFluencyState.notApplicable
        ? ''
        : accessibilityPreferences.readAloud
            ? ' Die Automatisierungsmessung ist pausiert, solange Vorlesen aktiviert ist. Die fachliche Sicherheit wird davon unabhängig weiter bewertet.'
            : switch (progress.fluencyState) {
                MicroFluencyState.notApplicable => '',
                MicroFluencyState.notMeasured =>
                  ' Für die Automatisierung fehlen noch genug unverzerrte Grundaufgaben aus normalen Übungsrunden ohne Countdown.',
                MicroFluencyState.building =>
                  ' Die Grundaufgaben sind inhaltlich getrennt bewertet; im aktuellen Automatisierungsfenster sind ${(progress.fluencyAccuracy * 100).round()} % richtig bei ${progress.fluencyTaskVariety} unterschiedlichen Aufgaben, typisch ${(progress.typicalFluencyResponseMs / 1000).toStringAsFixed(1)} s.',
                MicroFluencyState.fluent =>
                  ' Die Grundaufgaben werden zusätzlich flüssig abgerufen: ${(progress.fluencyAccuracy * 100).round()} % richtig bei ${progress.fluencyTaskVariety} unterschiedlichen Aufgaben, typisch ${(progress.typicalFluencyResponseMs / 1000).toStringAsFixed(1)} s.',
              };

    return '${parts.join(' · ')}. '
        '$independentDetail$guidedDetail$fluencyDetail '
        'Die Einschätzung bezieht sich nur auf die in Rechenblitz bearbeiteten Aufgaben im aktuellen Profil, in ${gradeLevel.label} und im Zahlenraum ${numberRange.label}.';
  }

  String _parentSelectionText({
    DateTime? now,
  }) {
    final plan = buildMyRound(now: now);
    final warmUp = plan[0];
    final focus = plan[1];
    final review = plan[2];
    final transfer = plan[3];
    final guidedFocus = guidedStepFocus();
    final parts = <String>[];

    if (warmUp.gradeBridge && warmUp.targetCompetency != null) {
      final label =
          MicroCompetencyCatalog.definition(warmUp.targetCompetency!).label;
      final bridge = gradeBridgeStatus();
      parts.add(
        '${warmUp.tasks} Brückenaufgaben bestätigen „$label“ aus ${bridge.previousGrade?.label ?? 'der vorherigen Klassenstufe'} in ${gradeLevel.label}',
      );
    } else if (warmUp.rangeBridge && warmUp.targetCompetency != null) {
      final label =
          MicroCompetencyCatalog.definition(warmUp.targetCompetency!).label;
      final bridge = numberRangeBridgeStatus();
      parts.add(
        '${warmUp.tasks} Brückenaufgaben bestätigen „$label“ aus ${bridge.previousRange?.label ?? 'dem vorherigen Zahlenraum'} im Zahlenraum ${numberRange.label}',
      );
    }

    if (focus.targetCompetency != null) {
      final label =
          MicroCompetencyCatalog.definition(focus.targetCompetency!).label;
      if (guidedFocus != null &&
          guidedFocus.competencyId == focus.targetCompetency) {
        parts.add(
          '${focus.tasks} Aufgaben fokussieren „$label“, weil „${guidedFocus.label}“ in der geführten Hilfe wiederholt unsicher war; die Unterstützung wird dabei von Darstellung über Denkhinweis bis ohne Vorhilfe reduziert',
        );
      } else {
        parts.add('${focus.tasks} Aufgaben fokussieren „$label“');
      }
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
    } else if (transfer.targetCompetency != null) {
      final label =
          MicroCompetencyCatalog.definition(transfer.targetCompetency!).label;
      parts.add(
        '${transfer.tasks} Aufgaben führen vorsichtig in „$label“ ein',
      );
    }

    return '${parts.join('; ')}. '
        'So übt Rechenblitz nicht einfach den Bereich mit der niedrigsten Gesamtquote, sondern den konkreten Teilschritt und die noch fehlende Evidenzart.';
  }

  LearningCompletionInsight? learningCompletionInsight({
    required MicroCompetencyId? targetCompetency,
    bool reviewEmphasis = false,
    bool transferEmphasis = false,
    bool fluencyEmphasis = false,
  }) {
    if (targetCompetency == null) return null;
    final progress = microCompetencyProgress(targetCompetency);
    final label = progress.definition.label;

    final title = switch (progress.state) {
      MicroCompetencyState.mastered => 'Schon richtig stabil',
      MicroCompetencyState.secure => 'Das klappt schon sicher',
      MicroCompetencyState.practicing => 'Das wird gerade sicherer',
      MicroCompetencyState.discovering => 'Heute weiter verstanden',
      MicroCompetencyState.newSkill => 'Heute kennengelernt',
    };

    late final String detail;
    if (fluencyEmphasis) {
      detail = switch (progress.fluencyState) {
        MicroFluencyState.fluent =>
          '„$label“ ist fachlich sicher und die passenden Grundaufgaben sind inzwischen flüssig abrufbar.',
        MicroFluencyState.building =>
          '„$label“ ist fachlich sicher. Heute wurde der flüssige Abruf ohne Countdown weiter aufgebaut.',
        MicroFluencyState.notMeasured =>
          '„$label“ ist fachlich sicher. Rechenblitz sammelt dafür jetzt unterschiedliche Grundaufgaben zur Automatisierung – ohne Zeitdruck.',
        MicroFluencyState.notApplicable =>
          '„$label“ wurde heute weiter gefestigt.',
      };
    } else if (transferEmphasis) {
      detail = progress.hasIndependentTransferEvidence
          ? '„$label“ wurde heute auch in einer veränderten Aufgabe selbstständig angewendet.'
          : '„$label“ wurde heute in einer veränderten Aufgabe ausprobiert. Rechenblitz prüft den Transfer später erneut.';
    } else if (reviewEmphasis) {
      detail = progress.hasIndependentReviewEvidence
          ? '„$label“ wurde heute nach zeitlichem Abstand wieder selbstständig abgerufen.'
          : '„$label“ wurde heute nach zeitlichem Abstand wiederholt. Für eine stabile Bestätigung braucht es noch eine selbstständige Lösung.';
    } else {
      detail = switch (progress.state) {
        MicroCompetencyState.mastered =>
          '„$label“ ist mit selbstständiger Basis, Wiederholung und Transfer belegt.',
        MicroCompetencyState.secure =>
          '„$label“ gelingt in den bisherigen Aufgaben überwiegend selbstständig.',
        MicroCompetencyState.practicing =>
          '„$label“ wurde heute gezielt geübt. Rechenblitz greift den Schritt wieder auf, bis er selbstständig sicher ist.',
        MicroCompetencyState.discovering =>
          '„$label“ wird gerade aufgebaut. Hilfe und selbstständige Versuche werden dabei getrennt bewertet.',
        MicroCompetencyState.newSkill =>
          '„$label“ hat heute erste passende Aufgaben bekommen. Daraus entsteht jetzt die Lernspur.',
      };
    }

    final nextStep = switch (progress.state) {
      MicroCompetencyState.mastered =>
        'Als Nächstes reicht eine kurze Erhaltung, wenn sie wieder fällig ist.',
      MicroCompetencyState.secure =>
        progress.hasIndependentReviewEvidence && progress.hasIndependentTransferEvidence
            ? 'Als Nächstes hält Rechenblitz den Schritt mit kurzen Abständen stabil.'
            : !progress.hasIndependentReviewEvidence
                ? 'Später prüft Rechenblitz, ob der Schritt auch nach einer Pause noch sitzt.'
                : 'Als Nächstes kommt derselbe Gedanke in einer etwas anderen Aufgabe.',
      MicroCompetencyState.practicing =>
        'Meine Runde übt den Schritt weiter, bis er ohne Hilfe zuverlässig klappt.',
      MicroCompetencyState.discovering =>
        'Der nächste passende Schritt bleibt klein und baut direkt darauf auf.',
      MicroCompetencyState.newSkill =>
        'Ein paar passende Aufgaben zeigen als Nächstes, wie selbstständig der Schritt schon gelingt.',
    };

    return LearningCompletionInsight(
      title: title,
      detail: detail,
      nextStep: nextStep,
      fluency: fluencyEmphasis,
    );
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
      final guidedFocus = guidedStepFocus();
      final dueReview = dueReviewMicroCompetency(now: now);
      final transfer = transferCandidateMicroCompetency(
        now: now,
        respectSchedule: true,
        excluding: dueReview?.definition.id,
      );
      final fluency = currentFocus == null
          ? fluencyFocusMicroCompetency()
          : null;
      final isFluencyPriority =
          fluency?.definition.id == priority.definition.id;

      final strongestConfidence = strongestMicro == null
          ? null
          : microEvidenceConfidence(strongestMicro.definition.id, now: now);
      final good = strongestMicro == null
          ? 'Noch nicht genug Daten – die ersten kurzen Runden bauen die Lernkarte auf.'
          : strongestConfidence!.level ==
                  MicroEvidenceConfidenceLevel.reconfirmationNeeded
              ? '„${strongestMicro.definition.label}“ war bisher ein starker Bereich. Die neueste Evidenz braucht aber eine erneute selbstständige Bestätigung.'
              : strongestConfidence.level ==
                      MicroEvidenceConfidenceLevel.maintenanceDue
                  ? '„${strongestMicro.definition.label}“ ist bisher sicher. Eine geplante Bestätigung ist jetzt fällig, damit die Aussage aktuell bleibt.'
                  : switch (strongestMicro.state) {
                      MicroCompetencyState.mastered =>
                        '„${strongestMicro.definition.label}“ ist bereits gemeistert: selbstständige Basis, Abstand und Transfer sind aktuell belegt.',
                      MicroCompetencyState.secure =>
                        '„${strongestMicro.definition.label}“ ist aktuell sicher und gelingt in den bisherigen Aufgaben überwiegend selbstständig.',
                      _ =>
                        'Am stabilsten zeigt sich derzeit „${strongestMicro.definition.label}“ mit ${(strongestMicro.independentAccuracy * 100).round()} % gewichteter selbstständiger Sicherheit.',
                    };

      late final String focusText;
      if (currentFocus != null &&
          currentFocus.definition.id == priority.definition.id) {
        if (guidedFocus != null &&
            guidedFocus.competencyId == priority.definition.id) {
          focusText =
              'In der geführten Hilfe war „${guidedFocus.label}“ wiederholt unsicher: '
              '${guidedFocus.incorrectFirstAttempts} von ${guidedFocus.observations} ersten Versuchen waren falsch. '
              'Deshalb bekommt „${priority.definition.label}“ jetzt gezielt weitere Übung.';
        } else {
          final independentStatus = priority.independentEvidence <= _evidenceEpsilon
              ? 'Es liegen noch keine selbstständigen Basislösungen vor.'
              : 'Selbstständig ${(priority.independentAccuracy * 100).round()} % bei ${priority.independentTaskVariety} unterschiedlichen Aufgaben.';
          focusText =
              'Der konkrete Teilschritt „${priority.definition.label}“ braucht aktuell am meisten Übung. '
              'Status: ${priority.state.label}. $independentStatus';
        }
      } else if (dueReview != null &&
          dueReview.definition.id == priority.definition.id) {
        final statusText = priority.state == MicroCompetencyState.mastered
            ? 'bereits gemeistert'
            : 'bereits sicher';
        focusText =
            '„${priority.definition.label}“ ist $statusText. Jetzt soll geprüft werden, ob der Teilschritt nach zeitlichem Abstand noch selbstständig gelingt.';
      } else if (transfer != null &&
          transfer.definition.id == priority.definition.id) {
        final statusText = priority.state == MicroCompetencyState.mastered
            ? 'bereits gemeistert'
            : 'bereits sicher';
        focusText =
            '„${priority.definition.label}“ ist $statusText. Als Nächstes wird die Anwendung in einer veränderten Aufgabe geprüft.';
      } else if (isFluencyPriority) {
        final statusText = priority.state == MicroCompetencyState.mastered
            ? 'bereits gemeistert'
            : 'fachlich sicher';
        focusText = priority.fluencyState == MicroFluencyState.building
            ? '„${priority.definition.label}“ ist $statusText. Im aktuellen Automatisierungsfenster sind ${(priority.fluencyAccuracy * 100).round()} % richtig bei ${priority.fluencyTaskVariety} unterschiedlichen Aufgaben; typisch braucht der Abruf ${(priority.typicalFluencyResponseMs / 1000).toStringAsFixed(1)} s. Deshalb wird kurz ohne Zeitdruck automatisiert.'
            : '„${priority.definition.label}“ ist $statusText. Für eine belastbare Automatisierungsmessung fehlen noch unterschiedliche Grundaufgaben aus normalen Übungsrunden; Blitz und Rechencheck zählen dafür nicht. Die Zeitmessung läuft nur im Hintergrund.';
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
      if (guidedFocus != null &&
          currentFocus?.definition.id == priority.definition.id &&
          guidedFocus.competencyId == priority.definition.id) {
        action =
            'Kurze Aufgaben zu „${priority.definition.label}“ üben. Die Hilfe wird bewusst schrittweise zurückgenommen: zuerst Darstellung, dann nur Denkhinweis, danach ohne Vorhilfe. '
            'Dabei besonders auf „${guidedFocus.label}“ achten. Die Teilfragen sind ein Hinweis aus einer Hilfesituation und kein selbstständiger Leistungsnachweis.';
      } else if (diagnosticIsActive) {
        action =
            'Im selben Übungsbereich ist das Muster „${diagnostic.pattern.label}“ wiederholt aufgefallen. '
            'Das ist ein zusätzlicher Hinweis, kein Beweis für eine Ursache. '
            '${diagnostic.pattern.action}';
      } else if (dueReview != null &&
          dueReview.definition.id == priority.definition.id) {
        action =
            'Eine kurze Abstandskontrolle ohne Starthilfe reicht. Entscheidend ist, ob der Rechenweg noch selbstständig abrufbar ist.';
      } else if (transfer != null &&
          transfer.definition.id == priority.definition.id) {
        action = priority.state == MicroCompetencyState.mastered
            ? 'Zwei kurze Aufgaben in veränderter Form halten die Anwendung flexibel. Sie dienen hier dem Erhalt, nicht einem noch fehlenden Nachweis.'
            : 'Zwei kurze Aufgaben in veränderter Form prüfen, ob dieselbe mathematische Idee übertragen werden kann.';
      } else if (isFluencyPriority) {
        action = priority.state == MicroCompetencyState.mastered
            ? 'Kurze bekannte Grundaufgaben ohne Countdown lösen. Das dient der Automatisierung und dem Erhalt; Rechenblitz misst die Antwortzeit nur im Hintergrund.'
            : 'Kurze bekannte Grundaufgaben ohne Countdown lösen. Rechenblitz misst die Antwortzeit nur im Hintergrund; Verständnis und richtige Rechenwege bleiben wichtiger als Tempo.';
      } else if (priority.state == MicroCompetencyState.newSkill) {
        action =
            'Den Teilschritt zunächst mit wenigen Aufgaben vorsichtig kennenlernen; daraus entsteht erst die Beobachtungsbasis.';
      } else {
        action =
            '3–5 Minuten gezielt „${priority.definition.label}“ üben und dabei den gewählten Schul-Rechenweg nutzen.';
      }

      final masteryStatus = switch (priority.state) {
        MicroCompetencyState.mastered =>
          'Für „Gemeistert“ fehlt bei diesem Teilschritt aktuell kein weiterer Nachweis. Wiederholungen dienen dem langfristigen Erhalt.',
        MicroCompetencyState.secure =>
          'Noch nicht „Gemeistert“: Es fehlt ${_masteryMissingText(priority)}.',
        MicroCompetencyState.newSkill =>
          'Noch keine belastbare Aussage: Erst einige passende Aufgaben zeigen, wie selbstständig der Teilschritt gelingt.',
        _ =>
          'Noch nicht „Sicher“: Es fehlt ${_masteryMissingText(priority)}. Tempo ist deshalb noch zweitrangig.',
      };
      final notYet = isFluencyPriority
          ? '$masteryStatus Automatisierung wird davon getrennt bewertet und kann noch im Aufbau sein, obwohl der fachliche Stand bereits sicher oder gemeistert ist.'
          : masteryStatus;

      return ParentLearningInsight(
        good: good,
        focus: focusText,
        action: action,
        notYet: notYet,
        trend: _weeklyTrendText(),
        confidence:
            '${microEvidenceConfidence(priority.definition.id, now: now).level.label}: ${microEvidenceConfidence(priority.definition.id, now: now).detail}',
        stability: microStabilityScheduleText(priority.definition.id, now: now),
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
      confidence:
          'Noch zu wenig Daten: Mit weiteren selbstständigen Aufgaben wird die Aussagekraft automatisch genauer.',
      stability:
          'Sobald genügend selbstständige Evidenz vorliegt, plant Rechenblitz Wiederholung und Transfer mit wachsendem Abstand.',
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

  bool _modeHasUnlockedMicroCompetency(TrainingMode mode) {
    final definitions = MicroCompetencyCatalog.forContext(
      gradeLevel,
      numberRange,
    ).where((definition) => definition.preferredMode == mode).toList();
    if (definitions.isEmpty) return true;
    return definitions.any(
      (definition) => _microCompetencyIsUnlocked(definition.id),
    );
  }

  TrainingMode _upperPrimaryRecommendation() {
    final allModes = curriculumModesForGrade(gradeLevel);
    final unlockedModes = allModes
        .where(_modeHasUnlockedMicroCompetency)
        .toList(growable: false);
    final modes = unlockedModes.isEmpty ? allModes : unlockedModes;
    final allAssessmentModes = learningModesForGrade(gradeLevel);
    final unlockedAssessmentModes = allAssessmentModes
        .where(_modeHasUnlockedMicroCompetency)
        .toList(growable: false);
    final assessmentFocus = _assessmentFocusFor(
      unlockedAssessmentModes.isEmpty
          ? allAssessmentModes
          : unlockedAssessmentModes,
    );
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

  String childRecommendationText() {
    final mode = recommendedMode();
    return switch (mode) {
      TrainingMode.practice => 'Starte mit einer kurzen Übungsrunde.',
      TrainingMode.minus => 'Als Nächstes üben wir Minus noch ein bisschen.',
      TrainingMode.speed =>
        'Die Aufgaben sitzen schon gut. „Schnell rechnen“ passt jetzt.',
      TrainingMode.tempo => 'Ein kurzer „Rechencheck“ passt jetzt gut.',
      _ => 'Als Nächstes passt „${mode.title}“.',
    };
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

    final microFocus = currentMicroFocus();
    if (microFocus != null) {
      return microFocus.definition.preferredMode;
    }

    if (gradeLevel.index >= GradeLevel.third.index) {
      return _upperPrimaryRecommendation();
    }

    final allModes = learningModesForGrade(gradeLevel);
    final unlockedModes = allModes
        .where(_modeHasUnlockedMicroCompetency)
        .toList(growable: false);
    final modes = unlockedModes.isEmpty ? allModes : unlockedModes;
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

  NumberRangeLevel? _previousAvailableRange() {
    final ranges = availableRanges;
    final index = ranges.indexOf(numberRange);
    if (index <= 0) return null;
    return ranges[index - 1];
  }

  bool _stableFoundationInContext(
    MicroCompetencyId id, {
    required GradeLevel grade,
    required NumberRangeLevel range,
  }) {
    final observations = microObservations
        .where(
          (entry) =>
              entry.id == id &&
              entry.gradeLevel == grade &&
              entry.numberRange == range &&
              (entry.source == MicroEvidenceSource.practice ||
                  entry.source == MicroEvidenceSource.remediation ||
                  entry.source == MicroEvidenceSource.independentStep),
        )
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    if (observations.isEmpty) return false;

    var evidence = 0.0;
    var correctEvidence = 0.0;
    for (final observation in observations) {
      if (observation.usedHelp) continue;
      evidence += observation.evidenceWeight;
      if (observation.correct) correctEvidence += observation.evidenceWeight;
    }
    if (!_evidenceAtLeast(evidence, _secureIndependentEvidence)) return false;
    if (evidence <= _evidenceEpsilon ||
        correctEvidence / evidence < _secureIndependentAccuracy) {
      return false;
    }

    for (final observation in observations) {
      if (observation.source == MicroEvidenceSource.practice ||
          observation.source == MicroEvidenceSource.remediation) {
        return observation.correct && !observation.usedHelp;
      }
    }
    return true;
  }

  bool _stableFoundationInRange(
    MicroCompetencyId id,
    NumberRangeLevel range,
  ) =>
      _stableFoundationInContext(
        id,
        grade: gradeLevel,
        range: range,
      );

  bool _stableFoundationInGrade(
    MicroCompetencyId id,
    GradeLevel grade,
  ) {
    final all = microObservations
        .where(
          (entry) =>
              entry.id == id &&
              entry.gradeLevel == grade &&
              (entry.source == MicroEvidenceSource.practice ||
                  entry.source == MicroEvidenceSource.remediation ||
                  entry.source == MicroEvidenceSource.independentStep),
        )
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    if (all.isEmpty) return false;

    for (final observation in all) {
      if (observation.source == MicroEvidenceSource.practice ||
          observation.source == MicroEvidenceSource.remediation) {
        if (!observation.correct || observation.usedHelp) return false;
        break;
      }
    }

    final ranges = all.map((entry) => entry.numberRange).toSet().toList()
      ..sort((a, b) => b.index.compareTo(a.index));
    for (final range in ranges) {
      if (_stableFoundationInContext(id, grade: grade, range: range)) {
        return true;
      }
    }
    return false;
  }

  bool _confirmedFoundationInCurrentRange(MicroCompetencyId id) {
    final progress = microCompetencyProgress(id);
    return _evidenceAtLeast(progress.independentEvidence, 1.5) &&
        progress.independentAccuracy >= _secureIndependentAccuracy &&
        !progress.basisNeedsReconfirmation;
  }

  GradeLevel? _previousGradeLevel() {
    if (gradeLevel.index <= 0) return null;
    return GradeLevel.values[gradeLevel.index - 1];
  }

  GradeBridgeStatus gradeBridgeStatus() {
    final previous = _previousGradeLevel();
    if (previous == null) {
      return GradeBridgeStatus(
        previousGrade: null,
        currentGrade: gradeLevel,
        foundationCompetencies: const <MicroCompetencyId>[],
        confirmedCompetencies: const <MicroCompetencyId>[],
        pendingCompetencies: const <MicroCompetencyId>[],
        reason: 'In Klasse 1 gibt es keine vorherige Klassenstufe zu bestätigen.',
      );
    }

    final foundations = MicroCompetencyCatalog.forContext(gradeLevel, numberRange)
        .where(
          (definition) =>
              definition.appliesTo(previous) &&
              (definition.domain == MicroCompetencyDomain.numberSense ||
                  definition.domain == MicroCompetencyDomain.arithmetic) &&
              _rangeReadinessModes.contains(definition.preferredMode) &&
              _stableFoundationInGrade(definition.id, previous),
        )
        .map((definition) => definition.id)
        .toList(growable: false);
    final confirmed = foundations
        .where(_confirmedFoundationInCurrentRange)
        .toList(growable: false);
    final confirmedSet = confirmed.toSet();
    final pending = foundations
        .where((id) => !confirmedSet.contains(id))
        .toList(growable: false);

    final reason = foundations.isEmpty
        ? 'Aus ${previous.label} gibt es noch keine ausreichend stabile Kernkompetenz, die in ${gradeLevel.label} gezielt bestätigt werden sollte.'
        : pending.isEmpty
            ? 'Alle ${foundations.length} stabilen Grundlagen aus ${previous.label} wurden in ${gradeLevel.label} bereits selbstständig bestätigt.'
            : '${confirmed.length} von ${foundations.length} stabilen Grundlagen aus ${previous.label} wurden in ${gradeLevel.label} bestätigt. Die übrigen werden kurz mit Aufgaben der neuen Klassenstufe überprüft.';
    return GradeBridgeStatus(
      previousGrade: previous,
      currentGrade: gradeLevel,
      foundationCompetencies: foundations,
      confirmedCompetencies: confirmed,
      pendingCompetencies: pending,
      reason: reason,
    );
  }

  MicroCompetencyProgress? gradeBridgeCandidateMicroCompetency({
    Iterable<MicroCompetencyId> excludingAny = const <MicroCompetencyId>[],
  }) {
    final status = gradeBridgeStatus();
    if (!status.isActive) return null;
    final excluded = excludingAny.toSet();
    for (final id in status.pendingCompetencies) {
      if (excluded.contains(id) || !_microCompetencyIsUnlocked(id)) continue;
      return microCompetencyProgress(id);
    }
    return null;
  }

  NumberRangeBridgeStatus numberRangeBridgeStatus() {
    final previous = _previousAvailableRange();
    if (previous == null) {
      return NumberRangeBridgeStatus(
        previousRange: null,
        currentRange: numberRange,
        foundationCompetencies: const <MicroCompetencyId>[],
        confirmedCompetencies: const <MicroCompetencyId>[],
        pendingCompetencies: const <MicroCompetencyId>[],
        reason: 'Dies ist der erste verfügbare Zahlenraum; es gibt keine frühere Grundlage zu bestätigen.',
      );
    }

    final previousIds = MicroCompetencyCatalog.forContext(gradeLevel, previous)
        .map((definition) => definition.id)
        .toSet();
    final foundations = MicroCompetencyCatalog.forContext(gradeLevel, numberRange)
        .where(
          (definition) =>
              previousIds.contains(definition.id) &&
              (definition.domain == MicroCompetencyDomain.numberSense ||
                  definition.domain == MicroCompetencyDomain.arithmetic) &&
              _rangeReadinessModes.contains(definition.preferredMode) &&
              _stableFoundationInRange(definition.id, previous),
        )
        .map((definition) => definition.id)
        .toList(growable: false);
    final confirmed = foundations
        .where(_confirmedFoundationInCurrentRange)
        .toList(growable: false);
    final confirmedSet = confirmed.toSet();
    final pending = foundations
        .where((id) => !confirmedSet.contains(id))
        .toList(growable: false);

    final reason = foundations.isEmpty
        ? 'Im Zahlenraum ${previous.label} gibt es noch keine ausreichend stabile Kernkompetenz, die gezielt übernommen werden sollte.'
        : pending.isEmpty
            ? 'Alle ${foundations.length} stabilen Grundlagen aus ${previous.label} wurden im Zahlenraum ${numberRange.label} bereits selbstständig bestätigt.'
            : '${confirmed.length} von ${foundations.length} stabilen Grundlagen aus ${previous.label} wurden im Zahlenraum ${numberRange.label} bestätigt. Die übrigen werden kurz in „Meine Runde“ überprüft.';
    return NumberRangeBridgeStatus(
      previousRange: previous,
      currentRange: numberRange,
      foundationCompetencies: foundations,
      confirmedCompetencies: confirmed,
      pendingCompetencies: pending,
      reason: reason,
    );
  }

  MicroCompetencyProgress? rangeBridgeCandidateMicroCompetency({
    Iterable<MicroCompetencyId> excludingAny = const <MicroCompetencyId>[],
  }) {
    final status = numberRangeBridgeStatus();
    if (!status.isActive) return null;
    final excluded = excludingAny.toSet();
    for (final id in status.pendingCompetencies) {
      if (excluded.contains(id) || !_microCompetencyIsUnlocked(id)) continue;
      return microCompetencyProgress(id);
    }
    return null;
  }

  NumberRangeReadiness numberRangeReadiness() {
    final ranges = availableRanges;
    final currentIndex = ranges.indexOf(numberRange);
    final nextRange = currentIndex >= 0 && currentIndex + 1 < ranges.length
        ? ranges[currentIndex + 1]
        : null;
    if (nextRange == null) {
      return NumberRangeReadiness(
        status: NumberRangeReadinessStatus.maximum,
        currentRange: numberRange,
        nextRange: null,
        evidencedCore: 0,
        secureCore: 0,
        confirmedCore: 0,
        averageIndependentAccuracy: 0,
        reason: 'Für ${gradeLevel.label} ist bereits der höchste verfügbare Zahlenraum eingestellt.',
      );
    }

    final core = MicroCompetencyCatalog.forContext(gradeLevel, numberRange)
        .where(
          (definition) =>
              (definition.domain == MicroCompetencyDomain.numberSense ||
                  definition.domain == MicroCompetencyDomain.arithmetic) &&
              _rangeReadinessModes.contains(definition.preferredMode),
        )
        .map((definition) => microCompetencyProgress(definition.id))
        .toList(growable: false);
    final evidenced = core
        .where((progress) => progress.independentEvidence >= 1.5)
        .toList(growable: false);
    final secure = evidenced
        .where(
          (progress) =>
              _microCompetencyIsUnlocked(progress.definition.id) &&
              (progress.state == MicroCompetencyState.secure ||
                  progress.state == MicroCompetencyState.mastered) &&
              !progress.basisNeedsReconfirmation,
        )
        .toList(growable: false);
    final confirmed = secure
        .where(
          (progress) =>
              progress.reviewIndependentEvidence >= 0.8 ||
              progress.transferIndependentEvidence >= 0.8,
        )
        .toList(growable: false);

    var requiredEvidence = (core.length * 0.35).ceil();
    if (core.isNotEmpty && requiredEvidence < 3) {
      requiredEvidence = core.length < 3 ? core.length : 3;
    }
    if (requiredEvidence > 6) requiredEvidence = 6;
    final totalWeight = evidenced.fold<double>(
      0,
      (sum, progress) => sum + progress.independentEvidence,
    );
    final weightedCorrect = evidenced.fold<double>(
      0,
      (sum, progress) =>
          sum + progress.independentAccuracy * progress.independentEvidence,
    );
    final averageAccuracy =
        totalWeight == 0 ? 0.0 : weightedCorrect / totalWeight;
    final secureRatio =
        evidenced.isEmpty ? 0.0 : secure.length / evidenced.length;
    final requiredConfirmed = evidenced.length >= 5 ? 2 : 1;
    final hasUnstableEvidence = evidenced.any(
      (progress) =>
          progress.basisNeedsReconfirmation ||
          !_microCompetencyIsUnlocked(progress.definition.id),
    );

    if (evidenced.length < requiredEvidence || requiredEvidence == 0) {
      return NumberRangeReadiness(
        status: NumberRangeReadinessStatus.collecting,
        currentRange: numberRange,
        nextRange: nextRange,
        evidencedCore: evidenced.length,
        secureCore: secure.length,
        confirmedCore: confirmed.length,
        averageIndependentAccuracy: averageAccuracy,
        reason: 'Für eine belastbare Empfehlung fehlen noch eigenständige Beobachtungen in mehreren Kernkompetenzen.',
      );
    }

    if (hasUnstableEvidence ||
        secureRatio < 0.75 ||
        averageAccuracy < 0.85 ||
        confirmed.length < requiredConfirmed) {
      return NumberRangeReadiness(
        status: NumberRangeReadinessStatus.consolidate,
        currentRange: numberRange,
        nextRange: nextRange,
        evidencedCore: evidenced.length,
        secureCore: secure.length,
        confirmedCore: confirmed.length,
        averageIndependentAccuracy: averageAccuracy,
        reason: hasUnstableEvidence
            ? 'Mindestens eine Kernkompetenz war zuletzt wieder unsicher oder nur mit Hilfe lösbar. Der aktuelle Zahlenraum sollte zuerst stabilisiert werden.'
            : 'Der aktuelle Zahlenraum ist noch nicht breit genug selbstständig, mit Abstand oder im Transfer bestätigt.',
      );
    }

    return NumberRangeReadiness(
      status: NumberRangeReadinessStatus.ready,
      currentRange: numberRange,
      nextRange: nextRange,
      evidencedCore: evidenced.length,
      secureCore: secure.length,
      confirmedCore: confirmed.length,
      averageIndependentAccuracy: averageAccuracy,
      reason: 'Die Kernkompetenzen sind überwiegend sicher und mindestens teilweise mit Abstand oder im Transfer bestätigt. ${nextRange.label} kann sinnvoll erprobt werden.',
    );
  }

  Future<void> setGradeLevel(GradeLevel value) async {
    final gradeChanged = value != gradeLevel;
    if (gradeChanged) {
      activeTeacherAssignment = null;
      await clearAssessmentProgress();
      await clearSupportSessionProgress();
      await clearCoreTrainingSession();
    }
    await clearGuidedRoundProgress();
    gradeLevel = value;
    numberRange = value.recommendedRange;

    if (gradeChanged) {
      history = history.where((entry) => !entry.isAssessment).toList();
      await storage.saveHistory(history);
      recentTaskKeysByMode = <String, List<String>>{};
      await storage.saveTaskDiversity(recentTaskKeysByMode);
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
    activeTeacherAssignment = null;
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
      activeTeacherAssignment = null;
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
    await clearSupportSessionProgress();
    await clearCoreTrainingSession();
    methodPreferences =
        methodPreferences.copyWith(selectionPreference: value);
    notifyListeners();
    await storage.setMethodPreferences(methodPreferences);
  }

  Future<void> setSubtractionStrategy(SubtractionStrategy value) async {
    await clearSupportSessionProgress();
    await clearCoreTrainingSession();
    methodPreferences = methodPreferences.copyWith(subtraction: value);
    notifyListeners();
    await storage.setMethodPreferences(methodPreferences);
  }

  Future<void> setMultiplicationStrategy(MultiplicationStrategy value) async {
    await clearSupportSessionProgress();
    await clearCoreTrainingSession();
    methodPreferences = methodPreferences.copyWith(multiplication: value);
    notifyListeners();
    await storage.setMethodPreferences(methodPreferences);
  }

  Future<void> setWrittenSubtractionStrategy(
    WrittenSubtractionStrategy value,
  ) async {
    await clearSupportSessionProgress();
    await clearCoreTrainingSession();
    methodPreferences =
        methodPreferences.copyWith(writtenSubtraction: value);
    notifyListeners();
    await storage.setMethodPreferences(methodPreferences);
  }

  Future<void> saveLearningStartSetup({
    required String name,
    required GradeLevel grade,
    required GermanState state,
  }) async {
    await clearGuidedRoundProgress();
    await clearSupportSessionProgress();
    await clearCoreTrainingSession();
    final nextRange = grade.recommendedRange;
    final assessmentContextChanged =
        grade != gradeLevel || nextRange != numberRange;
    if (assessmentContextChanged) await clearAssessmentProgress();
    final cleanName = name.trim().isEmpty ? 'Lernprofil' : name.trim();
    gradeLevel = grade;
    numberRange = nextRange;
    methodPreferences = methodPreferences.copyWith(
      selectionPreference: MethodSelectionPreference.automatic,
    );

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
    List<AssessmentModeResult> results, {
    List<AssessmentTaskResult> taskResults = const <AssessmentTaskResult>[],
  }) async {
    final now = DateTime.now();
    history = history.where((entry) => !entry.isAssessment).toList();
    microObservations = microObservations
        .where(
          (entry) =>
              entry.source != MicroEvidenceSource.assessment ||
              entry.gradeLevel != gradeLevel ||
              entry.numberRange != numberRange,
        )
        .toList();

    for (final task in taskResults) {
      _recordMicroCompetencies(
        mode: task.mode,
        taskKey: task.taskKey,
        correct: task.correct,
        fact: task.fact,
        usedHelp: false,
        helpLevel: 0,
        methodKey: null,
        source: MicroEvidenceSource.assessment,
        onlyCompetency: task.targetCompetency,
      );
    }

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
    await storage.saveMicroCompetencyObservations(microObservations);
    await storage.saveProfiles(profiles);
    await clearAssessmentProgress();
    notifyListeners();
  }

  Future<void> completeOnboardingWithoutAssessment() async {
    await clearAssessmentProgress();
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

  Future<void> setHelpPreferences(HelpPreferences value) async {
    if (profiles.isEmpty) return;
    await clearCoreTrainingSession();
    await clearSupportSessionProgress();
    profiles = profiles
        .map(
          (profile) => profile.id == activeProfileId
              ? profile.copyWith(helpPreferences: value)
              : profile,
        )
        .toList();
    notifyListeners();
    await storage.saveProfiles(profiles);
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
    if (value != numberRange) {
      activeTeacherAssignment = null;
      await clearGuidedRoundProgress();
      await clearAssessmentProgress();
      await clearSupportSessionProgress();
      await clearCoreTrainingSession();
      recentTaskKeysByMode = <String, List<String>>{};
      await storage.saveTaskDiversity(recentTaskKeysByMode);
    }
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
    final previous = accessibilityPreferences;
    accessibilityPreferences = value;
    notifyListeners();
    await storage.setAccessibilityPreferences(value);
    if ((previous.readAloud && !value.readAloud) ||
        (previous.spokenRoundFeedback && !value.spokenRoundFeedback)) {
      await speech.stop();
    }
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

  Future<void> speakRoundFeedback(String text) async {
    if (!accessibilityPreferences.spokenRoundFeedback) return;
    await speech.speak(
      text,
      rate: accessibilityPreferences.speechRate,
    );
  }

  String roundSpokenFeedback({
    required TrainingSessionResult result,
    required MicroCompetencyId? targetCompetency,
    bool reviewEmphasis = false,
    bool transferEmphasis = false,
    bool fluencyEmphasis = false,
  }) {
    if (targetCompetency == null) {
      final activity = result.mode.title;
      if (result.accuracy >= 0.9 && result.incorrectAttempts <= 1) {
        return 'Runde geschafft. Heute hast du $activity geübt. Viele Aufgaben gingen schon direkt.';
      }
      if (result.incorrectAttempts >= 2) {
        return 'Runde geschafft. Heute hast du $activity geübt. Einige Aufgaben waren noch knifflig. Die nehmen wir beim nächsten Mal wieder mit.';
      }
      return 'Runde geschafft. Heute hast du $activity geübt. Rechenblitz plant passend dazu weiter.';
    }

    final progress = microCompetencyProgress(targetCompetency);
    final label = progress.definition.label;
    final sessionObservations = microObservations.where((entry) =>
        entry.id == targetCompetency &&
        !entry.occurredAt.isBefore(result.startedAt) &&
        !entry.occurredAt.isAfter(
          result.finishedAt.add(const Duration(seconds: 2)),
        ));
    final helpedCorrect = sessionObservations.any(
      (entry) => entry.correct && entry.usedHelp,
    );
    final independentCorrect = sessionObservations.any(
      (entry) => entry.correct && !entry.usedHelp,
    );

    if (helpedCorrect && independentCorrect) {
      return 'Runde geschafft. Bei „$label“ bist du heute mit Hilfe gestartet. Danach hat der Schritt auch ohne Hilfe geklappt.';
    }
    if (helpedCorrect && !independentCorrect) {
      return 'Runde geschafft. Bei „$label“ hat dir heute eine Hilfe geholfen. Beim nächsten Mal probieren wir den Schritt wieder selbstständig.';
    }
    if (fluencyEmphasis) {
      return progress.fluencyState == MicroFluencyState.fluent
          ? 'Runde geschafft. „$label“ sitzt schon sicher und wird inzwischen flüssig abgerufen.'
          : 'Runde geschafft. Heute hast du „$label“ weiter flüssig geübt, ohne Zeitdruck.';
    }
    if (transferEmphasis) {
      return progress.hasIndependentTransferEvidence
          ? 'Runde geschafft. Heute hast du „$label“ auch in einer neuen Aufgabe selbstständig angewendet.'
          : 'Runde geschafft. Heute hast du „$label“ in einer neuen Aufgabe ausprobiert. Das schauen wir uns später noch einmal an.';
    }
    if (reviewEmphasis) {
      return progress.hasIndependentReviewEvidence
          ? 'Runde geschafft. „$label“ hat heute auch nach einer Pause wieder selbstständig geklappt.'
          : 'Runde geschafft. Heute hast du „$label“ nach einer Pause wiederholt. Beim nächsten Mal prüfen wir es noch einmal selbstständig.';
    }

    return switch (progress.state) {
      MicroCompetencyState.mastered =>
        'Runde geschafft. „$label“ sitzt schon richtig stabil. Später reicht eine kurze Wiederholung.',
      MicroCompetencyState.secure =>
        'Runde geschafft. „$label“ klappt schon sicher. Als Nächstes prüfen wir es nach einer Pause oder in einer neuen Aufgabe.',
      MicroCompetencyState.practicing =>
        'Runde geschafft. Heute hast du „$label“ weiter geübt. Beim nächsten Mal festigen wir den Schritt noch ein bisschen.',
      MicroCompetencyState.discovering =>
        'Runde geschafft. Heute hast du „$label“ weiter aufgebaut. Beim nächsten Mal geht es in einem kleinen Schritt weiter.',
      MicroCompetencyState.newSkill =>
        'Runde geschafft. Heute hast du „$label“ kennengelernt. Beim nächsten Mal probieren wir noch ein paar passende Aufgaben.',
    };
  }

  String guidedRoundSpokenFeedback({
    required List<String> strengthenedCompetencies,
    String? nextCompetency,
  }) {
    final distinct = strengthenedCompetencies.toSet();
    if (distinct.isEmpty) {
      return 'Deine Runde ist geschafft. Beim nächsten Mal plant Rechenblitz passend weiter.';
    }
    final first = distinct.first;
    final next = nextCompetency == null
        ? 'Beim nächsten Mal plant Rechenblitz passend weiter.'
        : nextCompetency == first
            ? 'Das üben wir beim nächsten Mal kurz weiter.'
            : 'Nächstes Mal geht es mit „$nextCompetency“ weiter.';
    return 'Deine Runde ist geschafft. Heute hast du „$first“ gestärkt. $next';
  }

  String? methodSupportInsight(MicroCompetencyId id) {
    final observations = _sortedMicroObservationsFor(id)
        .where((entry) => entry.methodKey != null)
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
    for (final best in eligible) {
      final label = MethodKeyLabel.resolve(best.key);
      if (label == null) continue;
      return 'Mit „$label“ waren ${(best.accuracy * 100).round()} % der '
          '${best.total} beobachteten Antworten richtig. '
          'Das ist eine Lernbeobachtung und ändert die Schulmethode nicht automatisch.';
    }
    return null;
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
    guidedRoundProgress = null;
    assessmentProgress = null;
    remediationSessionProgress = null;
    stepRecoverySessionProgress = null;
    coreTrainingSessionProgress = null;
    activeTeacherAssignment = null;
    _pendingBadgeIds.clear();
    lastSessionNewBadges = const [];
    if (profiles.isNotEmpty) {
      profiles = profiles
          .map(
            (profile) => profile.id == activeProfileId
                ? profile.copyWith(clearAssessment: true)
                : profile,
          )
          .toList();
      await storage.saveProfiles(profiles);
    }
    notifyListeners();
  }
}
