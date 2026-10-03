import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_mistake_focus.dart';
import 'package:rechenblitz/subjects/german/german_mistake_kind.dart';
import 'package:rechenblitz/subjects/german/german_practice_planner.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';

void main() {
  test('virtual classroom stays adaptive and broad over fifty rounds', () {
    final learners = List.generate(24, _VirtualLearner.new);
    for (final learner in learners) {
      learner.run(days: 50);
      expect(
        learner.maxCompetencyShare,
        lessThanOrEqualTo(0.25),
        reason: learner.label,
      );
      expect(
        learner.distinctCompetencies,
        greaterThanOrEqualTo(8),
        reason: learner.label,
      );
      expect(learner.distinctTasks, greaterThan(36), reason: learner.label);
      expect(learner.roundsWithTwelveTasks, 50, reason: learner.label);
    }

    final strong = learners.where(
      (learner) => learner.profile == _Profile.strong,
    );
    expect(strong.every((learner) => learner.finalFocusCount == 0), isTrue);

    final recovering = learners.where(
      (learner) => learner.profile == _Profile.recovering,
    );
    expect(recovering.every((learner) => learner.focusWasActive), isTrue);
    expect(recovering.every((learner) => learner.firstFocusDay! < 12), isTrue);
    expect(
      recovering.every((learner) => learner.firstResolvedAfterFocusDay != null),
      isTrue,
    );
    expect(recovering.every((learner) => learner.finalFocusCount == 0), isTrue);

    final relapsing = learners.where(
      (learner) => learner.profile == _Profile.relapse,
    );
    expect(relapsing.every((learner) => learner.focusActivations >= 2), isTrue);
    expect(
      relapsing.every((learner) => learner.secondFocusDay != null),
      isTrue,
    );
  });
}

enum _Profile {
  strong,
  average,
  persistentWriting,
  assistedReader,
  recovering,
  relapse,
}

class _VirtualLearner {
  _VirtualLearner(this.seed)
    : random = Random(seed),
      profile = _Profile.values[seed % _Profile.values.length];

  final int seed;
  final Random random;
  final _Profile profile;
  final history = <GermanSessionResult>[];
  final taskIds = <String>{};
  final competencyCounts = <GermanCompetencyId, int>{};
  int roundsWithTwelveTasks = 0;
  int focusActivations = 0;
  int? firstFocusDay;
  int? firstResolvedAfterFocusDay;
  int? secondFocusDay;
  int maxConsecutiveFocusDays = 0;
  int _currentFocusDays = 0;
  bool focusWasActive = false;
  bool _previousFocus = false;

  String get label => '${profile.name} #$seed';
  int get distinctTasks => taskIds.length;
  int get distinctCompetencies => competencyCounts.length;
  int get finalFocusCount => GermanMistakeFocusAnalyzer.analyze(
    history: history,
    now: DateTime(2026, 9, 1).add(const Duration(days: 61)),
  ).patterns.length;
  double get maxCompetencyShare {
    final total = competencyCounts.values.fold<int>(0, (a, b) => a + b);
    return competencyCounts.values.reduce(max) / total;
  }

  void run({required int days}) {
    for (var day = 0; day < days; day++) {
      final now = DateTime(2026, 7, 1, 10).add(Duration(days: day));
      final prioritizeReading = profile == _Profile.assistedReader;
      final round = GermanPracticePlanner.buildDailyRound(
        gradeLevel: GradeLevel.third,
        history: history,
        now: now,
        prioritizeIndependentReading: prioritizeReading,
      );
      if (round.length == 12) roundsWithTwelveTasks++;
      taskIds.addAll(round.map((task) => task.id));
      for (final task in round) {
        competencyCounts.update(
          task.competencyId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      history.add(
        _session(now, round.map((task) => _result(task, day)).toList()),
      );
      final active = !GermanMistakeFocusAnalyzer.analyze(
        history: history,
        now: now,
      ).isEmpty;
      if (active && !_previousFocus) {
        focusActivations++;
        firstFocusDay ??= day;
        if (focusActivations == 2) secondFocusDay = day;
      }
      if (active) {
        focusWasActive = true;
        _currentFocusDays++;
        maxConsecutiveFocusDays = max(
          maxConsecutiveFocusDays,
          _currentFocusDays,
        );
      } else {
        if (_previousFocus) firstResolvedAfterFocusDay ??= day;
        _currentFocusDays = 0;
      }
      _previousFocus = active;
    }
  }

  GermanTaskResult _result(GermanTask task, int day) {
    var failureChance = switch (profile) {
      _Profile.strong => 0.015,
      _Profile.average => 0.08,
      _Profile.persistentWriting =>
        task.competencyId == GermanCompetencyId.sentenceWriting ? 0.65 : 0.05,
      _Profile.assistedReader => 0.06,
      _Profile.recovering =>
        task.competencyId == GermanCompetencyId.sentenceWriting && day < 12
            ? 0.7
            : 0.02,
      _Profile.relapse =>
        task.competencyId == GermanCompetencyId.sentenceWriting &&
                (day < 10 || day >= 42)
            ? 0.7
            : 0.02,
    };
    final readingTask = task.competencyId == GermanCompetencyId.wordRecognition;
    final assisted =
        profile == _Profile.assistedReader && readingTask && day < 14;
    if (assisted) failureChance = 0;
    final failed = random.nextDouble() < failureChance;
    return GermanTaskResult(
      taskId: task.id,
      competencyId: task.competencyId,
      correctFirstTry: !failed,
      incorrectAttempts: failed ? 1 : 0,
      responseMs: failed ? 2200 : 1300,
      usedReadAloud: assisted,
      firstMistakeKind: failed ? _mistakeFor(task) : null,
    );
  }

  GermanMistakeKind _mistakeFor(GermanTask task) => switch (task.interaction) {
    GermanTaskInteraction.wordOrder => GermanMistakeKind.wordOrder,
    GermanTaskInteraction.wordBuilder => GermanMistakeKind.wordBuilding,
    GermanTaskInteraction.listeningChoice => GermanMistakeKind.listening,
    GermanTaskInteraction.typedText => GermanMistakeKind.capitalization,
    _ => GermanMistakeKind.selectionMissing,
  };
}

GermanSessionResult _session(
  DateTime finishedAt,
  List<GermanTaskResult> results,
) => GermanSessionResult(
  gradeLevel: GradeLevel.third,
  startedAt: finishedAt.subtract(const Duration(minutes: 5)),
  finishedAt: finishedAt,
  taskResults: results,
);
