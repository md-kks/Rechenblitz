import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_assessment.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/screens/german_assessment_result_screen.dart';

void main() {
  testWidgets('perfect Lerncheck shows no artificial practice focus', (
    tester,
  ) async {
    final summary = GermanAssessmentSummary.fromSession(
      _session(const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'read-perfect',
          competencyId: GermanCompetencyId.wordRecognition,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
        ),
        GermanTaskResult(
          taskId: 'language-perfect',
          competencyId: GermanCompetencyId.nounArticle,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(home: GermanAssessmentResultScreen(summary: summary)),
    );
    await tester.pumpAndSettle();

    final success = find.text('Heute direkt gelungen');
    await tester.scrollUntilVisible(
      success,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(success, findsOneWidget);
    expect(find.text('Als Nächstes üben'), findsNothing);
    expect(find.textContaining('nach weiteren Versuchen gelöst'), findsNothing);
  });

  testWidgets('Lerncheck shows assisted reading without fake weakness', (
    tester,
  ) async {
    final summary = GermanAssessmentSummary.fromSession(
      _session(const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'read-assisted',
          competencyId: GermanCompetencyId.wordRecognition,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
          usedReadAloud: true,
        ),
        GermanTaskResult(
          taskId: 'language-independent',
          competencyId: GermanCompetencyId.nounArticle,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(home: GermanAssessmentResultScreen(summary: summary)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('mit Vorlesen geübt'), findsOneWidget);
    final reading = find.widgetWithText(ListTile, 'Lesen');
    await tester.scrollUntilVisible(
      reading,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: reading,
        matching: find.textContaining('noch keine selbstständige Beobachtung'),
      ),
      findsOneWidget,
    );
    expect(find.text('Als Nächstes üben'), findsNothing);
    expect(find.text('Selbstständige Beobachtung ergänzen'), findsOneWidget);
    expect(find.text('Heute direkt gelungen'), findsNothing);
  });

  testWidgets('Lerncheck result makes retry evidence visible', (tester) async {
    final summary = GermanAssessmentSummary.fromSession(
      _session(const <GermanTaskResult>[
        GermanTaskResult(
          taskId: 'read-retry',
          competencyId: GermanCompetencyId.wordRecognition,
          correctFirstTry: false,
          incorrectAttempts: 2,
          responseMs: 1800,
        ),
        GermanTaskResult(
          taskId: 'language-direct',
          competencyId: GermanCompetencyId.nounArticle,
          correctFirstTry: true,
          incorrectAttempts: 0,
          responseMs: 900,
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(home: GermanAssessmentResultScreen(summary: summary)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('1 Aufgabe nach weiteren Versuchen gelöst'),
      findsOneWidget,
    );
    final focus = find.text('Als Nächstes üben');
    await tester.scrollUntilVisible(
      focus,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(focus, findsOneWidget);
    expect(find.text('Lesen'), findsWidgets);
    expect(find.text('Heute direkt gelungen'), findsNothing);
  });
}

GermanSessionResult _session(List<GermanTaskResult> results) =>
    GermanSessionResult(
      gradeLevel: GradeLevel.second,
      startedAt: DateTime(2026, 9, 18, 10),
      finishedAt: DateTime(2026, 9, 18, 10, 5),
      kind: GermanSessionKind.assessment,
      taskResults: results,
    );
