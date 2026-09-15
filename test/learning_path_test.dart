import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/guided_method.dart';
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
      now: DateTime(2026, 9, 3, 10, 5),
    );

    expect(insight.focus, contains('zeitlichem Abstand'));
    expect(insight.action, contains('ohne Starthilfe'));
    expect(insight.selection, contains('nach zeitlichem Abstand'));
    expect(insight.mastery, contains('Nachweis nach zeitlichem Abstand'));
  });

  test('Mikro-Fokus verwechselt fehlende Selbstständigkeit nicht mit 0 Prozent', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      3,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionTenBridge,
        occurredAt: DateTime(2026, 9, 10, 9, index),
        correct: true,
        evidenceWeight: 0.8,
        source: MicroEvidenceSource.practice,
        usedHelp: true,
        helpLevel: 1,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:17:4:$index',
      ),
    );

    final reason = controller.microFocusReason();

    expect(reason, contains('noch keine selbstständige Basisbeobachtung'));
    expect(reason, isNot(contains('0 % selbstständig richtig')));
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

    expect(insight.focus, contains('keine selbstständigen Basislösungen'));
    expect(insight.focus, isNot(contains('selbstständig 0 %')));
    expect(insight.mastery, contains('Für „Sicher“'));
    expect(insight.notYet, contains('Noch nicht „Sicher“'));
    expect(insight.evidence, contains('8 mit Hilfe'));
    expect(insight.evidence, contains('0 ohne Hilfe'));
    expect(
      insight.evidence,
      contains('noch keine auswertbare Beobachtung'),
    );
    expect(insight.evidence, isNot(contains('Sicherheit bei 0 %')));
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

  test('Elternhinweis trennt geführte Zwischenschritte von selbstständigen Aufgaben',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          occurredAt: DateTime(2026, 9, 5, 10, index),
          correct: true,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.guidedStep,
          usedHelp: true,
          helpLevel: 3,
          methodKey: 'subtraction:bridgeToTen',
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'guided:subtraction:bridgeToTen:bridgeAmount:$index',
        ),
      ),
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          occurredAt: DateTime(2026, 9, 4, 10, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'minus:13:5:$index',
        ),
      ),
    ];

    final insight = controller.parentInsight(
      now: DateTime(2026, 9, 5, 12),
    );

    expect(insight.evidence, contains('2 ohne Hilfe'));
    expect(insight.evidence, contains('2 mit Hilfe'));
    expect(insight.evidence, contains('2 geführte Zwischenschritte'));
    expect(insight.notYet, contains('Noch nicht „Sicher“'));
  });


  test('Elternhinweis nennt wiederholt unsicheren guidedStep konkret', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          occurredAt: DateTime(2026, 9, 5, 12, 10 + index),
          correct: false,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'minus:13:5:$index',
        ),
      ),
      ...List.generate(
        3,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.numberDecomposition,
          occurredAt: DateTime(2026, 9, 5, 12, index),
          correct: index == 2,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.guidedStep,
          usedHelp: true,
          helpLevel: HelpLevel.guided.value,
          methodKey: 'subtraction:bridgeToTen',
          mode: TrainingMode.minus,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'guided:subtraction:bridgeToTen:remainingSubtrahend:minus:13:5:$index',
        ),
      ),
    ];

    final insight = controller.parentInsight(
      now: DateTime(2026, 9, 5, 13),
    );

    expect(insight.focus, contains('verbleibenden Teil des Subtrahenden'));
    expect(insight.focus, contains('2 von 3'));
    expect(insight.action, contains('schrittweise zurückgenommen'));
    expect(insight.action, contains('verbleibenden Teil des Subtrahenden'));
    expect(insight.action, contains('kein selbstständiger Leistungsnachweis'));
    expect(insight.evidence, contains('2 von 3'));
    expect(insight.selection, contains('verbleibenden Teil des Subtrahenden'));
    expect(insight.selection, contains('Darstellung über Denkhinweis'));
  });


  test('Elternhinweis zeigt eigenständige Repräsentations-Teilfragen getrennt',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.multiplicationGroups,
          occurredAt: DateTime(2026, 9, 5, 12, index),
          correct: true,
          evidenceWeight: 0.30,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.wordProblems,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey:
              'independent:groupCount:process:representation:groups:3:4:$index',
        ),
      ),
      ...List.generate(
        2,
        (index) => MicroCompetencyObservation(
          id: MicroCompetencyId.multiplicationGroups,
          occurredAt: DateTime(2026, 9, 4, 12, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.multiply,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'multiply:3:4:$index',
        ),
      ),
    ];

    final insight = controller.parentInsight(
      now: DateTime(2026, 9, 5, 13),
    );

    expect(insight.evidence, contains('2 Teilfragen im Aufgabenfluss'));
    expect(insight.evidence, contains('4 ohne Hilfe'));
    expect(insight.evidence, isNot(contains('geführte Zwischenschritte')));
  });



  test('spätere Hilfe im Abstandstest nimmt Gemeistert zurück', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        6,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 1, 10, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'plus:47:${3 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 3, 10, index),
          source: MicroEvidenceSource.review,
          taskKey: 'review:plus:47:${3 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 3, 11, index),
          source: MicroEvidenceSource.transfer,
          mode: TrainingMode.wordProblems,
          taskKey:
              'story:transfer:skill:additionTenBridge:+:books:47:${3 + index}',
        ),
      ),
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 4, 12),
        source: MicroEvidenceSource.review,
        taskKey: 'review:plus:58:7',
        usedHelp: true,
        helpLevel: HelpLevel.visual.value,
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionTenBridge,
    );
    final insight = controller.parentInsight(now: DateTime(2026, 9, 4, 18));

    expect(progress.state, MicroCompetencyState.secure);
    expect(
      insight.mastery,
      contains('erneute selbstständige Abstandskontrolle'),
    );
  });

  test('später Transferfehler nimmt Gemeistert zurück', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        6,
        (index) => _microObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          when: DateTime(2026, 9, 1, 9, index),
          source: MicroEvidenceSource.practice,
          mode: TrainingMode.minus,
          taskKey: 'minus:${40 + index}:8',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          when: DateTime(2026, 9, 3, 9, index),
          source: MicroEvidenceSource.review,
          mode: TrainingMode.minus,
          taskKey: 'review:minus:${40 + index}:8',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          when: DateTime(2026, 9, 3, 10, index),
          source: MicroEvidenceSource.transfer,
          mode: TrainingMode.wordProblems,
          taskKey:
              'story:transfer:skill:subtractionTenBridge:-:books:${40 + index}:8',
        ),
      ),
      _microObservation(
        id: MicroCompetencyId.subtractionTenBridge,
        when: DateTime(2026, 9, 4, 13),
        source: MicroEvidenceSource.transfer,
        mode: TrainingMode.wordProblems,
        taskKey: 'story:transfer:skill:subtractionTenBridge:-:books:53:8',
        correct: false,
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.subtractionTenBridge,
    );
    final insight = controller.parentInsight(now: DateTime(2026, 9, 4, 18));

    expect(progress.state, MicroCompetencyState.secure);
    expect(
      insight.mastery,
      contains('erneute selbstständige Transferaufgabe'),
    );
  });

  test('unsichere Abstandskontrolle wird nach einem Tag wieder fällig', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        6,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'plus:27:${4 + index}',
        ),
      ),
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 4, 12),
        source: MicroEvidenceSource.review,
        taskKey: 'review:plus:38:5',
        usedHelp: true,
        helpLevel: HelpLevel.nudge.value,
      ),
    ];

    expect(
      controller.dueReviewMicroCompetency(now: DateTime(2026, 9, 5, 11, 59)),
      isNull,
    );
    expect(
      controller
          .dueReviewMicroCompetency(now: DateTime(2026, 9, 5, 12))
          ?.definition
          .id,
      MicroCompetencyId.additionTenBridge,
    );
  });

  test('unsichere fällige Abstandskontrolle hat Vorrang vor normaler Wiederholung',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        6,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'plus:27:${4 + index}',
        ),
      ),
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 4, 8),
        source: MicroEvidenceSource.review,
        taskKey: 'review:plus:38:5',
        correct: false,
      ),
      ...List.generate(
        6,
        (index) => _microObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          when: DateTime(2026, 9, 1, 7, index),
          source: MicroEvidenceSource.practice,
          mode: TrainingMode.minus,
          taskKey: 'minus:${40 + index}:8',
        ),
      ),
    ];

    final due = controller.dueReviewMicroCompetency(
      now: DateTime(2026, 9, 6, 8),
    );

    expect(due?.definition.id, MicroCompetencyId.additionTenBridge);
  });

  test('unsicherer letzter Transfer wird vor noch ungeprüftem Transfer repariert',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        6,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'plus:27:${4 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 2, 8, index),
          source: MicroEvidenceSource.transfer,
          mode: TrainingMode.wordProblems,
          taskKey:
              'story:transfer:skill:additionTenBridge:+:books:27:${4 + index}',
        ),
      ),
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 4, 8),
        source: MicroEvidenceSource.transfer,
        mode: TrainingMode.wordProblems,
        taskKey: 'story:transfer:skill:additionTenBridge:+:books:38:5',
        correct: false,
      ),
      ...List.generate(
        6,
        (index) => _microObservation(
          id: MicroCompetencyId.subtractionTenBridge,
          when: DateTime(2026, 9, 1, 7, index),
          source: MicroEvidenceSource.practice,
          mode: TrainingMode.minus,
          taskKey: 'minus:${40 + index}:8',
        ),
      ),
    ];

    final transfer = controller.transferCandidateMicroCompetency();

    expect(transfer?.definition.id, MicroCompetencyId.additionTenBridge);
  });

  test('Evidenzreihenfolge im Speicher beeinflusst den neuesten Status nicht', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final newest = DateTime(2026, 9, 5, 15);
    controller.microObservations = [
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 1, 8),
        source: MicroEvidenceSource.practice,
        taskKey: 'plus:17:4:oldest',
      ),
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: newest,
        source: MicroEvidenceSource.review,
        taskKey: 'review:plus:48:7:newest',
        usedHelp: true,
        helpLevel: HelpLevel.visual.value,
      ),
      ...List.generate(
        5,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 1, 9, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'plus:27:${4 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 3, 9, index),
          source: MicroEvidenceSource.review,
          taskKey: 'review:plus:37:${4 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 3, 10, index),
          source: MicroEvidenceSource.transfer,
          mode: TrainingMode.wordProblems,
          taskKey:
              'story:transfer:skill:additionTenBridge:+:books:37:${4 + index}',
        ),
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionTenBridge,
    );

    expect(progress.lastSeen, newest);
    expect(progress.state, MicroCompetencyState.secure);
  });


  test('später Hilfebedarf in Gesamtaufgabe nimmt Gemeistert zurück und wird Fokus',
      () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        6,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'plus:27:${4 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 3, 8, index),
          source: MicroEvidenceSource.review,
          taskKey: 'review:plus:37:${4 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 3, 9, index),
          source: MicroEvidenceSource.transfer,
          mode: TrainingMode.wordProblems,
          taskKey:
              'story:transfer:skill:additionTenBridge:+:books:37:${4 + index}',
        ),
      ),
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 5, 10),
        source: MicroEvidenceSource.practice,
        taskKey: 'plus:58:7',
        usedHelp: true,
        helpLevel: HelpLevel.visual.value,
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionTenBridge,
    );
    final focus = controller.currentMicroFocus();
    final plan = controller.buildMyRound(now: DateTime(2026, 9, 5, 11));
    final insight = controller.parentInsight(now: DateTime(2026, 9, 5, 11));

    expect(progress.state, MicroCompetencyState.secure);
    expect(focus?.definition.id, MicroCompetencyId.additionTenBridge);
    expect(plan[1].targetCompetency, MicroCompetencyId.additionTenBridge);
    expect(controller.microFocusReason(), contains('letzten Gesamtaufgabe'));
    expect(insight.mastery, contains('letzten Gesamtaufgabe'));
  });

  test('neue selbstständige Gesamtaufgabe kann frische Mastery wiederherstellen', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
        6,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'plus:27:${4 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 3, 8, index),
          source: MicroEvidenceSource.review,
          taskKey: 'review:plus:37:${4 + index}',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 3, 9, index),
          source: MicroEvidenceSource.transfer,
          mode: TrainingMode.wordProblems,
          taskKey:
              'story:transfer:skill:additionTenBridge:+:books:37:${4 + index}',
        ),
      ),
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 4, 10),
        source: MicroEvidenceSource.practice,
        taskKey: 'plus:48:7:helped',
        usedHelp: true,
        helpLevel: HelpLevel.visual.value,
      ),
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 5, 10),
        source: MicroEvidenceSource.practice,
        taskKey: 'plus:58:7:independent',
      ),
    ];

    final progress = controller.microCompetencyProgress(
      MicroCompetencyId.additionTenBridge,
    );

    expect(progress.state, MicroCompetencyState.mastered);
    expect(controller.currentMicroFocus(), isNull);
  });

}


MicroCompetencyObservation _microObservation({
  required MicroCompetencyId id,
  required DateTime when,
  required MicroEvidenceSource source,
  required String taskKey,
  TrainingMode mode = TrainingMode.practice,
  bool correct = true,
  bool usedHelp = false,
  int helpLevel = 0,
  double evidenceWeight = 1,
}) =>
    MicroCompetencyObservation(
      id: id,
      occurredAt: when,
      correct: correct,
      evidenceWeight: evidenceWeight,
      source: source,
      usedHelp: usedHelp,
      helpLevel: helpLevel,
      mode: mode,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      taskKey: taskKey,
    );
