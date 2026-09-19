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
      attemptReviews: const <RoundAttemptReview>[
        RoundAttemptReview(
          taskNumber: 1,
          taskKey: 'plus:7:5',
          prompt: '7 + 5 = ?',
          correctAnswer: '12',
        ),
      ],
    );

    final restored = CoreTrainingSessionProgress.fromJson(progress.toJson());

    expect(restored.attemptReviews, hasLength(1));
    expect(restored.attemptReviews.single.taskNumber, 1);
    expect(restored.attemptReviews.single.prompt, '7 + 5 = ?');
    expect(restored.attemptReviews.single.correctAnswer, '12');
    expect(restored.hasSaneState(now: now), isTrue);

    final legacy = Map<String, dynamic>.from(progress.toJson())
      ..remove('attemptReviews');
    expect(
      CoreTrainingSessionProgress.fromJson(legacy).attemptReviews,
      isEmpty,
    );
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
    expect(find.text('Richtige Antwort: 12'), findsOneWidget);
  });

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
    expect(find.text('Richtige Antwort: 8'), findsOneWidget);
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
    expect(find.text('Richtige Antwort: 120 min'), findsOneWidget);
  });

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
