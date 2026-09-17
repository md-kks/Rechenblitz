import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/screens/german_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('German home exposes daily round and all six domains', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meine Deutsch-Runde'), findsOneWidget);
    expect(find.text('Lerncheck'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Lesen'), 180);
    expect(find.text('Lesen'), findsOneWidget);
    expect(find.text('Rechtschreibung'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sprache untersuchen'), 180);
    expect(find.text('Sprache untersuchen'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Wörter & Wortschatz'), 180);
    expect(find.text('Wörter & Wortschatz'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Schreiben'), 180);
    expect(find.text('Sprechen & Zuhören'), findsOneWidget);
    expect(find.text('Schreiben'), findsOneWidget);
  });

  testWidgets('German home opens the competency map', (tester) async {
    final controller = AppController();
    await controller.load();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

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
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-daily-round')));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch üben'), findsOneWidget);
    expect(find.text('1 von 6'), findsOneWidget);
  });
  testWidgets('competency map starts targeted six-task practice', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-competency-map')));
    await tester.pumpAndSettle();
    final practiceButton = find.text('Gezielt üben').first;
    await tester.scrollUntilVisible(practiceButton, 160);
    await tester.tap(practiceButton);
    await tester.pumpAndSettle();

    expect(find.text('Deutsch üben'), findsOneWidget);
    expect(find.text('1 von 6'), findsOneWidget);
  });
  testWidgets('German home starts a support-free Lerncheck', (tester) async {
    final controller = AppController();
    await controller.load();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('german-assessment-start'));
    await tester.scrollUntilVisible(button, 180);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Deutsch-Lerncheck'), findsOneWidget);
    expect(find.text('1 von 12'), findsOneWidget);
  });

  testWidgets('first German visit offers Lerncheck or direct practice', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(false);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei Deutsch'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('german-intro-assessment')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('german-intro-skip')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('german-intro-skip')));
    await tester.pumpAndSettle();

    expect(find.text('Meine Deutsch-Runde'), findsOneWidget);
    expect(await storage.loadIntroComplete(), isTrue);
  });

  testWidgets('first German visit can start the adaptive Lerncheck directly', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    final storage = GermanStorageService(profileId: controller.activeProfileId);
    await storage.setIntroComplete(false);

    await tester.pumpWidget(
      MaterialApp(home: GermanHomeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('german-intro-assessment')));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch-Lerncheck'), findsOneWidget);
    expect(find.text('1 von 12'), findsOneWidget);
    expect(await storage.loadIntroComplete(), isTrue);
  });
}
