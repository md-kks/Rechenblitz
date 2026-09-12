import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
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
