import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/guided_method.dart';
import '../models/remediation_path.dart';
import '../models/support_session_progress.dart';
import '../services/app_controller.dart';
import '../widgets/number_answer_pad.dart';

class StepRecoveryScreen extends StatefulWidget {
  const StepRecoveryScreen({
    super.key,
    required this.controller,
    required this.focus,
  });

  final AppController controller;
  final IndependentStepRecoveryFocus focus;

  @override
  State<StepRecoveryScreen> createState() => _StepRecoveryScreenState();
}

class _StepRecoveryScreenState extends State<StepRecoveryScreen> {
  final ScrollController _scrollController = ScrollController();
  late final StepRecoveryPlan plan;
  int index = 0;
  int wrongOnCurrent = 0;
  bool locked = false;
  bool submitting = false;
  bool firstAttemptRecorded = false;
  bool resumedFromDraft = false;
  bool finishing = false;
  bool showHint = false;
  String feedback = '';

  RemediationTask get current => plan.tasks[index];

  bool get _autoHint => current.stage == RemediationStage.supported;

  int get _helpLevel =>
      (_autoHint || showHint) ? HelpLevel.nudge.value : HelpLevel.none.value;

  @override
  void initState() {
    super.initState();
    final saved = widget.controller.resumableStepRecoverySession(widget.focus);
    final pendingFinish = saved != null && saved.index >= saved.tasks.length;
    if (saved != null) {
      plan = StepRecoveryPlan(focus: widget.focus, tasks: saved.tasks);
      index = pendingFinish ? saved.tasks.length - 1 : saved.index;
      wrongOnCurrent = saved.wrongOnCurrent;
      firstAttemptRecorded = saved.firstAttemptRecorded;
      showHint = saved.showHint;
      resumedFromDraft = true;
      locked = pendingFinish;
    } else {
      plan = StepRecoveryGenerator().generate(
        focus: widget.focus,
        range: widget.controller.numberRange,
      );
      unawaited(_persistSession());
    }
    _scheduleCurrentTask();
    if (pendingFinish) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_finish());
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleCurrentTask({bool resetViewport = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (resetViewport) _resetViewportToStart();
      unawaited(widget.controller.speak(current.prompt));
    });
  }

  void _resetViewportToStart() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
  }

  StepRecoverySessionProgress _sessionSnapshot({
    int? indexOverride,
    int? wrongOnCurrentOverride,
    bool? firstAttemptRecordedOverride,
    bool? showHintOverride,
  }) => StepRecoverySessionProgress(
    focus: widget.focus,
    numberRange: widget.controller.numberRange,
    tasks: plan.tasks,
    index: indexOverride ?? index,
    wrongOnCurrent: wrongOnCurrentOverride ?? wrongOnCurrent,
    firstAttemptRecorded: firstAttemptRecordedOverride ?? firstAttemptRecorded,
    showHint: showHintOverride ?? showHint,
    updatedAt: DateTime.now(),
  );

  Future<void> _persistSession({
    int? indexOverride,
    int? wrongOnCurrentOverride,
    bool? firstAttemptRecordedOverride,
    bool? showHintOverride,
  }) => widget.controller.saveStepRecoverySession(
    _sessionSnapshot(
      indexOverride: indexOverride,
      wrongOnCurrentOverride: wrongOnCurrentOverride,
      firstAttemptRecordedOverride: firstAttemptRecordedOverride,
      showHintOverride: showHintOverride,
    ),
  );

  void _revealHint() {
    if (showHint) return;
    setState(() => showHint = true);
    unawaited(_persistSession());
  }

  Future<void> _answer(int answer) async {
    if (locked || submitting || finishing) return;
    final answeredIndex = index;
    final answeredTask = current;
    setState(() => submitting = true);

    final correct = answer == answeredTask.answer;
    try {
      if (!firstAttemptRecorded) {
        firstAttemptRecorded = true;
        await _persistSession();
        await widget.controller.recordIndependentStepAttempt(
          mode: answeredTask.mode,
          taskKey: answeredTask.taskKey,
          stepKey: widget.focus.stepKey,
          competencyId: widget.focus.competencyId,
          correct: correct,
          usedHelp: _helpLevel > 0,
          helpLevel: _helpLevel,
          evidenceWeight: 0.35,
        );
      }
    } catch (_) {
      if (mounted && index == answeredIndex) {
        setState(() => submitting = false);
      }
      rethrow;
    }

    if (!mounted || finishing || index != answeredIndex) return;

    if (!correct) {
      wrongOnCurrent += 1;
      setState(() {
        submitting = false;
        showHint = true;
        feedback = wrongOnCurrent == 1
            ? 'Noch nicht. Prüfe genau diesen Rechenschritt.'
            : 'Nutze den Hinweis und probiere den Schritt noch einmal.';
      });
      await _persistSession();
      return;
    }

    locked = true;
    if (widget.controller.hapticEnabled) HapticFeedback.lightImpact();
    if (widget.controller.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    setState(() {
      submitting = false;
      feedback = wrongOnCurrent == 0
          ? 'Richtig. Dieser Rechenschritt stimmt.'
          : 'Geschafft. Jetzt ist der Rechenschritt klar.';
    });

    final nextIndex = index + 1;
    await _persistSession(
      indexOverride: nextIndex,
      wrongOnCurrentOverride: 0,
      firstAttemptRecordedOverride: false,
      showHintOverride: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || finishing) return;

    if (nextIndex >= plan.tasks.length) {
      await _finish();
      return;
    }

    setState(() {
      index = nextIndex;
      wrongOnCurrent = 0;
      firstAttemptRecorded = false;
      locked = false;
      showHint = false;
      feedback = '';
    });
    _scheduleCurrentTask(resetViewport: true);
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;

    final nextFocus = widget.controller.independentStepRecoveryFocus();
    final recovered =
        nextFocus == null ||
        nextFocus.competencyId != widget.focus.competencyId ||
        nextFocus.stepKey != widget.focus.stepKey;
    await widget.controller.clearStepRecoverySession();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(recovered ? 'Geschafft!' : 'Wir üben noch ein bisschen'),
        content: Text(
          recovered
              ? 'Dieser Rechenschritt klappt jetzt sicher. Weiter geht es mit deiner normalen Runde.'
              : 'Dieser Rechenschritt braucht noch etwas Übung. Rechenblitz zeigt ihn dir später wieder.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = current.stage;
    final progress = (index + 1) / plan.tasks.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Kurz üben')),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('step-recovery-scroll'),
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text(
              resumedFromDraft
                  ? 'Aufgabe ${index + 1} von ${plan.tasks.length} · fortgesetzt'
                  : 'Aufgabe ${index + 1} von ${plan.tasks.length}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            Text(
              _stageTitle(stage),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Text(
              widget.focus.label,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              current.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                height: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (_autoHint || showHint)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded),
                      const SizedBox(width: 10),
                      Expanded(child: Text(current.hint)),
                    ],
                  ),
                ),
              ),
            if (!_autoHint && !showHint && stage != RemediationStage.check)
              TextButton.icon(
                onPressed: _revealHint,
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: const Text('Hinweis anzeigen'),
              ),
            if (stage == RemediationStage.check && !showHint)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Probier diese Aufgabe zuerst ohne Hilfe.'),
                ),
              ),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  feedback,
                  key: ValueKey(feedback),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
            ] else
              const SizedBox(height: 6),
            if (current.usesChoices)
              ...List.generate(
                current.choices!.length,
                (choiceIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.tonal(
                    onPressed: locked || submitting
                        ? null
                        : () => _answer(choiceIndex),
                    child: Text(current.choices![choiceIndex]),
                  ),
                ),
              )
            else
              NumberAnswerPad(
                key: ValueKey('step-recovery:$index:${current.taskKey}'),
                maxValue: current.maxAnswerValue,
                onAnswer: _answer,
              ),
          ],
        ),
      ),
    );
  }

  String _stageTitle(RemediationStage stage) => switch (stage) {
    RemediationStage.guided => 'Wir lösen das zusammen',
    RemediationStage.supported => 'Ein Hinweis hilft dir',
    RemediationStage.transfer => 'Jetzt probierst du es selbst',
    RemediationStage.check => 'Ohne Hilfe probieren',
  };
}
