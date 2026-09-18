import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cube_net.dart';
import '../models/curriculum_exercise.dart';
import '../models/active_response_timer.dart';
import '../models/adaptive_segment.dart';
import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import '../models/help_preferences.dart';
import '../models/micro_competency.dart';
import '../models/training.dart';
import '../models/training_session_progress.dart';
import '../models/touch_interaction.dart';
import '../services/app_controller.dart';
import '../widgets/geometry_relation_visual.dart';
import '../widgets/guided_method_panel.dart';
import '../widgets/independent_step_card.dart';
import '../widgets/number_answer_pad.dart';
import '../widgets/round_completion_dialog.dart';
import '../widgets/touch_answer_interaction.dart';

class CurriculumTrainingScreen extends StatefulWidget {
  const CurriculumTrainingScreen({
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
  final CurriculumExerciseGenerator? exerciseGenerator;

  @override
  State<CurriculumTrainingScreen> createState() =>
      _CurriculumTrainingScreenState();
}

class _CurriculumTrainingScreenState extends State<CurriculumTrainingScreen>
    with WidgetsBindingObserver {
  HelpPreferences get _helpPreferences => widget.controller.helpPreferences;
  HelpLevel? get _manualHelpLevel => _helpPreferences.manualStartLevel;
  bool get _helpAvailable => _helpPreferences.enabled;
  TouchInteractionPlan? get _touchInteraction => TouchInteractionPlan.forTask(
        mode: widget.mode,
        taskKey: current.key,
        answer: current.answer,
        maxValue: current.maxAnswerValue ?? widget.controller.effectiveMaxValue,
        choices: current.choices,
        answerSuffix: current.answerSuffix,
        targetCompetency: widget.targetCompetency,
      );

  MicroEvidenceSource get _evidenceSource => widget.transferEmphasis
      ? MicroEvidenceSource.transfer
      : widget.reviewEmphasis
          ? MicroEvidenceSource.review
          : MicroEvidenceSource.practice;

  late final CurriculumExerciseGenerator generator;
  late CurriculumExercise current;
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
  int taskIndex = 0;
  int checkpointIndex = 0;
  final Set<int> checkpointAttempted = <int>{};
  final Map<int, int> checkpointWrongAttempts = <int, int>{};
  bool checkpointLocked = false;
  bool hadCheckpointError = false;
  Future<void>? taskRememberFuture;
  String checkpointFeedback = '';

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
    generator = widget.exerciseGenerator ?? CurriculumExerciseGenerator();
    final saved = widget.exerciseGenerator == null
        ? widget.controller.resumableCoreTrainingSession(
      kind: CoreTrainingKind.curriculum,
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
      current = decodeCurriculumExercise(saved.currentTask);
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
        kind: CoreTrainingKind.curriculum,
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
        currentTask: encodeCurriculumExercise(current),
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
    taskIndex = completed;
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

  CurriculumExercise _next() => generator.generate(
        mode: widget.mode,
        gradeLevel: widget.controller.effectiveGradeLevel,
        maxValue: widget.controller.effectiveMaxValue,
        recentKeys: widget.controller.recentTaskKeys(widget.mode),
        targetCompetency: widget.targetCompetency,
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

  List<GuidedMethodStep> get _independentWrittenSteps {
    if (widget.reviewEmphasis ||
        widget.transferEmphasis ||
        !IndependentArithmeticStepPolicy.shouldProbeTask(
          taskIndex,
          scaffoldFading: widget.scaffoldFading,
        )) {
      return const <GuidedMethodStep>[];
    }
    return GuidedMethodFactory.independentWrittenStepsForTask(
      mode: widget.mode,
      taskKey: current.key,
      expected: current.answer,
      preferences: widget.controller.effectiveMethodPreferences,
      targetCompetency: widget.targetCompetency,
    );
  }

  bool get _checkpointsComplete =>
      checkpointIndex >= _independentWrittenSteps.length;

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

    final steps = _independentWrittenSteps;
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
        usedHelp: showHint,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
        evidenceWeight: step.evidenceWeight,
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
        _independentWrittenSteps.length <= index) {
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
      '${startedAt.microsecondsSinceEpoch}:curriculum:$completed:${current.key}';

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
      );

  Future<void> _recordPendingFirstAttempt(
    PendingFirstAttemptEvidence receipt,
  ) async {
    if (taskFirstAttemptRecorded) return;
    await _rememberCurrentTaskOnce();
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
        if (wrongOnCurrent >= 2 && retryHelp != null) {
          showHint = true;
          if (helpLevel < retryHelp.value) {
            helpLevel = retryHelp.value;
          }
          activeMethodKey ??= _guide.methodKey;
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
    if (firstTry) correctFirstTry += 1;
    if (!restoring && widget.controller.hapticEnabled) {
      HapticFeedback.lightImpact();
    }
    if (!restoring && widget.controller.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    setState(() {
      feedback = [
        'Richtig!',
        'Genau!',
        'Stimmt!',
        'Gut gelöst!',
      ][completed % 4];
    });
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
    final reason = widget.controller.rewardReasonForSession(result);
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
      starsEarned: result.starsEarned,
      rewardReason: reason,
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
    final promptFontSize = compactHeight ? 27.0 : 31.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.title),
        actions: [
          if (compactHeight && _helpAvailable && !showHint)
            IconButton(
              key: const ValueKey('curriculum-compact-help'),
              tooltip: 'Ich brauche Hilfe',
              onPressed: _showManualHelp,
              icon: const Icon(Icons.lightbulb_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: KeyedSubtree(
          key: ValueKey('curriculum-training-task:$completed:${current.key}'),
          child: ListView(
            key: const ValueKey('curriculum-training-scroll'),
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
                  child: Text(
                    current.prompt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: promptFontSize,
                      height: 1.3,
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
            if (current.key.startsWith('geomrel:') &&
                !(useTouchInput &&
                    _touchInteraction?.kind ==
                        TouchInteractionKind.geometryRelationChoice)) ...[
              SizedBox(height: visualGap),
              GeometryRelationVisual(taskKey: current.key),
            ],
            if (current.hasBars &&
                !(useTouchInput &&
                    _touchInteraction?.kind ==
                        TouchInteractionKind.dataChartSelection)) ...[
              SizedBox(height: visualGap),
              _BarChart(bars: current.bars!),
            ],
            if (current.hasCubeNet &&
                !(useTouchInput &&
                    _touchInteraction?.kind == TouchInteractionKind.cubeNetFoldChoice)) ...[
              SizedBox(height: visualGap),
              _CubeNetView(
                cells: current.cubeNetCells!,
                labels: current.cubeNetLabels ?? const <GridCell, String>{},
              ),
            ],
            SizedBox(height: sectionGap),
            if (!_checkpointsComplete) ...[
              IndependentStepCard(
                question:
                    _independentWrittenSteps[checkpointIndex].question!,
                choices:
                    _independentWrittenSteps[checkpointIndex].choices,
                index: checkpointIndex,
                total: _independentWrittenSteps.length,
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
                onStepAttempt: (step, correct) {
                  return widget.controller.recordGuidedStepAttempt(
                    mode: widget.mode,
                    taskKey: current.key,
                    methodKey: activeMethodKey ?? _guide.methodKey,
                    stepKey: step.evidenceKey!,
                    competencyId: step.evidenceCompetency!,
                    correct: correct,
                    evidenceWeight: step.evidenceWeight,
                  );
                },
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
            if (_checkpointsComplete)
              if (current.usesChoices &&
                  useTouchInput &&
                  _touchInteraction != null) ...[
                TouchAnswerInteraction(
                  key: ValueKey('touch:${current.key}:$completed'),
                  plan: _touchInteraction!,
                  locked: locked,
                  onAnswer: _answer,
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  key: const ValueKey('touch-switch-choices'),
                  onPressed: locked
                      ? null
                      : () {
                          setState(() => useTouchInput = false);
                          unawaited(_persistSession());
                        },
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('Lieber auswählen'),
                ),
              ] else if (current.usesChoices) ...[
                ...List.generate(
                  current.choices!.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.tonal(
                      onPressed: locked ? null : () => _answer(index),
                      child: Text(
                        current.choices![index],
                        textAlign: TextAlign.center,
                      ),
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
                if (useTouchInput && _touchInteraction != null) ...[
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
                    icon: const Icon(Icons.dialpad_rounded),
                    label: const Text('Lieber eintippen'),
                  ),
                ] else ...[
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
          ],
        ),
      ),
    ),
    );
  }
}

class _CubeNetView extends StatelessWidget {
  const _CubeNetView({
    required this.cells,
    required this.labels,
  });

  final List<GridCell> cells;
  final Map<GridCell, String> labels;

  @override
  Widget build(BuildContext context) {
    final maxX = cells.map((cell) => cell.x).reduce((a, b) => a > b ? a : b);
    final maxY = cells.map((cell) => cell.y).reduce((a, b) => a > b ? a : b);
    final columns = maxX + 1;
    final rows = maxY + 1;
    final occupied = cells.toSet();

    return Semantics(
      label: labels.isEmpty
          ? 'Würfelnetz aus sechs Quadraten'
          : 'Würfelnetz aus sechs Quadraten. Die Flächen A, B und C sind markiert.',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: AspectRatio(
            aspectRatio: columns / rows,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows * columns,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
              ),
              itemBuilder: (context, index) {
                final x = index % columns;
                final y = index ~/ columns;
                final cell = GridCell(x, y);
                final filled = occupied.contains(cell);
                final label = labels[cell];
                return Container(
                  margin: const EdgeInsets.all(1.5),
                  decoration: filled
                      ? BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        )
                      : null,
                  child: filled && label != null
                      ? Center(
                          child: Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.bars});

  final List<CurriculumBar> bars;

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<int>(
      1,
      (current, bar) => bar.value > current ? bar.value : current,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: bars
              .map(
                (bar) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          bar.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: bar.value / maxValue,
                          minHeight: 18,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${bar.value}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
