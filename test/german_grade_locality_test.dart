import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';

GermanSessionResult _completeRound(
  GradeLevel grade,
  List<GermanTask> tasks,
  int day,
) => GermanSessionResult(
  gradeLevel: grade,
  startedAt: DateTime(2026, 9, 1 + day, 15),
  finishedAt: DateTime(2026, 9, 1 + day, 15, 10),
  kind: GermanSessionKind.practice,
  taskResults: <GermanTaskResult>[
    for (final task in tasks)
      GermanTaskResult(
        taskId: task.id,
        competencyId: task.competencyId,
        correctFirstTry: true,
        incorrectAttempts: 0,
        responseMs: 1200,
      ),
  ],
);

GermanSessionResult _failedLowerGradeWordReading() => GermanSessionResult(
  gradeLevel: GradeLevel.first,
  startedAt: DateTime(2026, 9, 20, 14),
  finishedAt: DateTime(2026, 9, 20, 14, 2),
  kind: GermanSessionKind.practice,
  taskResults: const <GermanTaskResult>[
    GermanTaskResult(
      taskId: 'known-lower-reading-gap',
      competencyId: GermanCompetencyId.wordRecognition,
      correctFirstTry: false,
      incorrectAttempts: 2,
      responseMs: 2500,
    ),
  ],
);

void main() {
  test(
    'successful daily practice stays on the current grade across eight rounds',
    () {
      for (final grade in <GradeLevel>[
        GradeLevel.second,
        GradeLevel.third,
        GradeLevel.fourth,
      ]) {
        final history = <GermanSessionResult>[];
        Set<String>? previousIds;

        for (var day = 0; day < 8; day++) {
          final round = GermanPracticePlanner.buildDailyRound(
            gradeLevel: grade,
            history: history,
            now: DateTime(2026, 9, 1 + day, 16),
          );

          expect(round, hasLength(12), reason: '${grade.name}/day ${day + 1}');
          expect(
            round.every((task) => task.recommendedFromGrade == grade),
            isTrue,
            reason: '${grade.name}/day ${day + 1}',
          );

          final ids = round.map((task) => task.id).toSet();
          expect(ids, hasLength(12), reason: '${grade.name}/day ${day + 1}');
          if (previousIds != null) {
            expect(
              ids.intersection(previousIds),
              isEmpty,
              reason: '${grade.name}/day ${day + 1}',
            );
          }

          final domainCounts = <GermanLearningDomain, int>{};
          for (final task in round) {
            final domain = GermanCompetencyCatalog.definition(
              task.competencyId,
            ).domain;
            domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
          }
          expect(domainCounts, hasLength(GermanLearningDomain.values.length));
          expect(
            domainCounts.values.every((count) => count == 2),
            isTrue,
            reason: '${grade.name}/day ${day + 1}',
          );

          history.add(_completeRound(grade, round, day));
          previousIds = ids;
        }
      }
    },
  );

  test(
    'proven lower-grade weakness still overrides ordinary grade locality',
    () {
      final round = GermanPracticePlanner.buildDailyRound(
        gradeLevel: GradeLevel.fourth,
        history: <GermanSessionResult>[_failedLowerGradeWordReading()],
        now: DateTime(2026, 9, 20, 15),
        taskCount: 6,
      );

      expect(round, hasLength(6));
      expect(round.first.competencyId, GermanCompetencyId.wordRecognition);
      expect(round.first.recommendedFromGrade, GradeLevel.first);
    },
  );
}
