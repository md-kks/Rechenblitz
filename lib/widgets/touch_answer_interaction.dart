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
  int scaleBuiltSegments = 0;
  int? selectedConversionChoice;
  int durationCurrent = 0;
  int durationElapsed = 0;
  int calendarDay = 1;
  int calendarSteps = 0;
  int? selectedGeometryCandidate;
  int? selectedCubeNetChoice;
  int? selectedLargePlace;
  int? selectedLargeRelation;
  int? selectedLargeDigitPlace;
  final List<int> selectedLargeOrder = <int>[];
  final List<int> largePlaceDigits = <int>[];
  final List<int?> numberWordDigits = <int?>[];
  final Set<int> numberWordLockedPlaces = <int>{};
  int numberWordActiveIndex = 0;
  final List<int> mentalSelectedChunks = <int>[];
  int? selectedStrategyJump;
  final Set<int> selectedLawTerms = <int>{};
  final List<int> selectedLawOrder = <int>[];
  int? selectedLawGap;
  int romanReadIndex = 0;
  int? selectedRomanBlockValue;
  String romanReadFeedback = '';
  final List<String> romanBuiltSymbols = <String>[];
  int? selectedInverseOperation;
  int numberBondMissing = 0;
  int writtenColumnIndex = 0;
  int writtenIncomingCarry = 0;
  int? selectedWrittenDigit;
  int? selectedWrittenRegroup;
  final List<int> writtenResultDigits = <int>[];
  final List<int> writtenWorkingTopDigits = <int>[];
  String writtenStepFeedback = '';
  int multiplicationRowIndex = 0;
  int multiplicationColumnIndex = 0;
  int multiplicationIncomingCarry = 0;
  int? selectedMultiplicationDigit;
  int? selectedMultiplicationCarry;
  final List<int> multiplicationCurrentDigits = <int>[];
  final List<int> multiplicationPartialProducts = <int>[];
  String multiplicationStepFeedback = '';
  bool multiplicationAwaitingTotal = false;
  int divisionStepIndex = 0;
  int? selectedDivisionQuotient;
  int? selectedDivisionRemainder;
  final List<int> divisionQuotientDigits = <int>[];
  String divisionStepFeedback = '';
  final List<String> routeMoves = <String>[];
  int pathX = 0;
  int pathY = 0;
  final Set<int> selectedAxes = <int>{};
  final Set<int> selectedShapePoints = <int>{};
  final Set<int> selectedShapeSides = <int>{};
  final Set<int> selectedBodyFeatures = <int>{};
  bool bodyNoFeatureClaim = false;
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
    scaleBuiltSegments = 0;
    selectedConversionChoice = null;
    durationCurrent = widget.plan.kind == TouchInteractionKind.durationTimeline && widget.plan.dataValues.isNotEmpty
        ? widget.plan.dataValues.first
        : 0;
    durationElapsed = 0;
    calendarDay = widget.plan.kind == TouchInteractionKind.calendarStepper && widget.plan.dataValues.isNotEmpty
        ? widget.plan.dataValues.first
        : 1;
    calendarSteps = 0;
    selectedGeometryCandidate = null;
    selectedCubeNetChoice = null;
    selectedLargePlace = null;
    selectedLargeRelation = null;
    selectedLargeDigitPlace = null;
    selectedLargeOrder.clear();
    largePlaceDigits.clear();
    numberWordDigits.clear();
    numberWordLockedPlaces.clear();
    numberWordActiveIndex = 0;
    if (widget.plan.kind == TouchInteractionKind.numberWordPlaceValueBuilder &&
        widget.plan.dataValues.isNotEmpty) {
      final number = widget.plan.dataValues.first;
      final places = _largePlaces(number);
      numberWordDigits.addAll(List<int?>.filled(places.length, null));
      if (widget.plan.dataOperation == 'read:skip-tens-ones') {
        for (var index = 0; index < places.length; index++) {
          if (places[index] == 10 || places[index] == 1) {
            numberWordDigits[index] = (number ~/ places[index]) % 10;
            numberWordLockedPlaces.add(index);
          }
        }
        final firstOpen = List<int>.generate(places.length, (index) => index)
            .where((index) => !numberWordLockedPlaces.contains(index))
            .toList(growable: false);
        if (firstOpen.isNotEmpty) numberWordActiveIndex = firstOpen.first;
      }
    }
    mentalSelectedChunks.clear();
    selectedStrategyJump = null;
    selectedLawTerms.clear();
    selectedLawOrder.clear();
    selectedLawGap = null;
    romanReadIndex = 0;
    selectedRomanBlockValue = null;
    romanReadFeedback = '';
    romanBuiltSymbols.clear();
    selectedInverseOperation = null;
    if (widget.plan.kind == TouchInteractionKind.largeNumberDecompose &&
        widget.plan.dataValues.isNotEmpty) {
      largePlaceDigits.addAll(
        List<int>.filled(_largePlaces(widget.plan.dataValues.first).length, 0),
      );
    }
    writtenColumnIndex = 0;
    writtenIncomingCarry = 0;
    selectedWrittenDigit = null;
    selectedWrittenRegroup = null;
    writtenResultDigits.clear();
    writtenWorkingTopDigits.clear();
    writtenStepFeedback = '';
    multiplicationRowIndex = 0;
    multiplicationColumnIndex = 0;
    multiplicationIncomingCarry = 0;
    selectedMultiplicationDigit = null;
    selectedMultiplicationCarry = null;
    multiplicationCurrentDigits.clear();
    multiplicationPartialProducts.clear();
    multiplicationStepFeedback = '';
    multiplicationAwaitingTotal = false;
    divisionStepIndex = 0;
    selectedDivisionQuotient = null;
    selectedDivisionRemainder = null;
    divisionQuotientDigits.clear();
    divisionStepFeedback = '';
    routeMoves.clear();
    if (widget.plan.kind == TouchInteractionKind.routeSequenceWalker &&
        widget.plan.dataOperation == 'skip-first' &&
        widget.plan.dataLabels.length >= 2 &&
        widget.plan.dataValues.length >= 2) {
      routeMoves.addAll(
        List<String>.filled(
          widget.plan.dataValues[0],
          widget.plan.dataLabels[0],
        ),
      );
    }
    if (widget.plan.kind == TouchInteractionKind.writtenColumnProcedure &&
        widget.plan.dataValues.length >= 2 &&
        widget.plan.dataOperation == '-') {
      writtenWorkingTopDigits.addAll(
        _digitsLeastSignificantFirst(widget.plan.dataValues[0]),
      );
      final needed = _writtenColumnCount();
      while (writtenWorkingTopDigits.length < needed) {
        writtenWorkingTopDigits.add(0);
      }
    }
    pathX = 0;
    pathY = 0;
    selectedAxes.clear();
    selectedShapePoints.clear();
    selectedShapeSides.clear();
    selectedBodyFeatures.clear();
    bodyNoFeatureClaim = false;
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
            TouchInteractionKind.scaleDistanceBuilder =>
              _buildScaleDistanceBuilder(context),
            TouchInteractionKind.lengthRulerOperation =>
              _buildLengthRulerOperation(context),
            TouchInteractionKind.unitConversionMachine =>
              _buildUnitConversionMachine(context),
            TouchInteractionKind.durationTimeline =>
              _buildDurationTimeline(context),
            TouchInteractionKind.calendarStepper =>
              _buildCalendarStepper(context),
            TouchInteractionKind.geometryRelationChoice =>
              _buildGeometryRelationChoice(context),
            TouchInteractionKind.cubeNetFoldChoice =>
              _buildCubeNetFoldChoice(context),
            TouchInteractionKind.bodyPropertySelector =>
              _buildBodyPropertySelector(context),
            TouchInteractionKind.largeNumberCompare =>
              _buildLargeNumberCompare(context),
            TouchInteractionKind.largeNumberOrder =>
              _buildLargeNumberOrder(context),
            TouchInteractionKind.largeNumberDecompose =>
              _buildLargeNumberDecompose(context),
            TouchInteractionKind.largeNumberPlaceDigit =>
              _buildLargeNumberPlaceDigit(context),
            TouchInteractionKind.numberWordPlaceValueBuilder =>
              _buildNumberWordPlaceValueBuilder(context),
            TouchInteractionKind.mentalChunkPath =>
              _buildMentalChunkPath(context),
            TouchInteractionKind.strategyAnchorJump =>
              _buildStrategyAnchorJump(context),
            TouchInteractionKind.arithmeticLawStructure =>
              _buildArithmeticLawStructure(context),
            TouchInteractionKind.romanNumeralReader =>
              _buildRomanNumeralReader(context),
            TouchInteractionKind.romanNumeralBuilder =>
              _buildRomanNumeralBuilder(context),
            TouchInteractionKind.inverseFamilyMachine =>
              _buildInverseFamilyMachine(context),
            TouchInteractionKind.numberBondComposer =>
              _buildNumberBondComposer(context),
            TouchInteractionKind.writtenColumnProcedure =>
              _buildWrittenColumnProcedure(context),
            TouchInteractionKind.writtenMultiplicationProcedure =>
              _buildWrittenMultiplicationProcedure(context),
            TouchInteractionKind.writtenDivisionProcedure =>
              _buildWrittenDivisionProcedure(context),
            TouchInteractionKind.routeSequenceWalker =>
              _buildRouteSequenceWalker(context),
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

  Widget _buildInverseFamilyMachine(BuildContext context) {
    final values = widget.plan.dataValues;
    if (values.length < 3) return const SizedBox.shrink();
    final start = values[0];
    final operand = values[1];
    final result = values[2];
    final multiply = widget.plan.dataOperation?.startsWith('multiply') ?? false;
    final skipOperation =
        widget.plan.dataOperation?.endsWith(':skip-operation') ?? false;
    final sourceOperation = multiply ? '×$operand' : '+$operand';
    final inverseOperation = multiply ? '÷$operand' : '−$operand';
    final options = multiply
        ? <String>['×$operand', '÷$operand']
        : <String>['+$operand', '−$operand'];
    final operationReady = skipOperation || selectedInverseOperation != null;
    final operationCorrect = skipOperation || selectedInverseOperation == 1;
    final expected = widget.plan.expectedAnswer ?? start;

    Widget valueChip(String label, {Key? key}) => Container(
          key: key,
          constraints: const BoxConstraints(minWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Vorwärts',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          key: const ValueKey('touch-family-forward'),
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            valueChip('$start'),
            const Icon(Icons.arrow_forward_rounded),
            Chip(label: Text(sourceOperation)),
            const Icon(Icons.arrow_forward_rounded),
            valueChip('$result'),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Rückwärts',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          key: const ValueKey('touch-family-backward'),
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            valueChip('$result'),
            const Icon(Icons.arrow_forward_rounded),
            if (skipOperation)
              Chip(
                key: const ValueKey('touch-family-operation-checked'),
                avatar: const Icon(Icons.check_rounded, size: 18),
                label: Text(inverseOperation),
              )
            else
              for (var index = 0; index < options.length; index++)
                ChoiceChip(
                  key: ValueKey('touch-family-operation-$index'),
                  selected: selectedInverseOperation == index,
                  label: Text(options[index]),
                  onSelected: widget.locked
                      ? null
                      : (_) => setState(() => selectedInverseOperation = index),
                ),
            const Icon(Icons.arrow_forward_rounded),
            valueChip('?', key: const ValueKey('touch-family-target')),
          ],
        ),
        if (!skipOperation) ...[
          const SizedBox(height: 8),
          Text(
            selectedInverseOperation == null
                ? 'Welche Operation macht $sourceOperation wieder rückgängig?'
                : 'Gewählt: ${options[selectedInverseOperation!]}',
            key: const ValueKey('touch-family-operation-status'),
            textAlign: TextAlign.center,
          ),
        ],
        if (operationReady) ...[
          const SizedBox(height: 12),
          const Text(
            'Welche Zahl muss am Ende wieder herauskommen?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          NumberAnswerPad(
            key: const ValueKey('touch-family-result-pad'),
            maxValue: math.max(1, widget.plan.maxValue),
            onAnswer: widget.locked
                ? (_) {}
                : (value) => widget.onAnswer(
                      operationCorrect
                          ? value
                          : _wrongAnswer(value, expected),
                    ),
          ),
        ],
      ],
    );
  }

  Widget _buildNumberBondComposer(BuildContext context) {
    final values = widget.plan.dataValues;
    if (values.length < 2) return const SizedBox.shrink();
    final target = values[0];
    final known = values[1];
    final expected = widget.plan.expectedAnswer ?? math.max(0, target - known);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Zielzahl: $target',
          key: const ValueKey('touch-number-bond-target'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          key: const ValueKey('touch-number-bond-groups'),
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _StaticCounterGroup(label: 'Bekannter Teil', count: known),
            const Icon(Icons.add_rounded),
            _CounterGroupCard(
              key: const ValueKey('touch-number-bond-missing'),
              label: 'Fehlender Teil',
              count: numberBondMissing,
              onAdd: widget.locked || numberBondMissing >= target
                  ? null
                  : () => setState(() => numberBondMissing += 1),
              onRemove: widget.locked || numberBondMissing == 0
                  ? null
                  : () => setState(() => numberBondMissing -= 1),
              addKey: const ValueKey('touch-number-bond-add'),
              removeKey: const ValueKey('touch-number-bond-remove'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$known + $numberBondMissing sollen zusammen $target ergeben.',
          key: const ValueKey('touch-number-bond-equation'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-number-bond-submit'),
          onPressed: widget.locked
              ? null
              : () => widget.onAnswer(
                    numberBondMissing == expected
                        ? expected
                        : _wrongAnswer(numberBondMissing, expected),
                  ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Zerlegung prüfen'),
        ),
      ],
    );
  }

  Widget _buildRomanNumeralReader(BuildContext context) {
    final labels = widget.plan.dataLabels;
    final values = widget.plan.dataValues;
    final skipBlocks = widget.plan.dataOperation == 'read-total';
    final blocksComplete = skipBlocks || romanReadIndex >= values.length;
    final currentValue = blocksComplete ? null : values[romanReadIndex];
    final currentLabel = blocksComplete ? null : labels[romanReadIndex];
    final roman = widget.plan.unitLabel ?? labels.join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('touch-roman-read-display'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            roman,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
          ),
        ),
        const SizedBox(height: 12),
        if (!skipBlocks) ...[
          Wrap(
            key: const ValueKey('touch-roman-read-blocks'),
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < labels.length; i++)
                Chip(
                  avatar: i < romanReadIndex
                      ? const Icon(Icons.check_rounded, size: 18)
                      : null,
                  label: Text(labels[i]),
                  side: i == romanReadIndex
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 10),
        ] else ...[
          const Text(
            'Der Zehnerblock wurde im Zwischenschritt schon geprüft.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
        ],
        if (!blocksComplete && currentValue != null && currentLabel != null) ...[
          Text(
            'Welchen Wert hat der Block $currentLabel?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final candidate in _romanValueCandidates(currentValue))
                ChoiceChip(
                  key: ValueKey('touch-roman-read-value-$candidate'),
                  selected: selectedRomanBlockValue == candidate,
                  label: Text('$candidate'),
                  onSelected: widget.locked
                      ? null
                      : (_) => setState(() {
                            selectedRomanBlockValue = candidate;
                            romanReadFeedback = '';
                          }),
                ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton(
            key: const ValueKey('touch-roman-read-step-submit'),
            onPressed: widget.locked || selectedRomanBlockValue == null
                ? null
                : () {
                    if (selectedRomanBlockValue == currentValue) {
                      setState(() {
                        romanReadIndex += 1;
                        selectedRomanBlockValue = null;
                        romanReadFeedback = '';
                      });
                    } else {
                      setState(() {
                        romanReadFeedback = 'Dieser Blockwert passt noch nicht.';
                      });
                    }
                  },
            child: const Text('Block prüfen'),
          ),
          if (romanReadFeedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              romanReadFeedback,
              key: const ValueKey('touch-roman-read-feedback'),
              textAlign: TextAlign.center,
            ),
          ],
        ] else ...[
          Text(
            'Wie viel ist $roman insgesamt?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          NumberAnswerPad(
            key: const ValueKey('touch-roman-read-total-pad'),
            maxValue: math.max(1, widget.plan.maxValue),
            onAnswer: widget.locked ? (_) {} : widget.onAnswer,
          ),
        ],
      ],
    );
  }

  List<int> _romanValueCandidates(int correct) {
    const universe = <int>[1, 4, 5, 9, 10, 40, 50, 90, 100];
    final result = <int>{correct};
    final index = universe.indexOf(correct);
    if (index >= 0) {
      for (var distance = 1; result.length < 4; distance++) {
        final left = index - distance;
        final right = index + distance;
        if (left >= 0) result.add(universe[left]);
        if (right < universe.length) result.add(universe[right]);
        if (left < 0 && right >= universe.length) break;
      }
    }
    for (final value in universe) {
      if (result.length >= 4) break;
      result.add(value);
    }
    final out = result.take(4).toList()..sort();
    return out;
  }

  Widget _buildRomanNumeralBuilder(BuildContext context) {
    final target = widget.plan.dataValues.isEmpty ? 0 : widget.plan.dataValues.first;
    final expectedRoman = widget.plan.dataLabels.join();
    final built = romanBuiltSymbols.join();
    final expectedAnswer = widget.plan.expectedAnswer ?? 0;
    const symbols = <String>['I', 'V', 'X', 'L', 'C'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$target',
          key: const ValueKey('touch-roman-build-target'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Container(
          key: const ValueKey('touch-roman-build-display'),
          constraints: const BoxConstraints(minHeight: 58),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            built.isEmpty ? '…' : built,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          key: const ValueKey('touch-roman-symbols'),
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final symbol in symbols)
              ActionChip(
                key: ValueKey('touch-roman-symbol-$symbol'),
                label: Text(symbol),
                onPressed: widget.locked || romanBuiltSymbols.length >= 10
                    ? null
                    : () => setState(() => romanBuiltSymbols.add(symbol)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            TextButton.icon(
              key: const ValueKey('touch-roman-backspace'),
              onPressed: widget.locked || romanBuiltSymbols.isEmpty
                  ? null
                  : () => setState(() => romanBuiltSymbols.removeLast()),
              icon: const Icon(Icons.backspace_outlined),
              label: const Text('Letztes Zeichen'),
            ),
            TextButton.icon(
              key: const ValueKey('touch-roman-reset'),
              onPressed: widget.locked || romanBuiltSymbols.isEmpty
                  ? null
                  : () => setState(romanBuiltSymbols.clear),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Neu'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey('touch-roman-build-submit'),
          onPressed: widget.locked || romanBuiltSymbols.isEmpty
              ? null
              : () {
                  final correct = built == expectedRoman;
                  final alternatives = widget.plan.answerChoices.length;
                  final wrong = alternatives > 1
                      ? (expectedAnswer + 1) % alternatives
                      : expectedAnswer == 0
                          ? 1
                          : 0;
                  widget.onAnswer(correct ? expectedAnswer : wrong);
                },
          child: const Text('Römische Zahl prüfen'),
        ),
      ],
    );
  }

  Widget _buildMentalChunkPath(BuildContext context) {
    final values = widget.plan.dataValues;
    final start = values[0];
    final wholeOperand = values[1];
    final chunks = values.sublist(2);
    final rawOperation = widget.plan.dataOperation ?? '+';
    final operation = rawOperation.startsWith('-') ? '−' : '+';
    final skipFirst = rawOperation.endsWith(':skip-first');
    final requiredChunks = skipFirst && chunks.isNotEmpty
        ? chunks.sublist(1)
        : chunks;
    final options = <int>{...requiredChunks, wholeOperand};
    if (chunks.isNotEmpty) {
      options.add(chunks.first);
      final smaller = chunks.first ~/ 10;
      if (smaller > 0) options.add(smaller);
    }
    final optionList = options.where((value) => value > 0).toList()
      ..sort();
    final expected = widget.plan.expectedAnswer ?? 0;
    final complete = mentalSelectedChunks.length == requiredChunks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          key: const ValueKey('touch-mental-path'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('$start')),
                if (skipFirst && chunks.isNotEmpty) ...[
                  Text(operation),
                  Chip(
                    avatar: const Icon(Icons.check_rounded, size: 18),
                    label: Text('${chunks.first}'),
                  ),
                ],
                for (final chunk in mentalSelectedChunks) ...[
                  Text(operation),
                  Chip(label: Text('$chunk')),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          skipFirst
              ? 'Der erste Stellenwertblock wurde schon geprüft. Ordne jetzt die restlichen Blöcke.'
              : 'Tippe die Stellenwertblöcke vom größten zum kleinsten an.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const ValueKey('touch-mental-chunks'),
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in optionList)
              ActionChip(
                key: ValueKey('touch-mental-chunk-$value'),
                avatar: mentalSelectedChunks.contains(value)
                    ? CircleAvatar(
                        child: Text('${mentalSelectedChunks.indexOf(value) + 1}'),
                      )
                    : null,
                label: Text('$value'),
                onPressed: widget.locked ||
                        mentalSelectedChunks.contains(value) ||
                        complete
                    ? null
                    : () => setState(() => mentalSelectedChunks.add(value)),
              ),
          ],
        ),
        TextButton.icon(
          key: const ValueKey('touch-mental-reset'),
          onPressed: widget.locked || mentalSelectedChunks.isEmpty
              ? null
              : () => setState(mentalSelectedChunks.clear),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Blöcke neu ordnen'),
        ),
        if (complete) ...[
          const SizedBox(height: 8),
          Text(
            'Rechne den aufgebauten Weg jetzt selbst zu Ende.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          NumberAnswerPad(
            key: const ValueKey('touch-mental-result-pad'),
            maxValue: math.max(1, widget.plan.maxValue),
            onAnswer: widget.locked
                ? (_) {}
                : (value) {
                    final structureCorrect =
                        _listEqualsInt(mentalSelectedChunks, requiredChunks);
                    widget.onAnswer(
                      structureCorrect
                          ? value
                          : _wrongAnswer(value, expected),
                    );
                  },
          ),
        ],
      ],
    );
  }

  Widget _buildStrategyAnchorJump(BuildContext context) {
    final values = widget.plan.dataValues;
    final start = values[0];
    final second = values[1];
    final anchor = values[2];
    final gap = values[3];
    final expected = widget.plan.expectedAnswer ?? 0;
    final options = <int>{gap, second};
    if (gap > 1) options.add(gap - 1);
    if (gap + 1 <= second) options.add(gap + 1);
    if (gap > 2) options.add(math.max(1, gap ~/ 2));
    final candidates = options.where((value) => value > 0 && value <= second).toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          key: const ValueKey('touch-strategy-anchor'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Chip(label: Text('$start')),
                const Expanded(child: Divider(thickness: 2)),
                const Icon(Icons.arrow_forward_rounded),
                const Expanded(child: Divider(thickness: 2)),
                Chip(label: Text('$anchor')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Wie groß soll der erste Sprung sein?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final candidate in candidates)
              ChoiceChip(
                key: ValueKey('touch-strategy-jump-$candidate'),
                selected: selectedStrategyJump == candidate,
                label: Text('+$candidate'),
                onSelected: widget.locked
                    ? null
                    : (_) => setState(() => selectedStrategyJump = candidate),
              ),
          ],
        ),
        if (selectedStrategyJump != null) ...[
          const SizedBox(height: 8),
          Text(
            '$start + ${selectedStrategyJump!} = ${start + selectedStrategyJump!}; '
            'vom zweiten Summanden bleiben ${second - selectedStrategyJump!}.',
            key: const ValueKey('touch-strategy-status'),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 10),
        FilledButton(
          key: const ValueKey('touch-strategy-submit'),
          onPressed: widget.locked || selectedStrategyJump == null
              ? null
              : () => widget.onAnswer(
                    selectedStrategyJump == gap
                        ? expected
                        : _wrongAnswer(expected, expected),
                  ),
          child: const Text('Rechenweg prüfen'),
        ),
      ],
    );
  }

  Widget _buildArithmeticLawStructure(BuildContext context) {
    return switch (widget.plan.dataOperation) {
      'associate' => _buildAssociativeLaw(context),
      'commute' => _buildCommutativeLaw(context),
      'distribute' => _buildDistributiveLaw(context),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildAssociativeLaw(BuildContext context) {
    final values = widget.plan.dataValues;
    final expected = widget.plan.expectedAnswer ?? 0;
    final correct = widget.plan.correctSelectionIndexes.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          key: const ValueKey('touch-law-associate-terms'),
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(values.length, (index) {
            final selected = selectedLawTerms.contains(index);
            return ChoiceChip(
              key: ValueKey('touch-law-term-$index'),
              selected: selected,
              label: Text('${values[index]}'),
              onSelected: widget.locked
                  ? null
                  : (_) => setState(() {
                        if (selected) {
                          selectedLawTerms.remove(index);
                        } else if (selectedLawTerms.length < 2) {
                          selectedLawTerms.add(index);
                        }
                      }),
            );
          }),
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const ValueKey('touch-law-associate-submit'),
          onPressed: widget.locked || selectedLawTerms.length != 2
              ? null
              : () => widget.onAnswer(
                    setEquals(selectedLawTerms, correct)
                        ? expected
                        : _wrongAnswer(expected, expected),
                  ),
          child: const Text('Paar prüfen'),
        ),
      ],
    );
  }

  Widget _buildCommutativeLaw(BuildContext context) {
    final values = widget.plan.dataValues;
    final expected = widget.plan.expectedAnswer ?? 0;
    final correct = widget.plan.correctSelectionIndexes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          key: const ValueKey('touch-law-commute-factors'),
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(values.length, (index) {
            final position = selectedLawOrder.indexOf(index);
            return ActionChip(
              key: ValueKey('touch-law-factor-$index'),
              avatar: position >= 0
                  ? CircleAvatar(child: Text('${position + 1}'))
                  : null,
              label: Text('${values[index]}'),
              onPressed: widget.locked || position >= 0
                  ? null
                  : () => setState(() => selectedLawOrder.add(index)),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          selectedLawOrder.isEmpty
              ? 'Baue die vertauschte Reihenfolge.'
              : selectedLawOrder.map((index) => values[index]).join(' × '),
          key: const ValueKey('touch-law-commute-status'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        TextButton.icon(
          key: const ValueKey('touch-law-commute-reset'),
          onPressed: widget.locked || selectedLawOrder.isEmpty
              ? null
              : () => setState(selectedLawOrder.clear),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Neu anordnen'),
        ),
        FilledButton(
          key: const ValueKey('touch-law-commute-submit'),
          onPressed: widget.locked || selectedLawOrder.length != values.length
              ? null
              : () => widget.onAnswer(
                    _listEqualsInt(selectedLawOrder, correct)
                        ? expected
                        : _wrongAnswer(expected, expected),
                  ),
          child: const Text('Reihenfolge prüfen'),
        ),
      ],
    );
  }

  Widget _buildDistributiveLaw(BuildContext context) {
    final values = widget.plan.dataValues;
    final factor = values[0];
    final value = values[1];
    final rounded = values[2];
    final gap = values[3];
    final expected = widget.plan.expectedAnswer ?? 0;
    final options = <int>{gap};
    if (gap > 1) options.add(gap - 1);
    if (gap < 9) options.add(gap + 1);
    options.add(math.max(1, 10 - gap));
    final candidates = options.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          key: const ValueKey('touch-law-distribute-structure'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '$factor × $value = $factor × $rounded − ?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Wie groß ist zuerst der Abstand zur glatten Zahl?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final candidate in candidates)
              ChoiceChip(
                key: ValueKey('touch-law-gap-$candidate'),
                selected: selectedLawGap == candidate,
                label: Text('$candidate'),
                onSelected: widget.locked
                    ? null
                    : (_) => setState(() => selectedLawGap = candidate),
              ),
          ],
        ),
        if (selectedLawGap != null) ...[
          const SizedBox(height: 10),
          Text(
            'Korrektur berechnen: $factor × ${selectedLawGap!}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          NumberAnswerPad(
            key: const ValueKey('touch-law-correction-pad'),
            maxValue: math.max(1, widget.plan.maxValue),
            onAnswer: widget.locked
                ? (_) {}
                : (answer) => widget.onAnswer(
                      selectedLawGap == gap
                          ? answer
                          : _wrongAnswer(answer, expected),
                    ),
          ),
        ],
      ],
    );
  }

  Widget _buildWrittenMultiplicationProcedure(BuildContext context) {
    final a = widget.plan.dataValues[0];
    final b = widget.plan.dataValues[1];
    final multiplierDigits = _digitsLeastSignificantFirst(b);
    final multiplicandDigits = _digitsLeastSignificantFirst(a);
    final row = multiplicationRowIndex.clamp(0, multiplierDigits.length - 1);
    final multiplierDigit = multiplierDigits[row];

    if (multiplicationAwaitingTotal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _writtenMultiplicationSummary(context, a, b),
          const SizedBox(height: 10),
          Text(
            'Addiere die Teilprodukte stellenrichtig.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          NumberAnswerPad(
            key: const ValueKey('touch-written-multiply-total-pad'),
            maxValue: math.max(1, widget.plan.maxValue),
            onAnswer: widget.locked ? (_) {} : widget.onAnswer,
          ),
        ],
      );
    }

    final column = multiplicationColumnIndex.clamp(0, multiplicandDigits.length - 1);
    final multiplicandDigit = multiplicandDigits[column];
    final place = _pow10(column + row);
    final placeLabel = _largePlaceLabel(place);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _writtenMultiplicationSummary(context, a, b),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              '$placeLabel: $multiplicandDigit × $multiplierDigit${multiplicationIncomingCarry > 0 ? ' + Übertrag $multiplicationIncomingCarry' : ''}',
              key: const ValueKey('touch-written-multiply-calculation'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ergebnisziffer',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: List<Widget>.generate(10, (digit) => ChoiceChip(
                key: ValueKey('touch-written-multiply-digit-$digit'),
                selected: selectedMultiplicationDigit == digit,
                label: Text('$digit'),
                onSelected: widget.locked
                    ? null
                    : (_) => setState(() {
                          selectedMultiplicationDigit = digit;
                          multiplicationStepFeedback = '';
                        }),
              )),
        ),
        const SizedBox(height: 10),
        Text(
          'Übertrag in die nächste Spalte',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: List<Widget>.generate(10, (carry) => ChoiceChip(
                key: ValueKey('touch-written-multiply-carry-$carry'),
                selected: selectedMultiplicationCarry == carry,
                label: Text('$carry'),
                onSelected: widget.locked
                    ? null
                    : (_) => setState(() {
                          selectedMultiplicationCarry = carry;
                          multiplicationStepFeedback = '';
                        }),
              )),
        ),
        if (multiplicationStepFeedback.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            multiplicationStepFeedback,
            key: const ValueKey('touch-written-multiply-feedback'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 10),
        FilledButton(
          key: const ValueKey('touch-written-multiply-step-submit'),
          onPressed: widget.locked ||
                  selectedMultiplicationDigit == null ||
                  selectedMultiplicationCarry == null
              ? null
              : _submitWrittenMultiplicationStep,
          child: const Text('Spalte prüfen'),
        ),
      ],
    );
  }

  Widget _writtenMultiplicationSummary(BuildContext context, int a, int b) {
    return Card(
      key: const ValueKey('touch-written-multiply-table'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              '$a × $b',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (multiplicationPartialProducts.isNotEmpty) ...[
              const Divider(),
              for (var index = 0;
                  index < multiplicationPartialProducts.length;
                  index++)
                Text(
                  'Teilprodukt ${index + 1}: ${multiplicationPartialProducts[index]}',
                  key: ValueKey('touch-written-multiply-partial-$index'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _submitWrittenMultiplicationStep() {
    final a = widget.plan.dataValues[0];
    final b = widget.plan.dataValues[1];
    final expected = widget.plan.expectedAnswer ?? a * b;
    final multiplierDigits = _digitsLeastSignificantFirst(b);
    final multiplicandDigits = _digitsLeastSignificantFirst(a);
    final row = multiplicationRowIndex;
    final column = multiplicationColumnIndex;
    final multiplierDigit = multiplierDigits[row];
    final raw = multiplicandDigits[column] * multiplierDigit +
        multiplicationIncomingCarry;
    final expectedDigit = raw % 10;
    final expectedCarry = raw ~/ 10;
    final correct = selectedMultiplicationDigit == expectedDigit &&
        selectedMultiplicationCarry == expectedCarry;

    if (!correct) {
      setState(() {
        multiplicationStepFeedback =
            'Prüfe Ergebnisziffer und Übertrag in dieser Spalte.';
      });
      widget.onAnswer(_wrongAnswer(expected, expected));
      return;
    }

    while (multiplicationCurrentDigits.length <= column) {
      multiplicationCurrentDigits.add(0);
    }
    multiplicationCurrentDigits[column] = expectedDigit;
    final lastColumn = column == multiplicandDigits.length - 1;
    if (!lastColumn) {
      setState(() {
        multiplicationIncomingCarry = expectedCarry;
        multiplicationColumnIndex += 1;
        selectedMultiplicationDigit = null;
        selectedMultiplicationCarry = null;
        multiplicationStepFeedback = '';
      });
      return;
    }

    if (expectedCarry > 0) {
      multiplicationCurrentDigits.add(expectedCarry);
    }
    var unshifted = 0;
    for (var index = 0; index < multiplicationCurrentDigits.length; index++) {
      unshifted += multiplicationCurrentDigits[index] * _pow10(index);
    }
    final partial = unshifted * _pow10(row);
    multiplicationPartialProducts.add(partial);
    final lastRow = row == multiplierDigits.length - 1;
    if (lastRow) {
      if (multiplierDigits.length == 1) {
        widget.onAnswer(multiplicationPartialProducts.fold<int>(0, (a, b) => a + b));
        return;
      }
      setState(() {
        multiplicationAwaitingTotal = true;
        selectedMultiplicationDigit = null;
        selectedMultiplicationCarry = null;
        multiplicationStepFeedback = '';
      });
      return;
    }

    setState(() {
      multiplicationRowIndex += 1;
      multiplicationColumnIndex = 0;
      multiplicationIncomingCarry = 0;
      selectedMultiplicationDigit = null;
      selectedMultiplicationCarry = null;
      multiplicationCurrentDigits.clear();
      multiplicationStepFeedback = '';
    });
  }

  Widget _buildWrittenDivisionProcedure(BuildContext context) {
    final dividend = widget.plan.dataValues[0];
    final divisor = widget.plan.dataValues[1];
    final steps = _writtenDivisionSteps(dividend, divisor);
    final index = divisionStepIndex.clamp(0, steps.length - 1);
    final step = steps[index];
    final quotientText = divisionQuotientDigits.isEmpty
        ? '–'
        : divisionQuotientDigits.join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          key: const ValueKey('touch-written-division-table'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  '$dividend ÷ $divisor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quotient bisher: $quotientText',
                  key: const ValueKey('touch-written-division-quotient'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              '${step.$1} ÷ $divisor',
              key: const ValueKey('touch-written-division-chunk'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Quotientenziffer',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: List<Widget>.generate(10, (digit) => ChoiceChip(
                key: ValueKey('touch-written-division-q-$digit'),
                selected: selectedDivisionQuotient == digit,
                label: Text('$digit'),
                onSelected: widget.locked
                    ? null
                    : (_) => setState(() {
                          selectedDivisionQuotient = digit;
                          divisionStepFeedback = '';
                        }),
              )),
        ),
        const SizedBox(height: 10),
        Text(
          'Rest nach diesem Schritt',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: List<Widget>.generate(divisor, (remainder) => ChoiceChip(
                key: ValueKey('touch-written-division-r-$remainder'),
                selected: selectedDivisionRemainder == remainder,
                label: Text('$remainder'),
                onSelected: widget.locked
                    ? null
                    : (_) => setState(() {
                          selectedDivisionRemainder = remainder;
                          divisionStepFeedback = '';
                        }),
              )),
        ),
        if (divisionStepFeedback.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            divisionStepFeedback,
            key: const ValueKey('touch-written-division-feedback'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 10),
        FilledButton(
          key: const ValueKey('touch-written-division-step-submit'),
          onPressed: widget.locked ||
                  selectedDivisionQuotient == null ||
                  selectedDivisionRemainder == null
              ? null
              : _submitWrittenDivisionStep,
          child: Text(index == steps.length - 1 ? 'Ergebnis prüfen' : 'Schritt prüfen'),
        ),
      ],
    );
  }

  void _submitWrittenDivisionStep() {
    final dividend = widget.plan.dataValues[0];
    final divisor = widget.plan.dataValues[1];
    final expected = widget.plan.expectedAnswer ?? 0;
    final steps = _writtenDivisionSteps(dividend, divisor);
    final step = steps[divisionStepIndex];
    final correct = selectedDivisionQuotient == step.$2 &&
        selectedDivisionRemainder == step.$3;

    if (!correct) {
      setState(() {
        divisionStepFeedback =
            'Prüfe Quotientenziffer und Rest dieses Divisionsschritts.';
      });
      widget.onAnswer(_wrongAnswer(expected, expected));
      return;
    }

    divisionQuotientDigits.add(step.$2);
    final last = divisionStepIndex == steps.length - 1;
    if (last) {
      if (widget.plan.dataOperation == 'rest') {
        widget.onAnswer(expected);
        return;
      }
      var quotient = 0;
      for (final digit in divisionQuotientDigits) {
        quotient = quotient * 10 + digit;
      }
      widget.onAnswer(quotient);
      return;
    }

    setState(() {
      divisionStepIndex += 1;
      selectedDivisionQuotient = null;
      selectedDivisionRemainder = null;
      divisionStepFeedback = '';
    });
  }

  List<(int, int, int, int)> _writtenDivisionSteps(int dividend, int divisor) {
    final digits = '$dividend'.split('').map(int.parse).toList(growable: false);
    final steps = <(int, int, int, int)>[];
    var current = 0;
    var started = false;
    for (var index = 0; index < digits.length; index++) {
      current = current * 10 + digits[index];
      if (!started && current < divisor && index < digits.length - 1) {
        continue;
      }
      started = true;
      final quotient = current ~/ divisor;
      final remainder = current % divisor;
      steps.add((current, quotient, remainder, index));
      current = remainder;
    }
    return steps;
  }

  Widget _buildWrittenColumnProcedure(BuildContext context) {
    final values = widget.plan.dataValues;
    final a = values[0];
    final b = values[1];
    final addition = widget.plan.dataOperation == '+';
    final count = _writtenColumnCount();
    final column = writtenColumnIndex.clamp(0, count - 1);
    final place = _pow10(column);
    final bottomDigit = (b ~/ place) % 10;
    final rawTopDigit = addition
        ? (a ~/ place) % 10
        : writtenWorkingTopDigits[column];
    final previewTopDigit = !addition && selectedWrittenRegroup == 1
        ? rawTopDigit + 10
        : rawTopDigit;
    final regroupLabel = addition ? 'Übertrag' : 'Entbündeln';
    final placeLabel = _largePlaceLabel(place);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            key: const ValueKey('touch-written-table'),
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(count, (displayIndex) {
              final actualColumn = count - 1 - displayIndex;
              final displayPlace = _pow10(actualColumn);
              final top = (a ~/ displayPlace) % 10;
              final bottom = (b ~/ displayPlace) % 10;
              final result = actualColumn < writtenResultDigits.length
                  ? writtenResultDigits[actualColumn]
                  : null;
              final active = actualColumn == column;
              return Container(
                key: ValueKey('touch-written-column-$displayPlace'),
                width: 62,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: active ? 3 : 1.2,
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _largePlaceLabel(displayPlace),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text('$top', style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      '${addition ? '+' : '−'} $bottom',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(height: 8),
                    Text(
                      result == null ? '·' : '$result',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              addition
                  ? '$placeLabel: $rawTopDigit + $bottomDigit${writtenIncomingCarry > 0 ? ' + Übertrag $writtenIncomingCarry' : ''}'
                  : '$placeLabel: $previewTopDigit − $bottomDigit',
              key: const ValueKey('touch-written-current-calculation'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text('Ergebnisziffer', textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: List<Widget>.generate(10, (digit) {
            return ChoiceChip(
              key: ValueKey('touch-written-digit-$digit'),
              selected: selectedWrittenDigit == digit,
              label: Text('$digit'),
              onSelected: widget.locked
                  ? null
                  : (_) => setState(() {
                        selectedWrittenDigit = digit;
                        writtenStepFeedback = '';
                      }),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(regroupLabel, textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          children: [
            ChoiceChip(
              key: const ValueKey('touch-written-regroup-0'),
              selected: selectedWrittenRegroup == 0,
              label: Text(addition ? 'kein Übertrag' : 'nicht entbündeln'),
              onSelected: widget.locked
                  ? null
                  : (_) => setState(() {
                        selectedWrittenRegroup = 0;
                        writtenStepFeedback = '';
                      }),
            ),
            ChoiceChip(
              key: const ValueKey('touch-written-regroup-1'),
              selected: selectedWrittenRegroup == 1,
              label: Text(addition ? 'Übertrag 1' : 'entbündeln'),
              onSelected: widget.locked
                  ? null
                  : (_) => setState(() {
                        selectedWrittenRegroup = 1;
                        writtenStepFeedback = '';
                      }),
            ),
          ],
        ),
        if (writtenStepFeedback.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            writtenStepFeedback,
            key: const ValueKey('touch-written-step-feedback'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 10),
        FilledButton(
          key: const ValueKey('touch-written-column-submit'),
          onPressed: widget.locked ||
                  selectedWrittenDigit == null ||
                  selectedWrittenRegroup == null
              ? null
              : _submitWrittenColumn,
          child: Text(column == count - 1 ? 'Ergebnis prüfen' : 'Spalte prüfen'),
        ),
      ],
    );
  }

  void _submitWrittenColumn() {
    final values = widget.plan.dataValues;
    final a = values[0];
    final b = values[1];
    final expected = widget.plan.expectedAnswer ?? 0;
    final addition = widget.plan.dataOperation == '+';
    final column = writtenColumnIndex;
    final place = _pow10(column);
    final bottom = (b ~/ place) % 10;
    final top = addition
        ? (a ~/ place) % 10
        : writtenWorkingTopDigits[column];

    final expectedRegroup = addition
        ? (top + bottom + writtenIncomingCarry) ~/ 10
        : (top < bottom ? 1 : 0);
    final effectiveTop = !addition && expectedRegroup == 1 ? top + 10 : top;
    final raw = addition
        ? top + bottom + writtenIncomingCarry
        : effectiveTop - bottom;
    final expectedDigit = addition ? raw % 10 : raw;
    final stepCorrect = selectedWrittenDigit == expectedDigit &&
        selectedWrittenRegroup == expectedRegroup;

    if (!stepCorrect) {
      setState(() {
        writtenStepFeedback = addition
            ? 'Prüfe Ergebnisziffer und Übertrag in dieser Spalte.'
            : 'Prüfe Ergebnisziffer und ob du hier entbündeln musst.';
      });
      widget.onAnswer(_wrongAnswer(expected, expected));
      return;
    }

    if (!addition && expectedRegroup == 1) {
      _applyWrittenBorrow(column);
    }
    while (writtenResultDigits.length <= column) {
      writtenResultDigits.add(0);
    }
    writtenResultDigits[column] = expectedDigit;
    if (addition) writtenIncomingCarry = expectedRegroup;

    final count = _writtenColumnCount();
    if (column == count - 1) {
      var result = 0;
      for (var index = 0; index < writtenResultDigits.length; index++) {
        result += writtenResultDigits[index] * _pow10(index);
      }
      widget.onAnswer(result);
      return;
    }

    setState(() {
      writtenColumnIndex += 1;
      selectedWrittenDigit = null;
      selectedWrittenRegroup = null;
      writtenStepFeedback = '';
    });
  }

  void _applyWrittenBorrow(int column) {
    var source = column + 1;
    while (source < writtenWorkingTopDigits.length &&
        writtenWorkingTopDigits[source] == 0) {
      source += 1;
    }
    if (source >= writtenWorkingTopDigits.length) return;
    writtenWorkingTopDigits[source] -= 1;
    for (var index = source - 1; index > column; index--) {
      writtenWorkingTopDigits[index] = 9;
    }
  }

  int _writtenColumnCount() {
    if (widget.plan.dataValues.length < 2) return 1;
    final a = widget.plan.dataValues[0];
    final b = widget.plan.dataValues[1];
    final expected = widget.plan.expectedAnswer ?? 0;
    return math.max(
      _digitsLeastSignificantFirst(a).length,
      math.max(
        _digitsLeastSignificantFirst(b).length,
        _digitsLeastSignificantFirst(expected).length,
      ),
    );
  }

  List<int> _digitsLeastSignificantFirst(int value) {
    if (value == 0) return <int>[0];
    final digits = <int>[];
    var current = value.abs();
    while (current > 0) {
      digits.add(current % 10);
      current ~/= 10;
    }
    return digits;
  }

  int _pow10(int exponent) {
    var value = 1;
    for (var index = 0; index < exponent; index++) {
      value *= 10;
    }
    return value;
  }

  Widget _buildLargeNumberCompare(BuildContext context) {
    final values = widget.plan.dataValues;
    final a = values[0];
    final b = values[1];
    final decidingPlace = values[2];
    final places = _largePlaces(math.max(a.abs(), b.abs()));
    final relationOnly = widget.plan.dataOperation == 'relation-only';
    final expected = widget.plan.expectedAnswer ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            key: const ValueKey('touch-large-compare-table'),
            children: places.map((place) {
              final selected = selectedLargePlace == place;
              final aDigit = (a ~/ place) % 10;
              final bDigit = (b ~/ place) % 10;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  key: ValueKey('touch-large-compare-place-$place'),
                  onTap: widget.locked || relationOnly
                      ? null
                      : () => setState(() => selectedLargePlace = place),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: selected ? 3 : 1.5,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(_largePlaceLabel(place),
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('$aDigit', style: Theme.of(context).textTheme.titleLarge),
                        const Divider(height: 10),
                        Text('$bDigit', style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          children: List<Widget>.generate(widget.plan.answerChoices.length, (index) {
            return ChoiceChip(
              key: ValueKey('touch-large-compare-relation-$index'),
              selected: selectedLargeRelation == index,
              label: Text(widget.plan.answerChoices[index]),
              onSelected: widget.locked
                  ? null
                  : (_) => setState(() => selectedLargeRelation = index),
            );
          }),
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const ValueKey('touch-large-compare-submit'),
          onPressed: widget.locked ||
                  (!relationOnly && selectedLargePlace == null) ||
                  selectedLargeRelation == null
              ? null
              : () {
                  final relation = selectedLargeRelation!;
                  final structureCorrect =
                      relationOnly || selectedLargePlace == decidingPlace;
                  widget.onAnswer(
                    structureCorrect ? relation : _wrongAnswer(relation, expected),
                  );
                },
          child: const Text('Prüfen'),
        ),
      ],
    );
  }

  Widget _buildLargeNumberOrder(BuildContext context) {
    final values = widget.plan.dataValues;
    final correct = widget.plan.correctSelectionIndexes;
    final expected = widget.plan.expectedAnswer ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          key: const ValueKey('touch-large-order-cards'),
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: List<Widget>.generate(values.length, (index) {
            final position = selectedLargeOrder.indexOf(index);
            return ActionChip(
              key: ValueKey('touch-large-order-card-$index'),
              avatar: position >= 0 ? CircleAvatar(child: Text('${position + 1}')) : null,
              label: Text('${values[index]}'),
              onPressed: widget.locked || position >= 0
                  ? null
                  : () => setState(() => selectedLargeOrder.add(index)),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          selectedLargeOrder.isEmpty
              ? 'Noch keine Zahl eingeordnet.'
              : selectedLargeOrder.map((index) => values[index]).join(' < '),
          key: const ValueKey('touch-large-order-status'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        TextButton.icon(
          key: const ValueKey('touch-large-order-reset'),
          onPressed: widget.locked || selectedLargeOrder.isEmpty
              ? null
              : () => setState(selectedLargeOrder.clear),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Neu ordnen'),
        ),
        FilledButton(
          key: const ValueKey('touch-large-order-submit'),
          onPressed: widget.locked || selectedLargeOrder.length != values.length
              ? null
              : () {
                  final exact = _listEqualsInt(selectedLargeOrder, correct);
                  widget.onAnswer(exact ? expected : _wrongAnswer(expected, expected));
                },
          child: const Text('Prüfen'),
        ),
      ],
    );
  }

  Widget _buildNumberWordPlaceValueBuilder(BuildContext context) {
    if (widget.plan.dataValues.isEmpty) return const SizedBox.shrink();
    final number = widget.plan.dataValues.first;
    final places = _largePlaces(number);
    if (numberWordDigits.length != places.length) {
      numberWordDigits
        ..clear()
        ..addAll(List<int?>.filled(places.length, null));
      numberWordLockedPlaces.clear();
      numberWordActiveIndex = 0;
    }
    final skipTensOnes = widget.plan.dataOperation == 'read:skip-tens-ones';
    if (skipTensOnes) {
      for (var index = 0; index < places.length; index++) {
        if ((places[index] == 10 || places[index] == 1) &&
            !numberWordLockedPlaces.contains(index)) {
          numberWordDigits[index] = (number ~/ places[index]) % 10;
          numberWordLockedPlaces.add(index);
        }
      }
    }
    final complete = numberWordDigits.every((digit) => digit != null);
    var built = 0;
    if (complete) {
      for (var index = 0; index < places.length; index++) {
        built += numberWordDigits[index]! * places[index];
      }
    }
    final activePlace = places[numberWordActiveIndex.clamp(0, places.length - 1)];

    void selectDigit(int digit) {
      if (widget.locked || numberWordLockedPlaces.contains(numberWordActiveIndex)) {
        return;
      }
      setState(() {
        numberWordDigits[numberWordActiveIndex] = digit;
        final openIndexes = List<int>.generate(places.length, (index) => index)
            .where((index) =>
                !numberWordLockedPlaces.contains(index) &&
                numberWordDigits[index] == null)
            .toList(growable: false);
        if (openIndexes.isNotEmpty) {
          final after = openIndexes.where((index) => index > numberWordActiveIndex);
          numberWordActiveIndex = after.isNotEmpty ? after.first : openIndexes.first;
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (skipTensOnes) ...[
          Card.outlined(
            key: const ValueKey('touch-number-word-checked-suffix'),
            margin: EdgeInsets.zero,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zehner und Einer sind aus deinem ersten Schritt schon geklärt.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            key: const ValueKey('touch-number-word-table'),
            children: List<Widget>.generate(places.length, (index) {
              final place = places[index];
              final digit = numberWordDigits[index];
              final lockedPlace = numberWordLockedPlaces.contains(index);
              final active = numberWordActiveIndex == index && !lockedPlace;
              return Semantics(
                button: !lockedPlace,
                selected: active,
                label: lockedPlace
                    ? '${_largePlaceLabel(place)} bereits geklärt: ${digit ?? 0}'
                    : '${_largePlaceLabel(place)} auswählen',
                child: InkWell(
                  key: ValueKey('touch-number-word-place-$place'),
                  onTap: widget.locked || lockedPlace
                      ? null
                      : () => setState(() => numberWordActiveIndex = index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 62,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: active ? 3 : 1.5,
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                      color: lockedPlace
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _largePlaceLabel(place),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          digit?.toString() ?? '?',
                          key: ValueKey('touch-number-word-digit-$place'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (lockedPlace)
                          const Icon(Icons.check_rounded, size: 17),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          numberWordLockedPlaces.contains(numberWordActiveIndex)
              ? 'Diese Stelle ist bereits geklärt.'
              : 'Welche Ziffer gehört an die Stelle ${_largePlaceLabel(activePlace)}?',
          key: const ValueKey('touch-number-word-active-label'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const ValueKey('touch-number-word-digits'),
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 7,
          children: List<Widget>.generate(10, (digit) {
            final selected = !numberWordLockedPlaces.contains(numberWordActiveIndex) &&
                numberWordDigits[numberWordActiveIndex] == digit;
            return ChoiceChip(
              key: ValueKey('touch-number-word-choice-$digit'),
              selected: selected,
              label: Text('$digit'),
              onSelected: widget.locked ||
                      numberWordLockedPlaces.contains(numberWordActiveIndex)
                  ? null
                  : (_) => selectDigit(digit),
            );
          }),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const ValueKey('touch-number-word-clear'),
          onPressed: widget.locked ||
                  numberWordLockedPlaces.contains(numberWordActiveIndex)
              ? null
              : () => setState(() => numberWordDigits[numberWordActiveIndex] = null),
          icon: const Icon(Icons.backspace_outlined),
          label: const Text('Aktuelle Stelle leeren'),
        ),
        const SizedBox(height: 4),
        FilledButton.icon(
          key: const ValueKey('touch-number-word-submit'),
          onPressed: widget.locked || !complete
              ? null
              : () {
                  final expected = widget.plan.expectedAnswer ?? 0;
                  widget.onAnswer(
                    built == number ? expected : _wrongAnswer(expected, expected),
                  );
                },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Zahl prüfen'),
        ),
      ],
    );
  }

  Widget _buildLargeNumberDecompose(BuildContext context) {
    final number = widget.plan.dataValues.first;
    final places = _largePlaces(number);
    if (largePlaceDigits.length != places.length) {
      largePlaceDigits
        ..clear()
        ..addAll(List<int>.filled(places.length, 0));
    }
    var built = 0;
    for (var index = 0; index < places.length; index++) {
      built += largePlaceDigits[index] * places[index];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            key: const ValueKey('touch-large-decompose-table'),
            children: List<Widget>.generate(places.length, (index) {
              final place = places[index];
              final digit = largePlaceDigits[index];
              return SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Text(_largePlaceLabel(place),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    IconButton(
                      key: ValueKey('touch-large-digit-plus-$place'),
                      onPressed: widget.locked || digit >= 9
                          ? null
                          : () => setState(() => largePlaceDigits[index]++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    Text('$digit', style: Theme.of(context).textTheme.headlineSmall),
                    IconButton(
                      key: ValueKey('touch-large-digit-minus-$place'),
                      onPressed: widget.locked || digit <= 0
                          ? null
                          : () => setState(() => largePlaceDigits[index]--),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        Text(
          'Gebaut: $built',
          key: const ValueKey('touch-large-decompose-value'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey('touch-large-decompose-submit'),
          onPressed: widget.locked ? null : () => widget.onAnswer(built),
          child: const Text('Prüfen'),
        ),
      ],
    );
  }

  Widget _buildLargeNumberPlaceDigit(BuildContext context) {
    final number = widget.plan.dataValues[0];
    final targetPlace = widget.plan.dataValues[1];
    final places = _largePlaces(number);
    final expected = widget.plan.expectedAnswer ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            key: const ValueKey('touch-large-place-table'),
            children: places.map((place) {
              final digit = (number ~/ place) % 10;
              final selected = selectedLargeDigitPlace == place;
              return InkWell(
                key: ValueKey('touch-large-place-$place'),
                onTap: widget.locked
                    ? null
                    : () => setState(() => selectedLargeDigitPlace = place),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: selected ? 3 : 1.5,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(_largePlaceLabel(place),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('$digit', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const ValueKey('touch-large-place-submit'),
          onPressed: widget.locked || selectedLargeDigitPlace == null
              ? null
              : () {
                  final place = selectedLargeDigitPlace!;
                  final candidate = (number ~/ place) % 10;
                  widget.onAnswer(
                    place == targetPlace
                        ? candidate
                        : _wrongAnswer(candidate, expected),
                  );
                },
          child: const Text('Prüfen'),
        ),
      ],
    );
  }

  Widget _buildCubeNetFoldChoice(BuildContext context) {
    final cells = widget.plan.dataLabels
        .map((raw) => raw.split(','))
        .where((parts) => parts.length == 2)
        .map((parts) => (int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0))
        .toList(growable: false);
    final maxX = cells.isEmpty ? 0 : cells.map((c) => c.$1).reduce(math.max);
    final maxY = cells.isEmpty ? 0 : cells.map((c) => c.$2).reduce(math.max);
    final occupied = cells.toSet();
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: AspectRatio(
              aspectRatio: (maxX + 1) / math.max(1, maxY + 1),
              child: GridView.builder(
                key: const ValueKey('touch-cube-net-grid'),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (maxX + 1) * (maxY + 1),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: maxX + 1),
                itemBuilder: (context, index) {
                  final cell = (index % (maxX + 1), index ~/ (maxX + 1));
                  return Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: occupied.contains(cell)
                        ? BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                          )
                        : null,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            ChoiceChip(
              key: const ValueKey('touch-cube-net-yes'),
              selected: selectedCubeNetChoice == 0,
              avatar: const Icon(Icons.check_circle_outline),
              label: const Text('faltbar'),
              onSelected: widget.locked ? null : (_) => setState(() => selectedCubeNetChoice = 0),
            ),
            ChoiceChip(
              key: const ValueKey('touch-cube-net-no'),
              selected: selectedCubeNetChoice == 1,
              avatar: const Icon(Icons.block_outlined),
              label: const Text('nicht faltbar'),
              onSelected: widget.locked ? null : (_) => setState(() => selectedCubeNetChoice = 1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const ValueKey('touch-cube-net-submit'),
          onPressed: widget.locked || selectedCubeNetChoice == null
              ? null
              : () => widget.onAnswer(selectedCubeNetChoice!),
          child: const Text('Prüfen'),
        ),
      ],
    );
  }

  Widget _buildGeometryRelationChoice(BuildContext context) {
    final operation = widget.plan.dataOperation ?? 'lines';
    final optionCount = switch (operation) {
      'lines' => 3,
      'angle' => 3,
      'figure' => 4,
      'circle' => 3,
      _ => widget.plan.answerChoices.length,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          key: const ValueKey('touch-geometry-options'),
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: List<Widget>.generate(optionCount, (index) {
            final selected = selectedGeometryCandidate == index;
            return Semantics(
              button: true,
              selected: selected,
              label: 'Geometrisches Bild ${index + 1}',
              child: InkWell(
                key: ValueKey('touch-geometry-option-$index'),
                onTap: widget.locked
                    ? null
                    : () => setState(() => selectedGeometryCandidate = index),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: operation == 'figure' || operation == 'basic-shape' ? 132 : 150,
                  height: 118,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      width: selected ? 3 : 1.5,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _GeometryChoicePainter(
                      operation: operation,
                      index: index,
                      label: operation == 'basic-shape' &&
                              index < widget.plan.answerChoices.length
                          ? widget.plan.answerChoices[index]
                          : null,
                      lineColor: Theme.of(context).colorScheme.onSurface,
                      accentColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          selectedGeometryCandidate == null
              ? 'Noch kein Bild ausgewählt.'
              : 'Bild ${selectedGeometryCandidate! + 1} ausgewählt.',
          key: const ValueKey('touch-geometry-selection-status'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const ValueKey('touch-geometry-submit'),
          onPressed: widget.locked || selectedGeometryCandidate == null
              ? null
              : () => widget.onAnswer(selectedGeometryCandidate!),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Prüfen'),
        ),
      ],
    );
  }

  Widget _buildLengthRulerOperation(BuildContext context) {
    final values = widget.plan.dataValues;
    final first = values.isNotEmpty ? values[0] : 0;
    final second = values.length > 1 ? values[1] : 0;
    final subtraction = widget.plan.dataOperation == 'subtract';
    final span = widget.plan.maxValue - widget.plan.minValue;
    final expected = widget.plan.expectedAnswer ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card.outlined(
          key: const ValueKey('touch-length-ruler-model'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  subtraction
                      ? 'Ganzes Seil: $first cm · abgeschnitten: $second cm'
                      : '1. Stück: $first cm · 2. Stück: $second cm',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  subtraction
                      ? 'Wo endet der Rest auf dem Lineal?'
                      : 'Wo endet das zweite Stück, wenn es direkt angelegt wird?',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$selectedValue cm',
          key: const ValueKey('touch-length-ruler-value'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        Slider(
          key: const ValueKey('touch-length-ruler-slider'),
          value: selectedValue.toDouble(),
          min: widget.plan.minValue.toDouble(),
          max: widget.plan.maxValue.toDouble(),
          divisions: span > 0 ? span : null,
          label: '$selectedValue cm',
          onChanged: widget.locked
              ? null
              : (value) => setState(() => selectedValue = value.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${widget.plan.minValue} cm'),
            Text('${widget.plan.maxValue} cm'),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-length-ruler-submit'),
          onPressed: widget.locked
              ? null
              : () => widget.onAnswer(
                    selectedValue == expected
                        ? expected
                        : _wrongAnswer(selectedValue, expected),
                  ),
          icon: const Icon(Icons.straighten_rounded),
          label: const Text('Endpunkt prüfen'),
        ),
      ],
    );
  }

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

  Widget _buildScaleDistanceBuilder(BuildContext context) {
    final values = widget.plan.dataValues;
    final metersPerCentimeter = values.isNotEmpty ? values[0] : 1;
    final planCentimeters = values.length > 1 ? values[1] : 1;
    final expected = widget.plan.expectedAnswer ??
        metersPerCentimeter * planCentimeters;
    final maxBuilt = planCentimeters + 2;

    Widget segment(String label, {bool real = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: real
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            color: real
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '1 cm im Plan = $metersPerCentimeter m in Wirklichkeit',
          key: const ValueKey('touch-scale-ratio'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Planstrecke',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          key: const ValueKey('touch-scale-plan-segments'),
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 5,
          children: [
            for (var index = 0; index < planCentimeters; index++)
              segment('1 cm'),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Realstrecke: $scaleBuiltSegments Blöcke gebaut',
          key: const ValueKey('touch-scale-built-count'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        if (scaleBuiltSegments == 0)
          Text(
            'Baue die reale Strecke aus gleich großen Paketen.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          Wrap(
            key: const ValueKey('touch-scale-real-segments'),
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 5,
            children: [
              for (var index = 0; index < scaleBuiltSegments; index++)
                segment('$metersPerCentimeter m', real: true),
            ],
          ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              key: const ValueKey('touch-scale-add'),
              onPressed: widget.locked || scaleBuiltSegments >= maxBuilt
                  ? null
                  : () => setState(() => scaleBuiltSegments += 1),
              icon: const Icon(Icons.add_rounded),
              label: Text('$metersPerCentimeter m hinzufügen'),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('touch-scale-remove'),
              onPressed: widget.locked || scaleBuiltSegments == 0
                  ? null
                  : () => setState(() => scaleBuiltSegments -= 1),
              icon: const Icon(Icons.remove_rounded),
              label: const Text('Letzten Block entfernen'),
            ),
            TextButton.icon(
              key: const ValueKey('touch-scale-reset'),
              onPressed: widget.locked || scaleBuiltSegments == 0
                  ? null
                  : () => setState(() => scaleBuiltSegments = 0),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Neu bauen'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Wie lang ist die ganze Strecke in Wirklichkeit?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        NumberAnswerPad(
          key: const ValueKey('touch-scale-number-pad'),
          maxValue: widget.plan.maxValue,
          onAnswer: (candidate) {
            final structureCorrect = scaleBuiltSegments == planCentimeters;
            widget.onAnswer(
              structureCorrect && candidate == expected
                  ? expected
                  : _wrongAnswer(candidate, expected),
            );
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

  List<String> _expectedRouteMoves() {
    if (widget.plan.dataLabels.length < 2 || widget.plan.dataValues.length < 2) {
      return const <String>[];
    }
    return <String>[
      ...List<String>.filled(widget.plan.dataValues[0], widget.plan.dataLabels[0]),
      ...List<String>.filled(widget.plan.dataValues[1], widget.plan.dataLabels[1]),
    ];
  }

  int _routeLockedPrefixLength() {
    if (widget.plan.dataOperation != 'skip-first' ||
        widget.plan.dataValues.isEmpty) {
      return 0;
    }
    return widget.plan.dataValues.first;
  }

  String _routeArrow(String direction) => switch (direction) {
        'right' => '→',
        'up' => '↑',
        'left' => '←',
        'down' => '↓',
        _ => '?',
      };

  String _routeLabel(String direction) => switch (direction) {
        'right' => 'rechts',
        'up' => 'hoch',
        'left' => 'links',
        'down' => 'runter',
        _ => direction,
      };

  IconData _routeIcon(String direction) => switch (direction) {
        'right' => Icons.arrow_forward_rounded,
        'up' => Icons.arrow_upward_rounded,
        'left' => Icons.arrow_back_rounded,
        'down' => Icons.arrow_downward_rounded,
        _ => Icons.help_outline_rounded,
      };

  void _addRouteMove(String direction) {
    final expected = _expectedRouteMoves();
    if (widget.locked || routeMoves.length >= expected.length) return;
    setState(() => routeMoves.add(direction));
  }

  void _undoRouteMove() {
    final prefix = _routeLockedPrefixLength();
    if (widget.locked || routeMoves.length <= prefix) return;
    setState(() => routeMoves.removeLast());
  }

  void _resetRouteMoves() {
    if (widget.locked) return;
    final prefix = _routeLockedPrefixLength();
    setState(() {
      if (prefix == 0) {
        routeMoves.clear();
      } else {
        routeMoves
          ..clear()
          ..addAll(
            List<String>.filled(
              prefix,
              widget.plan.dataLabels.first,
            ),
          );
      }
    });
  }

  Widget _buildRouteSequenceWalker(BuildContext context) {
    final expectedMoves = _expectedRouteMoves();
    final prefix = _routeLockedPrefixLength();
    final required = expectedMoves.length;
    final completedAfterPrefix = math.max(0, routeMoves.length - prefix);
    final remainingAfterPrefix = math.max(0, required - routeMoves.length);
    const directions = <String>['left', 'up', 'down', 'right'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (prefix > 0) ...[
          Container(
            key: const ValueKey('touch-route-prefix-checked'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: Text(
              'Abschnitt 1 geprüft: $prefix × ${_routeArrow(widget.plan.dataLabels.first)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Center(
          child: SizedBox(
            width: 260,
            height: 220,
            child: CustomPaint(
              key: const ValueKey('touch-route-grid'),
              painter: _TouchRoutePainter(
                moves: routeMoves,
                verifiedPrefixLength: prefix,
                color: Theme.of(context).colorScheme.onSurface,
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          prefix > 0
              ? '$completedAfterPrefix Felder im zweiten Abschnitt gegangen · noch $remainingAfterPrefix'
              : '${routeMoves.length} von $required Feldern gegangen',
          key: const ValueKey('touch-route-progress'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (routeMoves.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            routeMoves.map(_routeArrow).join(' '),
            key: const ValueKey('touch-route-arrows'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final direction in directions)
              FilledButton.tonalIcon(
                key: ValueKey('touch-route-$direction'),
                onPressed: widget.locked || routeMoves.length >= required
                    ? null
                    : () => _addRouteMove(direction),
                icon: Icon(_routeIcon(direction)),
                label: Text('1 ${_routeLabel(direction)}'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              key: const ValueKey('touch-route-undo'),
              onPressed: widget.locked || routeMoves.length <= prefix
                  ? null
                  : _undoRouteMove,
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Letztes Feld zurück'),
            ),
            TextButton.icon(
              key: const ValueKey('touch-route-reset'),
              onPressed: widget.locked || routeMoves.length <= prefix
                  ? null
                  : _resetRouteMoves,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Abschnitt neu'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-route-submit'),
          onPressed: widget.locked || routeMoves.length != required
              ? null
              : _submitRouteSequence,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Route prüfen'),
        ),
      ],
    );
  }

  void _submitRouteSequence() {
    final expectedMoves = _expectedRouteMoves();
    final expectedAnswer = widget.plan.expectedAnswer ?? 0;
    final exact = _listEqualsString(routeMoves, expectedMoves);
    widget.onAnswer(
      exact ? expectedAnswer : _wrongAnswer(expectedAnswer, expectedAnswer),
    );
  }

  bool _listEqualsString(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
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

  Widget _buildBodyPropertySelector(BuildContext context) {
    const canvasSize = Size(250, 190);
    final body = widget.plan.geometryShape ?? '';
    final property = widget.plan.dataOperation ?? '';
    final expected = widget.plan.expectedAnswer ?? 0;
    final featureTargets = property == 'Flächen'
        ? _BodyTouchGeometry.faceCenters(body, canvasSize)
        : property == 'Ecken'
            ? _BodyTouchGeometry.cornerPoints(body, canvasSize)
            : _BodyTouchGeometry.edgeTargets(body, canvasSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          property == 'Flächen'
              ? '$body · Flächenmodell'
              : '$body · $property am Körper',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: canvasSize.width,
            height: canvasSize.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    key: const ValueKey('touch-body-preview'),
                    painter: property == 'Flächen'
                        ? _TouchBodySurfacePainter(
                            body: body,
                            selectedFeatures: Set<int>.of(selectedBodyFeatures),
                            lineColor: Theme.of(context).colorScheme.onSurface,
                            accentColor: Theme.of(context).colorScheme.primary,
                          )
                        : _TouchBodyDiagramPainter(
                            body: body,
                            property: property,
                            selectedFeatures: Set<int>.of(selectedBodyFeatures),
                            lineColor: Theme.of(context).colorScheme.onSurface,
                            accentColor: Theme.of(context).colorScheme.primary,
                          ),
                  ),
                ),
                for (var index = 0; index < featureTargets.length; index++)
                  Positioned(
                    left: featureTargets[index].dx - 20,
                    top: featureTargets[index].dy - 20,
                    width: 40,
                    height: 40,
                    child: Semantics(
                      button: true,
                      selected: selectedBodyFeatures.contains(index),
                      label: '$property ${index + 1}',
                      child: GestureDetector(
                        key: ValueKey('touch-body-feature-$index'),
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.locked
                            ? null
                            : () => setState(() {
                                  bodyNoFeatureClaim = false;
                                  if (!selectedBodyFeatures.add(index)) {
                                    selectedBodyFeatures.remove(index);
                                  }
                                }),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (property != 'Flächen') ...[
          const SizedBox(height: 8),
          Center(
            child: ChoiceChip(
              key: const ValueKey('touch-body-none'),
              selected: bodyNoFeatureClaim,
              label: Text('Keine $property'),
              onSelected: widget.locked
                  ? null
                  : (selected) => setState(() {
                        bodyNoFeatureClaim = selected;
                        if (selected) selectedBodyFeatures.clear();
                      }),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          bodyNoFeatureClaim
              ? 'Du meinst: keine $property.'
              : '${selectedBodyFeatures.length} $property markiert',
          key: const ValueKey('touch-body-selection-status'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const ValueKey('touch-body-submit'),
          onPressed: widget.locked
              ? null
              : () {
                  final expectedSet = widget.plan.correctSelectionIndexes.toSet();
                  final correct = expected == 0
                      ? bodyNoFeatureClaim
                      : !bodyNoFeatureClaim &&
                          setEquals(selectedBodyFeatures, expectedSet);
                  if (correct) {
                    widget.onAnswer(expected);
                  } else if (bodyNoFeatureClaim) {
                    widget.onAnswer(_wrongAnswer(0, expected));
                  } else {
                    widget.onAnswer(
                      _wrongAnswer(selectedBodyFeatures.length, expected),
                    );
                  }
                },
          icon: const Icon(Icons.check_rounded),
          label: Text('$property prüfen'),
        ),
      ],
    );
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

  List<int> _largePlaces(int number) {
    var place = 1;
    final value = number.abs();
    while (place * 10 <= math.max(1, value)) {
      place *= 10;
    }
    final result = <int>[];
    while (place >= 1) {
      result.add(place);
      if (place == 1) break;
      place ~/= 10;
    }
    return result;
  }

  String _largePlaceLabel(int place) => switch (place) {
        1000000 => 'M',
        100000 => 'HT',
        10000 => 'ZT',
        1000 => 'T',
        100 => 'H',
        10 => 'Z',
        _ => 'E',
      };

  bool _listEqualsInt(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
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

class _BodyTouchGeometry {
  static List<Offset> cornerPoints(String body, Size size) {
    switch (body) {
      case 'Würfel':
        return _boxCorners(size, square: true);
      case 'Quader':
        return _boxCorners(size, square: false);
      case 'Pyramide':
        final base = _pyramidBase(size);
        return <Offset>[_pyramidApex(size), ...base];
      case 'Kegel':
        return <Offset>[Offset(size.width * .50, size.height * .12)];
      default:
        return const <Offset>[];
    }
  }

  static List<Offset> edgeTargets(String body, Size size) {
    if (body == 'Würfel' || body == 'Quader') {
      return _boxEdges(size, square: body == 'Würfel')
          .map((edge) => _mid(edge.$1, edge.$2))
          .toList(growable: false);
    }
    if (body == 'Pyramide') {
      return _pyramidEdges(size)
          .map((edge) => _mid(edge.$1, edge.$2))
          .toList(growable: false);
    }
    if (body == 'Zylinder') {
      final rings = _cylinderRings(size);
      return rings
          .map((ring) => Offset(ring.right - 3, ring.center.dy))
          .toList(growable: false);
    }
    if (body == 'Kegel') {
      final ring = _coneBase(size);
      return <Offset>[Offset(ring.right - 3, ring.center.dy)];
    }
    return const <Offset>[];
  }

  static List<Offset> faceCenters(String body, Size size) =>
      _BodyFaceGeometry.forBody(body, size)
          .map((face) => face.center)
          .toList(growable: false);

  static List<Offset> _boxCorners(Size size, {required bool square}) {
    final w = square ? size.width * .48 : size.width * .58;
    final h = square ? size.height * .52 : size.height * .42;
    final front = Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .60),
      width: w,
      height: h,
    );
    final back = front.shift(Offset(size.width * .14, -size.height * .16));
    return <Offset>[
      front.topLeft,
      front.topRight,
      front.bottomRight,
      front.bottomLeft,
      back.topLeft,
      back.topRight,
      back.bottomRight,
      back.bottomLeft,
    ];
  }

  static List<(Offset, Offset, bool)> _boxEdges(
    Size size, {
    required bool square,
  }) {
    final points = _boxCorners(size, square: square);
    final f = points.sublist(0, 4);
    final b = points.sublist(4, 8);
    return <(Offset, Offset, bool)>[
      for (var i = 0; i < 4; i++) (f[i], f[(i + 1) % 4], false),
      for (var i = 0; i < 4; i++) (b[i], b[(i + 1) % 4], true),
      for (var i = 0; i < 4; i++) (f[i], b[i], false),
    ];
  }

  static Offset _pyramidApex(Size size) =>
      Offset(size.width * .48, size.height * .12);

  static List<Offset> _pyramidBase(Size size) => <Offset>[
        Offset(size.width * .18, size.height * .68),
        Offset(size.width * .72, size.height * .68),
        Offset(size.width * .86, size.height * .86),
        Offset(size.width * .32, size.height * .86),
      ];

  static List<(Offset, Offset, bool)> _pyramidEdges(Size size) {
    final apex = _pyramidApex(size);
    final base = _pyramidBase(size);
    return <(Offset, Offset, bool)>[
      for (var i = 0; i < 4; i++)
        (base[i], base[(i + 1) % 4], i == 2),
      for (var i = 0; i < 4; i++) (apex, base[i], i == 2),
    ];
  }

  static List<Rect> _cylinderRings(Size size) {
    final top = Rect.fromLTWH(
      size.width * .20,
      size.height * .14,
      size.width * .60,
      size.height * .25,
    );
    return <Rect>[top, top.shift(Offset(0, size.height * .48))];
  }

  static Rect _coneBase(Size size) => Rect.fromLTWH(
        size.width * .18,
        size.height * .66,
        size.width * .64,
        size.height * .24,
      );

  static Offset _mid(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
}

class _BodyFaceShape {
  const _BodyFaceShape(this.path, this.center);
  final Path path;
  final Offset center;
}

class _BodyFaceGeometry {
  static List<_BodyFaceShape> forBody(String body, Size size) {
    switch (body) {
      case 'Würfel':
        return _boxNet(size, rectangle: false);
      case 'Quader':
        return _boxNet(size, rectangle: true);
      case 'Pyramide':
        return _pyramidNet(size);
      case 'Zylinder':
        return _cylinderNet(size);
      case 'Kegel':
        return _coneNet(size);
      case 'Kugel':
        final center = Offset(size.width / 2, size.height / 2);
        final radius = size.shortestSide * .36;
        return <_BodyFaceShape>[
          _BodyFaceShape(
            Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
            center,
          ),
        ];
      default:
        return const <_BodyFaceShape>[];
    }
  }

  static List<_BodyFaceShape> _boxNet(Size size, {required bool rectangle}) {
    final cellW = rectangle ? 40.0 : 36.0;
    final cellH = rectangle ? 28.0 : 36.0;
    final origin = Offset(
      size.width / 2 - cellW * 1.5,
      size.height / 2 - cellH / 2,
    );
    final offsets = <Offset>[
      origin,
      origin.translate(cellW, 0),
      origin.translate(cellW * 2, 0),
      origin.translate(cellW * 3, 0),
      origin.translate(cellW, -cellH),
      origin.translate(cellW, cellH),
    ];
    return offsets.map((offset) {
      final rect = Rect.fromLTWH(offset.dx, offset.dy, cellW, cellH);
      return _BodyFaceShape(Path()..addRect(rect), rect.center);
    }).toList(growable: false);
  }

  static List<_BodyFaceShape> _pyramidNet(Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const half = 28.0;
    final square = Rect.fromCenter(center: c, width: half * 2, height: half * 2);
    Path triangle(Offset a, Offset b, Offset tip) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(tip.dx, tip.dy)
      ..close();
    final topTip = Offset(c.dx, square.top - 40);
    final rightTip = Offset(square.right + 40, c.dy);
    final bottomTip = Offset(c.dx, square.bottom + 40);
    final leftTip = Offset(square.left - 40, c.dy);
    return <_BodyFaceShape>[
      _BodyFaceShape(Path()..addRect(square), c),
      _BodyFaceShape(
        triangle(square.topLeft, square.topRight, topTip),
        Offset(c.dx, square.top - 14),
      ),
      _BodyFaceShape(
        triangle(square.topRight, square.bottomRight, rightTip),
        Offset(square.right + 14, c.dy),
      ),
      _BodyFaceShape(
        triangle(square.bottomLeft, square.bottomRight, bottomTip),
        Offset(c.dx, square.bottom + 14),
      ),
      _BodyFaceShape(
        triangle(square.topLeft, square.bottomLeft, leftTip),
        Offset(square.left - 14, c.dy),
      ),
    ];
  }

  static List<_BodyFaceShape> _cylinderNet(Size size) {
    final rect = Rect.fromLTWH(
      size.width * .28,
      size.height * .30,
      size.width * .44,
      size.height * .42,
    );
    final radius = size.width * .10;
    final left = Offset(size.width * .12, size.height * .51);
    final right = Offset(size.width * .88, size.height * .51);
    return <_BodyFaceShape>[
      _BodyFaceShape(Path()..addRect(rect), rect.center),
      _BodyFaceShape(
        Path()..addOval(Rect.fromCircle(center: left, radius: radius)),
        left,
      ),
      _BodyFaceShape(
        Path()..addOval(Rect.fromCircle(center: right, radius: radius)),
        right,
      ),
    ];
  }

  static List<_BodyFaceShape> _coneNet(Size size) {
    final center = Offset(size.width * .54, size.height * .52);
    final sector = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(size.width * .18, size.height * .22)
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .06,
        size.width * .88,
        size.height * .56,
      )
      ..close();
    final circleCenter = Offset(size.width * .28, size.height * .86);
    const radius = 20.0;
    return <_BodyFaceShape>[
      _BodyFaceShape(sector, Offset(size.width * .55, size.height * .34)),
      _BodyFaceShape(
        Path()..addOval(Rect.fromCircle(center: circleCenter, radius: radius)),
        circleCenter,
      ),
    ];
  }
}

class _TouchBodyDiagramPainter extends CustomPainter {
  const _TouchBodyDiagramPainter({
    required this.body,
    required this.property,
    required this.selectedFeatures,
    required this.lineColor,
    required this.accentColor,
  });

  final String body;
  final String property;
  final Set<int> selectedFeatures;
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rear = Paint()
      ..color = lineColor.withValues(alpha: .38)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final accent = Paint()
      ..color = accentColor
      ..strokeWidth = 4.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (body == 'Würfel' || body == 'Quader') {
      final edges = _BodyTouchGeometry._boxEdges(
        size,
        square: body == 'Würfel',
      );
      for (var index = 0; index < edges.length; index++) {
        final edge = edges[index];
        canvas.drawLine(
          edge.$1,
          edge.$2,
          selectedFeatures.contains(index) ? accent : (edge.$3 ? rear : line),
        );
      }
      _paintSelectedCorners(canvas, size);
      return;
    }

    if (body == 'Pyramide') {
      final edges = _BodyTouchGeometry._pyramidEdges(size);
      for (var index = 0; index < edges.length; index++) {
        final edge = edges[index];
        canvas.drawLine(
          edge.$1,
          edge.$2,
          selectedFeatures.contains(index) ? accent : (edge.$3 ? rear : line),
        );
      }
      _paintSelectedCorners(canvas, size);
      return;
    }

    if (body == 'Zylinder') {
      final rings = _BodyTouchGeometry._cylinderRings(size);
      for (var index = 0; index < rings.length; index++) {
        canvas.drawOval(
          rings[index],
          property == 'Kanten' && selectedFeatures.contains(index)
              ? accent
              : line,
        );
      }
      canvas.drawLine(
        Offset(rings.first.left, rings.first.center.dy),
        Offset(rings.last.left, rings.last.center.dy),
        line,
      );
      canvas.drawLine(
        Offset(rings.first.right, rings.first.center.dy),
        Offset(rings.last.right, rings.last.center.dy),
        line,
      );
      return;
    }

    if (body == 'Kegel') {
      final apex = Offset(size.width * .50, size.height * .12);
      final base = _BodyTouchGeometry._coneBase(size);
      canvas.drawLine(apex, Offset(base.left, base.center.dy), line);
      canvas.drawLine(apex, Offset(base.right, base.center.dy), line);
      canvas.drawOval(
        base,
        property == 'Kanten' && selectedFeatures.contains(0) ? accent : line,
      );
      _paintSelectedCorners(canvas, size);
      return;
    }

    if (body == 'Kugel') {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = size.shortestSide * .36;
      canvas.drawCircle(center, radius, line);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * .60,
        ),
        rear,
      );
      return;
    }
  }

  void _paintSelectedCorners(Canvas canvas, Size size) {
    if (property != 'Ecken') return;
    final points = _BodyTouchGeometry.cornerPoints(body, size);
    for (var index = 0; index < points.length; index++) {
      if (!selectedFeatures.contains(index)) continue;
      canvas.drawCircle(points[index], 6, Paint()..color = accentColor);
    }
  }

  @override
  bool shouldRepaint(covariant _TouchBodyDiagramPainter oldDelegate) =>
      body != oldDelegate.body ||
      property != oldDelegate.property ||
      !setEquals(selectedFeatures, oldDelegate.selectedFeatures) ||
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor;
}

class _TouchBodySurfacePainter extends CustomPainter {
  const _TouchBodySurfacePainter({
    required this.body,
    required this.selectedFeatures,
    required this.lineColor,
    required this.accentColor,
  });

  final String body;
  final Set<int> selectedFeatures;
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final baseFill = Paint()
      ..color = accentColor.withValues(alpha: .08)
      ..style = PaintingStyle.fill;
    final selectedFill = Paint()
      ..color = accentColor.withValues(alpha: .34)
      ..style = PaintingStyle.fill;
    final faces = _BodyFaceGeometry.forBody(body, size);
    for (var index = 0; index < faces.length; index++) {
      final face = faces[index];
      canvas.drawPath(
        face.path,
        selectedFeatures.contains(index) ? selectedFill : baseFill,
      );
      canvas.drawPath(face.path, line);
    }
  }

  @override
  bool shouldRepaint(covariant _TouchBodySurfacePainter oldDelegate) =>
      body != oldDelegate.body ||
      !setEquals(selectedFeatures, oldDelegate.selectedFeatures) ||
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor;
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

class _TouchRoutePainter extends CustomPainter {
  const _TouchRoutePainter({
    required this.moves,
    required this.verifiedPrefixLength,
    required this.color,
    required this.accent,
  });

  final List<String> moves;
  final int verifiedPrefixLength;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[Offset.zero];
    var current = Offset.zero;
    for (final move in moves) {
      current += switch (move) {
        'right' => const Offset(1, 0),
        'left' => const Offset(-1, 0),
        'up' => const Offset(0, 1),
        'down' => const Offset(0, -1),
        _ => Offset.zero,
      };
      points.add(current);
    }

    final minX = points.map((point) => point.dx).reduce(math.min);
    final maxX = points.map((point) => point.dx).reduce(math.max);
    final minY = points.map((point) => point.dy).reduce(math.min);
    final maxY = points.map((point) => point.dy).reduce(math.max);
    final columns = math.max(5, (maxX - minX + 3).ceil());
    final rows = math.max(5, (maxY - minY + 3).ceil());
    final cell = math.min(size.width / columns, size.height / rows);
    final origin = Offset(
      (size.width - (maxX - minX) * cell) / 2 - minX * cell,
      (size.height + (maxY - minY) * cell) / 2 + minY * cell,
    );
    Offset screen(Offset point) =>
        Offset(origin.dx + point.dx * cell, origin.dy - point.dy * cell);

    final grid = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final verifiedPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = accent
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var index = 1; index < points.length; index++) {
      canvas.drawLine(
        screen(points[index - 1]),
        screen(points[index]),
        index <= verifiedPrefixLength ? verifiedPaint : activePaint,
      );
    }
    final start = screen(points.first);
    final end = screen(points.last);
    canvas.drawCircle(start, 6, Paint()..color = color);
    canvas.drawCircle(end, 8, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _TouchRoutePainter oldDelegate) =>
      !_stringListsEqual(moves, oldDelegate.moves) ||
      verifiedPrefixLength != oldDelegate.verifiedPrefixLength ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;

  static bool _stringListsEqual(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
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

class _GeometryChoicePainter extends CustomPainter {
  const _GeometryChoicePainter({
    required this.operation,
    required this.index,
    this.label,
    required this.lineColor,
    required this.accentColor,
  });

  final String operation;
  final int index;
  final String? label;
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final accent = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    switch (operation) {
      case 'lines':
        _lines(canvas, size, line, accent);
      case 'angle':
        _angle(canvas, size, line);
      case 'figure':
        _figure(canvas, size, line, accent);
      case 'circle':
        _circle(canvas, size, line, accent);
      case 'basic-shape':
        _basicShape(canvas, size, line);
    }
  }

  void _lines(Canvas canvas, Size size, Paint line, Paint accent) {
    if (index == 0) {
      for (final y in [size.height * .38, size.height * .67]) {
        canvas.drawLine(Offset(size.width * .12, y), Offset(size.width * .88, y), line);
      }
      return;
    }
    if (index == 1) {
      final c = Offset(size.width / 2, size.height / 2);
      canvas.drawLine(Offset(size.width * .12, c.dy), Offset(size.width * .88, c.dy), line);
      canvas.drawLine(Offset(c.dx, size.height * .14), Offset(c.dx, size.height * .86), line);
      canvas.drawRect(Rect.fromLTWH(c.dx + 4, c.dy - 20, 16, 16), accent);
      return;
    }
    canvas.drawLine(Offset(size.width * .12, size.height * .72), Offset(size.width * .88, size.height * .30), line);
    canvas.drawLine(Offset(size.width * .12, size.height * .28), Offset(size.width * .88, size.height * .58), line);
  }

  void _angle(Canvas canvas, Size size, Paint line) {
    final o = Offset(size.width * .28, size.height * .76);
    canvas.drawLine(o, Offset(size.width * .86, o.dy), line);
    final safeIndex = index < 0 ? 0 : (index > 2 ? 2 : index);
    final degrees = [90.0, 45.0, 125.0][safeIndex];
    final rad = degrees * math.pi / 180;
    final length = size.shortestSide * .62;
    canvas.drawLine(o, Offset(o.dx + math.cos(rad) * length, o.dy - math.sin(rad) * length), line);
  }

  void _figure(Canvas canvas, Size size, Paint line, Paint accent) {
    final center = Offset(size.width / 2, size.height / 2);
    if (index == 0 || index == 1) {
      final rect = Rect.fromCenter(
        center: center,
        width: index == 0 ? 72 : 94,
        height: 72,
      );
      canvas.drawRect(rect, line);
      return;
    }
    final top = Offset(center.dx, size.height * .18);
    final left = Offset(index == 2 ? center.dx - 43 : center.dx - 50, size.height * .80);
    final right = Offset(index == 2 ? center.dx + 43 : center.dx + 32, size.height * .80);
    final path = Path()..moveTo(top.dx, top.dy)..lineTo(left.dx, left.dy)..lineTo(right.dx, right.dy)..close();
    canvas.drawPath(path, line);
    if (index == 2) {
      _tick(canvas, _mid(top, left), accent);
      _tick(canvas, _mid(top, right), accent);
      _tick(canvas, _mid(left, right), accent);
    } else {
      _tick(canvas, _mid(top, left), accent);
      _tick(canvas, _mid(top, right), accent);
    }
  }

  void _basicShape(Canvas canvas, Size size, Paint line) {
    final center = Offset(size.width / 2, size.height / 2);
    switch (label) {
      case 'Dreieck':
        final path = Path()
          ..moveTo(center.dx, size.height * .18)
          ..lineTo(size.width * .18, size.height * .82)
          ..lineTo(size.width * .82, size.height * .82)
          ..close();
        canvas.drawPath(path, line);
      case 'Quadrat':
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 72, height: 72),
          line,
        );
      case 'Rechteck':
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 98, height: 62),
          line,
        );
      case 'Kreis':
        canvas.drawCircle(center, size.shortestSide * .32, line);
      default:
        canvas.drawCircle(center, size.shortestSide * .12, line);
    }
  }

  void _circle(Canvas canvas, Size size, Paint line, Paint accent) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .34;
    canvas.drawCircle(center, radius, line);
    canvas.drawCircle(center, 4, Paint()..color = accentColor..style = PaintingStyle.fill);
    if (index == 0) {
      canvas.drawLine(center, Offset(center.dx + radius, center.dy), accent);
    } else if (index == 1) {
      canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), accent);
    } else {
      canvas.drawCircle(
        center,
        8,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  Offset _mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

  void _tick(Canvas canvas, Offset point, Paint paint) {
    canvas.drawLine(point.translate(-4, -4), point.translate(4, 4), paint);
  }

  @override
  bool shouldRepaint(covariant _GeometryChoicePainter oldDelegate) =>
      operation != oldDelegate.operation ||
      index != oldDelegate.index ||
      label != oldDelegate.label ||
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor;
}
