import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/screens/german_teacher_mode_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('German teacher mode creates anonymous offline assignment QR', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GermanTeacherModeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deutsch-Auftrag'), findsOneWidget);
    expect(find.text('Klassenstufe'), findsOneWidget);
    expect(find.text('Lernbereich'), findsOneWidget);
    expect(find.text('Lernziel'), findsOneWidget);
    expect(
      find.textContaining('Kein Name, keine Profil-ID und kein Lernverlauf'),
      findsOneWidget,
    );

    expect(find.byKey(const ValueKey('german-teacher-qr')), findsOneWidget);
    expect(find.textContaining('Auftrags-ID:'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('german-teacher-scan-result')),
      findsOneWidget,
    );
  });
}
