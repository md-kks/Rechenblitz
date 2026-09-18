import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/german_state.dart';
import '../../../core/grade_level.dart';
import '../../../core/learning_app_theme.dart';
import '../../../core/learning_subject.dart';
import '../../../services/app_controller.dart';
import '../german_assessment.dart';
import '../german_competency_catalog.dart';
import '../german_grade_bridge.dart';
import '../german_learning_domain.dart';
import '../german_parent_overview.dart';
import '../german_progress.dart';
import '../german_storage_service.dart';
import 'german_curriculum_audit_screen.dart';
import 'german_teacher_mode_screen.dart';

class GermanParentOverviewScreen extends StatefulWidget {
  const GermanParentOverviewScreen({
    super.key,
    required this.controller,
    this.now = DateTime.now,
  });

  final AppController controller;
  final DateTime Function() now;

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
        now: widget.now(),
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
        appBar: AppBar(title: const Text('Elternbereich · Deutsch')),
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
    final accuracyText = overview.totalTasks == 0 ? '–' : '$percent %';
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
      children: <Widget>[
        Text(
          widget.controller.activeProfileName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '${overview.gradeLevel.label} · Deutsch · ${widget.controller.activeProfile.state.label}',
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
                _Metric('Lernchecks', '${overview.assessmentCount}'),
                _Metric('Aufgaben', '${overview.totalTasks}'),
                _Metric('direkt richtig', accuracyText),
                _Metric(
                  'Lernschritte sicher',
                  '${overview.secureCompetencies}/${overview.progress.length}',
                ),
              ],
            ),
          ),
        ),
        if (overview.latestAssessment != null) ...<Widget>[
          const SizedBox(height: 16),
          _AssessmentSnapshot(
            summary: GermanAssessmentSummary.fromSession(
              overview.latestAssessment!,
            ),
          ),
        ],
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
            emptyText: overview.progress.every((entry) => entry.attempts == 0)
                ? 'Nach den ersten Deutsch-Runden erscheinen hier Lernschritte.'
                : 'Aktuell zeigt sich keine geübte Kompetenz mit besonderem Übungsbedarf.',
          ),
        ),
        if (overview.gradeBridges.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _InsightSection(
            title: 'Klassenstufe bestätigen',
            icon: Icons.stairs_rounded,
            children: _gradeBridgeLines(overview.gradeBridges),
          ),
        ],
        if (overview.reviewDue.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _InsightSection(
            title: 'Wiederholung fällig',
            icon: Icons.refresh_rounded,
            children: _progressLines(
              overview.reviewDue,
              emptyText: 'Aktuell ist keine Wiederholung fällig.',
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('german-parent-teacher-assignment'),
          onPressed: () => unawaited(
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    GermanTeacherModeScreen(controller: widget.controller),
              ),
            ),
          ),
          icon: const Icon(Icons.qr_code_2_rounded),
          label: const Text('Deutsch-Lehrerauftrag erstellen'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey('german-curriculum-audit'),
          onPressed: () => unawaited(
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    GermanCurriculumAuditScreen(controller: widget.controller),
              ),
            ),
          ),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Deutsch-Lehrplan-Audit öffnen'),
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
                      : _domainSummary(domain),
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
              'Die Übersicht übernimmt sichere Grundlagen aus früheren Klassenstufen. Gibt es auf der aktuellen Stufe neue schwierigere Aufgaben zu derselben Kompetenz, wird die Grundlage kurz neu bestätigt. „Sicher“ verlangt mindestens drei verschiedene Aufgaben, verteilt über mindestens zwei Runden, insgesamt mindestens 80 % direkt richtige Antworten und in den letzten fünf Aufgaben mindestens 75 %. Die Anzeige ist eine Lernhilfe, keine Schulnote.',
            ),
          ),
        ),
      ],
    );
  }

  String _domainSummary(GermanDomainProgressSummary domain) {
    final parts = <String>[
      '${domain.secureCompetencies} von ${domain.totalCompetencies} Lernschritten sicher',
    ];
    if (domain.gradeBridgeCompetencies > 0) {
      parts.add('${domain.gradeBridgeCompetencies} Klassenstufen-Check');
    }
    if (domain.reviewDueCompetencies > 0) {
      parts.add('${domain.reviewDueCompetencies} Wiederholung fällig');
    }
    parts.add('${(domain.accuracy * 100).round()} % direkt richtig');
    return parts.join(' · ');
  }

  List<Widget> _gradeBridgeLines(
    List<GermanGradeBridgeStatus> entries,
  ) => entries
      .map((entry) {
        final definition = GermanCompetencyCatalog.definition(
          entry.competencyId,
        );
        final source = entry.sourceGrade?.label ?? 'einer früheren Klasse';
        final evidence = entry.currentGradeAttempts == 0
            ? 'noch keine aktuelle Bestätigung'
            : '${entry.currentGradeCorrectFirstTry}/${entry.currentGradeAttempts} aktuelle Aufgaben direkt richtig';
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
                  '${definition.label} · Grundlage aus $source sicher · $evidence',
                ),
              ),
            ],
          ),
        );
      })
      .toList(growable: false);

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
                    '${definition.label} · ${_progressAccuracyLabel(entry)} (${entry.attempts} Aufgaben)',
                  ),
                ),
              ],
            ),
          );
        })
        .toList(growable: false);
  }
}

String _progressAccuracyLabel(GermanCompetencyProgress progress) {
  final overall = (progress.accuracy * 100).round();
  final recent = (progress.recentAccuracy * 100).round();
  if (progress.attempts <= progress.recentAttempts || recent == overall) {
    return '$overall % direkt richtig';
  }
  return 'aktuell $recent % · insgesamt $overall % direkt richtig';
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

class _AssessmentSnapshot extends StatelessWidget {
  const _AssessmentSnapshot({required this.summary});

  final GermanAssessmentSummary summary;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Letzter Lerncheck',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            summary.solvedAfterRetry == 0
                ? '${summary.session.correctFirstTry} von ${summary.session.total} direkt richtig. Keine Note – eine Momentaufnahme für die nächste Übungsplanung.'
                : '${summary.session.correctFirstTry} von ${summary.session.total} direkt richtig; ${summary.solvedAfterRetry} ${summary.solvedAfterRetry == 1 ? 'Aufgabe' : 'Aufgaben'} nach weiteren Versuchen gelöst. Keine Note – eine Momentaufnahme für die nächste Übungsplanung.',
          ),
          if (summary.nextDomains.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Nächster Fokus: ${summary.nextDomains.map((entry) => entry.domain.label).join(' · ')}',
            ),
          ],
        ],
      ),
    ),
  );
}
