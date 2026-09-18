import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_audit.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/home_screen.dart';
import 'package:rechenblitz/screens/parent_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('aktive Lernwelten folgen Klassenstufe und Landeslehrplan', () async {
    final controller = AppController();
    await controller.load();

    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.twenty;
    await controller.setProfileState(GermanState.bavaria);

    expect(
      controller.isModeAvailableInActiveCurriculum(TrainingMode.multiply),
      isFalse,
    );
    expect(
      controller.isModeAvailableInActiveCurriculum(TrainingMode.divide),
      isFalse,
    );
    expect(
      controller.isModeAvailableInActiveCurriculum(TrainingMode.dataCharts),
      isFalse,
    );

    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.setProfileState(GermanState.bavaria);

    expect(
      controller.isModeAvailableInActiveCurriculum(TrainingMode.multiply),
      isTrue,
    );
    expect(
      controller.isModeAvailableInActiveCurriculum(TrainingMode.dataCharts),
      isTrue,
    );
    expect(
      controller.isModeAvailableInActiveCurriculum(TrainingMode.probability),
      isTrue,
    );
    expect(
      controller.isModeAvailableInActiveCurriculum(TrainingMode.combinatorics),
      isTrue,
    );

    await controller.setProfileState(GermanState.hesse);

    expect(
      controller.isModeAvailableInActiveCurriculum(TrainingMode.dataCharts),
      isFalse,
    );
    expect(
      controller.isModeAvailableInActiveCurriculum(TrainingMode.probability),
      isFalse,
    );
    expect(
      controller.isModeAvailableInActiveCurriculum(TrainingMode.combinatorics),
      isFalse,
    );
  });

  test('Oberstufen-Lernwelten haben immer ein aktives Landesziel', () async {
    final controller = AppController();
    await controller.load();

    for (final state in GermanState.values) {
      await controller.setProfileState(state);
      for (final grade in <GradeLevel>[GradeLevel.third, GradeLevel.fourth]) {
        controller.gradeLevel = grade;
        final definitions = CurriculumAuditCatalog.definitionsForGrade(
          state,
          grade,
        );
        final activeModes = definitions
            .map((definition) => definition.preferredMode)
            .toSet();

        for (final mode in controller.curriculumModesForGrade(grade)) {
          expect(
            mode.isUpperPrimary,
            isTrue,
            reason: '${state.name}/${grade.name}',
          );
          expect(
            activeModes,
            contains(mode),
            reason: '${state.name}/${grade.name}/${mode.name}',
          );
        }
      }
    }
  });

  test('Empfehlung bleibt in allen Ländern curricular erreichbar', () async {
    final controller = AppController();
    await controller.load();

    for (final state in GermanState.values) {
      await controller.setProfileState(state);
      for (final grade in GradeLevel.values) {
        controller.gradeLevel = grade;
        controller.numberRange = switch (grade) {
          GradeLevel.first => NumberRangeLevel.twenty,
          GradeLevel.second => NumberRangeLevel.hundred,
          GradeLevel.third => NumberRangeLevel.thousand,
          GradeLevel.fourth => NumberRangeLevel.million,
        };

        final mode = controller.recommendedMode();
        expect(
          controller.isModeAvailableInActiveCurriculum(mode),
          isTrue,
          reason: '${state.name}/${grade.name}/${mode.name}',
        );
      }
    }
  });

  testWidgets('Klasse 1 blendet Malnehmen und Teilen im Übungskatalog aus', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.first;
    controller.numberRange = NumberRangeLevel.twenty;

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(controller: controller)),
    );
    await tester.tap(find.text('Mehr üben'));
    await tester.pumpAndSettle();

    expect(find.text('Minus üben'), findsOneWidget);
    expect(find.text('Malnehmen'), findsNothing);
    expect(find.text('Teilen'), findsNothing);
  });

  testWidgets('Klasse 2 zeigt frühe Landesziele nur dort wo sie gelten', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.setProfileState(GermanState.bavaria);

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(controller: controller)),
    );
    await tester.tap(find.text('Mehr üben'));
    await tester.pumpAndSettle();

    expect(find.text('Daten & Zufall · Lehrplan'), findsOneWidget);
    expect(find.text('Daten & Diagramme'), findsOneWidget);
    expect(find.text('Wahrscheinlichkeit'), findsOneWidget);
    expect(find.text('Kombinatorik'), findsOneWidget);

    await controller.setProfileState(GermanState.hesse);
    await tester.pumpAndSettle();

    expect(find.text('Daten & Zufall · Lehrplan'), findsNothing);
    expect(find.text('Daten & Diagramme'), findsNothing);
    expect(find.text('Wahrscheinlichkeit'), findsNothing);
    expect(find.text('Kombinatorik'), findsNothing);
  });

  testWidgets('Elternbereich zeigt frühe Landesziele konsistent', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    await controller.setProfileState(GermanState.bavaria);

    await tester.pumpWidget(
      MaterialApp(home: ParentScreen(controller: controller)),
    );
    await tester.scrollUntilVisible(
      find.text('Daten & Zufall · Landeslehrplan'),
      450,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Daten & Zufall · Landeslehrplan'), findsOneWidget);
    expect(find.text(TrainingMode.dataCharts.title), findsOneWidget);
    expect(find.text(TrainingMode.probability.title), findsOneWidget);
    expect(find.text(TrainingMode.combinatorics.title), findsOneWidget);

    await controller.setProfileState(GermanState.hesse);
    await tester.pumpAndSettle();

    expect(find.text('Daten & Zufall · Landeslehrplan'), findsNothing);
  });
}
