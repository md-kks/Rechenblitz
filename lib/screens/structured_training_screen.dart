import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/active_response_timer.dart';
import '../models/adaptive_segment.dart';
import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import '../models/help_preferences.dart';
import '../models/micro_competency.dart';
import '../models/structured_exercise.dart';
import '../models/training.dart';
import '../models/training_session_progress.dart';
import '../models/touch_interaction.dart';
import '../services/app_controller.dart';
import '../widgets/guided_method_panel.dart';
import '../widgets/independent_step_card.dart';
import '../widgets/number_answer_pad.dart';
import '../widgets/round_completion_dialog.dart';
import '../widgets/touch_answer_interaction.dart';

class StructuredTrainingScreen extends StatefulWidget {
  const StructuredTrainingScreen({
    super.key,
    required this.controller,
    required this.mode,
    this.targetTasks = 10,
    this.targetCompetency,
    this.reviewEmphasis = false,
    this.transferEmphasis = false,
    this.fluencyEmphasis = false,
    this.scaffoldFading = false,
    this.adaptiveLength = false,
    this.announceCompletion = true,
    this.exerciseGenerator,
  });

  final AppController controller;
  final TrainingMode mode;
  final int targetTasks;
  final MicroCompetencyId? targetCompetency;
  final bool reviewEmphasis;
  final bool transferEmphasis;
  final bool fluencyEmphasis;
  final bool scaffoldFading;
  final bool adaptiveLength;
  final bool announceCompletion;
  final StructuredExerciseGenerator? exerciseGenerator;

  @override
  State<StructuredTrainingScreen> createState() =>
      _StructuredTrainingScreenState();
}

