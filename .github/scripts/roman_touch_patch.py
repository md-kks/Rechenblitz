from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one marker, found {count}")
    return text.replace(old, new, 1)


model = Path("lib/models/touch_interaction.dart")
s = model.read_text()
s = replace_once(
    s,
    "  arithmeticLawStructure,\n  writtenColumnProcedure,",
    "  arithmeticLawStructure,\n  romanNumeralReader,\n  romanNumeralBuilder,\n  writtenColumnProcedure,",
    "roman enum",
)
planner_marker = """    if (mode == TrainingMode.writtenMultiply &&
        taskKey.startsWith('written:x:')) {
"""
planner = r"""    if (mode == TrainingMode.romanNumerals && taskKey.startsWith('roman:')) {
      final parts = taskKey.split(':');
      final value = parts.length >= 3 ? int.tryParse(parts[2]) : null;
      if (value != null && value >= 1 && value <= 100) {
        final roman = _romanText(value);
        if (parts[1] == 'read') {
          final tokens = _romanTokens(value);
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.romanNumeralReader,
            instruction: targetCompetency == MicroCompetencyId.romanNumeral
                ? 'Der Zehnerblock wurde schon geprüft. Bestimme jetzt den Gesamtwert der römischen Zahl.'
                : 'Lies die römische Zahl blockweise. Bestimme erst die Werte der Blöcke und danach den Gesamtwert.',
            dataLabels: tokens.map((entry) => entry.$1).toList(growable: false),
            dataValues: tokens.map((entry) => entry.$2).toList(growable: false),
            dataOperation: targetCompetency == MicroCompetencyId.romanNumeral
                ? 'read-total'
                : 'read-groups',
            unitLabel: roman,
            expectedAnswer: answer,
            maxValue: max(maxValue, value),
          );
        }
        if (parts[1] == 'write' && choices != null && choices.isNotEmpty) {
          return TouchInteractionPlan(
            taskKey: taskKey,
            kind: TouchInteractionKind.romanNumeralBuilder,
            instruction:
                'Baue die römische Zahl selbst aus I, V, X, L und C. Achte besonders auf IV, IX, XL und XC.',
            dataValues: <int>[value],
            dataLabels: roman.split(''),
            answerChoices: choices,
            unitLabel: roman,
            expectedAnswer: answer,
            maxValue: maxValue,
          );
        }
      }
    }

"""
s = replace_once(s, planner_marker, planner + planner_marker, "roman planner")
helper_marker = "  static int _missingNumberStart(List<String> parts, int answer) {\n"
helpers = r"""  static String _romanText(int value) {
    var rest = value;
    final out = StringBuffer();
    const values = <int>[100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = <String>['C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    for (var i = 0; i < values.length; i++) {
      while (rest >= values[i]) {
        out.write(symbols[i]);
        rest -= values[i];
      }
    }
    return out.toString();
  }

  static List<(String, int)> _romanTokens(int value) {
    var rest = value;
    final out = <(String, int)>[];
    const values = <int>[100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = <String>['C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    for (var i = 0; i < values.length; i++) {
      while (rest >= values[i]) {
        out.add((symbols[i], values[i]));
        rest -= values[i];
      }
    }
    return out;
  }

"""
s = replace_once(s, helper_marker, helpers + helper_marker, "roman helpers")
model.write_text(s)

widget = Path("lib/widgets/touch_answer_interaction.dart")
s = widget.read_text()
s = replace_once(
    s,
    "  int? selectedLawGap;\n  int writtenColumnIndex = 0;",
    "  int? selectedLawGap;\n  int romanReadIndex = 0;\n  int? selectedRomanBlockValue;\n  String romanReadFeedback = '';\n  final List<String> romanBuiltSymbols = <String>[];\n  int writtenColumnIndex = 0;",
    "roman state",
)
s = replace_once(
    s,
    "    selectedLawGap = null;\n    if (widget.plan.kind == TouchInteractionKind.largeNumberDecompose",
    "    selectedLawGap = null;\n    romanReadIndex = 0;\n    selectedRomanBlockValue = null;\n    romanReadFeedback = '';\n    romanBuiltSymbols.clear();\n    if (widget.plan.kind == TouchInteractionKind.largeNumberDecompose",
    "roman reset",
)
s = replace_once(
    s,
    "            TouchInteractionKind.arithmeticLawStructure =>\n              _buildArithmeticLawStructure(context),\n            TouchInteractionKind.writtenColumnProcedure =>",
    "            TouchInteractionKind.arithmeticLawStructure =>\n              _buildArithmeticLawStructure(context),\n            TouchInteractionKind.romanNumeralReader =>\n              _buildRomanNumeralReader(context),\n            TouchInteractionKind.romanNumeralBuilder =>\n              _buildRomanNumeralBuilder(context),\n            TouchInteractionKind.writtenColumnProcedure =>",
    "roman switch",
)
method_marker = "  Widget _buildMentalChunkPath(BuildContext context) {\n"
methods = r"""  Widget _buildRomanNumeralReader(BuildContext context) {
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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

"""
s = replace_once(s, method_marker, methods + method_marker, "roman widget methods")
widget.write_text(s)

