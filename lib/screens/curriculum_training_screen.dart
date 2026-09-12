import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cube_net.dart';
import '../models/curriculum_exercise.dart';
import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import '../models/help_preferences.dart';
import '../models/micro_competency.dart';
import '../models/training.dart';
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
    this.scaffoldFading = false,
    this.exerciseGenerator,
  });

  final AppController controller;
  final TrainingMode mode;
  final int targetTasks;
  final MicroCompetencyId? targetCompetency;
  final bool reviewEmphasis;
  final bool transferEmphasis;
  final bool scaffoldFading;
  final CurriculumExerciseGenerator? exerciseGenerator;

  @override
  State<CurriculumTrainingScreen> createState() =>
      _CurriculumTrainingScreenState();
}

class _CurriculumTrainingScreenState extends State<CurriculumTrainingScreen> {
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
      );

  MicroEvidenceSource get _evidenceSource => widget.transferEmphasis
      ? MicroEvidenceSource.transfer
      : widget.reviewEmphasis
          ? MicroEvidenceSource.review
          : MicroEvidenceSource.practice;

  late final CurriculumExerciseGenerator generator;
  late CurriculumExercise current;
  late DateTime startedAt;
  late DateTime shownAt;
  int completed = 0;
  int correctFirstTry = 0;
  int incorrectAttempts = 0;
  int wrongOnCurrent = 0;
  bool locked = false;
  bool finishing = false;
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

  @override
  void initState() {
    super.initState();
    generator = widget.exerciseGenerator ?? CurriculumExerciseGenerator();
    startedAt = DateTime.now();
    current = _next();
    _prepareHelpForCurrent();
    shownAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(current.prompt),
    );
  }

  void _prepareHelpForCurrent() {
    taskIndex = completed;
    checkpointIndex = 0;
    checkpointAttempted.clear();
    checkpointWrongAttempts.clear();
    checkpointLocked = false;
    hadCheckpointError = false;
    taskRememberFuture = null;
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
      unawaited(_rememberCurrentTaskOnce());
      unawaited(
        widget.controller.recordIndependentStepAttempt(
          mode: widget.mode,
          taskKey: current.key,
          stepKey: step.evidenceKey!,
          competencyId: step.evidenceCompetency!,
          correct: correct,
          usedHelp: showHint,
          helpLevel: helpLevel,
          methodKey: activeMethodKey,
          evidenceWeight: step.evidenceWeight,
        ),
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
  }

  Future<void> _answer(int answer) async {
    if (locked || finishing || !_checkpointsComplete) return;
    final response = DateTime.now().difference(shownAt);
    final diagnosedPattern = answer == current.answer
        ? null
        : ErrorClassifier.classify(
            mode: widget.mode,
            taskKey: current.key,
            expected: current.answer,
            actual: answer,
          );
    if (wrongOnCurrent == 0) {
      await _rememberCurrentTaskOnce();
      await widget.controller.recordDiagnosticAttempt(
        mode: widget.mode,
        taskKey: current.key,
        expected: current.answer,
        actual: answer,
        usedHelp: showHint,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
        source: _evidenceSource,
      );
    }
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
      });
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
    responseTimes.add(response.inMilliseconds.clamp(0, 30000).toInt());
    final firstTry = wrongOnCurrent == 0 && !hadCheckpointError;
    if (firstTry) correctFirstTry += 1;
    if (widget.controller.hapticEnabled) HapticFeedback.lightImpact();
    if (widget.controller.soundEnabled) {
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
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted || finishing) return;
    if (completed >= widget.targetTasks) {
      await _finish();
      return;
    }
    setState(() {
      current = _next();
      shownAt = DateTime.now();
      wrongOnCurrent = 0;
      locked = false;
      _prepareHelpForCurrent();
      currentErrorPattern = null;
      feedback = '';
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(current.prompt),
    );
  }

  Future<void> _finish() async {
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
    );
    final reason = widget.controller.rewardReasonForSession(result);
    result = result.copyWith(
      starsEarned: widget.controller.rewardStarsForSession(result),
    );
    if (completed > 0) await widget.controller.addSession(result);
    final newBadges = widget.controller.lastSessionNewBadges;
    if (!mounted) return;
    await showRoundCompletionDialog(
      context,
      completed: completed,
      correctFirstTry: correctFirstTry,
      starsEarned: result.starsEarned,
      rewardReason: reason,
      newBadges: newBadges,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
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
              'Aufgabe ${completed < widget.targetTasks ? completed + 1 : widget.targetTasks} von ${widget.targetTasks}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    current.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 31,
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
            if (current.key.startsWith('geomrel:')) ...[
              const SizedBox(height: 22),
              GeometryRelationVisual(taskKey: current.key),
            ],
            if (current.hasBars) ...[
              const SizedBox(height: 22),
              _BarChart(bars: current.bars!),
            ],
            if (current.hasCubeNet) ...[
              const SizedBox(height: 22),
              _CubeNetView(
                cells: current.cubeNetCells!,
                labels: current.cubeNetLabels ?? const <GridCell, String>{},
              ),
            ],
            const SizedBox(height: 18),
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
              const SizedBox(height: 12),
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
                },
                onGuideChanged: (guide) {
                  if (!mounted) return;
                  setState(() {
                    activeMethodKey = guide.methodKey;
                  });
                },
                onSpeak: widget.controller.speakOnDemand,
              ),
            ] else if (_helpAvailable) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  final starter = _manualHelpLevel;
                  if (starter == null) return;
                  setState(() {
                    showHint = true;
                    helpLevel = starter.value;
                    activeMethodKey = _guide.methodKey;
                  });
                },
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: const Text('Ich brauche Hilfe'),
              ),
            ],
            const SizedBox(height: 18),
            if (_checkpointsComplete)
              if (current.usesChoices)
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
                )
              else ...[
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
                        : () => setState(() => useTouchInput = false),
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
                          : () => setState(() => useTouchInput = true),
                      icon: const Icon(Icons.touch_app_rounded),
                      label: const Text('Mit Finger lösen'),
                    ),
                ],
              ],
          ],
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
