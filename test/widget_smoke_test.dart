import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/main.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Startseite zeigt Grundschulstruktur und Lernwelten', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    expect(find.text('Hallo!'), findsOneWidget);
    expect(find.text('Klassenstufe'), findsOneWidget);
    expect(find.text('Zahlenraum'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    for (final label in ['Plus & Minus', 'Malnehmen', 'Zahlenmauern']) {
      await tester.scrollUntilVisible(
        find.text(label),
        250,
        scrollable: scrollable,
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Meine Runde und Lernlandkarte sind direkt erreichbar', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('my-round-button')),
      300,
      scrollable: scrollable,
    );

    expect(find.text('Meine Runde'), findsOneWidget);
    expect(find.text('Meine Lernlandkarte'), findsOneWidget);

    final myRoundButton = find.byKey(const ValueKey('my-round-button'));
    await tester.ensureVisible(myRoundButton);
    await tester.pumpAndSettle();
    await tester.tap(myRoundButton);
    await tester.pumpAndSettle();

    expect(find.text('Etwa 5–8 Minuten Mathe.'), findsOneWidget);
    expect(find.textContaining('von 12 Aufgaben'), findsOneWidget);
  });

  testWidgets('Erfolgsseite ist für das Kind direkt erreichbar', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    await tester.tap(find.byIcon(Icons.emoji_events_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Meine Erfolge'), findsOneWidget);
    expect(find.text('So entstehen Erfolge'), findsOneWidget);
  });

  testWidgets('Klasse 3 aktiviert neue Lehrplanbereiche', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    await tester.tap(find.text('3').first);
    await tester.pumpAndSettle();

    expect(controller.gradeLevel, GradeLevel.third);
    expect(controller.numberRange, NumberRangeLevel.thousand);
    expect(find.text('bis 1.000'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Große Zahlen'),
      450,
      scrollable: scrollable,
    );
    expect(find.text('Große Zahlen'), findsOneWidget);
    expect(find.text('Runden'), findsOneWidget);
  });

  testWidgets('Elternbereich öffnet nach zwei Sekunden Halten', (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    final gate = find.byIcon(Icons.admin_panel_settings_rounded);
    expect(gate, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(gate));
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    expect(find.text('Elternbereich'), findsOneWidget);
    await gesture.up();

    final parentScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Warum gerade diese Aufgaben?'),
      450,
      scrollable: parentScroll,
    );
    expect(find.text('Auswahl der nächsten Runde'), findsOneWidget);
    expect(find.text('Warum dieser Lernstatus?'), findsOneWidget);
    expect(find.text('Worauf stützt sich das?'), findsOneWidget);
  });
}
