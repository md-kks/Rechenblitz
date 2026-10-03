import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/screens/parent_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Elternbereich zeigt konkrete schriftliche Teilschritt-Lücke sofort',
    (tester) async {
      final controller = AppController();
      await controller.load();
      controller.gradeLevel = GradeLevel.third;
      controller.numberRange = NumberRangeLevel.thousand;
      controller.microObservations = [
        MicroCompetencyObservation(
          id: MicroCompetencyId.writtenDivideProcedure,
          occurredAt: DateTime.now().subtract(const Duration(minutes: 2)),
          correct: false,
          evidenceWeight: 0.35,
          source: MicroEvidenceSource.independentStep,
          usedHelp: false,
          mode: TrainingMode.writtenDivide,
          gradeLevel: GradeLevel.third,
          numberRange: NumberRangeLevel.thousand,
          taskKey:
              'independent:firstDivisionRemainder:written:divide:324:6',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(home: ParentScreen(controller: controller)),
      );
      await tester.pump();
      final gap = find.byKey(
        const ValueKey('parent-written-step-gap-firstDivisionRemainder'),
      );
      await tester.scrollUntilVisible(
        gap,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Konkrete Rechenschritt-Lücken'), findsOneWidget);
      expect(gap, findsOneWidget);
      expect(
        find.textContaining('Rest nach dem ersten Divisionsschritt'),
        findsOneWidget,
      );
      expect(find.textContaining('„Meine Runde“'), findsOneWidget);
    },
  );
}
