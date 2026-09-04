import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/teacher_assignment.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Lehrerauftrag ist PII-freier Roundtrip', () {
    const assignment = TeacherAssignment(
      gradeLevel: GradeLevel.third,
      numberRange: NumberRangeLevel.thousand,
      mode: TrainingMode.wordProblems,
      tasks: 12,
      targetCompetency: MicroCompetencyId.wordProblemCalculation,
      transferEmphasis: true,
      methods: MethodPreferences(
        subtraction: SubtractionStrategy.bridgeToTen,
        multiplication: MultiplicationStrategy.decompose,
      ),
    );

    final payload = assignment.toPayload();
    final parsed = TeacherAssignment.tryParse(payload);

    expect(payload, startsWith(TeacherAssignment.prefix));
    expect(payload, isNot(contains('Michael')));
    expect(payload, isNot(contains('profile')));
    expect(payload, isNot(contains('name')));
    expect(parsed, isNotNull);
    expect(parsed!.gradeLevel, GradeLevel.third);
    expect(parsed.numberRange, NumberRangeLevel.thousand);
    expect(parsed.tasks, 12);
    expect(parsed.targetCompetency,
        MicroCompetencyId.wordProblemCalculation);
    expect(parsed.transferEmphasis, isTrue);
    expect(
      parsed.methods.multiplication,
      MultiplicationStrategy.decompose,
    );
  });

  test('Ungültiger Lehrerauftrag wird abgelehnt', () {
    expect(TeacherAssignment.tryParse('kein-auftrag'), isNull);
    expect(TeacherAssignment.tryParse('RB1:not-base64'), isNull);
  });

  test('Lehrerauftrag überschreibt Profilrahmen nur temporär', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.methodPreferences = const MethodPreferences(
      subtraction: SubtractionStrategy.complement,
    );

    const assignment = TeacherAssignment(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.twenty,
      mode: TrainingMode.minus,
      tasks: 8,
      targetCompetency: MicroCompetencyId.subtractionTenBridge,
      methods: MethodPreferences(
        subtraction: SubtractionStrategy.bridgeToTen,
      ),
    );

    controller.beginTeacherAssignment(assignment);
    expect(controller.effectiveGradeLevel, GradeLevel.second);
    expect(controller.effectiveNumberRange, NumberRangeLevel.twenty);
    expect(controller.effectiveMaxValue, 20);
    expect(
      controller.effectiveMethodPreferences.subtraction,
      SubtractionStrategy.bridgeToTen,
    );

    controller.endTeacherAssignment();
    expect(controller.numberRange, NumberRangeLevel.hundred);
    expect(
      controller.methodPreferences.subtraction,
      SubtractionStrategy.complement,
    );
  });
}
