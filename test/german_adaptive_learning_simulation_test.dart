import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_mistake_focus.dart';
import 'package:rechenblitz/subjects/german/german_mistake_kind.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_progress.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';

void main() {
  test(
    'long adaptive path uses fresh evidence and lets a resolved pattern go',
    () {
      final writingTasks = GermanTaskCatalog.forCompetency(
        GermanCompetencyId.sentenceWriting,
      ).where((task) => task.recommendedFromGrade == GradeLevel.third).toList();
      expect(writingTasks.length, greaterThanOrEqualTo(4));

      final failedIds = writingTasks.take(2).map((task) => task.id).toSet();
      final history = <GermanSessionResult>[
        _session(DateTime(2026, 9, 1, 10), <GermanTaskResult>[
          _failed(writingTasks[0]),
        ]),
        _session(DateTime(2026, 9, 2, 10), <GermanTaskResult>[
          _failed(writingTasks[1]),
        ]),
      ];

      final active = GermanMistakeFocusAnalyzer.analyze(
        history: history,
        now: DateTime(2026, 9, 3, 9),
      );
      expect(active.patterns, hasLength(1));

      final firstRemediation = GermanPracticePlanner.buildDailyRound(
        gradeLevel: GradeLevel.third,
        history: history,
        now: DateTime(2026, 9, 3, 9),
      );
      final freshWriting = firstRemediation.where(
        (task) =>
            task.competencyId == GermanCompetencyId.sentenceWriting &&
            !failedIds.contains(task.id),
      );
      expect(
        firstRemediation.first.competencyId,
        GermanCompetencyId.sentenceWriting,
      );
      expect(failedIds, isNot(contains(firstRemediation.first.id)));
      expect(freshWriting, isNotEmpty);

      final practicedIds = <String>{};
      for (var day = 0; day < 24; day++) {
        final now = DateTime(2026, 9, 3 + day, 10);
        final round = GermanPracticePlanner.buildDailyRound(
          gradeLevel: GradeLevel.third,
          history: history,
          now: now,
        );
        expect(round, hasLength(12), reason: 'day ${day + 1}');
        practicedIds.addAll(round.map((task) => task.id));
        history.add(_session(now, round.map(_clean).toList(growable: false)));
      }

      final resolved = GermanMistakeFocusAnalyzer.analyze(
        history: history,
        now: DateTime(2026, 9, 27, 12),
      );
      expect(resolved.isEmpty, isTrue);
      expect(practicedIds.length, greaterThan(24));
    },
  );

  test('strong learner stays broad across forty successful rounds', () {
    final history = <GermanSessionResult>[];
    final practiced = <String>{};
    final competencies = <GermanCompetencyId>{};

    for (var day = 0; day < 40; day++) {
      final now = DateTime(2026, 7, 1).add(Duration(days: day));
      final round = GermanPracticePlanner.buildDailyRound(
        gradeLevel: GradeLevel.third,
        history: history,
        now: now,
      );
      expect(round, hasLength(12));
      practiced.addAll(round.map((task) => task.id));
      competencies.addAll(round.map((task) => task.competencyId));
      history.add(_session(now, round.map(_clean).toList(growable: false)));
    }

    expect(practiced.length, greaterThan(40));
    expect(competencies.length, greaterThanOrEqualTo(12));
    expect(
      GermanMistakeFocusAnalyzer.analyze(
        history: history,
        now: DateTime(2026, 8, 10),
      ).isEmpty,
      isTrue,
    );
  });

  test('sporadic repeated slip on one task never becomes broad weakness', () {
    final tasks = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.wordRecognition,
    ).toList();
    expect(tasks, isNotEmpty);
    final history = <GermanSessionResult>[];

    for (var day = 0; day < 30; day++) {
      final now = DateTime(2026, 8, 1).add(Duration(days: day));
      final round = GermanPracticePlanner.buildDailyRound(
        gradeLevel: GradeLevel.first,
        history: history,
        now: now,
      );
      final results = round.map(_clean).toList(growable: false);
      if (day == 4 || day == 11 || day == 18) {
        history.add(_session(now, <GermanTaskResult>[_failed(tasks.first)]));
      } else {
        history.add(_session(now, results));
      }
    }

    final progress = GermanProgressAnalyzer.forCompetency(
      GermanCompetencyId.wordRecognition,
      history,
    );
    expect(progress.recentDistinctFailedTaskCount, lessThanOrEqualTo(1));
    expect(
      GermanMistakeFocusAnalyzer.analyze(
        history: history,
        now: DateTime(2026, 8, 31),
      ).isEmpty,
      isTrue,
    );
  });

  test(
    'multiple simultaneous needs stay focused without crowding out breadth',
    () {
      final writing =
          GermanTaskCatalog.forCompetency(GermanCompetencyId.sentenceWriting)
              .where((task) => task.recommendedFromGrade == GradeLevel.third)
              .take(2)
              .toList();
      final spelling =
          GermanTaskCatalog.forCompetency(GermanCompetencyId.spellingStrategies)
              .where((task) => task.recommendedFromGrade == GradeLevel.third)
              .take(2)
              .toList();
      expect(writing.length, 2);
      expect(spelling.length, 2);

      final history = <GermanSessionResult>[
        _session(DateTime(2026, 9, 1), writing.map(_failed).toList()),
        _session(DateTime(2026, 9, 2), spelling.map(_failed).toList()),
      ];
      final round = GermanPracticePlanner.buildDailyRound(
        gradeLevel: GradeLevel.third,
        history: history,
        now: DateTime(2026, 9, 3),
      );

      expect(round, hasLength(12));
      expect(
        round.map((task) => task.competencyId).toSet().length,
        greaterThan(4),
      );
      expect(
        round.where(
          (task) => task.competencyId == GermanCompetencyId.sentenceWriting,
        ),
        isNotEmpty,
      );
      expect(
        round.where(
          (task) => task.competencyId == GermanCompetencyId.spellingStrategies,
        ),
        isNotEmpty,
      );
      expect(
        round
            .where(
              (task) => task.competencyId == GermanCompetencyId.sentenceWriting,
            )
            .length,
        lessThanOrEqualTo(3),
      );
    },
  );

  test('assisted reading learner is asked for independent evidence', () {
    final readingTasks = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.wordRecognition,
    ).toList();
    expect(readingTasks.length, greaterThanOrEqualTo(2));
    final history = <GermanSessionResult>[
      _session(
        DateTime(2026, 9, 1),
        readingTasks
            .take(2)
            .map((task) => _clean(task, usedReadAloud: true))
            .toList(growable: false),
        gradeLevel: GradeLevel.second,
      ),
    ];

    final progress = GermanProgressAnalyzer.forCompetency(
      GermanCompetencyId.wordRecognition,
      history,
    );
    expect(progress.independentAttempts, 0);
    expect(progress.needsMoreIndependentEvidence, isTrue);

    final round = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.second,
      history: history,
      now: DateTime(2026, 9, 2),
      prioritizeIndependentReading: true,
    );
    expect(
      round.where(
        (task) => task.competencyId == GermanCompetencyId.wordRecognition,
      ),
      isNotEmpty,
    );
  });
}

GermanTaskResult _failed(GermanTask task) => GermanTaskResult(
  taskId: task.id,
  competencyId: task.competencyId,
  correctFirstTry: false,
  incorrectAttempts: 1,
  responseMs: 1800,
  firstMistakeKind: GermanMistakeKind.capitalization,
);

GermanTaskResult _clean(GermanTask task, {bool usedReadAloud = false}) =>
    GermanTaskResult(
      taskId: task.id,
      competencyId: task.competencyId,
      correctFirstTry: true,
      incorrectAttempts: 0,
      responseMs: 1300,
      usedReadAloud: usedReadAloud,
    );

GermanSessionResult _session(
  DateTime finishedAt,
  List<GermanTaskResult> results, {
  GradeLevel gradeLevel = GradeLevel.third,
}) => GermanSessionResult(
  gradeLevel: gradeLevel,
  startedAt: finishedAt.subtract(const Duration(minutes: 5)),
  finishedAt: finishedAt,
  taskResults: results,
);
