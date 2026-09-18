import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/curriculum_audit.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/assessment_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Lerncheck Klasse 2 berücksichtigt frühe Landesziele', () {
    final bavaria = AssessmentGenerator(random: Random(4201)).generate(
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      state: GermanState.bavaria,
    );
    final thuringia = AssessmentGenerator(random: Random(4201)).generate(
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      state: GermanState.thuringia,
    );

    expect(bavaria, hasLength(12));
    expect(thuringia, hasLength(12));
    final bavariaModes = bavaria.map((task) => task.mode).toSet();
    final thuringiaModes = thuringia.map((task) => task.mode).toSet();

    expect(bavariaModes, contains(TrainingMode.dataCharts));
    expect(bavariaModes, contains(TrainingMode.probability));
    expect(thuringiaModes, isNot(contains(TrainingMode.dataCharts)));
    expect(thuringiaModes, isNot(contains(TrainingMode.probability)));
  });

  test('Landesziele erzeugen passende Mikro-Kompetenz-Evidenz', () {
    final tasks = AssessmentGenerator(random: Random(4202)).generate(
      grade: GradeLevel.second,
      range: NumberRangeLevel.hundred,
      state: GermanState.bavaria,
    );

    final dataTargets = tasks
        .where((task) => task.mode == TrainingMode.dataCharts)
        .map((task) => task.targetCompetency)
        .toSet();
    final probabilityTargets = tasks
        .where((task) => task.mode == TrainingMode.probability)
        .map((task) => task.targetCompetency)
        .toSet();

    expect(
      dataTargets,
      containsAll(<MicroCompetencyId>{
        MicroCompetencyId.dataReading,
        MicroCompetencyId.tallyTableReading,
      }),
    );
    expect(
      probabilityTargets,
      equals(<MicroCompetencyId?>{MicroCompetencyId.probabilityReasoning}),
    );
  });

  test(
    'Lerncheck bleibt in allen Ländern und Klassen curricular konsistent',
    () {
      for (final state in GermanState.values) {
        for (final grade in GradeLevel.values) {
          final range = grade.recommendedRange;
          final tasks = AssessmentGenerator(
            random: Random(5000 + state.index * 100 + grade.index),
          ).generate(grade: grade, range: range, state: state);
          final allowed = CurriculumAuditCatalog.definitionsForContext(
            state,
            grade,
            range,
          ).map((definition) => definition.id).toSet();

          expect(tasks, hasLength(12), reason: '${state.name}/${grade.name}');
          expect(
            tasks.map((task) => task.mode).toSet(),
            hasLength(6),
            reason: '${state.name}/${grade.name}',
          );
          for (final task in tasks) {
            final target = task.targetCompetency;
            if (target != null) {
              expect(
                allowed,
                contains(target),
                reason: '${state.name}/${grade.name}/${task.taskKey}',
              );
            }
          }
        }
      }
    },
  );

  test('Resume verwirft Aufgaben außerhalb des gespeicherten Landespfads', () {
    final now = DateTime(2026, 9, 17, 22);
    final progress = AssessmentProgress(
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      state: GermanState.thuringia,
      tasks: const <AssessmentTask>[
        AssessmentTask(
          mode: TrainingMode.probability,
          taskKey: 'prob:possible:face:4',
          prompt: 'Normaler Würfel: Es fällt eine 4.',
          answer: 1,
          maxAnswerValue: 2,
          choices: <String>['sicher', 'möglich', 'unmöglich'],
          targetCompetency: MicroCompetencyId.probabilityReasoning,
        ),
        AssessmentTask(
          mode: TrainingMode.practice,
          taskKey: 'plus:2:3',
          prompt: '2 + 3 = ?',
          answer: 5,
          maxAnswerValue: 10,
        ),
      ],
      taskResults: const <AssessmentTaskResult>[
        AssessmentTaskResult(
          mode: TrainingMode.probability,
          taskKey: 'prob:possible:face:4',
          correct: true,
          targetCompetency: MicroCompetencyId.probabilityReasoning,
        ),
      ],
      nextIndex: 1,
      startedAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now,
    );

    expect(progress.hasSaneState(now: now), isFalse);
  });

  test('Lerncheck-Resume ist an das Bundesland gebunden', () {
    final now = DateTime(2026, 9, 17, 22);
    final progress = _progress(now, state: GermanState.bavaria);
    final restored = AssessmentProgress.fromJson(progress.toJson());

    expect(restored.state, GermanState.bavaria);
    expect(
      restored.isCompatible(
        grade: GradeLevel.second,
        range: NumberRangeLevel.hundred,
        currentState: GermanState.bavaria,
        now: now,
      ),
      isTrue,
    );
    expect(
      restored.isCompatible(
        grade: GradeLevel.second,
        range: NumberRangeLevel.hundred,
        currentState: GermanState.hesse,
        now: now,
      ),
      isFalse,
    );
  });

  test('Legacy-Lerncheck ohne Land wird nur für Thüringen fortgesetzt', () {
    final now = DateTime(2026, 9, 17, 22);
    final json = _progress(now, state: GermanState.thuringia).toJson()
      ..remove('state');
    final legacy = AssessmentProgress.fromJson(json);

    expect(legacy.state, isNull);
    expect(
      legacy.isCompatible(
        grade: GradeLevel.second,
        range: NumberRangeLevel.hundred,
        currentState: GermanState.thuringia,
        now: now,
      ),
      isTrue,
    );
    expect(
      legacy.isCompatible(
        grade: GradeLevel.second,
        range: NumberRangeLevel.hundred,
        currentState: GermanState.bavaria,
        now: now,
      ),
      isFalse,
    );
  });

  test('Bundeslandwechsel verwirft einen laufenden Lerncheck', () async {
    final controller = AppController();
    await controller.load();
    await controller.saveAssessmentProgress(
      _progress(DateTime.now(), state: GermanState.thuringia),
    );

    expect(controller.resumableAssessment(), isNotNull);
    await controller.setProfileState(GermanState.bavaria);

    expect(controller.assessmentProgress, isNull);
    expect(controller.resumableAssessment(), isNull);
  });

  test('Lernstart verwirft Lerncheck auch bei reinem Landeswechsel', () async {
    final controller = AppController();
    await controller.load();
    await controller.saveAssessmentProgress(
      _progress(DateTime.now(), state: GermanState.thuringia),
    );

    await controller.saveLearningStartSetup(
      name: 'Kind',
      grade: controller.gradeLevel,
      state: GermanState.bavaria,
    );

    expect(controller.activeProfile.state, GermanState.bavaria);
    expect(controller.assessmentProgress, isNull);
  });

  testWidgets(
    'AssessmentScreen reicht das aktive Bundesland an Generator weiter',
    (tester) async {
      final controller = AppController();
      await controller.load();
      await controller.setProfileState(GermanState.bavaria);
      final generator = _StateCapturingGenerator();

      await tester.pumpWidget(
        MaterialApp(
          home: AssessmentScreen(controller: controller, generator: generator),
        ),
      );
      await tester.pump();

      expect(generator.lastState, GermanState.bavaria);
      expect(find.text('Aufgabe 1 von 2'), findsOneWidget);
    },
  );
}

