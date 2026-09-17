import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/grade_level.dart';
import '../../../core/learning_app_theme.dart';
import '../../../core/learning_subject.dart';
import '../../../services/app_controller.dart';
import '../german_competency_catalog.dart';
import '../german_learning_domain.dart';
import '../german_parent_overview.dart';
import '../german_progress.dart';
import '../german_storage_service.dart';

class GermanParentOverviewScreen extends StatefulWidget {
  const GermanParentOverviewScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<GermanParentOverviewScreen> createState() =>
      _GermanParentOverviewScreenState();
}

class _GermanParentOverviewScreenState
    extends State<GermanParentOverviewScreen> {
  GermanParentOverview? _overview;

  GermanStorageService get _storage =>
      GermanStorageService(profileId: widget.controller.activeProfileId);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final history = await _storage.loadHistory();
    if (!mounted) return;
    setState(() {
      _overview = GermanParentOverview.analyze(
        gradeLevel: widget.controller.gradeLevel,
        history: history,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: LearningAppTheme.build(
      subject: LearningSubject.german,
      accessibility: widget.controller.accessibilityPreferences,
    ),
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Deutsch-Lernstand')),
        body: SafeArea(
          child: _overview == null
              ? const Center(child: CircularProgressIndicator())
              : _buildOverview(context, _overview!),
        ),
      ),
    ),
  );

  Widget _buildOverview(BuildContext context, GermanParentOverview overview) {
    final percent = (overview.accuracy * 100).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
      children: <Widget>[
        Text(
          widget.controller.activeProfileName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '${overview.gradeLevel.label} · Deutsch',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 28,
              runSpacing: 18,
              children: <Widget>[
                _Metric('Runden', '${overview.sessionCount}'),
                _Metric('Aufgaben', '${overview.totalTasks}'),
                _Metric('direkt richtig', '$percent %'),
                _Metric(
                  'Lernschritte sicher',
                  '${overview.secureCompetencies}/${overview.progress.length}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _InsightSection(
          title: 'Das klappt gut',
          icon: Icons.trending_up_rounded,
          children: _progressLines(
            overview.strengths,
            emptyText:
                'Noch nicht genug Übungsdaten für eine verlässliche Stärke.',
          ),
        ),
        const SizedBox(height: 12),
        _InsightSection(
          title: 'Hier lohnt sich Üben',
          icon: Icons.track_changes_rounded,
          children: _progressLines(
            overview.practiceNeeds,
            emptyText: overview.totalTasks == 0
                ? 'Nach den ersten Deutsch-Runden erscheinen hier Lernschritte.'
                : 'Aktuell zeigt sich keine geübte Kompetenz mit besonderem Übungsbedarf.',
          ),
        ),
        const SizedBox(height: 20),
        Text('Lernbereiche', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ...overview.domains.map(
          (domain) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.insights_rounded),
                title: Text(domain.domain.label),
                subtitle: Text(
                  domain.attempts == 0
                      ? 'Noch nicht geübt'
                      : '${domain.secureCompetencies} von ${domain.totalCompetencies} Lernschritten sicher · ${(domain.accuracy * 100).round()} % direkt richtig',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Die Übersicht bewertet nur Aufgaben dieser Klassenstufe und dieses Lernprofils. „Sicher“ bedeutet mindestens drei Versuche mit mindestens 80 % direkt richtigen Antworten. Die Anzeige ist eine Lernhilfe, keine Schulnote.',
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _progressLines(
    List<GermanCompetencyProgress> entries, {
    required String emptyText,
  }) {
    if (entries.isEmpty) return <Widget>[Text(emptyText)];
    return entries
        .map((entry) {
          final definition = GermanCompetencyCatalog.definition(
            entry.competencyId,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.circle, size: 8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${definition.label} · ${(entry.accuracy * 100).round()} % direkt richtig (${entry.attempts} Aufgaben)',
                  ),
                ),
              ],
            ),
          );
        })
        .toList(growable: false);
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
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
  Widget build(BuildContext context) => SizedBox(
    width: 125,
    child: Column(
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
    ),
  );
}
