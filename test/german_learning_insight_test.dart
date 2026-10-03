import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_learning_insight.dart';
import 'package:rechenblitz/subjects/german/german_mistake_kind.dart';
import 'package:rechenblitz/subjects/german/german_parent_overview.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';

void main() {
  test('one miss stays tentative instead of becoming a weakness', () {
    final history = <GermanSessionResult>[
      _session(DateTime(2026, 10, 1), <GermanTaskResult>[
        _result('one', correct: false),
      ]),
    ];
    final overview = GermanParentOverview.analyze(
      gradeLevel: GradeLevel.third,
      history: history,
      now: DateTime(2026, 10, 2),
    );
    final insight = overview.learningInsights.firstWhere(
      (entry) => entry.competencyId == GermanCompetencyId.sentenceWriting,
    );
    expect(insight.state, GermanLearningInsightState.tentative);
    expect(insight.title, startsWith('Einzelne Unsicherheit'));
    expect(insight.nextStep, contains('normal weiterüben'));
    expect(insight.adultSupport, contains('Nicht vorsagen'));
  });

  test('repeated distinct mistakes become a practice insight', () {
    final history = <GermanSessionResult>[
      _session(DateTime(2026, 10, 1, 9), <GermanTaskResult>[
        _result('one', correct: false),
      ]),
      _session(DateTime(2026, 10, 2, 9), <GermanTaskResult>[
        _result('two', correct: false),
      ]),
    ];
    final overview = GermanParentOverview.analyze(
      gradeLevel: GradeLevel.third,
      history: history,
      now: DateTime(2026, 10, 2, 12),
    );
    final insight = overview.learningInsights.firstWhere(
      (entry) => entry.competencyId == GermanCompetencyId.sentenceWriting,
    );
    expect(insight.state, GermanLearningInsightState.needsPractice);
    expect(
      insight.explanation,
      contains('mehreren unterschiedlichen Aufgaben'),
    );
    expect(insight.nextStep, contains('geführte Übung'));
    expect(insight.adultSupport, startsWith('Unterstützung:'));
  });

  test('assisted evidence is described as consolidation', () {
    final history = <GermanSessionResult>[
      _session(DateTime(2026, 10, 1), <GermanTaskResult>[
        _result('read-one', correct: true, assisted: true),
      ]),
    ];
    final overview = GermanParentOverview.analyze(
      gradeLevel: GradeLevel.third,
      history: history,
      now: DateTime(2026, 10, 2),
    );
    final insight = overview.learningInsights.firstWhere(
      (entry) => entry.competencyId == GermanCompetencyId.sentenceWriting,
    );
    expect(insight.state, GermanLearningInsightState.consolidating);
    expect(insight.explanation, contains('Unterstützung'));
  });

  test('trend distinguishes improvement from renewed attention', () {
    final improvingHistory = <GermanSessionResult>[];
    for (var day = 0; day < 6; day++) {
      improvingHistory.add(
        _session(DateTime(2026, 9, 1 + day), <GermanTaskResult>[
          _result('improve-$day', correct: day >= 3),
        ]),
      );
    }
    final improving =
        GermanParentOverview.analyze(
          gradeLevel: GradeLevel.third,
          history: improvingHistory,
          now: DateTime(2026, 9, 8),
        ).learningInsights.firstWhere(
          (entry) => entry.competencyId == GermanCompetencyId.sentenceWriting,
        );
    expect(improving.trend, GermanLearningTrend.improving);

    final relapseHistory = <GermanSessionResult>[];
    for (var day = 0; day < 6; day++) {
      relapseHistory.add(
        _session(DateTime(2026, 9, 1 + day), <GermanTaskResult>[
          _result('relapse-$day', correct: day < 3),
        ]),
      );
    }
    final relapse =
        GermanParentOverview.analyze(
          gradeLevel: GradeLevel.third,
          history: relapseHistory,
          now: DateTime(2026, 9, 8),
        ).learningInsights.firstWhere(
          (entry) => entry.competencyId == GermanCompetencyId.sentenceWriting,
        );
    expect(relapse.trend, GermanLearningTrend.renewedAttention);
  });
}

GermanSessionResult _session(DateTime at, List<GermanTaskResult> results) =>
    GermanSessionResult(
      gradeLevel: GradeLevel.third,
      startedAt: at.subtract(const Duration(minutes: 5)),
      finishedAt: at,
      taskResults: results,
    );

GermanTaskResult _result(
  String id, {
  required bool correct,
  bool assisted = false,
}) => GermanTaskResult(
  taskId: id,
  competencyId: GermanCompetencyId.sentenceWriting,
  correctFirstTry: correct,
  incorrectAttempts: correct ? 0 : 1,
  responseMs: 1200,
  usedReadAloud: assisted,
  firstMistakeKind: correct ? null : GermanMistakeKind.capitalization,
);
