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

  test('body property help has a visual without hijacking cube-net tasks', () {
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
      isFalse,
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
}
