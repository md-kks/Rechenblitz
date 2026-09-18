import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/german_state.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_curriculum.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_curriculum_audit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GermanSessionResult _session(
  GradeLevel grade,
  List<String> taskIds,
  GermanCompetencyId competency, {
  int minute = 0,
}) => GermanSessionResult(
  gradeLevel: grade,
  startedAt: DateTime(2026, 9, 18, 10, minute),
  finishedAt: DateTime(2026, 9, 18, 10, minute + 1),
  taskResults: <GermanTaskResult>[
    for (final taskId in taskIds)
      GermanTaskResult(
        taskId: taskId,
        competencyId: competency,
        correctFirstTry: true,
        incorrectAttempts: 0,
        responseMs: 1000,
      ),
  ],
);

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

  testWidgets('curriculum audit marks a pending grade bridge', (tester) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.third;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    final tasks =
        GermanTaskCatalog.forCompetency(GermanCompetencyId.wordFamilies)
            .where((task) => task.recommendedFromGrade == GradeLevel.second)
            .take(3)
            .toList(growable: false);
    await storage.saveHistory(<GermanSessionResult>[
      _session(
        GradeLevel.second,
        tasks.take(2).map((task) => task.id).toList(growable: false),
        GermanCompetencyId.wordFamilies,
      ),
      _session(
        GradeLevel.second,
        <String>[tasks.last.id],
        GermanCompetencyId.wordFamilies,
        minute: 5,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: GermanCurriculumAuditScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final tile = find.byKey(const ValueKey('german-curriculum-wordFamilies'));
    await tester.scrollUntilVisible(
      tile,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: tile,
        matching: find.textContaining('Klassenstufe bestätigen'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: tile,
        matching: find.textContaining('Grundlage aus Klasse 2 sicher'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: tile,
        matching: find.textContaining('Klasse 3 noch offen'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('curriculum audit ignores evidence from a future grade', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    final task = GermanTaskCatalog.forCompetency(
      GermanCompetencyId.nounArticle,
    ).first;
    await storage.saveHistory(<GermanSessionResult>[
      _session(GradeLevel.fourth, <String>[
        task.id,
      ], GermanCompetencyId.nounArticle),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: GermanCurriculumAuditScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final tile = find.byKey(const ValueKey('german-curriculum-nounArticle'));
    await tester.scrollUntilVisible(
      tile,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: tile,
        matching: find.text('Noch keine Lernbeobachtung'),
      ),
      findsOneWidget,
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
