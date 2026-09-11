import 'package:flutter/material.dart';

import '../models/error_diagnosis.dart';
import '../models/learning_path.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import 'curriculum_training_screen.dart';
import 'remediation_screen.dart';
import 'structured_training_screen.dart';
import 'step_recovery_screen.dart';
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
  late final bool hadStepRecoveryAtStart;
  bool stepRecoveryAttempted = false;
  bool stepRecoveryCompleted = false;

  @override
  void initState() {
    super.initState();
    hadStepRecoveryAtStart =
        widget.controller.independentStepRecoveryFocus() != null;
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
            targetCompetency: segment.targetCompetency,
            reviewEmphasis: segment.reviewEmphasis,
            transferEmphasis: segment.transferEmphasis,
            scaffoldFading: segment.scaffoldFading,
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
            targetCompetency: segment.targetCompetency,
            reviewEmphasis: segment.reviewEmphasis,
            transferEmphasis: segment.transferEmphasis,
            scaffoldFading: segment.scaffoldFading,
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
            targetCompetency: segment.targetCompetency,
            reviewEmphasis: segment.reviewEmphasis,
            transferEmphasis: segment.transferEmphasis,
            scaffoldFading: segment.scaffoldFading,
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
    final unresolvedStepRecovery = widget.controller
        .independentStepRecoveryFocus();
    final stepRecovery = stepRecoveryAttempted ? null : unresolvedStepRecovery;
    final remediation = unresolvedStepRecovery == null
        ? widget.controller.remediationCandidate()
        : null;
    final reviewOnly = remediation == null
        ? false
        : widget.controller.remediationReviewOnly(remediation.pattern);
    final regularDoneTasks = [
      for (var i = 0; i < plan.length; i++)
        if (completed.contains(i)) plan[i].tasks,
    ].fold<int>(0, (a, b) => a + b);
    final doneTasks = regularDoneTasks + (stepRecoveryCompleted ? 3 : 0);
    final regularTotalTasks = plan.fold<int>(
      0,
      (sum, segment) => sum + segment.tasks,
    );
    final totalTasks = regularTotalTasks + (hadStepRecoveryAtStart ? 3 : 0);
    final allDone =
        completed.length == plan.length &&
        (!hadStepRecoveryAtStart || stepRecoveryCompleted);

    int? nextIndex;
    for (var i = 0; i < plan.length; i++) {
      if (!completed.contains(i)) {
        nextIndex = i;
        break;
      }
    }
    final nextSegment = nextIndex == null ? null : plan[nextIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Runde')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone
                        ? 'Für heute geschafft.'
                        : 'Etwa 5–8 Minuten Mathe.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    allDone
                        ? 'Mehr ist heute nicht nötig.'
                        : '$doneTasks von $totalTasks Aufgaben',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: totalTasks == 0 ? 0 : doneTasks / totalTasks,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ],
              ),
            ),
          ),
          if (stepRecovery != null) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Kurz üben',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Wir schauen uns „${stepRecovery.label}“ in drei kurzen Aufgaben an.',
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const ValueKey('step-recovery-button'),
                      onPressed: () async {
                        final recoveryFinished = await Navigator.of(context)
                            .push<bool>(
                              MaterialPageRoute(
                                builder: (_) => StepRecoveryScreen(
                                  controller: widget.controller,
                                  focus: stepRecovery,
                                ),
                              ),
                            );
                        if (mounted && recoveryFinished == true) {
                          setState(() {
                            stepRecoveryAttempted = true;
                            stepRecoveryCompleted = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Los geht’s'),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (remediation != null && remediation.modes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      reviewOnly ? 'Kurz nochmal' : 'Knacknuss',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reviewOnly
                          ? 'Zwei Aufgaben zeigen, ob „${remediation.pattern.label}“ schon sicher klappt.'
                          : 'Wir üben „${remediation.pattern.label}“ zuerst mit Hilfe.',
                    ),
                    const SizedBox(height: 14),
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
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        reviewOnly ? '2 Aufgaben starten' : 'Knacknuss üben',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (!allDone && nextSegment != null && nextIndex != null) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Als Nächstes',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextSegment.mode.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text('${nextSegment.tasks} Aufgaben'),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const ValueKey('round-next-button'),
                      onPressed: () => _start(nextIndex!),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(nextIndex == 0 ? 'Starten' : 'Weiter'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (plan.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: ExpansionTile(
                key: const ValueKey('round-plan-expansion'),
                leading: const Icon(Icons.format_list_numbered_rounded),
                title: const Text('Rundenplan'),
                subtitle: const Text('Alle Teile deiner Runde'),
                children: [
                  for (var index = 0; index < plan.length; index++)
                    ListTile(
                      leading: CircleAvatar(
                        child: completed.contains(index)
                            ? const Icon(Icons.check_rounded)
                            : Text('${index + 1}'),
                      ),
                      title: Text(plan[index].mode.title),
                      subtitle: Text('${plan[index].tasks} Aufgaben'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
