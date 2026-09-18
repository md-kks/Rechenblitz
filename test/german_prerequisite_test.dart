import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_prerequisites.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
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

GermanSessionResult _sessionForTasks(
  GradeLevel grade,
  List<GermanTask> tasks, {
  int day = 12,
}) => GermanSessionResult(
  gradeLevel: grade,
  startedAt: DateTime(2026, 9, day, 10),
  finishedAt: DateTime(2026, 9, day, 10, 2),
  taskResults: <GermanTaskResult>[
    for (final task in tasks)
      GermanTaskResult(
        taskId: task.id,
        competencyId: task.competencyId,
        correctFirstTry: true,
        incorrectAttempts: 0,
        responseMs: 1000,
      ),
  ],
);

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

  test('pending grade bridge blocks a dependent upper-grade skill', () {
    final gradeTwoTasks =
        GermanTaskCatalog.forCompetency(GermanCompetencyId.wordFamilies)
            .where((task) => task.recommendedFromGrade == GradeLevel.second)
            .take(3)
            .toList(growable: false);
    final history = <GermanSessionResult>[
      _sessionForTasks(GradeLevel.second, gradeTwoTasks.take(2).toList()),
      _sessionForTasks(GradeLevel.second, <GermanTask>[
        gradeTwoTasks.last,
      ], day: 13),
    ];

    final status = GermanPrerequisiteResolver.status(
      GermanCompetencyId.compoundWords,
      history,
      currentGrade: GradeLevel.third,
    );

    expect(status.isUnlocked, isFalse);
    expect(status.nextRequired?.id, GermanCompetencyId.wordFamilies);
  });

  test('confirmed grade bridge unlocks the dependent upper-grade skill', () {
    final gradeTwoTasks =
        GermanTaskCatalog.forCompetency(GermanCompetencyId.wordFamilies)
            .where((task) => task.recommendedFromGrade == GradeLevel.second)
            .take(3)
            .toList(growable: false);
    final gradeThreeTasks =
        GermanTaskCatalog.forCompetency(GermanCompetencyId.wordFamilies)
            .where((task) => task.recommendedFromGrade == GradeLevel.third)
            .take(2)
            .toList(growable: false);
    final history = <GermanSessionResult>[
      _sessionForTasks(GradeLevel.second, gradeTwoTasks.take(2).toList()),
      _sessionForTasks(GradeLevel.second, <GermanTask>[
        gradeTwoTasks.last,
      ], day: 13),
      _sessionForTasks(GradeLevel.third, gradeThreeTasks, day: 14),
    ];

    final status = GermanPrerequisiteResolver.status(
      GermanCompetencyId.compoundWords,
      history,
      currentGrade: GradeLevel.third,
    );

    expect(status.isUnlocked, isTrue);
    expect(status.nextRequired, isNull);
  });

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
