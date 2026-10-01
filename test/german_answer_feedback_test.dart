import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/subjects/german/german_answer_feedback.dart';
import 'package:rechenblitz/subjects/german/german_sentence_structure_expansion_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_starter_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_thin_pool_expansion_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_writing_revision_expansion_task_catalog.dart';

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

  test('typed feedback identifies one missing word without revealing it', () {
    final feedback = GermanAnswerFeedback.forIncorrect(task, 'Heute regnet.');

    expect(feedback, contains('Ein Wort fehlt noch'));
    expect(feedback, isNot(contains('es')));
  });

  test('typed feedback identifies one extra word without revealing answer', () {
    final feedback = GermanAnswerFeedback.forIncorrect(
      task,
      'Heute regnet es stark.',
    );

    expect(feedback, contains('Ein Wort ist zu viel'));
  });

  test('typed feedback identifies internal punctuation problems', () {
    final connection = GermanWritingRevisionExpansionTaskCatalog.tasks
        .firstWhere((task) => task.id == 'g4-connect-frost-write');
    final feedback = GermanAnswerFeedback.forIncorrect(
      connection,
      'Die Wege sind glatt weil es nachts gefroren hat.',
    );

    expect(feedback, contains('Zeichensetzung'));
    expect(feedback, contains('Kommas'));
    expect(feedback, isNot(contains(connection.acceptedAnswers.first)));
  });

  test('typed feedback combines capitalization and punctuation diagnosis', () {
    final connection = GermanWritingRevisionExpansionTaskCatalog.tasks
        .firstWhere((task) => task.id == 'g4-connect-frost-write');
    final feedback = GermanAnswerFeedback.forIncorrect(
      connection,
      'die wege sind glatt weil es nachts gefroren hat.',
    );

    expect(feedback, contains('Groß- und Kleinschreibung'));
    expect(feedback, contains('Zeichensetzung'));
  });

  test('sentence-writing feedback identifies one close spelling error', () {
    final sentence = GermanSentenceStructureExpansionTaskCatalog.tasks
        .firstWhere((task) => task.id == 'g3-write-morning-bus');
    final feedback = GermanAnswerFeedback.forIncorrect(
      sentence,
      'Am Morgen färt Nora mit dem Bus zur Schule.',
    );

    expect(feedback, contains('Ein Wort ist noch nicht richtig geschrieben'));
    expect(feedback, isNot(contains('fährt')));
  });

  test('token feedback identifies one missing selection', () {
    final selection = GermanThinPoolExpansionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-family-mark-write',
    );
    final feedback = GermanAnswerFeedback.forIncorrect(
      selection,
      'schreiben · Schreiber',
    );

    expect(feedback, contains('Eine passende Markierung fehlt noch'));
    expect(feedback, contains('Wortstamm'));
    expect(feedback, isNot(contains('Schreibheft')));
  });

  test('token feedback identifies one extra selection', () {
    final selection = GermanThinPoolExpansionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-family-mark-write',
    );
    final feedback = GermanAnswerFeedback.forIncorrect(
      selection,
      'schreiben · Schreiber · Schreibheft · schreien',
    );

    expect(feedback, contains('Eine Markierung ist zu viel'));
    expect(feedback, contains('Wortstamm'));
  });

  test('token feedback identifies one selection to swap', () {
    final selection = GermanThinPoolExpansionTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-family-mark-write',
    );
    final feedback = GermanAnswerFeedback.forIncorrect(
      selection,
      'schreiben · Schreiber · schreien',
    );

    expect(feedback, contains('tausche genau eine aus'));
    expect(feedback, isNot(contains('Schreibheft')));
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
