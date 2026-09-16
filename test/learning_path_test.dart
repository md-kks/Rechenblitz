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
    expect(plan.map((segment) => segment.role), <GuidedRoundRole>[
      GuidedRoundRole.warmUp,
      GuidedRoundRole.focus,
      GuidedRoundRole.review,
      GuidedRoundRole.apply,
    ]);
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
    controller.microObservations = [
      ...List.generate(
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
      ),
      ..._secureEvidence(
        MicroCompetencyId.numberDecomposition,
        DateTime(2026, 9, 9, 8),
        mode: TrainingMode.numberFriends,
        prefix: 'focus-prereq-decompose',
      ),
      ..._secureEvidence(
        MicroCompetencyId.additionNoBridge,
        DateTime(2026, 9, 9, 9),
        mode: TrainingMode.practice,
        prefix: 'focus-prereq-add',
      ),
    ];

    final reason = controller.microFocusReason();

    expect(reason, contains('noch keine selbstständige Basisbeobachtung'));
    expect(reason, isNot(contains('0 % selbstständig richtig')));
  });

  test('Elternerklärung macht Hilfebedarf sichtbar ohne ihn aufzuwerten', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ...List.generate(
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
      ),
      ..._secureEvidence(
        MicroCompetencyId.numberDecomposition,
        DateTime(2026, 9, 3, 8),
        mode: TrainingMode.numberFriends,
        prefix: 'parent-prereq-decompose',
      ),
      ..._secureEvidence(
        MicroCompetencyId.subtractionNoBridge,
        DateTime(2026, 9, 3, 9),
        mode: TrainingMode.minus,
        prefix: 'parent-prereq-subtract',
      ),
    ];

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
      ..._secureEvidence(
        MicroCompetencyId.numberDecomposition,
        DateTime(2026, 9, 3, 8),
        mode: TrainingMode.numberFriends,
        prefix: 'guided-prereq-decompose',
      ),
      ..._secureEvidence(
        MicroCompetencyId.subtractionNoBridge,
        DateTime(2026, 9, 3, 9),
        mode: TrainingMode.minus,
        prefix: 'guided-prereq-subtract',
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

  test('stabile Abstandskontrolle wird nach sieben Tagen wieder fällig', () {
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
          taskKey: 'review:stable:$index',
        ),
      ),
    ];

    expect(
      controller.dueReviewMicroCompetency(now: DateTime(2026, 9, 10, 7, 59)),
      isNull,
    );
    expect(
      controller
          .dueReviewMicroCompetency(now: DateTime(2026, 9, 10, 8, 1))
          ?.definition
          .id,
      MicroCompetencyId.additionTenBridge,
    );
  });

  test('gemeisterte Kompetenz bekommt vierzehn Tage Abstand', () {
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
          taskKey: 'mastered-base:$index',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 3, 8, index),
          source: MicroEvidenceSource.review,
          taskKey: 'mastered-review:$index',
        ),
      ),
      ...List.generate(
        2,
        (index) => _microObservation(
          id: MicroCompetencyId.additionTenBridge,
          when: DateTime(2026, 9, 4, 8, index),
          source: MicroEvidenceSource.transfer,
          mode: TrainingMode.wordProblems,
          taskKey: 'mastered-transfer:$index',
        ),
      ),
    ];

    expect(
      controller.microCompetencyProgress(MicroCompetencyId.additionTenBridge).state,
      MicroCompetencyState.mastered,
    );
    expect(
      controller.dueReviewMicroCompetency(now: DateTime(2026, 9, 17, 7, 59)),
      isNull,
    );
    expect(
      controller
          .dueReviewMicroCompetency(now: DateTime(2026, 9, 17, 8, 1))
          ?.definition
          .id,
      MicroCompetencyId.additionTenBridge,
    );
  });

  test('stabiler Transfer wird nicht in jeder Runde erneut eingeplant', () {
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
          taskKey: 'transfer-gap-base:$index',
        ),
      ),
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 5, 8),
        source: MicroEvidenceSource.transfer,
        mode: TrainingMode.wordProblems,
        taskKey: 'transfer-gap-stable',
      ),
    ];

    expect(
      controller.transferCandidateMicroCompetency(
        now: DateTime(2026, 9, 10, 7, 59),
        respectSchedule: true,
      ),
      isNull,
    );
    expect(
      controller
          .transferCandidateMicroCompetency(
            now: DateTime(2026, 9, 10, 8, 1),
            respectSchedule: true,
          )
          ?.definition
          .id,
      MicroCompetencyId.additionTenBridge,
    );
  });

  test('unsicherer Transfer wird bereits nach einem Tag erneut angeboten', () {
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
          taskKey: 'transfer-retry-base:$index',
        ),
      ),
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 5, 8),
        source: MicroEvidenceSource.transfer,
        mode: TrainingMode.wordProblems,
        taskKey: 'transfer-retry-unstable',
        correct: false,
      ),
    ];

    expect(
      controller.transferCandidateMicroCompetency(
        now: DateTime(2026, 9, 6, 7, 59),
        respectSchedule: true,
      ),
      isNull,
    );
    expect(
      controller
          .transferCandidateMicroCompetency(
            now: DateTime(2026, 9, 6, 8, 1),
            respectSchedule: true,
          )
          ?.definition
          .id,
      MicroCompetencyId.additionTenBridge,
    );
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

  test('Meine Runde verwendet dieselbe Mikro-Kompetenz nicht in mehreren Rollen', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final old = DateTime(2026, 9, 1, 8);
    final recent = DateTime(2026, 9, 4, 8);
    controller.microObservations = [
      ..._secureEvidence(
        MicroCompetencyId.additionNoBridge,
        old,
        mode: TrainingMode.practice,
        prefix: 'plus',
      ),
      _microObservation(
        id: MicroCompetencyId.additionNoBridge,
        when: recent,
        source: MicroEvidenceSource.practice,
        taskKey: 'plus:48:7:helped',
        usedHelp: true,
        helpLevel: HelpLevel.visual.value,
      ),
      ..._secureEvidence(
        MicroCompetencyId.subtractionNoBridge,
        old.add(const Duration(hours: 1)),
        mode: TrainingMode.minus,
        prefix: 'minus',
      ),
      ..._secureEvidence(
        MicroCompetencyId.numberRelations,
        old.add(const Duration(hours: 2)),
        mode: TrainingMode.numberWall,
        prefix: 'wall',
      ),
      ..._secureEvidence(
        MicroCompetencyId.moneyCalculation,
        old.add(const Duration(hours: 3)),
        mode: TrainingMode.money,
        prefix: 'money',
      ),
    ];

    final plan = controller.buildMyRound(now: DateTime(2026, 9, 10, 8));
    final targets = plan
        .map((segment) => segment.targetCompetency)
        .whereType<MicroCompetencyId>()
        .toList();

    expect(plan[1].targetCompetency, MicroCompetencyId.additionNoBridge);
    expect(targets.toSet().length, targets.length);
    expect(plan.map((segment) => segment.role).toSet().length, 4);
  });

  test('Warm-up rotiert zur am längsten nicht gesehenen sicheren Kompetenz', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ..._secureEvidence(
        MicroCompetencyId.numberRelations,
        DateTime(2026, 9, 1, 8),
        mode: TrainingMode.numberWall,
        prefix: 'wall',
      ),
      ..._secureEvidence(
        MicroCompetencyId.moneyCalculation,
        DateTime(2026, 9, 5, 8),
        mode: TrainingMode.money,
        prefix: 'money',
      ),
    ];

    final warmUp = controller.warmUpMicroCompetency();

    expect(warmUp?.definition.id, MicroCompetencyId.numberRelations);
  });

  test('Review und Transfer respektieren mehrere geschützte Kompetenzen', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      ..._secureEvidence(
        MicroCompetencyId.numberRelations,
        DateTime(2026, 9, 1, 8),
        mode: TrainingMode.numberWall,
        prefix: 'wall',
      ),
      ..._secureEvidence(
        MicroCompetencyId.moneyCalculation,
        DateTime(2026, 9, 1, 9),
        mode: TrainingMode.money,
        prefix: 'money',
      ),
      ..._secureEvidence(
        MicroCompetencyId.shapeProperties,
        DateTime(2026, 9, 1, 10),
        mode: TrainingMode.geometry,
        prefix: 'geometry',
      ),
    ];

    final review = controller.dueReviewMicroCompetency(
      now: DateTime(2026, 9, 5, 12),
      excluding: const <MicroCompetencyId>[
        MicroCompetencyId.numberRelations,
        MicroCompetencyId.moneyCalculation,
      ],
    );
    final transfer = controller.transferCandidateMicroCompetency(
      excludingAny: const <MicroCompetencyId>[
        MicroCompetencyId.numberRelations,
        MicroCompetencyId.moneyCalculation,
      ],
    );

    expect(review?.definition.id, MicroCompetencyId.shapeProperties);
    expect(transfer?.definition.id, MicroCompetencyId.shapeProperties);
  });

  test('Neue Kompetenz wird erst nach stabilen Voraussetzungen entdeckt', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final blocked = MicroCompetencyCatalog.forContext(
      GradeLevel.second,
      NumberRangeLevel.hundred,
    )
        .map((definition) => definition.id)
        .where((id) => id != MicroCompetencyId.additionTenBridge)
        .toList();

    expect(
      controller.nextNewMicroCompetency(excluding: blocked),
      isNull,
    );

    controller.microObservations = [
      ..._secureEvidence(
        MicroCompetencyId.numberDecomposition,
        DateTime(2026, 9, 1, 8),
        mode: TrainingMode.numberFriends,
        prefix: 'friend',
      ),
      ..._secureEvidence(
        MicroCompetencyId.additionNoBridge,
        DateTime(2026, 9, 1, 9),
        mode: TrainingMode.practice,
        prefix: 'plus',
      ),
    ];

    expect(
      controller.nextNewMicroCompetency(excluding: blocked)?.definition.id,
      MicroCompetencyId.additionTenBridge,
    );
  });

  test('Runden-Replan bewahrt erledigte Rollen und erneuert nur offene Teile', () {
    final current = <GuidedRoundSegment>[
      _roundSegment(
        GuidedRoundRole.warmUp,
        TrainingMode.money,
        2,
        'altes Ankommen',
      ),
      _roundSegment(
        GuidedRoundRole.focus,
        TrainingMode.minus,
        5,
        'alter Fokus',
      ),
      _roundSegment(
        GuidedRoundRole.review,
        TrainingMode.numberWall,
        3,
        'alte Wiederholung',
      ),
      _roundSegment(
        GuidedRoundRole.apply,
        TrainingMode.wordProblems,
        2,
        'alte Anwendung',
      ),
    ];
    final updated = <GuidedRoundSegment>[
      _roundSegment(
        GuidedRoundRole.warmUp,
        TrainingMode.geometry,
        2,
        'neues Ankommen',
      ),
      _roundSegment(
        GuidedRoundRole.focus,
        TrainingMode.placeValue,
        5,
        'neuer Fokus',
      ),
      _roundSegment(
        GuidedRoundRole.review,
        TrainingMode.factFamilies,
        3,
        'neue Wiederholung',
      ),
      _roundSegment(
        GuidedRoundRole.apply,
        TrainingMode.money,
        2,
        'neue Anwendung',
      ),
    ];

    final merged = GuidedRoundOrchestrator.mergeRemaining(
      current: current,
      updated: updated,
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
    );

    expect(merged.first.mode, TrainingMode.money);
    expect(merged.first.reason, 'altes Ankommen');
    expect(merged[1].mode, TrainingMode.placeValue);
    expect(merged[2].mode, TrainingMode.factFamilies);
    expect(merged[3].mode, TrainingMode.money);
  });

  test('späte Kurz-Übung verdichtet offene Runde auf neun reguläre Aufgaben', () {
    final current = <GuidedRoundSegment>[
      _roundSegment(GuidedRoundRole.warmUp, TrainingMode.practice, 2, 'warm'),
      _roundSegment(GuidedRoundRole.focus, TrainingMode.minus, 5, 'focus'),
      _roundSegment(GuidedRoundRole.review, TrainingMode.numberWall, 3, 'review'),
      _roundSegment(GuidedRoundRole.apply, TrainingMode.wordProblems, 2, 'apply'),
    ];
    final updated = <GuidedRoundSegment>[
      _roundSegment(GuidedRoundRole.warmUp, TrainingMode.money, 2, 'warm neu'),
      _roundSegment(GuidedRoundRole.focus, TrainingMode.minus, 2, 'focus neu'),
      _roundSegment(GuidedRoundRole.review, TrainingMode.geometry, 3, 'review neu'),
      _roundSegment(GuidedRoundRole.apply, TrainingMode.wordProblems, 2, 'apply neu'),
    ];

    final compacted = GuidedRoundOrchestrator.mergeRemaining(
      current: current,
      updated: updated,
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
      regularTaskBudget: 9,
    );

    expect(
      compacted.fold<int>(0, (sum, segment) => sum + segment.tasks),
      9,
    );
    expect(compacted.first.reason, 'warm');
    expect(compacted.map((segment) => segment.role).toSet().length, compacted.length);
    expect(9 + 3, 12, reason: 'Mit drei Recovery-Aufgaben bleibt die Runde bei zwölf.');
  });


  test('Rundenfortschritt bleibt im gültigen Zeitfenster wiederaufnehmbar', () async {
    final controller = AppController();
    await controller.load();
    final now = DateTime.now();
    final plan = controller.buildMyRound();
    final decisionTrace = controller.guidedRoundDecisionTrace(now: now);
    final progress = GuidedRoundProgress(
      plan: plan,
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
      gradeLevel: controller.gradeLevel,
      numberRange: controller.numberRange,
      startedAt: now,
      updatedAt: now,
      recoveryRequired: false,
      decisionTrace: decisionTrace,
    );
    await controller.saveGuidedRoundProgress(progress);

    final restoredController = AppController();
    await restoredController.load();
    final restored = restoredController.resumableGuidedRound(
      now: now.add(const Duration(hours: 2)),
    );

    expect(restored, isNotNull);
    expect(restored!.completedRoles, contains(GuidedRoundRole.warmUp));
    expect(restored.plan.map((segment) => segment.role), plan.map((segment) => segment.role));
    expect(restored.decisionTrace.summary, decisionTrace.summary);
    expect(restored.decisionTrace.items.length, decisionTrace.items.length);
  });

  test('abgeschlossene Tagesrunde wird erst am Folgetag ungültig', () {
    final started = DateTime(2026, 9, 15, 8);
    final progress = GuidedRoundProgress(
      plan: <GuidedRoundSegment>[
        _roundSegment(GuidedRoundRole.warmUp, TrainingMode.practice, 2, 'warm'),
      ],
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: started,
      updatedAt: started.add(const Duration(minutes: 5)),
      recoveryRequired: false,
    );

    expect(progress.isComplete, isTrue);
    expect(
      progress.isCompatible(
        grade: GradeLevel.second,
        range: NumberRangeLevel.hundred,
        now: DateTime(2026, 9, 15, 20),
      ),
      isTrue,
    );
    expect(
      progress.isCompatible(
        grade: GradeLevel.second,
        range: NumberRangeLevel.hundred,
        now: DateTime(2026, 9, 16, 7),
      ),
      isFalse,
    );
  });

  test('alte oder zahlenraumfremde Zwischenrunde wird nicht fortgesetzt', () {
    final progress = GuidedRoundProgress(
      plan: <GuidedRoundSegment>[
        _roundSegment(GuidedRoundRole.focus, TrainingMode.minus, 5, 'focus'),
      ],
      completedRoles: const <GuidedRoundRole>{},
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: DateTime(2026, 9, 13, 8),
      updatedAt: DateTime(2026, 9, 13, 9),
      recoveryRequired: false,
    );

    expect(
      progress.isCompatible(
        grade: GradeLevel.second,
        range: NumberRangeLevel.hundred,
        now: DateTime(2026, 9, 15, 9),
      ),
      isFalse,
    );
    expect(
      progress.isCompatible(
        grade: GradeLevel.second,
        range: NumberRangeLevel.twenty,
        now: DateTime(2026, 9, 13, 10),
      ),
      isFalse,
    );
  });

  test('Zahlenraum-Empfehlung wartet auf breite eigenständige Evidenz', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.ten;

    final readiness = controller.numberRangeReadiness();

    expect(readiness.status, NumberRangeReadinessStatus.collecting);
    expect(readiness.nextRange, NumberRangeLevel.twenty);
  });

  test('stabile Kernkompetenzen schalten den nächsten Zahlenraum frei', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.ten;
    final definitions = MicroCompetencyCatalog.forContext(
      GradeLevel.first,
      NumberRangeLevel.ten,
    ).where(
      (definition) =>
          definition.domain == MicroCompetencyDomain.numberSense ||
          definition.domain == MicroCompetencyDomain.arithmetic,
    ).toList();
    final start = DateTime(2026, 9, 10, 10);
    for (final definition in definitions) {
      for (var index = 0; index < 6; index++) {
        controller.microObservations.add(
          MicroCompetencyObservation(
            id: definition.id,
            occurredAt: start.add(Duration(minutes: index)),
            correct: true,
            evidenceWeight: 1,
            source: MicroEvidenceSource.practice,
            usedHelp: false,
            helpLevel: 0,
            mode: definition.preferredMode,
            gradeLevel: GradeLevel.first,
            numberRange: NumberRangeLevel.ten,
            taskKey: 'range-ready:${definition.id.name}:$index',
          ),
        );
      }
    }
    for (final definition in definitions.take(2)) {
      controller.microObservations.add(
        MicroCompetencyObservation(
          id: definition.id,
          occurredAt: start.add(const Duration(days: 2)),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.review,
          usedHelp: false,
          helpLevel: 0,
          mode: definition.preferredMode,
          gradeLevel: GradeLevel.first,
          numberRange: NumberRangeLevel.ten,
          taskKey: 'range-review:${definition.id.name}',
        ),
      );
    }

    final readiness = controller.numberRangeReadiness();

    expect(readiness.status, NumberRangeReadinessStatus.ready);
    expect(readiness.nextRange, NumberRangeLevel.twenty);
    expect(readiness.secureCore, greaterThanOrEqualTo(3));
    expect(readiness.confirmedCore, greaterThanOrEqualTo(1));
  });

  test('frische instabile Kernevidenz blockiert Zahlenraum-Aufstieg', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.ten;
    final definitions = MicroCompetencyCatalog.forContext(
      GradeLevel.first,
      NumberRangeLevel.ten,
    ).where(
      (definition) =>
          definition.domain == MicroCompetencyDomain.numberSense ||
          definition.domain == MicroCompetencyDomain.arithmetic,
    ).toList();
    final start = DateTime(2026, 9, 10, 10);
    for (final definition in definitions) {
      for (var index = 0; index < 6; index++) {
        controller.microObservations.add(
          MicroCompetencyObservation(
            id: definition.id,
            occurredAt: start.add(Duration(minutes: index)),
            correct: true,
            evidenceWeight: 1,
            source: MicroEvidenceSource.practice,
            usedHelp: false,
            helpLevel: 0,
            mode: definition.preferredMode,
            gradeLevel: GradeLevel.first,
            numberRange: NumberRangeLevel.ten,
            taskKey: 'range-stable:${definition.id.name}:$index',
          ),
        );
      }
      controller.microObservations.add(
        MicroCompetencyObservation(
          id: definition.id,
          occurredAt: start.add(const Duration(days: 1)),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.review,
          usedHelp: false,
          helpLevel: 0,
          mode: definition.preferredMode,
          gradeLevel: GradeLevel.first,
          numberRange: NumberRangeLevel.ten,
          taskKey: 'range-confirm:${definition.id.name}',
        ),
      );
    }
    final unstable = definitions.first;
    controller.microObservations.add(
      MicroCompetencyObservation(
        id: unstable.id,
        occurredAt: start.add(const Duration(days: 3)),
        correct: false,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        helpLevel: 0,
        mode: unstable.preferredMode,
        gradeLevel: GradeLevel.first,
        numberRange: NumberRangeLevel.ten,
        taskKey: 'range-unstable:${unstable.id.name}',
      ),
    );

    final readiness = controller.numberRangeReadiness();

    expect(readiness.status, NumberRangeReadinessStatus.consolidate);
    expect(readiness.isReady, isFalse);
  });

  test('Zahlenraum-Brücke übernimmt stabile Grundlagen ohne sie hochzustufen', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.twenty;
    final start = DateTime(2026, 9, 10, 9);
    controller.microObservations.addAll(
      List.generate(
        6,
        (index) => _rangeObservation(
          id: MicroCompetencyId.numberDecomposition,
          when: start.add(Duration(minutes: index)),
          range: NumberRangeLevel.ten,
          grade: GradeLevel.first,
          mode: TrainingMode.numberFriends,
          taskKey: 'bridge-old:$index',
        ),
      ),
    );

    final bridge = controller.numberRangeBridgeStatus();
    final current = controller.microCompetencyProgress(
      MicroCompetencyId.numberDecomposition,
    );
    final plan = controller.buildMyRound();

    expect(bridge.isActive, isTrue);
    expect(bridge.previousRange, NumberRangeLevel.ten);
    expect(
      bridge.pendingCompetencies,
      contains(MicroCompetencyId.numberDecomposition),
    );
    expect(current.state, MicroCompetencyState.newSkill);
    expect(plan.first.rangeBridge, isTrue);
    expect(
      plan.first.targetCompetency,
      MicroCompetencyId.numberDecomposition,
    );
    expect(plan.first.reason, contains('vorherigen Zahlenraum'));
  });

  test('Zahlenraum-Brücke ignoriert zuletzt instabile alte Grundlagen', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.twenty;
    final start = DateTime(2026, 9, 10, 9);
    controller.microObservations.addAll(
      List.generate(
        6,
        (index) => _rangeObservation(
          id: MicroCompetencyId.numberDecomposition,
          when: start.add(Duration(minutes: index)),
          range: NumberRangeLevel.ten,
          grade: GradeLevel.first,
          mode: TrainingMode.numberFriends,
          taskKey: 'bridge-stable:$index',
        ),
      ),
    );
    controller.microObservations.add(
      _rangeObservation(
        id: MicroCompetencyId.numberDecomposition,
        when: start.add(const Duration(hours: 1)),
        range: NumberRangeLevel.ten,
        grade: GradeLevel.first,
        mode: TrainingMode.numberFriends,
        taskKey: 'bridge-latest-wrong',
        correct: false,
      ),
    );

    final bridge = controller.numberRangeBridgeStatus();

    expect(
      bridge.foundationCompetencies,
      isNot(contains(MicroCompetencyId.numberDecomposition)),
    );
    expect(bridge.isActive, isFalse);
  });

  test('neue eigenständige Evidenz schließt eine Zahlenraum-Brücke', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.twenty;
    final start = DateTime(2026, 9, 10, 9);
    controller.microObservations.addAll(
      List.generate(
        6,
        (index) => _rangeObservation(
          id: MicroCompetencyId.numberDecomposition,
          when: start.add(Duration(minutes: index)),
          range: NumberRangeLevel.ten,
          grade: GradeLevel.first,
          mode: TrainingMode.numberFriends,
          taskKey: 'bridge-source:$index',
        ),
      ),
    );
    controller.microObservations.addAll([
      _rangeObservation(
        id: MicroCompetencyId.numberDecomposition,
        when: start.add(const Duration(days: 1)),
        range: NumberRangeLevel.twenty,
        grade: GradeLevel.first,
        mode: TrainingMode.numberFriends,
        taskKey: 'bridge-confirm:1',
      ),
      _rangeObservation(
        id: MicroCompetencyId.numberDecomposition,
        when: start.add(const Duration(days: 1, minutes: 1)),
        range: NumberRangeLevel.twenty,
        grade: GradeLevel.first,
        mode: TrainingMode.numberFriends,
        taskKey: 'bridge-confirm:2',
      ),
    ]);

    final bridge = controller.numberRangeBridgeStatus();

    expect(
      bridge.confirmedCompetencies,
      contains(MicroCompetencyId.numberDecomposition),
    );
    expect(
      bridge.pendingCompetencies,
      isNot(contains(MicroCompetencyId.numberDecomposition)),
    );
    expect(bridge.progress, 1);
    expect(bridge.isActive, isFalse);
  });

  test('Brückenrolle bleibt im gespeicherten Rundenplan erhalten', () {
    const segment = GuidedRoundSegment(
      role: GuidedRoundRole.warmUp,
      mode: TrainingMode.numberFriends,
      tasks: 2,
      reason: 'Brücke',
      targetCompetency: MicroCompetencyId.numberDecomposition,
      rangeBridge: true,
    );

    final restored = GuidedRoundSegment.fromJson(segment.toJson());

    expect(restored.rangeBridge, isTrue);
    expect(restored.targetCompetency, MicroCompetencyId.numberDecomposition);
  });

  test('Zahlenraumwechsel verwirft alten Rundenplan und Aufgaben-Diversität', () async {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.ten;
    controller.recentTaskKeysByMode = <String, List<String>>{
      TrainingMode.numberFriends.name: <String>['plus:6:4'],
    };
    controller.guidedRoundProgress = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[
        GuidedRoundSegment(
          role: GuidedRoundRole.warmUp,
          mode: TrainingMode.numberFriends,
          tasks: 2,
          reason: 'alt',
        ),
      ],
      completedRoles: const <GuidedRoundRole>{},
      gradeLevel: GradeLevel.first,
      numberRange: NumberRangeLevel.ten,
      startedAt: DateTime(2026, 9, 15, 8),
      updatedAt: DateTime(2026, 9, 15, 8),
      recoveryRequired: false,
    );

    await controller.setNumberRange(NumberRangeLevel.twenty);

    expect(controller.numberRange, NumberRangeLevel.twenty);
    expect(controller.guidedRoundProgress, isNull);
    expect(controller.recentTaskKeysByMode, isEmpty);
  });


  test('Klassenstufen-Brücke übernimmt stabile Grundlagen aus der Vorstufe', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final start = DateTime(2026, 9, 15, 9);
    controller.microObservations.addAll(
      List.generate(
        6,
        (index) => _rangeObservation(
          id: MicroCompetencyId.numberDecomposition,
          when: start.add(Duration(minutes: index)),
          range: NumberRangeLevel.twenty,
          grade: GradeLevel.first,
          mode: TrainingMode.numberFriends,
          taskKey: 'grade-bridge-old:$index',
        ),
      ),
    );

    final bridge = controller.gradeBridgeStatus();
    final current = controller.microCompetencyProgress(
      MicroCompetencyId.numberDecomposition,
    );

    expect(bridge.isActive, isTrue);
    expect(bridge.previousGrade, GradeLevel.first);
    expect(bridge.currentGrade, GradeLevel.second);
    expect(
      bridge.pendingCompetencies,
      contains(MicroCompetencyId.numberDecomposition),
    );
    expect(current.state, MicroCompetencyState.newSkill);
    expect(bridge.reason, contains('Klasse 1'));
  });

  test('Klassenstufen-Brücke hat Vorrang vor einer Zahlenraum-Brücke', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final start = DateTime(2026, 9, 15, 9);
    controller.microObservations.addAll([
      ...List.generate(
        6,
        (index) => _rangeObservation(
          id: MicroCompetencyId.numberDecomposition,
          when: start.add(Duration(minutes: index)),
          range: NumberRangeLevel.twenty,
          grade: GradeLevel.first,
          mode: TrainingMode.numberFriends,
          taskKey: 'grade-priority-old:$index',
        ),
      ),
      ...List.generate(
        6,
        (index) => _rangeObservation(
          id: MicroCompetencyId.numberDecomposition,
          when: start.add(Duration(hours: 1, minutes: index)),
          range: NumberRangeLevel.twenty,
          grade: GradeLevel.second,
          mode: TrainingMode.numberFriends,
          taskKey: 'range-priority-old:$index',
        ),
      ),
    ]);

    expect(controller.gradeBridgeStatus().isActive, isTrue);
    expect(controller.numberRangeBridgeStatus().isActive, isTrue);

    final plan = controller.buildMyRound();
    final warmUp = plan.first;

    expect(warmUp.gradeBridge, isTrue);
    expect(warmUp.rangeBridge, isFalse);
    expect(warmUp.isBridge, isTrue);
    expect(
      warmUp.targetCompetency,
      MicroCompetencyId.numberDecomposition,
    );
    expect(warmUp.reason, contains('Klasse 1'));
    expect(warmUp.reason, contains('Klasse 2'));
  });

  test('neue eigenständige Evidenz schließt eine Klassenstufen-Brücke', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final start = DateTime(2026, 9, 15, 9);
    controller.microObservations.addAll([
      ...List.generate(
        6,
        (index) => _rangeObservation(
          id: MicroCompetencyId.numberDecomposition,
          when: start.add(Duration(minutes: index)),
          range: NumberRangeLevel.twenty,
          grade: GradeLevel.first,
          mode: TrainingMode.numberFriends,
          taskKey: 'grade-close-old:$index',
        ),
      ),
      _rangeObservation(
        id: MicroCompetencyId.numberDecomposition,
        when: start.add(const Duration(days: 1)),
        range: NumberRangeLevel.hundred,
        grade: GradeLevel.second,
        mode: TrainingMode.numberFriends,
        taskKey: 'grade-close-new:1',
      ),
      _rangeObservation(
        id: MicroCompetencyId.numberDecomposition,
        when: start.add(const Duration(days: 1, minutes: 1)),
        range: NumberRangeLevel.hundred,
        grade: GradeLevel.second,
        mode: TrainingMode.numberFriends,
        taskKey: 'grade-close-new:2',
      ),
    ]);

    final bridge = controller.gradeBridgeStatus();

    expect(
      bridge.confirmedCompetencies,
      contains(MicroCompetencyId.numberDecomposition),
    );
    expect(
      bridge.pendingCompetencies,
      isNot(contains(MicroCompetencyId.numberDecomposition)),
    );
    expect(bridge.progress, 1);
    expect(bridge.isActive, isFalse);
  });

  test('zuletzt instabile Vorstufen-Evidenz wird nicht überbrückt', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final start = DateTime(2026, 9, 15, 9);
    controller.microObservations.addAll(
      List.generate(
        6,
        (index) => _rangeObservation(
          id: MicroCompetencyId.numberDecomposition,
          when: start.add(Duration(minutes: index)),
          range: NumberRangeLevel.twenty,
          grade: GradeLevel.first,
          mode: TrainingMode.numberFriends,
          taskKey: 'grade-unstable-old:$index',
        ),
      ),
    );
    controller.microObservations.add(
      _rangeObservation(
        id: MicroCompetencyId.numberDecomposition,
        when: start.add(const Duration(hours: 1)),
        range: NumberRangeLevel.twenty,
        grade: GradeLevel.first,
        mode: TrainingMode.numberFriends,
        taskKey: 'grade-unstable-latest',
        correct: false,
      ),
    );

    final bridge = controller.gradeBridgeStatus();

    expect(
      bridge.foundationCompetencies,
      isNot(contains(MicroCompetencyId.numberDecomposition)),
    );
  });

  test('Klassenstufen-Brückenrolle bleibt im gespeicherten Rundenplan erhalten', () {
    const segment = GuidedRoundSegment(
      role: GuidedRoundRole.warmUp,
      mode: TrainingMode.numberFriends,
      tasks: 2,
      reason: 'Klassenbrücke',
      targetCompetency: MicroCompetencyId.numberDecomposition,
      gradeBridge: true,
    );

    final restored = GuidedRoundSegment.fromJson(segment.toJson());

    expect(restored.gradeBridge, isTrue);
    expect(restored.rangeBridge, isFalse);
    expect(restored.isBridge, isTrue);
    expect(restored.targetCompetency, MicroCompetencyId.numberDecomposition);
  });

  test('Klassenwechsel verwirft alten Rundenplan und Aufgaben-Diversität', () async {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.twenty;
    controller.recentTaskKeysByMode = <String, List<String>>{
      TrainingMode.numberFriends.name: <String>['plus:6:4'],
    };
    controller.guidedRoundProgress = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[
        GuidedRoundSegment(
          role: GuidedRoundRole.warmUp,
          mode: TrainingMode.numberFriends,
          tasks: 2,
          reason: 'alt',
        ),
      ],
      completedRoles: const <GuidedRoundRole>{},
      gradeLevel: GradeLevel.first,
      numberRange: NumberRangeLevel.twenty,
      startedAt: DateTime(2026, 9, 15, 9),
      updatedAt: DateTime(2026, 9, 15, 9),
      recoveryRequired: false,
    );

    await controller.setGradeLevel(GradeLevel.second);

    expect(controller.gradeLevel, GradeLevel.second);
    expect(controller.numberRange, NumberRangeLevel.hundred);
    expect(controller.guidedRoundProgress, isNull);
    expect(controller.recentTaskKeysByMode, isEmpty);
  });


  test('Stabilitätsplan nennt nächste Wiederholung und Transfer konsistent', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final id = MicroCompetencyId.additionTenBridge;
    controller.microObservations = List.generate(
      6,
      (index) => _microObservation(
        id: id,
        when: DateTime(2026, 9, 1, 8, index),
        source: MicroEvidenceSource.practice,
        taskKey: 'stability-base:$index',
      ),
    );

    expect(controller.microCompetencyProgress(id).state, MicroCompetencyState.secure);
    expect(controller.nextReviewDueAt(id), DateTime(2026, 9, 3, 8, 5));
    expect(controller.nextTransferDueAt(id), DateTime(2026, 9, 1, 8, 5));
    expect(
      controller.microStabilityScheduleText(id, now: DateTime(2026, 9, 2, 9)),
      contains('Abstandskontrolle morgen'),
    );
    expect(
      controller.microStabilityScheduleText(id, now: DateTime(2026, 9, 2, 9)),
      contains('Transfer jetzt fällig'),
    );
  });

  test('stabile und instabile Kontrollen verändern den sichtbaren Abstand', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final id = MicroCompetencyId.additionTenBridge;
    final base = List.generate(
      6,
      (index) => _microObservation(
        id: id,
        when: DateTime(2026, 9, 1, 8, index),
        source: MicroEvidenceSource.practice,
        taskKey: 'stability-base:$index',
      ),
    );
    controller.microObservations = [
      ...base,
      for (var index = 0; index < 2; index++)
        _microObservation(
          id: id,
          when: DateTime(2026, 9, 3, 8, index),
          source: MicroEvidenceSource.review,
          taskKey: 'stability-review:$index',
        ),
    ];
    expect(controller.nextReviewDueAt(id), DateTime(2026, 9, 10, 8, 1));
    expect(
      controller.microStabilityScheduleText(id, now: DateTime(2026, 9, 4, 8)),
      contains('Abstandskontrolle in 6 Tagen'),
    );

    controller.microObservations = [
      ...base,
      _microObservation(
        id: id,
        when: DateTime(2026, 9, 4, 8),
        source: MicroEvidenceSource.review,
        taskKey: 'stability-unstable',
        usedHelp: true,
        helpLevel: 1,
      ),
    ];
    expect(controller.nextReviewDueAt(id), DateTime(2026, 9, 5, 8));
    expect(
      controller.microStabilityScheduleText(id, now: DateTime(2026, 9, 4, 9)),
      contains('Abstandskontrolle morgen'),
    );
  });

  test('gemeisterte Kompetenz erhält vierzehn Tage für Review und Transfer', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final id = MicroCompetencyId.additionTenBridge;
    controller.microObservations = [
      for (var index = 0; index < 6; index++)
        _microObservation(
          id: id,
          when: DateTime(2026, 9, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'mastery-base:$index',
        ),
      for (var index = 0; index < 2; index++)
        _microObservation(
          id: id,
          when: DateTime(2026, 9, 3, 8, index),
          source: MicroEvidenceSource.review,
          taskKey: 'mastery-review:$index',
        ),
      for (var index = 0; index < 2; index++)
        _microObservation(
          id: id,
          when: DateTime(2026, 9, 4, 8, index),
          source: MicroEvidenceSource.transfer,
          mode: TrainingMode.wordProblems,
          taskKey: 'mastery-transfer:$index',
        ),
    ];

    expect(controller.microCompetencyProgress(id).state, MicroCompetencyState.mastered);
    expect(controller.nextReviewDueAt(id), DateTime(2026, 9, 17, 8, 1));
    expect(controller.nextTransferDueAt(id), DateTime(2026, 9, 18, 8, 1));
    final insight = controller.parentInsight(now: DateTime(2026, 9, 5, 8));
    expect(insight.stability, contains('Abstandskontrolle in 12 Tagen'));
    expect(insight.stability, contains('Transfer in 13 Tagen'));
  });

  test('unsichere Kompetenz zeigt bewusst noch keinen Erhaltungsplan', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      _microObservation(
        id: MicroCompetencyId.additionTenBridge,
        when: DateTime(2026, 9, 1, 8),
        source: MicroEvidenceSource.practice,
        taskKey: 'not-secure',
      ),
    ];

    expect(controller.nextReviewDueAt(MicroCompetencyId.additionTenBridge), isNull);
    expect(controller.nextTransferDueAt(MicroCompetencyId.additionTenBridge), isNull);
    expect(
      controller.microStabilityScheduleText(MicroCompetencyId.additionTenBridge),
      contains('Noch kein Erhaltungsplan'),
    );
  });


  test('Confidence trennt zu wenig Daten, Aufbau und aktuelle Evidenz', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final id = MicroCompetencyId.additionTenBridge;

    expect(
      controller.microEvidenceConfidence(id, now: DateTime(2026, 9, 1)).level,
      MicroEvidenceConfidenceLevel.insufficient,
    );

    controller.microObservations = [
      _microObservation(
        id: id,
        when: DateTime(2026, 9, 1, 8),
        source: MicroEvidenceSource.practice,
        taskKey: 'confidence-building',
      ),
    ];
    expect(
      controller.microEvidenceConfidence(id, now: DateTime(2026, 9, 1, 9)).level,
      MicroEvidenceConfidenceLevel.building,
    );

    controller.microObservations = [
      for (var index = 0; index < 6; index++)
        _microObservation(
          id: id,
          when: DateTime(2026, 9, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'confidence-secure:$index',
        ),
      _microObservation(
        id: id,
        when: DateTime(2026, 9, 1, 10),
        source: MicroEvidenceSource.transfer,
        mode: TrainingMode.wordProblems,
        taskKey: 'confidence-transfer',
      ),
    ];
    expect(
      controller.microEvidenceConfidence(id, now: DateTime(2026, 9, 2, 8)).level,
      MicroEvidenceConfidenceLevel.current,
    );
  });

  test('Confidence kennzeichnet fällige Erhaltung ohne Kompetenz zurückzustufen', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final id = MicroCompetencyId.additionTenBridge;
    controller.microObservations = [
      for (var index = 0; index < 6; index++)
        _microObservation(
          id: id,
          when: DateTime(2026, 9, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'confidence-due:$index',
        ),
    ];

    final progress = controller.microCompetencyProgress(id);
    final confidence = controller.microEvidenceConfidence(
      id,
      now: DateTime(2026, 9, 3, 9),
    );
    expect(progress.state, MicroCompetencyState.secure);
    expect(confidence.level, MicroEvidenceConfidenceLevel.maintenanceDue);
    expect(confidence.detail, contains('Abstandskontrolle'));
    expect(confidence.detail, contains('Transfer'));
  });

  test('Confidence priorisiert widersprüchliche neueste Evidenz', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final id = MicroCompetencyId.additionTenBridge;
    controller.microObservations = [
      for (var index = 0; index < 6; index++)
        _microObservation(
          id: id,
          when: DateTime(2026, 9, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'confidence-base:$index',
        ),
      _microObservation(
        id: id,
        when: DateTime(2026, 9, 2, 8),
        source: MicroEvidenceSource.practice,
        taskKey: 'confidence-latest-fail',
        correct: false,
      ),
    ];

    expect(controller.microCompetencyProgress(id).state, MicroCompetencyState.secure);
    final confidence = controller.microEvidenceConfidence(
      id,
      now: DateTime(2026, 9, 2, 9),
    );
    expect(
      confidence.level,
      MicroEvidenceConfidenceLevel.reconfirmationNeeded,
    );
    expect(confidence.detail, contains('letzte Basisaufgabe'));
    final insight = controller.parentInsight(now: DateTime(2026, 9, 2, 9));
    expect(insight.good, contains('erneute selbstständige Bestätigung'));
    expect(insight.confidence, contains('Erneute Bestätigung nötig'));
  });

  test('gemeisterte frische Evidenz wird als aktuell belastbar ausgewiesen', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final id = MicroCompetencyId.additionTenBridge;
    controller.microObservations = [
      for (var index = 0; index < 6; index++)
        _microObservation(
          id: id,
          when: DateTime(2026, 9, 1, 8, index),
          source: MicroEvidenceSource.practice,
          taskKey: 'confidence-mastered-base:$index',
        ),
      for (var index = 0; index < 2; index++)
        _microObservation(
          id: id,
          when: DateTime(2026, 9, 3, 8, index),
          source: MicroEvidenceSource.review,
          taskKey: 'confidence-mastered-review:$index',
        ),
      for (var index = 0; index < 2; index++)
        _microObservation(
          id: id,
          when: DateTime(2026, 9, 4, 8, index),
          source: MicroEvidenceSource.transfer,
          mode: TrainingMode.wordProblems,
          taskKey: 'confidence-mastered-transfer:$index',
        ),
    ];

    expect(controller.microCompetencyProgress(id).state, MicroCompetencyState.mastered);
    final confidence = controller.microEvidenceConfidence(
      id,
      now: DateTime(2026, 9, 5, 8),
    );
    expect(confidence.level, MicroEvidenceConfidenceLevel.current);
    expect(confidence.detail, contains('Basis, Abstand und Transfer'));
  });

  test('Rundenentscheidung zeigt gewählte und zurückgestellte Prioritäten', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final old = DateTime(2026, 9, 1, 8);
    final recent = DateTime(2026, 9, 4, 8);
    controller.microObservations = [
      ..._secureEvidence(
        MicroCompetencyId.additionNoBridge,
        old,
        mode: TrainingMode.practice,
        prefix: 'plus',
      ),
      _microObservation(
        id: MicroCompetencyId.additionNoBridge,
        when: recent,
        source: MicroEvidenceSource.practice,
        taskKey: 'plus:48:7:helped',
        usedHelp: true,
        helpLevel: HelpLevel.visual.value,
      ),
      ..._secureEvidence(
        MicroCompetencyId.subtractionNoBridge,
        old.add(const Duration(hours: 1)),
        mode: TrainingMode.minus,
        prefix: 'minus',
      ),
      ..._secureEvidence(
        MicroCompetencyId.numberRelations,
        old.add(const Duration(hours: 2)),
        mode: TrainingMode.numberWall,
        prefix: 'wall',
      ),
      ..._secureEvidence(
        MicroCompetencyId.moneyCalculation,
        old.add(const Duration(hours: 3)),
        mode: TrainingMode.money,
        prefix: 'money',
      ),
    ];

    final now = DateTime(2026, 9, 10, 8);
    final plan = controller.buildMyRound(now: now);
    final trace = controller.guidedRoundDecisionTrace(now: now);

    expect(trace.primary?.priority, 100);
    expect(trace.primary?.competencyId, plan[1].targetCompetency);
    expect(trace.summary, contains('Gewählt:'));
    expect(trace.summary, contains('Zurückgestellt:'));
    expect(trace.deferred, isNotEmpty);
    expect(trace.deferred.every((item) => !item.selected), isTrue);
    expect(
      trace.deferred.every((item) => item.priority < trace.primary!.priority),
      isTrue,
      reason: 'Zurückgestellte Alternativen dürfen den aktuellen Fokus nicht überstimmen.',
    );
  });

  test('Decision trace priorisiert ausgewählte Einträge vor Alternativen', () {
    const trace = GuidedRoundDecisionTrace(
      items: <GuidedRoundDecisionItem>[
        GuidedRoundDecisionItem(
          kind: GuidedRoundDecisionKind.focus,
          detail: 'Fokus',
          priority: 100,
          selected: true,
        ),
        GuidedRoundDecisionItem(
          kind: GuidedRoundDecisionKind.discovery,
          detail: 'Später',
          priority: 40,
          selected: false,
        ),
      ],
    );

    expect(trace.primary?.kind, GuidedRoundDecisionKind.focus);
    expect(trace.selected, hasLength(1));
    expect(trace.deferred, hasLength(1));
    expect(trace.summary, contains('Aktueller Lernfokus'));
    expect(trace.summary, contains('Neues vorsichtig entdecken'));
  });

  test('balancierte Verdichtung erhält alle noch offenen Rundenrollen', () {
    final current = <GuidedRoundSegment>[
      _roundSegment(GuidedRoundRole.warmUp, TrainingMode.practice, 2, 'warm'),
      _roundSegment(GuidedRoundRole.focus, TrainingMode.minus, 5, 'focus'),
      _roundSegment(GuidedRoundRole.review, TrainingMode.numberWall, 3, 'review'),
      _roundSegment(GuidedRoundRole.apply, TrainingMode.wordProblems, 2, 'apply'),
    ];

    final compacted = GuidedRoundOrchestrator.mergeRemaining(
      current: current,
      updated: current,
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
      regularTaskBudget: 9,
    );

    expect(compacted.fold<int>(0, (sum, segment) => sum + segment.tasks), 9);
    expect(
      compacted.map((segment) => segment.role),
      containsAll(<GuidedRoundRole>[
        GuidedRoundRole.focus,
        GuidedRoundRole.review,
        GuidedRoundRole.apply,
      ]),
    );
    expect(
      compacted.firstWhere((s) => s.role == GuidedRoundRole.focus).tasks,
      3,
    );
    expect(
      compacted.firstWhere((s) => s.role == GuidedRoundRole.review).tasks,
      2,
    );
    expect(
      compacted.firstWhere((s) => s.role == GuidedRoundRole.apply).tasks,
      2,
    );
  });

  test('optionale Kürzung schützt fällige Review- und Transfersegmente', () {
    const plan = <GuidedRoundSegment>[
      GuidedRoundSegment(
        role: GuidedRoundRole.review,
        mode: TrainingMode.numberWall,
        tasks: 3,
        reason: 'fällig',
        reviewEmphasis: true,
      ),
      GuidedRoundSegment(
        role: GuidedRoundRole.apply,
        mode: TrainingMode.wordProblems,
        tasks: 2,
        reason: 'Transfer',
        transferEmphasis: true,
      ),
    ];
    final trimmed = GuidedRoundOrchestrator.trimOptionalRepetition(
      plan: plan,
      completedRoles: const <GuidedRoundRole>{},
      reductions: 2,
    );
    expect(trimmed[0].tasks, 3);
    expect(trimmed[1].tasks, 2);
  });

  test('schwacher Abschnitt entlastet die restliche Runde sofort', () async {
    final controller = AppController();
    await controller.load();
    final current = controller.buildMyRound(now: DateTime(2026, 9, 15, 10));
    final completed = current.first;
    final adaptation = controller.adaptMyRoundAfterSegment(
      current: current,
      completedRoles: <GuidedRoundRole>{completed.role},
      completedSegment: completed,
      result: session(
        mode: completed.mode,
        correct: 0,
        total: 2,
        when: DateTime(2026, 9, 15, 10),
      ),
      now: DateTime(2026, 9, 15, 10, 5),
    );

    expect(adaptation.kind, GuidedRoundAdaptationKind.support);
    expect(adaptation.message, contains('anspruchsvoll'));
    expect(
      adaptation.plan.fold<int>(0, (sum, segment) => sum + segment.tasks),
      lessThanOrEqualTo(9),
    );
    expect(
      adaptation.plan
          .where((segment) => segment.role != completed.role)
          .map((segment) => segment.role)
          .toSet(),
      containsAll(<GuidedRoundRole>[
        GuidedRoundRole.focus,
        GuidedRoundRole.review,
        GuidedRoundRole.apply,
      ].where((role) => role != completed.role)),
    );
  });

  test('sichere Bestätigung kürzt nur optionale Wiederholung', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final start = DateTime(2026, 9, 15, 8);
    controller.microObservations = <MicroCompetencyObservation>[
      ..._secureEvidence(
        MicroCompetencyId.subtractionNoBridge,
        start,
        mode: TrainingMode.minus,
        prefix: 'minus-live',
      ),
      _microObservation(
        id: MicroCompetencyId.subtractionNoBridge,
        when: start.add(const Duration(minutes: 10)),
        source: MicroEvidenceSource.review,
        mode: TrainingMode.minus,
        taskKey: 'minus-live:review:1',
      ),
      _microObservation(
        id: MicroCompetencyId.subtractionNoBridge,
        when: start.add(const Duration(minutes: 11)),
        source: MicroEvidenceSource.review,
        mode: TrainingMode.minus,
        taskKey: 'minus-live:review:2',
      ),
      _microObservation(
        id: MicroCompetencyId.subtractionNoBridge,
        when: start.add(const Duration(minutes: 20)),
        source: MicroEvidenceSource.transfer,
        mode: TrainingMode.wordProblems,
        taskKey: 'minus-live:transfer:1',
      ),
      _microObservation(
        id: MicroCompetencyId.subtractionNoBridge,
        when: start.add(const Duration(minutes: 21)),
        source: MicroEvidenceSource.transfer,
        mode: TrainingMode.wordProblems,
        taskKey: 'minus-live:transfer:2',
      ),
    ];
    final current = <GuidedRoundSegment>[
      const GuidedRoundSegment(
        role: GuidedRoundRole.focus,
        mode: TrainingMode.minus,
        tasks: 5,
        reason: 'Fokus',
        targetCompetency: MicroCompetencyId.subtractionNoBridge,
      ),
      _roundSegment(GuidedRoundRole.review, TrainingMode.numberWall, 3, 'Pflege'),
      _roundSegment(GuidedRoundRole.apply, TrainingMode.wordProblems, 2, 'Anwenden'),
    ];
    final adaptation = controller.adaptMyRoundAfterSegment(
      current: current,
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.focus},
      completedSegment: current.first,
      result: session(
        mode: TrainingMode.minus,
        correct: 5,
        total: 5,
        when: start.add(const Duration(minutes: 30)),
      ),
      now: start.add(const Duration(hours: 1)),
    );

    expect(adaptation.kind, GuidedRoundAdaptationKind.confirmed);
    expect(adaptation.message, contains('ohne Fehlversuch'));
    final protected = adaptation.plan
        .where((segment) => segment.reviewEmphasis || segment.transferEmphasis);
    expect(protected.every((segment) => segment.tasks >= 1), isTrue);
  });

  test('Rundenanpassung wird mit dem Fortschritt persistiert', () {
    final now = DateTime(2026, 9, 15, 12);
    final progress = GuidedRoundProgress(
      plan: <GuidedRoundSegment>[
        _roundSegment(GuidedRoundRole.warmUp, TrainingMode.practice, 2, 'warm'),
      ],
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.warmUp},
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now,
      updatedAt: now,
      recoveryRequired: false,
      lastAdaptationKind: GuidedRoundAdaptationKind.support,
      lastAdaptationMessage: 'Runde bewusst verkürzt.',
    );

    final restored = GuidedRoundProgress.fromJson(progress.toJson());
    expect(restored.lastAdaptationKind, GuidedRoundAdaptationKind.support);
    expect(restored.lastAdaptationMessage, 'Runde bewusst verkürzt.');
  });


  test('Lernabschluss bleibt ohne Zielkompetenz bewusst leer', () {
    final controller = AppController();
    expect(
      controller.learningCompletionInsight(targetCompetency: null),
      isNull,
    );
  });

  test('Lernabschluss erklärt sicheren Stand und fehlende Abstandskontrolle', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final id = MicroCompetencyId.additionTenBridge;
    controller.microObservations = _secureEvidence(
      id,
      DateTime(2026, 9, 16, 8),
      mode: TrainingMode.practice,
      prefix: 'completion-secure',
    );

    final insight = controller.learningCompletionInsight(targetCompetency: id)!;
    expect(insight.title, 'Das klappt schon sicher');
    expect(insight.detail, contains('überwiegend selbstständig'));
    expect(insight.nextStep, contains('nach einer Pause'));
    expect(insight.fluency, isFalse);
  });

  test('Review- und Transferabschluss benennen die jeweilige Evidenzart', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final id = MicroCompetencyId.additionTenBridge;
    controller.microObservations = <MicroCompetencyObservation>[
      ..._secureEvidence(
        id,
        DateTime(2026, 9, 10, 8),
        mode: TrainingMode.practice,
        prefix: 'completion-base',
      ),
      _microObservation(
        id: id,
        when: DateTime(2026, 9, 12, 8),
        source: MicroEvidenceSource.review,
        taskKey: 'completion-review',
      ),
      _microObservation(
        id: id,
        when: DateTime(2026, 9, 13, 8),
        source: MicroEvidenceSource.transfer,
        mode: TrainingMode.wordProblems,
        taskKey: 'completion-transfer',
      ),
    ];

    final review = controller.learningCompletionInsight(
      targetCompetency: id,
      reviewEmphasis: true,
    )!;
    final transfer = controller.learningCompletionInsight(
      targetCompetency: id,
      transferEmphasis: true,
    )!;

    expect(review.detail, contains('zeitlichem Abstand'));
    expect(review.detail, contains('selbstständig'));
    expect(transfer.detail, contains('veränderten Aufgabe'));
    expect(transfer.detail, contains('selbstständig'));
  });

  test('Automatisierungsabschluss trennt Fluency vom fachlichen Lernstand', () {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    final id = MicroCompetencyId.additionNoBridge;
    controller.microObservations = <MicroCompetencyObservation>[
      for (var index = 0; index < 4; index++)
        MicroCompetencyObservation(
          id: id,
          occurredAt: DateTime(2026, 9, 16, 9, index),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.practice,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:${12 + index}:3',
          responseMs: 9000,
        ),
    ];

    final progress = controller.microCompetencyProgress(id);
    expect(progress.state, MicroCompetencyState.secure);
    expect(progress.fluencyState, MicroFluencyState.building);

    final insight = controller.learningCompletionInsight(
      targetCompetency: id,
      fluencyEmphasis: true,
    )!;
    expect(insight.fluency, isTrue);
    expect(insight.detail, contains('fachlich sicher'));
    expect(insight.detail, contains('ohne Countdown'));
  });

}


