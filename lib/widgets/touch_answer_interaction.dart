import 'dart:math' as math;

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
  int placeTens = 0;
  int placeOnes = 0;
  final List<int> moneyPieces = <int>[];
  int selectedHour = 12;
  int selectedMinute = 0;

  @override
  void initState() {
    super.initState();
    _resetInteractiveState();
  }

  @override
  void didUpdateWidget(covariant TouchAnswerInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan.taskKey != widget.plan.taskKey) {
      _resetInteractiveState();
    }
  }

  void _resetInteractiveState() {
    selectedValue = widget.plan.startValue;
    placeTens = 0;
    placeOnes = 0;
    moneyPieces.clear();
    selectedHour = widget.plan.clockHour == 12 ? 1 : 12;
    selectedMinute = 0;
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
            TouchInteractionKind.placeValueBuilder => _buildPlaceValue(context),
            TouchInteractionKind.moneyComposer => _buildMoneyComposer(context),
            TouchInteractionKind.clockSetter => _buildClockSetter(context),
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

  Widget _buildPlaceValue(BuildContext context) {
    final value = placeTens * 10 + placeOnes;
    final maxValue = widget.plan.maxValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _PlaceCounter(
              label: 'Zehner',
              value: placeTens,
              addKey: const ValueKey('touch-place-tens-add'),
              removeKey: const ValueKey('touch-place-tens-remove'),
              onAdd: widget.locked || value + 10 > maxValue
                  ? null
                  : () => setState(() => placeTens += 1),
              onRemove: widget.locked || placeTens == 0
                  ? null
                  : () => setState(() => placeTens -= 1),
            ),
            _PlaceCounter(
              label: 'Einer',
              value: placeOnes,
              addKey: const ValueKey('touch-place-ones-add'),
              removeKey: const ValueKey('touch-place-ones-remove'),
              onAdd: widget.locked || placeOnes >= 9 || value + 1 > maxValue
                  ? null
                  : () => setState(() => placeOnes += 1),
              onRemove: widget.locked || placeOnes == 0
                  ? null
                  : () => setState(() => placeOnes -= 1),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '$placeTens Zehner + $placeOnes Einer = $value',
          key: const ValueKey('touch-place-value'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-place-submit'),
          onPressed: widget.locked ? null : () => widget.onAnswer(value),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Zahl einsetzen'),
        ),
      ],
    );
  }

  Widget _buildMoneyComposer(BuildContext context) {
    final total = moneyPieces.fold<int>(0, (sum, value) => sum + value);
    final unit = widget.plan.unitLabel ?? '€';
    String label(int value) => '$value $unit';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label(total),
          key: const ValueKey('touch-money-total'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final denomination in widget.plan.denominations)
              FilledButton.tonal(
                key: ValueKey('touch-money-add-$denomination'),
                onPressed:
                    widget.locked || total + denomination > widget.plan.maxValue
                    ? null
                    : () => setState(() => moneyPieces.add(denomination)),
                child: Text('+ ${label(denomination)}'),
              ),
          ],
        ),
        if (moneyPieces.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var index = 0; index < moneyPieces.length; index++)
                InputChip(
                  key: ValueKey('touch-money-piece-$index'),
                  label: Text(label(moneyPieces[index])),
                  onDeleted: widget.locked
                      ? null
                      : () => setState(() => moneyPieces.removeAt(index)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                key: const ValueKey('touch-money-reset'),
                onPressed: widget.locked || moneyPieces.isEmpty
                    ? null
                    : () => setState(moneyPieces.clear),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Leeren'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey('touch-money-submit'),
                onPressed: widget.locked ? null : () => widget.onAnswer(total),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Betrag prüfen'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClockSetter(BuildContext context) {
    final targetMinute = widget.plan.clockMinute ?? 0;
    final minuteValues = targetMinute == 0 || targetMinute == 30
        ? const <int>[0, 30]
        : const <int>[0, 15, 30, 45];
    if (!minuteValues.contains(selectedMinute)) selectedMinute = 0;
    final minuteIndex = minuteValues
        .indexOf(selectedMinute)
        .clamp(0, minuteValues.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 170,
            height: 170,
            child: CustomPaint(
              key: const ValueKey('touch-clock-preview'),
              painter: _TouchClockPainter(
                hour: selectedHour,
                minute: selectedMinute,
                color: Theme.of(context).colorScheme.onSurface,
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$selectedHour:${selectedMinute.toString().padLeft(2, '0')} Uhr',
          key: const ValueKey('touch-clock-value'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Stunde: $selectedHour',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Slider(
          key: const ValueKey('touch-clock-hour-slider'),
          value: selectedHour.toDouble(),
          min: 1,
          max: 12,
          divisions: 11,
          label: '$selectedHour',
          onChanged: widget.locked
              ? null
              : (value) => setState(() => selectedHour = value.round()),
        ),
        Text(
          'Minuten: $selectedMinute',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Slider(
          key: const ValueKey('touch-clock-minute-slider'),
          value: minuteIndex.toDouble(),
          min: 0,
          max: (minuteValues.length - 1).toDouble(),
          divisions: math.max(1, minuteValues.length - 1),
          label: '$selectedMinute',
          onChanged: widget.locked
              ? null
              : (value) => setState(
                  () => selectedMinute = minuteValues[value.round()],
                ),
        ),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-clock-submit'),
          onPressed: widget.locked ? null : _submitClock,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Uhrzeit prüfen'),
        ),
      ],
    );
  }

  void _submitClock() {
    final label =
        '$selectedHour:${selectedMinute.toString().padLeft(2, '0')} Uhr';
    final exact = widget.plan.answerChoices.indexOf(label);
    if (exact >= 0) {
      widget.onAnswer(exact);
      return;
    }
    widget.onAnswer(-1);
  }
}

class _PlaceCounter extends StatelessWidget {
  const _PlaceCounter({
    required this.label,
    required this.value,
    required this.addKey,
    required this.removeKey,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final int value;
  final Key addKey;
  final Key removeKey;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    child: Container(
      width: 132,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('$value', style: Theme.of(context).textTheme.headlineMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: removeKey,
                tooltip: '$label wegnehmen',
                onPressed: onRemove,
                icon: const Icon(Icons.remove_rounded),
              ),
              IconButton(
                key: addKey,
                tooltip: '$label hinzufügen',
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TouchClockPainter extends CustomPainter {
  const _TouchClockPainter({
    required this.hour,
    required this.minute,
    required this.color,
    required this.accent,
  });

  final int hour;
  final int minute;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, outline);
    for (var tick = 0; tick < 12; tick++) {
      final angle = tick * math.pi / 6 - math.pi / 2;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 5),
        center.dy + math.sin(angle) * (radius - 5),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 13),
        center.dy + math.sin(angle) * (radius - 13),
      );
      canvas.drawLine(inner, outer, outline);
    }
    final minuteAngle = minute / 60 * 2 * math.pi - math.pi / 2;
    final hourAngle =
        ((hour % 12) + minute / 60) / 12 * 2 * math.pi - math.pi / 2;
    final minutePaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final hourPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(hourAngle) * radius * 0.52,
        center.dy + math.sin(hourAngle) * radius * 0.52,
      ),
      hourPaint,
    );
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(minuteAngle) * radius * 0.76,
        center.dy + math.sin(minuteAngle) * radius * 0.76,
      ),
      minutePaint,
    );
    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TouchClockPainter oldDelegate) =>
      hour != oldDelegate.hour ||
      minute != oldDelegate.minute ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
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
