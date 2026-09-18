import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';

void main() {
  test('entire German catalog satisfies structural task invariants', () {
    for (final task in GermanTaskCatalog.tasks) {
      expect(task.isWellFormed, isTrue, reason: task.id);
    }
  });

  test('single-choice task rejects duplicate and ambiguous options', () {
    final duplicate = _task(
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: const <String>['Hund'],
      choices: const <String>['Hund', ' hund ', 'Katze'],
    );
    final multipleCorrect = _task(
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: const <String>['Hund', 'Katze'],
      choices: const <String>['Hund', 'Katze', 'Maus'],
    );

    expect(duplicate.isWellFormed, isFalse);
    expect(multipleCorrect.isWellFormed, isFalse);
  });

  test('single-choice task matches answer and option after normalization', () {
    final task = _task(
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: const <String>['Der Hund'],
      choices: const <String>['  der   hund ', 'Die Katze'],
    );

    expect(task.isWellFormed, isTrue);
  });

  test('word-order task requires every offered chunk exactly once', () {
    final valid = _task(
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: const <String>['Morgen räumt Ben sein Zimmer auf'],
      choices: const <String>['Morgen', 'räumt', 'Ben', 'sein Zimmer', 'auf'],
    );
    final missingChunk = _task(
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: const <String>['Morgen räumt Ben auf'],
      choices: const <String>['Morgen', 'räumt', 'Ben', 'sein Zimmer', 'auf'],
    );
    final repeatedChunk = _task(
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: const <String>['Morgen räumt Ben Ben auf'],
      choices: const <String>['Morgen', 'räumt', 'Ben', 'sein Zimmer', 'auf'],
    );

    expect(valid.isWellFormed, isTrue);
    expect(missingChunk.isWellFormed, isFalse);
    expect(repeatedChunk.isWellFormed, isFalse);
  });

  test('word-order task supports multiple valid chunk arrangements', () {
    final task = _task(
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: const <String>[
        'Heute liest Mia leise',
        'Mia liest heute leise',
      ],
      choices: const <String>['Heute', 'liest', 'Mia', 'leise'],
    );

    expect(task.isWellFormed, isTrue);
  });

  test('typed task must stay free of choice-button data', () {
    final valid = _task(
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: const <String>['Heute regnet es.'],
    );
    final invalid = _task(
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: const <String>['Heute regnet es.'],
      choices: const <String>['Heute regnet es.'],
    );

    expect(valid.isWellFormed, isTrue);
    expect(invalid.isWellFormed, isFalse);
  });

  test('listening task requires spoken content', () {
    final valid = _task(
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: const <String>['acht Uhr'],
      choices: const <String>['acht Uhr', 'neun Uhr'],
      spokenText: 'Die Schule beginnt um acht Uhr.',
    );
    final invalid = _task(
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: const <String>['acht Uhr'],
      choices: const <String>['acht Uhr', 'neun Uhr'],
    );

    expect(valid.isWellFormed, isTrue);
    expect(invalid.isWellFormed, isFalse);
  });

  test('task rejects blank prompt or blank answers', () {
    final blankPrompt = _task(
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: const <String>['Antwort'],
      prompt: '   ',
    );
    final blankAnswer = _task(
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: const <String>['   '],
    );

    expect(blankPrompt.isWellFormed, isFalse);
    expect(blankAnswer.isWellFormed, isFalse);
  });
}

GermanTask _task({
  required GermanTaskInteraction interaction,
  required List<String> acceptedAnswers,
  List<String> choices = const <String>[],
  String prompt = 'Aufgabe',
  String? spokenText,
}) => GermanTask(
  id: 'test-task',
  competencyId: GermanCompetencyId.wordRecognition,
  recommendedFromGrade: GradeLevel.first,
  instruction: 'Bearbeite die Aufgabe.',
  prompt: prompt,
  interaction: interaction,
  acceptedAnswers: acceptedAnswers,
  choices: choices,
  spokenText: spokenText,
);
