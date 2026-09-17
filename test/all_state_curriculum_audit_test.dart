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
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('Lehrplan-Audit deckt alle Bundesländer strukturell ab', () {
    expect(CurriculumAuditCatalog.profiles.length, GermanState.values.length);
    expect(
      CurriculumAuditCatalog.profiles.values
          .map((profile) => profile.code)
          .toSet()
          .length,
      GermanState.values.length,
    );

    for (final state in GermanState.values) {
      final profile = CurriculumAuditCatalog.profileFor(state);
      expect(profile.sourceTitle, isNotEmpty, reason: state.name);
      expect(profile.sourceVersion, isNotEmpty, reason: state.name);
      expect(profile.authority, isNotEmpty, reason: state.name);
      expect(profile.structureNote, isNotEmpty, reason: state.name);

      for (final grade in GradeLevel.values) {
        final summary = CurriculumAuditCatalog.audit(grade, state: state);
        final expected = MicroCompetencyCatalog.forGrade(grade).length;
        expect(
          summary.structurallyComplete,
          isTrue,
          reason: '${state.name}/${grade.name}',
        );
        expect(summary.total, expected, reason: '${state.name}/${grade.name}');
        expect(summary.missingCompetencies, isEmpty);
      }
    }
  });

  test('Lehrplan-Audit nutzt landesspezifische IDs und Fachstrukturen', () {
    CurriculumObjective objectiveFor(GermanState state, MicroCompetencyId id) =>
        CurriculumAuditCatalog.objectivesFor(
          state,
        ).firstWhere((objective) => objective.competency == id);

    expect(
      objectiveFor(
        GermanState.thuringia,
        MicroCompetencyId.numberPatterns,
      ).domain,
      'Arithmetik',
    );
    expect(
      objectiveFor(GermanState.berlin, MicroCompetencyId.numberPatterns).domain,
      'Gleichungen und Funktionen',
    );
    expect(
      objectiveFor(
        GermanState.brandenburg,
        MicroCompetencyId.numberPatterns,
      ).domain,
      'Gleichungen und Funktionen',
    );
    expect(
      objectiveFor(
        GermanState.hamburg,
        MicroCompetencyId.numberPatterns,
      ).domain,
      'Muster, Strukturen und funktionaler Zusammenhang',
    );
    expect(
      objectiveFor(
        GermanState.bavaria,
        MicroCompetencyId.numberPatterns,
      ).domain,
      'Zahlen und Operationen',
    );
    expect(
      objectiveFor(GermanState.saxony, MicroCompetencyId.numberPatterns).id,
      startsWith('RB-SN-'),
    );
    expect(
      CurriculumAuditCatalog.profileFor(GermanState.saxonyAnhalt).sourceVersion,
      contains('01.08.2026'),
    );
  });

  testWidgets('Lehrplan-Audit zeigt die Quelle des aktiven Bundeslands', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await controller.setProfileState(GermanState.berlin);

    await tester.pumpWidget(
      MaterialApp(home: CurriculumAuditScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.text('Landesspezifische Zuordnung für Berlin'), findsOneWidget);
    expect(
      find.textContaining('Rahmenlehrplan Jahrgangsstufen 1–10'),
      findsOneWidget,
    );
  });

  testWidgets('Lehrplan-Audit zeigt Übergangsstände transparent', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await controller.setProfileState(GermanState.mecklenburgVorpommern);

    await tester.pumpWidget(
      MaterialApp(home: CurriculumAuditScreen(controller: controller)),
    );
    await tester.pump();

    expect(
      find.text('Landesspezifische Zuordnung für Mecklenburg-Vorpommern'),
      findsOneWidget,
    );
    expect(find.textContaining('31.07.2027'), findsOneWidget);
    expect(
      find.textContaining('keine amtliche Zertifizierung'),
      findsOneWidget,
    );
  });

  test('Thüringen-Standard-API bleibt rückwärtskompatibel', () {
    expect(CurriculumAuditCatalog.objectives, isNotEmpty);
    expect(
      CurriculumAuditCatalog.objectives.every(
        (objective) => objective.id.startsWith('RB-TH-'),
      ),
      isTrue,
    );
    for (final grade in GradeLevel.values) {
      expect(
        CurriculumAuditCatalog.audit(grade).total,
        CurriculumAuditCatalog.audit(grade, state: GermanState.thuringia).total,
      );
    }
  });
}
