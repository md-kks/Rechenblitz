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
}
