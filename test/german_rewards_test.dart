import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_rewards.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';

GermanSessionResult _session({
  GermanSessionKind kind = GermanSessionKind.practice,
  GradeLevel grade = GradeLevel.second,
  int incorrectAttempts = 0,
}) => GermanSessionResult(
  gradeLevel: grade,
  startedAt: DateTime(2026, 9, 18, 8),
  finishedAt: DateTime(2026, 9, 18, 8, 5),
  kind: kind,
  taskResults: List<GermanTaskResult>.generate(
    5,
    (index) => GermanTaskResult(
      taskId: 'reward-$index',
      competencyId: GermanCompetencyId.wordRecognition,
      correctFirstTry: incorrectAttempts == 0,
      incorrectAttempts: index == 0 ? incorrectAttempts : 0,
      responseMs: 900,
    ),
  ),
);
GermanSessionResult _catalogSession({
  required GradeLevel grade,
  required GermanCompetencyId competency,
  required List<String> taskIds,
  int minute = 0,
}) => GermanSessionResult(
  gradeLevel: grade,
  startedAt: DateTime(2026, 9, 18, 9, minute),
  finishedAt: DateTime(2026, 9, 18, 9, minute + 1),
  taskResults: <GermanTaskResult>[
    for (final taskId in taskIds)
      GermanTaskResult(
        taskId: taskId,
        competencyId: competency,
        correctFirstTry: true,
        incorrectAttempts: 0,
        responseMs: 900,
      ),
  ],
);

void main() {
  test('German rewards are based only on German practice evidence', () {
    final summary = GermanRewardSummary.fromHistory(
      gradeLevel: GradeLevel.second,
      history: <GermanSessionResult>[
        _session(),
        _session(kind: GermanSessionKind.assessment),
        _session(grade: GradeLevel.third),
      ],
    );

    expect(summary.stars, 2);
    expect(
      summary.badges.map((badge) => badge.id),
      containsAll(<String>['first_round', 'perfect_round']),
    );
  });

  test('duplicate round does not award stars twice', () {
    final session = _session();

    final summary = GermanRewardSummary.fromHistory(
      gradeLevel: GradeLevel.second,
      history: <GermanSessionResult>[session, session],
    );

    expect(summary.stars, 2);
    expect(
      summary.badges.map((badge) => badge.id),
      containsAll(<String>['first_round', 'perfect_round']),
    );
  });

  test('German rewards carry forward when grade level increases', () {
    final summary = GermanRewardSummary.fromHistory(
      gradeLevel: GradeLevel.third,
      history: <GermanSessionResult>[
        _session(grade: GradeLevel.second),
        _session(grade: GradeLevel.third),
        _session(grade: GradeLevel.fourth),
      ],
    );

    expect(summary.stars, 4);
    expect(
      summary.badges.map((badge) => badge.id),
      containsAll(<String>['first_round', 'perfect_round']),
    );
  });

  test('earned mastery badge survives a pending higher-grade bridge', () {
    final gradeTwoTasks =
        GermanTaskCatalog.forCompetency(GermanCompetencyId.wordFamilies)
            .where((task) => task.recommendedFromGrade == GradeLevel.second)
            .map((task) => task.id)
            .take(3)
            .toList(growable: false);
    final history = <GermanSessionResult>[
      _catalogSession(
        grade: GradeLevel.second,
        competency: GermanCompetencyId.wordFamilies,
        taskIds: gradeTwoTasks.take(2).toList(),
      ),
      _catalogSession(
        grade: GradeLevel.second,
        competency: GermanCompetencyId.wordFamilies,
        taskIds: <String>[gradeTwoTasks.last],
        minute: 3,
      ),
    ];

    final summary = GermanRewardSummary.fromHistory(
      gradeLevel: GradeLevel.third,
      history: history,
    );

    expect(summary.stars, 2);
    expect(summary.badges.map((badge) => badge.id), contains('first_secure'));
    expect(
      summary.badges.map((badge) => badge.id),
      isNot(contains('grade_step')),
    );
  });

  test('confirmed grade bridge earns Stufensteiger and restores mastery', () {
    final gradeTwoTasks =
        GermanTaskCatalog.forCompetency(GermanCompetencyId.wordFamilies)
            .where((task) => task.recommendedFromGrade == GradeLevel.second)
            .map((task) => task.id)
            .take(3)
            .toList(growable: false);
    final gradeThreeTasks =
        GermanTaskCatalog.forCompetency(GermanCompetencyId.wordFamilies)
            .where((task) => task.recommendedFromGrade == GradeLevel.third)
            .map((task) => task.id)
            .take(2)
            .toList(growable: false);
    final history = <GermanSessionResult>[
      _catalogSession(
        grade: GradeLevel.second,
        competency: GermanCompetencyId.wordFamilies,
        taskIds: gradeTwoTasks.take(2).toList(),
      ),
      _catalogSession(
        grade: GradeLevel.second,
        competency: GermanCompetencyId.wordFamilies,
        taskIds: <String>[gradeTwoTasks.last],
        minute: 3,
      ),
      _catalogSession(
        grade: GradeLevel.third,
        competency: GermanCompetencyId.wordFamilies,
        taskIds: gradeThreeTasks,
        minute: 6,
      ),
    ];

    final summary = GermanRewardSummary.fromHistory(
      gradeLevel: GradeLevel.third,
      history: history,
    );
    final badgeIds = summary.badges.map((badge) => badge.id);

    expect(badgeIds, contains('grade_step'));
    expect(badgeIds, contains('first_secure'));
  });

  test('Stufensteiger remains earned on the next grade level', () {
    final gradeTwoTasks =
        GermanTaskCatalog.forCompetency(GermanCompetencyId.wordFamilies)
            .where((task) => task.recommendedFromGrade == GradeLevel.second)
            .map((task) => task.id)
            .take(3)
            .toList(growable: false);
    final gradeThreeTasks =
        GermanTaskCatalog.forCompetency(GermanCompetencyId.wordFamilies)
            .where((task) => task.recommendedFromGrade == GradeLevel.third)
            .map((task) => task.id)
            .take(2)
            .toList(growable: false);
    final history = <GermanSessionResult>[
      _catalogSession(
        grade: GradeLevel.second,
        competency: GermanCompetencyId.wordFamilies,
        taskIds: gradeTwoTasks.take(2).toList(),
      ),
      _catalogSession(
        grade: GradeLevel.second,
        competency: GermanCompetencyId.wordFamilies,
        taskIds: <String>[gradeTwoTasks.last],
        minute: 3,
      ),
      _catalogSession(
        grade: GradeLevel.third,
        competency: GermanCompetencyId.wordFamilies,
        taskIds: gradeThreeTasks,
        minute: 6,
      ),
    ];

    final summary = GermanRewardSummary.fromHistory(
      gradeLevel: GradeLevel.fourth,
      history: history,
    );

    expect(summary.badges.map((badge) => badge.id), contains('grade_step'));
    expect(summary.badges.map((badge) => badge.id), contains('first_secure'));
  });

  test('German persistence earns its own achievement', () {
    final summary = GermanRewardSummary.fromHistory(
      gradeLevel: GradeLevel.second,
      history: <GermanSessionResult>[_session(incorrectAttempts: 2)],
    );

    expect(summary.stars, 2);
    expect(summary.badges.map((badge) => badge.id), contains('keep_going'));
  });
}
