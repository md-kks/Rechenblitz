import 'package:flutter/material.dart';

import '../models/error_diagnosis.dart';
import '../models/learning_path.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import 'curriculum_training_screen.dart';
import 'remediation_screen.dart';
import 'structured_training_screen.dart';
import 'training_screen.dart';

class MyRoundScreen extends StatefulWidget {
  const MyRoundScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<MyRoundScreen> createState() => _MyRoundScreenState();
}

class _MyRoundScreenState extends State<MyRoundScreen> {
  late List<GuidedRoundSegment> plan;
  final Set<int> completed = {};

  @override
  void initState() {
    super.initState();
    plan = widget.controller.buildMyRound();
  }

  Future<void> _start(int index) async {
    final segment = plan[index];
    final before = widget.controller.history.length;

    if (segment.mode.isUpperPrimary) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CurriculumTrainingScreen(
            controller: widget.controller,
            mode: segment.mode,
            targetTasks: segment.tasks,
          ),
        ),
      );
    } else if (segment.mode.isStructured) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StructuredTrainingScreen(
            controller: widget.controller,
            mode: segment.mode,
            targetTasks: segment.tasks,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrainingScreen(
            controller: widget.controller,
            mode: segment.mode,
            targetTasks: segment.tasks,
          ),
        ),
      );
    }

    if (!mounted) return;
    if (widget.controller.history.length > before) {
      setState(() => completed.add(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final remediation = widget.controller.remediationCandidate();
    final reviewOnly = remediation == null
        ? false
        : widget.controller.remediationReviewOnly(remediation.pattern);
    final doneTasks = [
      for (var i = 0; i < plan.length; i++)
        if (completed.contains(i)) plan[i].tasks,
    ].fold<int>(0, (a, b) => a + b);
    final totalTasks =
        plan.fold<int>(0, (sum, segment) => sum + segment.tasks);
    final allDone = completed.length == plan.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Runde')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone ? 'Für heute geschafft.' : 'Etwa 5 Minuten Mathe.',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    allDone
                        ? 'Grundlage, Lernziel und Transfer sind erledigt. Mehr ist heute nicht nötig.'
                        : 'Rechenblitz stellt die Runde aus Grundlagen, dem wichtigsten aktuellen Lernziel und einer Transferaufgabe zusammen.',
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: totalTasks == 0 ? 0 : doneTasks / totalTasks,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 6),
                  Text('$doneTasks von $totalTasks Aufgaben'),
                ],
              ),
            ),
          ),
          if (remediation != null && remediation.modes.isNotEmpty) ...[
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.healing_rounded),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reviewOnly
                                ? 'Kurze Kontrolle fällig'
                                : 'Knacknuss zuerst',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reviewOnly
                          ? '„${remediation.pattern.label}“ wurde bereits besser. Zwei Kontrollaufgaben prüfen jetzt, ob der Rechenweg stabil geblieben ist.'
                          : '„${remediation.pattern.label}“ ist wiederholt aufgefallen. Ein kurzer Förderpfad führt von Hilfe über selbstständiges Anwenden bis zur Kontrolle.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('remediation-button'),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RemediationScreen(
                              controller: widget.controller,
                              pattern: remediation.pattern,
                              preferredMode: remediation.modes.first,
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            plan = widget.controller.buildMyRound();
                          });
                        }
                      },
                      icon: Icon(
                        reviewOnly
                            ? Icons.fact_check_outlined
                            : Icons.route_rounded,
                      ),
                      label: Text(
                        reviewOnly
                            ? 'Kontrollrunde starten'
                            : 'Förderpfad starten',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ...List.generate(plan.length, (index) {
            final segment = plan[index];
            final isDone = completed.contains(index);
            final isNext = index == 0 || completed.contains(index - 1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        child: isDone
                            ? const Icon(Icons.check_rounded)
                            : Text('${index + 1}'),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              segment.mode.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${segment.tasks} Aufgaben · ${segment.reason}',
                            ),
                            if (!isDone && isNext) ...[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _start(index),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(
                                  index == 0 ? 'Runde starten' : 'Weiter',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
