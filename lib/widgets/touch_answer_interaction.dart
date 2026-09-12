import 'package:flutter/material.dart';

import '../models/touch_interaction.dart';

class TouchAnswerInteraction extends StatefulWidget {
  const TouchAnswerInteraction({
    super.key,
    required this.plan,
    required this.onAnswer,
    this.locked = false,
  });

  final TouchInteractionPlan plan;
  final ValueChanged<int> onAnswer;
  final bool locked;

  @override
  State<TouchAnswerInteraction> createState() => _TouchAnswerInteractionState();
}

class _TouchAnswerInteractionState extends State<TouchAnswerInteraction> {
  late int selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.plan.startValue;
  }

  @override
  void didUpdateWidget(covariant TouchAnswerInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan.taskKey != widget.plan.taskKey) {
      selectedValue = widget.plan.startValue;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('touch-answer-interaction'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.plan.instruction,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          switch (widget.plan.kind) {
            TouchInteractionKind.numberLine => _buildNumberLine(context),
            TouchInteractionKind.dragNumberToTarget => _buildDragNumberToTarget(
              context,
            ),
          },
        ],
      ),
    ),
  );

  Widget _buildNumberLine(BuildContext context) {
    final plan = widget.plan;
    final span = plan.maxValue - plan.minValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          label: 'Ausgewählte Zahl',
          value: '$selectedValue',
          child: Text(
            '$selectedValue',
            key: const ValueKey('touch-number-line-value'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        const SizedBox(height: 4),
        Slider(
          key: const ValueKey('touch-number-line-slider'),
          value: selectedValue.toDouble(),
          min: plan.minValue.toDouble(),
          max: plan.maxValue.toDouble(),
          divisions: span > 0 ? span : null,
          label: '$selectedValue',
          onChanged: widget.locked
              ? null
              : (value) => setState(() => selectedValue = value.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('${plan.minValue}'), Text('${plan.maxValue}')],
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-number-line-submit'),
          onPressed: widget.locked
              ? null
              : () => widget.onAnswer(selectedValue),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Zahl einsetzen'),
        ),
      ],
    );
  }

  Widget _buildDragNumberToTarget(BuildContext context) {
    final plan = widget.plan;
    final span = plan.maxValue - plan.minValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plan.hasInteractiveWall)
          _InteractiveNumberWall(
            values: plan.wallValues!,
            hiddenIndex: plan.hiddenWallIndex!,
            targetLabel: plan.targetLabel,
            locked: widget.locked,
            onAccept: widget.onAnswer,
          )
        else
          _NumberDropTarget(
            label: plan.targetLabel,
            locked: widget.locked,
            onAccept: widget.onAnswer,
          ),
        const SizedBox(height: 14),
        Text(
          'Gewählte Zahl: $selectedValue',
          key: const ValueKey('touch-drag-selected-value'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          key: const ValueKey('touch-drag-number-slider'),
          value: selectedValue.toDouble(),
          min: plan.minValue.toDouble(),
          max: plan.maxValue.toDouble(),
          divisions: span > 0 ? span : null,
          label: '$selectedValue',
          onChanged: widget.locked
              ? null
              : (value) => setState(() => selectedValue = value.round()),
        ),
        Center(
          child: _DraggableNumberCard(
            value: selectedValue,
            locked: widget.locked,
            onTap: () => widget.onAnswer(selectedValue),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Zieh die gewählte Zahl in das freie Feld. Antippen geht ebenfalls.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DraggableNumberCard extends StatelessWidget {
  const _DraggableNumberCard({
    required this.value,
    required this.locked,
    required this.onTap,
  });

  final int value;
  final bool locked;
  final VoidCallback onTap;

  Widget _card(BuildContext context) => Container(
    width: 68,
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: Text(
      '$value',
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: !locked,
    label: 'Zahl $value. Antippen oder in das freie Feld ziehen.',
    onTap: locked ? null : onTap,
    child: GestureDetector(
      key: ValueKey('touch-number-card-$value'),
      onTap: locked ? null : onTap,
      child: Draggable<int>(
        data: value,
        maxSimultaneousDrags: locked ? 0 : 1,
        feedback: Material(color: Colors.transparent, child: _card(context)),
        childWhenDragging: Opacity(opacity: 0.35, child: _card(context)),
        child: _card(context),
      ),
    ),
  );
}

class _NumberDropTarget extends StatelessWidget {
  const _NumberDropTarget({
    required this.label,
    required this.locked,
    required this.onAccept,
  });

  final String label;
  final bool locked;
  final ValueChanged<int> onAccept;

  @override
  Widget build(BuildContext context) => DragTarget<int>(
    key: const ValueKey('touch-drop-target'),
    onWillAcceptWithDetails: (_) => !locked,
    onAcceptWithDetails: (details) => onAccept(details.data),
    builder: (context, candidates, rejected) => AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: candidates.isNotEmpty
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: candidates.isNotEmpty
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: candidates.isNotEmpty ? 2 : 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _InteractiveNumberWall extends StatelessWidget {
  const _InteractiveNumberWall({
    required this.values,
    required this.hiddenIndex,
    required this.targetLabel,
    required this.locked,
    required this.onAccept,
  });

  final List<int> values;
  final int hiddenIndex;
  final String targetLabel;
  final bool locked;
  final ValueChanged<int> onAccept;

  Widget _brick(BuildContext context, int index) {
    if (index == hiddenIndex) {
      return SizedBox(
        width: 82,
        child: _NumberDropTarget(
          label: '?',
          locked: locked,
          onAccept: onAccept,
        ),
      );
    }
    return Container(
      width: 82,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        '${values[index]}',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Interaktive Zahlenmauer. $targetLabel.',
    child: Column(
      children: [
        _brick(context, 5),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _brick(context, 3),
            const SizedBox(width: 8),
            _brick(context, 4),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _brick(context, 0),
            const SizedBox(width: 8),
            _brick(context, 1),
            const SizedBox(width: 8),
            _brick(context, 2),
          ],
        ),
      ],
    ),
  );
}
