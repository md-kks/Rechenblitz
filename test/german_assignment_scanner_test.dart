import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/screens/assignment_scanner_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_teacher_assignment.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('manual scanner accepts a German offline assignment', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    const assignment = GermanTeacherAssignment(
      gradeLevel: GradeLevel.second,
      domain: GermanLearningDomain.reading,
      tasks: 5,
      targetCompetency: GermanCompetencyId.textInformation,
    );

    await tester.pumpWidget(
      MaterialApp(home: AssignmentScannerScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final input = find.byKey(const ValueKey('assignment-code-input')).first;
    await tester.ensureVisible(input);
    await tester.enterText(input, assignment.toPayload());
    await tester.tap(
      find.byKey(const ValueKey('assignment-code-submit')).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Deutsch-Auftrag erkannt'), findsOneWidget);
    expect(find.textContaining('Klasse 2'), findsWidgets);

    await tester.tap(find.text('Auftrag starten'));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch üben'), findsOneWidget);
    expect(find.text('1 von 5'), findsOneWidget);
  });
}
