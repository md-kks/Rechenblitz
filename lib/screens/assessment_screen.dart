import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../models/touch_interaction.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../widgets/number_answer_pad.dart';
import '../widgets/touch_answer_interaction.dart';
import 'my_round_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({
    super.key,
    required this.controller,
    this.fromOnboarding = false,
    this.generator,
  });

  final AppController controller;
  final bool fromOnboarding;
  final AssessmentGenerator? generator;

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  late final List<AssessmentTask> tasks;
  final Map<String, int> correctByMode = {};
  final Map<String, int> totalByMode = {};
  final List<AssessmentTaskResult> taskResults = <AssessmentTaskResult>[];
  int index = 0;
  bool locked = false;
  bool finished = false;
  bool useTouchInput = true;

  @override
  void initState() {
    super.initState();
    tasks = (widget.generator ?? AssessmentGenerator()).generate(
      grade: widget.controller.gradeLevel,
      range: widget.controller.numberRange,
    );
  }

  AssessmentTask get current => tasks[index];

  TouchInteractionPlan? get _touchInteraction => TouchInteractionPlan.forTask(
        mode: current.mode,
        taskKey: current.taskKey,
        answer: current.answer,
        maxValue: current.maxAnswerValue,
        wallValues: current.wallValues,
        hiddenWallIndex: current.hiddenWallIndex,
        choices: current.choices,
        clockHour: current.clockHour,
        clockMinute: current.clockMinute,
        answerSuffix: current.answerSuffix,
        targetCompetency: null,
      );

  Future<void> _answer(int? value) async {
    if (locked || finished) return;
    locked = true;

    final key = current.mode.name;
    final correct = value != null && value == current.answer;
    totalByMode[key] = (totalByMode[key] ?? 0) + 1;
    if (correct) {
      correctByMode[key] = (correctByMode[key] ?? 0) + 1;
    }
    taskResults.add(
      AssessmentTaskResult(
        mode: current.mode,
        taskKey: current.taskKey,
        correct: correct,
        fact: current.fact,
        targetCompetency: current.targetCompetency,
      ),
    );

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
      await widget.controller.completeAssessment(
        results,
        taskResults: taskResults,
      );
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
      useTouchInput = true;
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
            if (useTouchInput && _touchInteraction != null) ...[
              TouchAnswerInteraction(
                key: ValueKey('assessment-touch-$index'),
                plan: _touchInteraction!,
                locked: locked,
                onAnswer: _answer,
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                key: const ValueKey('assessment-touch-switch-classic'),
                onPressed: locked
                    ? null
                    : () => setState(() => useTouchInput = false),
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
              ),
              if (_touchInteraction != null)
                TextButton.icon(
                  key: const ValueKey('assessment-touch-switch-interaction'),
                  onPressed: locked
                      ? null
                      : () => setState(() => useTouchInput = true),
                  icon: const Icon(Icons.touch_app_rounded),
                  label: const Text('Mit Finger lösen'),
                ),
            ] else ...[
              NumberAnswerPad(
                key: ValueKey('assessment-answer-$index'),
                maxValue: current.maxAnswerValue,
                onAnswer: _answer,
              ),
              if (_touchInteraction != null)
                TextButton.icon(
                  key: const ValueKey('assessment-touch-switch-interaction'),
                  onPressed: locked
                      ? null
                      : () => setState(() => useTouchInput = true),
                  icon: const Icon(Icons.touch_app_rounded),
                  label: const Text('Mit Finger lösen'),
                ),
            ],
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
    final microFocus = widget.controller.currentMicroFocus();
    final focusLabel = microFocus?.definition.label ?? focus.title;

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
                      focusLabel,
                      key: const ValueKey('assessment-next-focus'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (microFocus != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        microFocus.definition.preferredMode.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
