import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_parent_overview.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/screens/german_parent_overview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GermanSessionResult _session({
  required GermanCompetencyId competency,
  required List<bool> correct,
  int minute = 0,
}) => GermanSessionResult(
  gradeLevel: GradeLevel.second,
  startedAt: DateTime(2026, 9, 17, 10, minute),
  finishedAt: DateTime(2026, 9, 17, 10, minute + 1),
  taskResults: <GermanTaskResult>[
    for (var i = 0; i < correct.length; i++)
      GermanTaskResult(
        taskId: '${competency.name}-$i',
        competencyId: competency,
        correctFirstTry: correct[i],
        incorrectAttempts: correct[i] ? 0 : 1,
        responseMs: 1200,
      ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('parent overview separates strengths from practice needs', () {
    final overview = GermanParentOverview.analyze(
      gradeLevel: GradeLevel.second,
      history: <GermanSessionResult>[
        _session(
          competency: GermanCompetencyId.nounArticle,
          correct: const <bool>[true, true, true],
        ),
        _session(
          competency: GermanCompetencyId.wordRecognition,
          correct: const <bool>[false, true],
          minute: 5,
        ),
      ],
    );

    expect(overview.sessionCount, 2);
    expect(overview.totalTasks, 5);
    expect(overview.secureCompetencies, 1);
    expect(
      overview.strengths.single.competencyId,
      GermanCompetencyId.nounArticle,
    );
    expect(
      overview.practiceNeeds.first.competencyId,
      GermanCompetencyId.wordRecognition,
    );
  });

  testWidgets('German parent overview reads only local profile progress', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.saveHistory(<GermanSessionResult>[
      _session(
        competency: GermanCompetencyId.nounArticle,
        correct: const <bool>[true, true, true],
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: GermanParentOverviewScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deutsch-Lernstand'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('100 %'), findsWidgets);
    expect(find.textContaining('Nomen und Artikel erkennen'), findsOneWidget);
  });
}
