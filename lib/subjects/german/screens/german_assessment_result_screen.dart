import 'package:flutter/material.dart';

import '../german_assessment.dart';
import '../german_learning_domain.dart';

class GermanAssessmentResultScreen extends StatelessWidget {
  const GermanAssessmentResultScreen({super.key, required this.summary});

  final GermanAssessmentSummary summary;

  @override
  Widget build(BuildContext context) {
    final percent = (summary.session.accuracy * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Lerncheck ausgewertet')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: <Widget>[
            Text(
              'Deine Momentaufnahme',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Der Lerncheck ist keine Note. Er zeigt, was gerade leicht fällt und was als Nächstes geübt werden kann.',
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${summary.session.correctFirstTry} von ${summary.session.total} direkt richtig',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text('$percent % beim ersten Versuch'),
                    if (summary.solvedAfterRetry > 0) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        '${summary.solvedAfterRetry} ${summary.solvedAfterRetry == 1 ? 'Aufgabe' : 'Aufgaben'} nach weiteren Versuchen gelöst',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Lernbereiche', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...summary.domains
                .where((entry) => entry.total > 0)
                .map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text(entry.domain.label),
                      subtitle: Text(
                        entry.solvedAfterRetry == 0
                            ? '${entry.correctFirstTry} von ${entry.total} direkt richtig'
                            : '${entry.correctFirstTry} direkt · ${entry.solvedAfterRetry} nach weiteren Versuchen',
                      ),
                      trailing: Text('${(entry.accuracy * 100).round()} %'),
                    ),
                  ),
                ),
            const SizedBox(height: 18),
            if (summary.nextDomains.isNotEmpty) ...<Widget>[
              Text(
                'Als Nächstes üben',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                summary.nextDomains
                    .map((entry) => entry.domain.label)
                    .join(' · '),
              ),
              const SizedBox(height: 18),
            ] else ...<Widget>[
              Text(
                'Heute direkt gelungen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'In diesem Lerncheck waren alle Aufgaben beim ersten Versuch richtig.',
              ),
              const SizedBox(height: 18),
            ],
            FilledButton(
              key: const ValueKey('german-assessment-done'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zurück zu Deutsch'),
            ),
          ],
        ),
      ),
    );
  }
}
