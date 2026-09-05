import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/error_diagnosis.dart';
import '../models/guided_method.dart';
import '../models/micro_competency.dart';
import '../models/structured_exercise.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../widgets/guided_method_panel.dart';
import '../widgets/number_answer_pad.dart';

class StructuredTrainingScreen extends StatefulWidget {
  const StructuredTrainingScreen({
    super.key,
    required this.controller,
    required this.mode,
    this.targetTasks = 10,
    this.targetCompetency,
    this.reviewEmphasis = false,
    this.transferEmphasis = false,
  });

  final AppController controller;
  final TrainingMode mode;
  final int targetTasks;
  final MicroCompetencyId? targetCompetency;
  final bool reviewEmphasis;
  final bool transferEmphasis;

  @override
  State<StructuredTrainingScreen> createState() =>
      _StructuredTrainingScreenState();
}

class _StructuredTrainingScreenState extends State<StructuredTrainingScreen> {
  MicroEvidenceSource get _evidenceSource => widget.transferEmphasis
      ? MicroEvidenceSource.transfer
      : widget.reviewEmphasis
          ? MicroEvidenceSource.review
          : MicroEvidenceSource.practice;

  final StructuredExerciseGenerator generator = StructuredExerciseGenerator();
  late StructuredExercise current;
  late DateTime startedAt;
  late DateTime shownAt;
  int completed = 0;
  int correctFirstTry = 0;
  int incorrectAttempts = 0;
  int wrongOnCurrent = 0;
  bool locked = false;
  bool finishing = false;
  bool showHint = false;
  int helpLevel = 0;
  String? activeMethodKey;
  String feedback = '';
  ErrorPattern? currentErrorPattern;
  final List<int> responseTimes = [];

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    current = _next();
    shownAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(current.prompt),
    );
  }

  StructuredExercise _next() => generator.generate(
        mode: widget.mode,
        maxValue: widget.controller.effectiveMaxValue,
        recentKeys: widget.controller.recentTaskKeys(widget.mode),
        targetCompetency: widget.targetCompetency,
        gradeLevel: widget.controller.effectiveGradeLevel,
        transferEmphasis: widget.transferEmphasis,
      );

  ErrorPattern get _helpPattern =>
      currentErrorPattern ??
      ErrorClassifier.classify(
        mode: widget.mode,
        taskKey: current.key,
        expected: current.answer,
        actual: current.answer,
      ) ??
      ErrorPattern.unknown;

  GuidedMethodGuide get _guide => GuidedMethodFactory.forTask(
        mode: widget.mode,
        taskKey: current.key,
        expected: current.answer,
        preferences: widget.controller.effectiveMethodPreferences,
        targetCompetency: widget.targetCompetency,
      );



  Future<void> _answer(int answer) async {
    if (locked || finishing) return;
    final response = DateTime.now().difference(shownAt);
    final diagnosedPattern = answer == current.answer
        ? null
        : ErrorClassifier.classify(
            mode: widget.mode,
            taskKey: current.key,
            expected: current.answer,
            actual: answer,
          );
    if (wrongOnCurrent == 0) {
      await widget.controller.rememberPresentedTask(
        widget.mode,
        current.key,
      );
      await widget.controller.recordDiagnosticAttempt(
        mode: widget.mode,
        taskKey: current.key,
        expected: current.answer,
        actual: answer,
        usedHelp: showHint,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
        source: _evidenceSource,
      );
    }
    if (answer != current.answer) {
      incorrectAttempts += 1;
      wrongOnCurrent += 1;
      setState(() {
        currentErrorPattern ??= diagnosedPattern;
        feedback = wrongOnCurrent >= 2
            ? 'Nutze den Hinweis und probier noch einmal.'
            : diagnosedPattern?.firstResponseHint ??
                'Prüfe die Aufgabe noch einmal.';
        showHint = wrongOnCurrent >= 2;
      });
      return;
    }

    if (wrongOnCurrent > 0 && helpLevel > 0) {
      await widget.controller.recordMicroSupportResolution(
        mode: widget.mode,
        taskKey: current.key,
        helpLevel: helpLevel,
        methodKey: activeMethodKey,
        source: _evidenceSource,
      );
      if (!mounted || finishing) return;
    }

    locked = true;
    completed += 1;
    responseTimes.add(response.inMilliseconds.clamp(0, 30000).toInt());
    if (wrongOnCurrent == 0) correctFirstTry += 1;
    if (widget.controller.hapticEnabled) HapticFeedback.lightImpact();
    if (widget.controller.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    setState(() => feedback =
        ['Richtig!', 'Genau!', 'Stimmt!', 'Gut gelöst!'][completed % 4]);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted || finishing) return;
    if (completed >= widget.targetTasks) {
      await _finish();
      return;
    }
    setState(() {
      current = _next();
      shownAt = DateTime.now();
      wrongOnCurrent = 0;
      locked = false;
      showHint = false;
      helpLevel = 0;
      activeMethodKey = null;
      currentErrorPattern = null;
      feedback = '';
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.speak(current.prompt),
    );
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;
    final avg = responseTimes.isEmpty
        ? 0.0
        : responseTimes.reduce((a, b) => a + b) / responseTimes.length;
    var result = TrainingSessionResult(
      mode: widget.mode,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      total: completed,
      correctFirstTry: correctFirstTry,
      incorrectAttempts: incorrectAttempts,
      plusCorrect: 0,
      plusTotal: 0,
      minusCorrect: 0,
      minusTotal: 0,
      averageResponseMs: avg,
      numberRange: widget.controller.effectiveNumberRange,
      gradeLevel: widget.controller.effectiveGradeLevel,
      starsEarned: 0,
    );
    final rewardReason = widget.controller.rewardReasonForSession(result);
    result = result.copyWith(
      starsEarned: widget.controller.rewardStarsForSession(result),
    );
    if (completed > 0) await widget.controller.addSession(result);
    final newBadges = widget.controller.lastSessionNewBadges;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Runde geschafft!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$completed Aufgaben bearbeitet.'),
              const SizedBox(height: 8),
              Text('$correctFirstTry direkt richtig.'),
              const SizedBox(height: 14),
              Text(
                '+${result.starsEarned} ★',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(rewardReason),
              if (newBadges.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Neues Abzeichen!',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                ...newBadges.map(
                  (badge) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('🏅 ${badge.title}  +${badge.stars} ★'),
                  ),
                ),
              ],
            ],
          ),
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
              '${widget.mode.title} · ${widget.controller.effectiveNumberRange.label}'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: widget.targetTasks == 0
                          ? 0
                          : completed / widget.targetTasks,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$completed/${widget.targetTasks}'),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      current.prompt,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:
                            widget.mode == TrainingMode.wordProblems ? 25 : 34,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Aufgabe vorlesen',
                    onPressed: () =>
                        widget.controller.speakOnDemand(current.prompt),
                    icon: const Icon(Icons.volume_up_outlined),
                  ),
                ],
              ),
              if (current.hasRepresentationVisual) ...[
                const SizedBox(height: 22),
                _RepresentationVisual(exercise: current),
              ],
              if (current.isNumberWall) ...[
                const SizedBox(height: 22),
                _NumberWall(exercise: current),
              ],
              if (current.hasClock) ...[
                const SizedBox(height: 22),
                Center(
                  child: SizedBox(
                    width: 190,
                    height: 190,
                    child: CustomPaint(
                      painter: _ClockPainter(
                        hour: current.clockHour!,
                        minute: current.clockMinute!,
                        color: Theme.of(context).colorScheme.onSurface,
                        accent: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
              if (current.shape != null) ...[
                const SizedBox(height: 22),
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 145,
                    child: CustomPaint(
                      painter: _ShapePainter(
                        shape: current.shape!,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
              if (current.hasMoneyVisual) ...[
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: current.moneyPartsCents!
                      .map((value) => _MoneyPiece(cents: value))
                      .toList(),
                ),
              ],
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  feedback,
                  key: ValueKey(feedback),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (showHint) ...[
                const SizedBox(height: 12),
                GuidedMethodPanel(
                  key: ValueKey('guide:${current.key}:$completed'),
                  guide: _guide,
                  pattern: _helpPattern,
                  taskKey: current.key,
                  expected: current.answer,
                  onHelpLevelChanged: (level) {
                    if (!mounted) return;
                    setState(() {
                      helpLevel = level.value;
                      activeMethodKey = _guide.methodKey;
                    });
                  },
                  onSpeak: widget.controller.speakOnDemand,
                ),
              ] else ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() {
                  showHint = true;
                  helpLevel = HelpLevel.nudge.value;
                  activeMethodKey = _guide.methodKey;
                }),
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('Hinweis anzeigen'),
                ),
              ],
              const SizedBox(height: 18),
              if (current.usesChoices)
                ...List.generate(
                  current.choices!.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.tonal(
                      onPressed: locked ? null : () => _answer(index),
                      child: Text(current.choices![index]),
                    ),
                  ),
                )
              else ...[
                if (current.answerSuffix != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Antwort in ${current.answerSuffix}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                NumberAnswerPad(
                  key: ValueKey('${current.key}:$completed'),
                  maxValue:
                      current.maxAnswerValue ?? widget.controller.effectiveMaxValue,
                  onAnswer: _answer,
                ),
              ],
            ],
          ),
        ),
      );
}

