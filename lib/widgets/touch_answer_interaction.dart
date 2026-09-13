import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../models/touch_interaction.dart';
import 'number_answer_pad.dart';

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
  bool clockMinuteHandActive = false;
  int fractionPartSize = 0;
  final Set<int> selectedFractionParts = <int>{};
  final Set<int> selectedMeasureParts = <int>{};
  int? selectedMeasureChoice;
  int proportionalUnitValue = 0;
  int? selectedConversionChoice;
  int durationCurrent = 0;
  int durationElapsed = 0;
  int calendarDay = 1;
  int calendarSteps = 0;
  int pathX = 0;
  int pathY = 0;
  final Set<int> selectedAxes = <int>{};
  final Set<int> selectedShapePoints = <int>{};
  final Set<int> selectedShapeSides = <int>{};
  final Set<int> selectedPerimeterEdges = <int>{};
  int areaColumns = 1;
  int areaRows = 1;
  final List<int> groupCounters = <int>[];
  int builtDivisionGroups = 0;
  final Set<int> selectedProbabilityOutcomes = <int>{};
  final Set<int> selectedCombinations = <int>{};
  bool probabilityNoOutcome = false;
  final Set<int> selectedDataBars = <int>{};
  final Set<int> selectedTallyUnits = <int>{};
  int? selectedEstimateA;
  int? selectedEstimateB;
  int volumeLayers = 1;
  int selectedRelativePercent = 0;

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
    clockMinuteHandActive = false;
    fractionPartSize = 0;
    selectedFractionParts.clear();
    selectedMeasureParts.clear();
    selectedMeasureChoice = null;
    proportionalUnitValue = 0;
    selectedConversionChoice = null;
    durationCurrent = widget.plan.kind == TouchInteractionKind.durationTimeline && widget.plan.dataValues.isNotEmpty
        ? widget.plan.dataValues.first
        : 0;
    durationElapsed = 0;
    calendarDay = widget.plan.kind == TouchInteractionKind.calendarStepper && widget.plan.dataValues.isNotEmpty
        ? widget.plan.dataValues.first
        : 1;
    calendarSteps = 0;
    pathX = 0;
    pathY = 0;
    selectedAxes.clear();
    selectedShapePoints.clear();
    selectedShapeSides.clear();
    selectedPerimeterEdges.clear();
    areaColumns = 1;
    areaRows = 1;
    groupCounters
      ..clear()
      ..addAll(List<int>.filled(widget.plan.groupCount ?? 0, 0));
    builtDivisionGroups = 0;
    selectedProbabilityOutcomes.clear();
    selectedCombinations.clear();
    probabilityNoOutcome = false;
    selectedDataBars.clear();
    selectedTallyUnits.clear();
    selectedEstimateA = null;
    selectedEstimateB = null;
    volumeLayers = 1;
    selectedRelativePercent = 0;
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
            TouchInteractionKind.fractionBuilder => _buildFractionBuilder(
              context,
            ),
            TouchInteractionKind.fractionMeasure => _buildFractionMeasure(context),
            TouchInteractionKind.proportionalUnitBuilder =>
              _buildProportionalUnitBuilder(context),
            TouchInteractionKind.unitConversionMachine =>
              _buildUnitConversionMachine(context),
            TouchInteractionKind.durationTimeline =>
              _buildDurationTimeline(context),
            TouchInteractionKind.calendarStepper =>
              _buildCalendarStepper(context),
            TouchInteractionKind.pathWalker => _buildPathWalker(context),
            TouchInteractionKind.symmetryAxes => _buildSymmetryAxes(context),
            TouchInteractionKind.shapeCorners => _buildShapeCorners(context),
            TouchInteractionKind.shapeSides => _buildShapeSides(context),
            TouchInteractionKind.rectanglePerimeterEdges =>
              _buildRectanglePerimeter(context),
            TouchInteractionKind.rectangleAreaBuilder =>
              _buildRectangleArea(context),
            TouchInteractionKind.equalGroupsBuilder => _buildEqualGroups(
              context,
            ),
            TouchInteractionKind.divisionGroupsBuilder => _buildDivisionGroups(
              context,
            ),
            TouchInteractionKind.dataChartSelection => _buildDataChart(context),
            TouchInteractionKind.tallySelection => _buildTallySelection(context),
            TouchInteractionKind.representationSorter =>
              _buildRepresentationSorter(context),
            TouchInteractionKind.probabilityOutcomes =>
              _buildProbabilityOutcomes(context),
            TouchInteractionKind.probabilityBagComparison =>
              _buildProbabilityBagComparison(context),
            TouchInteractionKind.probabilityExperimentComparison =>
              _buildProbabilityExperimentComparison(context),
            TouchInteractionKind.probabilityRelativeHundredGrid =>
              _buildProbabilityRelativeHundredGrid(context),
            TouchInteractionKind.combinatoricsGrid =>
              _buildCombinatoricsGrid(context),
            TouchInteractionKind.roundingNumberLine =>
              _buildRoundingNumberLine(context),
            TouchInteractionKind.estimationRounding =>
              _buildEstimationRounding(context),
            TouchInteractionKind.volumeLayerBuilder =>
              _buildVolumeLayerBuilder(context),
          },
        ],
      ),
    ),
  );

  Widget _buildUnitConversionMachine(BuildContext context) {
    final values = widget.plan.dataValues;
    final source = values.isNotEmpty ? values[0] : 0;
    final labels = widget.plan.dataLabels;
    final from = labels.isNotEmpty ? labels[0] : '';
    final to = labels.length > 1 ? labels[1] : '';
    final correctChoice = widget.plan.correctSelectionIndexes.isNotEmpty
        ? widget.plan.correctSelectionIndexes.first
        : 0;
    final expected = widget.plan.expectedAnswer ?? 0;
    final relationCorrect = selectedConversionChoice == correctChoice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          key: const ValueKey('touch-conversion-relation'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '$source $from → ? $to',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < widget.plan.answerChoices.length; index++)
              ChoiceChip(
                key: ValueKey('touch-conversion-choice-$index'),
                selected: selectedConversionChoice == index,
                label: Text(widget.plan.answerChoices[index]),
                onSelected: widget.locked
                    ? null
                    : (_) => setState(() => selectedConversionChoice = index),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          selectedConversionChoice == null
              ? 'Wähle zuerst, wie sich der Zahlenwert verändert.'
              : '$source $from ${widget.plan.answerChoices[selectedConversionChoice!]} = ? $to',
          key: const ValueKey('touch-conversion-status'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        NumberAnswerPad(
          key: const ValueKey('touch-conversion-pad'),
          maxValue: math.max(1, widget.plan.maxValue),
          onAnswer: widget.locked
              ? (_) {}
              : (value) => widget.onAnswer(
                    relationCorrect ? value : _wrongAnswer(value, expected),
                  ),
        ),
      ],
    );
  }

  Widget _buildDurationTimeline(BuildContext context) {
    final start = widget.plan.dataValues.isNotEmpty ? widget.plan.dataValues[0] : 0;
    final end = widget.plan.dataValues.length > 1 ? widget.plan.dataValues[1] : start;
    final expected = widget.plan.expectedAnswer ?? math.max(0, end - start);

    String clock(int total) {
      final hour = (total ~/ 60) % 24;
      final minute = total % 60;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    void addStep(int minutes) {
      if (widget.locked) return;
      setState(() {
        durationCurrent += minutes;
        durationElapsed += minutes;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Start\n${clock(start)}', textAlign: TextAlign.center)),
            const Icon(Icons.arrow_forward_rounded),
            Expanded(
              child: Text(
                'Jetzt\n${clock(durationCurrent)}',
                key: const ValueKey('touch-duration-current'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded),
            Expanded(child: Text('Ende\n${clock(end)}', textAlign: TextAlign.center)),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: expected <= 0 ? 0 : math.min(1.0, durationElapsed / expected),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final step in const [5, 15, 30, 60])
              FilledButton.tonal(
                key: ValueKey('touch-duration-step-$step'),
                onPressed: widget.locked ? null : () => addStep(step),
                child: Text('+$step min'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Gezählte Dauer: $durationElapsed min',
          key: const ValueKey('touch-duration-elapsed'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('touch-duration-reset'),
                onPressed: widget.locked
                    ? null
                    : () => setState(() {
                          durationCurrent = start;
                          durationElapsed = 0;
                        }),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Neu starten'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('touch-duration-submit'),
                onPressed: widget.locked
                    ? null
                    : () {
                        final correct = durationCurrent == end && durationElapsed == expected;
                        widget.onAnswer(correct
                            ? expected
                            : _wrongAnswer(durationElapsed, expected));
                      },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Dauer prüfen'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarStepper(BuildContext context) {
    final values = widget.plan.dataValues;
    final start = values.isNotEmpty ? values[0] : 1;
    final addDays = values.length > 1 ? values[1] : 0;
    final monthDays = values.length > 2 ? values[2] : 31;
    final month = widget.plan.dataLabels.isNotEmpty ? widget.plan.dataLabels.first : '';
    final expected = widget.plan.expectedAnswer ?? 0;

    void addStep(int days) {
      if (widget.locked || calendarDay + days > monthDays) return;
      setState(() {
        calendarDay += days;
        calendarSteps += days;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          key: const ValueKey('touch-calendar-current'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '$calendarDay. $month',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              key: const ValueKey('touch-calendar-step-1'),
              onPressed: widget.locked ? null : () => addStep(1),
              icon: const Icon(Icons.add_rounded),
              label: const Text('1 Tag'),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('touch-calendar-step-7'),
              onPressed: widget.locked ? null : () => addStep(7),
              icon: const Icon(Icons.calendar_view_week_rounded),
              label: const Text('1 Woche'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$calendarSteps von $addDays Tagen weitergegangen',
          key: const ValueKey('touch-calendar-steps'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('touch-calendar-reset'),
                onPressed: widget.locked
                    ? null
                    : () => setState(() {
                          calendarDay = start;
                          calendarSteps = 0;
                        }),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Neu starten'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('touch-calendar-submit'),
                onPressed: widget.locked
                    ? null
                    : () {
                        final targetDay = start + addDays;
                        final structureCorrect =
                            calendarSteps == addDays && calendarDay == targetDay;
                        widget.onAnswer(structureCorrect
                            ? expected
                            : _wrongAnswer(calendarSteps, expected));
                      },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Datum prüfen'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFractionMeasure(BuildContext context) {
    final values = widget.plan.dataValues;
    final numerator = values.isNotEmpty ? values[0] : 0;
    final denominator = values.length > 1 ? values[1] : 4;
    final wholeValue = values.length > 2 ? values[2] : 0;
    final timeTask = widget.plan.dataOperation == 'time';
    final choices = widget.plan.answerChoices;
    final expected = widget.plan.expectedAnswer ?? 0;
    final wholeLabel = timeTask ? '1 Stunde = $wholeValue min' : '1 Liter = $wholeValue ml';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          wholeLabel,
          key: const ValueKey('touch-fraction-measure-whole'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < denominator; index++)
              ChoiceChip(
                key: ValueKey('touch-fraction-measure-part-$index'),
                selected: selectedMeasureParts.contains(index),
                avatar: Icon(
                  timeTask ? Icons.schedule_rounded : Icons.water_drop_outlined,
                  size: 18,
                ),
                label: Text('1/$denominator'),
                onSelected: widget.locked
                    ? null
                    : (selected) => setState(() {
                          if (selected) {
                            selectedMeasureParts.add(index);
                          } else {
                            selectedMeasureParts.remove(index);
                          }
                        }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${selectedMeasureParts.length} von $denominator Teilen markiert',
          key: const ValueKey('touch-fraction-measure-status'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          timeTask ? 'Wie viele Minuten sind diese $numerator Viertel?' : 'Wie viele Milliliter ist dieses Viertel?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < choices.length; index++)
              ChoiceChip(
                key: ValueKey('touch-fraction-measure-choice-$index'),
                selected: selectedMeasureChoice == index,
                label: Text(choices[index]),
                onSelected: widget.locked
                    ? null
                    : (_) => setState(() => selectedMeasureChoice = index),
              ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-fraction-measure-submit'),
          onPressed: widget.locked || selectedMeasureChoice == null
              ? null
              : () {
                  final structureCorrect = selectedMeasureParts.length == numerator;
                  final answerCorrect = selectedMeasureChoice == expected;
                  final candidate = selectedMeasureChoice!;
                  widget.onAnswer(
                    structureCorrect && answerCorrect
                        ? expected
                        : _wrongAnswer(candidate, expected),
                  );
                },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Bruchteil prüfen'),
        ),
      ],
    );
  }

  Widget _buildProportionalUnitBuilder(BuildContext context) {
    final values = widget.plan.dataValues;
    final unit = values.isNotEmpty ? values[0] : 1;
    final first = values.length > 1 ? values[1] : 1;
    final second = values.length > 2 ? values[2] : 1;
    final knownTotal = values.length > 3 ? values[3] : unit * first;
    final family = widget.plan.dataLabels.isNotEmpty ? widget.plan.dataLabels.first : 'unit';
    final maxUnit = math.max(12, unit + 3);
    final icon = switch (family) {
      'notebooks' => Icons.menu_book_outlined,
      'tickets' => Icons.confirmation_number_outlined,
      'packs' => Icons.inventory_2_outlined,
      'ribbon' => Icons.straighten_rounded,
      _ => Icons.circle_outlined,
    };

    Widget unitGroup(int count) => Wrap(
      alignment: WrapAlignment.center,
      spacing: 5,
      runSpacing: 5,
      children: [
        for (var index = 0; index < count; index++)
          Icon(icon, size: 24),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$first Einheiten = $knownTotal €',
          key: const ValueKey('touch-proportion-known'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        unitGroup(first),
        const SizedBox(height: 14),
        Text(
          'Wert für 1 Einheit: $proportionalUnitValue €',
          key: const ValueKey('touch-proportion-unit-value'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          key: const ValueKey('touch-proportion-unit-slider'),
          value: proportionalUnitValue.toDouble(),
          min: 0,
          max: maxUnit.toDouble(),
          divisions: maxUnit,
          label: '$proportionalUnitValue €',
          onChanged: widget.locked
              ? null
              : (value) => setState(() => proportionalUnitValue = value.round()),
        ),
        const SizedBox(height: 8),
        Text(
          'Gesucht: $second Einheiten',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        unitGroup(second),
        const SizedBox(height: 12),
        NumberAnswerPad(
          key: const ValueKey('touch-proportion-number-pad'),
          maxValue: widget.plan.maxValue,
          onAnswer: (candidate) {
            final expected = widget.plan.expectedAnswer ?? 0;
            final correct = proportionalUnitValue == unit && candidate == expected;
            widget.onAnswer(correct ? expected : _wrongAnswer(candidate, expected));
          },
        ),
      ],
    );
  }

  Widget _buildRoundingNumberLine(BuildContext context) {
    final lower = widget.plan.minValue;
    final upper = widget.plan.maxValue;
    final number = widget.plan.startValue;
    final midpoint = lower + (upper - lower) ~/ 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$number liegt zwischen $lower und $upper.',
          key: const ValueKey('touch-rounding-range'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Slider(
          key: const ValueKey('touch-rounding-position'),
          value: number.clamp(lower, upper).toDouble(),
          min: lower.toDouble(),
          max: upper.toDouble(),
          onChanged: null,
        ),
        Row(
          children: [
            Expanded(child: Text('$lower', textAlign: TextAlign.start)),
            Expanded(child: Text('Mitte $midpoint', textAlign: TextAlign.center)),
            Expanded(child: Text('$upper', textAlign: TextAlign.end)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                key: const ValueKey('touch-rounding-lower'),
                onPressed: widget.locked ? null : () => widget.onAnswer(lower),
                child: Text('Zu $lower'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonal(
                key: const ValueKey('touch-rounding-upper'),
                onPressed: widget.locked ? null : () => widget.onAnswer(upper),
                child: Text('Zu $upper'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstimationRounding(BuildContext context) {
    final values = widget.plan.dataValues;
    final a = values[0];
    final b = values[1];
    final place = values[2];
    final roundedA = values[3];
    final roundedB = values[4];

    List<int> candidates(int value) {
      final lower = (value ~/ place) * place;
      final upper = lower + place;
      return <int>{lower, upper}.toList()..sort();
    }

    Widget rowFor({required String label, required int value, required bool first}) {
      final selected = first ? selectedEstimateA : selectedEstimateB;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final candidate in candidates(value))
                ChoiceChip(
                  key: ValueKey('touch-estimate-${first ? 'a' : 'b'}-$candidate'),
                  label: Text('$candidate'),
                  selected: selected == candidate,
                  onSelected: widget.locked
                      ? null
                      : (_) => setState(() {
                            if (first) {
                              selectedEstimateA = candidate;
                            } else {
                              selectedEstimateB = candidate;
                            }
                          }),
                ),
            ],
          ),
        ],
      );
    }

    final ready = selectedEstimateA != null && selectedEstimateB != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rowFor(label: 'Erster Summand', value: a, first: true),
        const SizedBox(height: 12),
        rowFor(label: 'Zweiter Summand', value: b, first: false),
        const SizedBox(height: 12),
        Text(
          ready
              ? '${selectedEstimateA!} + ${selectedEstimateB!} – welcher Überschlag passt?'
              : 'Runde zuerst beide Summanden.',
          key: const ValueKey('touch-estimate-status'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < widget.plan.answerChoices.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.tonal(
              key: ValueKey('touch-estimate-result-$index'),
              onPressed: widget.locked || !ready
                  ? null
                  : () {
                      final expected = widget.plan.expectedAnswer ?? 0;
                      final structureCorrect =
                          selectedEstimateA == roundedA && selectedEstimateB == roundedB;
                      widget.onAnswer(
                        structureCorrect && index == expected
                            ? expected
                            : _wrongAnswer(index, expected),
                      );
                    },
              child: Text(widget.plan.answerChoices[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildVolumeLayerBuilder(BuildContext context) {
    final length = widget.plan.dataValues[0];
    final width = widget.plan.dataValues[1];
    final targetLayers = widget.plan.dataValues[2];
    final baseCount = length * width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Eine Schicht: $length lang × $width breit',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: GridView.builder(
              key: const ValueKey('touch-volume-base-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: length,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: baseCount,
              itemBuilder: (context, index) => DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            IconButton.filledTonal(
              key: const ValueKey('touch-volume-layer-minus'),
              onPressed: widget.locked || volumeLayers <= 1
                  ? null
                  : () => setState(() => volumeLayers--),
              icon: const Icon(Icons.remove_rounded),
            ),
            Text(
              '$volumeLayers Schicht${volumeLayers == 1 ? '' : 'en'}',
              key: const ValueKey('touch-volume-layer-count'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton.filledTonal(
              key: const ValueKey('touch-volume-layer-plus'),
              onPressed: widget.locked || volumeLayers >= 6
                  ? null
                  : () => setState(() => volumeLayers++),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        Text(
          'Baue $targetLayers Schicht${targetLayers == 1 ? '' : 'en'} und gib dann die Gesamtzahl ein.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        NumberAnswerPad(
          key: const ValueKey('touch-volume-number-pad'),
          maxValue: widget.plan.maxValue,
          onAnswer: _submitVolumeAnswer,
        ),
      ],
    );
  }

  void _submitVolumeAnswer(int candidate) {
    final targetLayers = widget.plan.dataValues[2];
    final expected = widget.plan.expectedAnswer ?? 0;
    final correct = volumeLayers == targetLayers && candidate == expected;
    widget.onAnswer(correct ? expected : _wrongAnswer(candidate, expected));
  }

  Widget _buildRepresentationSorter(BuildContext context) {
    final choices = widget.plan.answerChoices;
    const icons = <IconData>[
      Icons.format_list_numbered_rounded,
      Icons.table_chart_rounded,
      Icons.bar_chart_rounded,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Draggable<int>(
          key: const ValueKey('touch-representation-source'),
          data: 1,
          feedback: Material(
            color: Colors.transparent,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lightbulb_outline_rounded),
                    SizedBox(width: 8),
                    Text('Diese Situation zuordnen'),
                  ],
                ),
              ),
            ),
          ),
          childWhenDragging: const Opacity(
            opacity: 0.35,
            child: _RepresentationSourceCard(),
          ),
          child: const _RepresentationSourceCard(),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < choices.length; index++) ...[
          DragTarget<int>(
            key: ValueKey('touch-representation-target-$index'),
            onWillAcceptWithDetails: (_) => !widget.locked,
            onAcceptWithDetails: (_) => widget.onAnswer(index),
            builder: (context, candidate, rejected) => InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.locked ? null : () => widget.onAnswer(index),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(icons[index], size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          choices[index],
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (index != choices.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildProbabilityOutcomes(BuildContext context) {
    final correct = widget.plan.correctSelectionIndexes.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < widget.plan.selectionLabels.length; index++)
              FilterChip(
                key: ValueKey('touch-probability-face-$index'),
                selected: selectedProbabilityOutcomes.contains(index),
                label: Text(widget.plan.selectionLabels[index]),
                avatar: const Icon(Icons.casino_outlined, size: 18),
                onSelected: widget.locked
                    ? null
                    : (selected) => setState(() {
                        probabilityNoOutcome = false;
                        if (selected) {
                          selectedProbabilityOutcomes.add(index);
                        } else {
                          selectedProbabilityOutcomes.remove(index);
                        }
                      }),
              ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey('touch-probability-none'),
          onPressed: widget.locked
              ? null
              : () => setState(() {
                    selectedProbabilityOutcomes.clear();
                    probabilityNoOutcome = true;
                  }),
          icon: Icon(
            probabilityNoOutcome
                ? Icons.check_circle_rounded
                : Icons.block_rounded,
          ),
          label: const Text('Keines der Ergebnisse passt'),
        ),
        const SizedBox(height: 8),
        Text(
          probabilityNoOutcome
              ? 'Kein Würfelergebnis markiert'
              : '${selectedProbabilityOutcomes.length} Ergebnis(se) markiert',
          key: const ValueKey('touch-probability-selection-status'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-probability-submit'),
          onPressed: widget.locked
              ? null
              : () {
                  final emptyIsExplicit = correct.isNotEmpty || probabilityNoOutcome;
                  final structureCorrect = emptyIsExplicit &&
                      setEquals(selectedProbabilityOutcomes, correct);
                  final expected = widget.plan.expectedAnswer ?? 0;
                  widget.onAnswer(
                    structureCorrect
                        ? expected
                        : _wrongAnswer(selectedProbabilityOutcomes.length, expected),
                  );
                },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Ergebnisraum prüfen'),
        ),
      ],
    );
  }

  Widget _buildProbabilityExperimentComparison(BuildContext context) {
    final values = widget.plan.dataValues;
    final trials = values.isNotEmpty ? values[0] : 0;
    final red = values.length > 1 ? values[1] : 0;
    final blue = values.length > 2 ? values[2] : 0;
    final choices = widget.plan.answerChoices;

    Widget countCard(String label, int count, Color color) => SizedBox(
      width: 128,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 3,
                runSpacing: 3,
                children: [
                  for (var i = 0; i < count; i++)
                    Icon(Icons.circle, size: 13, color: color),
                ],
              ),
              const SizedBox(height: 6),
              Text('$count von $trials'),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Beobachtete Ergebnisse in $trials Versuchen',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            countCard('Rot', red, Theme.of(context).colorScheme.error),
            countCard('Blau', blue, Theme.of(context).colorScheme.primary),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Draggable<int>(
            key: const ValueKey('touch-experiment-marker'),
            data: 1,
            feedback: const Material(
              color: Colors.transparent,
              child: Chip(
                avatar: Icon(Icons.fact_check_outlined),
                label: Text('Beobachtung'),
              ),
            ),
            childWhenDragging: const Opacity(
              opacity: 0.35,
              child: Chip(
                avatar: Icon(Icons.fact_check_outlined),
                label: Text('Beobachtung'),
              ),
            ),
            child: const Chip(
              avatar: Icon(Icons.fact_check_outlined),
              label: Text('Beobachtung zuordnen'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 440;
            final width = narrow
                ? constraints.maxWidth
                : (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < choices.length; index++)
                  SizedBox(
                    width: width,
                    child: DragTarget<int>(
                      key: ValueKey('touch-experiment-target-$index'),
                      onWillAcceptWithDetails: (_) => !widget.locked,
                      onAcceptWithDetails: (_) => widget.onAnswer(index),
                      builder: (context, candidate, rejected) => InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: widget.locked ? null : () => widget.onAnswer(index),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              choices[index],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        const Text(
          'Nur die beobachteten Häufigkeiten vergleichen – daraus folgt noch keine sichere Vorhersage.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProbabilityRelativeHundredGrid(BuildContext context) {
    final values = widget.plan.dataValues;
    final trials = values.isNotEmpty ? values[0] : 0;
    final hits = values.length > 1 ? values[1] : 0;
    final choices = widget.plan.answerChoices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$hits von $trials Versuchen waren Rot.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          key: const ValueKey('touch-relative-source-share'),
          value: trials == 0 ? 0 : hits / trials,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 12),
        Text(
          'Auf 100 übertragen: $selectedRelativePercent von 100',
          key: const ValueKey('touch-relative-value'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            key: const ValueKey('touch-relative-grid'),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: 100,
            itemBuilder: (context, index) {
              final filled = index < selectedRelativePercent;
              return InkWell(
                key: ValueKey('touch-relative-cell-$index'),
                onTap: widget.locked
                    ? null
                    : () => setState(() => selectedRelativePercent = index + 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: filled
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: filled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: filled ? 1.5 : 0.7,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ),
        Slider(
          key: const ValueKey('touch-relative-slider'),
          value: selectedRelativePercent.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          label: '$selectedRelativePercent %',
          onChanged: widget.locked
              ? null
              : (value) => setState(() => selectedRelativePercent = value.round()),
        ),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-relative-submit'),
          onPressed: widget.locked
              ? null
              : () {
                  final exact = choices.indexOf('$selectedRelativePercent %');
                  if (exact >= 0) {
                    widget.onAnswer(exact);
                    return;
                  }
                  final expected = widget.plan.expectedAnswer ?? 0;
                  final wrong = choices.length <= 1 ? -1 : (expected == 0 ? 1 : 0);
                  widget.onAnswer(wrong);
                },
          icon: const Icon(Icons.grid_on_rounded),
          label: const Text('100er-Feld prüfen'),
        ),
      ],
    );
  }

  Widget _buildProbabilityBagComparison(BuildContext context) {
    final red = widget.plan.dataValues.isNotEmpty ? widget.plan.dataValues[0] : 0;
    final blue = widget.plan.dataValues.length > 1 ? widget.plan.dataValues[1] : 0;
    final expected = widget.plan.expectedAnswer ?? 0;

    Widget pile(String label, int count, int answerIndex) => Expanded(
      child: DragTarget<int>(
        key: ValueKey('touch-bag-target-$answerIndex'),
        onWillAcceptWithDetails: (_) => !widget.locked,
        onAcceptWithDetails: (_) => widget.onAnswer(answerIndex),
        builder: (context, candidate, rejected) => InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.locked ? null : () => widget.onAnswer(answerIndex),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < count; i++)
                        Icon(
                          Icons.circle,
                          size: 22,
                          color: answerIndex == 0
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('$count Stück'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pile('Rot', red, 0),
            const SizedBox(width: 8),
            Expanded(
              child: DragTarget<int>(
                key: const ValueKey('touch-bag-target-2'),
                onWillAcceptWithDetails: (_) => !widget.locked,
                onAcceptWithDetails: (_) => widget.onAnswer(2),
                builder: (context, candidate, rejected) => InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: widget.locked ? null : () => widget.onAnswer(2),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.drag_handle_rounded, size: 32),
                          SizedBox(height: 6),
                          Text('gleich', style: TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            pile('Blau', blue, 1),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Draggable<int>(
            key: const ValueKey('touch-bag-marker'),
            data: expected,
            feedback: const Material(
              color: Colors.transparent,
              child: Chip(
                avatar: Icon(Icons.balance_rounded),
                label: Text('Chance'),
              ),
            ),
            childWhenDragging: const Opacity(
              opacity: 0.35,
              child: Chip(
                avatar: Icon(Icons.balance_rounded),
                label: Text('Chance'),
              ),
            ),
            child: const Chip(
              avatar: Icon(Icons.balance_rounded),
              label: Text('Chance-Marker ziehen'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCombinatoricsGrid(BuildContext context) {
    final values = widget.plan.dataValues;
    final first = values.isNotEmpty ? values[0] : 0;
    final second = values.length > 1 ? values[1] : 0;
    final third = values.length > 2 ? values[2] : 1;
    final total = first * second * third;
    final family = widget.plan.dataLabels.isNotEmpty
        ? widget.plan.dataLabels.first
        : 'combo';
    final labels = switch (family) {
      'clothes' => ('T-Shirt', 'Hose', 'Mütze'),
      'icecream' => ('Sorte', 'Soße', 'Streusel'),
      _ => ('Symbol', 'Farbe', 'Rahmen'),
    };

    String combinationLabel(int index) {
      final perLayer = first * second;
      final layer = index ~/ perLayer;
      final within = index % perLayer;
      final a = within ~/ second;
      final b = within % second;
      final base = '${labels.$1} ${a + 1} + ${labels.$2} ${b + 1}';
      return third > 1 ? '$base + ${labels.$3} ${layer + 1}' : base;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${selectedCombinations.length} von $total Kombinationen markiert',
          key: const ValueKey('touch-combo-count'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          key: const ValueKey('touch-combo-grid'),
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var index = 0; index < total; index++)
              FilterChip(
                key: ValueKey('touch-combo-$index'),
                selected: selectedCombinations.contains(index),
                label: Text(combinationLabel(index)),
                onSelected: widget.locked
                    ? null
                    : (selected) => setState(() {
                          if (selected) {
                            selectedCombinations.add(index);
                          } else {
                            selectedCombinations.remove(index);
                          }
                        }),
              ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-combo-submit'),
          onPressed: widget.locked
              ? null
              : () {
                  final expected = widget.plan.expectedAnswer ?? total;
                  widget.onAnswer(
                    selectedCombinations.length == total
                        ? expected
                        : _wrongAnswer(selectedCombinations.length, expected),
                  );
                },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Kombinationen prüfen'),
        ),
      ],
    );
  }

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
    final canAddTen = !widget.locked && value + 10 <= maxValue;
    final canAddOne =
        !widget.locked && placeOnes < 9 && value + 1 <= maxValue;
    void addTen() => setState(() => placeTens += 1);
    void addOne() => setState(() => placeOnes += 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Zieh Zehnerstäbe und Einerwürfel in die passenden Felder. Antippen geht auch.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            _PlaceManipulativeSource(
              sourceKey: const ValueKey('touch-place-source-10'),
              value: 10,
              label: 'Zehnerstab',
              locked: !canAddTen,
              onTap: addTen,
            ),
            _PlaceManipulativeSource(
              sourceKey: const ValueKey('touch-place-source-1'),
              value: 1,
              label: 'Einerwürfel',
              locked: !canAddOne,
              onTap: addOne,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _PlaceCounter(
              dropKey: const ValueKey('touch-place-tens-target'),
              label: 'Zehner',
              value: placeTens,
              acceptedValue: 10,
              addKey: const ValueKey('touch-place-tens-add'),
              removeKey: const ValueKey('touch-place-tens-remove'),
              onAccept: canAddTen ? addTen : null,
              onAdd: canAddTen ? addTen : null,
              onRemove: widget.locked || placeTens == 0
                  ? null
                  : () => setState(() => placeTens -= 1),
            ),
            _PlaceCounter(
              dropKey: const ValueKey('touch-place-ones-target'),
              label: 'Einer',
              value: placeOnes,
              acceptedValue: 1,
              addKey: const ValueKey('touch-place-ones-add'),
              removeKey: const ValueKey('touch-place-ones-remove'),
              onAccept: canAddOne ? addOne : null,
              onAdd: canAddOne ? addOne : null,
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
    void addMoney(int value) {
      if (widget.locked || total + value > widget.plan.maxValue) return;
      setState(() => moneyPieces.add(value));
    }
    void removeMoney(int index) {
      if (widget.locked || index < 0 || index >= moneyPieces.length) return;
      setState(() => moneyPieces.removeAt(index));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label(total),
          key: const ValueKey('touch-money-total'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Zieh Geld in das Feld. Antippen fügt es ebenfalls hinzu.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final denomination in widget.plan.denominations)
              _MoneySourcePiece(
                sourceKey: ValueKey('touch-money-add-$denomination'),
                value: denomination,
                unit: unit,
                locked:
                    widget.locked || total + denomination > widget.plan.maxValue,
                onTap: () => addMoney(denomination),
              ),
          ],
        ),
        const SizedBox(height: 12),
        DragTarget<_MoneyDragData>(
          key: const ValueKey('touch-money-workspace'),
          onWillAcceptWithDetails: (details) =>
              !widget.locked &&
              !details.data.isPlaced &&
              total + details.data.value <= widget.plan.maxValue,
          onAcceptWithDetails: (details) => addMoney(details.data.value),
          builder: (context, candidates, rejected) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(10),
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
            child: moneyPieces.isEmpty
                ? const Center(child: Text('Geld hier ablegen'))
                : Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (var index = 0; index < moneyPieces.length; index++)
                        _PlacedMoneyPiece(
                          pieceKey: ValueKey('touch-money-piece-$index'),
                          value: moneyPieces[index],
                          unit: unit,
                          index: index,
                          locked: widget.locked,
                          onDelete: () => removeMoney(index),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        DragTarget<_MoneyDragData>(
          key: const ValueKey('touch-money-return'),
          onWillAcceptWithDetails: (details) =>
              !widget.locked && details.data.isPlaced,
          onAcceptWithDetails: (details) =>
              removeMoney(details.data.placedIndex!),
          builder: (context, candidates, rejected) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: candidates.isNotEmpty
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: candidates.isNotEmpty
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_return_rounded),
                SizedBox(width: 7),
                Flexible(child: Text('Geldstück hierhin zurückziehen')),
              ],
            ),
          ),
        ),
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
    const clockSize = Size(220, 220);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welchen Zeiger möchtest du bewegen?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const ValueKey('touch-clock-hour-hand'),
              label: const Text('Kurzer Zeiger'),
              avatar: const Icon(Icons.schedule_rounded),
              selected: !clockMinuteHandActive,
              onSelected: widget.locked
                  ? null
                  : (_) => setState(() => clockMinuteHandActive = false),
            ),
            ChoiceChip(
              key: const ValueKey('touch-clock-minute-hand'),
              label: const Text('Langer Zeiger'),
              avatar: const Icon(Icons.more_time_rounded),
              selected: clockMinuteHandActive,
              onSelected: widget.locked
                  ? null
                  : (_) => setState(() => clockMinuteHandActive = true),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Semantics(
            label: 'Einstellbare Uhr',
            value:
                '$selectedHour:${selectedMinute.toString().padLeft(2, '0')} Uhr',
            hint: clockMinuteHandActive
                ? 'Ziehe den langen Minutenzeiger.'
                : 'Ziehe den kurzen Stundenzeiger.',
            child: GestureDetector(
              key: const ValueKey('touch-clock-drag-surface'),
              behavior: HitTestBehavior.opaque,
              onPanStart: widget.locked
                  ? null
                  : (details) => _updateClockFromPosition(
                      details.localPosition,
                      clockSize,
                      minuteValues,
                    ),
              onPanUpdate: widget.locked
                  ? null
                  : (details) => _updateClockFromPosition(
                      details.localPosition,
                      clockSize,
                      minuteValues,
                    ),
              onTapDown: widget.locked
                  ? null
                  : (details) => _updateClockFromPosition(
                      details.localPosition,
                      clockSize,
                      minuteValues,
                    ),
              child: SizedBox(
                width: clockSize.width,
                height: clockSize.height,
                child: CustomPaint(
                  key: const ValueKey('touch-clock-preview'),
                  painter: _TouchClockPainter(
                    hour: selectedHour,
                    minute: selectedMinute,
                    color: Theme.of(context).colorScheme.onSurface,
                    accent: Theme.of(context).colorScheme.primary,
                    minuteHandActive: clockMinuteHandActive,
                  ),
                ),
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
        const SizedBox(height: 4),
        Text(
          clockMinuteHandActive
              ? 'Zieh den langen Zeiger direkt auf die passenden Minuten.'
              : 'Zieh den kurzen Zeiger direkt auf die passende Stunde.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-clock-submit'),
          onPressed: widget.locked ? null : _submitClock,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Uhrzeit prüfen'),
        ),
      ],
    );
  }

  void _updateClockFromPosition(
    Offset position,
    Size size,
    List<int> minuteValues,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = position - center;
    if (delta.distance < 12) return;
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    if (clockMinuteHandActive) {
      final rawMinute = ((angle / (2 * math.pi)) * 60).round() % 60;
      final nearest = minuteValues.reduce((best, candidate) {
        int distance(int value) {
          final direct = (value - rawMinute).abs();
          return math.min(direct, 60 - direct);
        }

        return distance(candidate) < distance(best) ? candidate : best;
      });
      if (nearest != selectedMinute) {
        setState(() => selectedMinute = nearest);
      }
      return;
    }
    final rawHour = (angle / (2 * math.pi)) * 12 - selectedMinute / 60;
    var snappedHour = rawHour.round() % 12;
    if (snappedHour <= 0) snappedHour += 12;
    if (snappedHour != selectedHour) {
      setState(() => selectedHour = snappedHour);
    }
  }

  Widget _buildFractionBuilder(BuildContext context) {
    final numerator = widget.plan.fractionNumerator ?? 1;
    final denominator = widget.plan.fractionDenominator ?? 1;
    final whole = widget.plan.fractionWhole ?? 1;
    final total = fractionPartSize * denominator;
    final result = fractionPartSize * numerator;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Markiere $numerator von $denominator gleich großen Teilen.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Row(
          key: const ValueKey('touch-fraction-pieces'),
          children: [
            for (var index = 0; index < denominator; index++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == denominator - 1 ? 0 : 4,
                  ),
                  child: Semantics(
                    button: true,
                    selected: selectedFractionParts.contains(index),
                    label: 'Bruchteil ${index + 1} von $denominator',
                    child: InkWell(
                      key: ValueKey('touch-fraction-piece-$index'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: widget.locked
                          ? null
                          : () => setState(() {
                              if (!selectedFractionParts.add(index)) {
                                selectedFractionParts.remove(index);
                              }
                            }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedFractionParts.contains(index)
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedFractionParts.contains(index)
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                            width: selectedFractionParts.contains(index) ? 2 : 1,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${index + 1}/$denominator',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text('$fractionPartSize'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${selectedFractionParts.length} von $denominator Teilen markiert',
          key: const ValueKey('touch-fraction-selected-count'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          '1 Teil = $fractionPartSize',
          key: const ValueKey('touch-fraction-part-size'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Slider(
          key: const ValueKey('touch-fraction-part-slider'),
          value: fractionPartSize.toDouble(),
          min: 0,
          max: whole.toDouble(),
          divisions: whole,
          label: '$fractionPartSize',
          onChanged: widget.locked
              ? null
              : (value) => setState(() => fractionPartSize = value.round()),
        ),
        const SizedBox(height: 6),
        Text(
          '$denominator × $fractionPartSize = $total von $whole',
          key: const ValueKey('touch-fraction-total'),
          textAlign: TextAlign.center,
        ),
        Text(
          '$numerator/$denominator von $whole = $result',
          key: const ValueKey('touch-fraction-result'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-fraction-submit'),
          onPressed: widget.locked ? null : _submitFraction,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Bruchteil prüfen'),
        ),
      ],
    );
  }

  void _submitFraction() {
    final numerator = widget.plan.fractionNumerator ?? 1;
    final denominator = widget.plan.fractionDenominator ?? 1;
    final whole = widget.plan.fractionWhole ?? 1;
    final expected = widget.plan.expectedAnswer ?? fractionPartSize * numerator;
    final equalPartsFit = fractionPartSize * denominator == whole;
    final markedPartsFit = selectedFractionParts.length == numerator;
    if (equalPartsFit && markedPartsFit) {
      widget.onAnswer(expected);
      return;
    }
    final candidate = fractionPartSize * selectedFractionParts.length;
    widget.onAnswer(_wrongAnswer(candidate, expected));
  }

  Widget _buildPathWalker(BuildContext context) {
    final goalRight = widget.plan.pathRight ?? 0;
    final goalUp = widget.plan.pathUp ?? 0;
    final total = pathX + pathY;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 230,
            height: 210,
            child: CustomPaint(
              key: const ValueKey('touch-path-grid'),
              painter: _TouchPathPainter(
                goalRight: goalRight,
                goalUp: goalUp,
                currentRight: pathX,
                currentUp: pathY,
                color: Theme.of(context).colorScheme.onSurface,
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$pathX nach rechts + $pathY nach oben = $total Felder',
          key: const ValueKey('touch-path-value'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              key: const ValueKey('touch-path-right'),
              onPressed: widget.locked || pathX >= goalRight + 2
                  ? null
                  : () => setState(() => pathX += 1),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('1 rechts'),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('touch-path-up'),
              onPressed: widget.locked || pathY >= goalUp + 2
                  ? null
                  : () => setState(() => pathY += 1),
              icon: const Icon(Icons.arrow_upward_rounded),
              label: const Text('1 hoch'),
            ),
            TextButton.icon(
              key: const ValueKey('touch-path-reset'),
              onPressed: widget.locked || (pathX == 0 && pathY == 0)
                  ? null
                  : () => setState(() {
                      pathX = 0;
                      pathY = 0;
                    }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Neu starten'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-path-submit'),
          onPressed: widget.locked ? null : _submitPath,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Weg prüfen'),
        ),
      ],
    );
  }

  void _submitPath() {
    final goalRight = widget.plan.pathRight ?? 0;
    final goalUp = widget.plan.pathUp ?? 0;
    final expected = widget.plan.expectedAnswer ?? goalRight + goalUp;
    final total = pathX + pathY;
    if (pathX == goalRight && pathY == goalUp) {
      widget.onAnswer(expected);
    } else if (total != expected) {
      widget.onAnswer(total);
    } else {
      widget.onAnswer(math.max(0, expected - 1));
    }
  }

  Widget _buildSymmetryAxes(BuildContext context) {
    final labels = widget.plan.selectionLabels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 230,
            height: 180,
            child: CustomPaint(
              key: const ValueKey('touch-symmetry-preview'),
              painter: _TouchSymmetryPainter(
                shape: widget.plan.symmetryShape ?? '',
                selectedAxes: selectedAxes,
                color: Theme.of(context).colorScheme.onSurface,
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < labels.length; index++)
              FilterChip(
                key: ValueKey('touch-symmetry-axis-$index'),
                label: Text(labels[index]),
                selected: selectedAxes.contains(index),
                onSelected: widget.locked
                    ? null
                    : (selected) => setState(() {
                        if (selected) {
                          selectedAxes.add(index);
                        } else {
                          selectedAxes.remove(index);
                        }
                      }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${selectedAxes.length} Achsen ausgewählt',
          key: const ValueKey('touch-symmetry-count'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-symmetry-submit'),
          onPressed: widget.locked ? null : _submitSymmetry,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Achsen prüfen'),
        ),
      ],
    );
  }

  void _submitSymmetry() {
    final expectedSet = widget.plan.correctSelectionIndexes.toSet();
    final expected = widget.plan.expectedAnswer ?? expectedSet.length;
    if (selectedAxes.length == expectedSet.length &&
        selectedAxes.containsAll(expectedSet)) {
      widget.onAnswer(expected);
    } else if (selectedAxes.length != expected) {
      widget.onAnswer(selectedAxes.length);
    } else {
      widget.onAnswer(math.max(0, expected - 1));
    }
  }

  Widget _buildShapeCorners(BuildContext context) {
    const canvasSize = Size(250, 190);
    final shape = widget.plan.geometryShape ?? 'rectangle';
    final candidates = _shapeCandidatePoints(shape, canvasSize);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: canvasSize.width,
            height: canvasSize.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    key: const ValueKey('touch-shape-corners-preview'),
                    painter: _TouchShapeCornersPainter(
                      shape: shape,
                      selectedPoints: selectedShapePoints,
                      color: Theme.of(context).colorScheme.onSurface,
                      accent: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                for (var index = 0; index < candidates.length; index++)
                  Positioned(
                    left: candidates[index].dx - 22,
                    top: candidates[index].dy - 22,
                    width: 44,
                    height: 44,
                    child: Semantics(
                      button: true,
                      selected: selectedShapePoints.contains(index),
                      label: 'Markierpunkt ${index + 1}',
                      child: IconButton(
                        key: ValueKey('touch-shape-point-$index'),
                        tooltip: 'Punkt ${index + 1} markieren',
                        onPressed: widget.locked
                            ? null
                            : () => setState(() {
                                if (!selectedShapePoints.add(index)) {
                                  selectedShapePoints.remove(index);
                                }
                              }),
                        icon: Icon(
                          selectedShapePoints.contains(index)
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selectedShapePoints.contains(index)
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${selectedShapePoints.length} Punkte markiert',
          key: const ValueKey('touch-shape-corners-count'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-shape-corners-submit'),
          onPressed: widget.locked ? null : _submitShapeCorners,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Ecken prüfen'),
        ),
      ],
    );
  }

  void _submitShapeCorners() {
    final expectedSet = widget.plan.correctSelectionIndexes.toSet();
    final expected = widget.plan.expectedAnswer ?? expectedSet.length;
    if (setEquals(selectedShapePoints, expectedSet)) {
      widget.onAnswer(expected);
    } else if (selectedShapePoints.length != expected) {
      widget.onAnswer(selectedShapePoints.length);
    } else {
      widget.onAnswer(math.max(0, expected - 1));
    }
  }

  Widget _buildShapeSides(BuildContext context) {
    const canvasSize = Size(250, 190);
    final shape = widget.plan.geometryShape ?? 'rectangle';
    final segments = _shapeSideSegments(shape, canvasSize);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: canvasSize.width,
            height: canvasSize.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    key: const ValueKey('touch-shape-sides-preview'),
                    painter: _TouchShapeSidesPainter(
                      shape: shape,
                      selectedSides: selectedShapeSides,
                      color: Theme.of(context).colorScheme.onSurface,
                      accent: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                for (var index = 0; index < segments.length; index++)
                  _shapeSideTapTarget(
                    index: index,
                    segment: segments[index],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          shape == 'circle'
              ? 'Keine gerade Seite zum Markieren'
              : '${selectedShapeSides.length} Seiten markiert',
          key: const ValueKey('touch-shape-sides-count'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-shape-sides-submit'),
          onPressed: widget.locked ? null : _submitShapeSides,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Seiten prüfen'),
        ),
      ],
    );
  }

  Widget _shapeSideTapTarget({
    required int index,
    required (Offset, Offset) segment,
  }) {
    final start = segment.$1;
    final end = segment.$2;
    final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final selected = selectedShapeSides.contains(index);
    return Positioned(
      left: midpoint.dx - 24,
      top: midpoint.dy - 24,
      width: 48,
      height: 48,
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Seite ${index + 1}',
        child: Transform.rotate(
          angle: angle,
          child: IconButton(
            key: ValueKey('touch-shape-side-$index'),
            tooltip: 'Seite ${index + 1} markieren',
            onPressed: widget.locked
                ? null
                : () => setState(() {
                    if (!selectedShapeSides.add(index)) {
                      selectedShapeSides.remove(index);
                    }
                  }),
            icon: Icon(
              Icons.horizontal_rule_rounded,
              size: 42,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }

  void _submitShapeSides() {
    final expectedSet = widget.plan.correctSelectionIndexes.toSet();
    final expected = widget.plan.expectedAnswer ?? expectedSet.length;
    if (setEquals(selectedShapeSides, expectedSet)) {
      widget.onAnswer(expected);
    } else {
      widget.onAnswer(_wrongAnswer(selectedShapeSides.length, expected));
    }
  }

  Widget _buildRectanglePerimeter(BuildContext context) {
    final width = widget.plan.rectangleWidth ?? 1;
    final height = widget.plan.rectangleHeight ?? 1;
    final selectedLength = selectedPerimeterEdges.fold<int>(0, (sum, edge) {
      return sum + ((edge == 0 || edge == 2) ? width : height);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 250,
            height: 190,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    key: const ValueKey('touch-perimeter-preview'),
                    painter: _TouchPerimeterPainter(
                      selectedEdges: selectedPerimeterEdges,
                      color: Theme.of(context).colorScheme.onSurface,
                      accent: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                _perimeterTapTarget(
                  index: 0,
                  label: 'obere Kante, $width cm',
                  left: 35,
                  top: 12,
                  width: 180,
                  height: 42,
                ),
                _perimeterTapTarget(
                  index: 1,
                  label: 'rechte Kante, $height cm',
                  left: 196,
                  top: 34,
                  width: 42,
                  height: 122,
                ),
                _perimeterTapTarget(
                  index: 2,
                  label: 'untere Kante, $width cm',
                  left: 35,
                  top: 136,
                  width: 180,
                  height: 42,
                ),
                _perimeterTapTarget(
                  index: 3,
                  label: 'linke Kante, $height cm',
                  left: 12,
                  top: 34,
                  width: 42,
                  height: 122,
                ),
              ],
            ),
          ),
        ),
        Text(
          'Oben/unten: $width cm · Links/rechts: $height cm',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Markierte Kanten zusammen: $selectedLength cm',
          key: const ValueKey('touch-perimeter-length'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-perimeter-submit'),
          onPressed: widget.locked
              ? null
              : () => widget.onAnswer(selectedLength),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Umfang prüfen'),
        ),
      ],
    );
  }

  Widget _perimeterTapTarget({
    required int index,
    required String label,
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final selected = selectedPerimeterEdges.contains(index);
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          key: ValueKey('touch-perimeter-edge-$index'),
          behavior: HitTestBehavior.opaque,
          onTap: widget.locked
              ? null
              : () => setState(() {
                  if (!selectedPerimeterEdges.add(index)) {
                    selectedPerimeterEdges.remove(index);
                  }
                }),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildRectangleArea(BuildContext context) {
    final targetWidth = widget.plan.rectangleWidth ?? 1;
    final targetHeight = widget.plan.rectangleHeight ?? 1;
    final maxDimension = math.max(targetWidth, targetHeight);
    final builtArea = areaColumns * areaRows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gegeben: $targetWidth cm lang · $targetHeight cm breit',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            width: 270,
            height: 175,
            child: CustomPaint(
              key: const ValueKey('touch-area-preview'),
              painter: _TouchAreaPainter(
                columns: areaColumns,
                rows: areaRows,
                color: Theme.of(context).colorScheme.onSurface,
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        Text(
          '$areaColumns Spalten × $areaRows Reihen = $builtArea cm²',
          key: const ValueKey('touch-area-structure'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _areaDimensionControl(
          context: context,
          label: 'Länge / Spalten',
          value: areaColumns,
          maxValue: maxDimension,
          sliderKey: const ValueKey('touch-area-columns-slider'),
          removeKey: const ValueKey('touch-area-columns-remove'),
          addKey: const ValueKey('touch-area-columns-add'),
          onChanged: (value) => setState(() => areaColumns = value),
        ),
        const SizedBox(height: 6),
        _areaDimensionControl(
          context: context,
          label: 'Breite / Reihen',
          value: areaRows,
          maxValue: maxDimension,
          sliderKey: const ValueKey('touch-area-rows-slider'),
          removeKey: const ValueKey('touch-area-rows-remove'),
          addKey: const ValueKey('touch-area-rows-add'),
          onChanged: (value) => setState(() => areaRows = value),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-area-submit'),
          onPressed: widget.locked ? null : _submitRectangleArea,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Fläche prüfen'),
        ),
      ],
    );
  }

  Widget _areaDimensionControl({
    required BuildContext context,
    required String label,
    required int value,
    required int maxValue,
    required Key sliderKey,
    required Key removeKey,
    required Key addKey,
    required ValueChanged<int> onChanged,
  }) {
    final upper = math.max(1, maxValue);
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        IconButton(
          key: removeKey,
          tooltip: '$label verkleinern',
          onPressed: widget.locked || value <= 1
              ? null
              : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_rounded),
        ),
        Expanded(
          child: Slider(
            key: sliderKey,
            value: value.toDouble(),
            min: 1,
            max: upper.toDouble(),
            divisions: upper > 1 ? upper - 1 : null,
            label: '$value',
            onChanged: widget.locked || upper == 1
                ? null
                : (next) => onChanged(next.round()),
          ),
        ),
        IconButton(
          key: addKey,
          tooltip: '$label vergrößern',
          onPressed: widget.locked || value >= upper
              ? null
              : () => onChanged(value + 1),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }

  void _submitRectangleArea() {
    final targetWidth = widget.plan.rectangleWidth ?? 1;
    final targetHeight = widget.plan.rectangleHeight ?? 1;
    final expected = widget.plan.expectedAnswer ?? targetWidth * targetHeight;
    final exactStructure =
        (areaColumns == targetWidth && areaRows == targetHeight) ||
        (areaColumns == targetHeight && areaRows == targetWidth);
    final candidate = areaColumns * areaRows;
    widget.onAnswer(
      exactStructure ? expected : _wrongAnswer(candidate, expected),
    );
  }

  Widget _buildEqualGroups(BuildContext context) {
    final groups = widget.plan.groupCount ?? 0;
    final targetEach = widget.plan.itemsPerGroup ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$groups Gruppen · in jede gehören $targetEach Punkte',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            groupCounters.length,
            (index) => _CounterGroupCard(
              key: ValueKey('touch-equal-group-$index'),
              label: 'Gruppe ${index + 1}',
              count: groupCounters[index],
              onAdd: widget.locked || groupCounters[index] >= targetEach + 2
                  ? null
                  : () => setState(() => groupCounters[index] += 1),
              onRemove: widget.locked || groupCounters[index] == 0
                  ? null
                  : () => setState(() => groupCounters[index] -= 1),
              addKey: ValueKey('touch-equal-group-$index-add'),
              removeKey: ValueKey('touch-equal-group-$index-remove'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sind wirklich alle Gruppen gleich groß?',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-equal-groups-submit'),
          onPressed: widget.locked ? null : _submitEqualGroups,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Punktefeld prüfen'),
        ),
      ],
    );
  }

  void _submitEqualGroups() {
    final targetEach = widget.plan.itemsPerGroup ?? 0;
    final expected =
        widget.plan.expectedAnswer ??
        (widget.plan.groupCount ?? 0) * targetEach;
    final exact =
        groupCounters.isNotEmpty &&
        groupCounters.every((count) => count == targetEach);
    if (exact) {
      widget.onAnswer(expected);
      return;
    }
    final total = groupCounters.fold<int>(0, (sum, count) => sum + count);
    widget.onAnswer(_wrongAnswer(total, expected));
  }

  Widget _buildDivisionGroups(BuildContext context) {
    final total = widget.plan.totalItems ?? 0;
    return widget.plan.divisionGrouping
        ? _buildDivisionGrouping(context, total)
        : _buildDivisionSharing(context, total);
  }

  Widget _buildDivisionSharing(BuildContext context, int total) {
    final distributed = groupCounters.fold<int>(0, (sum, count) => sum + count);
    final remaining = math.max(0, total - distributed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Noch zu verteilen: $remaining von $total',
          key: const ValueKey('touch-sharing-remaining'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            groupCounters.length,
            (index) => _CounterGroupCard(
              key: ValueKey('touch-sharing-group-$index'),
              label: 'Gruppe ${index + 1}',
              count: groupCounters[index],
              onAdd: widget.locked || remaining == 0
                  ? null
                  : () => setState(() => groupCounters[index] += 1),
              onRemove: widget.locked || groupCounters[index] == 0
                  ? null
                  : () => setState(() => groupCounters[index] -= 1),
              addKey: ValueKey('touch-sharing-group-$index-add'),
              removeKey: ValueKey('touch-sharing-group-$index-remove'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Verteile alle Dinge so, dass jede Gruppe gleich viel bekommt.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-sharing-submit'),
          onPressed: widget.locked ? null : _submitDivisionSharing,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Verteilung prüfen'),
        ),
      ],
    );
  }

  void _submitDivisionSharing() {
    final total = widget.plan.totalItems ?? 0;
    final distributed = groupCounters.fold<int>(0, (sum, count) => sum + count);
    final expected = widget.plan.expectedAnswer ?? 0;
    final equal =
        groupCounters.isNotEmpty &&
        groupCounters.every((count) => count == groupCounters.first);
    if (distributed == total && equal) {
      widget.onAnswer(groupCounters.first);
      return;
    }
    final candidate = groupCounters.isEmpty ? 0 : groupCounters.first;
    widget.onAnswer(_wrongAnswer(candidate, expected));
  }

  Widget _buildDivisionGrouping(BuildContext context, int total) {
    final each = widget.plan.itemsPerGroup ?? 1;
    final used = builtDivisionGroups * each;
    final remaining = math.max(0, total - used);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Eine Gruppe enthält $each Dinge.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Gebildete Gruppen: $builtDivisionGroups · übrig: $remaining',
          key: const ValueKey('touch-grouping-progress'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            builtDivisionGroups,
            (index) => _StaticCounterGroup(
              key: ValueKey('touch-grouping-group-$index'),
              label: 'Gruppe ${index + 1}',
              count: each,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('touch-grouping-remove'),
              onPressed: widget.locked || builtDivisionGroups == 0
                  ? null
                  : () => setState(() => builtDivisionGroups -= 1),
              icon: const Icon(Icons.remove_rounded),
              label: const Text('Gruppe zurück'),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('touch-grouping-add'),
              onPressed: widget.locked || remaining < each
                  ? null
                  : () => setState(() => builtDivisionGroups += 1),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Gruppe bilden'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-grouping-submit'),
          onPressed: widget.locked ? null : _submitDivisionGrouping,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Gruppen prüfen'),
        ),
      ],
    );
  }

  void _submitDivisionGrouping() {
    final total = widget.plan.totalItems ?? 0;
    final each = widget.plan.itemsPerGroup ?? 1;
    final expected = widget.plan.expectedAnswer ?? 0;
    final used = builtDivisionGroups * each;
    widget.onAnswer(
      used == total
          ? builtDivisionGroups
          : _wrongAnswer(builtDivisionGroups, expected),
    );
  }

  Widget _buildDataChart(BuildContext context) {
    final values = widget.plan.dataValues;
    final labels = widget.plan.dataLabels;
    const scaleMax = 12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ein Kästchen steht für 1. Tippe die Balken an, die du für die Aufgabe brauchst.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < values.length; index++) ...[
          Semantics(
            button: true,
            selected: selectedDataBars.contains(index),
            label: 'Balken ${index < labels.length ? labels[index] : index + 1}',
            child: InkWell(
              key: ValueKey('touch-data-bar-$index'),
              borderRadius: BorderRadius.circular(10),
              onTap: widget.locked
                  ? null
                  : () => setState(() {
                      if (!selectedDataBars.add(index)) {
                        selectedDataBars.remove(index);
                      }
                    }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        index < labels.length ? labels[index] : '${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: List<Widget>.generate(scaleMax, (cell) {
                          final filled = cell < values[index];
                          return Expanded(
                            child: Container(
                              height: 24,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: filled
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: selectedDataBars.contains(index)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outlineVariant,
                                  width: selectedDataBars.contains(index) ? 2 : 1,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 28,
                      child: Icon(
                        selectedDataBars.contains(index)
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 22,
                        color: selectedDataBars.contains(index)
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (index != values.length - 1) const SizedBox(height: 2),
        ],
        const SizedBox(height: 10),
        Text(
          '${selectedDataBars.length} Balken markiert',
          key: const ValueKey('touch-data-selected-count'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (widget.plan.dataOperation == 'max')
          FilledButton.tonalIcon(
            key: const ValueKey('touch-data-submit'),
            onPressed: widget.locked ? null : _submitDataMaximum,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Auswahl prüfen'),
          )
        else ...[
          const Text(
            'Rechne jetzt mit den markierten Balken.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          NumberAnswerPad(
            key: const ValueKey('touch-data-number-pad'),
            maxValue: math.max(1, widget.plan.maxValue),
            onAnswer: _submitDataCalculation,
          ),
        ],
      ],
    );
  }

  bool _dataSelectionFits() {
    final values = widget.plan.dataValues;
    return switch (widget.plan.dataOperation) {
      'max' when values.isNotEmpty =>
        selectedDataBars.length == 1 &&
            values[selectedDataBars.single] == values.reduce(math.max),
      'sum' => selectedDataBars.length == values.length,
      'diff' => setEquals(selectedDataBars, const <int>{0, 1}),
      _ => false,
    };
  }

  void _submitDataMaximum() {
    final values = widget.plan.dataValues;
    final expected = widget.plan.expectedAnswer ?? 0;
    final candidate = selectedDataBars.length == 1
        ? values[selectedDataBars.single]
        : selectedDataBars.length;
    widget.onAnswer(
      _dataSelectionFits() ? expected : _wrongAnswer(candidate, expected),
    );
  }

  void _submitDataCalculation(int candidate) {
    final expected = widget.plan.expectedAnswer ?? 0;
    widget.onAnswer(
      _dataSelectionFits() ? candidate : _wrongAnswer(candidate, expected),
    );
  }

  Widget _buildTallySelection(BuildContext context) {
    final units = widget.plan.dataValues;
    final counted = selectedTallyUnits.fold<int>(
      0,
      (sum, index) => sum + units[index],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          key: const ValueKey('touch-tally-units'),
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(units.length, (index) {
            final selected = selectedTallyUnits.contains(index);
            final value = units[index];
            return FilterChip(
              key: ValueKey('touch-tally-unit-$index'),
              selected: selected,
              onSelected: widget.locked
                  ? null
                  : (_) => setState(() {
                      if (!selectedTallyUnits.add(index)) {
                        selectedTallyUnits.remove(index);
                      }
                    }),
              label: Text(
                value == 5 ? '||||/' : '|',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              tooltip: value == 5 ? 'Fünferblock' : 'ein Strich',
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          'Gezählt: $counted',
          key: const ValueKey('touch-tally-count'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-tally-submit'),
          onPressed: widget.locked ? null : _submitTally,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Strichliste prüfen'),
        ),
      ],
    );
  }

  void _submitTally() {
    final units = widget.plan.dataValues;
    final expected = widget.plan.expectedAnswer ?? 0;
    final counted = selectedTallyUnits.fold<int>(
      0,
      (sum, index) => sum + units[index],
    );
    final allMarked = selectedTallyUnits.length == units.length;
    widget.onAnswer(allMarked ? expected : _wrongAnswer(counted, expected));
  }

  int _wrongAnswer(int candidate, int expected) {
    if (candidate != expected) return candidate;
    return expected == 0 ? 1 : expected - 1;
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

class _CounterGroupCard extends StatelessWidget {
  const _CounterGroupCard({
    super.key,
    required this.label,
    required this.count,
    required this.onAdd,
    required this.onRemove,
    required this.addKey,
    required this.removeKey,
  });

  final String label;
  final int count;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final Key addKey;
  final Key removeKey;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: SizedBox(
      width: 122,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 6),
            _CounterDots(count: count),
            Text('$count'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  key: removeKey,
                  tooltip: 'Einen Punkt entfernen',
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                IconButton(
                  key: addKey,
                  tooltip: 'Einen Punkt hinzufügen',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _StaticCounterGroup extends StatelessWidget {
  const _StaticCounterGroup({
    super.key,
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: SizedBox(
      width: 110,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 4),
            _CounterDots(count: count),
          ],
        ),
      ),
    ),
  );
}

class _CounterDots extends StatelessWidget {
  const _CounterDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 28),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 3,
      runSpacing: 3,
      children: List.generate(
        count,
        (_) => Icon(
          Icons.circle,
          size: 10,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

class _TouchPathPainter extends CustomPainter {
  const _TouchPathPainter({
    required this.goalRight,
    required this.goalUp,
    required this.currentRight,
    required this.currentUp,
    required this.color,
    required this.accent,
  });

  final int goalRight;
  final int goalUp;
  final int currentRight;
  final int currentUp;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final columns = math.max(3, math.max(goalRight, currentRight) + 2);
    final rows = math.max(3, math.max(goalUp, currentUp) + 2);
    final dx = size.width / columns;
    final dy = size.height / rows;
    final grid = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (var x = 0; x <= columns; x++) {
      canvas.drawLine(Offset(x * dx, 0), Offset(x * dx, size.height), grid);
    }
    for (var y = 0; y <= rows; y++) {
      canvas.drawLine(Offset(0, y * dy), Offset(size.width, y * dy), grid);
    }
    Offset point(int right, int up) =>
        Offset((right + 0.5) * dx, size.height - (up + 0.5) * dy);
    final start = point(0, 0);
    final turn = point(currentRight, 0);
    final current = point(currentRight, currentUp);
    final target = point(goalRight, goalUp);
    final pathPaint = Paint()
      ..color = accent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, turn, pathPaint);
    canvas.drawLine(turn, current, pathPaint);
    canvas.drawCircle(start, 6, Paint()..color = color);
    canvas.drawCircle(current, 8, Paint()..color = accent);
    canvas.drawCircle(
      target,
      11,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _TouchPathPainter oldDelegate) =>
      goalRight != oldDelegate.goalRight ||
      goalUp != oldDelegate.goalUp ||
      currentRight != oldDelegate.currentRight ||
      currentUp != oldDelegate.currentUp ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
}

class _TouchSymmetryPainter extends CustomPainter {
  const _TouchSymmetryPainter({
    required this.shape,
    required this.selectedAxes,
    required this.color,
    required this.accent,
  });

  final String shape;
  final Set<int> selectedAxes;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final shapePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final axisPaint = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    if (shape == 'Quadrat' || shape == 'Rechteck') {
      final width = shape == 'Quadrat' ? 125.0 : 175.0;
      const height = 125.0;
      final rect = Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      );
      canvas.drawRect(rect, shapePaint);
      for (final axis in selectedAxes) {
        switch (axis) {
          case 0:
            canvas.drawLine(
              Offset(center.dx, rect.top - 12),
              Offset(center.dx, rect.bottom + 12),
              axisPaint,
            );
          case 1:
            canvas.drawLine(
              Offset(rect.left - 12, center.dy),
              Offset(rect.right + 12, center.dy),
              axisPaint,
            );
          case 2:
            canvas.drawLine(rect.topLeft, rect.bottomRight, axisPaint);
          case 3:
            canvas.drawLine(rect.topRight, rect.bottomLeft, axisPaint);
        }
      }
      return;
    }
    final top = Offset(center.dx, 18);
    final left = Offset(34, size.height - 20);
    final right = Offset(size.width - 34, size.height - 20);
    final triangle = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(triangle, shapePaint);
    final baseMid = Offset((left.dx + right.dx) / 2, left.dy);
    final rightMid = Offset((top.dx + right.dx) / 2, (top.dy + right.dy) / 2);
    final leftMid = Offset((top.dx + left.dx) / 2, (top.dy + left.dy) / 2);
    for (final axis in selectedAxes) {
      switch (axis) {
        case 0:
          canvas.drawLine(top, baseMid, axisPaint);
        case 1:
          canvas.drawLine(left, rightMid, axisPaint);
        case 2:
          canvas.drawLine(right, leftMid, axisPaint);
        case 3:
          canvas.drawLine(
            Offset(left.dx - 8, center.dy),
            Offset(right.dx + 8, center.dy),
            axisPaint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TouchSymmetryPainter oldDelegate) =>
      shape != oldDelegate.shape ||
      !setEquals(selectedAxes, oldDelegate.selectedAxes) ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
}

List<Offset> _shapeCandidatePoints(String shape, Size size) {
  if (shape == 'circle') {
    final center = Offset(size.width / 2, size.height / 2);
    return <Offset>[
      Offset(center.dx, 28),
      Offset(size.width - 32, center.dy),
      Offset(center.dx, size.height - 28),
      Offset(32, center.dy),
    ];
  }
  if (shape == 'triangle') {
    final top = Offset(size.width / 2, 24);
    final right = Offset(size.width - 30, size.height - 28);
    final left = Offset(30, size.height - 28);
    return <Offset>[
      top,
      Offset((top.dx + right.dx) / 2, (top.dy + right.dy) / 2),
      right,
      Offset((right.dx + left.dx) / 2, right.dy),
      left,
      Offset((left.dx + top.dx) / 2, (left.dy + top.dy) / 2),
    ];
  }
  final rect = shape == 'square'
      ? Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 130,
          height: 130,
        )
      : Rect.fromLTWH(30, 34, size.width - 60, size.height - 68);
  return <Offset>[
    rect.topLeft,
    Offset(rect.center.dx, rect.top),
    rect.topRight,
    Offset(rect.right, rect.center.dy),
    rect.bottomRight,
    Offset(rect.center.dx, rect.bottom),
    rect.bottomLeft,
    Offset(rect.left, rect.center.dy),
  ];
}

List<(Offset, Offset)> _shapeSideSegments(String shape, Size size) {
  if (shape == 'circle') return const <(Offset, Offset)>[];
  final points = _shapeCandidatePoints(shape, size);
  if (shape == 'triangle') {
    return <(Offset, Offset)>[
      (points[0], points[2]),
      (points[2], points[4]),
      (points[4], points[0]),
    ];
  }
  return <(Offset, Offset)>[
    (points[0], points[2]),
    (points[2], points[4]),
    (points[4], points[6]),
    (points[6], points[0]),
  ];
}

class _TouchShapeSidesPainter extends CustomPainter {
  const _TouchShapeSidesPainter({
    required this.shape,
    required this.selectedSides,
    required this.color,
    required this.accent,
  });

  final String shape;
  final Set<int> selectedSides;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;
    if (shape == 'circle') {
      canvas.drawOval(
        Rect.fromLTWH(32, 28, size.width - 64, size.height - 56),
        base,
      );
      return;
    }
    final segments = _shapeSideSegments(shape, size);
    for (final segment in segments) {
      canvas.drawLine(segment.$1, segment.$2, base);
    }
    final selected = Paint()
      ..color = accent
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (final index in selectedSides) {
      if (index >= 0 && index < segments.length) {
        canvas.drawLine(segments[index].$1, segments[index].$2, selected);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TouchShapeSidesPainter oldDelegate) =>
      shape != oldDelegate.shape ||
      !setEquals(selectedSides, oldDelegate.selectedSides) ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
}

class _TouchShapeCornersPainter extends CustomPainter {
  const _TouchShapeCornersPainter({
    required this.shape,
    required this.selectedPoints,
    required this.color,
    required this.accent,
  });

  final String shape;
  final Set<int> selectedPoints;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;
    final points = _shapeCandidatePoints(shape, size);
    if (shape == 'circle') {
      canvas.drawOval(
        Rect.fromLTWH(32, 28, size.width - 64, size.height - 56),
        paint,
      );
    } else if (shape == 'triangle') {
      final path = Path()
        ..moveTo(points[0].dx, points[0].dy)
        ..lineTo(points[2].dx, points[2].dy)
        ..lineTo(points[4].dx, points[4].dy)
        ..close();
      canvas.drawPath(path, paint);
    } else {
      canvas.drawRect(Rect.fromPoints(points[0], points[4]), paint);
    }
    for (final index in selectedPoints) {
      if (index >= 0 && index < points.length) {
        canvas.drawCircle(
          points[index],
          11,
          Paint()..color = accent.withValues(alpha: 0.22),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TouchShapeCornersPainter oldDelegate) =>
      shape != oldDelegate.shape ||
      !setEquals(selectedPoints, oldDelegate.selectedPoints) ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
}

class _TouchAreaPainter extends CustomPainter {
  const _TouchAreaPainter({
    required this.columns,
    required this.rows,
    required this.color,
    required this.accent,
  });

  final int columns;
  final int rows;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 18.0;
    final availableWidth = size.width - padding * 2;
    final availableHeight = size.height - padding * 2;
    final ratio = columns / math.max(1, rows);
    final canvasRatio = availableWidth / availableHeight;
    late double width;
    late double height;
    if (ratio >= canvasRatio) {
      width = availableWidth;
      height = math.max(42, width / ratio);
    } else {
      height = availableHeight;
      width = math.max(42, height * ratio);
    }
    width = math.min(width, availableWidth);
    height = math.min(height, availableHeight);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: width,
      height: height,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = accent.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final grid = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    if (columns <= 12 && rows <= 12) {
      for (var column = 1; column < columns; column++) {
        final x = rect.left + rect.width * column / columns;
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
      }
      for (var row = 1; row < rows; row++) {
        final y = rect.top + rect.height * row / rows;
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
      }
    } else {
      for (var marker = 1; marker < 4; marker++) {
        final x = rect.left + rect.width * marker / 4;
        final y = rect.top + rect.height * marker / 4;
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TouchAreaPainter oldDelegate) =>
      columns != oldDelegate.columns ||
      rows != oldDelegate.rows ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
}

class _TouchPerimeterPainter extends CustomPainter {
  const _TouchPerimeterPainter({
    required this.selectedEdges,
    required this.color,
    required this.accent,
  });

  final Set<int> selectedEdges;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(34, 34, size.width - 68, size.height - 68);
    final base = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(rect, base);
    final selected = Paint()
      ..color = accent
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    if (selectedEdges.contains(0)) {
      canvas.drawLine(rect.topLeft, rect.topRight, selected);
    }
    if (selectedEdges.contains(1)) {
      canvas.drawLine(rect.topRight, rect.bottomRight, selected);
    }
    if (selectedEdges.contains(2)) {
      canvas.drawLine(rect.bottomLeft, rect.bottomRight, selected);
    }
    if (selectedEdges.contains(3)) {
      canvas.drawLine(rect.topLeft, rect.bottomLeft, selected);
    }
  }

  @override
  bool shouldRepaint(covariant _TouchPerimeterPainter oldDelegate) =>
      !setEquals(selectedEdges, oldDelegate.selectedEdges) ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
}

class _PlaceManipulativeSource extends StatelessWidget {
  const _PlaceManipulativeSource({
    required this.sourceKey,
    required this.value,
    required this.label,
    required this.locked,
    required this.onTap,
  });

  final Key sourceKey;
  final int value;
  final String label;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: !locked,
    label: '$label. Antippen oder in das passende Feld ziehen.',
    onTap: locked ? null : onTap,
    child: GestureDetector(
      key: sourceKey,
      onTap: locked ? null : onTap,
      child: Draggable<int>(
        data: value,
        maxSimultaneousDrags: locked ? 0 : 1,
        feedback: Material(
          color: Colors.transparent,
          child: _BaseTenPiece(value: value, label: label),
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: _BaseTenPiece(value: value, label: label),
        ),
        child: _BaseTenPiece(value: value, label: label),
      ),
    ),
  );
}

class _BaseTenPiece extends StatelessWidget {
  const _BaseTenPiece({required this.value, this.label});

  final int value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    final outline = Theme.of(context).colorScheme.primary;
    final piece = value == 10
        ? SizedBox(
            width: 112,
            height: 30,
            child: Row(
              children: List.generate(
                10,
                (_) => Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: outline, width: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          )
        : Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: outline),
            ),
          );
    if (label == null) return piece;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        piece,
        const SizedBox(height: 3),
        Text(label!, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _PlaceCounter extends StatelessWidget {
  const _PlaceCounter({
    required this.dropKey,
    required this.label,
    required this.value,
    required this.acceptedValue,
    required this.addKey,
    required this.removeKey,
    required this.onAccept,
    required this.onAdd,
    required this.onRemove,
  });

  final Key dropKey;
  final String label;
  final int value;
  final int acceptedValue;
  final Key addKey;
  final Key removeKey;
  final VoidCallback? onAccept;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => DragTarget<int>(
    key: dropKey,
    onWillAcceptWithDetails: (details) =>
        details.data == acceptedValue && onAccept != null,
    onAcceptWithDetails: (_) => onAccept?.call(),
    builder: (context, candidates, rejected) => Semantics(
      label: '$label: $value',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 142,
        padding: const EdgeInsets.all(10),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('$value', style: Theme.of(context).textTheme.headlineMedium),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 30),
              child: value == 0
                  ? Text(
                      'Hier ablegen',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 3,
                      runSpacing: 3,
                      children: List.generate(
                        value,
                        (_) => Container(
                          width: acceptedValue == 10 ? 32 : 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
            ),
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
    ),
  );
}

class _MoneyDragData {
  const _MoneyDragData(this.value, {this.placedIndex});

  final int value;
  final int? placedIndex;
  bool get isPlaced => placedIndex != null;
}

class _MoneySourcePiece extends StatelessWidget {
  const _MoneySourcePiece({
    required this.sourceKey,
    required this.value,
    required this.unit,
    required this.locked,
    required this.onTap,
  });

  final Key sourceKey;
  final int value;
  final String unit;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: !locked,
    label: '$value $unit. Antippen oder in das Geldfeld ziehen.',
    onTap: locked ? null : onTap,
    child: GestureDetector(
      key: sourceKey,
      onTap: locked ? null : onTap,
      child: Draggable<_MoneyDragData>(
        data: _MoneyDragData(value),
        maxSimultaneousDrags: locked ? 0 : 1,
        feedback: Material(
          color: Colors.transparent,
          child: _MoneyPieceVisual(value: value, unit: unit),
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: _MoneyPieceVisual(value: value, unit: unit),
        ),
        child: _MoneyPieceVisual(value: value, unit: unit),
      ),
    ),
  );
}

class _PlacedMoneyPiece extends StatelessWidget {
  const _PlacedMoneyPiece({
    required this.pieceKey,
    required this.value,
    required this.unit,
    required this.index,
    required this.locked,
    required this.onDelete,
  });

  final Key pieceKey;
  final int value;
  final String unit;
  final int index;
  final bool locked;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Draggable<_MoneyDragData>(
    key: pieceKey,
    data: _MoneyDragData(value, placedIndex: index),
    maxSimultaneousDrags: locked ? 0 : 1,
    feedback: Material(
      color: Colors.transparent,
      child: _MoneyPieceVisual(value: value, unit: unit),
    ),
    childWhenDragging: Opacity(
      opacity: 0.3,
      child: InputChip(label: Text('$value $unit')),
    ),
    child: InputChip(
      label: Text('$value $unit'),
      onDeleted: locked ? null : onDelete,
    ),
  );
}

class _MoneyPieceVisual extends StatelessWidget {
  const _MoneyPieceVisual({required this.value, required this.unit});

  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final isCoin = unit == '€' && value <= 2;
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '$value $unit',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
    return Container(
      width: isCoin ? 54 : 76,
      height: 48,
      padding: const EdgeInsets.all(7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        shape: isCoin ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCoin ? null : BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: child,
    );
  }
}


class _RepresentationSourceCard extends StatelessWidget {
  const _RepresentationSourceCard();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.drag_indicator_rounded),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Situation greifen und zur passenden Darstellung ziehen',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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
    required this.minuteHandActive,
  });

  final int hour;
  final int minute;
  final Color color;
  final Color accent;
  final bool minuteHandActive;

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
      ..color = minuteHandActive ? accent : color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final hourPaint = Paint()
      ..color = minuteHandActive ? color : accent
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final hourEnd = Offset(
      center.dx + math.cos(hourAngle) * radius * 0.52,
      center.dy + math.sin(hourAngle) * radius * 0.52,
    );
    final minuteEnd = Offset(
      center.dx + math.cos(minuteAngle) * radius * 0.76,
      center.dy + math.sin(minuteAngle) * radius * 0.76,
    );
    canvas.drawLine(center, hourEnd, hourPaint);
    canvas.drawLine(center, minuteEnd, minutePaint);
    final handlePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(minuteHandActive ? minuteEnd : hourEnd, 9, handlePaint);
    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TouchClockPainter oldDelegate) =>
      hour != oldDelegate.hour ||
      minute != oldDelegate.minute ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent ||
      minuteHandActive != oldDelegate.minuteHandActive;
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
