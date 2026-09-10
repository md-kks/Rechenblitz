import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/curriculum_audit_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';

void main() {
  testWidgets('Lehrplan-Audit zeigt Hilfe nicht als selbstständige 100 Prozent',
      (tester) async {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      3,
      (index) => MicroCompetencyObservation(
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
    );

    await tester.pumpWidget(
      MaterialApp(home: CurriculumAuditScreen(controller: controller)),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Plus über den Zehner'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(
      find.textContaining('selbstständige Basis noch offen'),
      findsOneWidget,
    );
    expect(find.textContaining('100 %'), findsNothing);
  });

  testWidgets('Lehrplan-Audit zeigt echte selbstständige Nullquote als 0 Prozent',
      (tester) async {
    final controller = AppController();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      3,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionTenBridge,
        occurredAt: DateTime(2026, 9, 10, 11, index),
        correct: false,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: false,
        helpLevel: 0,
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:17:4:$index',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: CurriculumAuditScreen(controller: controller)),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Plus über den Zehner'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.textContaining('selbstständig 0 %'), findsOneWidget);
    expect(
      find.textContaining('selbstständige Basis noch offen'),
      findsNothing,
    );
  });
}
