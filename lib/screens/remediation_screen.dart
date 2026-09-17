import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import '../models/micro_competency.dart';
import '../models/remediation_path.dart';
import '../models/support_session_progress.dart';
import '../models/training.dart';
import '../models/touch_interaction.dart';
import '../services/app_controller.dart';
import '../widgets/learning_visual_aid.dart';
import '../widgets/number_answer_pad.dart';
import '../widgets/touch_answer_interaction.dart';

class RemediationScreen extends StatefulWidget {
  const RemediationScreen({
    super.key,
    required this.controller,
    required this.pattern,
    required this.preferredMode,
  });

  final AppController controller;
  final ErrorPattern pattern;
  final TrainingMode preferredMode;

  @override
  State<RemediationScreen> createState() => _RemediationScreenState();
}

class _RemediationScreenState extends State<RemediationScreen> {
  final ScrollController _scrollController = ScrollController();
  late final bool reviewOnly;
  late final RemediationPlan plan;
  int index = 0;
  int wrongOnCurrent = 0;
  int checkCorrect = 0;
  int checkTotal = 0;
  bool locked = false;
  bool submitting = false;
  bool firstAttemptRecorded = false;
  bool resumedFromDraft = false;
  bool finishing = false;
  bool showHint = false;
  bool useTouchInput = true;
  String feedback = '';

  RemediationTask get current => plan.tasks[index];

  TouchInteractionPlan? get _touchInteraction => TouchInteractionPlan.forTask(
    mode: current.mode,
    taskKey: current.sourceTaskKey,
    answer: current.answer,
    maxValue: current.maxAnswerValue,
    wallValues: current.wallValues,
    hiddenWallIndex: current.hiddenWallIndex,
    choices: current.choices,
    clockHour: current.clockHour,
    clockMinute: current.clockMinute,
    answerSuffix: current.answerSuffix,
    targetCompetency: current.effectiveTargetCompetency,
  );

  GuidedMethodGuide get _guide => GuidedMethodFactory.forTask(
    mode: current.mode,
    taskKey: current.sourceTaskKey,
    expected: current.answer,
    preferences: widget.controller.effectiveMethodPreferences,
    targetCompetency: current.effectiveTargetCompetency,
  );

  int get _currentHelpLevel => switch (current.stage) {
    RemediationStage.guided => HelpLevel.guided.value,
    RemediationStage.supported => HelpLevel.visual.value,
    RemediationStage.transfer || RemediationStage.check =>
      showHint ? HelpLevel.nudge.value : HelpLevel.none.value,
  };

