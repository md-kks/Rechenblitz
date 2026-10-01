import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/german_task_challenge.dart';

GermanSessionResult _session({
  required DateTime at,
  required List<GermanTaskResult> results,
  GradeLevel gradeLevel = GradeLevel.third,
}) => GermanSessionResult(
  gradeLevel: gradeLevel,
  startedAt: at.subtract(const Duration(minutes: 4)),
  finishedAt: at,
  taskResults: results,
);

GermanTaskResult _result(
  String id, {
  bool correct = true,
  int incorrectAttempts = 0,
  bool usedReadAloud = false,
  GermanCompetencyId competencyId = GermanCompetencyId.readingInference,
}) => GermanTaskResult(
  taskId: id,
  competencyId: competencyId,
  correctFirstTry: correct,
  incorrectAttempts: incorrectAttempts,
  responseMs: 1400,
  usedReadAloud: usedReadAloud,
);

List<int> _scores(List<GermanTask> tasks) =>
    tasks.map(GermanTaskChallenge.score).toList(growable: false);

bool _isNonDecreasing(List<int> values) {
  for (var index = 1; index < values.length; index++) {
    if (values[index] < values[index - 1]) return false;
  }
  return true;
}

int _totalChallenge(List<GermanTask> tasks) =>
    _scores(tasks).fold<int>(0, (total, value) => total + value);

