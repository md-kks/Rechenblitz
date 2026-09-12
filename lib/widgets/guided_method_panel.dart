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
    this.maxLevel = HelpLevel.guided,
    this.onStepAttempt,
    this.onSpeak,
    this.alternativeGuides = const <GuidedMethodGuide>[],
    this.onGuideChanged,
  });

  final GuidedMethodGuide guide;
  final ErrorPattern pattern;
  final String taskKey;
  final int expected;
  final ValueChanged<HelpLevel> onHelpLevelChanged;
  final HelpLevel initialLevel;
  final HelpLevel maxLevel;
  final Future<void> Function(GuidedMethodStep step, bool correct)?
      onStepAttempt;
  final Future<void> Function(String text)? onSpeak;
  final List<GuidedMethodGuide> alternativeGuides;
  final ValueChanged<GuidedMethodGuide>? onGuideChanged;

  @override
  State<GuidedMethodPanel> createState() => _GuidedMethodPanelState();
}

class _GuidedMethodPanelState extends State<GuidedMethodPanel> {
  late HelpLevel level;
  late GuidedMethodGuide activeGuide;
  int stepIndex = 0;
  final Set<int> solvedSteps = <int>{};
  final Set<int> attemptedSteps = <int>{};
  String feedback = '';
  bool methodChoiceVisible = false;

  @override
  void initState() {
    super.initState();
    level = widget.initialLevel.index <= widget.maxLevel.index
        ? widget.initialLevel
        : widget.maxLevel;
    activeGuide = widget.guide;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHelpLevelChanged(level);
    });
  }


  @override
  void didUpdateWidget(covariant GuidedMethodPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskKey != widget.taskKey ||
        oldWidget.guide.methodKey != widget.guide.methodKey) {
      activeGuide = widget.guide;
      stepIndex = 0;
      solvedSteps.clear();
      attemptedSteps.clear();
      feedback = '';
      methodChoiceVisible = false;
    }
  }

  List<GuidedMethodGuide> get _availableGuides {
    final guides = <GuidedMethodGuide>[activeGuide];
    for (final guide in [widget.guide, ...widget.alternativeGuides]) {
      if (!guides.any((entry) => entry.methodKey == guide.methodKey)) {
        guides.add(guide);
      }
    }
    return guides;
  }

  void _chooseGuide(String methodKey) {
    final guide = _availableGuides.firstWhere(
      (entry) => entry.methodKey == methodKey,
      orElse: () => activeGuide,
    );
    if (guide.methodKey == activeGuide.methodKey) return;
    setState(() {
      activeGuide = guide;
      stepIndex = 0;
      solvedSteps.clear();
      attemptedSteps.clear();
      feedback = '';
      methodChoiceVisible = false;
    });
    widget.onGuideChanged?.call(guide);
  }

  void _setLevel(HelpLevel value) {
    if (value.index < level.index || value.index > widget.maxLevel.index) return;
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
    if (stepIndex + 1 >= activeGuide.steps.length) return;
    setState(() {
      stepIndex += 1;
      feedback = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final guide = activeGuide;
    final step = guide.steps.isEmpty ? null : guide.steps[stepIndex];
    final stepSolved =
        step == null || !step.isInteractive || solvedSteps.contains(stepIndex);
    final hasVisual = LearningVisualAid.canRender(
      pattern: widget.pattern,
      taskKey: widget.taskKey,
      methodKey: guide.methodKey,
    );

    return Semantics(
      container: true,
      label: 'Rechenhilfe ${guide.methodLabel}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hilfe · ${guide.methodLabel}',
                      style: Theme.of(context).textTheme.titleMedium,
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
              Text(
                guide.nudge,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (_availableGuides.length > 1) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('help-toggle-methods'),
                    onPressed: () => setState(
                      () => methodChoiceVisible = !methodChoiceVisible,
                    ),
                    icon: Icon(
                      methodChoiceVisible
                          ? Icons.expand_less_rounded
                          : Icons.swap_horiz_rounded,
                    ),
                    label: const Text('Anderen Rechenweg probieren'),
                  ),
                ),
                if (methodChoiceVisible) ...[
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('guided-method-choice:${guide.methodKey}'),
                    initialValue: guide.methodKey,
                    decoration: const InputDecoration(
                      labelText: 'Rechenweg',
                    ),
                    items: _availableGuides
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.methodKey,
                            child: Text(entry.methodLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) _chooseGuide(value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gilt nur für diese Hilfe. Deine Einstellung bleibt gleich.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
              if (hasVisual && level.index >= HelpLevel.visual.index) ...[
                const SizedBox(height: 14),
                LearningVisualAid(
                  pattern: widget.pattern,
                  taskKey: widget.taskKey,
                  expected: widget.expected,
                  methodKey: guide.methodKey,
                ),
              ],
              if (level == HelpLevel.guided && step != null) ...[
                const SizedBox(height: 14),
                const Divider(),
                Text(
                  'Schritt ${stepIndex + 1} von ${guide.steps.length}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleMedium,
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
                        child: Text('Jetzt probiere die Aufgabe selbst.'),
                      ),
                    ],
                  ),
              ] else ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hasVisual &&
                        level == HelpLevel.nudge &&
                        widget.maxLevel.index >= HelpLevel.visual.index)
                      OutlinedButton.icon(
                        key: const ValueKey('help-show-visual'),
                        onPressed: () => _setLevel(HelpLevel.visual),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Bild zeigen'),
                      ),
                    if (guide.steps.isNotEmpty &&
                        widget.maxLevel.index >= HelpLevel.guided.index)
                      OutlinedButton.icon(
                        key: const ValueKey('help-show-guided'),
                        onPressed: () => _setLevel(HelpLevel.guided),
                        icon: const Icon(Icons.format_list_numbered_rounded),
                        label: const Text('Schritt für Schritt'),
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
