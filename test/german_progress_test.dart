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

  test('progress marks repeated accurate work as secure', () {
    final history = List<GermanSessionResult>.generate(
      3,
      (_) => _session(GermanCompetencyId.wordRecognition, correct: true),
    );
    final progress = GermanProgressAnalyzer.forCompetency(
      GermanCompetencyId.wordRecognition,
      history,
    );

    expect(progress.state, GermanCompetencyState.secure);
    expect(progress.accuracy, 1);
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
    expect(round.map((task) => task.id).toSet().length, greaterThan(1));
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
}) {
  final finished = DateTime(2026, 9, 17, 12);
  return GermanSessionResult(
    gradeLevel: GradeLevel.second,
    startedAt: finished.subtract(const Duration(minutes: 1)),
    finishedAt: finished,
    taskResults: <GermanTaskResult>[
      GermanTaskResult(
        taskId: 'test-${competencyId.name}',
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
