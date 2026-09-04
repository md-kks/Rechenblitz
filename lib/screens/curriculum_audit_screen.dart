import 'package:flutter/material.dart';

import '../models/curriculum_audit.dart';
import '../models/learner_profile.dart';
import '../models/micro_competency.dart';
import '../services/app_controller.dart';

class CurriculumAuditScreen extends StatelessWidget {
  const CurriculumAuditScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final grade = controller.gradeLevel;
    final summary = CurriculumAuditCatalog.audit(grade);
    final objectives = CurriculumAuditCatalog.forGrade(grade);
    final domains = <String, List<CurriculumObjective>>{};
    for (final objective in objectives) {
      domains.putIfAbsent(objective.domain, () => []).add(objective);
    }
    final thuringia =
        controller.activeProfile.state == GermanState.thuringia;

    return Scaffold(
      appBar: AppBar(title: const Text('Lehrplan-Audit')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                thuringia
                    ? 'Detaillierte Zuordnung für Thüringen. Der Audit beschreibt die Abdeckung in Rechenblitz und ist keine amtliche Zertifizierung.'
                    : 'Für ${controller.activeProfile.state.label} nutzt Rechenblitz derzeit den gemeinsamen Grundschul-Mathematikkern. Der detaillierte Lernziel-Audit ist momentan nur für Thüringen gepflegt.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _Metric('Lernziele', '${summary.total}'),
                  _Metric('digital übbar', '${summary.digital}'),
                  _Metric('praktisch ergänzen', '${summary.supported}'),
                  _Metric(
                    'Struktur',
                    summary.structurallyComplete ? 'vollständig' : 'Lücken',
                  ),
                ],
              ),
            ),
          ),
          if (!summary.structurallyComplete) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Interner Auditfehler: ${summary.missingCompetencies.length} Mikro-Kompetenzen besitzen noch keine Lernziel-Zuordnung.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...domains.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DomainCard(
                title: entry.key,
                objectives: entry.value,
                controller: controller,
              ),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Wichtig: Digital gut lösbare Aufgaben ersetzen keine realen Mess-, Zeichen-, Falt-, Bau- oder Orientierungserfahrungen. Rechenblitz markiert solche Lernziele deshalb ausdrücklich als praktisch zu ergänzen.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.title,
    required this.objectives,
    required this.controller,
  });

  final String title;
  final List<CurriculumObjective> objectives;
  final AppController controller;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...objectives.map((objective) {
                final progress =
                    controller.microCompetencyProgress(objective.competency);
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 10),
                  title: Text(
                    objective.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    progress.observations == 0
                        ? 'Noch keine Lernbeobachtung'
                        : '${progress.state.label} · ${(progress.accuracy * 100).round()} % · ${progress.observations} Beobachtungen',
                  ),
                  trailing: Chip(
                    label: Text(
                      objective.coverage ==
                              CurriculumCoverage.digitalPractice
                          ? 'digital'
                          : 'praktisch + digital',
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(objective.note),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Interne Lernziel-ID: ${objective.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label),
        ],
      );
}