void main() {
  test('challenge score reflects actual interaction workload', () {
    const shortOrder = GermanTask(
      id: 'short-order',
      competencyId: GermanCompetencyId.textSequence,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Ordne.',
      prompt: 'A B C',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>['A B C'],
      choices: <String>['A', 'B', 'C'],
    );
    const longOrder = GermanTask(
      id: 'long-order',
      competencyId: GermanCompetencyId.textSequence,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Ordne.',
      prompt: 'A B C D E',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>['A B C D E'],
      choices: <String>['A', 'B', 'C', 'D', 'E'],
    );
    const oneEvidence = GermanTask(
      id: 'one-evidence',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Markiere.',
      prompt: 'Text',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['A'],
      choices: <String>['A', 'B', 'C', 'D'],
    );
    const threeEvidence = GermanTask(
      id: 'three-evidence',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Markiere.',
      prompt: 'Text',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['A', 'B', 'C'],
      choices: <String>['A', 'B', 'C', 'D', 'E'],
    );

    expect(
      GermanTaskChallenge.score(longOrder),
      greaterThan(GermanTaskChallenge.score(shortOrder)),
    );
    expect(
      GermanTaskChallenge.score(threeEvidence),
      greaterThan(GermanTaskChallenge.score(oneEvidence)),
    );
  });

  test('new reading inference starts with lower challenge strong evidence', () {
    final round = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.readingInference,
      history: const <GermanSessionResult>[],
    );

    expect(round, hasLength(6));
    expect(
      round.every(
        (task) =>
            task.recommendedFromGrade == GradeLevel.third &&
            task.interaction == GermanTaskInteraction.tokenSelection,
      ),
      isTrue,
    );
    expect(_isNonDecreasing(_scores(round)), isTrue);
  });

  test('recent success raises selected challenge but keeps an upward ramp', () {
    final baseline = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.readingInference,
      history: const <GermanSessionResult>[],
    );
    final history = <GermanSessionResult>[
      _session(
        at: DateTime(2026, 9, 20, 8),
        results: <GermanTaskResult>[_result('successful-a')],
      ),
      _session(
        at: DateTime(2026, 9, 21, 8),
        results: <GermanTaskResult>[_result('successful-b')],
      ),
    ];

    final round = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.readingInference,
      history: history,
    );

    expect(round, hasLength(6));
    expect(
      _totalChallenge(round),
      greaterThanOrEqualTo(_totalChallenge(baseline)),
    );
    expect(_isNonDecreasing(_scores(round)), isTrue);
  });

  test('proven weakness keeps challenge gentler', () {
    final history = <GermanSessionResult>[
      _session(
        at: DateTime(2026, 9, 20, 8),
        results: <GermanTaskResult>[
          _result('weak-a', correct: false, incorrectAttempts: 1),
        ],
      ),
    ];

    final round = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.readingInference,
      history: history,
    );

    expect(round, hasLength(6));
    expect(_isNonDecreasing(_scores(round)), isTrue);
  });

  test('secure competency selects harder work but presents an upward ramp', () {
    final baseline = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.readingInference,
      history: const <GermanSessionResult>[],
    );
    final history = <GermanSessionResult>[
      _session(
        at: DateTime(2026, 9, 18, 8),
        results: <GermanTaskResult>[_result('secure-a')],
      ),
      _session(
        at: DateTime(2026, 9, 19, 8),
        results: <GermanTaskResult>[_result('secure-b')],
      ),
      _session(
        at: DateTime(2026, 9, 20, 8),
        results: <GermanTaskResult>[_result('secure-c')],
      ),
    ];

    final round = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.readingInference,
      history: history,
    );

    expect(round, hasLength(6));
    expect(
      _totalChallenge(round),
      greaterThanOrEqualTo(_totalChallenge(baseline)),
    );
    expect(_isNonDecreasing(_scores(round)), isTrue);
  });

  test('secure grade-four revision practice ramps from easier to harder', () {
    final history = <GermanSessionResult>[
      _session(
        at: DateTime(2026, 9, 18, 8),
        gradeLevel: GradeLevel.fourth,
        results: <GermanTaskResult>[
          _result(
            'revision-secure-a',
            competencyId: GermanCompetencyId.textRevision,
          ),
        ],
      ),
      _session(
        at: DateTime(2026, 9, 19, 8),
        gradeLevel: GradeLevel.fourth,
        results: <GermanTaskResult>[
          _result(
            'revision-secure-b',
            competencyId: GermanCompetencyId.textRevision,
          ),
        ],
      ),
      _session(
        at: DateTime(2026, 9, 20, 8),
        gradeLevel: GradeLevel.fourth,
        results: <GermanTaskResult>[
          _result(
            'revision-secure-c',
            competencyId: GermanCompetencyId.textRevision,
          ),
        ],
      ),
    ];

    final round = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.fourth,
      competencyId: GermanCompetencyId.textRevision,
      history: history,
    );
    final scores = _scores(round);

    expect(round, hasLength(6));
    expect(scores.toSet().length, greaterThan(1));
    expect(_isNonDecreasing(scores), isTrue);
  });

  test(
    'latest mistake temporarily lowers challenge despite secure history',
    () {
      final successHistory = <GermanSessionResult>[
        for (var day = 16; day <= 20; day++)
          _session(
            at: DateTime(2026, 9, day, 8),
            results: <GermanTaskResult>[_result('secure-success-$day')],
          ),
      ];
      final struggleHistory = <GermanSessionResult>[
        ...successHistory.take(4),
        _session(
          at: DateTime(2026, 9, 20, 8),
          results: <GermanTaskResult>[
            _result(
              'secure-struggle-latest',
              correct: false,
              incorrectAttempts: 1,
            ),
          ],
        ),
      ];

      final successRound = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.third,
        competencyId: GermanCompetencyId.readingInference,
        history: successHistory,
      );
      final struggleRound = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.third,
        competencyId: GermanCompetencyId.readingInference,
        history: struggleHistory,
      );

      expect(
        _totalChallenge(struggleRound),
        lessThan(_totalChallenge(successRound)),
      );
      expect(_isNonDecreasing(_scores(struggleRound)), isTrue);
    },
  );

  test('latest read-aloud assistance temporarily lowers challenge', () {
    final secureBase = <GermanSessionResult>[
      for (var day = 17; day <= 19; day++)
        _session(
          at: DateTime(2026, 9, day, 8),
          results: <GermanTaskResult>[_result('read-secure-$day')],
        ),
    ];
    final assistedHistory = <GermanSessionResult>[
      ...secureBase,
      _session(
        at: DateTime(2026, 9, 20, 8),
        results: <GermanTaskResult>[
          _result('read-assisted-latest', usedReadAloud: true),
        ],
      ),
    ];
    final independentHistory = <GermanSessionResult>[
      ...secureBase,
      _session(
        at: DateTime(2026, 9, 20, 8),
        results: <GermanTaskResult>[_result('read-independent-latest')],
      ),
    ];

    final assistedRound = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.readingInference,
      history: assistedHistory,
    );
    final independentRound = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.readingInference,
      history: independentHistory,
    );

    expect(
      _totalChallenge(assistedRound),
      lessThan(_totalChallenge(independentRound)),
    );
    expect(_isNonDecreasing(_scores(assistedRound)), isTrue);
  });

  test(
    'independent first-try success restores higher challenge after support',
    () {
      final history = <GermanSessionResult>[
        for (var day = 16; day <= 18; day++)
          _session(
            at: DateTime(2026, 9, day, 8),
            results: <GermanTaskResult>[_result('restore-secure-$day')],
          ),
        _session(
          at: DateTime(2026, 9, 19, 8),
          results: <GermanTaskResult>[
            _result('restore-assisted', usedReadAloud: true),
          ],
        ),
      ];
      final assistedRound = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.third,
        competencyId: GermanCompetencyId.readingInference,
        history: history,
      );
      final restoredRound = GermanPracticePlanner.buildCompetencyRound(
        gradeLevel: GradeLevel.third,
        competencyId: GermanCompetencyId.readingInference,
        history: <GermanSessionResult>[
          ...history,
          _session(
            at: DateTime(2026, 9, 20, 8),
            results: <GermanTaskResult>[_result('restore-independent')],
          ),
        ],
      );

      expect(
        _totalChallenge(restoredRound),
        greaterThan(_totalChallenge(assistedRound)),
      );
      expect(_isNonDecreasing(_scores(restoredRound)), isTrue);
    },
  );

  test('spaced failed task still outranks challenge preference', () {
    final actualTasks =
        GermanTaskCatalog.forCompetency(GermanCompetencyId.readingInference)
            .where(
              (task) =>
                  task.recommendedFromGrade == GradeLevel.third &&
                  task.interaction == GermanTaskInteraction.tokenSelection,
            )
            .toList();
    actualTasks.sort(
      (a, b) =>
          GermanTaskChallenge.score(a).compareTo(GermanTaskChallenge.score(b)),
    );
    final failed = actualTasks.first;

    final history = <GermanSessionResult>[
      _session(
        at: DateTime(2026, 9, 18, 8),
        results: <GermanTaskResult>[
          _result(failed.id, correct: false, incorrectAttempts: 1),
        ],
      ),
      _session(
        at: DateTime(2026, 9, 19, 8),
        results: <GermanTaskResult>[_result('spacing-buffer')],
      ),
    ];

    final round = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.readingInference,
      history: history,
    );

    expect(round.first.id, failed.id);
  });
}
