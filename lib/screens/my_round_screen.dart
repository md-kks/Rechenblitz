import 'dart:async';

import 'package:flutter/material.dart';

import '../models/error_diagnosis.dart';
import '../models/learning_path.dart';
import '../models/micro_competency.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import 'curriculum_training_screen.dart';
import 'remediation_screen.dart';
import 'structured_training_screen.dart';
import 'step_recovery_screen.dart';
import 'training_screen.dart';

class MyRoundScreen extends StatefulWidget {
  const MyRoundScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<MyRoundScreen> createState() => _MyRoundScreenState();
}

class _MyRoundScreenState extends State<MyRoundScreen> {
  late List<GuidedRoundSegment> plan;
  final Set<GuidedRoundRole> completedRoles = <GuidedRoundRole>{};
  final Map<GuidedRoundRole, int> completedTaskCounts =
      <GuidedRoundRole, int>{};
  bool stepRecoveryAttempted = false;
  bool stepRecoveryCompleted = false;
  bool deferEmergingRecovery = false;
  bool recoveryRequired = false;
  late DateTime roundStartedAt;
  late GuidedRoundDecisionTrace decisionTrace;
  GuidedRoundAdaptationKind? lastAdaptationKind;
  String? lastAdaptationMessage;
  bool completionSpeechTriggered = false;

  @override
  void initState() {
    super.initState();
    final restored = widget.controller.resumableGuidedRound();
    if (restored != null) {
      plan = List<GuidedRoundSegment>.from(restored.plan);
      completedRoles.addAll(restored.completedRoles);
      completedTaskCounts.addAll(restored.completedTaskCounts);
      stepRecoveryAttempted = restored.stepRecoveryAttempted;
      stepRecoveryCompleted = restored.stepRecoveryCompleted;
      deferEmergingRecovery = restored.deferEmergingRecovery;
      recoveryRequired = restored.recoveryRequired;
      roundStartedAt = restored.startedAt;
      decisionTrace = restored.decisionTrace.items.isEmpty
          ? widget.controller.guidedRoundDecisionTrace()
          : restored.decisionTrace;
      lastAdaptationKind = restored.lastAdaptationKind;
      lastAdaptationMessage = restored.lastAdaptationMessage;
      completionSpeechTriggered = restored.isComplete;
      if (recoveryRequired &&
          !stepRecoveryCompleted &&
          widget.controller.independentStepRecoveryFocus() == null) {
        recoveryRequired = false;
      }
    } else {
      roundStartedAt = DateTime.now();
      recoveryRequired =
          widget.controller.independentStepRecoveryFocus() != null;
      plan = widget.controller.buildMyRound();
      decisionTrace = widget.controller.guidedRoundDecisionTrace();
      lastAdaptationKind = null;
      lastAdaptationMessage = null;
    }
    unawaited(_persistRound());
  }

  GuidedRoundProgress _progressSnapshot() => GuidedRoundProgress(
        plan: List<GuidedRoundSegment>.from(plan),
        completedRoles: Set<GuidedRoundRole>.from(completedRoles),
        gradeLevel: widget.controller.gradeLevel,
        numberRange: widget.controller.numberRange,
        startedAt: roundStartedAt,
        updatedAt: DateTime.now(),
        recoveryRequired: recoveryRequired,
        stepRecoveryAttempted: stepRecoveryAttempted,
        stepRecoveryCompleted: stepRecoveryCompleted,
        deferEmergingRecovery: deferEmergingRecovery,
        decisionTrace: decisionTrace,
        lastAdaptationKind: lastAdaptationKind,
        lastAdaptationMessage: lastAdaptationMessage,
        completedTaskCounts:
            Map<GuidedRoundRole, int>.from(completedTaskCounts),
      );

  Future<void> _persistRound() =>
      widget.controller.saveGuidedRoundProgress(_progressSnapshot());

