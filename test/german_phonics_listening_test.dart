import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_answer_feedback.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_phonics_listening_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_support_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

void main() {
  test('phonics listening catalog is valid and truly auditory', () {
    expect(GermanPhonicsListeningTaskCatalog.tasks, hasLength(20));
    final spokenWords = <String>{};
    for (final task in GermanPhonicsListeningTaskCatalog.tasks) {
      expect(task.recommendedFromGrade, GradeLevel.first);
      expect(task.competencyId, GermanCompetencyId.letterSoundMatch);
      expect(task.interaction, GermanTaskInteraction.listeningChoice);
      expect(task.requiresSpeech, isTrue);
      expect(task.isWellFormed, isTrue, reason: task.id);
      expect(task.spokenText, isNotNull);
      expect(spokenWords.add(task.spokenText!), isTrue, reason: task.id);
      expect(
        task.prompt.toLowerCase().contains(task.spokenText!.toLowerCase()),
        isFalse,
        reason: 'spoken word leaked into prompt: ${task.id}',
      );
    }
  });

  test('targeted letter-sound practice prefers real listening tasks', () {
    final round = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.first,
      competencyId: GermanCompetencyId.letterSoundMatch,
      history: const <GermanSessionResult>[],
    );

    expect(round, hasLength(6));
    expect(
      round.every(
        (task) => task.interaction == GermanTaskInteraction.listeningChoice,
      ),
      isTrue,
    );
  });

  test('phonics hints teach listening to the first sound', () {
    final task = GermanPhonicsListeningTaskCatalog.tasks.first;
    expect(
      GermanSupportCatalog.firstHintForTask(task),
      contains('ersten Laut'),
    );
    expect(
      GermanSupportCatalog.secondHintForTask(task),
      contains('Buchstabennamen'),
    );
    expect(
      GermanAnswerFeedback.forIncorrect(task, 'N'),
      contains('ganz am Anfang'),
    );
  });

  testWidgets('phonics task auto-plays and can be corrected by touch', (
    tester,
  ) async {
    final task = GermanPhonicsListeningTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-phonics-listen-mouse',
    );
    final spoken = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.first,
          tasks: <GermanTask>[task],
          speak: (text) async => spoken.add(text),
          autoSpeak: (text) async => spoken.add(text),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(spoken, contains('Maus'));
    expect(find.text('Wort anhören'), findsOneWidget);
    final wrongChoice = find.widgetWithText(FilledButton, 'N');
    await tester.ensureVisible(wrongChoice);
    await tester.tap(wrongChoice);
    await tester.pump();
    expect(find.textContaining('Noch nicht'), findsOneWidget);

    final correctChoice = find.widgetWithText(FilledButton, 'M');
    await tester.ensureVisible(correctChoice);
    await tester.tap(correctChoice);
    await tester.pump();
    expect(find.text('Runde geschafft'), findsWidgets);
  });

  test(
    'word recognition uses close reading distractors without answer leak',
    () {
      const expected = <String, List<String>>{
        'g1-read-word-sonne': <String>['Sonne', 'Tonne', 'Sinne'],
        'g1-read-word-blume': <String>['Blume', 'Bluse', 'Bäume'],
        'g1-read-word-regen': <String>['Regen', 'Regeln', 'Rasen'],
        'g1-read-word-tiger': <String>['Tiger', 'Tinte', 'Taler'],
        'g1-read-word-wolke': <String>['Wolke', 'Wolle', 'Woche'],
        'g1-read-word-hase': <String>['Hase', 'Hose', 'Nase'],
      };

      final tasks = GermanTaskCatalog.forCompetency(
        GermanCompetencyId.wordRecognition,
      );
      for (final entry in expected.entries) {
        final task = tasks.firstWhere((task) => task.id == entry.key);
        expect(task.choices, entry.value);
        expect(task.accessiblePrompt, isNotNull);
        expect(
          task.accessiblePrompt!.toLowerCase().contains(
            task.acceptedAnswers.single.toLowerCase(),
          ),
          isFalse,
          reason: '${task.id} leaks its answer to read-aloud',
        );
      }
    },
  );

  test('word recognition feedback asks the child to really read', () {
    final task = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.wordRecognition,
    ).first;
    expect(
      GermanAnswerFeedback.forIncorrect(task, task.choices.last),
      contains('links nach rechts'),
    );
  });
}
