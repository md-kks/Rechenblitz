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

  testWidgets('Startseite zeigt zuerst nur die wichtigsten Kinderaktionen',
      (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    expect(find.text('Hallo!'), findsOneWidget);
    expect(find.text('Deine Runde'), findsOneWidget);
    expect(find.text('5 Blitzaufgaben'), findsOneWidget);
    expect(find.text('Lernlandkarte'), findsOneWidget);
    expect(find.text('Mehr üben'), findsOneWidget);
    expect(find.text('Schulauftrag'), findsOneWidget);
    expect(find.text('Klassenstufe'), findsNothing);
    expect(find.text('Zahlenraum'), findsNothing);
    expect(find.text('Plus & Minus'), findsNothing);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsNothing);
    expect(find.byIcon(Icons.admin_panel_settings_rounded), findsNothing);

    await tester.tap(find.text('Mehr üben'));
    await tester.pumpAndSettle();
    expect(find.text('Plus & Minus'), findsOneWidget);
    expect(find.text('Malnehmen'), findsOneWidget);
    expect(find.text('Zahlenmauern'), findsOneWidget);
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

    expect(find.text('Deine Runde'), findsOneWidget);
    expect(find.text('Lernlandkarte'), findsOneWidget);

    final myRoundButton = find.byKey(const ValueKey('my-round-button'));
    await tester.ensureVisible(myRoundButton);
    await tester.pumpAndSettle();
    await tester.tap(myRoundButton);
    await tester.pumpAndSettle();

    expect(find.text('Etwa 5–8 Minuten Mathe.'), findsOneWidget);
    expect(find.textContaining('von 12 Aufgaben'), findsOneWidget);
  });

  testWidgets('Datenschutz ist aus den Einstellungen erreichbar',
      (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    await tester.tap(find.byTooltip('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('more-settings')));
    await tester.pumpAndSettle();

    final settingsScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Datenschutz'),
      350,
      scrollable: settingsScroll,
    );
    await tester.tap(find.text('Datenschutz'));
    await tester.pumpAndSettle();

    expect(find.text('Datenschutzerklärung'), findsOneWidget);
    expect(find.text('Datenschutz bei Rechenblitz'), findsOneWidget);
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

  testWidgets('Klasse 3 zeigt ihre Lernbereiche erst nach Mehr üben',
      (tester) async {
    final controller = AppController();
    controller.facts = const [];
    controller.loaded = true;
    controller.gradeLevel = GradeLevel.third;
    controller.numberRange = NumberRangeLevel.thousand;
    await tester.pumpWidget(RechenblitzApp(controller: controller));

    expect(find.textContaining('bis 1.000'), findsNothing);
    expect(find.text('Große Zahlen'), findsNothing);

    await tester.tap(find.text('Mehr üben'));
    await tester.pumpAndSettle();
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

    expect(find.byKey(const ValueKey('parent-gate')), findsNothing);
    await tester.tap(find.byTooltip('Mehr'));
    await tester.pumpAndSettle();

    final gate = find.byKey(const ValueKey('parent-gate'));
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