  @override
  void initState() {
    super.initState();
    reviewOnly = widget.controller.remediationReviewOnly(widget.pattern);
    final saved = widget.controller.resumableRemediationSession(
      pattern: widget.pattern,
      mode: widget.preferredMode,
      reviewOnly: reviewOnly,
    );
    final pendingFinish = saved != null && saved.index >= saved.tasks.length;
    if (saved != null) {
      plan = RemediationPlan(
        pattern: widget.pattern,
        mode: widget.preferredMode,
        tasks: saved.tasks,
      );
      index = pendingFinish ? saved.tasks.length - 1 : saved.index;
      wrongOnCurrent = saved.wrongOnCurrent;
      firstAttemptRecorded = saved.firstAttemptRecorded;
      checkCorrect = saved.checkCorrect;
      checkTotal = saved.checkTotal;
      showHint = saved.showHint;
      resumedFromDraft = true;
      locked = pendingFinish;
    } else {
      plan = RemediationGenerator().generate(
        pattern: widget.pattern,
        preferredMode: widget.preferredMode,
        grade: widget.controller.gradeLevel,
        range: widget.controller.numberRange,
        methods: widget.controller.effectiveMethodPreferences,
        reviewOnly: reviewOnly,
      );
      unawaited(_persistSession());
    }
    _scheduleCurrentTask();
    if (saved == null) {
      unawaited(
        widget.controller.startRemediation(
          widget.pattern,
          reviewOnly: reviewOnly,
        ),
      );
    }
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

  RemediationSessionProgress _sessionSnapshot({
    int? indexOverride,
    int? wrongOnCurrentOverride,
    bool? firstAttemptRecordedOverride,
    bool? showHintOverride,
  }) => RemediationSessionProgress(
    pattern: widget.pattern,
    mode: widget.preferredMode,
    gradeLevel: widget.controller.gradeLevel,
    numberRange: widget.controller.numberRange,
    reviewOnly: reviewOnly,
    tasks: plan.tasks,
    index: indexOverride ?? index,
    wrongOnCurrent: wrongOnCurrentOverride ?? wrongOnCurrent,
    firstAttemptRecorded: firstAttemptRecordedOverride ?? firstAttemptRecorded,
    checkCorrect: checkCorrect,
    checkTotal: checkTotal,
    showHint: showHintOverride ?? showHint,
    updatedAt: DateTime.now(),
  );

  Future<void> _persistSession({
    int? indexOverride,
    int? wrongOnCurrentOverride,
    bool? firstAttemptRecordedOverride,
    bool? showHintOverride,
  }) => widget.controller.saveRemediationSession(
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

    try {
      if (!firstAttemptRecorded) {
        firstAttemptRecorded = true;
        await _persistSession();
        await widget.controller.recordDiagnosticAttempt(
          mode: answeredTask.mode,
          taskKey: answeredTask.taskKey,
          expected: answeredTask.answer,
          actual: answer,
          usedHelp: _currentHelpLevel > 0,
          helpLevel: _currentHelpLevel,
          methodKey: _guide.methodKey,
          source: MicroEvidenceSource.remediation,
        );
      }
    } catch (_) {
      if (mounted && index == answeredIndex) {
        setState(() => submitting = false);
      }
      rethrow;
    }

    if (!mounted || finishing || index != answeredIndex) return;

    if (answer != answeredTask.answer) {
      wrongOnCurrent += 1;
      setState(() {
        submitting = false;
        feedback = wrongOnCurrent == 1
            ? widget.pattern.firstResponseHint
            : 'Nutze den Hinweis und probiere es noch einmal.';
        showHint = true;
      });
      await _persistSession();
      return;
    }

    locked = true;
    if (current.stage == RemediationStage.check) {
      checkTotal += 1;
      if (wrongOnCurrent == 0) checkCorrect += 1;
    }

    if (widget.controller.hapticEnabled) HapticFeedback.lightImpact();
    if (widget.controller.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    setState(() {
      submitting = false;
      feedback = wrongOnCurrent == 0
          ? 'Richtig – der Rechenweg sitzt.'
          : 'Geschafft. Der richtige Weg ist jetzt klar.';
    });

    final nextIndex = index + 1;
    await _persistSession(
      indexOverride: nextIndex,
      wrongOnCurrentOverride: 0,
      firstAttemptRecordedOverride: false,
      showHintOverride: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 550));
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
      useTouchInput = true;
      feedback = '';
    });
    _scheduleCurrentTask(resetViewport: true);
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;
    final progress = await widget.controller.completeRemediation(
      widget.pattern,
      checkCorrect: checkCorrect,
      checkTotal: checkTotal,
      reviewOnly: reviewOnly,
    );
    await widget.controller.clearRemediationSession();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          progress.status == RemediationStatus.stable
              ? 'Geschafft!'
              : progress.status == RemediationStatus.improved
              ? 'Das wird sicherer'
              : 'Wir üben weiter',
        ),
        content: Text(
          '$checkCorrect von $checkTotal Aufgaben direkt richtig.\n\n'
          '${switch (progress.status) {
            RemediationStatus.stable => 'Das klappt jetzt sicher. Wir üben später wieder ganz normal weiter.',
            RemediationStatus.improved => 'Das hat schon besser geklappt. Wir schauen später noch einmal kurz danach.',
            RemediationStatus.recurring => 'Dieser Schritt braucht noch etwas Übung. Rechenblitz zeigt ihn dir später wieder.',
            RemediationStatus.inProgress => 'Wir machen beim nächsten Mal hier weiter.',
          }}',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
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
    final autoHint =
        stage == RemediationStage.guided || stage == RemediationStage.supported;

    return Scaffold(
      appBar: AppBar(
        title: Text(reviewOnly ? 'Kurze Kontrolle' : 'Knacknuss üben'),
      ),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('remediation-scroll'),
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
            const SizedBox(height: 6),
            Text(
              'Heute üben wir: ${widget.pattern.label}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Text(
              current.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                height: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (current.answerSuffix != null) ...[
              const SizedBox(height: 8),
              Text(
                'Antwort in ${current.answerSuffix}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 12),
            if (autoHint || showHint) ...[
              LearningVisualAid(
                pattern: widget.pattern,
                taskKey: current.sourceTaskKey,
                expected: current.answer,
                methodKey: _guide.methodKey,
              ),
              const SizedBox(height: 10),
              _HintCard(text: current.hint),
            ],
            if (!autoHint && !showHint && stage != RemediationStage.check)
              TextButton.icon(
                onPressed: _revealHint,
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: const Text('Hinweis anzeigen'),
              ),
            if (stage == RemediationStage.check && !showHint)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Probier diese Aufgabe zuerst ohne Hilfe.'),
                      ),
                    ],
                  ),
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
            if (useTouchInput && _touchInteraction != null) ...[
              TouchAnswerInteraction(
                key: ValueKey('remediation-touch:$index:${current.taskKey}'),
                plan: _touchInteraction!,
                locked: locked || submitting,
                onAnswer: _answer,
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                key: const ValueKey('remediation-touch-switch-classic'),
                onPressed: locked || submitting
                    ? null
                    : () => setState(() => useTouchInput = false),
                icon: Icon(
                  current.usesChoices
                      ? Icons.checklist_rounded
                      : Icons.dialpad_rounded,
                ),
                label: Text(
                  current.usesChoices ? 'Lieber auswählen' : 'Lieber eintippen',
                ),
              ),
            ] else if (current.usesChoices) ...[
              ...List.generate(
                current.choices!.length,
                (choiceIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.tonal(
                    onPressed: locked || submitting
                        ? null
                        : () => _answer(choiceIndex),
                    child: Text(
                      current.choices![choiceIndex],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              if (_touchInteraction != null)
                TextButton.icon(
                  key: const ValueKey('remediation-touch-switch-interaction'),
                  onPressed: locked || submitting
                      ? null
                      : () => setState(() => useTouchInput = true),
                  icon: const Icon(Icons.touch_app_rounded),
                  label: const Text('Mit Finger lösen'),
                ),
            ] else ...[
              NumberAnswerPad(
                key: ValueKey('remediation:$index:${current.taskKey}'),
                maxValue: current.maxAnswerValue,
                onAnswer: _answer,
              ),
              if (_touchInteraction != null)
                TextButton.icon(
                  key: const ValueKey('remediation-touch-switch-interaction'),
                  onPressed: locked || submitting
                      ? null
                      : () => setState(() => useTouchInput = true),
                  icon: const Icon(Icons.touch_app_rounded),
                  label: const Text('Mit Finger lösen'),
                ),
            ],
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

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.route_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}
