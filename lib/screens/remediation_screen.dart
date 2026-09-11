import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import '../models/micro_competency.dart';
import '../models/remediation_path.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../widgets/learning_visual_aid.dart';
import '../widgets/number_answer_pad.dart';

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
  late final bool reviewOnly;
  late final RemediationPlan plan;
  int index = 0;
  int wrongOnCurrent = 0;
  int checkCorrect = 0;
  int checkTotal = 0;
  bool locked = false;
  bool finishing = false;
  bool showHint = false;
  String feedback = '';

  RemediationTask get current => plan.tasks[index];

  GuidedMethodGuide get _guide => GuidedMethodFactory.forTask(
    mode: current.mode,
    taskKey: current.taskKey,
    expected: current.answer,
    preferences: widget.controller.effectiveMethodPreferences,
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
    plan = RemediationGenerator().generate(
      pattern: widget.pattern,
      preferredMode: widget.preferredMode,
      grade: widget.controller.gradeLevel,
      range: widget.controller.numberRange,
      methods: widget.controller.effectiveMethodPreferences,
      reviewOnly: reviewOnly,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(current.prompt),
    );
    unawaited(
      widget.controller.startRemediation(
        widget.pattern,
        reviewOnly: reviewOnly,
      ),
    );
  }

  Future<void> _answer(int answer) async {
    if (locked || finishing) return;

    if (wrongOnCurrent == 0) {
      await widget.controller.recordDiagnosticAttempt(
        mode: current.mode,
        taskKey: current.taskKey,
        expected: current.answer,
        actual: answer,
        usedHelp: _currentHelpLevel > 0,
        helpLevel: _currentHelpLevel,
        methodKey: _guide.methodKey,
        source: MicroEvidenceSource.remediation,
      );
    }

    if (answer != current.answer) {
      wrongOnCurrent += 1;
      setState(() {
        feedback = wrongOnCurrent == 1
            ? widget.pattern.firstResponseHint
            : 'Nutze den Hinweis und probiere es noch einmal.';
        showHint = true;
      });
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
      feedback = wrongOnCurrent == 0
          ? 'Richtig – der Rechenweg sitzt.'
          : 'Geschafft. Der richtige Weg ist jetzt klar.';
    });

    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted || finishing) return;

    if (index + 1 >= plan.tasks.length) {
      await _finish();
      return;
    }

    setState(() {
      index += 1;
      wrongOnCurrent = 0;
      locked = false;
      showHint = false;
      feedback = '';
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(current.prompt),
    );
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text(
              'Aufgabe ${index + 1} von ${plan.tasks.length}',
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
            const SizedBox(height: 18),
            if (autoHint || showHint) ...[
              LearningVisualAid(
                pattern: widget.pattern,
                taskKey: current.taskKey,
                expected: current.answer,
              ),
              const SizedBox(height: 10),
              _HintCard(text: current.hint),
            ],
            if (!autoHint && !showHint && stage != RemediationStage.check)
              TextButton.icon(
                onPressed: () => setState(() => showHint = true),
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
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                feedback,
                key: ValueKey(feedback),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 18),
            if (current.usesChoices)
              ...List.generate(
                current.choices!.length,
                (choiceIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.tonal(
                    onPressed: locked ? null : () => _answer(choiceIndex),
                    child: Text(
                      current.choices![choiceIndex],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              NumberAnswerPad(
                key: ValueKey('remediation:$index:${current.taskKey}'),
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
