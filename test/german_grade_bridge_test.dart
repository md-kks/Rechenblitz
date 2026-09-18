import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_grade_bridge.dart';
import 'package:rechenblitz/subjects/german/german_parent_overview.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_progress.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_competency_map_screen.dart';

void main() {
  test('secure prior-grade skill becomes a pending current-grade bridge', () {
    final history = _securePriorHistory(
      competency: GermanCompetencyId.wordFamilies,
      sourceGrade: GradeLevel.second,
      currentGrade: GradeLevel.third,
    );

    final bridge = GermanGradeBridgeAnalyzer.forCompetency(
      competencyId: GermanCompetencyId.wordFamilies,
      currentGrade: GradeLevel.third,
      history: history,
    );

    expect(bridge.state, GermanGradeBridgeState.pending);
    expect(bridge.sourceGrade, GradeLevel.second);
    expect(bridge.bridgeTaskCount, 2);
    expect(bridge.bridgeTaskGrade, GradeLevel.third);
    expect(bridge.currentGradeAttempts, 0);
  });

  test('unchanged secure skill carries forward without artificial bridge', () {
    final history = _securePriorHistory(
      competency: GermanCompetencyId.nounArticle,
      sourceGrade: GradeLevel.second,
      currentGrade: GradeLevel.third,
    );

    final bridge = GermanGradeBridgeAnalyzer.forCompetency(
      competencyId: GermanCompetencyId.nounArticle,
      currentGrade: GradeLevel.third,
      history: history,
    );

    expect(bridge.state, GermanGradeBridgeState.notNeeded);
  });

  test('one current task is not enough to confirm a two-task extension', () {
    final history = _securePriorHistory(
      competency: GermanCompetencyId.wordFamilies,
      sourceGrade: GradeLevel.second,
      currentGrade: GradeLevel.third,
    );
    final currentTasks = _currentGradeTasks(
      GermanCompetencyId.wordFamilies,
      GradeLevel.third,
    );
    history.add(
      _session(grade: GradeLevel.third, taskIds: <String>[currentTasks.first]),
    );

    final bridge = GermanGradeBridgeAnalyzer.forCompetency(
      competencyId: GermanCompetencyId.wordFamilies,
      currentGrade: GradeLevel.third,
      history: history,
    );

    expect(bridge.state, GermanGradeBridgeState.pending);
    expect(bridge.currentGradeAttempts, 1);
    expect(bridge.currentGradeDistinctTasks, 1);
  });

  test('two distinct current tasks confirm a grade bridge', () {
    final history = _securePriorHistory(
      competency: GermanCompetencyId.wordFamilies,
      sourceGrade: GradeLevel.second,
      currentGrade: GradeLevel.third,
    );
    final currentTasks = _currentGradeTasks(
      GermanCompetencyId.wordFamilies,
      GradeLevel.third,
    );
    history.add(
      _session(grade: GradeLevel.third, taskIds: currentTasks.take(2).toList()),
    );

    final bridge = GermanGradeBridgeAnalyzer.forCompetency(
      competencyId: GermanCompetencyId.wordFamilies,
      currentGrade: GradeLevel.third,
      history: history,
    );

    expect(bridge.state, GermanGradeBridgeState.confirmed);
    expect(bridge.currentGradeAttempts, 2);
    expect(bridge.currentGradeCorrectFirstTry, 2);
    expect(bridge.currentGradeDistinctTasks, 2);
  });

  test('skipped grade still checks the newest available extension', () {
    final history = _securePriorHistory(
      competency: GermanCompetencyId.sentenceWordOrder,
      sourceGrade: GradeLevel.second,
      currentGrade: GradeLevel.fourth,
    );

    final bridge = GermanGradeBridgeAnalyzer.forCompetency(
      competencyId: GermanCompetencyId.sentenceWordOrder,
      currentGrade: GradeLevel.fourth,
      history: history,
    );
    final round = GermanPracticePlanner.buildGradeBridgeRound(
      gradeLevel: GradeLevel.fourth,
      competencyId: GermanCompetencyId.sentenceWordOrder,
      history: history,
    );

    expect(bridge.state, GermanGradeBridgeState.pending);
    expect(bridge.sourceGrade, GradeLevel.second);
    expect(bridge.bridgeTaskGrade, GradeLevel.third);
    expect(round, hasLength(2));
    expect(
      round.every((task) => task.recommendedFromGrade == GradeLevel.third),
      isTrue,
    );
  });

  test('every grade extension offers two distinct bridge tasks', () {
    for (final competency in GermanCompetencyId.values) {
      final tasks = GermanTaskCatalog.forCompetency(competency);
      for (final grade in GradeLevel.values.skip(1)) {
        final earlier = tasks.where(
          (task) => task.recommendedFromGrade.index < grade.index,
        );
        final extension = tasks.where(
          (task) => task.recommendedFromGrade == grade,
        );
        if (earlier.isEmpty || extension.isEmpty) continue;
        expect(
          extension.length,
          greaterThanOrEqualTo(2),
          reason: '${competency.name} / ${grade.name}',
        );
      }
    }
  });

  test('failed bridge keeps remediation on the newer task level', () {
    final history = _securePriorHistory(
      competency: GermanCompetencyId.wordFamilies,
      sourceGrade: GradeLevel.second,
      currentGrade: GradeLevel.third,
    );
    final currentTasks = _currentGradeTasks(
      GermanCompetencyId.wordFamilies,
      GradeLevel.third,
    );
    history.add(
      _session(
        grade: GradeLevel.third,
        taskIds: <String>[currentTasks.first],
        incorrectIndexes: const <int>{0},
      ),
    );

    final progress = GermanProgressAnalyzer.forCompetency(
      GermanCompetencyId.wordFamilies,
      history,
    );
    final round = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.third,
      history: history,
      taskCount: 6,
      now: DateTime(2026, 9, 18, 10),
    );

    expect(progress.state, GermanCompetencyState.learning);
    expect(round.first.competencyId, GermanCompetencyId.wordFamilies);
    expect(round.first.recommendedFromGrade, GradeLevel.third);
  });

  test('bridge round uses only current-grade extension tasks', () {
    final history = _securePriorHistory(
      competency: GermanCompetencyId.wordFamilies,
      sourceGrade: GradeLevel.second,
      currentGrade: GradeLevel.third,
    );

    final round = GermanPracticePlanner.buildGradeBridgeRound(
      gradeLevel: GradeLevel.third,
      competencyId: GermanCompetencyId.wordFamilies,
      history: history,
    );

    expect(round, hasLength(2));
    expect(
      round.every(
        (task) =>
            task.competencyId == GermanCompetencyId.wordFamilies &&
            task.recommendedFromGrade == GradeLevel.third,
      ),
      isTrue,
    );
    expect(round.map((task) => task.id).toSet(), hasLength(2));
  });

  test('daily practice prioritizes current-grade bridge evidence', () {
    final history = _securePriorHistory(
      competency: GermanCompetencyId.wordFamilies,
      sourceGrade: GradeLevel.second,
      currentGrade: GradeLevel.third,
    );

    final round = GermanPracticePlanner.buildDailyRound(
      gradeLevel: GradeLevel.third,
      history: history,
      taskCount: 6,
      now: DateTime(2026, 9, 18, 10),
    );

    expect(round, hasLength(6));
    expect(round.first.competencyId, GermanCompetencyId.wordFamilies);
    expect(round.first.recommendedFromGrade, GradeLevel.third);
  });

  test(
    'parent overview carries prior evidence but withholds current-grade secure',
    () {
      final history = _securePriorHistory(
        competency: GermanCompetencyId.wordFamilies,
        sourceGrade: GradeLevel.second,
        currentGrade: GradeLevel.third,
      );

      final overview = GermanParentOverview.analyze(
        gradeLevel: GradeLevel.third,
        history: history,
        now: DateTime(2026, 9, 18, 10),
      );
      final progress = overview.progress.firstWhere(
        (entry) => entry.competencyId == GermanCompetencyId.wordFamilies,
      );

      expect(overview.sessionCount, 0);
      expect(overview.totalTasks, 0);
      expect(progress.state, GermanCompetencyState.secure);
      expect(progress.attempts, 3);
      expect(overview.gradeBridges, hasLength(1));
      expect(overview.secureCompetencies, 0);
      expect(
        overview.strengths.any(
          (entry) => entry.competencyId == GermanCompetencyId.wordFamilies,
        ),
        isFalse,
      );
      final vocabulary = overview.domains.firstWhere(
        (entry) => entry.domain.name == 'vocabulary',
      );
      expect(vocabulary.gradeBridgeCompetencies, 1);
      expect(vocabulary.secureCompetencies, 0);
    },
  );

  test('confirmed bridge restores current-grade secure status', () {
    final history = _securePriorHistory(
      competency: GermanCompetencyId.wordFamilies,
      sourceGrade: GradeLevel.second,
      currentGrade: GradeLevel.third,
    );
    final currentTasks = _currentGradeTasks(
      GermanCompetencyId.wordFamilies,
      GradeLevel.third,
    );
    history.add(
      _session(grade: GradeLevel.third, taskIds: currentTasks.take(2).toList()),
    );

    final overview = GermanParentOverview.analyze(
      gradeLevel: GradeLevel.third,
      history: history,
      now: DateTime(2026, 9, 18, 10),
    );

    expect(overview.gradeBridges, isEmpty);
    expect(
      overview.strengths.any(
        (entry) => entry.competencyId == GermanCompetencyId.wordFamilies,
      ),
      isTrue,
    );
  });

  testWidgets('competency map exposes pending grade confirmation', (
    tester,
  ) async {
    final history = _securePriorHistory(
      competency: GermanCompetencyId.wordFamilies,
      sourceGrade: GradeLevel.second,
      currentGrade: GradeLevel.third,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GermanCompetencyMapScreen(
          gradeLevel: GradeLevel.third,
          history: history,
          referenceNow: DateTime(2026, 9, 18, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1 Klassenstufen-Check'), findsOneWidget);
    final card = find.byKey(
      const ValueKey('german-competency-card-wordFamilies'),
    );
    await tester.scrollUntilVisible(
      card,
      180,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.descendant(
        of: card,
        matching: find.textContaining('Stufe bestätigen'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.textContaining('Grundlage aus Klasse 2 sicher'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Klasse 3 bestätigen')),
      findsOneWidget,
    );
  });
}

List<GermanSessionResult> _securePriorHistory({
  required GermanCompetencyId competency,
  required GradeLevel sourceGrade,
  required GradeLevel currentGrade,
}) {
  final taskIds = GermanTaskCatalog.forCompetency(competency)
      .where((task) => task.recommendedFromGrade.index < currentGrade.index)
      .map((task) => task.id)
      .take(3)
      .toList(growable: false);
  assert(taskIds.length == 3);
  return <GermanSessionResult>[
    _session(grade: sourceGrade, taskIds: taskIds.take(2).toList()),
    _session(grade: sourceGrade, taskIds: <String>[taskIds.last], minute: 2),
  ];
}

List<String> _currentGradeTasks(
  GermanCompetencyId competency,
  GradeLevel grade,
) => GermanTaskCatalog.forCompetency(competency)
    .where((task) => task.recommendedFromGrade == grade)
    .map((task) => task.id)
    .toList(growable: false);

GermanSessionResult _session({
  required GradeLevel grade,
  required List<String> taskIds,
  int minute = 0,
  Set<int> incorrectIndexes = const <int>{},
}) => GermanSessionResult(
  gradeLevel: grade,
  startedAt: DateTime(2026, 9, 17, 10, minute),
  finishedAt: DateTime(2026, 9, 17, 10, minute + 1),
  taskResults: <GermanTaskResult>[
    for (var index = 0; index < taskIds.length; index++)
      GermanTaskResult(
        taskId: taskIds[index],
        competencyId: _competencyForTask(taskIds[index]),
        correctFirstTry: !incorrectIndexes.contains(index),
        incorrectAttempts: incorrectIndexes.contains(index) ? 1 : 0,
        responseMs: 1200,
      ),
  ],
);

GermanCompetencyId _competencyForTask(String taskId) => GermanTaskCatalog.tasks
    .firstWhere((task) => task.id == taskId)
    .competencyId;
