import 'package:flutter/material.dart';

import '../models/error_diagnosis.dart';
import '../models/learning_methods.dart';
import '../models/math_fact.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import 'competency_map_screen.dart';
import 'curriculum_training_screen.dart';
import 'method_screen.dart';
import 'reward_screen.dart';
import 'structured_training_screen.dart';
import 'training_screen.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _percent(double value) => '${(value * 100).round()} %';
  String _seconds(double ms) =>
      ms == 0 ? '–' : '${(ms / 1000).toStringAsFixed(1)} s';

  Future<void> _startRecommended() async {
    final mode = widget.controller.recommendedMode();
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingScreen(
          controller: widget.controller,
          mode: mode,
          targetTasks: mode == TrainingMode.blitz ? 5 : 10,
          timeLimit:
              mode == TrainingMode.tempo ? const Duration(minutes: 2) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final recommendation = c.recommendationText();
    final insight = c.parentInsight();
    final diagnosticPatterns =
        c.diagnosticSummaries(recurringOnly: true).take(4).toList();
    final today = c.todayHistory.toList();
    final todayCorrect =
        today.fold<int>(0, (s, e) => s + e.correctFirstTry);
    final todayErrors =
        today.fold<int>(0, (s, e) => s + e.incorrectAttempts);
    final todayTasks = today.fold<int>(0, (s, e) => s + e.total);
    final todayAccuracy = todayTasks == 0 ? 0.0 : todayCorrect / todayTasks;
    final todayAvg = today.isEmpty
        ? 0.0
        : today.map((e) => e.averageResponseMs).fold<double>(0, (a, b) => a + b) /
            today.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Elternbereich')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          _Section(
            title: 'Aktueller Lernrahmen',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${c.activeProfileName} · ${c.gradeLevel.label} · Zahlenraum ${c.numberRange.label}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text('${c.stars} ★ · ${c.badges.length} Abzeichen'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Heute',
            child: Wrap(
              spacing: 22,
              runSpacing: 16,
              children: [
                _Metric('Aufgaben', '$todayTasks'),
                _Metric('direkt richtig',
                    todayTasks == 0 ? '–' : _percent(todayAccuracy)),
                _Metric('Fehlversuche', '$todayErrors'),
                _Metric('Ø Antwort', _seconds(todayAvg)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Klassenstufen',
            child: Column(
              children: GradeLevel.values
                  .map(
                    (grade) => _PercentBar(
                      label: grade.label,
                      value: c.gradeAccuracy(grade),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Was jetzt?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InsightLine(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Das klappt gut',
                  text: insight.good,
                ),
                _InsightLine(
                  icon: Icons.track_changes_rounded,
                  title: 'Hier lohnt sich Üben',
                  text: insight.focus,
                ),
                _InsightLine(
                  icon: Icons.playlist_add_check_circle_outlined,
                  title: 'Was hilft',
                  text: insight.action,
                ),
                _InsightLine(
                  icon: Icons.speed_rounded,
                  title: 'Noch nicht nötig',
                  text: insight.notYet,
                ),
                _InsightLine(
                  icon: Icons.trending_up_rounded,
                  title: 'Entwicklung',
                  text: insight.trend,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CompetencyMapScreen(controller: c),
                    ),
                  ),
                  icon: const Icon(Icons.route_rounded),
                  label: const Text('Lernlandkarte öffnen'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Mögliche Fehlermuster',
            child: diagnosticPatterns.isEmpty
                ? const Text(
                    'Noch kein wiederkehrendes Fehlermuster. Rechenblitz zeigt hier erst etwas an, wenn ein ähnlicher Fehler mindestens zweimal aufgefallen ist.',
                  )
                : Column(
                    children: diagnosticPatterns
                        .map(
                          (summary) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.search_rounded, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        summary.pattern.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${summary.confidenceLabel} · ${summary.errors} Beobachtungen',
                                      ),
                                      const SizedBox(height: 5),
                                      Text(summary.pattern.action),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Grundrechenarten',
            child: Column(
              children: [
                _PercentBar(
                    label: 'Plus', value: c.accuracyFor(MathOperation.plus)),
                _PercentBar(
                    label: 'Minus', value: c.accuracyFor(MathOperation.minus)),
                _PercentBar(
                    label: 'Mal', value: c.accuracyFor(MathOperation.multiply)),
                _PercentBar(
                    label: 'Geteilt', value: c.accuracyFor(MathOperation.divide)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Zahlenraumvergleich',
            child: Column(
              children: NumberRangeLevel.values
                  .map(
                    (range) => _PercentBar(
                      label: range.label,
                      value: c.rangeAccuracy(range),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Zahlen & Rechenwege',
            child: Column(
              children: const [
                TrainingMode.numberWall,
                TrainingMode.missingNumber,
                TrainingMode.neighbors,
                TrainingMode.placeValue,
                TrainingMode.doublesHalves,
                TrainingMode.sequences,
                TrainingMode.factFamilies,
              ]
                  .map(
                    (mode) => _PercentBar(
                      label: mode.title,
                      value: c.modeAccuracy(mode),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Sachrechnen & Alltag',
            child: Column(
              children: const [
                TrainingMode.wordProblems,
                TrainingMode.money,
                TrainingMode.clock,
                TrainingMode.measures,
                TrainingMode.geometry,
              ]
                  .map(
                    (mode) => _PercentBar(
                      label: mode.title,
                      value: c.modeAccuracy(mode),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (c.gradeLevel.index >= GradeLevel.third.index) ...[
            const SizedBox(height: 14),
            _Section(
              title: '${c.gradeLevel.label} · Lehrplanbereiche',
              child: Column(
                children: c
                    .curriculumModesForGrade(c.gradeLevel)
                    .map(
                      (mode) => _PercentBar(
                        label: mode.title,
                        value: c.modeAccuracy(mode),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _Section(
            title: 'Entwicklung',
            child: _AccuracyTrend(history: c.history),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Empfehlung',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(recommendation,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _startRecommended,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Passende Runde starten'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FactList(title: 'Aktuell schwierigste Aufgaben', facts: c.hardest()),
          const SizedBox(height: 14),
          _FactList(title: 'Aktuell sicherste Aufgaben', facts: c.safest()),
          const SizedBox(height: 14),
          _Section(
            title: 'So rechnet die Schule',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minus: ${c.methodPreferences.subtraction.label}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Einmaleins: ${c.methodPreferences.multiplication.label}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Schriftliche Subtraktion: ${c.methodPreferences.writtenSubtraction.label}',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MethodScreen(controller: c),
                    ),
                  ),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Rechenwege anpassen'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Belohnungssystem',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${c.badges.length} Abzeichen · ${c.badgeStars} Bonussterne durch Abzeichen',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Trigger sind abgeschlossene Runden, mindestens 80 % sichere Antworten, deutlicher Fortschritt gegenüber vergleichbaren Runden, Dranbleiben bei schwierigen Aufgaben, das Entdecken verschiedener Lernwelten, sichere Zahlenräume, sichere Rechenarten und das Meistern früherer Schwachstellen. Geschwindigkeit allein wird nicht belohnt.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RewardScreen(controller: c),
                    ),
                  ),
                  icon: const Icon(Icons.emoji_events_rounded),
                  label: const Text('Erfolge ansehen'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Fortschritt zurücksetzen?'),
                  content: const Text(
                    'Alle Lernstatistiken, Sterne und Abzeichen werden gelöscht.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Abbrechen'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Zurücksetzen'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) await c.resetProgress();
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Fortschritt zurücksetzen'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      );
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label),
          ],
        ),
      );
}

class _PercentBar extends StatelessWidget {
  const _PercentBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 115, child: Text(label)),
            Expanded(
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 44,
              child: Text(
                value == 0 ? '–' : '${(value * 100).round()} %',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
}

class _FactList extends StatelessWidget {
  const _FactList({required this.title, required this.facts});
  final String title;
  final List<MathFact> facts;

  @override
  Widget build(BuildContext context) => _Section(
        title: title,
        child: facts.isEmpty
            ? const Text('Noch nicht genug Daten.')
            : Column(
                children: facts
                    .map(
                      (f) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(f.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          'Treffer ${(f.accuracy * 100).round()} % · Ø ${(f.averageResponseMs / 1000).toStringAsFixed(1)} s',
                        ),
                        trailing: Text('${(f.masteryScore * 100).round()} %'),
                      ),
                    )
                    .toList(),
              ),
      );
}

class _AccuracyTrend extends StatelessWidget {
  const _AccuracyTrend({required this.history});
  final List<TrainingSessionResult> history;

  @override
  Widget build(BuildContext context) {
    final sessions =
        history.where((e) => e.total > 0).take(12).toList().reversed.toList();
    if (sessions.length < 2) {
      return const Text(
        'Nach zwei abgeschlossenen Runden wird hier die Entwicklung sichtbar.',
      );
    }
    final values = sessions.map((e) => e.accuracy).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(
              values: values,
              lineColor: Theme.of(context).colorScheme.primary,
              gridColor: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Letzte Runde: ${(values.last * 100).round()} % direkt richtig · ${sessions.last.mode.title}',
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final fraction in [0.25, 0.5, 0.75, 1.0]) {
      final y = size.height * (1 - fraction);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()..color = lineColor;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final normalized = values[i].clamp(0.0, 1.0).toDouble();
      final y = size.height * (1 - normalized);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}
