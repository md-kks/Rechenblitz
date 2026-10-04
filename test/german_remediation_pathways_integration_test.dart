import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_mistake_focus.dart';
import 'package:rechenblitz/subjects/german/german_mistake_kind.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';

void main() {
  final cases = <_PathCase>[
    const _PathCase(
      name: 'spelling',
      kind: GermanMistakeKind.spelling,
      source: GermanCompetencyId.sentenceWriting,
      guided: <GermanCompetencyId>{GermanCompetencyId.spellingStrategies},
      guidedInteractions: <GermanTaskInteraction>{
        GermanTaskInteraction.tokenSelection,
        GermanTaskInteraction.wordBuilder,
      },
      transferInteractions: <GermanTaskInteraction>{
        GermanTaskInteraction.typedText,
      },
    ),
    const _PathCase(
      name: 'word order',
      kind: GermanMistakeKind.wordOrder,
      source: GermanCompetencyId.sentenceWriting,
      guided: <GermanCompetencyId>{GermanCompetencyId.sentenceWordOrder},
      guidedInteractions: <GermanTaskInteraction>{
        GermanTaskInteraction.wordOrder,
      },
      transferInteractions: <GermanTaskInteraction>{
        GermanTaskInteraction.wordOrder,
        GermanTaskInteraction.typedText,
      },
    ),
    const _PathCase(
      name: 'direct speech punctuation',
      kind: GermanMistakeKind.directSpeechPunctuation,
      source: GermanCompetencyId.directSpeechPunctuation,
      guided: <GermanCompetencyId>{
        GermanCompetencyId.directSpeechPunctuation,
        GermanCompetencyId.sentenceWriting,
        GermanCompetencyId.textRevision,
      },
      guidedInteractions: <GermanTaskInteraction>{
        GermanTaskInteraction.tokenSelection,
        GermanTaskInteraction.wordBuilder,
      },
      transferInteractions: <GermanTaskInteraction>{
        GermanTaskInteraction.typedText,
      },
    ),
    const _PathCase(
      name: 'text revision',
      kind: GermanMistakeKind.textRevision,
      source: GermanCompetencyId.textRevision,
      guided: <GermanCompetencyId>{GermanCompetencyId.textRevision},
      guidedInteractions: <GermanTaskInteraction>{
        GermanTaskInteraction.singleChoice,
        GermanTaskInteraction.tokenSelection,
        GermanTaskInteraction.wordBuilder,
      },
      transferInteractions: <GermanTaskInteraction>{
        GermanTaskInteraction.typedText,
      },
    ),
  ];
  for (final path in cases) {
    test(
      'real catalog stages ${path.name} remediation',
      () => _verifyPath(path),
    );
  }

  test('listening remediation and transfer stay auditory', () {
    final source = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.listeningComprehension,
    ).where((task) => task.requiresSpeech).take(2).toList();
    expect(source.length, 2);
    final history = _mistakeHistory(source, GermanMistakeKind.listening);
    final guided = _focusedTask(history, DateTime(2026, 9, 3, 9));
    expect(guided.requiresSpeech, isTrue);
    expect(
      guided.interaction,
      anyOf(
        GermanTaskInteraction.listeningChoice,
        GermanTaskInteraction.tokenSelection,
      ),
    );
    history.add(_session(DateTime(2026, 9, 3, 10), [_clean(guided)]));
    final transfer = _focusedTask(history, DateTime(2026, 9, 4, 9));
    expect(transfer.requiresSpeech, isTrue);
    expect(
      transfer.interaction,
      anyOf(
        GermanTaskInteraction.wordOrder,
        GermanTaskInteraction.tokenSelection,
      ),
    );
  });
}

void _verifyPath(_PathCase path) {
  final source = GermanTaskCatalog.forCompetency(path.source).take(2).toList();
  expect(source.length, 2, reason: path.name);
  final history = _mistakeHistory(source, path.kind);
  final initial = GermanMistakeFocusAnalyzer.analyze(
    history: history,
    now: DateTime(2026, 9, 3, 9),
  );
  expect(
    initial.patterns.single.needsGuidedPractice,
    isTrue,
    reason: path.name,
  );
  final guided = _focusedTask(history, DateTime(2026, 9, 3, 9));
  expect(path.guided, contains(guided.competencyId), reason: path.name);
  expect(
    path.guidedInteractions,
    contains(guided.interaction),
    reason: path.name,
  );
  history.add(_session(DateTime(2026, 9, 3, 10), [_clean(guided)]));
  final staged = GermanMistakeFocusAnalyzer.analyze(
    history: history,
    now: DateTime(2026, 9, 4, 9),
  );
  expect(
    staged.patterns.single.needsIndependentConfirmation,
    isTrue,
    reason: path.name,
  );
  final transfer = _focusedTask(history, DateTime(2026, 9, 4, 9));
  expect(
    path.transferInteractions,
    contains(transfer.interaction),
    reason: path.name,
  );
  expect(
    GermanTaskCatalog.forGrade(
      GradeLevel.fourth,
    ).any((task) => task.id == transfer.id),
    isTrue,
    reason: path.name,
  );
}

GermanTask _focusedTask(List<GermanSessionResult> history, DateTime now) {
  final focus = GermanMistakeFocusAnalyzer.analyze(history: history, now: now);
  final round = GermanPracticePlanner.buildDailyRound(
    gradeLevel: GradeLevel.fourth,
    history: history,
    now: now,
  );
  final guided = round.where(focus.isGuidedPriority).toList(growable: false);
  if (guided.isNotEmpty) return guided.first;
  return round.reduce(
    (a, b) => focus.priorityFor(a) >= focus.priorityFor(b) ? a : b,
  );
}

List<GermanSessionResult> _mistakeHistory(
  List<GermanTask> tasks,
  GermanMistakeKind kind,
) => <GermanSessionResult>[
  _session(DateTime(2026, 9, 1, 9), [_failed(tasks[0], kind)]),
  _session(DateTime(2026, 9, 2, 9), [_failed(tasks[1], kind)]),
];

GermanTaskResult _failed(GermanTask task, GermanMistakeKind kind) =>
    GermanTaskResult(
      taskId: task.id,
      competencyId: task.competencyId,
      correctFirstTry: false,
      incorrectAttempts: 1,
      responseMs: 1800,
      firstMistakeKind: kind,
    );

GermanTaskResult _clean(GermanTask task) => GermanTaskResult(
  taskId: task.id,
  competencyId: task.competencyId,
  correctFirstTry: true,
  incorrectAttempts: 0,
  responseMs: 1200,
);

GermanSessionResult _session(DateTime at, List<GermanTaskResult> results) =>
    GermanSessionResult(
      gradeLevel: GradeLevel.fourth,
      startedAt: at.subtract(const Duration(minutes: 5)),
      finishedAt: at,
      taskResults: results,
    );

class _PathCase {
  const _PathCase({
    required this.name,
    required this.kind,
    required this.source,
    required this.guided,
    required this.guidedInteractions,
    required this.transferInteractions,
  });
  final String name;
  final GermanMistakeKind kind;
  final GermanCompetencyId source;
  final Set<GermanCompetencyId> guided;
  final Set<GermanTaskInteraction> guidedInteractions;
  final Set<GermanTaskInteraction> transferInteractions;
}
