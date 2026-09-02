import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/structured_exercise.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../widgets/number_answer_pad.dart';

class StructuredTrainingScreen extends StatefulWidget {
  const StructuredTrainingScreen({
    super.key,
    required this.controller,
    required this.mode,
    this.targetTasks = 10,
  });

  final AppController controller;
  final TrainingMode mode;
  final int targetTasks;

  @override
  State<StructuredTrainingScreen> createState() =>
      _StructuredTrainingScreenState();
}

class _StructuredTrainingScreenState extends State<StructuredTrainingScreen> {
  final StructuredExerciseGenerator generator = StructuredExerciseGenerator();
  late StructuredExercise current;
  late DateTime startedAt;
  late DateTime shownAt;
  int completed = 0;
  int correctFirstTry = 0;
  int incorrectAttempts = 0;
  int wrongOnCurrent = 0;
  bool locked = false;
  bool finishing = false;
  bool showHint = false;
  String feedback = '';
  final List<int> responseTimes = [];

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    current = _next();
    shownAt = DateTime.now();
  }

  StructuredExercise _next() => generator.generate(
        mode: widget.mode,
        maxValue: widget.controller.maxValue,
      );

  Future<void> _answer(int answer) async {
    if (locked || finishing) return;
    final response = DateTime.now().difference(shownAt);
    if (answer != current.answer) {
      incorrectAttempts += 1;
      wrongOnCurrent += 1;
      setState(() {
        feedback = wrongOnCurrent >= 2
            ? 'Nutze den Hinweis und probier noch einmal.'
            : 'Fast. Schau noch einmal.';
        showHint = wrongOnCurrent >= 2;
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
    setState(() => feedback =
        ['Richtig!', 'Genau!', 'Stimmt!', 'Gut gelöst!'][completed % 4]);
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
      feedback = '';
    });
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
      numberRange: widget.controller.numberRange,
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
            Text(rewardReason),
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
              '${widget.mode.title} · ${widget.controller.numberRange.label}'),
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
              const SizedBox(height: 30),
              if (current.isNumberWall) ...[
                Text(
                  current.prompt,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 22),
                _NumberWall(exercise: current),
              ] else
                Text(
                  current.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 38, fontWeight: FontWeight.w800),
                ),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded),
                        const SizedBox(width: 10),
                        Expanded(child: Text(current.hint)),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => showHint = true),
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('Hinweis anzeigen'),
                ),
              ],
              const SizedBox(height: 18),
              NumberAnswerPad(
                key: ValueKey('${current.key}:$completed'),
                maxValue: widget.controller.maxValue,
                onAnswer: _answer,
              ),
            ],
          ),
        ),
      );
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
