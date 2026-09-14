import 'package:flutter/material.dart';
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
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-roman-read-step-submit')));
    await tester.pump();
    expect(find.text('Dieser Blockwert passt noch nicht.'), findsOneWidget);
    expect(find.text('Welchen Wert hat der Block XL?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('touch-roman-read-value-40')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('touch-roman-read-step-submit')));
    await tester.pump();
    expect(find.text('Welchen Wert hat der Block IV?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('touch-roman-read-value-4')));
    await tester.pump();
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
