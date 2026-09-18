import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/screens/parent_screen.dart';
import 'package:rechenblitz/screens/teacher_mode_screen.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/subjects/german/german_storage_service.dart';
import 'package:rechenblitz/subjects/german/screens/german_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('German home keeps parent and achievements in German context', (
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
    expect(find.byKey(const ValueKey('german-rewards')), findsOneWidget);
    expect(find.byKey(const ValueKey('german-more')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('german-rewards')));
    await tester.pumpAndSettle();
    expect(find.text('Meine Deutsch-Erfolge'), findsOneWidget);
    expect(find.textContaining('Mathe-Sterne'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('german-more')));
    await tester.pumpAndSettle();

    expect(find.text('Elternbereich'), findsOneWidget);
    expect(find.text('Deutsch · 2 Sekunden gedrückt halten'), findsOneWidget);
  });

  testWidgets('math parent and teacher areas do not expose German sections', (
    tester,
  ) async {
    final controller = AppController();
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(home: ParentScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Elternbereich · Mathe'), findsOneWidget);
    expect(find.byKey(const ValueKey('parent-german-overview')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(home: TeacherModeScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('teacher-open-german')), findsNothing);
    expect(find.text('Deutsch-Auftrag erstellen'), findsNothing);
  });
}
