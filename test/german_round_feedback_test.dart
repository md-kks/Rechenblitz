import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_round_feedback.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';

void main() {
  test('mixed German round names a concrete strength and next step', () {
    final result = _session(<GermanTaskResult>[
      _task('read-a', GermanCompetencyId.wordRecognition, correct: true),
      _task('read-b', GermanCompetencyId.wordRecognition, correct: true),
      _task(
        'write-a',
        GermanCompetencyId.sentenceWriting,
        correct: false,
        incorrectAttempts: 2,
      ),
      _task(
        'connect-a',
        GermanCompetencyId.sentenceConnections,
        correct: false,
        incorrectAttempts: 1,
      ),
    ]);

    final feedback = GermanRoundFeedback.forSession(result);

    expect(feedback.detail, contains('Wörter sicher lesen'));
    expect(feedback.detail, contains('Eigene Sätze schreiben'));
    expect(feedback.spokenText, contains('Wörter sicher lesen'));
    expect(feedback.spokenText, contains('Eigene Sätze schreiben'));
    expect(feedback.detail, isNot(contains('Sätze sinnvoll verknüpfen')));
  });

  test(
    'perfect German round names what went well without inventing a weakness',
    () {
      final result = _session(<GermanTaskResult>[
        _task('read-a', GermanCompetencyId.wordRecognition, correct: true),
        _task('read-b', GermanCompetencyId.wordRecognition, correct: true),
      ]);

      final feedback = GermanRoundFeedback.forSession(result);

      expect(feedback.detail, contains('Wörter sicher lesen'));
      expect(feedback.detail, isNot(contains('Als Nächstes')));
    },
  );

  test('read-aloud reading success is not praised as independent strength', () {
    final result = _session(<GermanTaskResult>[
      _task(
        'read-assisted',
        GermanCompetencyId.wordRecognition,
        correct: true,
        usedReadAloud: true,
      ),
      _task(
        'write-independent',
        GermanCompetencyId.sentenceWriting,
        correct: true,
      ),
      _task(
        'connect-needs-work',
        GermanCompetencyId.sentenceConnections,
        correct: false,
        incorrectAttempts: 1,
      ),
    ]);

    final feedback = GermanRoundFeedback.forSession(result);

    expect(feedback.detail, contains('Eigene Sätze schreiben'));
    expect(feedback.detail, isNot(contains('Wörter sicher lesen')));
  });

  test('all-assisted reading round avoids fake independent praise', () {
    final result = _session(<GermanTaskResult>[
      _task(
        'read-assisted-a',
        GermanCompetencyId.wordRecognition,
        correct: true,
        usedReadAloud: true,
      ),
      _task(
        'read-assisted-b',
        GermanCompetencyId.wordRecognition,
        correct: true,
        usedReadAloud: true,
      ),
    ]);

    final feedback = GermanRoundFeedback.forSession(result);

    expect(feedback.headline, 'Runde geschafft');
    expect(feedback.detail, contains('2 Aufgaben mit Vorlesen geübt'));
    expect(feedback.detail, contains('selbstständiges Lesen'));
    expect(feedback.detail, isNot(contains('besonders gut')));
    expect(feedback.detail, isNot(contains('Alles direkt geschafft')));
  });

  test('difficult German round names the strongest practice need', () {
    final result = _session(<GermanTaskResult>[
      _task(
        'revise-a',
        GermanCompetencyId.textRevision,
        correct: false,
        incorrectAttempts: 3,
      ),
      _task(
        'connect-a',
        GermanCompetencyId.sentenceConnections,
        correct: false,
        incorrectAttempts: 1,
      ),
    ]);

    final feedback = GermanRoundFeedback.forSession(result);

    expect(feedback.detail, contains('Texte gezielt überarbeiten'));
    expect(feedback.detail, isNot(contains('besonders gut')));
  });

  test('same competency is not praised and targeted at the same time', () {
    final result = _session(<GermanTaskResult>[
      _task('write-a', GermanCompetencyId.sentenceWriting, correct: true),
      _task(
        'write-b',
        GermanCompetencyId.sentenceWriting,
        correct: false,
        incorrectAttempts: 1,
      ),
    ]);

    final feedback = GermanRoundFeedback.forSession(result);

    expect(feedback.detail, contains('Eigene Sätze schreiben'));
    expect(feedback.detail, isNot(contains('besonders gut')));
    expect(feedback.detail, contains('Als Nächstes'));
  });
}

GermanSessionResult _session(List<GermanTaskResult> tasks) =>
    GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: DateTime(2026, 9, 18, 9),
      finishedAt: DateTime(2026, 9, 18, 9, 10),
      taskResults: tasks,
    );

GermanTaskResult _task(
  String id,
  GermanCompetencyId competency, {
  required bool correct,
  int incorrectAttempts = 0,
  bool usedReadAloud = false,
}) => GermanTaskResult(
  taskId: id,
  competencyId: competency,
  correctFirstTry: correct,
  incorrectAttempts: incorrectAttempts,
  responseMs: 1000,
  usedReadAloud: usedReadAloud,
);
