import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/teacher_assignment.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/method_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/widgets/learning_visual_aid.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('alte Rechenweg-Einstellungen erhalten sicheren Additionsstandard', () {
    final restored = MethodPreferences.fromJson(<String, dynamic>{
      'subtraction': SubtractionStrategy.complement.name,
      'multiplication': MultiplicationStrategy.decompose.name,
      'writtenSubtraction': WrittenSubtractionStrategy.complement.name,
      'selectionPreference': MethodSelectionPreference.schoolMethod.name,
    });

    expect(restored.addition, AdditionStrategy.bridgeToTen);
    expect(restored.subtraction, SubtractionStrategy.complement);
  });

  test('Additionsstrategie round-tript durch Profil- und QR-Daten', () {
    const methods = MethodPreferences(
      addition: AdditionStrategy.compensate,
      subtraction: SubtractionStrategy.takeAway,
    );
    final decoded = MethodPreferences.fromJson(
      jsonDecode(jsonEncode(methods.toJson())) as Map<String, dynamic>,
    );
    expect(decoded.addition, AdditionStrategy.compensate);

    const assignment = TeacherAssignment(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      mode: TrainingMode.practice,
      tasks: 5,
      methods: methods,
    );
    final parsed = TeacherAssignment.tryParse(assignment.toPayload());
    expect(parsed, isNotNull);
    expect(parsed!.methods.addition, AdditionStrategy.compensate);
  });

  test('Runden und ausgleichen bildet eine echte Hilfsaufgabe', () {
    final fact = MathFact(a: 47, b: 18, operation: MathOperation.plus);
    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.practice,
      taskKey: fact.key,
      expected: fact.result,
      preferences: const MethodPreferences(
        addition: AdditionStrategy.compensate,
      ),
      fact: fact,
    );

    expect(guide.methodKey, 'addition:compensate');
    expect(guide.methodLabel, 'Runden & ausgleichen');
    expect(guide.nudge, contains('+20'));
    expect(guide.steps, hasLength(3));
    expect(guide.steps[0].question, 'Wie viel ist 47 + 20?');
    expect(guide.steps[0].choices[guide.steps[0].correctChoice!], '67');
    expect(guide.steps[1].choices[guide.steps[1].correctChoice!], '2');
    expect(guide.steps[2].choices[guide.steps[2].correctChoice!], '65');
  });

  test('Plus über den Zehner bietet beide Rechenwege in der Hilfe', () {
    final fact = MathFact(a: 47, b: 18, operation: MathOperation.plus);
    const preferences = MethodPreferences(
      addition: AdditionStrategy.compensate,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );

    final alternatives = GuidedMethodFactory.alternativesForTask(
      mode: TrainingMode.practice,
      taskKey: fact.key,
      expected: fact.result,
      preferences: preferences,
      fact: fact,
    );

    expect(alternatives.map((guide) => guide.methodLabel).toSet(), <String>{
      'Erst zum Zehner',
      'Runden & ausgleichen',
    });
    expect(preferences.addition, AdditionStrategy.compensate);
  });

  test(
    'Automatik bleibt bei Plus über den Zehner beim sicheren Zehnerstopp',
    () {
      final fact = MathFact(a: 47, b: 18, operation: MathOperation.plus);
      final guide = GuidedMethodFactory.forTask(
        mode: TrainingMode.practice,
        taskKey: fact.key,
        expected: fact.result,
        preferences: const MethodPreferences(
          addition: AdditionStrategy.compensate,
          selectionPreference: MethodSelectionPreference.automatic,
        ),
        fact: fact,
      );

      expect(guide.methodKey, 'addition:bridgeToTen');
    },
  );

  testWidgets('Kompensationshilfe zeigt Hilfssumme und Ausgleich sichtbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningVisualAid(
            pattern: ErrorPattern.tenBridge,
            taskKey: 'plus:47:18',
            expected: 65,
            methodKey: 'addition:compensate',
          ),
        ),
      ),
    );

    expect(find.text('Runden & ausgleichen'), findsOneWidget);
    expect(find.text('Hilfssumme'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('−2'), findsOneWidget);
    expect(find.textContaining('47 + 18 = 67 − 2 = 65'), findsOneWidget);
  });

  test('Controller speichert Additionsmethode profilbezogen', () async {
    final controller = AppController();
    await controller.load();

    await controller.setAdditionStrategy(AdditionStrategy.compensate);
    expect(controller.methodPreferences.addition, AdditionStrategy.compensate);

    final reloaded = AppController();
    await reloaded.load();
    expect(reloaded.methodPreferences.addition, AdditionStrategy.compensate);
  });

  testWidgets('Methodenansicht bietet Addition über den Zehner an', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: MethodScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.text('Addition über den Zehner'), findsOneWidget);
    final dropdown = find.byKey(const ValueKey('method-addition-strategy'));
    expect(dropdown, findsOneWidget);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Runden & ausgleichen').last);
    await tester.pumpAndSettle();

    expect(controller.methodPreferences.addition, AdditionStrategy.compensate);
  });
}
