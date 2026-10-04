import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_learning_insight.dart';
import 'package:rechenblitz/subjects/german/german_mistake_focus.dart';
import 'package:rechenblitz/subjects/german/german_mistake_kind.dart';
import 'package:rechenblitz/subjects/german/german_parent_overview.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';

void main() {
  test('real catalog completes capitalization remediation lifecycle', () {
    final writing = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.sentenceWriting,
    ).where((task) => task.recommendedFromGrade == GradeLevel.third).toList();
    expect(writing.length, greaterThanOrEqualTo(4));

    final history = <GermanSessionResult>[
      _session(DateTime(2026, 9, 1, 9), <GermanTaskResult>[
        _failed(writing[0]),
      ]),
      _session(DateTime(2026, 9, 2, 9), <GermanTaskResult>[
        _failed(writing[1]),
      ]),
    ];

    var focus = GermanMistakeFocusAnalyzer.analyze(
      history: history,
      now: DateTime(2026, 9, 3, 9),
    );
    expect(focus.patterns.single.needsGuidedPractice, isTrue);
    expect(
      _insight(history, DateTime(2026, 9, 3, 9)).state,
      GermanLearningInsightState.needsPractice,
    );

    final guidedRound = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.third,
      history: history,
      now: DateTime(2026, 9, 3, 9),
    );
    final guided = guidedRound.first;
    expect(guided.competencyId, GermanCompetencyId.nounArticle);
    expect(guided.interaction, GermanTaskInteraction.tokenSelection);
    expect(
      GermanTaskCatalog.forGrade(
        GradeLevel.third,
      ).any((task) => task.id == guided.id),
      isTrue,
    );
    history.add(
      _session(DateTime(2026, 9, 3, 10), <GermanTaskResult>[_clean(guided)]),
    );

    focus = GermanMistakeFocusAnalyzer.analyze(
      history: history,
      now: DateTime(2026, 9, 4, 9),
    );
    expect(focus.patterns.single.guidedEvidenceCount, greaterThanOrEqualTo(1));
    expect(focus.patterns.single.needsIndependentConfirmation, isTrue);
    expect(
      _insight(history, DateTime(2026, 9, 4, 9)).state,
      GermanLearningInsightState.transferCheck,
    );

    final transferRound = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.third,
      history: history,
      now: DateTime(2026, 9, 4, 9),
    );
    final transfer = transferRound.firstWhere(
      (task) =>
          task.competencyId == GermanCompetencyId.sentenceWriting &&
          task.interaction == GermanTaskInteraction.typedText &&
          task.id != writing[0].id &&
          task.id != writing[1].id,
    );
    expect(
      GermanTaskCatalog.forGrade(
        GradeLevel.third,
      ).any((task) => task.id == transfer.id),
      isTrue,
    );
    history.add(
      _session(DateTime(2026, 9, 4, 10), <GermanTaskResult>[_clean(transfer)]),
    );

    focus = GermanMistakeFocusAnalyzer.analyze(
      history: history,
      now: DateTime(2026, 9, 5, 9),
    );
    expect(focus.patterns.single.cleanEvidenceCount, 1);

    final confirmationRound = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.third,
      history: history,
      now: DateTime(2026, 9, 5, 9),
    );
    final confirmation = confirmationRound.firstWhere(
      (task) =>
          task.competencyId == GermanCompetencyId.sentenceWriting &&
          task.id != transfer.id &&
          task.id != writing[0].id &&
          task.id != writing[1].id,
    );
    history.add(
      _session(DateTime(2026, 9, 5, 10), <GermanTaskResult>[
        _clean(confirmation),
      ]),
    );

    focus = GermanMistakeFocusAnalyzer.analyze(
      history: history,
      now: DateTime(2026, 9, 6, 9),
    );
    expect(focus.isEmpty, isTrue);
    final finalInsight = _insight(history, DateTime(2026, 9, 6, 9));
    expect(finalInsight.state, isNot(GermanLearningInsightState.needsPractice));
    expect(finalInsight.state, isNot(GermanLearningInsightState.transferCheck));
  });
}

GermanLearningInsight _insight(
  List<GermanSessionResult> history,
  DateTime now,
) =>
    GermanParentOverview.analyze(
      gradeLevel: GradeLevel.third,
      history: history,
      now: now,
    ).learningInsights.firstWhere(
      (entry) => entry.competencyId == GermanCompetencyId.sentenceWriting,
    );

GermanTaskResult _failed(GermanTask task) => GermanTaskResult(
  taskId: task.id,
  competencyId: task.competencyId,
  correctFirstTry: false,
  incorrectAttempts: 1,
  responseMs: 1800,
  firstMistakeKind: GermanMistakeKind.capitalization,
);

GermanTaskResult _clean(GermanTask task) => GermanTaskResult(
  taskId: task.id,
  competencyId: task.competencyId,
  correctFirstTry: true,
  incorrectAttempts: 0,
  responseMs: 1200,
);

GermanSessionResult _session(
  DateTime finishedAt,
  List<GermanTaskResult> results,
) => GermanSessionResult(
  gradeLevel: GradeLevel.third,
  startedAt: finishedAt.subtract(const Duration(minutes: 5)),
  finishedAt: finishedAt,
  taskResults: results,
);
