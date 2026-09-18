import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_session.dart';
import 'package:rechenblitz/subjects/german/screens/german_competency_map_screen.dart';

void main() {
  testWidgets('competency map separates secure skill from due review', (
    tester,
  ) async {
    final history = <GermanSessionResult>[
      _session(
        finishedAt: DateTime(2026, 8, 20, 10),
        taskIds: const <String>['word-a', 'word-b'],
      ),
      _session(
        finishedAt: DateTime(2026, 8, 21, 10),
        taskIds: const <String>['word-c'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: GermanCompetencyMapScreen(
          gradeLevel: GradeLevel.second,
          history: history,
          referenceNow: DateTime(2026, 9, 18, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1 Wiederholung'), findsOneWidget);

    final card = find.byKey(
      const ValueKey('german-competency-card-wordRecognition'),
    );
    await tester.scrollUntilVisible(
      card,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('Wiederholen')),
      findsOneWidget,
    );

    final practice = find.byKey(
      const ValueKey('german-competency-practice-wordRecognition'),
    );
    expect(
      find.descendant(of: practice, matching: find.text('Auffrischen')),
      findsOneWidget,
    );
  });

  testWidgets('fresh secure skill stays marked secure', (tester) async {
    final history = <GermanSessionResult>[
      _session(
        finishedAt: DateTime(2026, 9, 17, 10),
        taskIds: const <String>['word-a', 'word-b'],
      ),
      _session(
        finishedAt: DateTime(2026, 9, 17, 11),
        taskIds: const <String>['word-c'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: GermanCompetencyMapScreen(
          gradeLevel: GradeLevel.second,
          history: history,
          referenceNow: DateTime(2026, 9, 18, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(
      const ValueKey('german-competency-card-wordRecognition'),
    );
    await tester.scrollUntilVisible(
      card,
      180,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.descendant(of: card, matching: find.textContaining('Sicher')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Gezielt üben')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Auffrischen')),
      findsNothing,
    );
  });
}

GermanSessionResult _session({
  required DateTime finishedAt,
  required List<String> taskIds,
}) => GermanSessionResult(
  gradeLevel: GradeLevel.second,
  startedAt: finishedAt.subtract(const Duration(minutes: 1)),
  finishedAt: finishedAt,
  taskResults: <GermanTaskResult>[
    for (final taskId in taskIds)
      GermanTaskResult(
        taskId: taskId,
        competencyId: GermanCompetencyId.wordRecognition,
        correctFirstTry: true,
        incorrectAttempts: 0,
        responseMs: 900,
      ),
  ],
);
