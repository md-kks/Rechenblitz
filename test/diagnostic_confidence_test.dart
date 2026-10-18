import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';

DiagnosticAttempt attempt({
  required DateTime at,
  required String key,
  required bool correct,
}) => DiagnosticAttempt(
  occurredAt: at,
  mode: TrainingMode.minus,
  taskKey: key,
  expected: 8,
  actual: correct ? 8 : 9,
  correct: correct,
  gradeLevel: GradeLevel.second,
  numberRange: NumberRangeLevel.hundred,
  pattern: correct ? null : ErrorPattern.tenBridge,
);

AppController controller(List<DiagnosticAttempt> entries) => AppController()
  ..gradeLevel = GradeLevel.second
  ..numberRange = NumberRangeLevel.hundred
  ..diagnostics = entries;

void main() {
  test('Wiederholungen derselben Aufgabe erzeugen kein wiederkehrendes Muster', () {
    final c = controller([
      attempt(at: DateTime(2026, 10, 19, 10, 2), key: 'minus:13:5', correct: false),
      attempt(at: DateTime(2026, 10, 19, 10, 1), key: 'minus:13:5', correct: false),
      attempt(at: DateTime(2026, 10, 19, 10), key: 'minus:13:5', correct: false),
    ]);
    final all = c.diagnosticSummaries();
    expect(all.single.errors, 3);
    expect(all.single.independentTaskVariety, 1);
    expect(all.single.isRecurring, isFalse);
    expect(c.diagnosticSummaries(recurringOnly: true), isEmpty);
    expect(c.topDiagnosticForMode(TrainingMode.minus), isNull);
  });

  test('zwei unterschiedliche Aufgaben bestaetigen das Muster', () {
    final c = controller([
      attempt(at: DateTime(2026, 10, 19, 10, 1), key: 'minus:13:5', correct: false),
      attempt(at: DateTime(2026, 10, 19, 10), key: 'minus:12:4', correct: false),
    ]);
    final summary = c.diagnosticSummaries(recurringOnly: true).single;
    expect(summary.independentTaskVariety, 2);
    expect(summary.isRecurring, isTrue);
    expect(summary.confidenceLabel, contains('unterschiedlichen Aufgaben'));
  });

  test('richtige Loesung zwischen Fehlern wird in der Sicherheit sichtbar', () {
    final c = controller([
      attempt(at: DateTime(2026, 10, 19, 10, 2), key: 'minus:14:6', correct: false),
      attempt(at: DateTime(2026, 10, 19, 10, 1), key: 'minus:13:5', correct: true),
      attempt(at: DateTime(2026, 10, 19, 10), key: 'minus:12:4', correct: false),
    ]);
    final summary = c.diagnosticSummaries(recurringOnly: true).single;
    expect(summary.confirmedAfterSuccess, isTrue);
    expect(summary.confidenceLabel, contains('nach einer richtigen Lösung erneut'));
  });

  test('mehr Vielfalt wird vor bloßer Fehlerzahl priorisiert', () {
    final c = controller([
      attempt(at: DateTime(2026, 10, 19, 10, 5), key: 'minus:13:5', correct: false),
      attempt(at: DateTime(2026, 10, 19, 10, 4), key: 'minus:12:4', correct: false),
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 10, 19, 10, 3), mode: TrainingMode.minus,
        taskKey: 'minus:20:3', expected: 17, actual: 16, correct: false,
        gradeLevel: GradeLevel.second, numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.countingStep,
      ),
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 10, 19, 10, 2), mode: TrainingMode.minus,
        taskKey: 'minus:20:3', expected: 17, actual: 16, correct: false,
        gradeLevel: GradeLevel.second, numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.countingStep,
      ),
      DiagnosticAttempt(
        occurredAt: DateTime(2026, 10, 19, 10, 1), mode: TrainingMode.minus,
        taskKey: 'minus:20:3', expected: 17, actual: 16, correct: false,
        gradeLevel: GradeLevel.second, numberRange: NumberRangeLevel.hundred,
        pattern: ErrorPattern.countingStep,
      ),
    ]);
    final summaries = c.diagnosticSummaries();
    expect(summaries.first.pattern, ErrorPattern.tenBridge);
    expect(summaries.first.independentTaskVariety, 2);
  });
}
