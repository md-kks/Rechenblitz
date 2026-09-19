import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/main_wortblitz.dart';
import 'package:rechenblitz/screens/home_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Wortblitz onboarding never starts the Mathe assessment', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();

    await tester.pumpWidget(WortblitzApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Wortblitz'), findsOneWidget);
    expect(find.text('Start 1 von 1'), findsOneWidget);
    expect(find.text('Weiter zu Wortblitz'), findsOneWidget);
    expect(find.text('Weiter zum Lerncheck'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('learning-start-next')));
    await tester.pumpAndSettle();

    expect(controller.needsOnboarding, isFalse);
    expect(find.text('Willkommen bei Wortblitz'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('german-intro-assessment')),
      findsOneWidget,
    );
    expect(find.text('Ein kurzer Lerncheck'), findsNothing);
  });

  testWidgets('standalone Wortblitz shows German only', (tester) async {
    final controller = AppController();
    await controller.load();
    await controller.completeOnboardingWithoutAssessment();
    await GermanStorageService(
      profileId: controller.activeProfileId,
    ).setIntroComplete(true);

    await tester.pumpWidget(WortblitzApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Wortblitz'), findsOneWidget);
    expect(find.text('Meine Deutsch-Runde'), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-switch-math')), findsNothing);
    expect(find.byKey(const ValueKey('subject-switch-german')), findsNothing);
  });

  testWidgets('combined shell can still expose both subjects', (tester) async {
    final controller = AppController();
    await controller.load();
    await controller.completeOnboardingWithoutAssessment();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(controller: controller, showSubjectSwitcher: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('subject-switch-math')), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-switch-german')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('subject-switch-german')));
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei Deutsch'), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-switch-math')), findsOneWidget);
  });
}
