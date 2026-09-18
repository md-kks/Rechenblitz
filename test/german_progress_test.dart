import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_progress.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_teacher_assignment.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('German session round-trips without losing evidence', () {
    final session = _session(
      GermanCompetencyId.wordRecognition,
      correct: false,
      incorrectAttempts: 2,
    );

    final restored = GermanSessionResult.fromJson(session.toJson());
    expect(restored.gradeLevel, GradeLevel.second);
    expect(
      restored.taskResults.single.competencyId,
      GermanCompetencyId.wordRecognition,
    );
    expect(restored.taskResults.single.incorrectAttempts, 2);
  });

  test('German history stays isolated per learner profile', () async {
    final first = GermanStorageService(profileId: 'first');
    final second = GermanStorageService(profileId: 'second');
    await first.appendSession(
      _session(GermanCompetencyId.letterSoundMatch, correct: true),
    );

    expect(await first.loadHistory(), hasLength(1));
    expect(await second.loadHistory(), isEmpty);
  });

  test(
    'one damaged German history entry does not hide valid progress',
    () async {
      final valid = _session(GermanCompetencyId.wordRecognition, correct: true);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile:child:subject:german:history_v1': jsonEncode(<Object>[
          valid.toJson(),
          <String, Object>{'broken': true},
        ]),
      });
      final storage = GermanStorageService(profileId: 'child');

      final history = await storage.loadHistory();
      expect(history, hasLength(1));
      expect(
        history.single.taskResults.single.competencyId,
        GermanCompetencyId.wordRecognition,
      );
    },
  );

  test('repeating one German task cannot fake a secure competency', () {
    final history = List<GermanSessionResult>.generate(
      3,
      (index) => _session(
        GermanCompetencyId.wordRecognition,
        correct: true,
        taskId: 'same-task',
        finishedAt: DateTime(2026, 9, 10 + index, 12),
      ),
    );
    final progress = GermanProgressAnalyzer.forCompetency(
      GermanCompetencyId.wordRecognition,
      history,
    );

    expect(progress.state, GermanCompetencyState.learning);
    expect(progress.distinctTaskCount, 1);
    expect(progress.sessionCount, 3);
  });

  test('diverse evidence across rounds can secure a German competency', () {
    final history = <GermanSessionResult>[
      _session(
        GermanCompetencyId.wordRecognition,
        correct: true,
        taskId: 'word-a',
        finishedAt: DateTime(2026, 9, 10, 12),
      ),
      _session(
        GermanCompetencyId.wordRecognition,
        correct: true,
        taskId: 'word-b',
        finishedAt: DateTime(2026, 9, 11, 12),
      ),
      _session(
        GermanCompetencyId.wordRecognition,
        correct: true,
        taskId: 'word-c',
        finishedAt: DateTime(2026, 9, 11, 13),
      ),
    ];
    final progress = GermanProgressAnalyzer.forCompetency(
      GermanCompetencyId.wordRecognition,
      history,
    );

    expect(progress.state, GermanCompetencyState.secure);
    expect(progress.distinctTaskCount, 3);
    expect(progress.sessionCount, 3);
    expect(progress.accuracy, 1);
  });

  test('secure German evidence becomes due for spaced review', () {
    final history = <GermanSessionResult>[
      for (var index = 0; index < 3; index++)
        _session(
          GermanCompetencyId.wordRecognition,
          correct: true,
          taskId: 'word-$index',
          finishedAt: DateTime(2026, 8, 20 + index, 12),
        ),
    ];
    final progress = GermanProgressAnalyzer.forCompetency(
      GermanCompetencyId.wordRecognition,
      history,
    );

    expect(progress.state, GermanCompetencyState.secure);
    expect(progress.needsReview(now: DateTime(2026, 9, 17)), isTrue);
    expect(
      progress.attention(now: DateTime(2026, 9, 17)),
      GermanPracticeAttention.reviewDue,
    );
    expect(
      progress.attention(now: DateTime(2026, 8, 30)),
      GermanPracticeAttention.none,
    );
  });

  test('recent setbacks can move an old secure skill back into learning', () {
    final history = <GermanSessionResult>[
      for (var index = 0; index < 10; index++)
        _session(
          GermanCompetencyId.wordRecognition,
          correct: true,
          taskId: 'old-word-$index',
          finishedAt: DateTime(2026, 9, 1 + index, 12),
        ),
      _session(
        GermanCompetencyId.wordRecognition,
        correct: false,
        taskId: 'recent-word-a',
        finishedAt: DateTime(2026, 9, 16, 12),
      ),
      _session(
        GermanCompetencyId.wordRecognition,
        correct: false,
        taskId: 'recent-word-b',
        finishedAt: DateTime(2026, 9, 17, 12),
      ),
    ];

    final progress = GermanProgressAnalyzer.forCompetency(
      GermanCompetencyId.wordRecognition,
      history,
    );

    expect(progress.accuracy, greaterThanOrEqualTo(0.8));
    expect(progress.recentAccuracy, 0.6);
    expect(progress.state, GermanCompetencyState.learning);
    expect(
      progress.attention(now: DateTime(2026, 9, 18)),
      GermanPracticeAttention.needsPractice,
    );
  });

  test('daily round puts a proven weak skill ahead of new skills', () {
    final history = <GermanSessionResult>[
      _session(GermanCompetencyId.wordRecognition, correct: false),
    ];

    final round = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.first,
      history: history,
      taskCount: 6,
    );

    expect(round, isNotEmpty);
    expect(round.first.competencyId, GermanCompetencyId.wordRecognition);
  });

  test('daily round keeps subject areas varied', () {
    final round = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.second,
      history: const <GermanSessionResult>[],
      taskCount: 6,
    );
    final counts = <GermanLearningDomain, int>{};
    for (final task in round) {
      final domain = _domainFor(task.competencyId);
      counts[domain] = (counts[domain] ?? 0) + 1;
    }

    expect(round, hasLength(6));
    expect(counts.values.every((count) => count <= 2), isTrue);
  });

  test('default daily round uses 12 tasks across all six domains', () {
    final round = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.second,
      history: const <GermanSessionResult>[],
    );
    final counts = <GermanLearningDomain, int>{};
    for (final task in round) {
      final domain = _domainFor(task.competencyId);
      counts[domain] = (counts[domain] ?? 0) + 1;
    }

    expect(round, hasLength(12));
    expect(counts, hasLength(GermanLearningDomain.values.length));
    expect(counts.values.every((count) => count == 2), isTrue);
    expect(round.map((task) => task.id).toSet(), hasLength(12));
  });

  test('daily round gives real weak evidence extra practice time', () {
    final history = <GermanSessionResult>[
      _session(
        GermanCompetencyId.wordRecognition,
        correct: false,
        incorrectAttempts: 1,
        finishedAt: DateTime(2026, 9, 18, 9),
      ),
    ];
    final round = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.second,
      history: history,
      now: DateTime(2026, 9, 18, 10),
    );
    final domainCounts = <GermanLearningDomain, int>{};
    for (final task in round) {
      final domain = _domainFor(task.competencyId);
      domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
    }

    expect(round, hasLength(12));
    expect(domainCounts, hasLength(GermanLearningDomain.values.length));
    expect(
      domainCounts.values.every((count) => count >= 1 && count <= 3),
      isTrue,
    );
    expect(domainCounts[GermanLearningDomain.reading], 3);
    expect(
      round
          .where(
            (task) => task.competencyId == GermanCompetencyId.wordRecognition,
          )
          .length,
      3,
    );
    expect(round.map((task) => task.id).toSet(), hasLength(12));
  });

  test('daily round gives due secure skill a refresh slot', () {
    final history = <GermanSessionResult>[
      for (var index = 0; index < 3; index++)
        _session(
          GermanCompetencyId.wordRecognition,
          correct: true,
          taskId: 'review-word-$index',
          finishedAt: DateTime(2026, 8, 20 + index, 12),
        ),
    ];
    final round = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.second,
      history: history,
      now: DateTime(2026, 9, 18, 10),
    );
    final readingCount = round
        .where(
          (task) =>
              _domainFor(task.competencyId) == GermanLearningDomain.reading,
        )
        .length;

    expect(round, hasLength(12));
    expect(readingCount, 3);
    expect(
      round
          .where(
            (task) => task.competencyId == GermanCompetencyId.wordRecognition,
          )
          .length,
      3,
    );
  });

  test('fourth-grade daily round includes productive writing', () {
    final round = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.fourth,
      history: const <GermanSessionResult>[],
    );
    final writing = round
        .where(
          (task) =>
              _domainFor(task.competencyId) == GermanLearningDomain.writing,
        )
        .toList(growable: false);

    expect(writing, hasLength(2));
    expect(
      writing.every(
        (task) => task.interaction == GermanTaskInteraction.typedText,
      ),
      isTrue,
    );
    expect(
      round.any((task) => task.interaction != GermanTaskInteraction.typedText),
      isTrue,
    );
  });

  test(
    'new upper-primary daily rounds stay age-appropriate in every domain',
    () {
      for (final grade in <GradeLevel>[GradeLevel.third, GradeLevel.fourth]) {
        final round = GermanPracticePlanner.buildDailyRound(
          gradeLevel: grade,
          history: const <GermanSessionResult>[],
        );

        for (final domain in GermanLearningDomain.values) {
          final domainTasks = round
              .where((task) => _domainFor(task.competencyId) == domain)
              .toList(growable: false);
          expect(
            domainTasks,
            hasLength(2),
            reason: '${grade.name} / ${domain.name}',
          );
          expect(
            domainTasks.every((task) => task.recommendedFromGrade == grade),
            isTrue,
            reason: '${grade.name} / ${domain.name}',
          );
        }
      }
    },
  );

  test(
    'new fourth-grader starts with age-appropriate upper-primary skills',
    () {
      final round = GermanPracticePlanner.buildDailyRound(
        gradeLevel: GradeLevel.fourth,
        history: const <GermanSessionResult>[],
        taskCount: 6,
      );

      expect(round, hasLength(6));
      expect(
        round
            .take(5)
            .every((task) => task.recommendedFromGrade == GradeLevel.fourth),
        isTrue,
      );
      expect(
        round.any(
          (task) => task.competencyId == GermanCompetencyId.textMainIdea,
        ),
        isTrue,
      );
    },
  );

  test(
    'known lower-grade weakness still outranks new fourth-grade content',
    () {
      final history = <GermanSessionResult>[
        _session(GermanCompetencyId.wordRecognition, correct: false),
      ];
      final round = GermanPracticePlanner.buildDailyRound(
        gradeLevel: GradeLevel.fourth,
        history: history,
        taskCount: 6,
      );

      expect(round.first.competencyId, GermanCompetencyId.wordRecognition);
    },
  );

  test('targeted German round stays on the selected competency', () {
    final round = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.second,
      competencyId: GermanCompetencyId.wordRecognition,
      history: const <GermanSessionResult>[],
    );

    expect(round, hasLength(6));
    expect(
      round.every(
        (task) => task.competencyId == GermanCompetencyId.wordRecognition,
      ),
      isTrue,
    );
    expect(round.map((task) => task.id).toSet().length, 6);
  });

  test('targeted practice rotates away from the most recent task', () {
    final tasks = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.wordRecognition,
    );
    expect(tasks.length, greaterThanOrEqualTo(3));
    final recent = tasks.first;
    final history = <GermanSessionResult>[
      _session(
        GermanCompetencyId.wordRecognition,
        correct: true,
        taskId: recent.id,
      ),
    ];

    final round = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.second,
      competencyId: GermanCompetencyId.wordRecognition,
      history: history,
    );

    expect(round.first.id, isNot(recent.id));
  });

  test('teacher assignment keeps its requested task count offline', () {
    final assignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.second,
      domain: GermanLearningDomain.reading,
      tasks: 5,
      targetCompetency: GermanCompetencyId.textInformation,
    );

    final round = GermanPracticePlanner.buildAssignmentRound(
      assignment: assignment,
      history: const <GermanSessionResult>[],
    );

    expect(round, hasLength(5));
    expect(
      round.every(
        (task) => task.competencyId == GermanCompetencyId.textInformation,
      ),
      isTrue,
    );
  });
}

GermanSessionResult _session(
  GermanCompetencyId competencyId, {
  required bool correct,
  int incorrectAttempts = 0,
  String? taskId,
  DateTime? finishedAt,
}) {
  final finished = finishedAt ?? DateTime(2026, 9, 17, 12);
  return GermanSessionResult(
    gradeLevel: GradeLevel.second,
    startedAt: finished.subtract(const Duration(minutes: 1)),
    finishedAt: finished,
    taskResults: <GermanTaskResult>[
      GermanTaskResult(
        taskId: taskId ?? 'test-${competencyId.name}',
        competencyId: competencyId,
        correctFirstTry: correct,
        incorrectAttempts: incorrectAttempts,
        responseMs: 1400,
      ),
    ],
  );
}

GermanLearningDomain _domainFor(GermanCompetencyId id) =>
    GermanCompetencyCatalog.definition(id).domain;
