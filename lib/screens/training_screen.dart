import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/math_fact.dart';
import '../models/training.dart';
import '../services/app_controller.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({
    super.key,
    required this.controller,
    required this.mode,
    required this.targetTasks,
    this.timeLimit,
  });

  final AppController controller;
  final TrainingMode mode;
  final int targetTasks;
  final Duration? timeLimit;

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
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
  String feedback = '';
  final List<int> completedResponseMs = [];
  int plusTotal = 0;
  int plusCorrect = 0;
  int minusTotal = 0;
  int minusCorrect = 0;

  int get _minusStage {
    final tried = widget.controller.facts
        .where((f) => f.isMinus && f.attempts > 0)
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
    taskShownAt = DateTime.now();
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
        previousKey: completed == 0 ? null : current.key,
      );

  Future<void> _answer(int answer) async {
    if (locked || finishing) return;
    final response = DateTime.now().difference(taskShownAt);
    final correct = answer == current.result;
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
      completedResponseMs.add(response.inMilliseconds.clamp(0, 30000).toInt());
      if (current.isMinus) {
        minusTotal += 1;
      } else {
        plusTotal += 1;
      }
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
        feedback = wrongOnCurrent >= 2
            ? 'Schau dir die Hilfe an und probier noch einmal.'
            : 'Fast. Schau noch einmal.';
        if (wrongOnCurrent >= 2) {
          showHelp = true;
          usedHelp = true;
        }
      });
      return;
    }

    locked = true;
    completed += 1;
    completedResponseMs.add(response.inMilliseconds.clamp(0, 30000).toInt());
    if (wrongOnCurrent == 0) correctFirstTry += 1;
    if (current.isMinus) {
      minusTotal += 1;
      if (wrongOnCurrent == 0) minusCorrect += 1;
    } else {
      plusTotal += 1;
      if (wrongOnCurrent == 0) plusCorrect += 1;
    }
    if (widget.controller.hapticEnabled) HapticFeedback.lightImpact();
    if (widget.controller.soundEnabled) SystemSound.play(SystemSoundType.click);
    setState(() => feedback = ['Richtig!', 'Genau!', 'Stimmt!', 'Gut gerechnet!'][completed % 4]);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted || finishing) return;
    if (completed >= widget.targetTasks) {
      await _finish();
      return;
    }
    _showNextTask();
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
      feedback = '';
      locked = false;
    });
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;
    timer?.cancel();
    locked = true;
    final avg = completedResponseMs.isEmpty
        ? 0.0
        : completedResponseMs.reduce((a, b) => a + b) / completedResponseMs.length;
    final result = TrainingSessionResult(
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
      averageResponseMs: avg,
    );
    if (completed > 0) await widget.controller.addSession(result);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Fertig!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Du hast $completed Aufgaben gerechnet.'),
            const SizedBox(height: 8),
            Text('$correctFirstTry davon waren direkt richtig.'),
            if (widget.mode == TrainingMode.tempo || widget.mode == TrainingMode.speed) ...[
              const SizedBox(height: 8),
              Text('Ø ${(avg / 1000).toStringAsFixed(1)} Sekunden pro Aufgabe'),
            ],
            if (widget.mode == TrainingMode.tempo) ...[
              const SizedBox(height: 8),
              Text('Plus: $plusCorrect/$plusTotal direkt richtig'),
              Text('Minus: $minusCorrect/$minusTotal direkt richtig'),
              Text('Noch offen: ${(widget.targetTasks - completed).clamp(0, widget.targetTasks)}'),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Für jetzt fertig'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTimer = widget.mode == TrainingMode.tempo && widget.timeLimit != null;
    final remainingSeconds = widget.timeLimit == null
        ? null
        : (widget.timeLimit!.inSeconds - elapsed.inSeconds).clamp(0, widget.timeLimit!.inSeconds).toInt();
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.mode.title),
          actions: [
            if (visibleTimer)
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Center(
                  child: Text(
                    '${remainingSeconds! ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: widget.targetTasks == 0 ? 0 : completed / widget.targetTasks,
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
                      Chip(label: Text('Minus · Stufe $_minusStage')),
                      const SizedBox(height: 12),
                    ],
                    if (widget.mode == TrainingMode.numberFriends)
                      Text(
                        '${current.result} = ${current.a} + ?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800),
                      )
                    else
                      Text(
                        '${current.a} ${current.symbol} ${current.b} = ?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800),
                      ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        feedback,
                        key: ValueKey(feedback),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (current.isMinus && showHelp)
                      _MinusHelp(fact: current),
                    if (current.isMinus &&
                        !showHelp &&
                        widget.mode != TrainingMode.tempo &&
                        (widget.mode != TrainingMode.minus || _minusStage <= 2 || wrongOnCurrent > 0))
                      TextButton.icon(
                        onPressed: () => setState(() {
                          usedHelp = true;
                          showHelp = true;
                        }),
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: const Text('Zeig mir eine Hilfe'),
                      ),
                    const SizedBox(height: 24),
                    _AnswerPad(
                      onAnswer: widget.mode == TrainingMode.numberFriends
                          ? (value) => _answer(value == current.b ? current.result : -999)
                          : _answer,
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

class _AnswerPad extends StatelessWidget {
  const _AnswerPad({required this.onAnswer});
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
        ),
        itemCount: 11,
        itemBuilder: (_, i) => FilledButton.tonal(
          onPressed: () => onAnswer(i),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          child: Text('$i'),
        ),
      );
}

class _MinusHelp extends StatelessWidget {
  const _MinusHelp({required this.fact});
  final MathFact fact;

  @override
  Widget build(BuildContext context) {
    final remaining = fact.result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 7,
              runSpacing: 7,
              children: List.generate(
                fact.a,
                (i) => Icon(
                  i < remaining ? Icons.circle : Icons.circle_outlined,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('${fact.a} minus ${fact.b}: Von ${fact.a} nehmen wir ${fact.b} weg.'),
            const SizedBox(height: 5),
            Text('Du kannst auch denken: ${fact.b} + ? = ${fact.a}'),
          ],
        ),
      ),
    );
  }
}
