import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_rewards.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';

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

  test('German persistence earns its own achievement', () {
    final summary = GermanRewardSummary.fromHistory(
      gradeLevel: GradeLevel.second,
      history: <GermanSessionResult>[_session(incorrectAttempts: 2)],
    );

    expect(summary.stars, 2);
    expect(summary.badges.map((badge) => badge.id), contains('keep_going'));
  });
}