test = Path("test/roman_touch_interaction_test.dart")
test.write_text(r"""import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/widgets/touch_answer_interaction.dart';

void main() {
  test('roman planner separates reading blocks and canonical writing', () {
    final read = TouchInteractionPlan.forTask(
      mode: TrainingMode.romanNumerals,
      taskKey: 'roman:read:44',
      answer: 44,
      maxValue: 100,
    );
    expect(read?.kind, TouchInteractionKind.romanNumeralReader);
    expect(read?.dataLabels, <String>['XL', 'IV']);
    expect(read?.dataValues, <int>[40, 4]);
    expect(read?.dataOperation, 'read-groups');

    final targeted = TouchInteractionPlan.forTask(
      mode: TrainingMode.romanNumerals,
      taskKey: 'roman:read:44',
      answer: 44,
      maxValue: 100,
      targetCompetency: MicroCompetencyId.romanNumeral,
    );
    expect(targeted?.dataOperation, 'read-total');

    final write = TouchInteractionPlan.forTask(
      mode: TrainingMode.romanNumerals,
      taskKey: 'roman:write:49',
      answer: 0,
      maxValue: 100,
      choices: const <String>['XLIX', 'IL', 'XXXXIX', 'L'],
    );
    expect(write?.kind, TouchInteractionKind.romanNumeralBuilder);
    expect(write?.dataLabels.join(), 'XLIX');
  });

  testWidgets('roman reader checks XL and IV before total', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'roman:read:44',
      kind: TouchInteractionKind.romanNumeralReader,
      instruction: 'Lies blockweise.',
      dataLabels: <String>['XL', 'IV'],
      dataValues: <int>[40, 4],
      dataOperation: 'read-groups',
      unitLabel: 'XLIV',
      expectedAnswer: 44,
      maxValue: 100,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('XLIV'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-roman-read-value-50')));
    await tester.tap(find.byKey(const ValueKey('touch-roman-read-step-submit')));
    await tester.pump();
    expect(find.text('Dieser Blockwert passt noch nicht.'), findsOneWidget);
    expect(find.text('Welchen Wert hat der Block XL?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-roman-read-value-40')));
    await tester.tap(find.byKey(const ValueKey('touch-roman-read-step-submit')));
    await tester.pump();
    expect(find.text('Welchen Wert hat der Block IV?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-roman-read-value-4')));
    await tester.tap(find.byKey(const ValueKey('touch-roman-read-step-submit')));
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-roman-read-total-pad')), findsOneWidget);

    for (final label in <String>['4', '4', 'OK']) {
      await tester.tap(find.widgetWithText(FilledButton, label));
      await tester.pump();
    }
    expect(answer, 44);
  });

  testWidgets('targeted roman reading does not repeat tens-block diagnosis', (tester) async {
    const plan = TouchInteractionPlan(
      taskKey: 'roman:read:44',
      kind: TouchInteractionKind.romanNumeralReader,
      instruction: 'Bestimme den Gesamtwert.',
      dataLabels: <String>['XL', 'IV'],
      dataValues: <int>[40, 4],
      dataOperation: 'read-total',
      unitLabel: 'XLIV',
      expectedAnswer: 44,
      maxValue: 100,
    );
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TouchAnswerInteraction(plan: plan, onAnswer: _noop),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('touch-roman-read-total-pad')), findsOneWidget);
    expect(find.byKey(const ValueKey('touch-roman-read-step-submit')), findsNothing);
  });

  testWidgets('roman builder composes canonical subtractive notation', (tester) async {
    var answer = -1;
    const plan = TouchInteractionPlan(
      taskKey: 'roman:write:49',
      kind: TouchInteractionKind.romanNumeralBuilder,
      instruction: 'Baue die römische Zahl.',
      dataValues: <int>[49],
      dataLabels: <String>['X', 'L', 'I', 'X'],
      answerChoices: <String>['XLIX', 'IL', 'XXXXIX', 'L'],
      expectedAnswer: 0,
      maxValue: 100,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TouchAnswerInteraction(plan: plan, onAnswer: (value) => answer = value),
        ),
      ),
    ));
    await tester.pump();
    for (final symbol in <String>['X', 'L', 'I', 'X']) {
      await tester.tap(find.byKey(ValueKey('touch-roman-symbol-$symbol')));
      await tester.pump();
    }
    expect(find.text('XLIX'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-roman-build-submit')));
    expect(answer, 0);
  });

  testWidgets('roman touch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const plan = TouchInteractionPlan(
      taskKey: 'roman:write:88',
      kind: TouchInteractionKind.romanNumeralBuilder,
      instruction: 'Baue die römische Zahl.',
      dataValues: <int>[88],
      dataLabels: <String>['L', 'X', 'X', 'X', 'V', 'I', 'I', 'I'],
      answerChoices: <String>['LXXXVIII', 'XXCVIII', 'LXXXII', 'VIII'],
      expectedAnswer: 0,
      maxValue: 100,
    );
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TouchAnswerInteraction(plan: plan, onAnswer: _noop),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('touch-roman-build-display')), findsOneWidget);
  });
}

void _noop(int value) {}
""")
