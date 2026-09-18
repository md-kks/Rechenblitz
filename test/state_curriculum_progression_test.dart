import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_audit.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/learning_path.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/screens/curriculum_audit_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('Bayern und Baden-Württemberg nutzen Doppeljahrgangs-Checkpoints', () {
    for (final state in <GermanState>[
      GermanState.bavaria,
      GermanState.badenWuerttemberg,
      GermanState.northRhineWestphalia,
    ]) {
      final firstYear = CurriculumAuditCatalog.progressionFor(
        state,
        GradeLevel.first,
        MicroCompetencyId.numberPatterns,
      );
      final secondYear = CurriculumAuditCatalog.progressionFor(
        state,
        GradeLevel.second,
        MicroCompetencyId.numberPatterns,
      );
      final thirdYear = CurriculumAuditCatalog.progressionFor(
        state,
        GradeLevel.third,
        MicroCompetencyId.writtenMultiplyProcedure,
      );
      final fourthYear = CurriculumAuditCatalog.progressionFor(
        state,
        GradeLevel.fourth,
        MicroCompetencyId.writtenMultiplyProcedure,
      );

      expect(firstYear.stage, CurriculumProgressionStage.building);
      expect(firstYear.checkpointGrade, GradeLevel.second);
      expect(secondYear.stage, CurriculumProgressionStage.dueNow);
      expect(thirdYear.stage, CurriculumProgressionStage.building);
      expect(thirdYear.checkpointGrade, GradeLevel.fourth);
      expect(fourthYear.stage, CurriculumProgressionStage.dueNow);
    }
  });

  test(
    'Berlin und Brandenburg bilden die Niveaustufen über Jahrgangsbänder ab',
    () {
      for (final state in <GermanState>[
        GermanState.berlin,
        GermanState.brandenburg,
      ]) {
        expect(
          CurriculumAuditCatalog.profileFor(state).progressionModel,
          CurriculumProgressionModel.frameworkLevels,
        );
        expect(
          CurriculumAuditCatalog.progressionFor(
            state,
            GradeLevel.first,
            MicroCompetencyId.numberPatterns,
          ).label,
          contains('Niveaustufen-Band'),
        );
        expect(
          CurriculumAuditCatalog.progressionFor(
            state,
            GradeLevel.fourth,
            MicroCompetencyId.romanNumeral,
          ).stage,
          CurriculumProgressionStage.dueNow,
        );
      }
    },
  );

  test('Hessen erfindet keine künstlichen Jahresziele vor Ende Klasse 4', () {
    final gradeTwo = CurriculumAuditCatalog.progressionFor(
      GermanState.hesse,
      GradeLevel.second,
      MicroCompetencyId.numberPatterns,
    );
    final gradeFour = CurriculumAuditCatalog.progressionFor(
      GermanState.hesse,
      GradeLevel.fourth,
      MicroCompetencyId.numberPatterns,
    );

    expect(
      CurriculumAuditCatalog.profileFor(GermanState.hesse).progressionModel,
      CurriculumProgressionModel.primaryEnd,
    );
    expect(gradeTwo.stage, CurriculumProgressionStage.building);
    expect(gradeTwo.checkpointGrade, GradeLevel.fourth);
    expect(gradeFour.stage, CurriculumProgressionStage.dueNow);
    expect(gradeFour.label, contains('Ende Klasse 4'));
  });

  test(
    'frühe Daten- und Zufallsziele werden nur in belegten Ländern freigeschaltet',
    () {
      const earlyStates = <GermanState>[
        GermanState.badenWuerttemberg,
        GermanState.bavaria,
        GermanState.berlin,
        GermanState.brandenburg,
        GermanState.bremen,
        GermanState.hamburg,
        GermanState.hesse,
        GermanState.mecklenburgVorpommern,
        GermanState.lowerSaxony,
        GermanState.northRhineWestphalia,
        GermanState.rhinelandPalatinate,
        GermanState.saarland,
        GermanState.saxony,
        GermanState.saxonyAnhalt,
        GermanState.schleswigHolstein,
      ];
      for (final state in earlyStates) {
        final ids = CurriculumAuditCatalog.definitionsForGrade(
          state,
          GradeLevel.second,
        ).map((definition) => definition.id).toSet();
        expect(
          ids,
          contains(MicroCompetencyId.dataReading),
          reason: state.name,
        );
        expect(
          ids,
          contains(MicroCompetencyId.tallyTableReading),
          reason: state.name,
        );
        expect(
          ids,
          contains(MicroCompetencyId.probabilityReasoning),
          reason: state.name,
        );
        expect(
          ids,
          isNot(contains(MicroCompetencyId.probabilityExperiment)),
          reason: state.name,
        );
      }

      for (final state in <GermanState>[
        GermanState.thuringia,
      ]) {
        final ids = CurriculumAuditCatalog.definitionsForGrade(
          state,
          GradeLevel.second,
        ).map((definition) => definition.id).toSet();
        expect(
          ids,
          isNot(contains(MicroCompetencyId.probabilityReasoning)),
          reason: state.name,
        );
      }
    },
  );

  test('frühe Kombinatorik bleibt auf belegte Länder begrenzt', () {
    for (final state in <GermanState>[
      GermanState.bavaria,
      GermanState.berlin,
      GermanState.brandenburg,
      GermanState.bremen,
      GermanState.hamburg,
      GermanState.hesse,
      GermanState.mecklenburgVorpommern,
      GermanState.lowerSaxony,
      GermanState.northRhineWestphalia,
      GermanState.saarland,
      GermanState.saxony,
      GermanState.saxonyAnhalt,
      GermanState.schleswigHolstein,
    ]) {
      expect(
        CurriculumAuditCatalog.definitionsForGrade(
          state,
          GradeLevel.second,
        ).map((definition) => definition.id),
        contains(MicroCompetencyId.combinatoricsSystematic),
        reason: state.name,
      );
    }
    expect(
      CurriculumAuditCatalog.definitionsForGrade(
        GermanState.badenWuerttemberg,
        GradeLevel.second,
      ).map((definition) => definition.id),
      isNot(contains(MicroCompetencyId.combinatoricsSystematic)),
    );
  });

  test('Klasse-2-Kombinatorik bleibt kindgerecht klein', () {
    final generator = CurriculumExerciseGenerator(random: Random(91));
    for (var i = 0; i < 60; i++) {
      final task = generator.generate(
        mode: TrainingMode.combinatorics,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
        targetCompetency: MicroCompetencyId.combinatoricsSystematic,
      );
      expect(task.answer, inInclusiveRange(4, 9));
      expect(task.key, startsWith('combo:'));
    }
  });

  test('Klasse-2-Strichlisten bleiben im kleinen Zahlenraum', () {
    final generator = CurriculumExerciseGenerator(random: Random(92));
    for (var i = 0; i < 40; i++) {
      final task = generator.generate(
        mode: TrainingMode.dataCharts,
        maxValue: 100,
        gradeLevel: GradeLevel.second,
        targetCompetency: MicroCompetencyId.tallyTableReading,
      );
      expect(task.answer, inInclusiveRange(6, 20));
      expect(task.key, startsWith('data:tally:'));
    }
  });

  test('Klasse-2-Lernwelten folgen der Landesfreigabe', () async {
    final bavaria = AppController();
    await bavaria.load();
    await bavaria.setProfileState(GermanState.bavaria);
    final bavarianModes = bavaria.learningModesForGrade(GradeLevel.second);
    expect(bavarianModes, contains(TrainingMode.dataCharts));
    expect(bavarianModes, contains(TrainingMode.probability));
    expect(bavarianModes, contains(TrainingMode.combinatorics));

    final thuringia = AppController();
    await thuringia.load();
    await thuringia.setProfileState(GermanState.thuringia);
    final thuringiaModes =
        thuringia.learningModesForGrade(GradeLevel.second);
    expect(thuringiaModes, isNot(contains(TrainingMode.dataCharts)));
    expect(thuringiaModes, isNot(contains(TrainingMode.probability)));
    expect(thuringiaModes, isNot(contains(TrainingMode.combinatorics)));
  });

  test('Controller sieht landesspezifisch vorgezogene Ziele', () async {
    final bavaria = AppController();
    await bavaria.load();
    bavaria.gradeLevel = GradeLevel.second;
    bavaria.numberRange = NumberRangeLevel.hundred;
    await bavaria.setProfileState(GermanState.bavaria);

    final thuringia = AppController();
    await thuringia.load();
    thuringia.gradeLevel = GradeLevel.second;
    thuringia.numberRange = NumberRangeLevel.hundred;
    await thuringia.setProfileState(GermanState.thuringia);

    expect(
      bavaria
          .microCompetenciesForMode(TrainingMode.probability)
          .map((progress) => progress.definition.id),
      contains(MicroCompetencyId.probabilityReasoning),
    );
    expect(
      thuringia.microCompetenciesForMode(TrainingMode.probability),
      isEmpty,
    );
  });

  test('später vorgesehene Kompetenzen erhalten keine Discovery-Priorität', () {
    final later = CurriculumAuditCatalog.progressionFor(
      GermanState.bavaria,
      GradeLevel.second,
      MicroCompetencyId.scale,
    );
    final due = CurriculumAuditCatalog.progressionFor(
      GermanState.bavaria,
      GradeLevel.second,
      MicroCompetencyId.numberPatterns,
    );

    expect(later.stage, CurriculumProgressionStage.later);
    expect(later.priority, 0);
    expect(due.priority, greaterThan(later.priority));
  });

  test(
    'Discovery kann ein landesspezifisch vorgezogenes Lernziel auswählen',
    () async {
      final excluded = MicroCompetencyId.values
          .where((id) => id != MicroCompetencyId.probabilityReasoning)
          .toList(growable: false);

      final bavaria = AppController();
      await bavaria.load();
      bavaria.gradeLevel = GradeLevel.second;
      bavaria.numberRange = NumberRangeLevel.hundred;
      await bavaria.setProfileState(GermanState.bavaria);
      expect(
        bavaria.nextNewMicroCompetency(excluding: excluded)?.definition.id,
        MicroCompetencyId.probabilityReasoning,
      );

      final thuringia = AppController();
      await thuringia.load();
      thuringia.gradeLevel = GradeLevel.second;
      thuringia.numberRange = NumberRangeLevel.hundred;
      await thuringia.setProfileState(GermanState.thuringia);
      expect(
        thuringia.nextNewMicroCompetency(excluding: excluded),
        isNull,
      );
    },
  );

  test('Meine Runde begründet neue Lernziele mit dem Landeslehrplan', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.setProfileState(GermanState.bavaria);

    final apply = controller.buildMyRound().firstWhere(
      (segment) => segment.role == GuidedRoundRole.apply,
    );

    expect(apply.targetCompetency, isNotNull);
    expect(apply.transferEmphasis, isFalse);
    expect(apply.reason, contains('Lehrplan:'));
    expect(apply.reason, contains('bis Ende Klasse 2 im Lernband sichern'));
  });

  test('Elternhinweis erklärt neue Ziele mit der Landesprogression', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.setProfileState(GermanState.bavaria);

    final insight = controller.parentInsight();

    expect(insight.focus, contains('Lehrplan für Bayern'));
    expect(insight.focus, contains('bis Ende Klasse 2 im Lernband sichern'));
    expect(insight.action, contains('Einordnung:'));
  });

  test('Bundeslandwechsel verwirft nur curriculare Resume-Pläne', () async {
    final controller = AppController();
    await controller.load();
    final now = DateTime.now();
    controller.guidedRoundProgress = GuidedRoundProgress(
      plan: const <GuidedRoundSegment>[
        GuidedRoundSegment(
          role: GuidedRoundRole.apply,
          mode: TrainingMode.probability,
          tasks: 2,
          reason: 'Landesspezifische Entdeckung',
          targetCompetency: MicroCompetencyId.probabilityReasoning,
        ),
      ],
      completedRoles: const <GuidedRoundRole>{},
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now.subtract(const Duration(minutes: 2)),
      updatedAt: now,
      recoveryRequired: false,
    );
    controller.coreTrainingSessionProgress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.curriculum,
      mode: TrainingMode.probability,
      targetTasks: 2,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      startedAt: now.subtract(const Duration(minutes: 1)),
      updatedAt: now,
      currentTask: const <String, dynamic>{'mode': 'probability'},
    );

    await controller.setProfileState(GermanState.bavaria);

    expect(controller.guidedRoundProgress, isNull);
    expect(controller.coreTrainingSessionProgress, isNull);
    expect(controller.activeProfile.state, GermanState.bavaria);
  });

  testWidgets('Audit zeigt die Progressionslogik des aktiven Landes', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    await controller.setProfileState(GermanState.bavaria);

    await tester.pumpWidget(
      MaterialApp(home: CurriculumAuditScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.text('Progression: Lernbänder 1/2 und 3/4'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Musterregeln erkennen'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Musterregeln erkennen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Musterregeln erkennen'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Lehrplan-Progression: bis Ende Klasse 2'),
      findsOneWidget,
    );
  });
}
