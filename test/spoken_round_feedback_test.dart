import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/accessibility_preferences.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/screens/my_round_screen.dart';
import 'package:rechenblitz/screens/parent_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/speech_service.dart';
import 'package:rechenblitz/widgets/round_completion_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingSpeechService extends SpeechService {
  final List<String> spoken = <String>[];
  final List<double> rates = <double>[];
  int stopCalls = 0;

  @override
  Future<void> speak(String text, {double rate = 0.45}) async {
    spoken.add(text);
    rates.add(rate);
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }
}

TrainingSessionResult _result({
  required DateTime startedAt,
  required DateTime finishedAt,
  int total = 4,
  int correctFirstTry = 3,
  int incorrectAttempts = 1,
}) => TrainingSessionResult(
  mode: TrainingMode.practice,
  startedAt: startedAt,
  finishedAt: finishedAt,
  total: total,
  correctFirstTry: correctFirstTry,
  incorrectAttempts: incorrectAttempts,
  plusCorrect: correctFirstTry,
  plusTotal: total,
  minusCorrect: 0,
  minusTotal: 0,
  averageResponseMs: 1200,
  gradeLevel: GradeLevel.second,
  numberRange: NumberRangeLevel.twenty,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('alte Audio-Einstellungen bekommen gesprochenes Rundenfeedback', () {
    final legacy = AccessibilityPreferences.fromJson(<String, dynamic>{
      'readAloud': false,
      'speechRate': 0.5,
    });
    final disabled = AccessibilityPreferences.fromJson(<String, dynamic>{
      'spokenRoundFeedback': false,
    });

    expect(legacy.spokenRoundFeedback, isTrue);
    expect(disabled.spokenRoundFeedback, isFalse);
    expect(
      disabled
          .copyWith(spokenRoundFeedback: true)
          .toJson()['spokenRoundFeedback'],
      isTrue,
    );
  });

  test(
    'gesprochenes Feedback erklärt einen korrigierten Erstversuch eindeutig',
    () {
      final controller = AppController();
      final started = DateTime(2026, 9, 20, 8);
      final feedback = controller.roundSpokenFeedback(
        result: _result(
          startedAt: started,
          finishedAt: started.add(const Duration(minutes: 3)),
          total: 5,
          correctFirstTry: 4,
          incorrectAttempts: 3,
        ),
        targetCompetency: null,
      );

      expect(
        feedback,
        contains('Eine Aufgabe brauchte mehr als einen Versuch'),
      );
      expect(feedback, contains('am Ende richtig gelöst'));
      expect(feedback, isNot(contains('noch knifflig')));
      expect(feedback, isNot(contains('war falsch')));
      expect(feedback, isNot(contains('3 Aufgaben')));
    },
  );

  test('gesprochenes Feedback nennt die Zahl korrigierter Aufgaben', () {
    final controller = AppController();
    final started = DateTime(2026, 9, 20, 8);
    final feedback = controller.roundSpokenFeedback(
      result: _result(
        startedAt: started,
        finishedAt: started.add(const Duration(minutes: 3)),
        total: 5,
        correctFirstTry: 3,
        incorrectAttempts: 4,
      ),
      targetCompetency: null,
    );

    expect(feedback, contains('2 Aufgaben brauchten mehr als einen Versuch'));
    expect(feedback, contains('am Ende richtig gelöst'));
  });

  test('komplett direkte Runde wird gesprochen ausdrücklich so benannt', () {
    final controller = AppController();
    final started = DateTime(2026, 9, 20, 8);
    final feedback = controller.roundSpokenFeedback(
      result: _result(
        startedAt: started,
        finishedAt: started.add(const Duration(minutes: 3)),
        total: 5,
        correctFirstTry: 5,
        incorrectAttempts: 0,
      ),
      targetCompetency: null,
    );

    expect(
      feedback,
      contains('Alle 5 Aufgaben waren beim ersten Versuch richtig'),
    );
  });

  test('gezieltes Lernfeedback behält Erstversuch-Klarheit', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.twenty;
    final started = DateTime(2026, 9, 20, 8);
    final feedback = controller.roundSpokenFeedback(
      result: _result(
        startedAt: started,
        finishedAt: started.add(const Duration(minutes: 3)),
        total: 4,
        correctFirstTry: 3,
        incorrectAttempts: 1,
      ),
      targetCompetency: MicroCompetencyId.additionNoBridge,
    );

    expect(feedback, contains('Eine Aufgabe brauchte mehr als einen Versuch'));
    expect(feedback, contains('am Ende richtig gelöst'));
    expect(feedback, contains('Plus ohne Zehnerübergang'));
  });

  test('Rundenfeedback unterscheidet Hilfe von selbstständigem Erfolg', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.twenty;
    final started = DateTime(2026, 9, 17, 15);
    final finished = started.add(const Duration(minutes: 4));
    controller.microObservations = <MicroCompetencyObservation>[
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: started.add(const Duration(minutes: 1)),
        correct: true,
        evidenceWeight: 0.65,
        source: MicroEvidenceSource.practice,
        usedHelp: true,
        helpLevel: 2,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        taskKey: '8+1',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: started.add(const Duration(minutes: 2)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        taskKey: '7+2',
      ),
    ];

    final feedback = controller.roundSpokenFeedback(
      result: _result(startedAt: started, finishedAt: finished),
      targetCompetency: MicroCompetencyId.additionNoBridge,
    );

    expect(feedback, contains('mit Hilfe gestartet'));
    expect(feedback, contains('ohne Hilfe geklappt'));
    expect(feedback, isNot(contains('alles sicher')));
  });

  test(
    'nur mit Hilfe gelöste Runde wird nicht als selbstständig ausgegeben',
    () {
      final controller = AppController()
        ..gradeLevel = GradeLevel.second
        ..numberRange = NumberRangeLevel.twenty;
      final started = DateTime(2026, 9, 17, 15);
      final finished = started.add(const Duration(minutes: 3));
      controller.microObservations = <MicroCompetencyObservation>[
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: started.add(const Duration(minutes: 1)),
          correct: true,
          evidenceWeight: 0.5,
          source: MicroEvidenceSource.practice,
          usedHelp: true,
          helpLevel: 3,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.twenty,
          taskKey: '6+3',
        ),
      ];

      final feedback = controller.roundSpokenFeedback(
        result: _result(startedAt: started, finishedAt: finished),
        targetCompetency: MicroCompetencyId.additionNoBridge,
      );

      expect(feedback, contains('eine Hilfe geholfen'));
      expect(feedback, contains('wieder selbstständig'));
      expect(feedback, isNot(contains('schon sicher')));
    },
  );

  test('alte Transfer-Evidenz wird nicht als heutiger Transfer ausgegeben', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.twenty;
    final started = DateTime(2026, 9, 21, 14);
    final finished = started.add(const Duration(minutes: 3));
    controller.microObservations = <MicroCompetencyObservation>[
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: started.subtract(const Duration(days: 7)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.transfer,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        taskKey: 'story:transfer:old',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: started.add(const Duration(minutes: 1)),
        correct: false,
        evidenceWeight: 1,
        source: MicroEvidenceSource.transfer,
        usedHelp: false,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        taskKey: 'story:transfer:today',
      ),
    ];

    final feedback = controller.roundSpokenFeedback(
      result: _result(
        startedAt: started,
        finishedAt: finished,
        total: 1,
        correctFirstTry: 0,
        incorrectAttempts: 1,
      ),
      targetCompetency: MicroCompetencyId.additionNoBridge,
      transferEmphasis: true,
    );

    expect(feedback, contains('in einer neuen Aufgabe ausprobiert'));
    expect(
      feedback,
      isNot(contains('selbstständig angewendet')),
    );
  });

  test(
    'aktueller selbstständiger Transfer wird als heutiger Erfolg benannt',
    () {
      final controller = AppController()
        ..gradeLevel = GradeLevel.second
        ..numberRange = NumberRangeLevel.twenty;
      final started = DateTime(2026, 9, 21, 14);
      final finished = started.add(const Duration(minutes: 3));
      controller.microObservations = <MicroCompetencyObservation>[
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: started.add(const Duration(minutes: 1)),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.transfer,
          usedHelp: false,
          mode: TrainingMode.wordProblems,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.twenty,
          taskKey: 'story:transfer:today',
        ),
      ];

      final feedback = controller.roundSpokenFeedback(
        result: _result(
          startedAt: started,
          finishedAt: finished,
          total: 1,
          correctFirstTry: 1,
          incorrectAttempts: 0,
        ),
        targetCompetency: MicroCompetencyId.additionNoBridge,
        transferEmphasis: true,
      );

      expect(
        feedback,
        contains('in einer neuen Aufgabe selbstständig angewendet'),
      );
    },
  );

  test(
    'alte Review-Evidenz wird nicht als heutiger Review-Erfolg ausgegeben',
    () {
      final controller = AppController()
        ..gradeLevel = GradeLevel.second
        ..numberRange = NumberRangeLevel.twenty;
      final started = DateTime(2026, 9, 21, 14);
      final finished = started.add(const Duration(minutes: 3));
      controller.microObservations = <MicroCompetencyObservation>[
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: started.subtract(const Duration(days: 7)),
          correct: true,
          evidenceWeight: 1,
          source: MicroEvidenceSource.review,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.twenty,
          taskKey: 'review:old',
        ),
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionNoBridge,
          occurredAt: started.add(const Duration(minutes: 1)),
          correct: false,
          evidenceWeight: 1,
          source: MicroEvidenceSource.review,
          usedHelp: false,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.twenty,
          taskKey: 'review:today',
        ),
      ];

      final feedback = controller.roundSpokenFeedback(
        result: _result(
          startedAt: started,
          finishedAt: finished,
          total: 1,
          correctFirstTry: 0,
          incorrectAttempts: 1,
        ),
        targetCompetency: MicroCompetencyId.additionNoBridge,
        reviewEmphasis: true,
      );

      expect(feedback, contains('nach einer Pause wiederholt'));
      expect(feedback, isNot(contains('wieder selbstständig geklappt')));
    },
  );

  test('aktueller selbstständiger Review wird als heutiger Erfolg benannt', () {
    final controller = AppController()
      ..gradeLevel = GradeLevel.second
      ..numberRange = NumberRangeLevel.twenty;
    final started = DateTime(2026, 9, 21, 14);
    final finished = started.add(const Duration(minutes: 3));
    controller.microObservations = <MicroCompetencyObservation>[
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: started.add(const Duration(minutes: 1)),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.review,
        usedHelp: false,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        taskKey: 'review:today',
      ),
    ];

    final feedback = controller.roundSpokenFeedback(
      result: _result(
        startedAt: started,
        finishedAt: finished,
        total: 1,
        correctFirstTry: 1,
        incorrectAttempts: 0,
      ),
      targetCompetency: MicroCompetencyId.additionNoBridge,
      reviewEmphasis: true,
    );

    expect(
      feedback,
      contains('nach einer Pause wieder selbstständig geklappt'),
    );
  });

  test('Meine Runde nennt mehrere gestärkte Lernziele ohne TTS-Liste zu überladen', () {
    final controller = AppController();
    final feedback = controller.guidedRoundSpokenFeedback(
      strengthenedCompetencies: const <String>[
        'Plus über den Zehner',
        'Zeitspannen',
        'Daten lesen',
        'Plus über den Zehner',
      ],
      nextCompetency: 'Zeitspannen',
    );

    expect(feedback, contains('„Plus über den Zehner“, „Zeitspannen“'));
    expect(feedback, contains('noch ein weiteres Lernziel'));
    expect(feedback, contains('Eines davon üben wir beim nächsten Mal kurz weiter'));
    expect(feedback, isNot(contains('Daten lesen')));
  });

  test('Meine Runde nennt ein neues nächstes Lernziel ausdrücklich', () {
    final controller = AppController();
    final feedback = controller.guidedRoundSpokenFeedback(
      strengthenedCompetencies: const <String>[
        'Plus über den Zehner',
        'Zeitspannen',
      ],
      nextCompetency: 'Daten lesen',
    );

    expect(feedback, contains('„Plus über den Zehner“ und „Zeitspannen“'));
    expect(feedback, contains('Nächstes Mal geht es mit „Daten lesen“ weiter'));
  });

  test(
    'automatisches Rundenfeedback respektiert Schalter und Sprechtempo',
    () async {
      final speech = _RecordingSpeechService();
      final controller = AppController(speech: speech)
        ..accessibilityPreferences = const AccessibilityPreferences(
          spokenRoundFeedback: false,
          speechRate: 0.55,
        );

      await controller.speakRoundFeedback('Nicht sprechen');
      expect(speech.spoken, isEmpty);

      controller.accessibilityPreferences = controller.accessibilityPreferences
          .copyWith(spokenRoundFeedback: true);
      await controller.speakRoundFeedback('Kurzes Feedback');

      expect(speech.spoken, <String>['Kurzes Feedback']);
      expect(speech.rates.single, closeTo(0.55, 0.001));
    },
  );

  testWidgets(
    'Abschlussdialog spricht einmal automatisch und kann wiederholen',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => showRoundCompletionDialog(
                  context,
                  completed: 5,
                  correctFirstTry: 4,
                  starsEarned: 1,
                  spokenFeedback: 'Runde geschafft. Heute hast du den Zehnerübergang geübt.',
                  autoSpeakSpokenFeedback: true,
                  onSpeakSpokenFeedback: () async {
                    calls += 1;
                  },
                ),
                child: const Text('Öffnen'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(
        find.byKey(const ValueKey('round-spoken-feedback')),
        findsOneWidget,
      );
      expect(find.textContaining('Zehnerübergang geübt'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('round-spoken-feedback-replay')),
      );
      await tester.pump();
      expect(calls, 2);
    },
  );

  testWidgets('fertige Einzelübung spricht das echte Abschlussfeedback', (
    tester,
  ) async {
    final speech = _RecordingSpeechService();
    final controller = AppController(speech: speech);
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;
    final fact = MathFact(a: 4, b: 2, operation: MathOperation.plus);
    controller.facts = <MathFact>[fact];
    final started = DateTime.now().subtract(const Duration(minutes: 1));
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.practice,
      targetTasks: 1,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.twenty,
      startedAt: started,
      updatedAt: DateTime.now(),
      currentTask: <String, dynamic>{'key': fact.key},
      completed: 1,
      correctFirstTry: 1,
      responseTimes: const <int>[900],
      taskResolved: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 1,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(speech.spoken, hasLength(1));
    expect(speech.spoken.single, contains('Runde geschafft'));
    expect(find.byKey(const ValueKey('round-spoken-feedback')), findsOneWidget);
  });

  testWidgets('Zwischenteil von Meine Runde bleibt sprachlich still', (
    tester,
  ) async {
    final speech = _RecordingSpeechService();
    final controller = AppController(speech: speech);
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;
    final fact = MathFact(a: 5, b: 2, operation: MathOperation.plus);
    controller.facts = <MathFact>[fact];
    final started = DateTime.now().subtract(const Duration(minutes: 1));
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.practice,
      targetTasks: 1,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.twenty,
      startedAt: started,
      updatedAt: DateTime.now(),
      currentTask: <String, dynamic>{'key': fact.key},
      completed: 1,
      correctFirstTry: 1,
      responseTimes: const <int>[800],
      taskResolved: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TrainingScreen(
          controller: controller,
          mode: TrainingMode.practice,
          targetTasks: 1,
          announceCompletion: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(speech.spoken, isEmpty);
    expect(find.text('Runde geschafft!'), findsOneWidget);
    expect(find.byKey(const ValueKey('round-spoken-feedback')), findsNothing);
  });

  testWidgets('fertige Meine Runde spricht beim Wiederöffnen nicht erneut', (
    tester,
  ) async {
    final speech = _RecordingSpeechService();
    final controller = AppController(speech: speech);
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;
    final now = DateTime.now();
    controller.guidedRoundProgress = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[
        GuidedRoundSegment(
          role: GuidedRoundRole.focus,
          mode: TrainingMode.practice,
          tasks: 3,
          reason: 'Passender Schwerpunkt',
          targetCompetency: MicroCompetencyId.additionNoBridge,
        ),
      ],
      completedRoles: const <GuidedRoundRole>{GuidedRoundRole.focus},
      completedTaskCounts: const <GuidedRoundRole, int>{
        GuidedRoundRole.focus: 3,
      },
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.twenty,
      startedAt: now.subtract(const Duration(minutes: 6)),
      updatedAt: now,
      recoveryRequired: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: MyRoundScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(speech.spoken, isEmpty);
    expect(
      find.byKey(const ValueKey('guided-round-spoken-feedback')),
      findsOneWidget,
    );
    expect(find.textContaining('Plus ohne Zehnerübergang'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('guided-round-feedback-replay')),
    );
    await tester.pump();
    expect(speech.spoken, hasLength(1));
  });

  testWidgets(
    'Meine Runde spricht erst nach dem letzten Segment genau einmal',
    (tester) async {
      final speech = _RecordingSpeechService();
      final controller = AppController(speech: speech);
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.twenty;
      final fact = MathFact(a: 6, b: 2, operation: MathOperation.plus);
      controller.facts = <MathFact>[fact];
      final now = DateTime.now();
      controller.guidedRoundProgress = GuidedRoundProgress(
        plan: const <GuidedRoundSegment>[
          GuidedRoundSegment(
            role: GuidedRoundRole.warmUp,
            mode: TrainingMode.practice,
            tasks: 1,
            reason: 'Kurz ankommen',
            targetCompetency: MicroCompetencyId.additionNoBridge,
          ),
          GuidedRoundSegment(
            role: GuidedRoundRole.focus,
            mode: TrainingMode.practice,
            tasks: 1,
            reason: 'Passender Schwerpunkt',
            targetCompetency: MicroCompetencyId.additionNoBridge,
          ),
          GuidedRoundSegment(
            role: GuidedRoundRole.review,
            mode: TrainingMode.practice,
            tasks: 1,
            reason: 'Kurz wiederholen',
            targetCompetency: MicroCompetencyId.additionNoBridge,
          ),
          GuidedRoundSegment(
            role: GuidedRoundRole.apply,
            mode: TrainingMode.practice,
            tasks: 1,
            reason: 'Zum Schluss anwenden',
            targetCompetency: MicroCompetencyId.additionNoBridge,
          ),
        ],
        completedRoles: const <GuidedRoundRole>{
          GuidedRoundRole.warmUp,
          GuidedRoundRole.focus,
          GuidedRoundRole.review,
        },
        completedTaskCounts: const <GuidedRoundRole, int>{
          GuidedRoundRole.warmUp: 1,
          GuidedRoundRole.focus: 1,
          GuidedRoundRole.review: 1,
        },
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        startedAt: now.subtract(const Duration(minutes: 3)),
        updatedAt: now,
        recoveryRequired: false,
      );
      controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
        kind: CoreTrainingKind.fact,
        mode: TrainingMode.practice,
        targetTasks: 1,
        targetCompetency: MicroCompetencyId.additionNoBridge,
        adaptiveLength: true,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.twenty,
        startedAt: now.subtract(const Duration(minutes: 2)),
        updatedAt: now,
        currentTask: <String, dynamic>{'key': fact.key},
        completed: 1,
        correctFirstTry: 1,
        responseTimes: const <int>[800],
        taskResolved: true,
      );

      await tester.pumpWidget(
        MaterialApp(home: MyRoundScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('round-next-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Runde geschafft!'), findsOneWidget);
      expect(speech.spoken, isEmpty);

      await tester.tap(find.byKey(const ValueKey('round-completion-done')));
      await tester.pumpAndSettle();

      expect(speech.spoken, hasLength(1));
      expect(speech.spoken.single, contains('Deine Runde ist geschafft'));
      expect(
        find.byKey(const ValueKey('guided-round-spoken-feedback')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Elternbereich kann Rundenfeedback geräteweit abschalten', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: ParentScreen(controller: controller)),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('parent-spoken-round-feedback')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(controller.accessibilityPreferences.spokenRoundFeedback, isTrue);
    await tester.tap(
      find.byKey(const ValueKey('parent-spoken-round-feedback')),
    );
    await tester.pumpAndSettle();

    expect(controller.accessibilityPreferences.spokenRoundFeedback, isFalse);
    expect(controller.accessibilityPreferences.readAloud, isFalse);
  });
}
