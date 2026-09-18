import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/german_state.dart';
import '../../../core/grade_level.dart';
import '../../../core/learning_app_theme.dart';
import '../../../core/learning_subject.dart';
import '../../../services/app_controller.dart';
import '../german_competency.dart';
import '../german_curriculum.dart';
import '../german_grade_bridge.dart';
import '../german_learning_domain.dart';
import '../german_progress.dart';
import '../german_session.dart';
import '../german_storage_service.dart';

class GermanCurriculumAuditScreen extends StatefulWidget {
  const GermanCurriculumAuditScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<GermanCurriculumAuditScreen> createState() =>
      _GermanCurriculumAuditScreenState();
}

class _GermanCurriculumAuditScreenState
    extends State<GermanCurriculumAuditScreen> {
  List<GermanSessionResult>? _history;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final history = await GermanStorageService(
      profileId: widget.controller.activeProfileId,
    ).loadHistory();
    if (!mounted) return;
    setState(() => _history = history);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.activeProfile.state;
    final grade = widget.controller.gradeLevel;
    final profile = GermanCurriculumRegistry.forState(state);
    final summary = GermanCurriculumAudit.summarize(grade);
    final definitions = profile.competenciesFor(grade);
    final eligibleHistory = _history
        ?.where((session) => session.gradeLevel.index <= grade.index)
        .toList(growable: false);
    final byDomain = <GermanLearningDomain, List<GermanCompetencyDefinition>>{};
    for (final definition in definitions) {
      byDomain
          .putIfAbsent(definition.domain, () => <GermanCompetencyDefinition>[])
          .add(definition);
    }

    return Theme(
      data: LearningAppTheme.build(
        subject: LearningSubject.german,
        accessibility: widget.controller.accessibilityPreferences,
      ),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Deutsch-Lehrplan-Audit')),
          body: _history == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
                  children: <Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          profile.detailedMapping
                              ? 'Detaillierte Zuordnung für ${state.label}. Der Audit beschreibt die Abdeckung in der App und ist keine amtliche Zertifizierung.'
                              : 'Für ${state.label} nutzt Deutsch derzeit den gemeinsamen Grundschul-Kern. Eine landesspezifische Detailzuordnung ist noch nicht gepflegt.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SummaryCard(summary: summary),
                    const SizedBox(height: 16),
                    ...byDomain.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _DomainCard(
                          title: entry.key.label,
                          definitions: entry.value,
                          history: eligibleHistory!,
                          gradeLevel: grade,
                        ),
                      ),
                    ),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Sprechen, Erzählen, Präsentieren und Diskutieren lassen sich digital vorbereiten, müssen aber auch im echten Gespräch geübt und beobachtet werden.',
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final GermanCurriculumAuditSummary summary;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: <Widget>[
          _Metric('Lernschritte', '${summary.total}'),
          _Metric('digital', '${summary.digitalPractice}'),
          _Metric('unterstützt', '${summary.guidedDigitalPractice}'),
          _Metric('praktisch ergänzen', '${summary.classroomExtension}'),
          _Metric(
            'Struktur',
            summary.structurallyComplete ? 'vollständig' : 'Lücken',
          ),
        ],
      ),
    ),
  );
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.title,
    required this.definitions,
    required this.history,
    required this.gradeLevel,
  });

  final String title;
  final List<GermanCompetencyDefinition> definitions;
  final List<GermanSessionResult> history;
  final GradeLevel gradeLevel;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...definitions.map((definition) {
            final progress = GermanProgressAnalyzer.forCompetency(
              definition.id,
              history,
            );
            final bridge = GermanGradeBridgeAnalyzer.forCompetency(
              competencyId: definition.id,
              currentGrade: gradeLevel,
              history: history,
            );
            final coverage = GermanCurriculumAudit.coverageFor(definition.id);
            return ExpansionTile(
              key: ValueKey('german-curriculum-${definition.id.name}'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 10),
              title: Text(
                definition.label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                _progressLabel(
                  progress,
                  bridge:
                      progress.state == GermanCompetencyState.secure &&
                          bridge.isPending
                      ? bridge
                      : null,
                ),
              ),
              trailing: Chip(label: Text(coverage.label)),
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(definition.description),
                ),
                if (definition.prerequisites.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Baut auf ${definition.prerequisites.length} vorherigen Lernschritt(en) auf.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    ),
  );
}

String _progressLabel(
  GermanCompetencyProgress progress, {
  GermanGradeBridgeStatus? bridge,
}) {
  if (progress.attempts == 0) return 'Noch keine Lernbeobachtung';
  if (bridge != null) {
    final source = bridge.sourceGrade?.label ?? 'früherer Klasse';
    return 'Klassenstufe bestätigen · Grundlage aus $source sicher · '
        '${bridge.currentGrade.label} noch offen';
  }
  final overall = (progress.accuracy * 100).round();
  final recent = (progress.recentAccuracy * 100).round();
  final accuracy =
      progress.attempts <= progress.recentAttempts || recent == overall
      ? '$overall % direkt richtig'
      : 'aktuell $recent % · insgesamt $overall %';
  return '${progress.shortLabel} · $accuracy · ${progress.distinctTaskCount} verschiedene Aufgaben';
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      Text(label),
    ],
  );
}
