import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_mistake_focus.dart';
import 'package:rechenblitz/subjects/german/german_mistake_kind.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';

GermanTaskResult _result({
  required String id,
  required GermanCompetencyId competency,
  GermanMistakeKind? mistake,
  bool correct = false,
  bool usedReadAloud = false,
}) => GermanTaskResult(
  taskId: id,
  competencyId: competency,
  correctFirstTry: correct,
  incorrectAttempts: correct ? 0 : 1,
  responseMs: 1200,
  usedReadAloud: usedReadAloud,
  firstMistakeKind: mistake,
);

GermanSessionResult _session(
  DateTime finishedAt,
  List<GermanTaskResult> results, {
  GradeLevel grade = GradeLevel.third,
}) => GermanSessionResult(
  gradeLevel: grade,
  startedAt: finishedAt.subtract(const Duration(minutes: 5)),
  finishedAt: finishedAt,
  taskResults: results,
);

const _sentenceWritingTask = GermanTask(
  id: 'focus-writing',
  competencyId: GermanCompetencyId.sentenceWriting,
  recommendedFromGrade: GradeLevel.third,
  instruction: 'Schreibe.',
  prompt: 'Satz',
  interaction: GermanTaskInteraction.typedText,
  acceptedAnswers: <String>['Ein Satz.'],
);

const _textRevisionTask = GermanTask(
  id: 'focus-revision',
  competencyId: GermanCompetencyId.textRevision,
  recommendedFromGrade: GradeLevel.fourth,
  instruction: 'Überarbeite.',
  prompt: 'Text',
  interaction: GermanTaskInteraction.typedText,
  acceptedAnswers: <String>['Ein Text.'],
);

const _listeningTask = GermanTask(
  id: 'focus-listening',
  competencyId: GermanCompetencyId.listeningComprehension,
  recommendedFromGrade: GradeLevel.first,
  instruction: 'Hör zu.',
  prompt: 'Hörtext',
  interaction: GermanTaskInteraction.listeningChoice,
  acceptedAnswers: <String>['A'],
  choices: <String>['A', 'B'],
  spokenText: 'Ein Hörtext.',
);

