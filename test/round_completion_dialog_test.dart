import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/reward_badge.dart';
import 'package:rechenblitz/widgets/round_completion_dialog.dart';

void main() {
  testWidgets('Rundenabschluss zeigt nur die wichtigsten Kinderinfos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showRoundCompletionDialog(
                  context,
                  completed: 10,
                  correctFirstTry: 8,
                  starsEarned: 2,
                  rewardReason: 'Du bist drangeblieben.',
                  newBadges: const [
                    RewardBadge(
                      id: 'explorer',
                      title: 'Entdecker',
                      description: 'Test',
                      stars: 2,
                      iconKey: 'explore',
                    ),
                  ],
                  averageSeconds: 3.4,
                ),
                child: const Text('Öffnen'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();

    expect(find.text('Runde geschafft!'), findsOneWidget);
    expect(find.text('8 von 10 direkt richtig'), findsOneWidget);
    expect(find.text('Im Schnitt 3.4 Sekunden'), findsOneWidget);
    expect(find.text('+2 Sterne'), findsOneWidget);
    expect(find.text('Du bist drangeblieben.'), findsOneWidget);
    expect(find.text('Neues Abzeichen'), findsOneWidget);
    expect(find.text('Entdecker'), findsOneWidget);
    expect(find.textContaining('Aufgaben bearbeitet'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('round-completion-done')));
    await tester.pumpAndSettle();
    expect(find.text('Runde geschafft!'), findsNothing);
  });

  testWidgets('Rundenabschluss erklärt adaptive Verkürzung', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showRoundCompletionDialog(
                context,
                completed: 3,
                correctFirstTry: 3,
                starsEarned: 1,
                adaptiveNote:
                    'Drei selbstständige Aufgaben waren direkt richtig. Zwei weitere Wiederholungen sind heute nicht nötig.',
              ),
              child: const Text('Adaptiv öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Adaptiv öffnen'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('round-adaptive-note')), findsOneWidget);
    expect(find.text('3 von 3 direkt richtig'), findsOneWidget);
    expect(find.textContaining('Zwei weitere Wiederholungen'), findsOneWidget);
  });

  testWidgets('adaptive Abschlussmeldung bleibt bei 200 Prozent lesbar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showRoundCompletionDialog(
                context,
                completed: 3,
                correctFirstTry: 3,
                starsEarned: 1,
                adaptiveNote:
                    'Drei selbstständige Aufgaben waren direkt richtig. Zwei weitere Wiederholungen sind heute nicht nötig.',
              ),
              child: const Text('Öffnen klein'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Öffnen klein'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('round-adaptive-note')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
