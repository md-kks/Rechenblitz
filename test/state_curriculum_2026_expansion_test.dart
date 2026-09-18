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
      CurriculumAuditCatalog.earlyStateCompetencies(GermanState.thuringia),
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

  test('Bremen nutzt verbindliche Standards Ende 2 und 4', () {
    final profile = CurriculumAuditCatalog.profileFor(GermanState.bremen);
    expect(profile.sourceVersion, contains('2025'));
    expect(profile.progressionModel, CurriculumProgressionModel.gradePairs);

    final data = CurriculumAuditCatalog.progressionFor(
      GermanState.bremen,
      GradeLevel.second,
      MicroCompetencyId.dataReading,
    );
    expect(data.stage, CurriculumProgressionStage.dueNow);
    expect(data.checkpointGrade, GradeLevel.second);

    final combo = CurriculumAuditCatalog.progressionFor(
      GermanState.bremen,
      GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic,
    );
    expect(combo.stage, CurriculumProgressionStage.dueNow);
    expect(combo.checkpointGrade, GradeLevel.second);
  });

  test(
    'Mecklenburg-Vorpommern bildet Schuleingangsphase plus Jahrgänge ab',
    () {
      final profile = CurriculumAuditCatalog.profileFor(
        GermanState.mecklenburgVorpommern,
      );
      expect(
        profile.progressionModel,
        CurriculumProgressionModel.schoolEntryPhaseThenAnnual,
      );

      final entryPhase = CurriculumAuditCatalog.progressionFor(
        GermanState.mecklenburgVorpommern,
        GradeLevel.second,
        MicroCompetencyId.probabilityReasoning,
      );
      expect(entryPhase.stage, CurriculumProgressionStage.dueNow);
      expect(entryPhase.checkpointGrade, GradeLevel.second);
      expect(entryPhase.label, contains('Schuleingangsphase'));

      final gradeThree = CurriculumAuditCatalog.progressionFor(
        GermanState.mecklenburgVorpommern,
        GradeLevel.third,
        MicroCompetencyId.writtenAlignment,
      );
      expect(gradeThree.stage, CurriculumProgressionStage.dueNow);
      expect(gradeThree.checkpointGrade, GradeLevel.third);
      expect(gradeThree.label, contains('Klasse 3'));
    },
  );

  test(
    'Hessen öffnet frühe Lernwelten ohne künstlichen Klasse-2-Regelstandard',
    () {
      final profile = CurriculumAuditCatalog.profileFor(GermanState.hesse);
      expect(profile.progressionModel, CurriculumProgressionModel.primaryEnd);
      expect(profile.earlyProgressionNote, isNotEmpty);

      final data = CurriculumAuditCatalog.progressionFor(
        GermanState.hesse,
        GradeLevel.second,
        MicroCompetencyId.dataReading,
      );
      expect(data.stage, CurriculumProgressionStage.building);
      expect(data.checkpointGrade, GradeLevel.fourth);

      final combo = CurriculumAuditCatalog.progressionFor(
        GermanState.hesse,
        GradeLevel.second,
        MicroCompetencyId.combinatoricsSystematic,
      );
      expect(combo.stage, CurriculumProgressionStage.building);
      expect(combo.checkpointGrade, GradeLevel.fourth);
    },
  );

  test('Niedersachsen nutzt die verbindlichen Checkpoints Ende 2 und 4', () {
    final profile = CurriculumAuditCatalog.profileFor(GermanState.lowerSaxony);
    expect(profile.sourceVersion, contains('2025'));
    expect(profile.progressionModel, CurriculumProgressionModel.gradePairs);

    for (final id in <MicroCompetencyId>[
      MicroCompetencyId.dataReading,
      MicroCompetencyId.tallyTableReading,
      MicroCompetencyId.probabilityReasoning,
      MicroCompetencyId.combinatoricsSystematic,
    ]) {
      final progression = CurriculumAuditCatalog.progressionFor(
        GermanState.lowerSaxony,
        GradeLevel.second,
        id,
      );
      expect(progression.stage, CurriculumProgressionStage.dueNow);
      expect(progression.checkpointGrade, GradeLevel.second);
    }
  });

  test('Saarland bildet den aktuellen Kernlehrplan als Doppeljahrgang ab', () {
    final profile = CurriculumAuditCatalog.profileFor(GermanState.saarland);
    expect(profile.sourceVersion, contains('2026'));
    expect(profile.progressionModel, CurriculumProgressionModel.gradePairs);

    final combo = CurriculumAuditCatalog.progressionFor(
      GermanState.saarland,
      GradeLevel.second,
      MicroCompetencyId.combinatoricsSystematic,
    );
    expect(combo.stage, CurriculumProgressionStage.dueNow);
    expect(combo.checkpointGrade, GradeLevel.second);

    final patterns = CurriculumAuditCatalog.objectivesFor(GermanState.saarland)
        .firstWhere(
          (objective) =>
              objective.competency == MicroCompetencyId.numberPatterns,
        );
    expect(patterns.domain, 'Muster, Strukturen und funktionaler Zusammenhang');
  });

  test('Sachsen-Anhalt bündelt Schuleingangsphase und Abschluss Ende 4', () {
    final profile = CurriculumAuditCatalog.profileFor(GermanState.saxonyAnhalt);
    expect(
      profile.progressionModel,
      CurriculumProgressionModel.schoolEntryPhaseThenPrimaryEnd,
    );
    expect(profile.sourceVersion, contains('01.08.2026'));

    final early = CurriculumAuditCatalog.progressionFor(
      GermanState.saxonyAnhalt,
      GradeLevel.second,
      MicroCompetencyId.probabilityReasoning,
    );
    expect(early.stage, CurriculumProgressionStage.dueNow);
    expect(early.checkpointGrade, GradeLevel.second);
    expect(early.label, contains('Schuleingangsphase'));

    final later = CurriculumAuditCatalog.progressionFor(
      GermanState.saxonyAnhalt,
      GradeLevel.third,
      MicroCompetencyId.writtenAlignment,
    );
    expect(later.stage, CurriculumProgressionStage.building);
    expect(later.checkpointGrade, GradeLevel.fourth);
    expect(later.label, contains('Ende Klasse 4'));

    final patterns =
        CurriculumAuditCatalog.objectivesFor(
          GermanState.saxonyAnhalt,
        ).firstWhere(
          (objective) =>
              objective.competency == MicroCompetencyId.numberPatterns,
        );
    expect(patterns.domain, 'Muster, Strukturen und funktionaler Zusammenhang');
  });

  test('Thüringen bildet das gemischte Übergangsjahr konservativ ab', () {
    final profile = CurriculumAuditCatalog.profileFor(GermanState.thuringia);
    expect(profile.progressionModel, CurriculumProgressionModel.stateSequence);
    expect(profile.sourceVersion, contains('Klassen 1/3'));
    expect(profile.sourceVersion, contains('Klassen 2/4'));
    expect(profile.transitionNote, contains('2026/27'));
    expect(profile.earlyProgressionNote, contains('keine pauschale Freigabe'));
    expect(
      CurriculumAuditCatalog.earlyStateCompetencies(GermanState.thuringia),
      isEmpty,
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

  testWidgets('Lehrplan-Audit zeigt Thüringens Übergang 2026/27 sichtbar', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await controller.setProfileState(GermanState.thuringia);

    await tester.pumpWidget(
      MaterialApp(home: CurriculumAuditScreen(controller: controller)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('curriculum-early-progression-note')),
      findsOneWidget,
    );
    expect(find.textContaining('Klassen 1 und 3'), findsOneWidget);
    expect(find.textContaining('Klassen 2 und 4'), findsOneWidget);
  });
}
