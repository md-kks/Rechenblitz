import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/active_response_timer.dart';
import '../models/adaptive_segment.dart';
import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import '../models/help_preferences.dart';
import '../models/math_fact.dart';
import '../models/micro_competency.dart';
import '../models/training.dart';
import '../models/training_session_progress.dart';
import '../models/training_review_history.dart';
import '../models/touch_interaction.dart';
import '../services/app_controller.dart';
import '../widgets/guided_method_panel.dart';
import '../widgets/independent_step_card.dart';
import '../widgets/number_answer_pad.dart';
import '../widgets/round_completion_dialog.dart';
import '../widgets/touch_answer_interaction.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({
    super.key,
    required this.controller,
    required this.mode,
    required this.targetTasks,
    this.timeLimit,
    this.targetCompetency,
    this.reviewEmphasis = false,
    this.transferEmphasis = false,
    this.fluencyEmphasis = false,
    this.scaffoldFading = false,
    this.adaptiveLength = false,
    this.announceCompletion = true,
  });

  final AppController controller;
  final TrainingMode mode;
  final int targetTasks;
  final Duration? timeLimit;
  final MicroCompetencyId? targetCompetency;
  final bool reviewEmphasis;
  final bool transferEmphasis;
  final bool fluencyEmphasis;
  final bool scaffoldFading;
  final bool adaptiveLength;
  final bool announceCompletion;

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with WidgetsBindingObserver {
  HelpPreferences get _helpPreferences => widget.controller.helpPreferences;
  HelpLevel? get _manualHelpLevel => _helpPreferences.manualStartLevel;
  bool get _helpAvailable => _helpPreferences.enabled;
  bool get _manualHelpAvailable =>
      _helpAvailable &&
      widget.mode != TrainingMode.speed &&
      widget.mode != TrainingMode.tempo &&
      widget.mode != TrainingMode.blitz &&
      (widget.mode == TrainingMode.numberFriends ||
          _independentArithmeticSteps.isNotEmpty ||
          current.isMinus ||
          current.isMultiply ||
          current.isDivide);


  void _showManualHelp() {
    final starter = _manualHelpLevel;
    if (starter == null) return;
    setState(() {
      usedHelp = true;
      showHelp = true;
      helpLevel = starter.value;
      activeMethodKey = _guide.methodKey;
    });
    unawaited(_persistSession());
  }

  int get _selectionMaxValue {
    final currentMax = widget.controller.effectiveMaxValue;
    if (!widget.fluencyEmphasis) return currentMax;
    final cap = switch (widget.targetCompetency) {
      MicroCompetencyId.additionNoBridge ||
      MicroCompetencyId.additionTenBridge ||
      MicroCompetencyId.subtractionNoBridge ||
      MicroCompetencyId.subtractionTenBridge => 20,
      MicroCompetencyId.multiplicationFacts ||
      MicroCompetencyId.divisionFacts => 100,
      _ => currentMax,
    };
    return currentMax < cap ? currentMax : cap;
  }
  TouchInteractionPlan? get _touchInteraction {
    if (widget.fluencyEmphasis) return null;
    final plan = TouchInteractionPlan.forTask(
      mode: widget.mode,
      taskKey: current.key,
      answer: _expectedAnswer,
      maxValue: _selectionMaxValue,
      targetCompetency: widget.targetCompetency,
    );
    final arithmeticNumberLine = plan?.kind == TouchInteractionKind.numberLine &&
        switch (widget.targetCompetency) {
          MicroCompetencyId.additionNoBridge ||
          MicroCompetencyId.additionTenBridge ||
          MicroCompetencyId.subtractionNoBridge ||
          MicroCompetencyId.subtractionTenBridge => true,
          _ => false,
        };
    if (arithmeticNumberLine &&
        (widget.reviewEmphasis || widget.scaffoldFading)) {
      return null;
    }
    return plan;
  }

  MicroEvidenceSource get _evidenceSource => widget.transferEmphasis
      ? MicroEvidenceSource.transfer
      : widget.reviewEmphasis
          ? MicroEvidenceSource.review
          : MicroEvidenceSource.practice;

  late MathFact current;
  late ActiveResponseTimer responseTimer;
  late DateTime startedAt;
  Timer? timer;
  Duration elapsed = Duration.zero;
  int completed = 0;
  int incorrectAttempts = 0;
  int correctFirstTry = 0;
  int wrongOnCurrent = 0;
  int? firstWrongAnswer;
  bool usedHelp = false;
  bool showHelp = false;
  bool locked = false;
  bool finishing = false;
  bool segmentUsedHelp = false;
  bool useTouchInput = true;
  bool helpCountedForCurrent = false;
  bool taskFirstAttemptRecorded = false;
  bool submitting = false;
  int factAttemptSequence = 0;
  PendingFactAttempt? pendingFactAttempt;
  bool resumedFromDraft = false;
  bool resumeResolvedTask = false;
  int helpLevel = 0;
  String? activeMethodKey;
  String feedback = '';
  ErrorPattern? currentErrorPattern;
  int taskIndex = 0;
  int checkpointIndex = 0;
  final Set<int> checkpointAttempted = <int>{};
  final Map<int, int> checkpointWrongAttempts = <int, int>{};
  bool checkpointLocked = false;
  bool hadCheckpointError = false;
  CheckpointAttemptReview? firstCheckpointAttempt;
  Future<void>? taskRememberFuture;
  String checkpointFeedback = '';
  final List<int> completedResponseMs = [];
  final List<RoundAttemptReview> attemptReviews = [];
  int plusTotal = 0;
  int plusCorrect = 0;
  int minusTotal = 0;
  int minusCorrect = 0;
  int multiplyTotal = 0;
  int multiplyCorrect = 0;
  int divideTotal = 0;
  int divideCorrect = 0;
  Duration activeElapsedBase = Duration.zero;
  late DateTime activeClockStartedAt;
  bool activeClockRunning = true;

  int get _minusStage {
    final tried = widget.controller.facts
        .where((f) =>
            f.isMinus &&
            f.attempts > 0 &&
            f.a <= _selectionMaxValue &&
            f.b <= _selectionMaxValue)
        .toList();
    if (tried.length < 8) return 1;
    final average = tried
            .map((f) => f.masteryScore)
            .fold<double>(0, (a, b) => a + b) /
        tried.length;
    if (average < 0.48) return 1;
    if (average < 0.72) return 2;
    return 3;
  }

  bool get _adaptiveTargetStable {
    final id = widget.targetCompetency;
    if (id == null) return false;
    final progress = widget.controller.microCompetencyProgress(id);
    final confidence = widget.controller.microEvidenceConfidence(id);
    return (progress.state == MicroCompetencyState.secure ||
            progress.state == MicroCompetencyState.mastered) &&
        confidence.level == MicroEvidenceConfidenceLevel.current;
  }

  AdaptiveSegmentDecision _adaptiveSegmentDecision() =>
      AdaptiveSegmentPolicy.evaluate(
        enabled: widget.adaptiveLength,
        mode: widget.mode,
        plannedTasks: widget.targetTasks,
        completed: completed,
        correctFirstTry: correctFirstTry,
        incorrectAttempts: incorrectAttempts,
        usedHelp: segmentUsedHelp,
        targetStable: _adaptiveTargetStable,
        reviewEmphasis: widget.reviewEmphasis,
        transferEmphasis: widget.transferEmphasis,
        fluencyEmphasis: widget.fluencyEmphasis,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final saved = widget.controller.resumableCoreTrainingSession(
      kind: CoreTrainingKind.fact,
      mode: widget.mode,
      targetTasks: widget.targetTasks,
      targetCompetency: widget.targetCompetency,
      reviewEmphasis: widget.reviewEmphasis,
      transferEmphasis: widget.transferEmphasis,
      fluencyEmphasis: widget.fluencyEmphasis,
      scaffoldFading: widget.scaffoldFading,
      adaptiveLength: widget.adaptiveLength,
      timeLimit: widget.timeLimit,
    );
    final now = DateTime.now();
    activeClockStartedAt = now;
    if (saved != null) {
      startedAt = saved.startedAt;
      activeElapsedBase = Duration(milliseconds: saved.elapsedActiveMs);
      elapsed = activeElapsedBase;
      completed = saved.completed;
      incorrectAttempts = saved.incorrectAttempts;
      correctFirstTry = saved.correctFirstTry;
      wrongOnCurrent = saved.wrongOnCurrent;
      firstWrongAnswer = saved.firstWrongAnswer;
      segmentUsedHelp = saved.segmentUsedHelp;
      showHelp = saved.assistanceVisible;
      usedHelp = saved.usedHelp;
      useTouchInput = saved.useTouchInput;
      helpLevel = saved.helpLevel;
      activeMethodKey = saved.activeMethodKey;
      currentErrorPattern = saved.currentErrorPattern;
      checkpointIndex = saved.checkpointIndex;
      checkpointAttempted.addAll(saved.checkpointAttempted);
      checkpointWrongAttempts.addAll(saved.checkpointWrongAttempts);
      hadCheckpointError = saved.hadCheckpointError;
      firstCheckpointAttempt = saved.firstCheckpointAttempt;
      taskFirstAttemptRecorded = saved.taskFirstAttemptRecorded;
      helpCountedForCurrent = saved.helpCountedForCurrent;
      factAttemptSequence = saved.factAttemptSequence;
      pendingFactAttempt = saved.pendingFactAttempt;
      completedResponseMs.addAll(saved.responseTimes);
      attemptReviews.addAll(saved.attemptReviews);
      plusTotal = saved.plusTotal;
      plusCorrect = saved.plusCorrect;
      minusTotal = saved.minusTotal;
      minusCorrect = saved.minusCorrect;
      multiplyTotal = saved.multiplyTotal;
      multiplyCorrect = saved.multiplyCorrect;
      divideTotal = saved.divideTotal;
      divideCorrect = saved.divideCorrect;
      final key = saved.currentTask['key'] as String?;
      final matches = widget.controller.facts.where((fact) => fact.key == key);
      current = matches.isNotEmpty
          ? matches.first
          : widget.controller.engine.selectNext(
              facts: widget.controller.facts,
              mode: widget.mode,
              maxValue: _selectionMaxValue,
              previousKey: null,
              recentKeys: widget.controller.recentTaskKeys(widget.mode),
              targetCompetency: widget.targetCompetency,
            );
      responseTimer = ActiveResponseTimer(startedAt: now);
      resumedFromDraft = true;
      resumeResolvedTask = saved.taskResolved;
      locked = resumeResolvedTask || pendingFactAttempt != null;
    } else {
      startedAt = now;
      current = _next();
      _prepareHelpForCurrent();
      responseTimer = ActiveResponseTimer(startedAt: now);
      unawaited(_persistSession());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (pendingFactAttempt != null) {
        unawaited(_recoverPendingFactAttempt());
      } else if (resumeResolvedTask) {
        unawaited(_continueResolvedSession());
      } else {
        unawaited(widget.controller.speak(_spokenTask));
      }
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !activeClockRunning) return;
      setState(() => elapsed = _activeElapsed());
      if (widget.timeLimit != null && elapsed >= widget.timeLimit!) {
        _finish();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      responseTimer.resume(at: now);
      if (!activeClockRunning) {
        activeClockStartedAt = now;
        activeClockRunning = true;
      }
      return;
    }
    responseTimer.pause();
    if (activeClockRunning) {
      activeElapsedBase = _activeElapsed();
      elapsed = activeElapsedBase;
      activeClockRunning = false;
    }
    unawaited(_persistSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  Duration _activeElapsed() => activeElapsedBase +
      (activeClockRunning
          ? DateTime.now().difference(activeClockStartedAt)
          : Duration.zero);

  CoreTrainingSessionProgress _sessionSnapshot({
    bool? taskResolvedOverride,
    bool clearPendingFactAttempt = false,
  }) =>
      CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: widget.mode,
        targetTasks: widget.targetTasks,
        targetCompetency: widget.targetCompetency,
        reviewEmphasis: widget.reviewEmphasis,
        transferEmphasis: widget.transferEmphasis,
        fluencyEmphasis: widget.fluencyEmphasis,
        scaffoldFading: widget.scaffoldFading,
        adaptiveLength: widget.adaptiveLength,
        gradeLevel: widget.controller.effectiveGradeLevel,
        numberRange: widget.controller.effectiveNumberRange,
        teacherAssignmentActive: widget.controller.hasTeacherAssignment,
        teacherAssignmentId:
            widget.controller.activeTeacherAssignment?.assignmentId,
        timeLimitMs: widget.timeLimit?.inMilliseconds,
        startedAt: startedAt,
        updatedAt: DateTime.now(),
        currentTask: {'key': current.key},
        elapsedActiveMs: _activeElapsed().inMilliseconds,
        completed: completed,
        incorrectAttempts: incorrectAttempts,
        correctFirstTry: correctFirstTry,
        wrongOnCurrent: wrongOnCurrent,
        firstWrongAnswer: firstWrongAnswer,
        segmentUsedHelp: segmentUsedHelp,
        assistanceVisible: showHelp,
        usedHelp: usedHelp,
        useTouchInput: useTouchInput,
        helpLevel: helpLevel,
        activeMethodKey: activeMethodKey,
        currentErrorPattern: currentErrorPattern,
        checkpointIndex: checkpointIndex,
        checkpointAttempted: checkpointAttempted.toList()..sort(),
        checkpointWrongAttempts:
            Map<int, int>.from(checkpointWrongAttempts),
        hadCheckpointError: hadCheckpointError,
        firstCheckpointAttempt: firstCheckpointAttempt,
        taskFirstAttemptRecorded: taskFirstAttemptRecorded,
        helpCountedForCurrent: helpCountedForCurrent,
        factAttemptSequence: factAttemptSequence,
        pendingFactAttempt:
            clearPendingFactAttempt ? null : pendingFactAttempt,
        responseTimes: List<int>.from(completedResponseMs),
        attemptReviews: List<RoundAttemptReview>.from(attemptReviews),
        plusTotal: plusTotal,
        plusCorrect: plusCorrect,
        minusTotal: minusTotal,
        minusCorrect: minusCorrect,
        multiplyTotal: multiplyTotal,
        multiplyCorrect: multiplyCorrect,
        divideTotal: divideTotal,
        divideCorrect: divideCorrect,
        taskResolved: taskResolvedOverride ?? false,
      );

  Future<void> _persistSession({
    bool? taskResolvedOverride,
    bool clearPendingFactAttempt = false,
  }) =>
      widget.controller.saveCoreTrainingSession(
        _sessionSnapshot(
          taskResolvedOverride: taskResolvedOverride,
          clearPendingFactAttempt: clearPendingFactAttempt,
        ),
      );

  Future<void> _continueResolvedSession() async {
    final adaptiveDecision = _adaptiveSegmentDecision();
    if (adaptiveDecision.shouldStop || completed >= widget.targetTasks) {
      await _finish(
        adaptiveStopReason:
            adaptiveDecision.shouldStop ? adaptiveDecision.message : null,
      );
      return;
    }
    resumeResolvedTask = false;
    _showNextTask();
  }

  void _prepareHelpForCurrent() {
    taskIndex = completed;
    checkpointIndex = 0;
    checkpointAttempted.clear();
    checkpointWrongAttempts.clear();
    checkpointLocked = false;
    hadCheckpointError = false;
    firstCheckpointAttempt = null;
    taskRememberFuture = null;
    taskFirstAttemptRecorded = false;
    pendingFactAttempt = null;
    submitting = false;
    checkpointFeedback = '';
    useTouchInput = true;

    final fadingLevel = ScaffoldFadingPolicy.initialLevelForTask(
      completed,
      enabled: widget.scaffoldFading,
    );
    final allowedFadingLevel =
        fadingLevel == null
            ? null
            : _helpPreferences.automaticStartLevel(fadingLevel);
    if (widget.scaffoldFading) {
      usedHelp = allowedFadingLevel != null;
      showHelp = allowedFadingLevel != null;
      helpLevel = allowedFadingLevel?.value ?? HelpLevel.none.value;
      activeMethodKey = allowedFadingLevel == null ? null : _guide.methodKey;
      return;
    }

    if (widget.fluencyEmphasis) {
      usedHelp = false;
      showHelp = false;
      helpLevel = HelpLevel.none.value;
      activeMethodKey = null;
      return;
    }

    final starter = _helpPreferences.clamp(HelpLevel.nudge);
    usedHelp =
        widget.mode == TrainingMode.minus && _minusStage == 1 && starter != null;
    showHelp = usedHelp;
    helpLevel = showHelp ? starter!.value : HelpLevel.none.value;
    activeMethodKey = showHelp ? _guide.methodKey : null;
  }

  MathFact _next() => widget.controller.engine.selectNext(
        facts: widget.controller.facts,
        mode: widget.mode,
        maxValue: _selectionMaxValue,
        previousKey: completed == 0 ? null : current.key,
        recentKeys: widget.controller.recentTaskKeys(widget.mode),
        targetCompetency: widget.targetCompetency,
      );

  ErrorPattern get _helpPattern =>
      currentErrorPattern ??
      ErrorClassifier.classify(
        mode: widget.mode,
        taskKey: current.key,
        expected: _expectedAnswer,
        actual: _expectedAnswer,
        fact: current,
      ) ??
      ErrorPattern.unknown;

  GuidedMethodGuide get _guide => GuidedMethodFactory.forTask(
        mode: widget.mode,
        taskKey: current.key,
        expected: _expectedAnswer,
        preferences: widget.controller.effectiveMethodPreferences,
        targetCompetency: widget.targetCompetency,
        fact: current,
      );

  List<GuidedMethodGuide> get _guideAlternatives {
    if (widget.controller.hasTeacherAssignment) {
      return const <GuidedMethodGuide>[];
    }
    return GuidedMethodFactory.alternativesForTask(
      mode: widget.mode,
      taskKey: current.key,
      expected: _expectedAnswer,
      preferences: widget.controller.effectiveMethodPreferences,
      targetCompetency: widget.targetCompetency,
      fact: current,
    );
  }

  List<GuidedMethodStep> get _independentArithmeticSteps {
    if (widget.reviewEmphasis ||
        widget.transferEmphasis ||
        !IndependentArithmeticStepPolicy.shouldProbeTask(
          taskIndex,
          scaffoldFading: widget.scaffoldFading,
        )) {
      return const <GuidedMethodStep>[];
    }
    return GuidedMethodFactory.independentArithmeticStepsForTask(
      mode: widget.mode,
      fact: current,
      preferences: widget.controller.effectiveMethodPreferences,
      targetCompetency: widget.targetCompetency,
    );
  }

  bool get _checkpointsComplete =>
      checkpointIndex >= _independentArithmeticSteps.length;

  Future<void> _rememberCurrentTaskOnce() {
    final existing = taskRememberFuture;
    if (existing != null) return existing;
    final future = widget.controller.rememberPresentedTask(
      widget.mode,
      current.key,
    );
    taskRememberFuture = future;
    return future;
  }

  Future<void> _answerCheckpoint(int choice) async {
    if (locked ||
        finishing ||
        checkpointLocked ||
        _checkpointsComplete) {
      return;
    }

    final steps = _independentArithmeticSteps;
    final index = checkpointIndex;
    final step = steps[index];
    final correct = choice == step.correctChoice;
    final firstAttempt = checkpointAttempted.add(index);

    if (firstAttempt) {
      await _persistSession();
      await _rememberCurrentTaskOnce();
      await widget.controller.recordIndependentStepAttempt(
        mode: widget.mode,
        taskKey: current.key,
        stepKey: step.evidenceKey!,
        competencyId: step.evidenceCompetency!,
        correct: correct,
        usedHelp: usedHelp || showHelp,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
        evidenceWeight: step.evidenceWeight,
      );
    }

    if (!correct) {
      hadCheckpointError = true;
      firstCheckpointAttempt ??= CheckpointAttemptReview.tryFromChoices(
        question: step.question,
        choices: step.choices,
        firstChoice: choice,
        correctChoice: step.correctChoice,
      );
      final attempts = (checkpointWrongAttempts[index] ?? 0) + 1;
      checkpointWrongAttempts[index] = attempts;
      final retryHelp = _manualHelpLevel;
      setState(() {
        checkpointFeedback = attempts >= 2 && retryHelp != null
            ? 'Schau dir die Hilfe an und probier den Schritt noch einmal.'
            : 'Noch nicht. Probier den Schritt noch einmal.';
        if (attempts >= 2 && retryHelp != null) {
          showHelp = true;
          usedHelp = true;
          if (helpLevel < retryHelp.value) {
            helpLevel = retryHelp.value;
          }
          activeMethodKey ??= _guide.methodKey;
        }
      });
      await _persistSession();
      return;
    }

    setState(() {
      checkpointLocked = true;
      checkpointFeedback = 'Genau!';
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted ||
        finishing ||
        checkpointIndex != index ||
        _independentArithmeticSteps.length <= index) {
      return;
    }
    setState(() {
      checkpointIndex += 1;
      checkpointLocked = false;
      checkpointFeedback = '';
    });
    await _persistSession();
  }

  String get _spokenTask => widget.mode == TrainingMode.numberFriends
      ? '${current.result} ist gleich ${current.a} plus welche Zahl?'
      : '${current.a} ${current.symbol} ${current.b} ist gleich?';

  int get _expectedAnswer =>
      widget.mode == TrainingMode.numberFriends ? current.b : current.result;

  String _factAttemptId(int sequence) =>
      '${startedAt.microsecondsSinceEpoch}:${widget.mode.name}:${current.key}:$sequence';

  Future<void> _recoverPendingFactAttempt() async {
    final receipt = pendingFactAttempt;
    if (receipt == null || submitting) return;
    submitting = true;
    try {
      await _commitFactAttempt(receipt, restoring: true);
    } catch (_) {
      // Keep the persisted receipt. A later retry can safely replay it because
      // recordAttempt is idempotent for the same receipt id.
      submitting = false;
      if (mounted) setState(() => locked = false);
    }
  }

  Future<void> _ensureFirstAttemptEvidence(
    PendingFactAttempt receipt,
  ) async {
    if (taskFirstAttemptRecorded) return;
    await _rememberCurrentTaskOnce();
    await widget.controller.recordDiagnosticAttempt(
      mode: widget.mode,
      taskKey: current.key,
      expected: _expectedAnswer,
      actual: receipt.actualAnswer,
      fact: current,
      usedHelp: usedHelp || showHelp,
      helpLevel: helpLevel,
      methodKey: activeMethodKey,
      source: _evidenceSource,
      responseTime: _independentArithmeticSteps.isEmpty
          ? Duration(milliseconds: receipt.responseMs)
          : null,
      evidenceId: '${receipt.id}:diagnostic',
    );
    taskFirstAttemptRecorded = true;
    await _persistSession();
  }

  Future<void> _commitFactAttempt(
    PendingFactAttempt receipt, {
    required bool restoring,
  }) async {
    if (receipt.taskKey != current.key) {
      submitting = false;
      return;
    }
    await _ensureFirstAttemptEvidence(receipt);
    final response = Duration(milliseconds: receipt.responseMs);
    final diagnosedPattern = receipt.correct
        ? null
        : ErrorClassifier.classify(
            mode: widget.mode,
            taskKey: current.key,
            expected: _expectedAnswer,
            actual: receipt.actualAnswer,
            fact: current,
          );

    await widget.controller.recordAttempt(
      current,
      correct: receipt.correct,
      responseTime: response,
      usedHelp: receipt.usedHelp,
      attemptId: receipt.id,
    );
    if (receipt.usedHelp) helpCountedForCurrent = true;
    if (!mounted || finishing) {
      submitting = false;
      return;
    }

    if (!receipt.correct) {
      firstWrongAnswer ??= receipt.actualAnswer;
    }

    if (!receipt.correct && widget.mode == TrainingMode.tempo) {
      incorrectAttempts += 1;
      completed += 1;
      completedResponseMs.add(receipt.responseMs);
      _rememberAttemptReview();
      _countCompletedFact(firstTryCorrect: false);
      locked = true;
      setState(() => feedback = 'Weiter geht’s.');
      await _persistSession(
        taskResolvedOverride: true,
        clearPendingFactAttempt: true,
      );
      pendingFactAttempt = null;
      submitting = false;
      if (!restoring) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      if (!mounted || finishing) return;
      if (completed >= widget.targetTasks) {
        await _finish();
        return;
      }
      _showNextTask();
      return;
    }

    if (!receipt.correct) {
      incorrectAttempts += 1;
      wrongOnCurrent += 1;
      locked = false;
      final retryHelp = _manualHelpLevel;
      setState(() {
        currentErrorPattern ??= diagnosedPattern;
        feedback = wrongOnCurrent >= 2 && retryHelp != null
            ? 'Schau dir die Hilfe an und probier noch einmal.'
            : _helpAvailable
                ? diagnosedPattern?.firstResponseHint ?? 'Probier es noch einmal.'
                : 'Probier es noch einmal.';
        if (wrongOnCurrent >= 2 && retryHelp != null) {
          showHelp = true;
          usedHelp = true;
          if (helpLevel < retryHelp.value) {
            helpLevel = retryHelp.value;
          }
          activeMethodKey ??= _guide.methodKey;
        }
      });
      await _persistSession(clearPendingFactAttempt: true);
      pendingFactAttempt = null;
      submitting = false;
      return;
    }

    if (wrongOnCurrent > 0 && helpLevel > 0) {
      await widget.controller.recordMicroSupportResolution(
        mode: widget.mode,
        taskKey: current.key,
        fact: current,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
        source: _evidenceSource,
      );
      if (!mounted || finishing) {
        submitting = false;
        return;
      }
    }

    locked = true;
    completed += 1;
    segmentUsedHelp = segmentUsedHelp || usedHelp || showHelp || helpLevel > 0;
    completedResponseMs.add(receipt.responseMs);
    final firstTry = wrongOnCurrent == 0 && !hadCheckpointError;
    if (firstTry) {
      correctFirstTry += 1;
    } else {
      _rememberAttemptReview();
    }
    _countCompletedFact(firstTryCorrect: firstTry);
    if (!restoring && widget.controller.hapticEnabled) {
      HapticFeedback.lightImpact();
    }
    if (!restoring && widget.controller.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    setState(() => feedback =
        ['Richtig!', 'Genau!', 'Stimmt!', 'Gut gerechnet!'][completed % 4]);
    final adaptiveDecision = _adaptiveSegmentDecision();
    await _persistSession(
      taskResolvedOverride: true,
      clearPendingFactAttempt: true,
    );
    pendingFactAttempt = null;
    submitting = false;
    if (!restoring) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
    }
    if (!mounted || finishing) return;
    if (adaptiveDecision.shouldStop) {
      await _finish(adaptiveStopReason: adaptiveDecision.message);
      return;
    }
    if (completed >= widget.targetTasks) {
      await _finish();
      return;
    }
    _showNextTask();
  }

  Future<void> _answer(int answer) async {
    if (locked || finishing || !_checkpointsComplete || submitting) return;
    final pending = pendingFactAttempt;
    if (pending != null) {
      submitting = true;
      try {
        await _commitFactAttempt(pending, restoring: false);
      } catch (_) {
        submitting = false;
        rethrow;
      }
      return;
    }

    submitting = true;
    try {
      final response = responseTimer.elapsed();
      final correct = answer == _expectedAnswer;
      factAttemptSequence += 1;
      final receipt = PendingFactAttempt(
        id: _factAttemptId(factAttemptSequence),
        taskKey: current.key,
        correct: correct,
        actualAnswer: answer,
        responseMs: response.inMilliseconds.clamp(0, 30000).toInt(),
        usedHelp: usedHelp && !helpCountedForCurrent,
      );
      pendingFactAttempt = receipt;
      await _persistSession();
      await _commitFactAttempt(receipt, restoring: false);
    } catch (_) {
      submitting = false;
      rethrow;
    }
  }

  String get _reviewPrompt => widget.mode == TrainingMode.numberFriends
      ? '${current.result} = ${current.a} + ?'
      : '${current.a} ${current.symbol} ${current.b} = ?';

  void _rememberAttemptReview() {
    if (completed <= 0 ||
        attemptReviews.any((review) => review.taskNumber == completed)) {
      return;
    }
    attemptReviews.add(
      RoundAttemptReview(
        taskNumber: completed,
        taskKey: current.key,
        prompt: _reviewPrompt,
        correctAnswer: '$_expectedAnswer',
        firstAnswer:
            firstWrongAnswer == null ? null : '$firstWrongAnswer',
        hadCheckpointError: hadCheckpointError,
        checkpointAttempt: firstCheckpointAttempt,
      ),
    );
  }

  void _countCompletedFact({required bool firstTryCorrect}) {
    switch (current.operation) {
      case MathOperation.plus:
        plusTotal += 1;
        if (firstTryCorrect) plusCorrect += 1;
        break;
      case MathOperation.minus:
        minusTotal += 1;
        if (firstTryCorrect) minusCorrect += 1;
        break;
      case MathOperation.multiply:
        multiplyTotal += 1;
        if (firstTryCorrect) multiplyCorrect += 1;
        break;
      case MathOperation.divide:
        divideTotal += 1;
        if (firstTryCorrect) divideCorrect += 1;
        break;
    }
  }

  void _showNextTask() {
    if (!mounted || finishing) return;
    setState(() {
      current = _next();
      responseTimer.reset();
      wrongOnCurrent = 0;
      firstWrongAnswer = null;
      helpCountedForCurrent = false;
      _prepareHelpForCurrent();
      currentErrorPattern = null;
      feedback = '';
      locked = false;
    });
    unawaited(_persistSession());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(_spokenTask),
    );
  }

  Future<void> _finish({String? adaptiveStopReason}) async {
    if (finishing) return;
    finishing = true;
    activeElapsedBase = _activeElapsed();
    elapsed = activeElapsedBase;
    activeClockRunning = false;
    timer?.cancel();
    locked = true;
    final avg = completedResponseMs.isEmpty
        ? 0.0
        : completedResponseMs.reduce((a, b) => a + b) /
            completedResponseMs.length;
    var result = TrainingSessionResult(
      mode: widget.mode,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      total: completed,
      correctFirstTry: correctFirstTry,
      incorrectAttempts: incorrectAttempts,
      plusCorrect: plusCorrect,
      plusTotal: plusTotal,
      minusCorrect: minusCorrect,
      minusTotal: minusTotal,
      multiplyCorrect: multiplyCorrect,
      multiplyTotal: multiplyTotal,
      divideCorrect: divideCorrect,
      divideTotal: divideTotal,
      averageResponseMs: avg,
      numberRange: widget.controller.effectiveNumberRange,
      gradeLevel: widget.controller.effectiveGradeLevel,
      starsEarned: 0,
      plannedTotal: widget.targetTasks,
      adaptiveStopReason: adaptiveStopReason,
      attemptReviews: trainingAttemptReviews(attemptReviews),
    );
    final rewardReason = widget.controller.rewardReasonForSession(result);
    result = result.copyWith(
      starsEarned: widget.controller.rewardStarsForSession(result),
    );
    final alreadyRecorded = widget.controller.history.any(
      (entry) =>
          entry.mode == widget.mode &&
          entry.startedAt == startedAt &&
          entry.plannedTotal == widget.targetTasks,
    );
    if (completed > 0 && !alreadyRecorded) {
      await widget.controller.addSession(result);
    }
    await widget.controller.clearCoreTrainingSession();
    final newBadges = widget.controller.lastSessionNewBadges;
    final learningInsight = completed == 0
        ? null
        : widget.controller.learningCompletionInsight(
            targetCompetency: widget.targetCompetency,
            reviewEmphasis: widget.reviewEmphasis,
            transferEmphasis: widget.transferEmphasis,
            fluencyEmphasis: widget.fluencyEmphasis,
          );
    final spokenFeedback = completed == 0 || !widget.announceCompletion
        ? null
        : widget.controller.roundSpokenFeedback(
            result: result,
            targetCompetency: widget.targetCompetency,
            reviewEmphasis: widget.reviewEmphasis,
            transferEmphasis: widget.transferEmphasis,
            fluencyEmphasis: widget.fluencyEmphasis,
          );
    final spokenFeedbackEnabled = spokenFeedback != null &&
        widget.controller.accessibilityPreferences.spokenRoundFeedback;
    if (!mounted) return;
    await showRoundCompletionDialog(
      context,
      completed: completed,
      correctFirstTry: correctFirstTry,
      attemptReviews: attemptReviews,
      starsEarned: result.starsEarned,
      rewardReason: rewardReason,
      adaptiveNote: adaptiveStopReason,
      learningInsight: learningInsight,
      spokenFeedback: spokenFeedback,
      autoSpeakSpokenFeedback: spokenFeedbackEnabled,
      onSpeakSpokenFeedback: spokenFeedbackEnabled
          ? () => widget.controller.speakRoundFeedback(spokenFeedback)
          : null,
      newBadges: newBadges,
      averageSeconds: widget.mode == TrainingMode.tempo ||
              widget.mode == TrainingMode.speed
          ? avg / 1000
          : null,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    final compactHeight = screenHeight < 720;
    final compactPhone = compactHeight && screenSize.width < 600;
    final pagePadding = EdgeInsets.symmetric(
      horizontal: compactHeight ? 16 : 20,
      vertical: compactHeight ? 10 : 20,
    );
    final largeGap = compactHeight ? 10.0 : 20.0;
    final answerGap = compactHeight ? 10.0 : 24.0;
    final taskFontSize = compactHeight ? 42.0 : 52.0;
    final numberFriendFontSize = compactHeight ? 40.0 : 48.0;
    final visibleTimer =
        widget.mode == TrainingMode.tempo && widget.timeLimit != null;
    final remainingSeconds = widget.timeLimit == null
        ? null
        : (widget.timeLimit!.inSeconds - elapsed.inSeconds)
            .clamp(0, widget.timeLimit!.inSeconds)
            .toInt();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.title),
        actions: [
          if (compactPhone && _manualHelpAvailable && !showHelp)
            IconButton(
              key: const ValueKey('training-compact-help'),
              tooltip: 'Ich brauche Hilfe',
              onPressed: _showManualHelp,
              icon: const Icon(Icons.lightbulb_outline_rounded),
            ),
          if (compactPhone &&
              _checkpointsComplete &&
              _touchInteraction != null)
            IconButton(
              key: ValueKey(
                useTouchInput
                    ? 'touch-switch-keypad'
                    : 'touch-switch-interaction',
              ),
              tooltip: useTouchInput
                  ? 'Lieber eintippen'
                  : 'Mit Finger lösen',
              onPressed: locked
                  ? null
                  : () {
                      setState(() => useTouchInput = !useTouchInput);
                      unawaited(_persistSession());
                    },
              icon: Icon(
                useTouchInput
                    ? Icons.dialpad_rounded
                    : Icons.touch_app_rounded,
              ),
            ),
          if (visibleTimer)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Center(
                child: Text(
                  '${remainingSeconds! ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => KeyedSubtree(
            key: ValueKey('training-task:$completed:${current.key}'),
            child: SingleChildScrollView(
              key: const ValueKey('training-scroll'),
            padding: pagePadding,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(
                    minHeight: constraints.maxHeight - pagePadding.vertical - 1,
                  ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: widget.targetTasks == 0
                        ? 0
                        : completed / widget.targetTasks,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aufgabe ${completed < widget.targetTasks ? completed + 1 : widget.targetTasks} von ${widget.targetTasks}${resumedFromDraft ? ' · fortgesetzt' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (widget.fluencyEmphasis) ...[
                    const SizedBox(height: 8),
                    Card(
                      key: const ValueKey('fluency-no-pressure'),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.self_improvement_rounded, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Kein Countdown – rechne in deinem Tempo. Die Zeitmessung läuft nur im Hintergrund.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: largeGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.mode == TrainingMode.numberFriends
                                ? '${current.result} = ${current.a} + ?'
                                : '${current.a} ${current.symbol} ${current.b} = ?',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: widget.mode == TrainingMode.numberFriends
                                  ? numberFriendFontSize
                                  : taskFontSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Aufgabe vorlesen',
                        onPressed: () =>
                            widget.controller.speakOnDemand(_spokenTask),
                        icon: const Icon(Icons.volume_up_outlined),
                      ),
                    ],
                  ),
                  SizedBox(height: largeGap),
                  if (!_checkpointsComplete) ...[
                    const SizedBox(height: 2),
                    IndependentStepCard(
                      question:
                          _independentArithmeticSteps[checkpointIndex].question!,
                      choices:
                          _independentArithmeticSteps[checkpointIndex].choices,
                      index: checkpointIndex,
                      total: _independentArithmeticSteps.length,
                      feedback: checkpointFeedback,
                      locked: checkpointLocked,
                      onChoice: _answerCheckpoint,
                    ),
                    const SizedBox(height: 10),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      feedback,
                      key: ValueKey(feedback),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: compactHeight ? 6 : 12),
                  if (showHelp)
                    GuidedMethodPanel(
                      key: ValueKey('guide:${current.key}:$completed'),
                      guide: _guide,
                      alternativeGuides: _guideAlternatives,
                      pattern: _helpPattern,
                      initialLevel: HelpLevel.values[helpLevel],
                      maxLevel: _helpPreferences.maxLevel ?? HelpLevel.nudge,
                      taskKey: current.key,
                      expected: _expectedAnswer,
                      onStepAttempt: (step, correct) =>
                          widget.controller.recordGuidedStepAttempt(
                            mode: widget.mode,
                            taskKey: current.key,
                            methodKey: activeMethodKey ?? _guide.methodKey,
                            stepKey: step.evidenceKey!,
                            competencyId: step.evidenceCompetency!,
                            correct: correct,
                            evidenceWeight: step.evidenceWeight,
                          ),
                      onHelpLevelChanged: (level) {
                        if (!mounted) return;
                        setState(() {
                          usedHelp = true;
                          helpLevel = level.value;
                          activeMethodKey ??= _guide.methodKey;
                        });
                        unawaited(_persistSession());
                      },
                      onGuideChanged: (guide) {
                        if (!mounted) return;
                        setState(() {
                          usedHelp = true;
                          activeMethodKey = guide.methodKey;
                        });
                        unawaited(_persistSession());
                      },
                      onSpeak: widget.controller.speakOnDemand,
                    ),
                  if (!showHelp && _manualHelpAvailable && !compactPhone)
                    TextButton.icon(
                      onPressed: _showManualHelp,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Ich brauche Hilfe'),
                    ),
                  SizedBox(height: answerGap),
                  if (_checkpointsComplete &&
                      useTouchInput &&
                      _touchInteraction != null) ...[
                    TouchAnswerInteraction(
                      key: ValueKey('touch:${current.key}:$completed'),
                      plan: _touchInteraction!,
                      locked: locked,
                      onAnswer: _answer,
                    ),
                    if (!compactPhone) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        key: const ValueKey('touch-switch-keypad'),
                        onPressed: locked
                            ? null
                            : () {
                                setState(() => useTouchInput = false);
                                unawaited(_persistSession());
                              },
                        icon: const Icon(Icons.dialpad_rounded),
                        label: const Text('Lieber eintippen'),
                      ),
                    ],
                  ] else if (_checkpointsComplete) ...[
                    NumberAnswerPad(
                      key: ValueKey('${current.key}:$completed'),
                      maxValue: _selectionMaxValue,
                      onAnswer: _answer,
                    ),
                    if (_touchInteraction != null && !compactPhone)
                      TextButton.icon(
                        key: const ValueKey('touch-switch-interaction'),
                        onPressed: locked
                            ? null
                            : () {
                              setState(() => useTouchInput = true);
                              unawaited(_persistSession());
                            },
                        icon: const Icon(Icons.touch_app_rounded),
                        label: const Text('Lieber mit Punkten'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

