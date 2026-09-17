import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/screens/german_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('German home exposes daily round and all six domains', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meine Deutsch-Runde'), findsOneWidget);
    expect(find.text('Lesen'), findsOneWidget);
    expect(find.text('Rechtschreibung'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sprache untersuchen'), 180);
    expect(find.text('Sprache untersuchen'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Wörter & Wortschatz'), 180);
    expect(find.text('Wörter & Wortschatz'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Schreiben'), 180);
    expect(find.text('Hören & Verstehen'), findsOneWidget);
    expect(find.text('Schreiben'), findsOneWidget);
  });

  testWidgets('German home opens the competency map', (tester) async {
    final controller = AppController();
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-competency-map')));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch-Lernlandkarte'), findsOneWidget);
    expect(find.textContaining('sicher'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Laute und Buchstaben verbinden'),
      180,
    );
    expect(find.text('Laute und Buchstaben verbinden'), findsOneWidget);
  });

  testWidgets('daily German round opens a touch-first training session', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-daily-round')));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch üben'), findsOneWidget);
    expect(find.text('1 von 6'), findsOneWidget);
  });
}
