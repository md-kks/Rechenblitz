import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/screens/curriculum_training_screen.dart';
import 'package:rechenblitz/screens/structured_training_screen.dart';
import 'package:rechenblitz/screens/training_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/widgets/number_answer_pad.dart';
import 'package:rechenblitz/widgets/round_completion_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Rundenrückschau bleibt im Sitzungsentwurf erhalten', () {
    final now = DateTime(2026, 9, 19, 18);
    final progress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.fact,
      mode: TrainingMode.practice,
      targetTasks: 5,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.twenty,
      startedAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now,
      currentTask: const <String, dynamic>{'key': 'plus:4:6'},
      completed: 2,
      correctFirstTry: 1,
      incorrectAttempts: 1,
      firstWrongAnswer: 9,
      firstWrongAnswerLabel: 'Gruppen: 1, 0, 0 Punkte',
      hadCheckpointError: true,
      firstCheckpointAttempt: const CheckpointAttemptReview(
        question: 'Wie viel fehlt bis 10?',
        firstAnswer: '3',
        correctAnswer: '2',
      ),
      attemptReviews: const <RoundAttemptReview>[
        RoundAttemptReview(
          taskNumber: 1,
          taskKey: 'plus:7:5',
          prompt: '7 + 5 = ?',
          correctAnswer: '12',
          firstAnswer: '11',
          wrongAnswerAttempts: 2,
          usedHelp: true,
          hadCheckpointError: true,
          checkpointAttempt: CheckpointAttemptReview(
            question: 'Wie viel fehlt bis 10?',
            firstAnswer: '3',
            correctAnswer: '2',
          ),
        ),
      ],
    );

    final restored = CoreTrainingSessionProgress.fromJson(progress.toJson());

    expect(restored.attemptReviews, hasLength(1));
    expect(restored.attemptReviews.single.taskNumber, 1);
    expect(restored.attemptReviews.single.prompt, '7 + 5 = ?');
    expect(restored.attemptReviews.single.correctAnswer, '12');
    expect(restored.attemptReviews.single.firstAnswer, '11');
    expect(restored.attemptReviews.single.wrongAnswerAttempts, 2);
    expect(restored.attemptReviews.single.usedHelp, isTrue);
    expect(restored.attemptReviews.single.checkpointAttempt?.firstAnswer, '3');
    expect(
      restored.attemptReviews.single.checkpointAttempt?.correctAnswer,
      '2',
    );
    expect(restored.firstWrongAnswer, 9);
    expect(restored.firstWrongAnswerLabel, 'Gruppen: 1, 0, 0 Punkte');
    expect(restored.firstCheckpointAttempt?.question, 'Wie viel fehlt bis 10?');
    expect(restored.firstCheckpointAttempt?.firstAnswer, '3');
    expect(restored.firstCheckpointAttempt?.correctAnswer, '2');
    expect(restored.hasSaneState(now: now), isTrue);

    final legacy = Map<String, dynamic>.from(progress.toJson())
      ..remove('attemptReviews')
      ..remove('firstWrongAnswerLabel');
    final restoredLegacy = CoreTrainingSessionProgress.fromJson(legacy);
    expect(restoredLegacy.attemptReviews, isEmpty);
    expect(restoredLegacy.firstWrongAnswerLabel, isNull);
  });

  testWidgets('Abschluss zeigt konkrete Aufgaben statt nur Fehlerzahl', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showRoundCompletionDialog(
                context,
                completed: 5,
                correctFirstTry: 4,
                attemptReviews: const <RoundAttemptReview>[
                  RoundAttemptReview(
                    taskNumber: 3,
                    taskKey: 'plus:3:17',
                    prompt: '20 = 3 + ?',
                    correctAnswer: '17',
                    firstAnswer: '0',
                    wrongAnswerAttempts: 1,
                    usedHelp: false,
                  ),
                ],
                starsEarned: 1,
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('round-attempt-review')), findsOneWidget);
    expect(find.text('4 von 5 beim ersten Versuch richtig'), findsOneWidget);
    expect(find.text('Aufgabe 3: 20 = 3 + ?'), findsOneWidget);
    expect(find.text('Dein erster Versuch: 0'), findsOneWidget);
    expect(
      find.text('1 Fehlversuch vor der richtigen Lösung'),
      findsOneWidget,
    );
    expect(find.text('Ohne Hilfe gelöst'), findsOneWidget);
    expect(find.text('Richtige Antwort: 17'), findsOneWidget);
    expect(find.textContaining('am Ende richtig gelöst'), findsOneWidget);
  });

  testWidgets('erst falsch dann richtig erscheint in der Rundenrückschau', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;
    controller.facts = <MathFact>[
      MathFact(a: 7, b: 5, operation: MathOperation.plus),
    ];

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

    var pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
    pad.onAnswer(11);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
    pad.onAnswer(12);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Runde geschafft!'), findsOneWidget);
    expect(find.text('0 von 1 beim ersten Versuch richtig'), findsOneWidget);
    expect(find.text('Aufgabe 1: 7 + 5 = ?'), findsOneWidget);
    expect(find.text('Dein erster Versuch: 11'), findsOneWidget);
    expect(find.text('Richtige Antwort: 12'), findsOneWidget);
    final stored = controller.history.single.attemptReviews;
    expect(stored, isNotNull);
    expect(stored, hasLength(1));
    expect(stored!.single.prompt, '7 + 5 = ?');
    expect(stored.single.firstAnswer, '11');
    expect(stored.single.wrongAnswerAttempts, 1);
    expect(stored.single.usedHelp, isFalse);
    expect(stored.single.correctAnswer, '12');
  });

  testWidgets(
    'erste Antwort richtig mit Hilfe bleibt im Abschluss sichtbar',
    (tester) async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.twenty;
      const task = StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt: 'In einer Kiste sind 5 rote und 3 blaue Steine. Wie viele sind es?',
        answer: 8,
        hint: 'Addiere beide Mengen.',
        key: 'review:help-only:sum',
        maxAnswerValue: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StructuredTrainingScreen(
            controller: controller,
            mode: TrainingMode.wordProblems,
            targetTasks: 1,
            announceCompletion: false,
            exerciseGenerator: _FixedStructuredGenerator(task),
          ),
        ),
      );
      await tester.pump();

      final help = find.text('Ich brauche Hilfe');
      expect(help, findsOneWidget);
      await tester.ensureVisible(help);
      await tester.tap(help);
      await tester.pump();

      final pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
      pad.onAnswer(8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Runde geschafft!'), findsOneWidget);
      expect(find.text('1 von 1 beim ersten Versuch richtig'), findsOneWidget);
      expect(find.byKey(const ValueKey('round-attempt-review')), findsNothing);
      expect(find.byKey(const ValueKey('round-help-review')), findsOneWidget);
      expect(find.text('Beim ersten Versuch mit Hilfe'), findsOneWidget);
      expect(
        find.text('Mit Hilfe beim ersten Versuch richtig'),
        findsOneWidget,
      );

      final stored = controller.history.single.attemptReviews;
      expect(stored, isNotNull);
      expect(stored, hasLength(1));
      expect(stored!.single.wrongAnswerAttempts, 0);
      expect(stored.single.usedHelp, isTrue);
      expect(stored.single.firstAnswer, isNull);
      expect(stored.single.correctAnswer, '8');
    },
  );

  testWidgets('Grundrechnen speichert Hilfe trotz richtigem Erstversuch',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;
    controller.facts = <MathFact>[
      MathFact(a: 12, b: 5, operation: MathOperation.minus),
    ];

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

    final help = find.text('Ich brauche Hilfe');
    expect(help, findsOneWidget);
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pump();

    final pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
    pad.onAnswer(7);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('round-help-review')), findsOneWidget);
    expect(find.byKey(const ValueKey('round-attempt-review')), findsNothing);
    final stored = controller.history.single.attemptReviews;
    expect(stored, hasLength(1));
    expect(stored!.single.usedHelp, isTrue);
    expect(stored.single.wrongAnswerAttempts, 0);
  });

  testWidgets('Lehrplan-Aufgabe speichert Hilfe trotz richtigem Erstversuch',
      (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    const task = CurriculumExercise(
      mode: TrainingMode.rounding,
      prompt: 'Runde 153 auf Zehner.',
      answer: 150,
      hint: 'Schau auf die Einerstelle.',
      key: 'review:help-only:rounding',
      maxAnswerValue: 200,
      method: 'Runden',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.rounding,
          targetTasks: 1,
          announceCompletion: false,
          exerciseGenerator: _FixedCurriculumGenerator(task),
        ),
      ),
    );
    await tester.pump();

    final help = find.text('Ich brauche Hilfe');
    expect(help, findsOneWidget);
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pump();

    final pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
    pad.onAnswer(150);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('round-help-review')), findsOneWidget);
    expect(find.byKey(const ValueKey('round-attempt-review')), findsNothing);
    final stored = controller.history.single.attemptReviews;
    expect(stored, hasLength(1));
    expect(stored!.single.usedHelp, isTrue);
    expect(stored.single.wrongAnswerAttempts, 0);
  });

  testWidgets(
    'Grundrechnen behält Touch-Fehlerbeschreibung über Neustart',
    (tester) async {
      final controller = AppController();
      await controller.load();
      await controller.setGradeLevel(GradeLevel.second);
      await controller.setNumberRange(NumberRangeLevel.twenty);
      controller.facts = <MathFact>[
        MathFact(a: 5, b: 4, operation: MathOperation.plus),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: TrainingScreen(
            controller: controller,
            mode: TrainingMode.practice,
            targetTasks: 1,
            targetCompetency: MicroCompetencyId.additionNoBridge,
            transferEmphasis: true,
            announceCompletion: false,
          ),
        ),
      );
      await tester.pump();

      final submit = find.byKey(const ValueKey('touch-number-line-submit'));
      expect(submit, findsOneWidget);
      await tester.tap(submit);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(
        controller.coreTrainingSessionProgress?.firstWrongAnswerLabel,
        'Zahl 5 auf dem Zahlenstrahl',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final restarted = AppController();
      await restarted.load();
      restarted.facts = <MathFact>[
        MathFact(a: 5, b: 4, operation: MathOperation.plus),
      ];
      expect(
        restarted.coreTrainingSessionProgress?.firstWrongAnswerLabel,
        'Zahl 5 auf dem Zahlenstrahl',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TrainingScreen(
            controller: restarted,
            mode: TrainingMode.practice,
            targetTasks: 1,
            targetCompetency: MicroCompetencyId.additionNoBridge,
            transferEmphasis: true,
            announceCompletion: false,
          ),
        ),
      );
      await tester.pump();

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('touch-number-line-slider')),
      );
      slider.onChanged!(9);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('touch-number-line-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Runde geschafft!'), findsOneWidget);
      expect(
        find.text(
          'Dein erster Versuch: Zahl 5 auf dem Zahlenstrahl',
        ),
        findsOneWidget,
      );
      final stored = restarted.history.single.attemptReviews;
      expect(stored, isNotNull);
      expect(stored, hasLength(1));
      expect(stored!.single.firstAnswer, 'Zahl 5 auf dem Zahlenstrahl');
      expect(stored.single.correctAnswer, '9');
    },
  );

  testWidgets('strukturierte Aufgabe erscheint in der Rundenrückschau', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;
    const task = StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt: 'In der Kiste sind 5 rote und 3 blaue Steine. Wie viele sind es?',
      answer: 8,
      hint: 'Addiere beide Mengen.',
      key: 'review:structured:sum',
      maxAnswerValue: 20,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetTasks: 1,
          announceCompletion: false,
          exerciseGenerator: _FixedStructuredGenerator(task),
        ),
      ),
    );
    await tester.pump();

    var pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
    pad.onAnswer(7);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
    pad.onAnswer(6);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
    pad.onAnswer(8);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Runde geschafft!'), findsOneWidget);
    expect(
      find.text(
        'Aufgabe 1: In der Kiste sind 5 rote und 3 blaue Steine. Wie viele sind es?',
      ),
      findsOneWidget,
    );
    expect(find.text('Dein erster Versuch: 7'), findsOneWidget);
    expect(
      find.text('2 Fehlversuche vor der richtigen Lösung'),
      findsOneWidget,
    );
    expect(find.text('Mit Hilfe gelöst'), findsOneWidget);
    expect(find.text('Richtige Antwort: 8'), findsOneWidget);
    final stored = controller.history.single.attemptReviews;
    expect(stored, isNotNull);
    expect(stored, hasLength(1));
    expect(stored!.single.firstAnswer, '7');
    expect(stored.single.wrongAnswerAttempts, 2);
    expect(stored.single.usedHelp, isTrue);
    expect(stored.single.correctAnswer, '8');
  });

  testWidgets('Auswahlaufgabe zeigt sichtbaren Text statt internen Index', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.twenty;
    const task = StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt: 'Welche Farbe passt?',
      answer: 1,
      hint: 'Wähle die passende Farbe.',
      key: 'review:choice:color',
      choices: <String>['Rot', 'Blau', 'Grün'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StructuredTrainingScreen(
          controller: controller,
          mode: TrainingMode.wordProblems,
          targetTasks: 1,
          announceCompletion: false,
          exerciseGenerator: _FixedStructuredGenerator(task),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Rot'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.widgetWithText(FilledButton, 'Blau'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Dein erster Versuch: Rot'), findsOneWidget);
    expect(find.text('Richtige Antwort: Blau'), findsOneWidget);
  });

  testWidgets('Lehrplan-Aufgabe zeigt Einheit in der Rundenrückschau', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    const task = CurriculumExercise(
      mode: TrainingMode.timeDurations,
      prompt: 'Wie viele Minuten sind 2 Stunden?',
      answer: 120,
      hint: 'Eine Stunde hat 60 Minuten.',
      key: 'review:curriculum:minutes',
      answerSuffix: 'min',
      maxAnswerValue: 240,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CurriculumTrainingScreen(
          controller: controller,
          mode: TrainingMode.timeDurations,
          targetTasks: 1,
          announceCompletion: false,
          exerciseGenerator: _FixedCurriculumGenerator(task),
        ),
      ),
    );
    await tester.pump();

    var pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
    pad.onAnswer(100);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
    pad.onAnswer(120);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Runde geschafft!'), findsOneWidget);
    expect(
      find.text('Aufgabe 1: Wie viele Minuten sind 2 Stunden?'),
      findsOneWidget,
    );
    expect(find.text('Dein erster Versuch: 100 min'), findsOneWidget);
    expect(find.text('Richtige Antwort: 120 min'), findsOneWidget);
    final stored = controller.history.single.attemptReviews;
    expect(stored, isNotNull);
    expect(stored, hasLength(1));
    expect(stored!.single.firstAnswer, '100 min');
    expect(stored.single.wrongAnswerAttempts, 1);
    expect(stored.single.usedHelp, isFalse);
    expect(stored.single.correctAnswer, '120 min');
  });

  testWidgets(
    'falscher Zwischenschritt zeigt erste und richtige Auswahl konkret',
    (tester) async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.second;
      controller.numberRange = NumberRangeLevel.twenty;
      const task = StructuredExercise(
        mode: TrainingMode.wordProblems,
        prompt: '5 rote und 3 blaue Steine. Wie viele sind es zusammen?',
        answer: 8,
        hint: 'Addiere beide Mengen.',
        key: 'review:structured:checkpoint',
        maxAnswerValue: 20,
        checkpoints: <ExerciseCheckpoint>[
          ExerciseCheckpoint(
            key: 'review-add-step',
            question: 'Welche Rechnung passt zum ersten Schritt?',
            choices: <String>['5 + 2', '5 + 3', '3 + 3'],
            correctChoice: 1,
            competencyId: MicroCompetencyId.additionNoBridge,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StructuredTrainingScreen(
            controller: controller,
            mode: TrainingMode.wordProblems,
            targetTasks: 1,
            announceCompletion: false,
            exerciseGenerator: _FixedStructuredGenerator(task),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, '5 + 2'));
      await tester.pump();
      expect(
        find.text('Noch nicht. Probier den Schritt noch einmal.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, '5 + 3'));
      await tester.pump(const Duration(milliseconds: 400));

      final pad = tester.widget<NumberAnswerPad>(find.byType(NumberAnswerPad));
      pad.onAnswer(8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Runde geschafft!'), findsOneWidget);
      expect(
        find.text('Zwischenschritt: Welche Rechnung passt zum ersten Schritt?'),
        findsOneWidget,
      );
      expect(
        find.text('Dein erster Versuch im Schritt: 5 + 2'),
        findsOneWidget,
      );
      expect(find.text('Richtig im Schritt: 5 + 3'), findsOneWidget);
    },
  );

  testWidgets('Rückschau bleibt bei 200 Prozent Schrift scrollbar und lesbar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showRoundCompletionDialog(
                context,
                completed: 4,
                correctFirstTry: 2,
                attemptReviews: const <RoundAttemptReview>[
                  RoundAttemptReview(
                    taskNumber: 2,
                    taskKey: 'story:test:1',
                    prompt:
                        'In einer Kiste liegen 18 Karten. 7 kommen dazu. Wie viele Karten sind es jetzt?',
                    correctAnswer: '25 Karten',
                    firstAnswer: '24 Karten',
                    wrongAnswerAttempts: 1,
                  ),
                  RoundAttemptReview(
                    taskNumber: 4,
                    taskKey: 'time:test:1',
                    prompt:
                        'Ein Film beginnt um 14:20 Uhr und endet um 15:05 Uhr.',
                    correctAnswer: '45 min',
                    hadCheckpointError: true,
                  ),
                ],
                starsEarned: 1,
              ),
              child: const Text('Groß öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Groß öffnen'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Richtige Antwort: 25 Karten'), findsOneWidget);
    expect(find.text('Ein Zwischenschritt wurde korrigiert.'), findsOneWidget);
  });
}

class _FixedStructuredGenerator extends StructuredExerciseGenerator {
  _FixedStructuredGenerator(this.exercise);

  final StructuredExercise exercise;

  @override
  StructuredExercise generate({
    required TrainingMode mode,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
    GradeLevel gradeLevel = GradeLevel.second,
    bool transferEmphasis = false,
  }) => exercise;
}

class _FixedCurriculumGenerator extends CurriculumExerciseGenerator {
  _FixedCurriculumGenerator(this.exercise);

  final CurriculumExercise exercise;

  @override
  CurriculumExercise generate({
    required TrainingMode mode,
    required GradeLevel gradeLevel,
    required int maxValue,
    Iterable<String> recentKeys = const <String>[],
    MicroCompetencyId? targetCompetency,
    bool transferEmphasis = false,
  }) => exercise;
}
