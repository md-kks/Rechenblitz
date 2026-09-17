import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_prerequisites.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';

List<GermanSessionResult> _secureEvidence(
  GermanCompetencyId competency, {
  int day = 10,
}) {
  final tasks = GermanTaskCatalog.forCompetency(competency);
  return <GermanSessionResult>[
    for (var index = 0; index < 3; index++)
      GermanSessionResult(
        gradeLevel: tasks[index].recommendedFromGrade,
        startedAt: DateTime(2026, 9, day + index, 10),
        finishedAt: DateTime(2026, 9, day + index, 10, 2),
        taskResults: <GermanTaskResult>[
          GermanTaskResult(
            taskId: tasks[index].id,
            competencyId: competency,
            correctFirstTry: true,
            incorrectAttempts: 0,
            responseMs: 1000,
          ),
        ],
      ),
  ];
}

void main() {
  test(
    'deep German prerequisite chain points to the earliest missing basis',
    () {
      final status = GermanPrerequisiteResolver.status(
        GermanCompetencyId.sentenceComprehension,
        const <GermanSessionResult>[],
      );

      expect(status.isUnlocked, isFalse);
      expect(status.nextRequired?.id, GermanCompetencyId.letterSoundMatch);
      expect(status.reason, contains('Laute und Buchstaben'));
    },
  );

  test('secure basis advances the next German prerequisite', () {
    final history = _secureEvidence(GermanCompetencyId.letterSoundMatch);
    final status = GermanPrerequisiteResolver.status(
      GermanCompetencyId.sentenceComprehension,
      history,
    );

    expect(status.isUnlocked, isFalse);
    expect(status.nextRequired?.id, GermanCompetencyId.wordRecognition);
  });

  test(
    'complete secure prerequisite chain unlocks the German learning step',
    () {
      final history = <GermanSessionResult>[
        ..._secureEvidence(GermanCompetencyId.letterSoundMatch),
        ..._secureEvidence(GermanCompetencyId.wordRecognition, day: 14),
      ];
      final status = GermanPrerequisiteResolver.status(
        GermanCompetencyId.sentenceComprehension,
        history,
      );

      expect(status.isUnlocked, isTrue);
      expect(status.nextRequired, isNull);
    },
  );

  test('strong own evidence preserves a previously proven German skill', () {
    final history = _secureEvidence(GermanCompetencyId.sentenceComprehension);
    final status = GermanPrerequisiteResolver.status(
      GermanCompetencyId.sentenceComprehension,
      history,
    );

    expect(status.isUnlocked, isTrue);
    expect(status.confirmedByOwnEvidence, isTrue);
  });
}
