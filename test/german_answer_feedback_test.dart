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

  test('choice feedback stays neutral', () {
    final choice = GermanStarterTaskCatalog.tasks.firstWhere(
      (task) => task.interaction == GermanTaskInteraction.singleChoice,
    );

    expect(
      GermanAnswerFeedback.forIncorrect(choice, 'falsch'),
      GermanAnswerFeedback.retry,
    );
  });
}
