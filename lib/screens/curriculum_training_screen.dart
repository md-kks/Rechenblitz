import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/curriculum_exercise.dart';
import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import '../models/micro_competency.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../widgets/guided_method_panel.dart';
import '../widgets/number_answer_pad.dart';

class CurriculumTrainingScreen extends StatefulWidget {
  const CurriculumTrainingScreen({
    super.key,
    required this.controller,
    required this.mode,
    this.targetTasks = 10,
    this.targetCompetency,
  });

  final AppController controller;
  final TrainingMode mode;
  final int targetTasks;
  final MicroCompetencyId? targetCompetency;

  @override
  State<CurriculumTrainingScreen> createState() =>
      _CurriculumTrainingScreenState();
}

class _CurriculumTrainingScreenState extends State<CurriculumTrainingScreen> {
  final CurriculumExerciseGenerator generator = CurriculumExerciseGenerator();
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
  int helpLevel = 0;
  String? activeMethodKey;
  String feedback = '';
  final List<int> responseTimes = [];

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    current = _next();
    shownAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(current.prompt),
    );
  }

  CurriculumExercise _next() => generator.generate(
        mode: widget.mode,
        gradeLevel: widget.controller.effectiveGradeLevel,
        maxValue: widget.controller.effectiveMaxValue,
        recentKeys: widget.controller.recentTaskKeys(widget.mode),
        targetCompetency: widget.targetCompetency,
      );

  ErrorPattern get _helpPattern =>
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



  Future<void> _answer(int answer) async {
    if (locked || finishing) return;
    final response = DateTime.now().difference(shownAt);
    if (wrongOnCurrent == 0) {
      await widget.controller.rememberPresentedTask(
        widget.mode,
        current.key,
      );
      await widget.controller.recordDiagnosticAttempt(
        mode: widget.mode,
        taskKey: current.key,
        expected: current.answer,
        actual: answer,
        usedHelp: showHint,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
      );
    }
    if (answer != current.answer) {
      incorrectAttempts += 1;
      wrongOnCurrent += 1;
      setState(() {
        feedback = wrongOnCurrent >= 2
            ? 'Nutze den Rechenhinweis und probiere noch einmal.'
            : 'Fast. Prüfe deinen Rechenweg noch einmal.';
        if (wrongOnCurrent >= 2) {
          showHint = true;
          if (helpLevel < HelpLevel.nudge.value) {
            helpLevel = HelpLevel.nudge.value;
          }
          activeMethodKey ??= _guide.methodKey;
        }
      });
      return;
    }

    locked = true;
    completed += 1;
    responseTimes.add(response.inMilliseconds.clamp(0, 30000).toInt());
    if (wrongOnCurrent == 0) correctFirstTry += 1;
    if (widget.controller.hapticEnabled) HapticFeedback.lightImpact();
    if (widget.controller.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    setState(() {
      feedback = [
        'Richtig!',
        'Genau!',
        'Rechenweg stimmt!',
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
      showHint = false;
      helpLevel = 0;
      activeMethodKey = null;
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
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Runde geschafft!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$completed Aufgaben bearbeitet.'),
              const SizedBox(height: 8),
              Text('$correctFirstTry direkt richtig.'),
              const SizedBox(height: 14),
              Text(
                '+${result.starsEarned} ★',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(reason),
              if (newBadges.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Neues Abzeichen!',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                ...newBadges.map(
                  (badge) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('🏅 ${badge.title}  +${badge.stars} ★'),
                  ),
                ),
              ],
            ],
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode.title} · ${widget.controller.effectiveGradeLevel.label}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(widget.controller.effectiveGradeLevel.label)),
                Chip(label: Text(widget.controller.effectiveNumberRange.label)),
                if (current.method != null)
                  Chip(
                    avatar: const Icon(Icons.route_rounded, size: 18),
                    label: Text(current.method!),
                  ),
              ],
            ),
            const SizedBox(height: 22),
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
            if (current.hasBars) ...[
              const SizedBox(height: 22),
              _BarChart(bars: current.bars!),
            ],
            const SizedBox(height: 18),
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
                pattern: _helpPattern,
                taskKey: current.key,
                expected: current.answer,
                onHelpLevelChanged: (level) {
                  if (!mounted) return;
                  setState(() {
                    helpLevel = level.value;
                    activeMethodKey = _guide.methodKey;
                  });
                },
                onSpeak: widget.controller.speakOnDemand,
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() {
                showHint = true;
                helpLevel = HelpLevel.nudge.value;
                activeMethodKey = _guide.methodKey;
              }),
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: const Text('Rechenhinweis anzeigen'),
              ),
            ],
            const SizedBox(height: 18),
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
              NumberAnswerPad(
                key: ValueKey('${current.key}:$completed'),
                maxValue: current.maxAnswerValue ?? widget.controller.effectiveMaxValue,
                onAnswer: _answer,
              ),
            ],
          ],
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
