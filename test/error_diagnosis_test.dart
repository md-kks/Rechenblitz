import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Zehnerübergang wird von bloßer falscher Rechenart unterschieden', () {
    final fact = MathFact(
      a: 13,
      b: 5,
      operation: MathOperation.minus,
    );

    expect(
      ErrorClassifier.classify(
        mode: TrainingMode.minus,
        taskKey: fact.key,
        expected: 8,
        actual: 9,
        fact: fact,
      ),
      ErrorPattern.tenBridge,
    );

    expect(
      ErrorClassifier.classify(
        mode: TrainingMode.minus,
        taskKey: fact.key,
        expected: 8,
        actual: 18,
        fact: fact,
      ),
      ErrorPattern.operationChoice,
    );
  });

  test('Einmaleins-Fehler wird als Faktenabruf eingeordnet', () {
    final fact = MathFact(
      a: 7,
      b: 8,
      operation: MathOperation.multiply,
    );

    expect(
      ErrorClassifier.classify(
        mode: TrainingMode.multiply,
        taskKey: fact.key,
        expected: 56,
        actual: 54,
        fact: fact,
      ),
      ErrorPattern.multiplicationFact,
    );
  });

  test('strukturierte Sachaufgabe und Größenumwandlung werden erkannt', () {
    expect(
      ErrorClassifier.classify(
        mode: TrainingMode.wordProblems,
        taskKey: 'story:-:18:7',
        expected: 11,
        actual: 25,
      ),
      ErrorPattern.wordProblem,
    );
    expect(
      ErrorClassifier.classify(
        mode: TrainingMode.measures,
        taskKey: 'measure:dm-cm:4',
        expected: 40,
        actual: 4,
      ),
      ErrorPattern.unitConversion,
    );
  });

  test('schriftliche Subtraktion mit Entbündeln wird gesondert erkannt', () {
    expect(
      ErrorClassifier.classify(
        mode: TrainingMode.writtenAddSub,
        taskKey: 'written:-:402:187',
        expected: 215,
        actual: 225,
      ),
      ErrorPattern.writtenRegrouping,
    );
  });

  test('ein einzelner Fehler wird noch nicht als wiederkehrendes Muster gezeigt',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.diagnostics = [
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 9, 4, 20),
        mode: TrainingMode.minus,
        taskKey: 'minus:13:5',
        expected: 8,
        actual: 9,
        correct: false,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.tenBridge,
      ),
    ];

    expect(
      controller.diagnosticSummaries(recurringOnly: true),
      isEmpty,
    );
    expect(controller.topDiagnosticForMode(TrainingMode.minus), isNull);
  });

  test('wiederkehrender Fehler wird zusammengefasst und beeinflusst Hilfe', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.diagnostics = [
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 9, 4, 20, 2),
        mode: TrainingMode.minus,
        taskKey: 'minus:13:5',
        expected: 8,
        actual: 9,
        correct: false,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.tenBridge,
      ),
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 9, 4, 20),
        mode: TrainingMode.minus,
        taskKey: 'minus:12:4',
        expected: 8,
        actual: 9,
        correct: false,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.tenBridge,
      ),
    ];

    final summary = controller.topDiagnosticForMode(TrainingMode.minus);
    expect(summary, isNotNull);
    expect(summary!.pattern, ErrorPattern.tenBridge);
    expect(summary.errors, 2);
    expect(summary.isRecurring, isTrue);
  });

  test('Diagnosen anderer Klassenstufen und Zahlenräume werden nicht vermischt',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    controller.diagnostics = [
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 9, 4, 20),
        mode: TrainingMode.writtenAddSub,
        taskKey: 'written:-:402:187',
        expected: 215,
        actual: 225,
        correct: false,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.writtenRegrouping,
      ),
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 9, 4, 20, 1),
        mode: TrainingMode.writtenAddSub,
        taskKey: 'written:-:802:187',
        expected: 615,
        actual: 625,
        correct: false,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.writtenRegrouping,
      ),
    ];

    expect(
      controller.diagnosticSummaries(recurringOnly: true),
      isEmpty,
    );
  });

  test('Diagnosebeobachtungen bleiben nach Neustart lokal erhalten', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    await controller.recordDiagnosticAttempt(
      mode: TrainingMode.minus,
      taskKey: 'minus:13:5',
      expected: 8,
      actual: 9,
      fact: MathFact(
        a: 13,
        b: 5,
        operation: MathOperation.minus,
      ),
    );

    final reloaded = AppController();
    await reloaded.load();

    expect(reloaded.diagnostics, hasLength(1));
    expect(reloaded.diagnostics.single.pattern, ErrorPattern.tenBridge);
  });
}
