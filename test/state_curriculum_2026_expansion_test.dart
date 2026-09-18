import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_audit.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/curriculum_audit_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('weitere Länder schalten belegte frühe Daten-und-Zufall-Ziele frei', () {
    expect(
      CurriculumAuditCatalog.earlyStateCompetencies(GermanState.hamburg).keys,
      containsAll(<MicroCompetencyId>{
        MicroCompetencyId.dataReading,
        MicroCompetencyId.tallyTableReading,
        MicroCompetencyId.probabilityReasoning,
        MicroCompetencyId.combinatoricsSystematic,
      }),
    );
    expect(
      CurriculumAuditCatalog.earlyStateCompetencies(
        GermanState.rhinelandPalatinate,
      ).keys.toSet(),
      <MicroCompetencyId>{
        MicroCompetencyId.dataReading,
        MicroCompetencyId.tallyTableReading,
        MicroCompetencyId.probabilityReasoning,
      },
    );
    expect(
      CurriculumAuditCatalog.earlyStateCompetencies(
        GermanState.saxony,
      ).keys.toSet(),
      <MicroCompetencyId>{
        MicroCompetencyId.dataReading,
        MicroCompetencyId.tallyTableReading,
        MicroCompetencyId.probabilityReasoning,
        MicroCompetencyId.combinatoricsSystematic,
      },
    );
    expect(
      CurriculumAuditCatalog.earlyStateCompetencies(
        GermanState.schleswigHolstein,
      ).keys.toSet(),
      <MicroCompetencyId>{
        MicroCompetencyId.dataReading,
        MicroCompetencyId.tallyTableReading,
        MicroCompetencyId.probabilityReasoning,
        MicroCompetencyId.combinatoricsSystematic,
      },
    );

    for (final state in <GermanState>[
      GermanState.hamburg,
      GermanState.rhinelandPalatinate,
      GermanState.saxony,
      GermanState.schleswigHolstein,
    ]) {
      for (final grade in CurriculumAuditCatalog.earlyStateCompetencies(
        state,
      ).values) {
        expect(grade, GradeLevel.second, reason: state.name);
      }
    }
  });

  test('frühe Landesfreigaben bleiben bewusst auf belegte Länder begrenzt', () {
    const expectedStates = <GermanState>{
      GermanState.badenWuerttemberg,
      GermanState.bavaria,
      GermanState.berlin,
      GermanState.brandenburg,
      GermanState.hamburg,
      GermanState.northRhineWestphalia,
      GermanState.rhinelandPalatinate,
      GermanState.saxony,
      GermanState.schleswigHolstein,
    };

    final actualStates = GermanState.values
        .where(
          (state) =>
              CurriculumAuditCatalog.earlyStateCompetencies(state).isNotEmpty,
        )
        .toSet();

    expect(actualStates, expectedStates);

    for (final state in actualStates) {
      expect(
        CurriculumAuditCatalog.profileFor(state).earlyProgressionNote,
        isNotEmpty,
        reason: state.name,
      );
    }

    expect(
      CurriculumAuditCatalog.earlyStateCompetencies(GermanState.hesse),
      isEmpty,
    );
    expect(
      CurriculumAuditCatalog.earlyStateCompetencies(
        GermanState.mecklenburgVorpommern,
      ),
      isEmpty,
    );
  });

  test('Hamburg trennt Beobachtung Ende 2 von Anforderungen Ende 4', () {
    final profile = CurriculumAuditCatalog.profileFor(GermanState.hamburg);
    expect(
      profile.progressionModel,
      CurriculumProgressionModel.observedGradePair,
    );

    final laterData = CurriculumAuditCatalog.progressionFor(
      GermanState.hamburg,
      GradeLevel.first,
      MicroCompetencyId.dataReading,
    );
    expect(laterData.stage, CurriculumProgressionStage.later);
    expect(laterData.checkpointGrade, GradeLevel.second);

    final building = CurriculumAuditCatalog.progressionFor(
      GermanState.hamburg,
      GradeLevel.first,
      MicroCompetencyId.additionNoBridge,
    );
    expect(building.stage, CurriculumProgressionStage.building);
    expect(building.checkpointGrade, GradeLevel.second);
    expect(building.label, contains('Beobachtungskriterien'));

    final due = CurriculumAuditCatalog.progressionFor(
      GermanState.hamburg,
      GradeLevel.second,
      MicroCompetencyId.dataReading,
    );
    expect(due.stage, CurriculumProgressionStage.dueNow);
    expect(due.checkpointGrade, GradeLevel.second);
    expect(due.label, contains('Beobachtungskriterien'));

    final upperDue = CurriculumAuditCatalog.progressionFor(
      GermanState.hamburg,
      GradeLevel.fourth,
      MicroCompetencyId.scale,
    );
    expect(upperDue.stage, CurriculumProgressionStage.dueNow);
    expect(upperDue.checkpointGrade, GradeLevel.fourth);
    expect(upperDue.label, contains('Regelanforderungen'));
  });

  test('Rheinland-Pfalz und Schleswig-Holstein nutzen Doppeljahrgänge', () {
    expect(
      CurriculumAuditCatalog.profileFor(
        GermanState.rhinelandPalatinate,
      ).progressionModel,
      CurriculumProgressionModel.gradePairs,
    );
    expect(
      CurriculumAuditCatalog.profileFor(
        GermanState.schleswigHolstein,
      ).progressionModel,
      CurriculumProgressionModel.gradePairs,
    );

    final rp = CurriculumAuditCatalog.progressionFor(
      GermanState.rhinelandPalatinate,
      GradeLevel.second,
      MicroCompetencyId.probabilityReasoning,
    );
    expect(rp.stage, CurriculumProgressionStage.dueNow);
    expect(rp.checkpointGrade, GradeLevel.second);

    final sh = CurriculumAuditCatalog.progressionFor(
      GermanState.schleswigHolstein,
      GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic,
    );
    expect(sh.stage, CurriculumProgressionStage.dueNow);
    expect(sh.checkpointGrade, GradeLevel.second);
  });

  test('Sachsen behält die Klassenfolge nach dem gemeinsamen Einstieg', () {
    final profile = CurriculumAuditCatalog.profileFor(GermanState.saxony);
    expect(profile.progressionModel, CurriculumProgressionModel.stateSequence);
    expect(profile.sourceVersion, contains('2026'));

    expect(
      CurriculumAuditCatalog.effectiveMinGrade(
        GermanState.saxony,
        MicroCompetencyId.dataReading,
      ),
      GradeLevel.second,
    );
    expect(
      CurriculumAuditCatalog.effectiveMinGrade(
        GermanState.saxony,
        MicroCompetencyId.writtenAlignment,
      ),
      GradeLevel.third,
    );
  });

  testWidgets('Lehrplan-Audit erklärt Hamburgs frühe Progression sichtbar', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await controller.setProfileState(GermanState.hamburg);

    await tester.pumpWidget(
      MaterialApp(home: CurriculumAuditScreen(controller: controller)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('curriculum-early-progression-note')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Beobachtungskriterien am Ende von Klasse 2'),
      findsOneWidget,
    );
    expect(find.textContaining('18.09.2026'), findsOneWidget);
  });

  testWidgets('Lehrplan-Audit zeigt ohne Sonderfreigabe keinen Frühhinweis', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await controller.setProfileState(GermanState.hesse);

    await tester.pumpWidget(
      MaterialApp(home: CurriculumAuditScreen(controller: controller)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('curriculum-early-progression-note')),
      findsNothing,
    );
  });
}
