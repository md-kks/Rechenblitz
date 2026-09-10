import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/competency_map_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';

void main() {
  testWidgets('Lernlandkarte trennt fehlende von falscher Selbstständigkeit',
      (tester) async {
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
    await tester.scrollUntilVisible(
      find.text('Plus über den Zehner'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.textContaining('Selbstständig: noch nicht beobachtet'), findsOneWidget);
    expect(find.textContaining('Abstand: bisher nur mit Hilfe'), findsOneWidget);
    expect(find.textContaining('Transfer: bisher nur mit Hilfe'), findsOneWidget);
    expect(find.textContaining('Selbstständig: 0 %'), findsNothing);
  });
}
