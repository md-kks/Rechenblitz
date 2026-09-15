import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/theme/app_theme.dart';
import 'package:rechenblitz/widgets/learning_visual_aid.dart';

void main() {
  const preferences = MethodPreferences();

  GuidedMethodGuide guide(TrainingMode mode, String key, int expected) =>
      GuidedMethodFactory.forTask(
        mode: mode,
        taskKey: key,
        expected: expected,
        preferences: preferences,
      );

  test('missing-number variants have dedicated guided methods', () {
    final cases = <(String, int)>[
      ('gap:+:7:5:b', 5),
      ('gap:+:5:7:a', 5),
      ('gap:-:12:5:b', 5),
      ('gap:-:12:5:a', 12),
    ];

    for (final entry in cases) {
      final result = guide(TrainingMode.missingNumber, entry.$1, entry.$2);
      expect(result.methodKey, isNot(startsWith('general:')));
      expect(result.steps.length, greaterThanOrEqualTo(2));
      expect(
        LearningVisualAid.canRender(
          pattern: ErrorPattern.inverseOperation,
          taskKey: entry.$1,
          methodKey: result.methodKey,
        ),
        isTrue,
      );
    }
  });

  test('other audited task families no longer use generic help', () {
    final cases = <(TrainingMode, String, int)>[
      (TrainingMode.neighbors, 'neighbor:7:before', 6),
      (TrainingMode.neighbors, 'neighbor:7:after', 8),
      (TrainingMode.placeValue, 'place:47', 47),
      (TrainingMode.geometry, 'geometry:name:square', 0),
      (TrainingMode.geometry, 'geometry:corners:triangle', 3),
      (TrainingMode.geometry, 'geometry:sides:rectangle', 4),
      (TrainingMode.romanNumerals, 'roman:write:45', 0),
      (TrainingMode.probability, 'prob:sure:below:9', 0),
      (TrainingMode.probability, 'prob:possible:face:3', 1),
      (TrainingMode.probability, 'prob:impossible:face:8', 2),
      (TrainingMode.probability, 'prob:experiment:relative:20:7', 0),
      (TrainingMode.geometryRelations, 'geomrel:lines:parallel:fourth', 0),
      (TrainingMode.geometryRelations, 'geomrel:circle:diameter:fourth', 1),
      (TrainingMode.geometryBodies, 'body:Würfel:Ecken', 8),
      (TrainingMode.geometryBodies, 'body:cube-net:faces', 6),
      (TrainingMode.symmetry, 'symmetry:Quadrat', 4),
      (TrainingMode.plansAndOrientation, 'plan:path:6:15', 21),
    ];

    for (final entry in cases) {
      final result = guide(entry.$1, entry.$2, entry.$3);
      expect(
        result.methodKey,
        isNot(startsWith('general:')),
        reason: '${entry.$1.name}: ${entry.$2}',
      );
    }
  });

  test('written division help handles tiny remainder choice domains', () {
    final result = guide(
      TrainingMode.writtenDivide,
      'written:divide:275970:3',
      91990,
    );
    final remainderStep = result.steps.firstWhere(
      (step) => step.evidenceKey == 'firstDivisionRemainder',
    );

    expect(result.methodKey, 'writtenDivision:standard');
    expect(remainderStep.choices, contains('0'));
    expect(remainderStep.choices.length, 3);
  });

  testWidgets('missing-number visual shows a concrete bridge path', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.inverseOperation,
            taskKey: 'gap:+:7:5:b',
            expected: 5,
            methodKey: 'missingNumber:add-complement',
          ),
        ),
      ),
    );

    expect(find.text('Lückenweg'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.textContaining('12 − 7 = 5'), findsOneWidget);
  });

  testWidgets('high contrast help visuals use theme contrast colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(highContrast: true),
        home: const Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.placeValue,
            taskKey: 'place:47',
            expected: 47,
          ),
        ),
      ),
    );

    final decorated = tester
        .widgetList<Container>(find.byType(Container))
        .where((container) {
          final decoration = container.decoration;
          return decoration is BoxDecoration && decoration.border != null;
        });
    expect(
      decorated.any((container) {
        final border =
            (container.decoration! as BoxDecoration).border! as Border;
        return border.top.color == Colors.black87;
      }),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(highContrast: true),
        home: const Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.tenBridge,
            taskKey: 'plus:+:7:5',
            expected: 12,
          ),
        ),
      ),
    );

    final customPaint = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .firstWhere(
          (paint) =>
              paint.painter?.runtimeType.toString() == '_NumberLinePainter',
        );
    final dynamic painter = customPaint.painter;
    expect(painter.lineColor, Colors.black87);
    expect(painter.accentColor, Colors.black);
  });

  test('number friends use decomposition help instead of ordinary plus help', () {
    final fact = MathFact(a: 6, b: 4, operation: MathOperation.plus);
    final result = GuidedMethodFactory.forTask(
      mode: TrainingMode.numberFriends,
      taskKey: fact.key,
      expected: 4,
      preferences: preferences,
      fact: fact,
    );

    expect(result.methodKey, 'numberFriends:decomposition');
    expect(result.nudge, contains('10 ist das Ganze'));
    expect(result.steps, hasLength(3));
    expect(result.steps[1].question, 'Welcher zweite Teil fehlt?');
    expect(
      result.steps[1].choices[result.steps[1].correctChoice!],
      '4',
    );
    expect(
      LearningVisualAid.canRender(
        pattern: ErrorPattern.numberBond,
        taskKey: fact.key,
        methodKey: result.methodKey,
      ),
      isTrue,
    );
  });

  test('visual help exists for early structural task families', () {
    const cases = <(ErrorPattern, String, String)>[
      (ErrorPattern.numberBond, 'double:6', 'doublesHalves:relationship'),
      (ErrorPattern.numberBond, 'half:12', 'doublesHalves:relationship'),
      (ErrorPattern.inverseOperation, 'family:+:7:5', 'inverse:operationRelationship'),
      (ErrorPattern.patternRule, 'sequence:+:4:2', 'sequence:constantStep'),
      (ErrorPattern.unitConversion, 'measure:add:ribbon:7:5', 'measure:calculationPlan'),
      (ErrorPattern.unitConversion, 'measure:subtract:rope:12:5', 'measure:calculationPlan'),
    ];

    for (final entry in cases) {
      expect(
        LearningVisualAid.canRender(
          pattern: entry.$1,
          taskKey: entry.$2,
          methodKey: entry.$3,
        ),
        isTrue,
        reason: entry.$2,
      );
    }
  });

  test('body property and cube-net help use distinct visuals', () {
    const bodies = <String>[
      'Würfel',
      'Quader',
      'Kugel',
      'Zylinder',
      'Kegel',
      'Pyramide',
    ];
    const properties = <String>['Ecken', 'Kanten', 'Flächen'];
    for (final body in bodies) {
      for (final property in properties) {
        expect(
          LearningVisualAid.canRender(
            pattern: ErrorPattern.spatialReasoning,
            taskKey: 'body:$body:$property',
            methodKey: 'geometryBodies:properties',
          ),
          isTrue,
          reason: '$body / $property',
        );
      }
    }
    expect(
      LearningVisualAid.canRender(
        pattern: ErrorPattern.spatialReasoning,
        taskKey: 'body:cube-net:faces',
        methodKey: 'geometryBodies:cube-net-basics',
      ),
      isTrue,
    );
  });

  testWidgets('all body property visuals render in two representations', (
    tester,
  ) async {
    const bodies = <String>[
      'Würfel',
      'Quader',
      'Kugel',
      'Zylinder',
      'Kegel',
      'Pyramide',
    ];
    const properties = <String>['Ecken', 'Kanten', 'Flächen'];
    for (final body in bodies) {
      for (final property in properties) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LearningVisualAid(
                  pattern: ErrorPattern.spatialReasoning,
                  taskKey: 'body:$body:$property',
                  expected: 0,
                  methodKey: 'geometryBodies:properties',
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(ValueKey('body-aid:$body:$property')),
          findsOneWidget,
          reason: '$body / $property',
        );
        expect(find.text('Körperansicht'), findsOneWidget);
        expect(
          find.text(property == 'Flächen'
              ? 'Flächen auseinandergelegt'
              : 'Zweite Ansicht'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: '$body / $property');
      }
    }
  });

  testWidgets('body property visual stays stable at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LearningVisualAid(
              pattern: ErrorPattern.spatialReasoning,
              taskKey: 'body:Pyramide:Flächen',
              expected: 5,
              methodKey: 'geometryBodies:properties',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('body-aid:Pyramide:Flächen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('number friend visual keeps the missing part unsolved', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.numberBond,
            taskKey: 'plus:6:4',
            expected: 4,
            methodKey: 'numberFriends:decomposition',
          ),
        ),
      ),
    );

    expect(find.text('Ganzes: 10'), findsOneWidget);
    expect(find.text('bekannter Teil: 6'), findsOneWidget);
    expect(find.text('fehlender Teil: ?'), findsOneWidget);
    expect(find.text('fehlender Teil: 4'), findsNothing);
    expect(find.text('6 + ? = 10'), findsOneWidget);
  });

  testWidgets('measure calculation visual is a length model, not a unit ladder',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.unitConversion,
            taskKey: 'measure:add:ribbon:7:5',
            expected: 12,
            methodKey: 'measure:calculationPlan',
          ),
        ),
      ),
    );

    expect(find.text('Längen aneinanderlegen'), findsOneWidget);
    expect(find.byKey(const ValueKey('help-measure-parts')), findsOneWidget);
    expect(find.text('zusammen: ? cm'), findsOneWidget);
  });

  test('visual help covers money clock and basic geometry', () {
    const cases = <(ErrorPattern, String, String)>[
      (ErrorPattern.moneyCalculation, 'money:change:kiosk:10:6', 'money:calculationPlan'),
      (ErrorPattern.clockReading, 'clock:7:45', 'clock:readHands'),
      (ErrorPattern.geometryProperty, 'geometry:corners:square', 'geometry:shape-properties'),
    ];
    for (final entry in cases) {
      expect(
        LearningVisualAid.canRender(
          pattern: entry.$1,
          taskKey: entry.$2,
          methodKey: entry.$3,
        ),
        isTrue,
        reason: entry.$2,
      );
    }
  });

  testWidgets('money visual keeps the requested amount unsolved', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.moneyCalculation,
            taskKey: 'money:change:kiosk:10:6',
            expected: 4,
            methodKey: 'money:calculationPlan',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-money-model')), findsOneWidget);
    expect(find.text('bezahlt'), findsOneWidget);
    expect(find.text('Preis'), findsOneWidget);
    expect(find.text('Rest: ? €'), findsOneWidget);
    expect(find.text('Rest: 4 €'), findsNothing);
  });

  testWidgets('clock visual teaches hand roles without printing target time', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.clockReading,
            taskKey: 'clock:7:45',
            expected: 3,
            methodKey: 'clock:readHands',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-clock-reference')), findsOneWidget);
    expect(find.text('langer Zeiger → Minuten'), findsOneWidget);
    expect(find.text('kurzer Zeiger → Stunden'), findsOneWidget);
    expect(find.textContaining('7:45'), findsNothing);
  });

  testWidgets('geometry visual marks feature types without giving the count', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.geometryProperty,
            taskKey: 'geometry:corners:square',
            expected: 4,
            methodKey: 'geometry:shape-properties',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-geometry-properties')), findsOneWidget);
    expect(find.byKey(const ValueKey('help-geometry-shape')), findsOneWidget);
    expect(find.text('Ecke = Treffpunkt'), findsOneWidget);
    expect(find.text('Seite = gerader Rand'), findsOneWidget);
    expect(find.textContaining('4 Ecken'), findsNothing);
  });

  testWidgets('money clock and geometry visuals stay stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const cases = <(ErrorPattern, String, int, String)>[
      (ErrorPattern.moneyCalculation, 'money:add:shop:7:5', 12, 'money:calculationPlan'),
      (ErrorPattern.clockReading, 'clock:3:30', 0, 'clock:readHands'),
      (ErrorPattern.geometryProperty, 'geometry:sides:triangle', 3, 'geometry:shape-properties'),
    ];
    for (final entry in cases) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningVisualAid(
                pattern: entry.$1,
                taskKey: entry.$2,
                expected: entry.$3,
                methodKey: entry.$4,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: entry.$2);
    }
  });

  test('visual help covers rounding estimation and roman numerals', () {
    const cases = <(ErrorPattern, String, String)>[
      (ErrorPattern.roundingPlace, 'round:347:100', 'rounding:place'),
      (ErrorPattern.estimation, 'estimate:347:181:100', 'estimation:roundedSummands'),
      (ErrorPattern.romanNumeral, 'roman:read:44', 'roman:tens-block'),
      (ErrorPattern.romanNumeral, 'roman:write:44', 'roman:compose'),
    ];
    for (final entry in cases) {
      expect(
        LearningVisualAid.canRender(
          pattern: entry.$1,
          taskKey: entry.$2,
          methodKey: entry.$3,
        ),
        isTrue,
        reason: entry.$2,
      );
    }
  });

  testWidgets('rounding visual shows anchors without stating the rounded result',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.roundingPlace,
            taskKey: 'round:347:100',
            expected: 300,
            methodKey: 'rounding:place',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-rounding-anchors')), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
    expect(find.text('Mitte\n350'), findsOneWidget);
    expect(find.text('347 ≈ 300'), findsNothing);
    expect(find.text('Das Ergebnis ist 300.'), findsNothing);
  });

  testWidgets('estimation visual keeps rounded summands and total unsolved',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.estimation,
            taskKey: 'estimate:347:181:100',
            expected: 500,
            methodKey: 'estimation:roundedSummands',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-estimation-anchors')), findsOneWidget);
    expect(find.text('1. Summand: 347'), findsOneWidget);
    expect(find.text('2. Summand: 181'), findsOneWidget);
    expect(find.textContaining('Überschlag: 500'), findsNothing);
    expect(find.text('347 ≈ 300'), findsNothing);
    expect(find.text('181 ≈ 200'), findsNothing);
  });

  testWidgets('roman visual teaches symbols without composing the target answer',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.romanNumeral,
            taskKey: 'roman:write:44',
            expected: 0,
            methodKey: 'roman:compose',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-roman-legend')), findsOneWidget);
    expect(find.text('I = 1'), findsOneWidget);
    expect(find.text('X = 10'), findsOneWidget);
    expect(find.text('XLIV'), findsNothing);
  });

  testWidgets('number-representation help stays stable at 200 percent text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const cases = <(ErrorPattern, String, int, String)>[
      (ErrorPattern.roundingPlace, 'round:347:100', 300, 'rounding:place'),
      (ErrorPattern.estimation, 'estimate:347:181:100', 500, 'estimation:roundedSummands'),
      (ErrorPattern.romanNumeral, 'roman:write:44', 0, 'roman:compose'),
    ];
    for (final entry in cases) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningVisualAid(
                pattern: entry.$1,
                taskKey: entry.$2,
                expected: entry.$3,
                methodKey: entry.$4,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: entry.$2);
    }
  });

  test('visual help covers data probability and combinatorics', () {
    const cases = <(ErrorPattern, String, String)>[
      (ErrorPattern.dataReading, 'data:max:4-7-3-6', 'data:read-chart-values'),
      (ErrorPattern.dataReading, 'data:tally:17', 'data:tally-five-blocks'),
      (ErrorPattern.probabilityReasoning, 'prob:sure:below:8', 'probability:sample-space'),
      (ErrorPattern.probabilityReasoning, 'prob:bag:kugeln:5:3', 'probability:count-relation'),
      (ErrorPattern.combinatorics, 'combo:clothes:3:2:2', 'combinatorics:first-branch'),
    ];
    for (final entry in cases) {
      expect(
        LearningVisualAid.canRender(
          pattern: entry.$1,
          taskKey: entry.$2,
          methodKey: entry.$3,
        ),
        isTrue,
        reason: entry.$2,
      );
    }
  });

  testWidgets('data chart visual teaches reading without printing bar values', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.dataReading,
            taskKey: 'data:sum:4-7-3-6',
            expected: 20,
            methodKey: 'data:read-chart-values',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-data-chart')), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('7'), findsNothing);
    expect(find.text('20'), findsNothing);
    expect(find.textContaining('Addiert wird erst danach'), findsOneWidget);
  });

  testWidgets('probability visuals expose structure but not the final judgement', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.probabilityReasoning,
            taskKey: 'prob:sure:below:8',
            expected: 0,
            methodKey: 'probability:sample-space',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-probability-sample-space')), findsOneWidget);
    for (var face = 1; face <= 6; face++) {
      expect(find.text('$face'), findsOneWidget);
    }
    expect(find.text('sicher'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.probabilityReasoning,
            taskKey: 'prob:experiment:relative:20:7',
            expected: 1,
            methodKey: 'probability:relative-frequency',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-probability-relative')), findsOneWidget);
    expect(find.text('7 / 20   =   ? / 100'), findsOneWidget);
    expect(find.textContaining('35 %'), findsNothing);
    expect(find.byKey(const ValueKey('help-relative-hundred-grid')), findsOneWidget);
  });

  testWidgets('combinatorics visual completes one branch without total answer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.combinatorics,
            taskKey: 'combo:clothes:3:2:2',
            expected: 12,
            methodKey: 'combinatorics:first-branch',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-combinatorics-branch')), findsOneWidget);
    expect(find.text('1 T-Shirt fest'), findsOneWidget);
    expect(find.textContaining('Hose 1 + Mütze 1'), findsOneWidget);
    expect(find.text('12'), findsNothing);
  });

  testWidgets('data probability and combinatorics visuals stay stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    for (final config in <(ErrorPattern, String, int, String)>[
      (ErrorPattern.dataReading, 'data:diff:9-5-4-7', 4, 'data:read-chart-values'),
      (ErrorPattern.probabilityReasoning, 'prob:bag:kugeln:7:4', 0, 'probability:count-relation'),
      (ErrorPattern.combinatorics, 'combo:icecream:3:2:2', 12, 'combinatorics:first-branch'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningVisualAid(
                pattern: config.$1,
                taskKey: config.$2,
                expected: config.$3,
                methodKey: config.$4,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: config.$2);
    }
  });


  test('mega visual help batch covers remaining structural families', () {
    const cases = <(ErrorPattern, String, String)>[
      (ErrorPattern.numberRelations, 'wall:2-3-4-5-7-12:1', 'numberWall:relationDirection'),
      (ErrorPattern.divisionFact, 'divide:24:6', 'division:inverseMultiplication'),
      (ErrorPattern.mentalStrategy, 'mental:+:47:36', 'mental:placeChunks'),
      (ErrorPattern.arithmeticLaw, 'law:distribute:7:38', 'arithmeticLaws:structure'),
      (ErrorPattern.arithmeticLaw, 'process:reasoning:compensate:27:35:2', 'reasoning:relation'),
      (ErrorPattern.proportionalReasoning, 'proportion:notebooks:4:3:7', 'proportion:unitValue'),
      (ErrorPattern.symmetry, 'symmetry:Quadrat', 'symmetry:systematic-axes'),
      (ErrorPattern.planScale, 'plan:scale:100:4', 'scale:operation-choice'),
      (ErrorPattern.volume, 'volume:4:3:2', 'volume:single-layer'),
      (ErrorPattern.unknown, 'geomrel:lines:parallel:fourth', 'geometry:line-relation'),
    ];
    for (final entry in cases) {
      expect(
        LearningVisualAid.canRender(
          pattern: entry.$1,
          taskKey: entry.$2,
          methodKey: entry.$3,
        ),
        isTrue,
        reason: entry.$2,
      );
    }
  });

  testWidgets('number wall visual hides exactly the missing stone', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LearningVisualAid(
      pattern: ErrorPattern.numberRelations,
      taskKey: 'wall:2-3-4-5-7-12:1',
      expected: 3,
      methodKey: 'numberWall:relationDirection',
    ))));
    expect(find.byKey(const ValueKey('help-number-wall')), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    expect(find.byKey(const ValueKey('help-wall-stone-1')), findsOneWidget);
  });

  testWidgets('division and mental visuals stop before the final result', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LearningVisualAid(
      pattern: ErrorPattern.divisionFact,
      taskKey: 'divide:24:6',
      expected: 4,
      methodKey: 'division:inverseMultiplication',
    ))));
    expect(find.text('6'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('?'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LearningVisualAid(
      pattern: ErrorPattern.mentalStrategy,
      taskKey: 'mental:+:47:36',
      expected: 83,
      methodKey: 'mental:placeChunks',
    ))));
    expect(find.byKey(const ValueKey('help-mental-chunks')), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('83'), findsNothing);
  });

  testWidgets('law and reasoning visuals show structure without final answer', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LearningVisualAid(
      pattern: ErrorPattern.arithmeticLaw,
      taskKey: 'law:distribute:7:38',
      expected: 14,
      methodKey: 'arithmeticLaws:structure',
    ))));
    expect(find.byKey(const ValueKey('help-law-distribute')), findsOneWidget);
    expect(find.textContaining('7 × 38'), findsOneWidget);
    expect(find.text('14'), findsNothing);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LearningVisualAid(
      pattern: ErrorPattern.arithmeticLaw,
      taskKey: 'process:reasoning:commute:6:8',
      expected: 0,
      methodKey: 'reasoning:relation',
    ))));
    expect(find.byKey(const ValueKey('help-reasoning-structure')), findsOneWidget);
    expect(find.text('Was verändert sich?'), findsOneWidget);
  });

  testWidgets('proportion scale and volume keep requested totals open', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Column(children: [
      LearningVisualAid(pattern: ErrorPattern.proportionalReasoning, taskKey: 'proportion:notebooks:4:3:7', expected: 28, methodKey: 'proportion:unitValue'),
      LearningVisualAid(pattern: ErrorPattern.planScale, taskKey: 'plan:scale:100:4', expected: 400, methodKey: 'scale:operation-choice'),
      LearningVisualAid(pattern: ErrorPattern.volume, taskKey: 'volume:4:3:2', expected: 24, methodKey: 'volume:single-layer'),
    ])))));
    expect(find.byKey(const ValueKey('help-proportion-unit')), findsOneWidget);
    expect(find.text('7 Einheiten = ? €'), findsOneWidget);
    expect(find.text('28'), findsNothing);
    expect(find.byKey(const ValueKey('help-plan-scale')), findsOneWidget);
    expect(find.text('Gesamt: ? m'), findsOneWidget);
    expect(find.text('400'), findsNothing);
    expect(find.byKey(const ValueKey('help-volume-layers')), findsOneWidget);
    expect(find.text('alle Würfel zusammen: ?'), findsOneWidget);
    expect(find.text('24'), findsNothing);
  });

  testWidgets('symmetry and geometry relation help teach reference concepts', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Column(children: [
      LearningVisualAid(pattern: ErrorPattern.symmetry, taskKey: 'symmetry:Quadrat', expected: 4, methodKey: 'symmetry:systematic-axes'),
      LearningVisualAid(pattern: ErrorPattern.unknown, taskKey: 'geomrel:lines:parallel:fourth', expected: 0, methodKey: 'geometry:line-relation'),
      LearningVisualAid(pattern: ErrorPattern.unknown, taskKey: 'geomrel:circle:radius:fourth', expected: 0, methodKey: 'geometry:circle-parts'),
    ])))));
    expect(find.byKey(const ValueKey('help-symmetry-axis')), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.byKey(const ValueKey('help-geomrel-lines')), findsOneWidget);
    expect(find.byKey(const ValueKey('help-geomrel-circle')), findsOneWidget);
  });

  testWidgets('mega visual help batch stays stable at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    const cases = <(ErrorPattern, String, int, String)>[
      (ErrorPattern.numberRelations, 'wall:2-3-4-5-7-12:1', 3, 'numberWall:relationDirection'),
      (ErrorPattern.divisionFact, 'divide:24:6', 4, 'division:inverseMultiplication'),
      (ErrorPattern.mentalStrategy, 'mental:+:47:36', 83, 'mental:placeChunks'),
      (ErrorPattern.arithmeticLaw, 'law:associate:40:27:60', 0, 'arithmeticLaws:structure'),
      (ErrorPattern.proportionalReasoning, 'proportion:notebooks:4:3:7', 28, 'proportion:unitValue'),
      (ErrorPattern.symmetry, 'symmetry:Quadrat', 4, 'symmetry:systematic-axes'),
      (ErrorPattern.planScale, 'plan:scale:100:4', 400, 'scale:operation-choice'),
      (ErrorPattern.volume, 'volume:4:3:2', 24, 'volume:single-layer'),
      (ErrorPattern.unknown, 'geomrel:angle:right:paper:fourth', 0, 'geometry:right-angle-reference'),
    ];
    for (final entry in cases) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: LearningVisualAid(
        pattern: entry.$1, taskKey: entry.$2, expected: entry.$3, methodKey: entry.$4,
      )))));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: entry.$2);
    }
  });


  test('large-number and cube-net help use task-specific visuals', () {
    const cases = <(ErrorPattern, String, String)>[
      (ErrorPattern.placeValue, 'large:order:1200-1300-2200', 'largeNumbers:order'),
      (ErrorPattern.placeValue, 'large:word:read:3047', 'largeNumbers:numberWord'),
      (ErrorPattern.placeValue, 'large:decompose:3047', 'largeNumbers:decompose'),
      (ErrorPattern.spatialReasoning, 'body:cube-net:faces', 'geometryBodies:cube-net-basics'),
    ];
    for (final entry in cases) {
      expect(LearningVisualAid.canRender(pattern: entry.$1, taskKey: entry.$2, methodKey: entry.$3), isTrue, reason: entry.$2);
    }
  });

  testWidgets('large-number visuals preserve unsolved ordering and word reading', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Column(children: [
      LearningVisualAid(pattern: ErrorPattern.placeValue, taskKey: 'large:order:1200-1300-2200', expected: 0, methodKey: 'largeNumbers:order'),
      LearningVisualAid(pattern: ErrorPattern.placeValue, taskKey: 'large:word:read:3047', expected: 0, methodKey: 'largeNumbers:numberWord'),
    ])))));
    expect(find.byKey(const ValueKey('help-large-order')), findsOneWidget);
    expect(find.textContaining('Noch nicht sortieren'), findsOneWidget);
    expect(find.byKey(const ValueKey('help-large-word-structure')), findsOneWidget);
    expect(find.text('3.047'), findsNothing);
  });

  testWidgets('cube-net visual teaches folding without judging the task', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LearningVisualAid(
      pattern: ErrorPattern.spatialReasoning,
      taskKey: 'body:cube-net:fold:yes:local:demo:net',
      expected: 0,
      methodKey: 'geometryBodies:cube-net-basics',
    ))));
    expect(find.byKey(const ValueKey('help-cube-net-fold')), findsOneWidget);
    expect(find.textContaining('nicht die Lösung'), findsOneWidget);
    expect(find.textContaining('Ja'), findsNothing);
    expect(find.textContaining('Nein'), findsNothing);
  });

  test('generated structured and upper-primary tasks have specific help', () {
    final structured = StructuredExerciseGenerator(random: Random(17));
    final curriculum = CurriculumExerciseGenerator(random: Random(23));

    for (final mode in TrainingMode.values.where((mode) => mode.isStructured)) {
      for (var i = 0; i < 24; i++) {
        final exercise = structured.generate(
          mode: mode,
          maxValue: 100,
          gradeLevel: GradeLevel.second,
        );
        final result = guide(mode, exercise.key, exercise.answer);
        expect(
          result.methodKey,
          isNot(startsWith('general:')),
          reason: '${mode.name}: ${exercise.key}',
        );
      }
    }

    for (final mode in TrainingMode.values.where(
      (mode) => mode.isUpperPrimary,
    )) {
      for (var i = 0; i < 24; i++) {
        final exercise = curriculum.generate(
          mode: mode,
          gradeLevel: GradeLevel.fourth,
          maxValue: 1000000,
        );
        final result = guide(mode, exercise.key, exercise.answer);
        expect(
          result.methodKey,
          isNot(startsWith('general:')),
          reason: '${mode.name}: ${exercise.key}',
        );
      }
    }
  });

  testWidgets('direct addition visual keeps the result unsolved', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.countingStep,
            taskKey: 'plus:3:4',
            expected: 7,
            methodKey: 'addition:direct',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('help-addition-direct')), findsOneWidget);
    expect(find.text('Start: 3'), findsOneWidget);
    expect(find.text('+4'), findsOneWidget);
    expect(find.text('Ziel: ?'), findsOneWidget);
    expect(find.text('Ziel: 7'), findsNothing);
  });

  testWidgets('story calculation visual keeps all four results unsolved', (tester) async {
    const cases = <(String, String)>[
      ('story:calc:+:8:7', '+'),
      ('story:calc:-:15:6', '−'),
      ('story:calc:x:4:6', '×'),
      ('story:calc:divide:24:4', '÷'),
    ];
    for (final entry in cases) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningVisualAid(
              pattern: ErrorPattern.countingStep,
              taskKey: entry.$1,
              expected: 999,
              methodKey: 'wordProblem:meaning',
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('help-story-calculation')), findsOneWidget);
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
      expect(find.text('999'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });


}
