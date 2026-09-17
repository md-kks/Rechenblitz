import 'package:flutter/material.dart';

import '../../../core/grade_level.dart';
import '../german_competency_catalog.dart';
import '../german_learning_domain.dart';
import '../german_progress.dart';
import '../german_prerequisites.dart';
import '../german_session.dart';

class GermanCompetencyMapScreen extends StatelessWidget {
  const GermanCompetencyMapScreen({
    super.key,
    required this.gradeLevel,
    required this.history,
  });

  final GradeLevel gradeLevel;
  final List<GermanSessionResult> history;

  @override
  Widget build(BuildContext context) {
    final definitions = GermanCompetencyCatalog.recommendedFor(gradeLevel);
    final progress = definitions
        .map(
          (definition) =>
              GermanProgressAnalyzer.forCompetency(definition.id, history),
        )
        .toList(growable: false);
    final secure = progress
        .where((item) => item.state == GermanCompetencyState.secure)
        .length;
    final learning = progress
        .where((item) => item.state == GermanCompetencyState.learning)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Deutsch-Lernlandkarte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    gradeLevel.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$secure sicher · $learning im Aufbau · '
                    '${definitions.length - secure - learning} neu',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...GermanLearningDomain.values.expand(
            (domain) => _domainSection(context, domain),
          ),
        ],
      ),
    );
  }

  List<Widget> _domainSection(
    BuildContext context,
    GermanLearningDomain domain,
  ) {
    final definitions = GermanCompetencyCatalog.forDomain(domain, gradeLevel);
    if (definitions.isEmpty) return const <Widget>[];
    return <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
        child: Text(
          domain.label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      ...definitions.map((definition) {
        final progress = GermanProgressAnalyzer.forCompetency(
          definition.id,
          history,
        );
        final unlock = GermanPrerequisiteResolver.status(
          definition.id,
          history,
        );
        final practiceId = unlock.isUnlocked
            ? definition.id
            : unlock.nextRequired?.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CompetencyCard(
            competencyId: definition.id.name,
            label: definition.label,
            description: definition.description,
            progress: progress,
            unlock: unlock,
            onPractice: practiceId == null
                ? null
                : () => Navigator.of(context).pop(practiceId),
          ),
        );
      }),
    ];
  }
}

class _CompetencyCard extends StatelessWidget {
  const _CompetencyCard({
    required this.competencyId,
    required this.label,
    required this.description,
    required this.progress,
    required this.unlock,
    required this.onPractice,
  });

  final String competencyId;
  final String label;
  final String description;
  final GermanCompetencyProgress progress;
  final GermanCompetencyUnlockStatus unlock;
  final VoidCallback? onPractice;

  @override
  Widget build(BuildContext context) {
    final status = switch (progress.state) {
      GermanCompetencyState.newSkill => ('Neu', Icons.circle_outlined),
      GermanCompetencyState.learning => ('Im Aufbau', Icons.timelapse_rounded),
      GermanCompetencyState.secure => (
        'Sicher',
        Icons.check_circle_outline_rounded,
      ),
    };
    final evidence = progress.attempts == 0
        ? 'Noch keine Übungsergebnisse'
        : '${progress.correctFirstTry} von ${progress.attempts} direkt richtig';
    final locked = !unlock.isUnlocked;
    final next = unlock.nextRequired;
    final detail = locked && next != null
        ? '$evidence\nZuerst: ${next.label}'
        : evidence;
    return Card(
      key: ValueKey('german-competency-card-$competencyId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ListTile(
            leading: Icon(locked ? Icons.lock_outline_rounded : status.$2),
            title: Text(label),
            subtitle: Text('${status.$1} · $description\n$detail'),
            isThreeLine: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: OutlinedButton.icon(
              key: ValueKey('german-competency-practice-$competencyId'),
              onPressed: onPractice,
              icon: Icon(
                locked ? Icons.account_tree_outlined : Icons.play_arrow_rounded,
              ),
              label: Text(locked ? 'Grundlage üben' : 'Gezielt üben'),
            ),
          ),
        ],
      ),
    );
  }
}