AssessmentProgress _progress(DateTime now, {required GermanState state}) {
  const tasks = <AssessmentTask>[
    AssessmentTask(
      mode: TrainingMode.practice,
      taskKey: 'plus:2:3',
      prompt: '2 + 3 = ?',
      answer: 5,
      maxAnswerValue: 10,
      targetCompetency: MicroCompetencyId.additionNoBridge,
    ),
    AssessmentTask(
      mode: TrainingMode.minus,
      taskKey: 'minus:8:3',
      prompt: '8 − 3 = ?',
      answer: 5,
      maxAnswerValue: 10,
      targetCompetency: MicroCompetencyId.subtractionNoBridge,
    ),
  ];
  return AssessmentProgress(
    gradeLevel: GradeLevel.second,
    numberRange: NumberRangeLevel.hundred,
    state: state,
    tasks: tasks,
    taskResults: const <AssessmentTaskResult>[
      AssessmentTaskResult(
        mode: TrainingMode.practice,
        taskKey: 'plus:2:3',
        correct: true,
        targetCompetency: MicroCompetencyId.additionNoBridge,
      ),
    ],
    nextIndex: 1,
    startedAt: now.subtract(const Duration(minutes: 2)),
    updatedAt: now,
  );
}

class _StateCapturingGenerator extends AssessmentGenerator {
  GermanState? lastState;

  @override
  List<AssessmentTask> generate({
    required GradeLevel grade,
    required NumberRangeLevel range,
    GermanState state = GermanState.thuringia,
  }) {
    lastState = state;
    return const <AssessmentTask>[
      AssessmentTask(
        mode: TrainingMode.practice,
        taskKey: 'plus:2:3',
        prompt: '2 + 3 = ?',
        answer: 5,
        maxAnswerValue: 10,
      ),
      AssessmentTask(
        mode: TrainingMode.minus,
        taskKey: 'minus:8:3',
        prompt: '8 − 3 = ?',
        answer: 5,
        maxAnswerValue: 10,
      ),
    ];
  }
}
