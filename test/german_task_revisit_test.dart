import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';

GermanSessionResult _session({
  required DateTime finishedAt,
  required List<GermanTask> tasks,
  String? wrongTaskId,
  String? assistedTaskId,
}) => GermanSessionResult(
  gradeLevel: GradeLevel.first,
  startedAt: finishedAt.subtract(const Duration(minutes: 5)),
  finishedAt: finishedAt,
  kind: GermanSessionKind.practice,
  taskResults: <GermanTaskResult>[
    for (final task in tasks)
      GermanTaskResult(
        taskId: task.id,
        competencyId: task.competencyId,
        correctFirstTry: task.id != wrongTaskId,
        incorrectAttempts: task.id == wrongTaskId ? 1 : 0,
        responseMs: 1300,
        usedReadAloud: task.id == assistedTaskId,
      ),
  ],
);

List<GermanTask> _round(Iterable<GermanSessionResult> history) =>
    GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.first,
      competencyId: GermanCompetencyId.wordRecognition,
      history: history,
    );

void main() {
  test('a failed task waits behind fresh evidence before returning', () {
    final first = _round(const <GermanSessionResult>[]);
    expect(first, hasLength(6));
    final failed = first.first;
    final firstSession = _session(
      finishedAt: DateTime(2026, 9, 20, 8),
      tasks: first,
      wrongTaskId: failed.id,
    );

    final second = _round(<GermanSessionResult>[firstSession]);
    expect(second, hasLength(6));
    expect(
      second
          .map((task) => task.id)
          .toSet()
          .intersection(first.map((task) => task.id).toSet()),
      isEmpty,
    );

    final secondSession = _session(
      finishedAt: DateTime(2026, 9, 20, 9),
      tasks: second,
    );
    final third = _round(<GermanSessionResult>[firstSession, secondSession]);

    expect(third.first.id, failed.id);
  });

  test('read-aloud assisted task returns for independent confirmation', () {
    final first = _round(const <GermanSessionResult>[]);
    final assisted = first[1];
    final firstSession = _session(
      finishedAt: DateTime(2026, 9, 20, 8),
      tasks: first,
      assistedTaskId: assisted.id,
    );
    final second = _round(<GermanSessionResult>[firstSession]);
    final secondSession = _session(
      finishedAt: DateTime(2026, 9, 20, 9),
      tasks: second,
    );

    final third = _round(<GermanSessionResult>[firstSession, secondSession]);
    expect(third.first.id, assisted.id);
  });

  test(
    'later independent success clears the task-level follow-up priority',
    () {
      final first = _round(const <GermanSessionResult>[]);
      final failed = first.first;
      final firstSession = _session(
        finishedAt: DateTime(2026, 9, 20, 8),
        tasks: first,
        wrongTaskId: failed.id,
      );
      final second = _round(<GermanSessionResult>[firstSession]);
      final secondSession = _session(
        finishedAt: DateTime(2026, 9, 20, 9),
        tasks: second,
      );
      final third = _round(<GermanSessionResult>[firstSession, secondSession]);
      expect(third.first.id, failed.id);

      final correction = _session(
        finishedAt: DateTime(2026, 9, 20, 10),
        tasks: <GermanTask>[failed],
      );
      final afterCorrection = _round(<GermanSessionResult>[
        firstSession,
        secondSession,
        correction,
      ]);

      expect(afterCorrection.first.id, isNot(failed.id));
    },
  );

  test('most recent evidence wins even when history is not pre-sorted', () {
    final first = _round(const <GermanSessionResult>[]);
    final target = first.first;
    final olderFailure = _session(
      finishedAt: DateTime(2026, 9, 20, 8),
      tasks: <GermanTask>[target],
      wrongTaskId: target.id,
    );
    final newerSuccess = _session(
      finishedAt: DateTime(2026, 9, 20, 10),
      tasks: <GermanTask>[target],
    );

    final round = _round(<GermanSessionResult>[newerSuccess, olderFailure]);
    expect(round.first.id, isNot(target.id));
  });
}