GuidedRoundSegment _roundSegment(
  GuidedRoundRole role,
  TrainingMode mode,
  int tasks,
  String reason,
) =>
    GuidedRoundSegment(
      role: role,
      mode: mode,
      tasks: tasks,
      reason: reason,
    );


List<MicroCompetencyObservation> _secureEvidence(
  MicroCompetencyId id,
  DateTime start, {
  required TrainingMode mode,
  required String prefix,
}) =>
    List.generate(
      6,
      (index) => _microObservation(
        id: id,
        when: start.add(Duration(minutes: index)),
        source: MicroEvidenceSource.practice,
        mode: mode,
        taskKey: '$prefix:secure:$index',
      ),
    );


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

MicroCompetencyObservation _rangeObservation({
  required MicroCompetencyId id,
  required DateTime when,
  required NumberRangeLevel range,
  required GradeLevel grade,
  required TrainingMode mode,
  required String taskKey,
  bool correct = true,
  bool usedHelp = false,
  double evidenceWeight = 1,
}) =>
    MicroCompetencyObservation(
      id: id,
      occurredAt: when,
      correct: correct,
      evidenceWeight: evidenceWeight,
      source: MicroEvidenceSource.practice,
      usedHelp: usedHelp,
      helpLevel: usedHelp ? 1 : 0,
      mode: mode,
      gradeLevel: grade,
      numberRange: range,
      taskKey: taskKey,
    );
