import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../models/learning_path.dart';
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
        title: const Text('Kurzer Lerncheck'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${index + 1}/${tasks.length}'),
              ],
            ),
            const SizedBox(height: 18),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.favorite_outline_rounded),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kein Test und keine Note. Wenn du etwas noch nicht weißt, ist das völlig okay.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              current.mode.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            Text(
              current.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 31,
                height: 1.28,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (current.answerSuffix != null) ...[
              const SizedBox(height: 8),
              Text(
                'Antwort in ${current.answerSuffix}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
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
                    onPressed:
                        locked ? null : () => _answer(choiceIndex),
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
    final modes = <String, AssessmentTask>{};
    for (final task in tasks) {
      modes.putIfAbsent(task.mode.name, () => task);
    }

    final progress = modes.values
        .map((task) => widget.controller.competencyProgress(task.mode))
        .toList();
    final secure = progress
        .where((item) => item.state == CompetencyState.secure)
        .toList();
    final focus = widget.controller.recommendedMode();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dein Lernstart'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
        children: [
          Icon(
            Icons.route_rounded,
            size: 54,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Jetzt weiß Rechenblitz schon etwas mehr.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Der Lerncheck ist nur ein Startpunkt. Die Lernlandkarte wird mit jeder echten Runde genauer.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          _ResultCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Das wirkt schon sicher',
            text: secure.isEmpty
                ? 'Noch kein Bereich wird vorschnell als sicher markiert. Das ist beim ersten Check völlig normal.'
                : secure.map((item) => item.mode.title).join(' · '),
          ),
          const SizedBox(height: 12),
          _ResultCard(
            icon: Icons.track_changes_rounded,
            title: 'Damit starten wir',
            text:
                '${focus.title} ist für die erste persönliche Runde ein sinnvoller Schwerpunkt.',
          ),
          const SizedBox(height: 12),
          ...progress.map(
            (item) => Card(
              child: ListTile(
                leading: Icon(
                  item.state == CompetencyState.secure
                      ? Icons.check_circle_outline_rounded
                      : Icons.timelapse_rounded,
                ),
                title: Text(item.mode.title),
                subtitle: Text(
                  '${(item.accuracy * 100).round()} % im Lerncheck',
                ),
                trailing: Chip(label: Text(item.state.label)),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
            label: const Text('Meine erste Runde starten'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zur Startseite'),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(text),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
