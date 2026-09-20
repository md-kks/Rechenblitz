import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';

List<GermanSessionResult> _longHistory() {
  final tasks = GermanTaskCatalog.forGrade(GradeLevel.fourth);
  return <GermanSessionResult>[
    for (var sessionIndex = 0; sessionIndex < 300; sessionIndex++)
      GermanSessionResult(
        gradeLevel: GradeLevel.fourth,
        startedAt: DateTime(2026, 1, 1).add(Duration(days: sessionIndex)),
        finishedAt: DateTime(
          2026,
          1,
          1,
        ).add(Duration(days: sessionIndex)).add(const Duration(minutes: 8)),
        taskResults: <GermanTaskResult>[
          for (var offset = 0; offset < 12; offset++)
            (() {
              final task =
                  tasks[(sessionIndex * 7 + offset * 11) % tasks.length];
              final missed = (sessionIndex + offset) % 4 == 0;
              return GermanTaskResult(
                taskId: task.id,
                competencyId: task.competencyId,
                correctFirstTry: !missed,
                incorrectAttempts: missed ? 1 : 0,
                responseMs: 900 + ((sessionIndex + offset) % 20) * 70,
              );
            })(),
        ],
      ),
  ];
}

void main() {
  test('cached German ranking stays deterministic with maximum history', () {
    final history = _longHistory();
    final now = DateTime(2026, 9, 20);

    final chronological = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.fourth,
      history: history,
      now: now,
    );
    final reversed = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.fourth,
      history: history.reversed,
      now: now,
    );

    expect(chronological, hasLength(12));
    expect(chronological.map((task) => task.id).toSet(), hasLength(12));
    expect(
      reversed.map((task) => task.id),
      chronological.map((task) => task.id),
    );

    final domains = chronological
        .map(
          (task) =>
              GermanCompetencyCatalog.definition(task.competencyId).domain,
        )
        .toSet();
    expect(domains, hasLength(6));
  });
}
