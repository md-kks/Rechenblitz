import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../widgets/number_answer_pad.dart';
import 'my_round_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({
    super.key,
    required this.controller,
    this.fromOnboarding = false,
  });

  final AppController controller;
  final bool fromOnboarding;

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  late final List<AssessmentTask> tasks;
  final Map<String, int> correctByMode = {};
  final Map<String, int> totalByMode = {};
  int index = 0;
  bool locked = false;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    tasks = AssessmentGenerator().generate(
      grade: widget.controller.gradeLevel,
      range: widget.controller.numberRange,
    );
  }

  AssessmentTask get current => tasks[index];

  Future<void> _answer(int? value) async {
    if (locked || finished) return;
    locked = true;

    final key = current.mode.name;
    totalByMode[key] = (totalByMode[key] ?? 0) + 1;
    if (value != null && value == current.answer) {
      correctByMode[key] = (correctByMode[key] ?? 0) + 1;
    }

    if (index + 1 >= tasks.length) {
      final results = <AssessmentModeResult>[];
      final seen = <String>{};
      for (final task in tasks) {
        if (!seen.add(task.mode.name)) continue;
        results.add(
          AssessmentModeResult(
            mode: task.mode,
            correct: correctByMode[task.mode.name] ?? 0,
            total: totalByMode[task.mode.name] ?? 0,
          ),
        );
      }
      await widget.controller.completeAssessment(results);
      if (!mounted) return;
      setState(() {
        finished = true;
        locked = false;
      });
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() {
      index += 1;
      locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (finished) return _buildResult(context);

    final progress = (index + 1) / tasks.length;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.fromOnboarding,
        title: const Text('Lerncheck'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text(
              'Aufgabe ${index + 1} von ${tasks.length}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Ohne Zeitdruck · ohne Note',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 34),
            Text(
              current.prompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (current.answerSuffix != null) ...[
              const SizedBox(height: 8),
              Text(
                'Antwort in ${current.answerSuffix}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 30),
            if (current.usesChoices)
              ...List.generate(
                current.choices!.length,
                (choiceIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.tonal(
                    key: ValueKey('assessment-choice-$choiceIndex'),
                    onPressed: locked ? null : () => _answer(choiceIndex),
                    child: Text(
                      current.choices![choiceIndex],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              NumberAnswerPad(
                key: ValueKey('assessment-answer-$index'),
                maxValue: current.maxAnswerValue,
                onAnswer: _answer,
              ),
            const SizedBox(height: 14),
            TextButton.icon(
              key: const ValueKey('assessment-dont-know'),
              onPressed: locked ? null : () => _answer(null),
              icon: const Icon(Icons.help_outline_rounded),
              label: const Text('Weiß ich noch nicht'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final focus = widget.controller.recommendedMode();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Lerncheck'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 34),
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Lerncheck geschafft!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Rechenblitz kennt jetzt einen guten Startpunkt. Beim Üben wird die Lernlandkarte immer genauer.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.route_rounded,
                      size: 34,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Als Nächstes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      focus.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Damit starten wir in deiner ersten Runde.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              key: const ValueKey('assessment-start-my-round'),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        MyRoundScreen(controller: widget.controller),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Erste Runde starten'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zur Startseite'),
            ),
          ],
        ),
      ),
    );
  }
}
