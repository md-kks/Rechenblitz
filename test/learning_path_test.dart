import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/micro_competency.dart';
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

  test('Meine Runde besteht aus 12 Aufgaben in vier Lernabschnitten', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    final plan = controller.buildMyRound();

    expect(plan, hasLength(4));
    expect(plan.fold<int>(0, (sum, item) => sum + item.tasks), 12);
    expect(plan[0].tasks, 2);
    expect(plan[1].tasks, 5);
    expect(plan[2].tasks, 3);
    expect(plan[3].tasks, 2);
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

    expect(controller.parentPriorityMicroCompetency(), isNull);
    expect(insight.good, contains('Geld'));
    expect(insight.focus, contains('Zahlenmauern'));
    expect(insight.action, contains('3–5 Minuten'));
    expect(insight.notYet, contains('Tempo'));
    expect(insight.mastery, contains('Mikro-Beobachtungen'));
  });


  test('Elternerklärung trennt Sicher von Gemeistert', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      6,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionTenBridge,
        occurredAt: DateTime(2026, 9, 4, 12, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:47:${3 + index}',
      ),
    );

    final insight = controller.parentInsight(
      now: DateTime(2026, 9, 5, 12),
    );

    expect(insight.good, contains('sicher'));
    expect(insight.focus, contains('veränderten Aufgabe'));
    expect(insight.mastery, contains('„Sicher“'));
    expect(insight.mastery, contains('„Gemeistert“'));
    expect(insight.notYet, contains('Noch nicht „Gemeistert“'));
    expect(insight.notYet, contains('zeitlichem Abstand'));
    expect(insight.notYet, contains('Transfer'));
    expect(insight.evidence, contains('6 passende Beobachtungen'));
    expect(insight.evidence, contains('6 ohne Hilfe'));
    expect(insight.selection, contains('veränderter Form'));
  });

  test('Elternerklärung benennt fällige Abstandskontrolle kausal', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      6,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        occurredAt: DateTime(2026, 9, 1, 10, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:${30 + index}:8',
      ),
    );

    final insight = controller.parentInsight(
      now: DateTime(2026, 9, 3, 10),
    );

    expect(insight.focus, contains('zeitlichem Abstand'));
    expect(insight.action, contains('ohne Starthilfe'));
    expect(insight.selection, contains('nach zeitlichem Abstand'));
    expect(insight.mastery, contains('Nachweis nach zeitlichem Abstand'));
  });

  test('Elternerklärung macht Hilfebedarf sichtbar ohne ihn aufzuwerten', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      8,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        occurredAt: DateTime(2026, 9, 4, 11, index),
        correct: true,
        evidenceWeight: 0.8,
        source: MicroEvidenceSource.practice,
        usedHelp: true,
        helpLevel: 1,
        mode: TrainingMode.minus,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'minus:43:18:$index',
      ),
    );

    final insight = controller.parentInsight(
      now: DateTime(2026, 9, 5, 11),
    );

    expect(insight.focus, contains('selbstständig 0 %'));
    expect(insight.mastery, contains('Für „Sicher“'));
    expect(insight.notYet, contains('Noch nicht „Sicher“'));
    expect(insight.evidence, contains('8 mit Hilfe'));
    expect(insight.evidence, contains('0 ohne Hilfe'));
  });


  test('Elternerklärung nennt bei Gemeistert keinen fehlenden Nachweis', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: DateTime(2026, 9, 4, 12, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.review,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'review:plus:47:${3 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: DateTime(2026, 9, 3, 12, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.transfer,
          usedHelp: false,
          mode: TrainingMode.wordProblems,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'story:transfer:skill:additionTenBridge:+:books:47:${3 + index}',
        ),
      ),
      ...List.generate(
        6,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: DateTime(2026, 9, 1, 12, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:47:${3 + index}',
        ),
      ),
    ];

    final insight = controller.parentInsight(
      now: DateTime(2026, 9, 5, 12),
    );

    expect(insight.mastery, contains('„Gemeistert“'));
    expect(insight.notYet, contains('kein weiterer Nachweis'));
    expect(insight.focus, contains('bereits gemeistert'));
    expect(insight.action, contains('dem Erhalt'));
    expect(insight.evidence, contains('2 nach Abstand'));
    expect(insight.evidence, contains('2 im Transfer'));
  });

  test('frisches Profil erklärt Entdeckung statt scheinbarer Diagnose', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;

    final insight = controller.parentInsight(
      now: DateTime(2026, 9, 5, 12),
    );

    expect(insight.mastery, contains('noch neu'));
    expect(insight.evidence, contains('noch keine passenden Beobachtungen'));
    expect(insight.selection, contains('führen vorsichtig in'));
    expect(insight.notYet, contains('Noch keine belastbare Aussage'));
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
