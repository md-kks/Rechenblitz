import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/guided_method.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Schulmethode bleibt bei geführtem Minus verbindlich', () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.bridgeToTen,
      selectionPreference: MethodSelectionPreference.schoolMethod,
    );
    final fact = MathFact(
      a: 13,
      b: 5,
      operation: MathOperation.minus,
    );

    final guide = GuidedMethodFactory.forTask(
      mode: TrainingMode.minus,
      taskKey: fact.key,
      expected: 8,
      preferences: preferences,
      fact: fact,
    );

    expect(guide.methodKey, 'subtraction:bridgeToTen');
    expect(guide.methodLabel, 'Erst zum Zehner');
    expect(guide.steps.length, greaterThanOrEqualTo(3));
    expect(guide.steps.where((step) => step.isInteractive), isNotEmpty);
  });

  test('Automatisch vergleicht Methoden ohne gespeicherte Schulmethode zu ändern',
      () {
    const preferences = MethodPreferences(
      subtraction: SubtractionStrategy.complement,
      selectionPreference: MethodSelectionPreference.automatic,
    );
    final selected =
        preferences.effectiveSubtraction(taskKey: 'minus:13:5');

    expect(SubtractionStrategy.values, contains(selected));
    expect(preferences.subtraction, SubtractionStrategy.complement);
    expect(
      preferences.selectionPreference,
      MethodSelectionPreference.automatic,
    );
  });

  test('Hilfestufen gewichten Mikro-Evidenz abgestuft', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    final fact1 = MathFact(a: 13, b: 5, operation: MathOperation.minus);
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: fact1.key,
      expected: 8,
      actual: 8,
      fact: fact1,
      helpLevel: HelpLevel.none.value,
      methodKey: 'subtraction:bridgeToTen',
    );
    final noHelp = controller.microObservations.firstWhere(
      (entry) => entry.id == MicroCompetencyId.subtractionTenBridge,
    );

    final fact2 = MathFact(a: 14, b: 6, operation: MathOperation.minus);
    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: fact2.key,
      expected: 8,
      actual: 8,
      fact: fact2,
      helpLevel: HelpLevel.guided.value,
      methodKey: 'subtraction:bridgeToTen',
    );
    final guided = controller.microObservations.firstWhere(
      (entry) =>
          entry.id == MicroCompetencyId.subtractionTenBridge &&
          entry.taskKey == fact2.key,
    );

    expect(noHelp.evidenceWeight, closeTo(1.0, 0.001));
    expect(guided.evidenceWeight, closeTo(0.50, 0.001));
    expect(guided.helpLevel, 3);
    expect(guided.methodKey, 'subtraction:bridgeToTen');
  });

  test('Methodenbeobachtung ändert Schulmethode nicht', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.methodPreferences = const MethodPreferences(
      subtraction: SubtractionStrategy.complement,
      selectionPreference: MethodSelectionPreference.automatic,
    );

    controller.microObservations = List.generate(
      4,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        occurredAt: DateTime(2026, 9, 5, 10, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        helpLevel: 0,
        methodKey: 'subtraction:bridgeToTen',
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:${13 + index}:5',
      ),
    );

    final insight = controller.methodSupportInsight(
      MicroCompetencyId.subtractionTenBridge,
    );

    expect(insight, contains('Erst zum Zehner'));
    expect(
      controller.methodPreferences.subtraction,
      SubtractionStrategy.complement,
    );
  });
}
