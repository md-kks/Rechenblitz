import 'dart:async';

import 'package:flutter/material.dart';

import '../core/learning_subject.dart';
import '../core/widgets/learning_subject_switcher.dart';
import '../models/error_diagnosis.dart';
import '../models/support_session_progress.dart';
import '../models/training.dart';
import '../models/training_session_progress.dart';
import '../services/app_controller.dart';
import '../subjects/german/screens/german_home_screen.dart';
import 'assessment_screen.dart';
import 'assignment_scanner_screen.dart';
import 'competency_map_screen.dart';
import 'curriculum_training_screen.dart';
import 'my_round_screen.dart';
import 'parent_screen.dart';
import 'remediation_screen.dart';
import 'reward_screen.dart';
import 'settings_screen.dart';
import 'step_recovery_screen.dart';
import 'structured_training_screen.dart';
import 'training_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    this.showSubjectSwitcher = false,
  });

  final AppController controller;
  final bool showSubjectSwitcher;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _parentGateTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _parentGateTimer?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _startParentGate({BuildContext? sheetContext}) {
    _parentGateTimer?.cancel();
    _parentGateTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _parentGateTimer = null;
      unawaited(_openParentArea(sheetContext));
    });
  }

  Future<void> _openParentArea(BuildContext? sheetContext) async {
    if (!mounted) return;
    if (sheetContext != null && Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
      await Future<void>.delayed(Duration.zero);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentScreen(controller: widget.controller),
      ),
    );
  }

  void _cancelParentGate() {
    _parentGateTimer?.cancel();
    _parentGateTimer = null;
  }

  Future<void> _showMoreMenu() async {
    _cancelParentGate();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    'Mehr',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                ListTile(
                  key: const ValueKey('more-school-assignment'),
                  leading: const Icon(Icons.qr_code_scanner_rounded),
                  title: const Text('Schulauftrag'),
                  subtitle: const Text('QR-Code der Lehrkraft öffnen'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AssignmentScannerScreen(
                          controller: widget.controller,
                        ),
                      ),
                    );
                  },
                ),
                if (widget.showSubjectSwitcher)
                  ListTile(
                    key: const ValueKey('more-german'),
                    leading: const Icon(Icons.menu_book_rounded),
                    title: const Text('Deutsch'),
                    subtitle: const Text('Lesen, Schreiben, Sprache und Hören'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GermanHomeScreen(
                            controller: widget.controller,
                            showSubjectSwitcher: true,
                          ),
                        ),
                      );
                    },
                  ),
                ListTile(
                  key: const ValueKey('more-settings'),
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('Einstellungen'),
                  subtitle: const Text('Profil, Rechenwege und Darstellung'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SettingsScreen(controller: widget.controller),
                      ),
                    );
                  },
                ),
                Listener(
                  key: const ValueKey('parent-gate'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) =>
                      _startParentGate(sheetContext: sheetContext),
                  onPointerUp: (_) => _cancelParentGate(),
                  onPointerCancel: (_) => _cancelParentGate(),
                  child: Semantics(
                    button: true,
                    label: 'Elternbereich – 2 Sekunden gedrückt halten',
                    child: const ListTile(
                      leading: Icon(Icons.lock_outline_rounded),
                      title: Text('Elternbereich'),
                      subtitle: Text('2 Sekunden gedrückt halten'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _cancelParentGate();
  }

  CoreTrainingSessionProgress? _resumableCoreDraft() {
    final draft = widget.controller.coreTrainingSessionProgress;
    if (draft == null) return null;
    return widget.controller.resumableCoreTrainingSession(
      kind: draft.kind,
      mode: draft.mode,
      targetTasks: draft.targetTasks,
      targetCompetency: draft.targetCompetency,
      reviewEmphasis: draft.reviewEmphasis,
      transferEmphasis: draft.transferEmphasis,
      fluencyEmphasis: draft.fluencyEmphasis,
      scaffoldFading: draft.scaffoldFading,
      adaptiveLength: draft.adaptiveLength,
      timeLimit: draft.timeLimitMs == null
          ? null
          : Duration(milliseconds: draft.timeLimitMs!),
    );
  }

  RemediationSessionProgress? _resumableRemediationDraft() {
    final draft = widget.controller.remediationSessionProgress;
    if (draft == null ||
        widget.controller.remediationReviewOnly(draft.pattern) !=
            draft.reviewOnly) {
      return null;
    }
    return widget.controller.resumableRemediationSession(
      pattern: draft.pattern,
      mode: draft.mode,
      reviewOnly: draft.reviewOnly,
    );
  }

  StepRecoverySessionProgress? _resumableStepRecoveryDraft() {
    final draft = widget.controller.stepRecoverySessionProgress;
    if (draft == null) return null;
    return widget.controller.resumableStepRecoverySession(draft.focus);
  }

  _ResumeActivity? _standaloneResumeActivity() {
    final guidedRound = widget.controller.resumableGuidedRound();
    if (guidedRound != null && !guidedRound.isComplete) return null;

    final candidates = <_ResumeActivity>[];
    final assessment = widget.controller.resumableAssessment();
    if (assessment != null) {
      candidates.add(
        _ResumeActivity(
          kind: _ResumeKind.assessment,
          updatedAt: assessment.updatedAt,
          title: 'Lerncheck fortsetzen',
          subtitle:
              '${assessment.nextIndex} von ${assessment.tasks.length} Aufgaben beantwortet',
          payload: assessment,
        ),
      );
    }

    final core = _resumableCoreDraft();
    if (core != null) {
      final nextTask = core.completed >= core.targetTasks
          ? core.targetTasks
          : core.completed + 1;
      candidates.add(
        _ResumeActivity(
          kind: _ResumeKind.core,
          updatedAt: core.updatedAt,
          title: '${core.mode.title} fortsetzen',
          subtitle: core.taskResolved && core.completed >= core.targetTasks
              ? 'Letzte Aufgabe gelöst · Abschluss anzeigen'
              : 'Aufgabe $nextTask von ${core.targetTasks}',
          payload: core,
        ),
      );
    }

    final remediation = _resumableRemediationDraft();
    if (remediation != null) {
      final pendingFinish = remediation.index >= remediation.tasks.length;
      candidates.add(
        _ResumeActivity(
          kind: _ResumeKind.remediation,
          updatedAt: remediation.updatedAt,
          title: remediation.reviewOnly
              ? 'Kurze Wiederholung fortsetzen'
              : 'Knacknuss fortsetzen',
          subtitle: pendingFinish
              ? '${remediation.pattern.label} · Abschluss anzeigen'
              : '${remediation.pattern.label} · Aufgabe ${remediation.index + 1} von ${remediation.tasks.length}',
          payload: remediation,
        ),
      );
    }

    final recovery = _resumableStepRecoveryDraft();
    if (recovery != null) {
      final pendingFinish = recovery.index >= recovery.tasks.length;
      candidates.add(
        _ResumeActivity(
          kind: _ResumeKind.stepRecovery,
          updatedAt: recovery.updatedAt,
          title: 'Kurz üben fortsetzen',
          subtitle: pendingFinish
              ? '${recovery.focus.label} · Abschluss anzeigen'
              : '${recovery.focus.label} · Aufgabe ${recovery.index + 1} von ${recovery.tasks.length}',
          payload: recovery,
        ),
      );
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return candidates.first;
  }

  Future<void> _resumeActivity(_ResumeActivity activity) async {
    final controller = widget.controller;
    switch (activity.kind) {
      case _ResumeKind.assessment:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssessmentScreen(controller: controller),
          ),
        );
      case _ResumeKind.core:
        await _openCoreDraft(activity.payload as CoreTrainingSessionProgress);
      case _ResumeKind.remediation:
        final draft = activity.payload as RemediationSessionProgress;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RemediationScreen(
              controller: controller,
              pattern: draft.pattern,
              preferredMode: draft.mode,
            ),
          ),
        );
      case _ResumeKind.stepRecovery:
        final draft = activity.payload as StepRecoverySessionProgress;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                StepRecoveryScreen(controller: controller, focus: draft.focus),
          ),
        );
    }
    if (mounted) setState(() {});
  }

  Future<void> _openCoreDraft(CoreTrainingSessionProgress draft) async {
    final controller = widget.controller;
    final route = switch (draft.kind) {
      CoreTrainingKind.fact => MaterialPageRoute<void>(
        builder: (_) => TrainingScreen(
          controller: controller,
          mode: draft.mode,
          targetTasks: draft.targetTasks,
          targetCompetency: draft.targetCompetency,
          reviewEmphasis: draft.reviewEmphasis,
          transferEmphasis: draft.transferEmphasis,
          fluencyEmphasis: draft.fluencyEmphasis,
          scaffoldFading: draft.scaffoldFading,
          adaptiveLength: draft.adaptiveLength,
          timeLimit: draft.timeLimitMs == null
              ? null
              : Duration(milliseconds: draft.timeLimitMs!),
        ),
      ),
      CoreTrainingKind.structured => MaterialPageRoute<void>(
        builder: (_) => StructuredTrainingScreen(
          controller: controller,
          mode: draft.mode,
          targetTasks: draft.targetTasks,
          targetCompetency: draft.targetCompetency,
          reviewEmphasis: draft.reviewEmphasis,
          transferEmphasis: draft.transferEmphasis,
          fluencyEmphasis: draft.fluencyEmphasis,
          scaffoldFading: draft.scaffoldFading,
          adaptiveLength: draft.adaptiveLength,
        ),
      ),
      CoreTrainingKind.curriculum => MaterialPageRoute<void>(
        builder: (_) => CurriculumTrainingScreen(
          controller: controller,
          mode: draft.mode,
          targetTasks: draft.targetTasks,
          targetCompetency: draft.targetCompetency,
          reviewEmphasis: draft.reviewEmphasis,
          transferEmphasis: draft.transferEmphasis,
          fluencyEmphasis: draft.fluencyEmphasis,
          scaffoldFading: draft.scaffoldFading,
          adaptiveLength: draft.adaptiveLength,
        ),
      ),
    };
    await Navigator.of(context).push(route);
  }

  Future<void> _openMode(TrainingMode mode) async {
    if (mode.isUpperPrimary) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CurriculumTrainingScreen(
            controller: widget.controller,
            mode: mode,
          ),
        ),
      );
      return;
    }

    if (mode.isStructured) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StructuredTrainingScreen(
            controller: widget.controller,
            mode: mode,
          ),
        ),
      );
      return;
    }

    if (mode == TrainingMode.tempo) {
      final config = await showModalBottomSheet<TempoConfig>(
        context: context,
        showDragHandle: true,
        builder: (_) => const _TempoConfigurator(),
      );
      if (!mounted || config == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrainingScreen(
            controller: widget.controller,
            mode: mode,
            targetTasks: config.tasks,
            timeLimit: config.duration,
          ),
        ),
      );
      return;
    }

    final target = mode == TrainingMode.blitz ? 5 : 10;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingScreen(
          controller: widget.controller,
          mode: mode,
          targetTasks: target,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final recommendation = controller.childRecommendationText();
    final guidedRound = controller.resumableGuidedRound();
    final resumeActivity = _standaloneResumeActivity();
    final roundButtonLabel = guidedRound == null
        ? 'Runde starten'
        : guidedRound.isComplete
        ? 'Heutige Runde ansehen'
        : 'Runde fortsetzen';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechenblitz'),
        actions: [
          IconButton(
            tooltip: 'Meine Erfolge',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RewardScreen(controller: controller),
              ),
            ),
            icon: const Icon(Icons.emoji_events_rounded),
          ),
          IconButton(
            key: const ValueKey('home-more'),
            tooltip: 'Mehr',
            onPressed: _showMoreMenu,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            Text(
              controller.activeProfileName == 'Lernprofil'
                  ? 'Hallo!'
                  : 'Hallo, ${controller.activeProfileName}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            if (widget.showSubjectSwitcher) ...<Widget>[
              LearningSubjectSwitcher(
                current: LearningSubject.mathematics,
                onMathematics: () {},
                onGerman: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GermanHomeScreen(
                      controller: controller,
                      showSubjectSwitcher: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (resumeActivity != null) ...[
              _ResumeCard(
                activity: resumeActivity,
                onResume: () => _resumeActivity(resumeActivity),
              ),
              const SizedBox(height: 14),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Deine Runde',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const Chip(label: Text('5–8 Min')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(recommendation),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('my-round-button'),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MyRoundScreen(controller: controller),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                      icon: Icon(
                        guidedRound?.isComplete == true
                            ? Icons.check_circle_outline_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(roundButtonLabel),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.flash_on_rounded,
                    label: '5 Blitzaufgaben',
                    onTap: () => _openMode(TrainingMode.blitz),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.route_rounded,
                    label: 'Lernlandkarte',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CompetencyMapScreen(controller: controller),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PracticeCatalog(controller: controller, onOpenMode: _openMode),
            if (controller.todayTasks > 0) ...[
              const SizedBox(height: 14),
              Text(
                'Heute schon ${controller.todayTasks} Aufgaben geschafft.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ResumeKind { assessment, core, remediation, stepRecovery }

class _ResumeActivity {
  const _ResumeActivity({
    required this.kind,
    required this.updatedAt,
    required this.title,
    required this.subtitle,
    required this.payload,
  });

  final _ResumeKind kind;
  final DateTime updatedAt;
  final String title;
  final String subtitle;
  final Object payload;

  IconData get icon => switch (kind) {
    _ResumeKind.assessment => Icons.route_rounded,
    _ResumeKind.core => Icons.play_circle_outline_rounded,
    _ResumeKind.remediation => Icons.psychology_alt_outlined,
    _ResumeKind.stepRecovery => Icons.build_circle_outlined,
  };
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.activity, required this.onResume});

  final _ResumeActivity activity;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('home-resume-card'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          final details = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                activity.icon,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activity.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
          final button = FilledButton(
            key: ValueKey('home-resume-${activity.kind.name}'),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 54)),
            onPressed: onResume,
            child: const Text('Weiter'),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 12), button],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 10),
              button,
            ],
          );
        },
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
}

