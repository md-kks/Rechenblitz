import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/grade_level.dart';
import '../../../core/learning_app_theme.dart';
import '../../../core/learning_subject.dart';
import '../../../services/app_controller.dart';
import '../german_competency.dart';
import '../german_competency_catalog.dart';
import '../german_learning_domain.dart';
import '../german_practice_planner.dart';
import '../german_progress.dart';
import '../german_round_draft.dart';
import '../german_session.dart';
import '../german_storage_service.dart';
import '../german_teacher_assignment.dart';
import '../german_teacher_assignment_result.dart';
import '../german_task.dart';
import 'german_assignment_result_screen.dart';
import 'german_competency_map_screen.dart';
import 'german_training_screen.dart';

class GermanHomeScreen extends StatefulWidget {
  const GermanHomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<GermanHomeScreen> createState() => _GermanHomeScreenState();
}

class _GermanHomeScreenState extends State<GermanHomeScreen> {
  List<GermanSessionResult> _history = const <GermanSessionResult>[];
  GermanRoundDraft? _draft;
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
    var draft = await _storage.loadRoundDraft();
    if (draft != null && !draft.isResumableFor(widget.controller.gradeLevel)) {
      await _storage.clearRoundDraft();
      draft = null;
    }
    if (!mounted) return;
    setState(() {
      _history = history;
      _draft = draft;
      _loading = false;
    });
  }

  ThemeData get _germanTheme => LearningAppTheme.build(
    subject: LearningSubject.german,
    accessibility: widget.controller.accessibilityPreferences,
  );

  Future<void> _openRound(
    List<GermanTask> tasks, {
    GermanRoundDraft? draft,
  }) async {
    if (tasks.isEmpty) return;
    final activeDraft =
        draft ??
        GermanRoundDraft(
          gradeLevel: widget.controller.gradeLevel,
          taskIds: tasks.map((task) => task.id).toList(growable: false),
          currentIndex: 0,
          startedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedResults: const <GermanTaskResult>[],
        );
    await _storage.saveRoundDraft(activeDraft);
    if (!mounted) return;
    setState(() => _draft = activeDraft);

    final session = await Navigator.of(context).push<GermanSessionResult>(
      MaterialPageRoute<GermanSessionResult>(
        builder: (_) => Theme(
          data: _germanTheme,
          child: GermanTrainingScreen(
            gradeLevel: widget.controller.gradeLevel,
            tasks: tasks,
            speak: widget.controller.speakOnDemand,
            speakCompletion:
                widget.controller.accessibilityPreferences.spokenRoundFeedback,
            draft: activeDraft,
            onDraftChanged: _saveDraft,
            onComplete: _saveResult,
          ),
        ),
      ),
    );
    if (!mounted || session == null) return;

    final payload = activeDraft.assignmentPayload;
    if (payload != null) {
      final assignment = GermanTeacherAssignment.tryParse(payload);
      if (assignment != null) {
        final result = GermanTeacherAssignmentResult.fromSession(
          assignment: assignment,
          session: session,
        );
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Theme(
              data: _germanTheme,
              child: GermanAssignmentResultScreen(result: result),
            ),
          ),
        );
      }
    }
  }

  void _saveDraft(GermanRoundDraft draft) {
    if (mounted) setState(() => _draft = draft);
    unawaited(_storage.saveRoundDraft(draft));
  }

  void _saveResult(GermanSessionResult result) {
    setState(() {
      _history = <GermanSessionResult>[result, ..._history];
      _draft = null;
    });
    unawaited(_persistCompletedResult(result));
  }

  Future<void> _persistCompletedResult(GermanSessionResult result) async {
    await _storage.appendSession(result);
    await _storage.clearRoundDraft();
  }

  Future<void> _resumeRound() async {
    final draft = _draft;
    if (draft == null) return;
    final tasks = draft.resolveTasks();
    if (tasks == null) {
      await _storage.clearRoundDraft();
      if (mounted) setState(() => _draft = null);
      return;
    }
    await _openRound(tasks, draft: draft);
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

  void _openCompetencyMap() {
    unawaited(_selectCompetencyFromMap());
  }

  Future<void> _selectCompetencyFromMap() async {
    final competency = await Navigator.of(context).push<GermanCompetencyId>(
      MaterialPageRoute<GermanCompetencyId>(
        builder: (_) => Theme(
          data: _germanTheme,
          child: GermanCompetencyMapScreen(
            gradeLevel: widget.controller.gradeLevel,
            history: _history,
          ),
        ),
      ),
    );
    if (!mounted || competency == null) return;
    final tasks = GermanPracticePlanner.buildCompetencyRound(
      gradeLevel: widget.controller.gradeLevel,
      competencyId: competency,
      history: _history,
    );
    await _openRound(tasks);
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
                key: ValueKey(
                  _draft == null ? 'german-daily-round' : 'german-resume-round',
                ),
                onPressed: _draft == null ? _startDailyRound : _resumeRound,
                icon: Icon(
                  _draft == null
                      ? Icons.play_arrow_rounded
                      : Icons.restore_rounded,
                ),
                label: Text(
                  _draft == null ? 'Runde starten' : 'Runde fortsetzen',
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const ValueKey('german-competency-map'),
        onPressed: _openCompetencyMap,
        icon: const Icon(Icons.route_rounded),
        label: const Text('Lernlandkarte ansehen'),
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
    final draft = _draft;
    if (draft != null) {
      final kind = draft.assignmentPayload == null
          ? 'Deine angefangene Runde'
          : 'Dein angefangener Schulauftrag';
      return '$kind wartet: Aufgabe ${draft.nextTaskNumber} von ${draft.totalTasks}.';
    }
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
