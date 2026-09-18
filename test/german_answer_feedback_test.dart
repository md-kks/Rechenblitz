import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/subjects/german/german_answer_feedback.dart';
import 'package:rechenblitz/subjects/german/german_starter_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';

void main() {
  final task = GermanStarterTaskCatalog.tasks.firstWhere(
    (task) => task.interaction == GermanTaskInteraction.typedText,
  );

  test('typed feedback points to capitalization without revealing answer', () {
    final feedback = GermanAnswerFeedback.forIncorrect(
      task,
      'heute regnet es.',
    );

    expect(feedback, contains('Groß- und Kleinschreibung'));
    expect(feedback, isNot(contains(task.acceptedAnswers.first)));
  });

  test('typed feedback identifies missing sentence punctuation', () {
    final feedback = GermanAnswerFeedback.forIncorrect(task, 'Heute regnet es');

    expect(feedback, contains('Satzzeichen am Ende'));
  });

  test('typed feedback checks every accepted sentence variant', () {
    expect(task.acceptedAnswers.length, greaterThanOrEqualTo(2));

    final capitalization = GermanAnswerFeedback.forIncorrect(
      task,
      'es regnet heute.',
    );
    final punctuation = GermanAnswerFeedback.forIncorrect(
      task,
      'Es regnet heute',
    );

    expect(capitalization, contains('Groß- und Kleinschreibung'));
    expect(punctuation, contains('Satzzeichen am Ende'));
    for (final answer in task.acceptedAnswers) {
      expect(capitalization, isNot(contains(answer)));
      expect(punctuation, isNot(contains(answer)));
    }
  });

  test('typed feedback identifies word-order problems', () {
    final feedback = GermanAnswerFeedback.forIncorrect(
      task,
      'Heute es regnet.',
    );

    expect(feedback, contains('Reihenfolge'));
  });

  test('typed feedback stays generic when words are missing', () {
    final feedback = GermanAnswerFeedback.forIncorrect(task, 'Heute regnet.');

    expect(feedback, contains('alle vorgegebenen Wörter'));
  });

  test('choice feedback gives a non-spoiling next action', () {
    final choice = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.singleChoice,
    );
    final wrong = choice.choices.firstWhere(
      (value) => !choice.acceptedAnswers.contains(value),
    );

    final feedback = GermanAnswerFeedback.forIncorrect(choice, wrong);

    expect(feedback, contains('Vergleiche deine Auswahl'));
    for (final answer in choice.acceptedAnswers) {
      expect(feedback, isNot(contains(answer)));
    }
  });

  test(
    'listening feedback points back to the audio without revealing answer',
    () {
      final listening = GermanStarterTaskCatalog.tasks.firstWhere(
        (task) => task.interaction == GermanTaskInteraction.listeningChoice,
      );
      final wrong = listening.choices.firstWhere(
        (value) => !listening.acceptedAnswers.contains(value),
      );

      final feedback = GermanAnswerFeedback.forIncorrect(listening, wrong);

      expect(feedback, contains('Hör die Aufgabe noch einmal'));
      expect(feedback, contains('gesuchte Information'));
      for (final answer in listening.acceptedAnswers) {
        expect(feedback, isNot(contains(answer)));
      }
    },
  );

  test('word-order feedback confirms completeness but not the solution', () {
    final wordOrder = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.wordOrder,
    );
    final wrong = wordOrder.choices.reversed.join(' ');

    final feedback = GermanAnswerFeedback.forIncorrect(wordOrder, wrong);

    expect(feedback, contains('Satzbausteine'));
    expect(feedback, contains('Reihenfolge'));
    for (final answer in wordOrder.acceptedAnswers) {
      expect(feedback, isNot(contains(answer)));
    }
  });
}
