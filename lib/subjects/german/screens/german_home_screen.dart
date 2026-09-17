import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/grade_level.dart';
import '../../../core/learning_app_theme.dart';
import '../../../core/learning_subject.dart';
import '../../../services/app_controller.dart';
import '../german_competency_catalog.dart';
import '../german_learning_domain.dart';
import '../german_practice_planner.dart';
import '../german_progress.dart';
import '../german_session.dart';
import '../german_storage_service.dart';
import '../german_task.dart';
import 'german_training_screen.dart';

class GermanHomeScreen extends StatefulWidget {
  const GermanHomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<GermanHomeScreen> createState() => _GermanHomeScreenState();
}

class _GermanHomeScreenState extends State<GermanHomeScreen> {
  List<GermanSessionResult> _history = const <GermanSessionResult>[];
  bool _loading = true;

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
      _history = history;
      _loading = false;
    });
  }

  ThemeData get _germanTheme => LearningAppTheme.build(
    subject: LearningSubject.german,
    accessibility: widget.controller.accessibilityPreferences,
  );

  Future<void> _openRound(List<GermanTask> tasks) async {
    if (tasks.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: _germanTheme,
          child: GermanTrainingScreen(
            gradeLevel: widget.controller.gradeLevel,
            tasks: tasks,
            speak: widget.controller.speakOnDemand,
            onComplete: _saveResult,
          ),
        ),
      ),
    );
  }

  void _saveResult(GermanSessionResult result) {
    setState(() => _history = <GermanSessionResult>[result, ..._history]);
    unawaited(_storage.appendSession(result));
  }

  void _startDailyRound() {
    final tasks = GermanPracticePlanner.buildDailyRound(
      gradeLevel: widget.controller.gradeLevel,
      history: _history,
    );
    unawaited(_openRound(tasks));
  }

  void _startDomain(GermanLearningDomain domain) {
    final tasks = GermanPracticePlanner.buildDomainRound(
      gradeLevel: widget.controller.gradeLevel,
      domain: domain,
      history: _history,
    );
    unawaited(_openRound(tasks));
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: _germanTheme,
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Deutsch')),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(context),
        ),
      ),
    ),
  );

  Widget _buildContent(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: <Widget>[
      Text(
        'Hallo ${widget.controller.activeProfileName}',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 6),
      Text(
        '${widget.controller.gradeLevel.label} · Deutsch',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Meine Deutsch-Runde',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_roundSummary()),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('german-daily-round'),
                onPressed: _startDailyRound,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Runde starten'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('Lernbereiche', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      ...GermanLearningDomain.values.map(
        (domain) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              key: ValueKey('german-domain-${domain.name}'),
              leading: Icon(_iconFor(domain)),
              title: Text(domain.label),
              subtitle: Text(_domainSummary(domain)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _startDomain(domain),
            ),
          ),
        ),
      ),
      if (_history.isNotEmpty) ...<Widget>[
        const SizedBox(height: 14),
        Text('Zuletzt', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        _LastGermanRoundCard(result: _history.first),
      ],
    ],
  );

  String _roundSummary() {
    if (_history.isEmpty) {
      return 'Kurze Aufgaben aus Lesen, Sprache, Schreiben und Hören.';
    }
    final weakest = _weakestProgress();
    if (weakest == null) return 'Heute werden neue Lernschritte entdeckt.';
    final label = GermanCompetencyCatalog.definition(
      weakest.competencyId,
    ).label;
    return 'Heute bekommt „$label“ etwas mehr Übungszeit.';
  }

  GermanCompetencyProgress? _weakestProgress() {
    final practiced =
        GermanCompetencyCatalog.recommendedFor(widget.controller.gradeLevel)
            .map(
              (definition) =>
                  GermanProgressAnalyzer.forCompetency(definition.id, _history),
            )
            .where((progress) => progress.attempts > 0)
            .toList();
    if (practiced.isEmpty) return null;
    practiced.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return practiced.first;
  }

  String _domainSummary(GermanLearningDomain domain) {
    final definitions = GermanCompetencyCatalog.forDomain(
      domain,
      widget.controller.gradeLevel,
    );
    final practiced = definitions
        .map(
          (definition) =>
              GermanProgressAnalyzer.forCompetency(definition.id, _history),
        )
        .toList();
    final secure = practiced
        .where((progress) => progress.state == GermanCompetencyState.secure)
        .length;
    final attempts = practiced.fold<int>(
      0,
      (sum, value) => sum + value.attempts,
    );
    if (attempts == 0) return 'Noch nicht geübt';
    return '$secure von ${definitions.length} Lernschritten sicher';
  }

  IconData _iconFor(GermanLearningDomain domain) => switch (domain) {
    GermanLearningDomain.reading => Icons.menu_book_rounded,
    GermanLearningDomain.spelling => Icons.spellcheck_rounded,
    GermanLearningDomain.language => Icons.translate_rounded,
    GermanLearningDomain.vocabulary => Icons.abc_rounded,
    GermanLearningDomain.listening => Icons.hearing_rounded,
    GermanLearningDomain.writing => Icons.edit_rounded,
  };
}

class _LastGermanRoundCard extends StatelessWidget {
  const _LastGermanRoundCard({required this.result});

  final GermanSessionResult result;

  @override
  Widget build(BuildContext context) {
    final percent = (result.accuracy * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            const Icon(Icons.check_circle_outline_rounded, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${result.correctFirstTry} von ${result.total} direkt richtig',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('$percent % beim ersten Versuch'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