class _RepresentationVisual extends StatelessWidget {
  const _RepresentationVisual({required this.exercise});

  final StructuredExercise exercise;

  @override
  Widget build(BuildContext context) => switch (exercise.representation!) {
        ExerciseRepresentation.placeValue => _PlaceValueVisual(
            number: exercise.representationA!,
          ),
        ExerciseRepresentation.equalGroups => _EqualGroupsVisual(
            groups: exercise.representationA!,
            each: exercise.representationB!,
          ),
      };
}

class _PlaceValueVisual extends StatelessWidget {
  const _PlaceValueVisual({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    const labels = ['E', 'Z', 'H', 'T', 'ZT', 'HT', 'M'];
    final digits = <int>[];
    var remaining = number;
    do {
      digits.add(remaining % 10);
      remaining ~/= 10;
    } while (remaining > 0);

    return Semantics(
      label: 'Stellenwertdarstellung für eine Zahl',
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            digits.length,
            (index) {
              final reversedIndex = digits.length - 1 - index;
              final label = labels[reversedIndex];
              final digit = digits[reversedIndex];
              return Container(
                width: 58,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$digit',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EqualGroupsVisual extends StatelessWidget {
  const _EqualGroupsVisual({
    required this.groups,
    required this.each,
  });

  final int groups;
  final int each;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$groups gleich große Gruppen mit je $each Punkten',
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              groups,
              (_) => Container(
                width: 76,
                constraints: const BoxConstraints(minHeight: 62),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  color:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 5,
                  runSpacing: 5,
                  children: List.generate(
                    each,
                    (_) => Icon(
                      Icons.circle,
                      size: 13,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _MoneyPiece extends StatelessWidget {
  const _MoneyPiece({required this.cents});
  final int cents;

  @override
  Widget build(BuildContext context) {
    final label = cents >= 100 && cents % 100 == 0
        ? '${cents ~/ 100} €'
        : '$cents ct';
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
    );
  }
}

class _NumberWall extends StatelessWidget {
  const _NumberWall({required this.exercise});
  final StructuredExercise exercise;

  @override
  Widget build(BuildContext context) {
    final values = exercise.wallValues!;
    final hidden = exercise.hiddenWallIndex!;
    Widget brick(int index) => Container(
          width: 78,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            color: index == hidden
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            index == hidden ? '?' : '${values[index]}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        );

    return Column(
      children: [
        brick(5),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [brick(3), const SizedBox(width: 8), brick(4)],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            brick(0),
            const SizedBox(width: 8),
            brick(1),
            const SizedBox(width: 8),
            brick(2),
          ],
        ),
      ],
    );
  }
}

class _ClockPainter extends CustomPainter {
  const _ClockPainter({
    required this.hour,
    required this.minute,
    required this.color,
    required this.accent,
  });

  final int hour;
  final int minute;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, outline);

    final tick = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 - math.pi / 2;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 5),
        center.dy + math.sin(angle) * (radius - 5),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 14),
        center.dy + math.sin(angle) * (radius - 14),
      );
      canvas.drawLine(inner, outer, tick);
    }

    final minuteAngle = minute * math.pi / 30 - math.pi / 2;
    final hourAngle = ((hour % 12) + minute / 60) * math.pi / 6 - math.pi / 2;
    final minutePaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final hourPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + math.cos(minuteAngle) * radius * 0.72,
          center.dy + math.sin(minuteAngle) * radius * 0.72),
      minutePaint,
    );
    canvas.drawLine(
      center,
      Offset(center.dx + math.cos(hourAngle) * radius * 0.48,
          center.dy + math.sin(hourAngle) * radius * 0.48),
      hourPaint,
    );
    canvas.drawCircle(center, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) =>
      hour != oldDelegate.hour || minute != oldDelegate.minute;
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter({required this.shape, required this.color});

  final ExerciseShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round;
    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    switch (shape) {
      case ExerciseShape.triangle:
        final path = Path()
          ..moveTo(size.width / 2, 12)
          ..lineTo(size.width - 12, size.height - 12)
          ..lineTo(12, size.height - 12)
          ..close();
        canvas.drawPath(path, paint);
      case ExerciseShape.square:
        final side = math.min(rect.width, rect.height);
        final square = Rect.fromCenter(
          center: rect.center,
          width: side,
          height: side,
        );
        canvas.drawRect(square, paint);
      case ExerciseShape.rectangle:
        canvas.drawRect(rect, paint);
      case ExerciseShape.circle:
        canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) =>
      shape != oldDelegate.shape || color != oldDelegate.color;
}
