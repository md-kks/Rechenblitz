import 'dart:async';

import 'package:flutter/material.dart';

import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import 'learning_visual_aid.dart';

class GuidedMethodPanel extends StatefulWidget {
  const GuidedMethodPanel({
    super.key,
    required this.guide,
    required this.pattern,
    required this.taskKey,
    required this.expected,
    required this.onHelpLevelChanged,
    this.initialLevel = HelpLevel.nudge,
    this.onStepAttempt,
    this.onSpeak,
  });

  final GuidedMethodGuide guide;
  final ErrorPattern pattern;
  final String taskKey;
  final int expected;
  final ValueChanged<HelpLevel> onHelpLevelChanged;
  final HelpLevel initialLevel;
  final Future<void> Function(GuidedMethodStep step, bool correct)?
      onStepAttempt;
  final Future<void> Function(String text)? onSpeak;

  @override
  State<GuidedMethodPanel> createState() => _GuidedMethodPanelState();
}

class _GuidedMethodPanelState extends State<GuidedMethodPanel> {
  late HelpLevel level;
  int stepIndex = 0;
  final Set<int> solvedSteps = <int>{};
  final Set<int> attemptedSteps = <int>{};
  String feedback = '';

  @override
  void initState() {
    super.initState();
    level = widget.initialLevel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHelpLevelChanged(level);
    });
  }

  void _setLevel(HelpLevel value) {
    if (value.index < level.index) return;
    setState(() {
      level = value;
      feedback = '';
    });
    widget.onHelpLevelChanged(value);
  }

  void _choose(GuidedMethodStep step, int choice) {
    final correct = choice == step.correctChoice;
    final firstAttempt = attemptedSteps.add(stepIndex);

    if (correct) {
      setState(() {
        solvedSteps.add(stepIndex);
        feedback = 'Genau. Dieser Schritt stimmt.';
      });
    } else {
      setState(() {
        feedback = 'Noch nicht. Schau auf den Schritt und probiere noch einmal.';
      });
    }

    if (firstAttempt &&
        step.recordsIntermediateEvidence &&
        widget.onStepAttempt != null) {
      unawaited(widget.onStepAttempt!(step, correct));
    }
  }

  void _nextStep() {
    if (stepIndex + 1 >= widget.guide.steps.length) return;
    setState(() {
      stepIndex += 1;
      feedback = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;
    final step = guide.steps.isEmpty ? null : guide.steps[stepIndex];
    final stepSolved =
        step == null || !step.isInteractive || solvedSteps.contains(stepIndex);

    return Semantics(
      container: true,
      label: 'Rechenhilfe ${guide.methodLabel}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.route_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rechenweg: ${guide.methodLabel}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (widget.onSpeak != null)
                    IconButton(
                      tooltip: 'Hilfe vorlesen',
                      onPressed: () => widget.onSpeak!(
                        level == HelpLevel.nudge
                            ? guide.nudge
                            : step?.instruction ?? guide.nudge,
                      ),
                      icon: const Icon(Icons.volume_up_outlined),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _LevelChip(
                    label: '1 Denkhinweis',
                    selected: level.index >= HelpLevel.nudge.index,
                    onTap: () => _setLevel(HelpLevel.nudge),
                  ),
                  _LevelChip(
                    label: '2 Darstellung',
                    selected: level.index >= HelpLevel.visual.index,
                    onTap: () => _setLevel(HelpLevel.visual),
                  ),
                  _LevelChip(
                    label: '3 Gemeinsam lösen',
                    selected: level.index >= HelpLevel.guided.index,
                    onTap: () => _setLevel(HelpLevel.guided),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                guide.nudge,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (level.index >= HelpLevel.visual.index) ...[
                const SizedBox(height: 12),
                LearningVisualAid(
                  pattern: widget.pattern,
                  taskKey: widget.taskKey,
                  expected: widget.expected,
                ),
              ],
              if (level == HelpLevel.guided && step != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                Text(
                  'Schritt ${stepIndex + 1} von ${guide.steps.length}: ${step.title}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(step.instruction),
                if (step.question != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    step.question!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
                if (step.isInteractive) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      step.choices.length,
                      (index) => ChoiceChip(
                        label: Text(step.choices[index]),
                        selected: solvedSteps.contains(stepIndex) &&
                            index == step.correctChoice,
                        onSelected: (_) => _choose(step, index),
                      ),
                    ),
                  ),
                ],
                if (feedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    feedback,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 10),
                if (stepIndex + 1 < guide.steps.length)
                  OutlinedButton.icon(
                    onPressed: stepSolved ? _nextStep : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Nächster Schritt'),
                  )
                else if (stepSolved)
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Der Rechenweg ist vollständig. Jetzt probiere die Aufgabe selbst.',
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: selected
            ? const Icon(Icons.check_rounded, size: 18)
            : null,
        label: Text(label),
        onPressed: onTap,
      );
}