class _PracticeCatalog extends StatelessWidget {
  const _PracticeCatalog({required this.controller, required this.onOpenMode});

  final AppController controller;
  final Future<void> Function(TrainingMode mode) onOpenMode;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: const ValueKey('more-practice-expansion'),
      leading: const Icon(Icons.grid_view_rounded),
      title: const Text('Mehr üben'),
      subtitle: const Text('Alle Lernbereiche anzeigen'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Schnell starten'),
            const SizedBox(height: 10),
            _LearningGrid(
              children: [
                _LearningTile(
                  icon: Icons.school_rounded,
                  title: 'Plus & Minus',
                  subtitle: 'adaptiv üben',
                  onTap: () => onOpenMode(TrainingMode.practice),
                ),
                _LearningTile(
                  icon: Icons.flash_on_rounded,
                  title: '5 Blitzaufgaben',
                  subtitle: 'kurze Runde',
                  onTap: () => onOpenMode(TrainingMode.blitz),
                ),
                _LearningTile(
                  icon: Icons.speed_rounded,
                  title: 'Schnell rechnen',
                  subtitle: 'Tempo trainieren',
                  onTap: () => onOpenMode(TrainingMode.speed),
                ),
                _LearningTile(
                  icon: Icons.fact_check_outlined,
                  title: 'Rechencheck',
                  subtitle: 'mit optionaler Zeit',
                  onTap: () => onOpenMode(TrainingMode.tempo),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Grundrechenarten'),
            const SizedBox(height: 10),
            _LearningGrid(
              children: [
                _LearningTile(
                  icon: Icons.remove_circle_outline_rounded,
                  title: 'Minus üben',
                  subtitle: 'mit Hilfen',
                  onTap: () => onOpenMode(TrainingMode.minus),
                ),
                _LearningTile(
                  icon: Icons.close_rounded,
                  title: 'Malnehmen',
                  subtitle: 'Einmaleins aufbauen',
                  onTap: () => onOpenMode(TrainingMode.multiply),
                ),
                _LearningTile(
                  icon: Icons.horizontal_rule_rounded,
                  title: 'Teilen',
                  subtitle: 'Umkehraufgaben nutzen',
                  onTap: () => onOpenMode(TrainingMode.divide),
                ),
                _LearningTile(
                  icon: Icons.shuffle_rounded,
                  title: 'Gemischt',
                  subtitle: 'alle Grundrechenarten',
                  onTap: () => onOpenMode(TrainingMode.mixed),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Zahlen verstehen'),
            const SizedBox(height: 10),
            _LearningGrid(
              children: [
                _LearningTile(
                  icon: Icons.extension_rounded,
                  title: 'Zahlenfreunde',
                  subtitle: 'Zerlegen & ergänzen',
                  onTap: () => onOpenMode(TrainingMode.numberFriends),
                ),
                _LearningTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Nachbarzahlen',
                  subtitle: 'vorher & nachher',
                  onTap: () => onOpenMode(TrainingMode.neighbors),
                ),
                _LearningTile(
                  icon: Icons.view_column_rounded,
                  title: 'Zehner & Einer',
                  subtitle: 'Stellenwert verstehen',
                  onTap: () => onOpenMode(TrainingMode.placeValue),
                ),
                _LearningTile(
                  icon: Icons.balance_rounded,
                  title: 'Doppelt & Hälfte',
                  subtitle: 'Zahlbeziehungen',
                  onTap: () => onOpenMode(TrainingMode.doublesHalves),
                ),
                _LearningTile(
                  icon: Icons.trending_up_rounded,
                  title: 'Zahlenfolgen',
                  subtitle: 'Muster erkennen',
                  onTap: () => onOpenMode(TrainingMode.sequences),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Rechenwege'),
            const SizedBox(height: 10),
            _LearningGrid(
              children: [
                _LearningTile(
                  icon: Icons.account_balance_rounded,
                  title: 'Zahlenmauern',
                  subtitle: 'Steine ergänzen',
                  onTap: () => onOpenMode(TrainingMode.numberWall),
                ),
                _LearningTile(
                  icon: Icons.question_mark_rounded,
                  title: 'Lückenaufgaben',
                  subtitle: 'fehlende Zahl finden',
                  onTap: () => onOpenMode(TrainingMode.missingNumber),
                ),
                _LearningTile(
                  icon: Icons.family_restroom_rounded,
                  title: 'Rechenfamilien',
                  subtitle: 'Umkehraufgaben',
                  onTap: () => onOpenMode(TrainingMode.factFamilies),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Sachrechnen & Alltag'),
            const SizedBox(height: 10),
            _LearningGrid(
              children: [
                _LearningTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Sachaufgaben',
                  subtitle: 'Rechnen aus Geschichten',
                  onTap: () => onOpenMode(TrainingMode.wordProblems),
                ),
                _LearningTile(
                  icon: Icons.euro_rounded,
                  title: 'Geld',
                  subtitle: 'Euro, Cent & Rückgeld',
                  onTap: () => onOpenMode(TrainingMode.money),
                ),
                _LearningTile(
                  icon: Icons.schedule_rounded,
                  title: 'Uhrzeit',
                  subtitle: 'Uhren lesen',
                  onTap: () => onOpenMode(TrainingMode.clock),
                ),
                _LearningTile(
                  icon: Icons.straighten_rounded,
                  title: 'Längen & Größen',
                  subtitle: 'cm, dm & m',
                  onTap: () => onOpenMode(TrainingMode.measures),
                ),
                _LearningTile(
                  icon: Icons.category_rounded,
                  title: 'Geometrie',
                  subtitle: 'Formen, Seiten & Ecken',
                  onTap: () => onOpenMode(TrainingMode.geometry),
                ),
              ],
            ),
            if (controller.gradeLevel.index >= GradeLevel.third.index) ...[
              const SizedBox(height: 28),
              _SectionTitle(
                title: '${controller.gradeLevel.label} · Zahlen & Rechnen',
              ),
              const SizedBox(height: 10),
              _LearningGrid(
                children: [
                  _LearningTile(
                    icon: Icons.format_list_numbered_rounded,
                    title: 'Große Zahlen',
                    subtitle: 'Stellenwert & Orientierung',
                    onTap: () => onOpenMode(TrainingMode.largeNumbers),
                  ),
                  _LearningTile(
                    icon: Icons.adjust_rounded,
                    title: 'Runden',
                    subtitle: 'sinnvoll annähern',
                    onTap: () => onOpenMode(TrainingMode.rounding),
                  ),
                  _LearningTile(
                    icon: Icons.psychology_alt_rounded,
                    title: 'Halbschriftlich',
                    subtitle: 'geschickt zerlegen',
                    onTap: () => onOpenMode(TrainingMode.mentalStrategies),
                  ),
                  _LearningTile(
                    icon: Icons.add_box_outlined,
                    title: 'Schriftlich + / −',
                    subtitle: 'mit Überträgen',
                    onTap: () => onOpenMode(TrainingMode.writtenAddSub),
                  ),
                  _LearningTile(
                    icon: Icons.close_rounded,
                    title: 'Schriftlich mal',
                    subtitle: 'Stelle für Stelle',
                    onTap: () => onOpenMode(TrainingMode.writtenMultiply),
                  ),
                  _LearningTile(
                    icon: Icons.horizontal_rule_rounded,
                    title: 'Schriftlich teilen',
                    subtitle: 'mit Probe',
                    onTap: () => onOpenMode(TrainingMode.writtenDivide),
                  ),
                  _LearningTile(
                    icon: Icons.calculate_outlined,
                    title: 'Überschlag',
                    subtitle: 'Ergebnisse prüfen',
                    onTap: () => onOpenMode(TrainingMode.estimation),
                  ),
                  _LearningTile(
                    icon: Icons.lightbulb_circle_outlined,
                    title: 'Rechenvorteile',
                    subtitle: 'Gesetze nutzen',
                    onTap: () => onOpenMode(TrainingMode.arithmeticLaws),
                  ),
                  _LearningTile(
                    icon: Icons.history_edu_rounded,
                    title: 'Römische Zahlen',
                    subtitle: 'lesen & schreiben',
                    onTap: () => onOpenMode(TrainingMode.romanNumerals),
                  ),
                  _LearningTile(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'Bruchteile',
                    subtitle: '1/2, 1/4 und Größen',
                    onTap: () => onOpenMode(TrainingMode.fractions),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Größen, Zeit & Sachrechnen'),
              const SizedBox(height: 10),
              _LearningGrid(
                children: [
                  _LearningTile(
                    icon: Icons.straighten_rounded,
                    title: 'Größen umwandeln',
                    subtitle: 'Länge, Masse, Volumen',
                    onTap: () => onOpenMode(TrainingMode.advancedMeasures),
                  ),
                  _LearningTile(
                    icon: Icons.timer_outlined,
                    title: 'Zeitspannen',
                    subtitle: 'Dauer berechnen',
                    onTap: () => onOpenMode(TrainingMode.timeDurations),
                  ),
                  _LearningTile(
                    icon: Icons.swap_vert_circle_outlined,
                    title: 'Zuordnungen',
                    subtitle: 'proportional denken',
                    onTap: () => onOpenMode(TrainingMode.proportionality),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Geometrie & Raum'),
              const SizedBox(height: 10),
              _LearningGrid(
                children: [
                  _LearningTile(
                    icon: Icons.crop_square_rounded,
                    title: 'Umfang & Fläche',
                    subtitle: 'Rechtecke untersuchen',
                    onTap: () => onOpenMode(TrainingMode.perimeterArea),
                  ),
                  _LearningTile(
                    icon: Icons.architecture_rounded,
                    title: 'Geraden & Winkel',
                    subtitle: 'parallel, senkrecht & Kreis',
                    onTap: () => onOpenMode(TrainingMode.geometryRelations),
                  ),
                  _LearningTile(
                    icon: Icons.view_in_ar_rounded,
                    title: 'Körper & Netze',
                    subtitle: 'Ecken, Kanten, Flächen',
                    onTap: () => onOpenMode(TrainingMode.geometryBodies),
                  ),
                  _LearningTile(
                    icon: Icons.vertical_align_center_rounded,
                    title: 'Symmetrie',
                    subtitle: 'Achsen erkennen',
                    onTap: () => onOpenMode(TrainingMode.symmetry),
                  ),
                  _LearningTile(
                    icon: Icons.map_outlined,
                    title: 'Pläne & Wege',
                    subtitle: 'Orientierung & Maßstab',
                    onTap: () => onOpenMode(TrainingMode.plansAndOrientation),
                  ),
                  _LearningTile(
                    icon: Icons.grid_4x4_rounded,
                    title: 'Rauminhalt',
                    subtitle: 'mit Einheitswürfeln',
                    onTap: () => onOpenMode(TrainingMode.volumeCubes),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Daten, Muster & Zufall'),
              const SizedBox(height: 10),
              _LearningGrid(
                children: [
                  _LearningTile(
                    icon: Icons.bar_chart_rounded,
                    title: 'Daten & Diagramme',
                    subtitle: 'lesen & auswerten',
                    onTap: () => onOpenMode(TrainingMode.dataCharts),
                  ),
                  _LearningTile(
                    icon: Icons.casino_outlined,
                    title: 'Wahrscheinlichkeit',
                    subtitle: 'Chancen einschätzen',
                    onTap: () => onOpenMode(TrainingMode.probability),
                  ),
                  _LearningTile(
                    icon: Icons.account_tree_outlined,
                    title: 'Kombinatorik',
                    subtitle: 'Möglichkeiten finden',
                    onTap: () => onOpenMode(TrainingMode.combinatorics),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _LearningGrid extends StatelessWidget {
  const _LearningGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth >= 700 ? 3 : 2;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: count,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: constraints.maxWidth < 390 ? 1.08 : 1.25,
        children: children,
      );
    },
  );
}

class _LearningTile extends StatelessWidget {
  const _LearningTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

class TempoConfig {
  const TempoConfig(this.tasks, this.duration);
  final int tasks;
  final Duration? duration;
}

class _TempoConfigurator extends StatefulWidget {
  const _TempoConfigurator();

  @override
  State<_TempoConfigurator> createState() => _TempoConfiguratorState();
}

class _TempoConfiguratorState extends State<_TempoConfigurator> {
  int tasks = 20;
  int minutes = 2;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Rechencheck einstellen',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        const Text('Aufgaben'),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 10, label: Text('10')),
            ButtonSegment(value: 20, label: Text('20')),
            ButtonSegment(value: 30, label: Text('30')),
          ],
          selected: {tasks},
          onSelectionChanged: (values) => setState(() => tasks = values.first),
        ),
        const SizedBox(height: 18),
        const Text('Zeit'),
        DropdownButtonFormField<int>(
          initialValue: minutes,
          items: const [
            DropdownMenuItem(value: 1, child: Text('1 Minute')),
            DropdownMenuItem(value: 2, child: Text('2 Minuten')),
            DropdownMenuItem(value: 3, child: Text('3 Minuten')),
            DropdownMenuItem(value: 0, child: Text('Ohne festes Limit')),
          ],
          onChanged: (value) => setState(() => minutes = value ?? 2),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            TempoConfig(
              tasks,
              minutes == 0 ? null : Duration(minutes: minutes),
            ),
          ),
          child: const Text('Rechencheck starten'),
        ),
      ],
    ),
  );
}
