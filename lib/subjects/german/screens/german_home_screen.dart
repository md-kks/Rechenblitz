import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/german_state.dart';
import '../../../core/grade_level.dart';
import '../../../core/learning_app_theme.dart';
import '../../../core/learning_subject.dart';
import '../../../core/widgets/learning_subject_switcher.dart';
import '../../../screens/assignment_scanner_screen.dart';
import '../../../services/app_controller.dart';
import '../german_assessment.dart';
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
import 'german_assessment_result_screen.dart';
import 'german_assignment_result_screen.dart';
import 'german_competency_map_screen.dart';
import 'german_parent_overview_screen.dart';
import 'german_reward_screen.dart';
import 'german_training_screen.dart';

class GermanHomeScreen extends StatefulWidget {
  const GermanHomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<GermanHomeScreen> createState() => _GermanHomeScreenState();
}

class _GermanHomeScreenState extends State<GermanHomeScreen> {
  Timer? _parentGateTimer;
  List<GermanSessionResult> _history = const <GermanSessionResult>[];
  GermanRoundDraft? _draft;
  bool _introComplete = false;
  bool _loading = true;

  GermanStorageService get _storage =>
      GermanStorageService(profileId: widget.controller.activeProfileId);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _parentGateTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final history = await _storage.loadHistory();
    var draft = await _storage.loadRoundDraft();
    var introComplete = await _storage.loadIntroComplete();
    if (draft != null && !draft.isResumableFor(widget.controller.gradeLevel)) {
      await _storage.clearRoundDraft();
      draft = null;
    }
    if (!introComplete && (history.isNotEmpty || draft != null)) {
      introComplete = true;
      await _storage.setIntroComplete(true);
    }
    if (!mounted) return;
    setState(() {
      _history = history;
      _draft = draft;
      _introComplete = introComplete;
      _loading = false;
    });
  }

  ThemeData get _germanTheme => LearningAppTheme.build(
    subject: LearningSubject.german,
    accessibility: widget.controller.accessibilityPreferences,
  );

  void _startParentGate(BuildContext sheetContext) {
    _parentGateTimer?.cancel();
    _parentGateTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _parentGateTimer = null;
      unawaited(_openParentArea(sheetContext));
    });
  }

  void _cancelParentGate() {
    _parentGateTimer?.cancel();
    _parentGateTimer = null;
  }

  Future<void> _openParentArea(BuildContext sheetContext) async {
    if (Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
      await Future<void>.delayed(Duration.zero);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            GermanParentOverviewScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _showMoreMenu() async {
    _cancelParentGate();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                key: const ValueKey('german-more-school-assignment'),
                leading: const Icon(Icons.qr_code_scanner_rounded),
                title: const Text('Schulauftrag'),
                subtitle: const Text('Deutsch-Auftrag per QR-Code öffnen'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AssignmentScannerScreen(
                        controller: widget.controller,
                      ),
                    ),
                  );
                },
              ),
              Listener(
                key: const ValueKey('german-parent-gate'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _startParentGate(sheetContext),
                onPointerUp: (_) => _cancelParentGate(),
                onPointerCancel: (_) => _cancelParentGate(),
                child: Semantics(
                  button: true,
                  label: 'Elternbereich Deutsch – 2 Sekunden gedrückt halten',
                  child: ListTile(
                    leading: Icon(Icons.lock_outline_rounded),
                    title: Text('Elternbereich'),
                    subtitle: Text('Deutsch · 2 Sekunden gedrückt halten'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    _cancelParentGate();
  }

  Future<void> _openRewards() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: _germanTheme,
          child: GermanRewardScreen(
            gradeLevel: widget.controller.gradeLevel,
            history: _history,
          ),
        ),
      ),
    );
  }

  Future<void> _openRound(
    List<GermanTask> tasks, {
    GermanRoundDraft? draft,
    GermanSessionKind sessionKind = GermanSessionKind.practice,
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
          sessionKind: sessionKind,
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
            autoSpeak: widget.controller.speak,
            speakCompletion:
                widget.controller.accessibilityPreferences.spokenRoundFeedback,
            sessionKind: activeDraft.sessionKind,
            supportEnabled:
                activeDraft.sessionKind != GermanSessionKind.assessment,
            draft: activeDraft,
            onDraftChanged: _saveDraft,
            onComplete: _saveResult,
          ),
        ),
      ),
    );
    if (!mounted || session == null) return;

    if (session.kind == GermanSessionKind.assessment) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Theme(
            data: _germanTheme,
            child: GermanAssessmentResultScreen(
              summary: GermanAssessmentSummary.fromSession(session),
            ),
          ),
        ),
      );
      return;
    }

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
    await _openRound(tasks, draft: draft, sessionKind: draft.sessionKind);
  }

  Future<void> _completeIntro({required bool startAssessment}) async {
    await _storage.setIntroComplete(true);
    if (!mounted) return;
    setState(() => _introComplete = true);
    if (startAssessment) _startAssessment();
  }

  void _startAssessment() {
    if (_draft != null) return;
    final tasks = GermanAssessmentPlanner.buildRound(
      widget.controller.gradeLevel,
      history: _history,
    );
    unawaited(_openRound(tasks, sessionKind: GermanSessionKind.assessment));
  }

  GermanSessionResult? get _latestAssessment {
    for (final session in _history) {
      if (session.kind == GermanSessionKind.assessment) return session;
    }
    return null;
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
        appBar: AppBar(
          title: const Text('Deutsch'),
          actions: <Widget>[
            IconButton(
              key: const ValueKey('german-rewards'),
              tooltip: 'Meine Deutsch-Erfolge',
              onPressed: _loading ? null : () => unawaited(_openRewards()),
              icon: const Icon(Icons.emoji_events_rounded),
            ),
            IconButton(
              key: const ValueKey('german-more'),
              tooltip: 'Mehr',
              onPressed: _showMoreMenu,
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _introComplete
              ? _buildContent(context)
              : _buildIntro(context),
        ),
      ),
    ),
  );

  Widget _buildSubjectSwitcher() => LearningSubjectSwitcher(
    current: LearningSubject.german,
    onMathematics: () {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    },
    onGerman: () {},
  );

  Widget _buildIntro(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: <Widget>[
      _buildSubjectSwitcher(),
      const SizedBox(height: 24),
      Icon(
        Icons.auto_stories_rounded,
        size: 68,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 18),
      Text(
        'Willkommen bei Deutsch',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 10),
      Text(
        'Kurze Übungen passen sich an ${widget.controller.activeProfileName} an. Alles bleibt auf diesem Gerät.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Mit Lerncheck starten',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                '12 kurze Aufgaben zeigen, welche Lernbereiche schon sicher sind. Es gibt keine Note.',
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const ValueKey('german-intro-assessment'),
                onPressed: () =>
                    unawaited(_completeIntro(startAssessment: true)),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Lerncheck starten'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        key: const ValueKey('german-intro-skip'),
        onPressed: () => unawaited(_completeIntro(startAssessment: false)),
        child: const Text('Erst einmal ohne Lerncheck üben'),
      ),
    ],
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
        '${widget.controller.gradeLevel.label} · Deutsch · ${widget.controller.activeProfile.state.label}',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 12),
      _buildSubjectSwitcher(),
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
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Lerncheck', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(_assessmentSummaryText()),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('german-assessment-start'),
                onPressed: _draft == null ? _startAssessment : null,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Lerncheck starten'),
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
    final draft = _draft;
    if (draft != null) {
      final kind = switch (draft.sessionKind) {
        GermanSessionKind.practice => 'Deine angefangene Runde',
        GermanSessionKind.assessment => 'Dein angefangener Lerncheck',
        GermanSessionKind.teacherAssignment => 'Dein angefangener Schulauftrag',
      };
      return '$kind wartet: Aufgabe ${draft.nextTaskNumber} von ${draft.totalTasks}.';
    }
    if (_history.isEmpty) {
      return '12 kurze Aufgaben aus allen sechs Deutsch-Lernbereichen.';
    }
    final weakest = _weakestProgress();
    if (weakest == null) return 'Heute werden neue Lernschritte entdeckt.';
    final label = GermanCompetencyCatalog.definition(
      weakest.competencyId,
    ).label;
    return '12 Aufgaben für heute. „$label“ bekommt etwas mehr Übungszeit.';
  }

  String _assessmentSummaryText() {
    final latest = _latestAssessment;
    if (latest == null) {
      return 'Eine kurze Momentaufnahme über alle Deutsch-Lernbereiche – ohne Note.';
    }
    final percent = (latest.accuracy * 100).round();
    return 'Letzter Lerncheck: ${latest.correctFirstTry} von ${latest.total} direkt richtig · $percent %.';
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
    practiced.sort((a, b) {
      final recent = a.recentAccuracy.compareTo(b.recentAccuracy);
      return recent != 0 ? recent : a.accuracy.compareTo(b.accuracy);
    });
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
