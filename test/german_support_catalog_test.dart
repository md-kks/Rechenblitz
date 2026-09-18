import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_support_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';

void main() {
  test('every German competency has two non-empty support levels', () {
    for (final id in GermanCompetencyId.values) {
      expect(
        GermanSupportCatalog.firstHint(id).trim(),
        isNotEmpty,
        reason: 'first hint: ${id.name}',
      );
      expect(
        GermanSupportCatalog.secondHint(id).trim(),
        isNotEmpty,
        reason: 'second hint: ${id.name}',
      );
    }
  });

  test('constrained word order respects the required sentence start', () {
    final task = GermanTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g3-order-room-separable',
    );

    final first = GermanSupportCatalog.firstHintForTask(task);
    final second = GermanSupportCatalog.secondHintForTask(task);

    expect(first, contains('vorgegebenen Satzanfang'));
    expect(first, contains('zweiter Stelle'));
    expect(first, isNot(contains('Beginne mit der Person')));
    expect(second, contains('trennbaren Verben'));
    expect(second, contains('Satzende'));
  });

  test('simple lower-primary word order keeps the basic subject hint', () {
    final task = GermanTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g1-order-bird-flies',
    );

    expect(
      GermanSupportCatalog.firstHintForTask(task),
      GermanSupportCatalog.firstHint(GermanCompetencyId.sentenceWordOrder),
    );
    expect(
      GermanSupportCatalog.secondHintForTask(task),
      contains('Wer oder was'),
    );
  });

  test('upper-primary listening support stays listening-specific', () {
    final hint = GermanSupportCatalog.secondHint(
      GermanCompetencyId.listeningMainIdeas,
    );

    expect(hint, contains('Hör noch einmal'));
    expect(hint, contains('wichtigste Aussage'));
    expect(hint, isNot(contains('Prüfe jedes Wort')));
  });

  test('upper-primary reading support asks for textual evidence', () {
    final inference = GermanSupportCatalog.secondHint(
      GermanCompetencyId.readingInference,
    );
    final mainIdea = GermanSupportCatalog.secondHint(
      GermanCompetencyId.textMainIdea,
    );

    expect(inference, contains('mindestens zwei Hinweise'));
    expect(mainIdea, contains('ganzen Text'));
  });

  test('direct-speech support names the punctuation sequence', () {
    final hint = GermanSupportCatalog.secondHint(
      GermanCompetencyId.directSpeechPunctuation,
    );

    expect(hint, contains('Begleitsatz'));
    expect(hint, contains('Anführungszeichen'));
    expect(hint, contains('Satzzeichen'));
  });
}
