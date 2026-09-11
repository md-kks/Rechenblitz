import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/competency_map_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';

void main() {
  testWidgets('Lernlandkarte trennt fehlende von falscher Selbstständigkeit', (
    tester,
  ) async {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = [
      for (var index = 0; index < 3; index++)
        MicroCompetencyObservation(
          id: MicroCompetencyId.additionTenBridge,
          occurredAt: DateTime(2026, 9, 10, 10, index),
          correct: true,
          evidenceWeight: 0.8,
          source: MicroEvidenceSource.practice,
          usedHelp: true,
          helpLevel: 1,
          mode: TrainingMode.practice,
          gradeLevel: GradeLevel.second,
          numberRange: NumberRangeLevel.hundred,
          taskKey: 'plus:17:4:$index',
        ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionTenBridge,
        occurredAt: DateTime(2026, 9, 10, 11),
        correct: true,
        evidenceWeight: 0.8,
        source: MicroEvidenceSource.review,
        usedHelp: true,
        helpLevel: 1,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:18:5:review',
      ),
      MicroCompetencyObservation(
        id: MicroCompetencyId.additionTenBridge,
        occurredAt: DateTime(2026, 9, 10, 12),
        correct: true,
        evidenceWeight: 0.8,
        source: MicroEvidenceSource.transfer,
        usedHelp: true,
        helpLevel: 1,
        mode: TrainingMode.wordProblems,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'story:transfer:skill:additionTenBridge:+:books:18:5',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: CompetencyMapScreen(controller: controller)),
    );
    await tester.pump();

    expect(find.text('Als Nächstes'), findsOneWidget);
    expect(find.text('Dein Fortschritt'), findsOneWidget);
    expect(find.text('Plus über den Zehner'), findsOneWidget);
    expect(find.textContaining('noch nicht beobachtet'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('learning-group:Zahlen & Rechnen')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('learning-mode:practice')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('micro-info:additionTenBridge')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('micro-info:additionTenBridge')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Allein'), findsOneWidget);
    expect(find.text('noch nicht allein probiert'), findsOneWidget);
    expect(find.text('Später noch einmal'), findsOneWidget);
    expect(find.text('Bei anderer Aufgabe'), findsOneWidget);
    expect(find.text('bisher mit Hilfe'), findsNWidgets(2));
    expect(find.text('0 % richtig'), findsNothing);
  });
}
