import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

TrainingSessionResult session({
  required TrainingMode mode,
  required int correct,
  int total = 10,
  GradeLevel grade = GradeLevel.second,
  NumberRangeLevel range = NumberRangeLevel.hundred,
  DateTime? when,
}) =>
    TrainingSessionResult(
      mode: mode,
      startedAt: when ?? DateTime(2026, 9, 4, 10),
      finishedAt: (when ?? DateTime(2026, 9, 4, 10))
          .add(const Duration(minutes: 5)),
      total: total,
      correctFirstTry: correct,
      incorrectAttempts: total - correct,
      plusCorrect: 0,
      plusTotal: 0,
      minusCorrect: 0,
      minusTotal: 0,
      averageResponseMs: 2500,
      numberRange: range,
      gradeLevel: grade,
      starsEarned: 1,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Kompetenzkarte unterscheidet neu, sicher und gemeistert', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    expect(
      controller.competencyProgress(TrainingMode.money).state,
      CompetencyState.newSkill,
    );

    controller.history = [
      session(mode: TrainingMode.money, correct: 8),
    ];
    expect(
      controller.competencyProgress(TrainingMode.money).state,
      CompetencyState.secure,
    );

    controller.history = [
      session(mode: TrainingMode.money, correct: 9),
      session(mode: TrainingMode.money, correct: 9),
      session(mode: TrainingMode.money, correct: 9),
    ];
    expect(
      controller.competencyProgress(TrainingMode.money).state,
      CompetencyState.mastered,
    );
  });

  test('Meine Runde besteht aus 10 Aufgaben in drei Lernabschnitten', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    final plan = controller.buildMyRound();

    expect(plan, hasLength(3));
    expect(plan.fold<int>(0, (sum, item) => sum + item.tasks), 10);
    expect(plan.first.tasks, 3);
    expect(plan[1].tasks, 4);
    expect(plan.last.tasks, 3);
    expect(plan[1].mode, isNot(plan.first.mode));
  });

  test('Elternhinweis nennt Stärke, Fokus und konkrete nächste Handlung', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.history = [
      session(mode: TrainingMode.money, correct: 9),
      session(mode: TrainingMode.numberWall, correct: 5),
    ];

    final insight = controller.parentInsight();

    expect(insight.good, contains('Geld'));
    expect(insight.focus, contains('Zahlenmauern'));
    expect(insight.action, contains('3–5 Minuten'));
    expect(insight.notYet, contains('Tempo'));
  });

  test('Rechenweg-Einstellungen werden pro Profil im Controller gespeichert', () async {
    final controller = AppController();
    await controller.load();

    await controller.setSubtractionStrategy(
      SubtractionStrategy.complement,
    );

    expect(
      controller.methodPreferences.subtraction,
      SubtractionStrategy.complement,
    );
  });

  test('wiederkehrendes Fehlermuster präzisiert die Elternempfehlung', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.history = [
      session(mode: TrainingMode.minus, correct: 5),
      session(mode: TrainingMode.money, correct: 9),
    ];
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

    final insight = controller.parentInsight();

    expect(insight.focus, contains('Minus'));
    expect(insight.action, contains('Zehnerübergang'));
    expect(insight.action, contains('Tempo noch nicht'));
  });

}
