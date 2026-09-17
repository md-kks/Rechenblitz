import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/german_state.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_curriculum.dart';
import 'package:rechenblitz/subjects/german/screens/german_curriculum_audit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test(
    'German curriculum registry distinguishes detailed and baseline states',
    () {
      final thuringia = GermanCurriculumRegistry.forState(
        GermanState.thuringia,
      );
      final saxony = GermanCurriculumRegistry.forState(GermanState.saxony);

      expect(thuringia.detailedMapping, isTrue);
      expect(thuringia.referenceLabel, contains('Thüringer'));
      expect(saxony.detailedMapping, isFalse);
      expect(saxony.referenceLabel, contains('Grundschul-Deutsch-Kern'));
    },
  );

  test('German curriculum audit has no task coverage gaps', () {
    for (final grade in GradeLevel.values) {
      final summary = GermanCurriculumAudit.summarize(grade);
      expect(summary.total, greaterThan(0), reason: grade.name);
      expect(summary.structurallyComplete, isTrue, reason: grade.name);
      expect(
        summary.digitalPractice +
            summary.guidedDigitalPractice +
            summary.classroomExtension,
        summary.total,
        reason: grade.name,
      );
    }
  });

  test('speaking production stays marked for real-world practice', () {
    expect(
      GermanCurriculumAudit.coverageFor(
        GermanCompetencyId.presentationStructure,
      ),
      GermanCurriculumCoverage.classroomExtension,
    );
    expect(
      GermanCurriculumAudit.coverageFor(GermanCompetencyId.textRevision),
      GermanCurriculumCoverage.guidedDigitalPractice,
    );
  });

  testWidgets('German curriculum audit shows the profile state', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GermanCurriculumAuditScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deutsch-Lehrplan-Audit'), findsOneWidget);
    expect(
      find.textContaining('Detaillierte Zuordnung für Thüringen'),
      findsOneWidget,
    );
    expect(find.text('Struktur'), findsOneWidget);
    expect(find.text('vollständig'), findsOneWidget);
  });
}
