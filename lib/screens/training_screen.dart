import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import '../models/math_fact.dart';
import '../models/micro_competency.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../widgets/guided_method_panel.dart';
import '../widgets/number_answer_pad.dart';

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
  });

  final AppController controller;
  final TrainingMode mode;
  final int targetTasks;
  final Duration? timeLimit;
  final MicroCompetencyId? targetCompetency;
  final bool reviewEmphasis;
  final bool transferEmphasis;

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  MicroEvidenceSource get _evidenceSource => widget.transferEmphasis
      ? MicroEvidenceSource.transfer
      : widget.reviewEmphasis
          ? MicroEvidenceSource.review
          : MicroEvidenceSource.practice;

  late MathFact current;
  late DateTime taskShownAt;
  late DateTime startedAt;
  Timer? timer;
  Duration elapsed = Duration.zero;
  int completed = 0;
  int incorrectAttempts = 0;
  int correctFirstTry = 0;
  int wrongOnCurrent = 0;
  bool usedHelp = false;
  bool showHelp = false;
  bool locked = false;
  bool finishing = false;
  bool helpCountedForCurrent = false;
  int helpLevel = 0;
  String? activeMethodKey;
  String feedback = '';
  ErrorPattern? currentErrorPattern;
  final List<int> completedResponseMs = [];
  int plusTotal = 0;
  int plusCorrect = 0;
  int minusTotal = 0;
  int minusCorrect = 0;
  int multiplyTotal = 0;
  int multiplyCorrect = 0;
  int divideTotal = 0;
  int divideCorrect = 0;

  int get _minusStage {
    final tried = widget.controller.facts
        .where((f) =>
            f.isMinus &&
            f.attempts > 0 &&
            f.a <= widget.controller.effectiveMaxValue &&
            f.b <= widget.controller.effectiveMaxValue)
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

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    current = _next();
    usedHelp = widget.mode == TrainingMode.minus && _minusStage == 1;
    showHelp = usedHelp;
    helpLevel = showHelp ? HelpLevel.nudge.value : 0;
    activeMethodKey = showHelp ? _guide.methodKey : null;
    taskShownAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(_spokenTask),
    );
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => elapsed = DateTime.now().difference(startedAt));
      if (widget.timeLimit != null && elapsed >= widget.timeLimit!) {
        _finish();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  MathFact _next() => widget.controller.engine.selectNext(
        facts: widget.controller.facts,
        mode: widget.mode,
        maxValue: widget.controller.effectiveMaxValue,
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

  String get _spokenTask => widget.mode == TrainingMode.numberFriends
      ? '${current.result} ist gleich ${current.a} plus welche Zahl?'
      : '${current.a} ${current.symbol} ${current.b} ist gleich?';

  int get _expectedAnswer =>
      widget.mode == TrainingMode.numberFriends ? current.b : current.result;

  Future<void> _answer(int answer) async {
    if (locked || finishing) return;
    final response = DateTime.now().difference(taskShownAt);
    final correct = answer == _expectedAnswer;
    final diagnosedPattern = correct
        ? null
        : ErrorClassifier.classify(
            mode: widget.mode,
            taskKey: current.key,
            expected: _expectedAnswer,
            actual: answer,
            fact: current,
          );
    if (wrongOnCurrent == 0) {
      await widget.controller.rememberPresentedTask(
        widget.mode,
        current.key,
      );
      await widget.controller.recordDiagnosticAttempt(
        mode: widget.mode,
        taskKey: current.key,
        expected: _expectedAnswer,
        actual: answer,
        fact: current,
        usedHelp: usedHelp || showHelp,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
        source: _evidenceSource,
      );
    }
    await widget.controller.recordAttempt(
      current,
      correct: correct,
      responseTime: response,
      usedHelp: usedHelp && !helpCountedForCurrent,
    );
    if (usedHelp) helpCountedForCurrent = true;
    if (!mounted || finishing) return;

    if (!correct && widget.mode == TrainingMode.tempo) {
      incorrectAttempts += 1;
      completed += 1;
      completedResponseMs
          .add(response.inMilliseconds.clamp(0, 30000).toInt());
      _countCompletedFact(firstTryCorrect: false);
      locked = true;
      setState(() => feedback = 'Weiter geht’s.');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || finishing) return;
      if (completed >= widget.targetTasks) {
        await _finish();
        return;
      }
      _showNextTask();
      return;
    }

    if (!correct) {
      incorrectAttempts += 1;
      wrongOnCurrent += 1;
      setState(() {
        currentErrorPattern ??= diagnosedPattern;
        feedback = wrongOnCurrent >= 2
            ? 'Schau dir die Hilfe an und probier noch einmal.'
            : diagnosedPattern?.firstResponseHint ??
                'Prüfe deinen Rechenweg noch einmal.';
        if (wrongOnCurrent >= 2) {
          showHelp = true;
          usedHelp = true;
          if (helpLevel < HelpLevel.nudge.value) {
            helpLevel = HelpLevel.nudge.value;
          }
          activeMethodKey ??= _guide.methodKey;
        }
      });
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
      if (!mounted || finishing) return;
    }

    locked = true;
    completed += 1;
    completedResponseMs
        .add(response.inMilliseconds.clamp(0, 30000).toInt());
    final firstTry = wrongOnCurrent == 0;
    if (firstTry) correctFirstTry += 1;
    _countCompletedFact(firstTryCorrect: firstTry);
    if (widget.controller.hapticEnabled) HapticFeedback.lightImpact();
    if (widget.controller.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    setState(() => feedback =
        ['Richtig!', 'Genau!', 'Stimmt!', 'Gut gerechnet!'][completed % 4]);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted || finishing) return;
    if (completed >= widget.targetTasks) {
      await _finish();
      return;
    }
    _showNextTask();
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
      taskShownAt = DateTime.now();
      wrongOnCurrent = 0;
      helpCountedForCurrent = false;
      usedHelp = widget.mode == TrainingMode.minus && _minusStage == 1;
      showHelp = usedHelp;
      helpLevel = showHelp ? HelpLevel.nudge.value : 0;
      activeMethodKey = showHelp ? _guide.methodKey : null;
      currentErrorPattern = null;
      feedback = '';
      locked = false;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(_spokenTask),
    );
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;
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
    );
    final rewardReason = widget.controller.rewardReasonForSession(result);
    result = result.copyWith(
      starsEarned: widget.controller.rewardStarsForSession(result),
    );
    if (completed > 0) await widget.controller.addSession(result);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Runde geschafft!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Du hast $completed Aufgaben gerechnet.'),
            const SizedBox(height: 8),
            Text('$correctFirstTry davon waren direkt richtig.'),
            if (widget.mode == TrainingMode.tempo ||
                widget.mode == TrainingMode.speed) ...[
              const SizedBox(height: 8),
              Text('Ø ${(avg / 1000).toStringAsFixed(1)} Sekunden pro Aufgabe'),
            ],
            if (result.starsEarned > 0) ...[
              const SizedBox(height: 14),
              Text(
                '+${result.starsEarned} ★',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(rewardReason),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTimer =
        widget.mode == TrainingMode.tempo && widget.timeLimit != null;
    final remainingSeconds = widget.timeLimit == null
        ? null
        : (widget.timeLimit!.inSeconds - elapsed.inSeconds)
            .clamp(0, widget.timeLimit!.inSeconds)
            .toInt();
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode.title} · ${widget.controller.effectiveNumberRange.label}'),
        actions: [
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
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 40),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: widget.targetTasks == 0
                              ? 0
                              : completed / widget.targetTasks,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$completed/${widget.targetTasks}'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (widget.mode == TrainingMode.minus) ...[
                    Chip(label: Text('Minus · Lernstufe $_minusStage')),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: widget.mode == TrainingMode.numberFriends
                            ? Text(
                                '${current.result} = ${current.a} + ?',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : Text(
                                '${current.a} ${current.symbol} ${current.b} = ?',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w800,
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
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 12),
                  if (showHelp)
                    GuidedMethodPanel(
                      key: ValueKey('guide:${current.key}:$completed'),
                      guide: _guide,
                      pattern: _helpPattern,
                      taskKey: current.key,
                      expected: _expectedAnswer,
                      onHelpLevelChanged: (level) {
                        if (!mounted) return;
                        setState(() {
                          usedHelp = true;
                          helpLevel = level.value;
                          activeMethodKey = _guide.methodKey;
                        });
                      },
                      onSpeak: widget.controller.speakOnDemand,
                    ),
                  if (!showHelp &&
                      widget.mode != TrainingMode.tempo &&
                      (current.isMinus || current.isMultiply || current.isDivide))
                    TextButton.icon(
                      onPressed: () => setState(() {
                        usedHelp = true;
                        showHelp = true;
                        helpLevel = HelpLevel.nudge.value;
                        activeMethodKey = _guide.methodKey;
                      }),
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Zeig mir eine Hilfe'),
                    ),
                  const SizedBox(height: 24),
                  NumberAnswerPad(
                    key: ValueKey('${current.key}:$completed'),
                    maxValue: widget.controller.effectiveMaxValue,
                    onAnswer: _answer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