class _StructuredTrainingScreenState extends State<StructuredTrainingScreen>
    with WidgetsBindingObserver {
  HelpPreferences get _helpPreferences => widget.controller.helpPreferences;
  HelpLevel? get _manualHelpLevel => _helpPreferences.manualStartLevel;
  bool get _helpAvailable => _helpPreferences.enabled;
  TouchInteractionPlan? get _touchInteraction => TouchInteractionPlan.forTask(
        mode: widget.mode,
        taskKey: current.key,
        answer: current.answer,
        maxValue: current.maxAnswerValue ?? widget.controller.effectiveMaxValue,
        wallValues: current.wallValues,
        hiddenWallIndex: current.hiddenWallIndex,
        choices: current.choices,
        clockHour: current.clockHour,
        clockMinute: current.clockMinute,
        answerSuffix: current.answerSuffix,
        targetCompetency: widget.targetCompetency,
      );

  MicroEvidenceSource get _evidenceSource => widget.transferEmphasis
      ? MicroEvidenceSource.transfer
      : widget.reviewEmphasis
          ? MicroEvidenceSource.review
          : MicroEvidenceSource.practice;

  late final StructuredExerciseGenerator generator;
  late StructuredExercise current;
  late DateTime startedAt;
  late ActiveResponseTimer responseTimer;
  int completed = 0;
  int correctFirstTry = 0;
  int incorrectAttempts = 0;
  int wrongOnCurrent = 0;
  bool locked = false;
  bool finishing = false;
  bool submitting = false;
  bool segmentUsedHelp = false;
  bool taskFirstAttemptRecorded = false;
  PendingFirstAttemptEvidence? pendingFirstAttemptEvidence;
  bool resumedFromDraft = false;
  bool resumeResolvedTask = false;
  bool showHint = false;
  bool useTouchInput = true;
  int helpLevel = 0;
  String? activeMethodKey;
  String feedback = '';
  ErrorPattern? currentErrorPattern;
  final List<int> responseTimes = [];
  final List<RoundAttemptReview> attemptReviews = [];
  int checkpointIndex = 0;
  final Set<int> checkpointAttempted = <int>{};
  final Map<int, int> checkpointWrongAttempts = <int, int>{};
  bool checkpointLocked = false;
  bool hadCheckpointError = false;
  Future<void>? taskRememberFuture;
  String checkpointFeedback = '';

  bool get _checkpointsComplete =>
      checkpointIndex >= current.checkpoints.length;

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
    generator = widget.exerciseGenerator ?? StructuredExerciseGenerator();
    final saved = widget.exerciseGenerator == null
        ? widget.controller.resumableCoreTrainingSession(
      kind: CoreTrainingKind.structured,
      mode: widget.mode,
      targetTasks: widget.targetTasks,
      targetCompetency: widget.targetCompetency,
      reviewEmphasis: widget.reviewEmphasis,
      transferEmphasis: widget.transferEmphasis,
      fluencyEmphasis: widget.fluencyEmphasis,
      scaffoldFading: widget.scaffoldFading,
      adaptiveLength: widget.adaptiveLength,
            timeLimit: null,
          )
        : null;
    final now = DateTime.now();
    if (saved != null) {
      startedAt = saved.startedAt;
      current = decodeStructuredExercise(saved.currentTask);
      completed = saved.completed;
      correctFirstTry = saved.correctFirstTry;
      incorrectAttempts = saved.incorrectAttempts;
      wrongOnCurrent = saved.wrongOnCurrent;
      segmentUsedHelp = saved.segmentUsedHelp;
      showHint = saved.assistanceVisible;
      useTouchInput = saved.useTouchInput;
      helpLevel = saved.helpLevel;
      activeMethodKey = saved.activeMethodKey;
      currentErrorPattern = saved.currentErrorPattern;
      checkpointIndex = saved.checkpointIndex;
      checkpointAttempted.addAll(saved.checkpointAttempted);
      checkpointWrongAttempts.addAll(saved.checkpointWrongAttempts);
      hadCheckpointError = saved.hadCheckpointError;
      taskFirstAttemptRecorded = saved.taskFirstAttemptRecorded;
      pendingFirstAttemptEvidence = saved.pendingFirstAttemptEvidence;
      responseTimes.addAll(saved.responseTimes);
      attemptReviews.addAll(saved.attemptReviews);
      responseTimer = ActiveResponseTimer(startedAt: now);
      resumedFromDraft = true;
      resumeResolvedTask = saved.taskResolved;
      locked = resumeResolvedTask || pendingFirstAttemptEvidence != null;
    } else {
      startedAt = now;
      current = _next();
      _prepareHelpForCurrent();
      responseTimer = ActiveResponseTimer(startedAt: now);
      unawaited(_persistSession());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (pendingFirstAttemptEvidence != null) {
        unawaited(_recoverPendingFirstAttempt());
      } else if (resumeResolvedTask) {
        unawaited(_continueResolvedSession());
      } else {
        unawaited(widget.controller.speak(current.prompt));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      responseTimer.resume();
      return;
    }
    responseTimer.pause();
    unawaited(_persistSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  CoreTrainingSessionProgress _sessionSnapshot({
    bool? taskResolvedOverride,
    bool clearPendingFirstAttempt = false,
  }) =>
      CoreTrainingSessionProgress(
        kind: CoreTrainingKind.structured,
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
        startedAt: startedAt,
        updatedAt: DateTime.now(),
        currentTask: encodeStructuredExercise(current),
        completed: completed,
        incorrectAttempts: incorrectAttempts,
        correctFirstTry: correctFirstTry,
        wrongOnCurrent: wrongOnCurrent,
        segmentUsedHelp: segmentUsedHelp,
        assistanceVisible: showHint,
        useTouchInput: useTouchInput,
        helpLevel: helpLevel,
        activeMethodKey: activeMethodKey,
        currentErrorPattern: currentErrorPattern,
        checkpointIndex: checkpointIndex,
        checkpointAttempted: checkpointAttempted.toList()..sort(),
        checkpointWrongAttempts:
            Map<int, int>.from(checkpointWrongAttempts),
        hadCheckpointError: hadCheckpointError,
        taskFirstAttemptRecorded: taskFirstAttemptRecorded,
        pendingFirstAttemptEvidence:
            clearPendingFirstAttempt ? null : pendingFirstAttemptEvidence,
        responseTimes: List<int>.from(responseTimes),
        attemptReviews: List<RoundAttemptReview>.from(attemptReviews),
        taskResolved: taskResolvedOverride ?? false,
      );

  Future<void> _persistSession({
    bool? taskResolvedOverride,
    bool clearPendingFirstAttempt = false,
  }) {
    if (widget.exerciseGenerator != null) return Future<void>.value();
    return widget.controller.saveCoreTrainingSession(
      _sessionSnapshot(
        taskResolvedOverride: taskResolvedOverride,
        clearPendingFirstAttempt: clearPendingFirstAttempt,
      ),
    );
  }

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
    setState(() {
      current = _next();
      responseTimer.reset();
      wrongOnCurrent = 0;
      locked = false;
      _prepareHelpForCurrent();
      currentErrorPattern = null;
      feedback = '';
    });
    await _persistSession();
    unawaited(widget.controller.speak(current.prompt));
  }

  void _showManualHelp() {
    final starter = _manualHelpLevel;
    if (starter == null) return;
    setState(() {
      showHint = true;
      helpLevel = starter.value;
      activeMethodKey = _guide.methodKey;
    });
    unawaited(_persistSession());
  }

  void _prepareHelpForCurrent() {
    checkpointIndex = 0;
    checkpointAttempted.clear();
    checkpointWrongAttempts.clear();
    checkpointLocked = false;
    hadCheckpointError = false;
    taskRememberFuture = null;
    taskFirstAttemptRecorded = false;
    pendingFirstAttemptEvidence = null;
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
    showHint = allowedFadingLevel != null;
    helpLevel = allowedFadingLevel?.value ?? HelpLevel.none.value;
    activeMethodKey = allowedFadingLevel == null ? null : _guide.methodKey;
  }

  StructuredExercise _next() => generator.generate(
        mode: widget.mode,
        maxValue: widget.controller.effectiveMaxValue,
        recentKeys: widget.controller.recentTaskKeys(widget.mode),
        targetCompetency: widget.targetCompetency,
        gradeLevel: widget.controller.effectiveGradeLevel,
        transferEmphasis: widget.transferEmphasis,
      );

  ErrorPattern get _helpPattern =>
      currentErrorPattern ??
      ErrorClassifier.classify(
        mode: widget.mode,
        taskKey: current.key,
        expected: current.answer,
        actual: current.answer,
      ) ??
      ErrorPattern.unknown;

  GuidedMethodGuide get _guide => GuidedMethodFactory.forTask(
        mode: widget.mode,
        taskKey: current.key,
        expected: current.answer,
        preferences: widget.controller.effectiveMethodPreferences,
        targetCompetency: widget.targetCompetency,
      );



  List<GuidedMethodGuide> get _guideAlternatives {
    if (widget.controller.hasTeacherAssignment) {
      return const <GuidedMethodGuide>[];
    }
    return GuidedMethodFactory.alternativesForTask(
      mode: widget.mode,
      taskKey: current.key,
      expected: current.answer,
      preferences: widget.controller.effectiveMethodPreferences,
      targetCompetency: widget.targetCompetency,
    );
  }

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

    final index = checkpointIndex;
    final checkpoint = current.checkpoints[index];
    final correct = choice == checkpoint.correctChoice;
    final firstAttempt = checkpointAttempted.add(index);

    if (firstAttempt) {
      await _persistSession();
      await _rememberCurrentTaskOnce();
      await widget.controller.recordIndependentStepAttempt(
        mode: widget.mode,
        taskKey: current.key,
        stepKey: checkpoint.key,
        competencyId: checkpoint.competencyId,
        correct: correct,
        usedHelp: showHint,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
        evidenceWeight: checkpoint.evidenceWeight,
      );
    }

    if (!correct) {
      hadCheckpointError = true;
      final attempts = (checkpointWrongAttempts[index] ?? 0) + 1;
      checkpointWrongAttempts[index] = attempts;
      final retryHelp = _manualHelpLevel;
      setState(() {
        checkpointFeedback = attempts >= 2 && retryHelp != null
            ? 'Schau dir die Hilfe an und probier den Schritt noch einmal.'
            : 'Noch nicht. Probier den Schritt noch einmal.';
        if (attempts >= 2 && retryHelp != null) {
          showHint = true;
          if (helpLevel < retryHelp.value) {
            helpLevel = retryHelp.value;
            activeMethodKey = _guide.methodKey;
          }
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
        current.checkpoints.length <= index) {
      return;
    }
    setState(() {
      checkpointIndex += 1;
      checkpointLocked = false;
      checkpointFeedback = '';
    });
    await _persistSession();
  }

  String _firstAttemptEvidenceId() =>
      '${startedAt.microsecondsSinceEpoch}:structured:$completed:${current.key}';

  PendingFirstAttemptEvidence _pendingFirstAttempt(
    int answer,
    Duration response,
  ) =>
      PendingFirstAttemptEvidence(
        id: _firstAttemptEvidenceId(),
        taskKey: current.key,
        expected: current.answer,
        actual: answer,
        responseMs: response.inMilliseconds.clamp(0, 30000).toInt(),
        usedHelp: showHint,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
        source: _evidenceSource,
        directStepKey: current.directIndependentStepKey,
        directStepCompetency: current.directIndependentStepCompetency,
      );

  Future<void> _recordPendingFirstAttempt(
    PendingFirstAttemptEvidence receipt,
  ) async {
    if (taskFirstAttemptRecorded) return;
    await _rememberCurrentTaskOnce();
    if (!mounted || finishing) return;
    final stepKey = receipt.directStepKey;
    final stepCompetency = receipt.directStepCompetency;
    if (stepKey != null && stepCompetency != null) {
      await widget.controller.recordIndependentStepAttempt(
        mode: widget.mode,
        taskKey: receipt.taskKey,
        stepKey: stepKey,
        competencyId: stepCompetency,
        correct: receipt.actual == receipt.expected,
        usedHelp: receipt.usedHelp,
        helpLevel: receipt.helpLevel,
        methodKey: receipt.methodKey,
        evidenceWeight: receipt.directStepEvidenceWeight,
        evidenceId: '${receipt.id}:direct-step',
      );
    }
    await widget.controller.recordDiagnosticAttempt(
      mode: widget.mode,
      taskKey: receipt.taskKey,
      expected: receipt.expected,
      actual: receipt.actual,
      usedHelp: receipt.usedHelp,
      helpLevel: receipt.helpLevel,
      methodKey: receipt.methodKey,
      source: receipt.source,
      responseTime: Duration(milliseconds: receipt.responseMs),
      evidenceId: '${receipt.id}:diagnostic',
    );
    taskFirstAttemptRecorded = true;
    await _persistSession();
  }

  Future<void> _recoverPendingFirstAttempt() async {
    final receipt = pendingFirstAttemptEvidence;
    if (receipt == null || submitting) return;
    submitting = true;
    try {
      await _recordPendingFirstAttempt(receipt);
      if (!mounted || finishing) return;
      await _applyAnswerOutcome(
        receipt.actual,
        Duration(milliseconds: receipt.responseMs),
        restoring: true,
      );
    } catch (_) {
      submitting = false;
      if (mounted) setState(() => locked = false);
    }
  }

  Future<void> _answer(int answer) async {
    if (finishing || !_checkpointsComplete || submitting) return;
    final pending = pendingFirstAttemptEvidence;
    if (pending != null) {
      submitting = true;
      try {
        await _recordPendingFirstAttempt(pending);
        if (!mounted || finishing) return;
        await _applyAnswerOutcome(
          pending.actual,
          Duration(milliseconds: pending.responseMs),
          restoring: true,
        );
      } catch (_) {
        submitting = false;
        if (mounted) setState(() => locked = false);
        rethrow;
      }
      return;
    }
    if (locked) return;
    submitting = true;
    try {
      final response = responseTimer.elapsed();
      if (!taskFirstAttemptRecorded) {
        final receipt = _pendingFirstAttempt(answer, response);
        pendingFirstAttemptEvidence = receipt;
        await _persistSession();
        await _recordPendingFirstAttempt(receipt);
      }
      await _applyAnswerOutcome(answer, response, restoring: false);
    } catch (_) {
      submitting = false;
      rethrow;
    }
  }

  Future<void> _applyAnswerOutcome(
    int answer,
    Duration response, {
    required bool restoring,
  }) async {
    final diagnosedPattern = answer == current.answer
        ? null
        : ErrorClassifier.classify(
            mode: widget.mode,
            taskKey: current.key,
            expected: current.answer,
            actual: answer,
          );
    if (answer != current.answer) {
      incorrectAttempts += 1;
      wrongOnCurrent += 1;
      final retryHelp = _manualHelpLevel;
      setState(() {
        currentErrorPattern ??= diagnosedPattern;
        feedback = wrongOnCurrent >= 2 && retryHelp != null
            ? 'Schau dir die Hilfe an und probier noch einmal.'
            : _helpAvailable
                ? diagnosedPattern?.firstResponseHint ?? 'Probier es noch einmal.'
                : 'Probier es noch einmal.';
        showHint = wrongOnCurrent >= 2 && retryHelp != null;
        if (showHint && helpLevel < retryHelp!.value) {
          helpLevel = retryHelp.value;
          activeMethodKey = _guide.methodKey;
        }
        locked = false;
      });
      pendingFirstAttemptEvidence = null;
      submitting = false;
      await _persistSession(clearPendingFirstAttempt: true);
      return;
    }

    if (wrongOnCurrent > 0 && helpLevel > 0) {
      await widget.controller.recordMicroSupportResolution(
        mode: widget.mode,
        taskKey: current.key,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
        source: _evidenceSource,
      );
      if (!mounted || finishing) return;
    }

    locked = true;
    completed += 1;
    segmentUsedHelp = segmentUsedHelp || showHint || helpLevel > 0;
    responseTimes.add(response.inMilliseconds.clamp(0, 30000).toInt());
    final firstTry = wrongOnCurrent == 0 && !hadCheckpointError;
    if (firstTry) {
      correctFirstTry += 1;
    } else {
      _rememberAttemptReview();
    }
    if (!restoring && widget.controller.hapticEnabled) {
      HapticFeedback.lightImpact();
    }
    if (!restoring && widget.controller.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    setState(() => feedback =
        ['Richtig!', 'Genau!', 'Stimmt!', 'Gut gelöst!'][completed % 4]);
    final adaptiveDecision = _adaptiveSegmentDecision();
    pendingFirstAttemptEvidence = null;
    submitting = false;
    await _persistSession(
      taskResolvedOverride: true,
      clearPendingFirstAttempt: true,
    );
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
    setState(() {
      current = _next();
      responseTimer.reset();
      wrongOnCurrent = 0;
      locked = false;
      _prepareHelpForCurrent();
      currentErrorPattern = null;
      feedback = '';
    });
    await _persistSession();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(current.prompt),
    );
  }

  String get _reviewCorrectAnswer {
    final choices = current.choices;
    if (choices != null &&
        current.answer >= 0 &&
        current.answer < choices.length) {
      return choices[current.answer];
    }
    final suffix = current.answerSuffix?.trim();
    return suffix == null || suffix.isEmpty
        ? '${current.answer}'
        : '${current.answer} $suffix';
  }

  void _rememberAttemptReview() {
    if (completed <= 0 ||
        attemptReviews.any((review) => review.taskNumber == completed)) {
      return;
    }
    attemptReviews.add(
      RoundAttemptReview(
        taskNumber: completed,
        taskKey: current.key,
        prompt: current.prompt,
        correctAnswer: _reviewCorrectAnswer,
        hadCheckpointError: hadCheckpointError,
      ),
    );
  }

  Future<void> _finish({String? adaptiveStopReason}) async {
    if (finishing) return;
    finishing = true;
    final avg = responseTimes.isEmpty
        ? 0.0
        : responseTimes.reduce((a, b) => a + b) / responseTimes.length;
    var result = TrainingSessionResult(
      mode: widget.mode,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      total: completed,
      correctFirstTry: correctFirstTry,
      incorrectAttempts: incorrectAttempts,
      plusCorrect: 0,
      plusTotal: 0,
      minusCorrect: 0,
      minusTotal: 0,
      averageResponseMs: avg,
      numberRange: widget.controller.effectiveNumberRange,
      gradeLevel: widget.controller.effectiveGradeLevel,
      starsEarned: 0,
      plannedTotal: widget.targetTasks,
      adaptiveStopReason: adaptiveStopReason,
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
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final compactHeight = screenSize.height < 720 && screenSize.width < 600;
    final pagePadding = EdgeInsets.symmetric(
      horizontal: compactHeight ? 16 : 20,
      vertical: compactHeight ? 10 : 20,
    );
    final topGap = compactHeight ? 10.0 : 20.0;
    final visualGap = compactHeight ? 12.0 : 22.0;
    final sectionGap = compactHeight ? 10.0 : 18.0;
    final promptFontSize = widget.mode == TrainingMode.wordProblems
        ? (compactHeight ? 22.0 : 25.0)
        : (compactHeight ? 30.0 : 34.0);
    final compactMathPrompt = compactHeight &&
        MediaQuery.textScalerOf(context).scale(1) >= 1.5 &&
        widget.mode != TrainingMode.wordProblems &&
        current.prompt.length <= 36 &&
        !current.prompt.contains('\n');
    final clockSize = compactHeight ? 150.0 : 190.0;
    final shapeWidth = compactHeight ? 150.0 : 180.0;
    final shapeHeight = compactHeight ? 120.0 : 145.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.title),
        actions: [
          if (compactHeight && _helpAvailable && !showHint)
            IconButton(
              key: const ValueKey('structured-compact-help'),
              tooltip: 'Ich brauche Hilfe',
              onPressed: _showManualHelp,
              icon: const Icon(Icons.lightbulb_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: KeyedSubtree(
          key: ValueKey('structured-training-task:$completed:${current.key}'),
          child: ListView(
            key: const ValueKey('structured-training-scroll'),
          padding: pagePadding,
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
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: topGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: compactMathPrompt
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              current.prompt,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: promptFontSize,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : Text(
                            current.prompt,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: promptFontSize,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  IconButton(
                    tooltip: 'Aufgabe vorlesen',
                    onPressed: () =>
                        widget.controller.speakOnDemand(current.prompt),
                    icon: const Icon(Icons.volume_up_outlined),
                  ),
                ],
              ),
              if (current.hasRepresentationVisual) ...[
                SizedBox(height: visualGap),
                _RepresentationVisual(exercise: current),
              ],
              if (current.isNumberWall &&
                  (!_checkpointsComplete ||
                      !useTouchInput ||
                      _touchInteraction == null)) ...[
                SizedBox(height: visualGap),
                _NumberWall(exercise: current),
              ],
              if (current.hasClock) ...[
                SizedBox(height: visualGap),
                Center(
                  child: SizedBox(
                    width: clockSize,
                    height: clockSize,
                    child: CustomPaint(
                      painter: _ClockPainter(
                        hour: current.clockHour!,
                        minute: current.clockMinute!,
                        color: Theme.of(context).colorScheme.onSurface,
                        accent: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
              if (current.shape != null) ...[
                SizedBox(height: visualGap),
                Center(
                  child: SizedBox(
                    width: shapeWidth,
                    height: shapeHeight,
                    child: CustomPaint(
                      painter: _ShapePainter(
                        shape: current.shape!,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
              if (current.hasMoneyVisual) ...[
                SizedBox(height: sectionGap),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: current.moneyPartsCents!
                      .map((value) => _MoneyPiece(cents: value))
                      .toList(),
                ),
              ],
              if (current.hasCheckpoints && !_checkpointsComplete) ...[
                SizedBox(height: sectionGap),
                IndependentStepCard(
                  question: current.checkpoints[checkpointIndex].question,
                  choices: current.checkpoints[checkpointIndex].choices,
                  index: checkpointIndex,
                  total: current.checkpoints.length,
                  feedback: checkpointFeedback,
                  locked: checkpointLocked,
                  onChoice: _answerCheckpoint,
                ),
              ],
              SizedBox(height: sectionGap),
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
              if (showHint) ...[
                SizedBox(height: compactHeight ? 8 : 12),
                GuidedMethodPanel(
                  key: ValueKey('guide:${current.key}:$completed'),
                  guide: _guide,
                  alternativeGuides: _guideAlternatives,
                  pattern: _helpPattern,
                  initialLevel: HelpLevel.values[helpLevel],
                  maxLevel: _helpPreferences.maxLevel ?? HelpLevel.nudge,
                  taskKey: current.key,
                  expected: current.answer,
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
                      helpLevel = level.value;
                      activeMethodKey ??= _guide.methodKey;
                    });
                    unawaited(_persistSession());
                  },
                  onGuideChanged: (guide) {
                    if (!mounted) return;
                    setState(() {
                      activeMethodKey = guide.methodKey;
                    });
                    unawaited(_persistSession());
                  },
                  onSpeak: widget.controller.speakOnDemand,
                ),
              ] else if (_helpAvailable && !compactHeight) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showManualHelp,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('Ich brauche Hilfe'),
                ),
              ],
              SizedBox(height: sectionGap),
              if (!_checkpointsComplete)
                const SizedBox.shrink()
              else if (useTouchInput && _touchInteraction != null) ...[
                if (current.answerSuffix != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Antwort in ${current.answerSuffix}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                TouchAnswerInteraction(
                  key: ValueKey('touch:${current.key}:$completed'),
                  plan: _touchInteraction!,
                  locked: locked,
                  onAnswer: _answer,
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  key: const ValueKey('touch-switch-keypad'),
                  onPressed: locked
                      ? null
                      : () {
                          setState(() => useTouchInput = false);
                          unawaited(_persistSession());
                        },
                  icon: Icon(
                    current.usesChoices
                        ? Icons.checklist_rounded
                        : Icons.dialpad_rounded,
                  ),
                  label: Text(
                    current.usesChoices ? 'Lieber auswählen' : 'Lieber eintippen',
                  ),
                ),
              ] else if (current.usesChoices) ...[
                ...List.generate(
                  current.choices!.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.tonal(
                      onPressed: locked ? null : () => _answer(index),
                      child: Text(current.choices![index]),
                    ),
                  ),
                ),
                if (_touchInteraction != null)
                  TextButton.icon(
                    key: const ValueKey('touch-switch-interaction'),
                    onPressed: locked
                        ? null
                        : () {
                          setState(() => useTouchInput = true);
                          unawaited(_persistSession());
                        },
                    icon: const Icon(Icons.touch_app_rounded),
                    label: const Text('Mit Finger lösen'),
                  ),
              ] else ...[
                if (current.answerSuffix != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Antwort in ${current.answerSuffix}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                NumberAnswerPad(
                  key: ValueKey('${current.key}:$completed'),
                  maxValue: current.maxAnswerValue ??
                      widget.controller.effectiveMaxValue,
                  onAnswer: _answer,
                ),
                if (_touchInteraction != null)
                  TextButton.icon(
                    key: const ValueKey('touch-switch-interaction'),
                    onPressed: locked
                        ? null
                        : () {
                          setState(() => useTouchInput = true);
                          unawaited(_persistSession());
                        },
                    icon: const Icon(Icons.touch_app_rounded),
                    label: const Text('Mit Finger lösen'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RepresentationVisual extends StatelessWidget {
  const _RepresentationVisual({required this.exercise});

  final StructuredExercise exercise;

  @override
  Widget build(BuildContext context) => switch (exercise.representation!) {
        ExerciseRepresentation.placeValue => _PlaceValueVisual(
            number: exercise.representationA!,
          ),
        ExerciseRepresentation.equalGroups => _EqualGroupsVisual(
            groups: exercise.representationA!,
            each: exercise.representationB!,
          ),
      };
}

class _PlaceValueVisual extends StatelessWidget {
  const _PlaceValueVisual({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    const labels = ['E', 'Z', 'H', 'T', 'ZT', 'HT', 'M'];
    final digits = <int>[];
    var remaining = number;
    do {
      digits.add(remaining % 10);
      remaining ~/= 10;
    } while (remaining > 0);

    return Semantics(
      label: 'Stellenwertdarstellung für eine Zahl',
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            digits.length,
            (index) {
              final reversedIndex = digits.length - 1 - index;
              final label = labels[reversedIndex];
              final digit = digits[reversedIndex];
              return Container(
                width: 58,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$digit',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EqualGroupsVisual extends StatelessWidget {
  const _EqualGroupsVisual({
    required this.groups,
    required this.each,
  });

  final int groups;
  final int each;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$groups gleich große Gruppen mit je $each Punkten',
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              groups,
              (_) => Container(
                width: 76,
                constraints: const BoxConstraints(minHeight: 62),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  color:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 5,
                  runSpacing: 5,
                  children: List.generate(
                    each,
                    (_) => Icon(
                      Icons.circle,
                      size: 13,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _MoneyPiece extends StatelessWidget {
  const _MoneyPiece({required this.cents});
  final int cents;

  @override
  Widget build(BuildContext context) {
    final label = cents >= 100 && cents % 100 == 0
        ? '${cents ~/ 100} €'
        : '$cents ct';
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
    );
  }
}

class _NumberWall extends StatelessWidget {
  const _NumberWall({required this.exercise});
  final StructuredExercise exercise;

  @override
  Widget build(BuildContext context) {
    final values = exercise.wallValues!;
    final hidden = exercise.hiddenWallIndex!;
    Widget brick(int index) => Container(
          width: 78,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            color: index == hidden
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            index == hidden ? '?' : '${values[index]}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        );

    return Column(
      children: [
        brick(5),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [brick(3), const SizedBox(width: 8), brick(4)],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            brick(0),
            const SizedBox(width: 8),
            brick(1),
            const SizedBox(width: 8),
            brick(2),
          ],
        ),
      ],
    );
  }
}

class _ClockPainter extends CustomPainter {
  const _ClockPainter({
    required this.hour,
    required this.minute,
    required this.color,
    required this.accent,
  });

  final int hour;
  final int minute;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, outline);

    final tick = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 - math.pi / 2;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 5),
        center.dy + math.sin(angle) * (radius - 5),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 14),
        center.dy + math.sin(angle) * (radius - 14),
      );
      canvas.drawLine(inner, outer, tick);
    }

    final minuteAngle = minute * math.pi / 30 - math.pi / 2;
    final hourAngle = ((hour % 12) + minute / 60) * math.pi / 6 - math.pi / 2;
    final minutePaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final hourPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + math.cos(minuteAngle) * radius * 0.72,
          center.dy + math.sin(minuteAngle) * radius * 0.72),
      minutePaint,
    );
    canvas.drawLine(
      center,
      Offset(center.dx + math.cos(hourAngle) * radius * 0.48,
          center.dy + math.sin(hourAngle) * radius * 0.48),
      hourPaint,
    );
    canvas.drawCircle(center, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) =>
      hour != oldDelegate.hour || minute != oldDelegate.minute;
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter({required this.shape, required this.color});

  final ExerciseShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round;
    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    switch (shape) {
      case ExerciseShape.triangle:
        final path = Path()
          ..moveTo(size.width / 2, 12)
          ..lineTo(size.width - 12, size.height - 12)
          ..lineTo(12, size.height - 12)
          ..close();
        canvas.drawPath(path, paint);
      case ExerciseShape.square:
        final side = math.min(rect.width, rect.height);
        final square = Rect.fromCenter(
          center: rect.center,
          width: side,
          height: side,
        );
        canvas.drawRect(square, paint);
      case ExerciseShape.rectangle:
        canvas.drawRect(rect, paint);
      case ExerciseShape.circle:
        canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) =>
      shape != oldDelegate.shape || color != oldDelegate.color;
}
