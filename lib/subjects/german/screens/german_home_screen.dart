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
import '../german_grade_bridge.dart';
import '../german_history_scope.dart';
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
  const GermanHomeScreen({
    super.key,
    required this.controller,
    this.now = DateTime.now,
  });

  final AppController controller;
  final DateTime Function() now;

  @override
  State<GermanHomeScreen> createState() => _GermanHomeScreenState();
}

class _GermanHomeScreenState extends State<GermanHomeScreen> {
  Timer? _parentGateTimer;
  List<GermanSessionResult> _history = const <GermanSessionResult>[];
  GermanRoundDraft? _draft;
  bool _introComplete = false;
  bool _loading = true;
  late String _observedProfileId;
  late GradeLevel _observedGradeLevel;

  GermanStorageService get _storage =>
      GermanStorageService(profileId: widget.controller.activeProfileId);

  List<GermanSessionResult> get _gradeHistory =>
      GermanHistoryScope.throughGrade(_history, widget.controller.gradeLevel);

  @override
  void initState() {
    super.initState();
    _observedProfileId = widget.controller.activeProfileId;
    _observedGradeLevel = widget.controller.gradeLevel;
    widget.controller.addListener(_handleControllerChange);
    unawaited(_load());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _parentGateTimer?.cancel();
    super.dispose();
  }

  void _handleControllerChange() {
    if (!mounted) return;
    final profileId = widget.controller.activeProfileId;
    final gradeLevel = widget.controller.gradeLevel;
    if (profileId != _observedProfileId || gradeLevel != _observedGradeLevel) {
      _observedProfileId = profileId;
      _observedGradeLevel = gradeLevel;
      setState(() {
        _history = const <GermanSessionResult>[];
        _draft = null;
        _introComplete = false;
        _loading = true;
      });
      unawaited(_load());
      return;
    }
    setState(() {});
  }

  Future<void> _load() async {
    final profileId = widget.controller.activeProfileId;
    final gradeLevel = widget.controller.gradeLevel;
    final storage = GermanStorageService(profileId: profileId);
    final history = await storage.loadHistory();
    var draft = await storage.loadRoundDraft();
    var introComplete = await storage.loadIntroComplete();
    if (draft != null && !draft.isResumableFor(gradeLevel)) {
      await storage.clearRoundDraft();
      draft = null;
    }
    if (!introComplete && (history.isNotEmpty || draft != null)) {
      introComplete = true;
      await storage.setIntroComplete(true);
    }
    if (!mounted ||
        widget.controller.activeProfileId != profileId ||
        widget.controller.gradeLevel != gradeLevel) {
      return;
    }
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
        builder: (_) => GermanParentOverviewScreen(
          controller: widget.controller,
          now: widget.now,
        ),
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
    final roundProfileId = widget.controller.activeProfileId;
    final roundGradeLevel = widget.controller.gradeLevel;
    final roundStorage = GermanStorageService(profileId: roundProfileId);
    final activeDraft =
        draft ??
        GermanRoundDraft(
          gradeLevel: roundGradeLevel,
          taskIds: tasks.map((task) => task.id).toList(growable: false),
          currentIndex: 0,
          startedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedResults: const <GermanTaskResult>[],
          sessionKind: sessionKind,
        );
    await roundStorage.saveRoundDraft(activeDraft);
    if (!mounted ||
        widget.controller.activeProfileId != roundProfileId ||
        widget.controller.gradeLevel != roundGradeLevel) {
      return;
    }
    setState(() => _draft = activeDraft);

    final session = await Navigator.of(context).push<GermanSessionResult>(
      MaterialPageRoute<GermanSessionResult>(
        builder: (_) => Theme(
          data: _germanTheme,
          child: GermanTrainingScreen(
            gradeLevel: roundGradeLevel,
            tasks: tasks,
            speak: widget.controller.speakOnDemand,
            autoSpeak: widget.controller.speakOnDemand,
            readAloudEnabled:
                widget.controller.accessibilityPreferences.readAloud,
            speakCompletion:
                widget.controller.accessibilityPreferences.spokenRoundFeedback,
            sessionKind: activeDraft.sessionKind,
            supportEnabled:
                activeDraft.sessionKind != GermanSessionKind.assessment,
            draft: activeDraft,
            onDraftChanged: (value) =>
                _saveDraft(value, profileId: roundProfileId),
            onComplete: (value) =>
                _saveResult(value, profileId: roundProfileId),
          ),
        ),
      ),
    );
    if (!mounted || session == null) return;
    if (widget.controller.activeProfileId != roundProfileId ||
        widget.controller.gradeLevel != roundGradeLevel) {
      return;
    }

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

  void _saveDraft(GermanRoundDraft draft, {required String profileId}) {
    if (mounted &&
        widget.controller.activeProfileId == profileId &&
        widget.controller.gradeLevel == draft.gradeLevel) {
      setState(() => _draft = draft);
    }
    unawaited(GermanStorageService(profileId: profileId).saveRoundDraft(draft));
  }

  void _saveResult(GermanSessionResult result, {required String profileId}) {
    if (mounted &&
        widget.controller.activeProfileId == profileId &&
        widget.controller.gradeLevel == result.gradeLevel) {
      setState(() {
        _history = GermanHistoryScope.unique(<GermanSessionResult>[
          result,
          ..._history,
        ]);
        _draft = null;
      });
    }
    unawaited(_persistCompletedResult(result, profileId: profileId));
  }

  Future<void> _persistCompletedResult(
    GermanSessionResult result, {
    required String profileId,
  }) async {
    final storage = GermanStorageService(profileId: profileId);
    await storage.appendSession(result);
    await storage.clearRoundDraft();
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
      history: _gradeHistory,
    );
    unawaited(_openRound(tasks, sessionKind: GermanSessionKind.assessment));
  }