void main() {
  test('one isolated mistake does not create adaptive focus', () {
    final history = <GermanSessionResult>[
      _session(DateTime(2026, 10, 1, 10), <GermanTaskResult>[
        _result(
          id: 'one',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.capitalization,
        ),
      ]),
    ];

    final focus = GermanMistakeFocusAnalyzer.analyze(
      history: history,
      now: DateTime(2026, 10, 2),
    );
    expect(focus.isEmpty, isTrue);
    expect(focus.priorityFor(_sentenceWritingTask), 0);
  });

  test('repeated same mistake activates exact and related practice', () {
    final history = <GermanSessionResult>[
      _session(DateTime(2026, 9, 30, 10), <GermanTaskResult>[
        _result(
          id: 'a',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.capitalization,
        ),
      ]),
      _session(DateTime(2026, 10, 1, 10), <GermanTaskResult>[
        _result(
          id: 'b',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.capitalization,
        ),
      ]),
    ];

    final focus = GermanMistakeFocusAnalyzer.analyze(
      history: history,
      now: DateTime(2026, 10, 2),
    );
    expect(focus.patterns, hasLength(1));
    expect(focus.patterns.single.kind, GermanMistakeKind.capitalization);
    expect(focus.patterns.single.count, 2);
    expect(
      focus.priorityFor(_sentenceWritingTask),
      greaterThan(focus.priorityFor(_textRevisionTask)),
    );
    expect(focus.priorityFor(_textRevisionTask), greaterThan(0));
    expect(focus.priorityFor(_listeningTask), 0);
  });

  test('two clean follow-up results resolve an active mistake focus', () {
    final history = <GermanSessionResult>[
      _session(DateTime(2026, 9, 28, 10), <GermanTaskResult>[
        _result(
          id: 'a',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.spelling,
        ),
      ]),
      _session(DateTime(2026, 9, 29, 10), <GermanTaskResult>[
        _result(
          id: 'b',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.spelling,
        ),
      ]),
      _session(DateTime(2026, 9, 30, 10), <GermanTaskResult>[
        _result(
          id: 'clean-1',
          competency: GermanCompetencyId.sentenceWriting,
          correct: true,
        ),
      ]),
      _session(DateTime(2026, 10, 1, 10), <GermanTaskResult>[
        _result(
          id: 'clean-2',
          competency: GermanCompetencyId.sentenceWriting,
          correct: true,
        ),
      ]),
    ];

    final focus = GermanMistakeFocusAnalyzer.analyze(
      history: history,
      now: DateTime(2026, 10, 2),
    );
    expect(focus.isEmpty, isTrue);
  });

  test('mistakes outside the recent window no longer steer practice', () {
    final history = <GermanSessionResult>[
      _session(DateTime(2026, 8, 1, 10), <GermanTaskResult>[
        _result(
          id: 'old-a',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.punctuation,
        ),
      ]),
      _session(DateTime(2026, 8, 2, 10), <GermanTaskResult>[
        _result(
          id: 'old-b',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.punctuation,
        ),
      ]),
    ];

    final focus = GermanMistakeFocusAnalyzer.analyze(
      history: history,
      now: DateTime(2026, 10, 2),
    );
    expect(focus.isEmpty, isTrue);
  });

  test('spelling mistakes also prioritize spelling-strategy practice', () {
    final history = <GermanSessionResult>[
      _session(DateTime(2026, 9, 30, 10), <GermanTaskResult>[
        _result(
          id: 'spell-a',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.spelling,
        ),
      ]),
      _session(DateTime(2026, 10, 1, 10), <GermanTaskResult>[
        _result(
          id: 'spell-b',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.spelling,
        ),
      ]),
    ];

    const strategyTask = GermanTask(
      id: 'focus-spelling-strategy',
      competencyId: GermanCompetencyId.spellingStrategies,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Prüfe.',
      prompt: 'Wort',
      interaction: GermanTaskInteraction.wordBuilder,
      acceptedAnswers: <String>['Wort'],
      choices: <String>['Wo', 'rt'],
    );
    final focus = GermanMistakeFocusAnalyzer.analyze(
      history: history,
      now: DateTime(2026, 10, 2),
    );
    expect(focus.priorityFor(strategyTask), greaterThan(0));
  });

  test('selection mistakes prefer token-selection practice in same skill', () {
    final history = <GermanSessionResult>[
      _session(DateTime(2026, 9, 30, 10), <GermanTaskResult>[
        _result(
          id: 'select-a',
          competency: GermanCompetencyId.readingInference,
          mistake: GermanMistakeKind.selectionMissing,
        ),
      ], grade: GradeLevel.fourth),
      _session(DateTime(2026, 10, 1, 10), <GermanTaskResult>[
        _result(
          id: 'select-b',
          competency: GermanCompetencyId.readingInference,
          mistake: GermanMistakeKind.selectionMissing,
        ),
      ], grade: GradeLevel.fourth),
    ];
    const tokenTask = GermanTask(
      id: 'focus-token',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere.',
      prompt: 'Text',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['A'],
      choices: <String>['A', 'B'],
    );
    const choiceTask = GermanTask(
      id: 'focus-choice',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Wähle.',
      prompt: 'Text',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['A'],
      choices: <String>['A', 'B'],
    );

    final focus = GermanMistakeFocusAnalyzer.analyze(
      history: history,
      now: DateTime(2026, 10, 2),
    );
    expect(
      focus.priorityFor(tokenTask),
      greaterThan(focus.priorityFor(choiceTask)),
    );
  });

  test('daily round adds bounded focus for a recurring mistake pattern', () {
    final history = <GermanSessionResult>[
      _session(DateTime(2026, 9, 27, 10), <GermanTaskResult>[
        _result(
          id: 'clean-a',
          competency: GermanCompetencyId.sentenceWriting,
          correct: true,
        ),
        _result(
          id: 'clean-b',
          competency: GermanCompetencyId.sentenceWriting,
          correct: true,
        ),
      ]),
      _session(DateTime(2026, 9, 28, 10), <GermanTaskResult>[
        _result(
          id: 'clean-c',
          competency: GermanCompetencyId.sentenceWriting,
          correct: true,
        ),
      ]),
      _session(DateTime(2026, 9, 30, 10), <GermanTaskResult>[
        _result(
          id: 'mistake-a',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.capitalization,
          usedReadAloud: true,
        ),
      ]),
      _session(DateTime(2026, 10, 1, 10), <GermanTaskResult>[
        _result(
          id: 'mistake-b',
          competency: GermanCompetencyId.sentenceWriting,
          mistake: GermanMistakeKind.capitalization,
          usedReadAloud: true,
        ),
      ]),
    ];

    final round = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.third,
      history: history,
      now: DateTime(2026, 10, 2),
    );
    final writingTasks = round.where(
      (task) =>
          GermanCompetencyCatalog.definition(task.competencyId).domain ==
          GermanLearningDomain.writing,
    );

    expect(round, hasLength(12));
    expect(writingTasks, hasLength(3));
    expect(
      writingTasks.where(
        (task) => task.competencyId == GermanCompetencyId.sentenceWriting,
      ),
      isNotEmpty,
    );
  });
}