  Future<void> _start(int index) async {
    final segment = plan[index];
    final before = widget.controller.history.length;

    if (segment.mode.isUpperPrimary) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CurriculumTrainingScreen(
            controller: widget.controller,
            mode: segment.mode,
            targetTasks: segment.tasks,
            targetCompetency: segment.targetCompetency,
            reviewEmphasis: segment.reviewEmphasis,
            transferEmphasis: segment.transferEmphasis,
            fluencyEmphasis: segment.fluencyEmphasis,
            scaffoldFading: segment.scaffoldFading,
            adaptiveLength: true,
            announceCompletion: false,
          ),
        ),
      );
    } else if (segment.mode.isStructured) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StructuredTrainingScreen(
            controller: widget.controller,
            mode: segment.mode,
            targetTasks: segment.tasks,
            targetCompetency: segment.targetCompetency,
            reviewEmphasis: segment.reviewEmphasis,
            transferEmphasis: segment.transferEmphasis,
            fluencyEmphasis: segment.fluencyEmphasis,
            scaffoldFading: segment.scaffoldFading,
            adaptiveLength: true,
            announceCompletion: false,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrainingScreen(
            controller: widget.controller,
            mode: segment.mode,
            targetTasks: segment.tasks,
            targetCompetency: segment.targetCompetency,
            reviewEmphasis: segment.reviewEmphasis,
            transferEmphasis: segment.transferEmphasis,
            fluencyEmphasis: segment.fluencyEmphasis,
            scaffoldFading: segment.scaffoldFading,
            adaptiveLength: true,
            announceCompletion: false,
          ),
        ),
      );
    }

    if (!mounted) return;
    if (widget.controller.history.length > before) {
      final result = widget.controller.history.first;
      setState(() {
        completedRoles.add(segment.role);
        completedTaskCounts[segment.role] = result.total;
        if (result.endedAdaptively && result.total < segment.tasks) {
          plan[index] = segment.copyWith(
            tasks: result.total,
            reason:
                '${segment.reason} Dieser Teil endete adaptiv nach ${result.total} von ${result.plannedTotal ?? segment.tasks} geplanten Aufgaben.',
          );
        }
        final adaptation = widget.controller.adaptMyRoundAfterSegment(
          current: plan,
          completedRoles: completedRoles,
          completedTaskCounts: completedTaskCounts,
          completedSegment: segment,
          result: result,
        );
        plan = adaptation.plan;
        decisionTrace = widget.controller.guidedRoundDecisionTrace();
        lastAdaptationKind = adaptation.kind;
        lastAdaptationMessage = adaptation.message;

        final emergingRecovery =
            widget.controller.independentStepRecoveryFocus();
        if (!recoveryRequired &&
            !stepRecoveryAttempted &&
            emergingRecovery != null) {
          final completedTasks = plan
              .where(_isCompleted)
              .fold<int>(
                0,
                (sum, item) => sum + _completedTaskCountFor(item),
              );
          if (completedTasks > 9) {
            deferEmergingRecovery = true;
            lastAdaptationKind = GuidedRoundAdaptationKind.support;
            lastAdaptationMessage =
                'Ein unsicherer Zwischenschritt ist neu aufgefallen. Weil heute schon $completedTasks reguläre Aufgaben erledigt sind, wird die kurze Recovery in die nächste Runde verschoben statt die heutige Runde zu verlängern.';
          } else {
            recoveryRequired = true;
            _replanRemaining(compactForRecovery: true);
            lastAdaptationKind = GuidedRoundAdaptationKind.support;
            lastAdaptationMessage =
                'Ein unsicherer Zwischenschritt ist neu aufgefallen. Drei kurze Recovery-Aufgaben kommen jetzt zuerst; die übrige Runde wurde ausgeglichen verkürzt.';
          }
        }
      });
      await _persistRound();
      await _maybeSpeakOverallCompletion();
    }
  }

  void _replanRemaining({bool compactForRecovery = false}) {
    final updated = widget.controller.buildMyRound();
    plan = GuidedRoundOrchestrator.mergeRemaining(
      current: plan,
      updated: updated,
      completedRoles: completedRoles,
      completedTaskCounts: completedTaskCounts,
      regularTaskBudget: compactForRecovery ? 9 : null,
    );
    decisionTrace = widget.controller.guidedRoundDecisionTrace();
  }

  bool _isCompleted(GuidedRoundSegment segment) =>
      completedRoles.contains(segment.role);

  int _completedTaskCountFor(GuidedRoundSegment segment) =>
      completedTaskCounts[segment.role] ?? segment.tasks;

  bool get _roundIsComplete =>
      plan.every(_isCompleted) && (!recoveryRequired || stepRecoveryCompleted);

  List<String> get _completedCompetencyLabels => <String>{
        for (final segment in plan)
          if (_isCompleted(segment) && segment.targetCompetency != null)
            MicroCompetencyCatalog.definition(segment.targetCompetency!).label,
      }.toList(growable: false);

  String _overallSpokenFeedback() {
    final next = widget.controller.guidedRoundDecisionTrace().primary;
    final nextLabel = next?.competencyId == null
        ? null
        : MicroCompetencyCatalog.definition(next!.competencyId!).label;
    return widget.controller.guidedRoundSpokenFeedback(
      strengthenedCompetencies: _completedCompetencyLabels,
      nextCompetency: nextLabel,
    );
  }

  Future<void> _maybeSpeakOverallCompletion() async {
    if (completionSpeechTriggered || !_roundIsComplete) return;
    completionSpeechTriggered = true;
    await widget.controller.speakRoundFeedback(_overallSpokenFeedback());
  }

  @override
  Widget build(BuildContext context) {
    final unresolvedStepRecovery = widget.controller
        .independentStepRecoveryFocus();
    final stepRecovery =
        !recoveryRequired || stepRecoveryAttempted || deferEmergingRecovery
            ? null
            : unresolvedStepRecovery;
    final remediation = unresolvedStepRecovery == null
        ? widget.controller.remediationCandidate()
        : null;
    final reviewOnly = remediation == null
        ? false
        : widget.controller.remediationReviewOnly(remediation.pattern);
    final remediationFocus = remediation == null
        ? null
        : widget.controller.remediationTargetCompetency(remediation.pattern);
    final remediationLabel = remediationFocus == null
        ? remediation?.pattern.label
        : MicroCompetencyCatalog.definition(remediationFocus).label;
    final recoveryIncluded = recoveryRequired;
    final regularDoneTasks = plan
        .where(_isCompleted)
        .fold<int>(0, (sum, segment) => sum + _completedTaskCountFor(segment));
    final doneTasks = regularDoneTasks + (stepRecoveryCompleted ? 3 : 0);
    final regularTotalTasks = plan.fold<int>(
      0,
      (sum, segment) =>
          sum + (_isCompleted(segment) ? _completedTaskCountFor(segment) : segment.tasks),
    );
    final totalTasks = regularTotalTasks + (recoveryIncluded ? 3 : 0);
    final allDone =
        plan.every(_isCompleted) &&
        (!recoveryIncluded || stepRecoveryCompleted);

    int? nextIndex;
    for (var i = 0; i < plan.length; i++) {
      if (!_isCompleted(plan[i])) {
        nextIndex = i;
        break;
      }
    }
    final nextSegment = nextIndex == null ? null : plan[nextIndex];
    final completedCompetencyLabels = _completedCompetencyLabels;
    final completionDecisionTrace =
        allDone ? widget.controller.guidedRoundDecisionTrace() : decisionTrace;
    final nextDecision = allDone ? completionDecisionTrace.primary : null;
    final nextDecisionCompetency = nextDecision?.competencyId == null
        ? null
        : MicroCompetencyCatalog.definition(nextDecision!.competencyId!).label;
    final spokenRoundFeedback = allDone ? _overallSpokenFeedback() : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Runde')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone
                        ? 'Für heute geschafft.'
                        : 'Etwa 5–8 Minuten Mathe.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    allDone
                        ? 'Mehr ist heute nicht nötig.'
                        : '$doneTasks von $totalTasks Aufgaben',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: totalTasks == 0 ? 0 : doneTasks / totalTasks,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ],
              ),
            ),
          ),
          if (allDone) ...[
            const SizedBox(height: 12),
            Card(
              key: const ValueKey('round-learning-summary'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Das hast du heute gestärkt',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$doneTasks Aufgaben sind genug für heute. Rechenblitz hat Verstehen, Wiederholung, Anwendung und Automatisierung getrennt ausgewertet.',
                    ),
                    if (completedCompetencyLabels.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final label in completedCompetencyLabels)
                            Chip(label: Text(label)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      nextDecision == null
                          ? 'Die nächste Runde wird aus deinem aktuellen Lernstand neu geplant.'
                          : nextDecisionCompetency == null
                              ? 'Nächstes Mal plant Rechenblitz neu: ${nextDecision.kind.label}.'
                              : 'Nächstes Mal ist voraussichtlich „$nextDecisionCompetency“ dran: ${nextDecision.kind.label}.',
                      key: const ValueKey('round-next-learning-step'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (spokenRoundFeedback != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.record_voice_over_outlined, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              spokenRoundFeedback,
                              key: const ValueKey('guided-round-spoken-feedback'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      if (widget.controller.accessibilityPreferences.spokenRoundFeedback) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const ValueKey('guided-round-feedback-replay'),
                          onPressed: () => widget.controller
                              .speakRoundFeedback(spokenRoundFeedback),
                          icon: const Icon(Icons.volume_up_outlined),
                          label: const Text('Feedback nochmal anhören'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (lastAdaptationMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              key: const ValueKey('round-adaptation-card'),
              child: ListTile(
                leading: Icon(
                  lastAdaptationKind == GuidedRoundAdaptationKind.support
                      ? Icons.favorite_outline_rounded
                      : lastAdaptationKind == GuidedRoundAdaptationKind.confirmed
                          ? Icons.verified_outlined
                          : Icons.autorenew_rounded,
                ),
                title: Text(
                  lastAdaptationKind?.label ?? 'Plan aktualisiert',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(lastAdaptationMessage!),
              ),
            ),
          ],
          if (stepRecovery != null) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Kurz üben',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Wir schauen uns „${stepRecovery.label}“ in drei kurzen Aufgaben an.',
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const ValueKey('step-recovery-button'),
                      onPressed: () async {
                        final recoveryFinished = await Navigator.of(context)
                            .push<bool>(
                              MaterialPageRoute(
                                builder: (_) => StepRecoveryScreen(
                                  controller: widget.controller,
                                  focus: stepRecovery,
                                ),
                              ),
                            );
                        if (mounted && recoveryFinished == true) {
                          setState(() {
                            stepRecoveryAttempted = true;
                            stepRecoveryCompleted = true;
                          });
                          await _persistRound();
                          await _maybeSpeakOverallCompletion();
                        }
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Los geht’s'),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (remediation != null && remediation.modes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      reviewOnly ? 'Kurz nochmal' : 'Knacknuss',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reviewOnly
                          ? 'Zwei Aufgaben zeigen, ob „$remediationLabel“ schon sicher klappt.'
                          : 'Wir üben „$remediationLabel“ zuerst mit Hilfe.',
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const ValueKey('remediation-button'),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RemediationScreen(
                              controller: widget.controller,
                              pattern: remediation.pattern,
                              preferredMode: remediation.modes.first,
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(_replanRemaining);
                          await _persistRound();
                        }
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        reviewOnly ? '2 Aufgaben starten' : 'Knacknuss üben',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (!allDone && nextSegment != null && nextIndex != null) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Als Nächstes',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${nextSegment.role.label}: ${nextSegment.mode.title}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text('${nextSegment.tasks} Aufgaben'),
                    const SizedBox(height: 6),
                    Text(nextSegment.reason),
                    if (nextSegment.gradeBridge) ...[
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          key: ValueKey('round-grade-bridge-chip'),
                          avatar: Icon(Icons.school_rounded, size: 18),
                          label: Text('Brückenaufgaben in der neuen Klassenstufe'),
                        ),
                      ),
                    ] else if (nextSegment.rangeBridge) ...[
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: Icon(Icons.compare_arrows_rounded, size: 18),
                          label: Text('Brückenaufgaben im neuen Zahlenraum'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const ValueKey('round-next-button'),
                      onPressed: () => _start(nextIndex!),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(nextIndex == 0 ? 'Starten' : 'Weiter'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (plan.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: ExpansionTile(
                key: const ValueKey('round-plan-expansion'),
                leading: const Icon(Icons.format_list_numbered_rounded),
                title: const Text('Rundenplan'),
                subtitle: const Text('Alle Teile deiner Runde'),
                children: [
                  for (var index = 0; index < plan.length; index++)
                    ListTile(
                      leading: CircleAvatar(
                        child: _isCompleted(plan[index])
                            ? const Icon(Icons.check_rounded)
                            : Text('${index + 1}'),
                      ),
                      title: Text('${plan[index].role.label}: ${plan[index].mode.title}'),
                      subtitle: Text(
                        '${plan[index].tasks} Aufgaben${plan[index].isBridge ? ' · Brücke' : ''} · ${plan[index].reason}',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ExpansionTile(
                key: const ValueKey('round-decision-expansion'),
                leading: const Icon(Icons.rule_folder_outlined),
                title: const Text('Warum dieser Plan?'),
                subtitle: const Text('Prioritäten und zurückgestellte Alternativen'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(decisionTrace.summary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