  GermanSessionResult? get _latestAssessment {
    for (final session in _history) {
      if (session.kind == GermanSessionKind.assessment &&
          session.gradeLevel == widget.controller.gradeLevel) {
        return session;
      }
    }
    return null;
  }

  void _startDailyRound() {
    final tasks = GermanPracticePlanner.buildDailyRound(
      gradeLevel: widget.controller.gradeLevel,
      history: _gradeHistory,
      now: widget.now(),
    );
    unawaited(_openRound(tasks));
  }

  void _startDomain(GermanLearningDomain domain) {
    final tasks = GermanPracticePlanner.buildDomainRound(
      gradeLevel: widget.controller.gradeLevel,
      domain: domain,
      history: _gradeHistory,
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
            history: _gradeHistory,
            referenceNow: widget.now(),
          ),
        ),
      ),
    );
    if (!mounted || competency == null) return;
    final gradeHistory = _gradeHistory;
    final progress = GermanProgressAnalyzer.forCompetency(
      competency,
      gradeHistory,
    );
    final bridge = GermanGradeBridgeAnalyzer.forCompetency(
      competencyId: competency,
      currentGrade: widget.controller.gradeLevel,
      history: gradeHistory,
    );
    final tasks =
        progress.state == GermanCompetencyState.secure && bridge.isPending
        ? GermanPracticePlanner.buildGradeBridgeRound(
            gradeLevel: widget.controller.gradeLevel,
            competencyId: competency,
            history: gradeHistory,
            now: widget.now(),
          )
        : GermanPracticePlanner.buildCompetencyRound(
            gradeLevel: widget.controller.gradeLevel,
            competencyId: competency,
            history: gradeHistory,
            now: widget.now(),
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
      if (_gradeHistory.isNotEmpty) ...<Widget>[
        const SizedBox(height: 14),
        Text('Zuletzt', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        _LastGermanRoundCard(result: _gradeHistory.first),
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
    if (_gradeHistory.isEmpty) {
      return '12 kurze Aufgaben aus allen sechs Deutsch-Lernbereichen.';
    }
    final focus = _practiceFocus();
    if (focus == null) {
      return '12 Aufgaben für heute – ausgewogen aus allen sechs Lernbereichen.';
    }
    final label = GermanCompetencyCatalog.definition(
      focus.progress.competencyId,
    ).label;
    final bridge = focus.bridge;
    if (bridge != null) {
      return '12 Aufgaben für heute. „$label“ wird mit Aufgaben aus '
          '${bridge.currentGrade.label} kurz bestätigt.';
    }
    return switch (focus.progress.attention(now: widget.now())) {
      GermanPracticeAttention.needsPractice =>
        '12 Aufgaben für heute. „$label“ bekommt etwas mehr Übungszeit.',
      GermanPracticeAttention.reviewDue =>
        '12 Aufgaben für heute. „$label“ wird zur Auffrischung wiederholt.',
      GermanPracticeAttention.none =>
        '12 Aufgaben für heute – ausgewogen aus allen sechs Lernbereichen.',
    };
  }

  String _assessmentSummaryText() {
    final latest = _latestAssessment;
    if (latest == null) {
      return 'Eine kurze Momentaufnahme über alle Deutsch-Lernbereiche – ohne Note.';
    }
    final assisted = latest.readAloudAssistedAttempts;
    if (assisted == 0) {
      final percent = (latest.accuracy * 100).round();
      return 'Letzter Lerncheck: ${latest.correctFirstTry} von ${latest.total} direkt richtig · $percent %.';
    }
    if (latest.independentAttempts == 0) {
      return 'Letzter Lerncheck: ${latest.correctFirstTry} von ${latest.total} direkt richtig · '
          '$assisted mit Vorlesen · selbstständig noch keine Beobachtung.';
    }
    final percent = (latest.independentAccuracy * 100).round();
    return 'Letzter Lerncheck: ${latest.independentCorrectFirstTry} von '
        '${latest.independentAttempts} selbstständig direkt richtig · '
        '$assisted mit Vorlesen · $percent % selbstständig.';
  }

  _GermanPracticeFocus? _practiceFocus() {
    final now = widget.now();
    final gradeHistory = _gradeHistory;
    final focuses = <_GermanPracticeFocus>[];
    for (final definition in GermanCompetencyCatalog.recommendedFor(
      widget.controller.gradeLevel,
    )) {
      final progress = GermanProgressAnalyzer.forCompetency(
        definition.id,
        gradeHistory,
      );
      final attention = progress.attention(now: now);
      final bridge = GermanGradeBridgeAnalyzer.forCompetency(
        competencyId: definition.id,
        currentGrade: widget.controller.gradeLevel,
        history: gradeHistory,
      );
      if (attention == GermanPracticeAttention.needsPractice) {
        focuses.add(_GermanPracticeFocus(progress: progress, priority: 0));
      } else if (progress.state == GermanCompetencyState.secure &&
          bridge.isPending) {
        focuses.add(
          _GermanPracticeFocus(progress: progress, bridge: bridge, priority: 1),
        );
      } else if (attention == GermanPracticeAttention.reviewDue) {
        focuses.add(_GermanPracticeFocus(progress: progress, priority: 2));
      }
    }
    if (focuses.isEmpty) return null;
    focuses.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      if (priority != 0) return priority;
      final recent = a.progress.recentAccuracy.compareTo(
        b.progress.recentAccuracy,
      );
      return recent != 0
          ? recent
          : a.progress.accuracy.compareTo(b.progress.accuracy);
    });
    return focuses.first;
  }

  String _domainSummary(GermanLearningDomain domain) {
    final gradeHistory = _gradeHistory;
    final definitions = GermanCompetencyCatalog.forDomain(
      domain,
      widget.controller.gradeLevel,
    );
    final practiced = definitions
        .map(
          (definition) =>
              GermanProgressAnalyzer.forCompetency(definition.id, gradeHistory),
        )
        .toList();
    final progressById = {
      for (final progress in practiced) progress.competencyId: progress,
    };
    final bridgeIds = definitions
        .where((definition) {
          final progress = progressById[definition.id]!;
          if (progress.state != GermanCompetencyState.secure) return false;
          return GermanGradeBridgeAnalyzer.forCompetency(
            competencyId: definition.id,
            currentGrade: widget.controller.gradeLevel,
            history: gradeHistory,
          ).isPending;
        })
        .map((definition) => definition.id)
        .toSet();
    final secure = practiced
        .where(
          (progress) =>
              progress.state == GermanCompetencyState.secure &&
              !bridgeIds.contains(progress.competencyId),
        )
        .length;
    final reviewDue = practiced
        .where(
          (progress) =>
              !bridgeIds.contains(progress.competencyId) &&
              progress.attention(now: widget.now()) ==
                  GermanPracticeAttention.reviewDue,
        )
        .length;
    final attempts = practiced.fold<int>(
      0,
      (sum, value) => sum + value.attempts,
    );
    if (attempts == 0) return 'Noch nicht geübt';
    final parts = <String>[
      '$secure von ${definitions.length} Lernschritten sicher',
    ];
    if (bridgeIds.isNotEmpty) {
      parts.add('${bridgeIds.length} Klassenstufen-Check');
    }
    if (reviewDue > 0) parts.add('$reviewDue Wiederholung fällig');
    return parts.join(' · ');
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

class _GermanPracticeFocus {
  const _GermanPracticeFocus({
    required this.progress,
    required this.priority,
    this.bridge,
  });

  final GermanCompetencyProgress progress;
  final GermanGradeBridgeStatus? bridge;
  final int priority;
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
                  Text(
                    '${result.gradeLevel.label} · $percent % beim ersten Versuch',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
