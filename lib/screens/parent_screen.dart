import 'package:flutter/material.dart';

import '../models/math_fact.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
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
  String _seconds(double ms) => ms == 0 ? '–' : '${(ms / 1000).toStringAsFixed(1)} s';

  Future<void> _startRecommended() async {
    final mode = widget.controller.recommendedMode();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingScreen(
          controller: widget.controller,
          mode: mode,
          targetTasks: mode == TrainingMode.blitz ? 5 : 10,
          timeLimit: mode == TrainingMode.tempo ? const Duration(minutes: 2) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final recommendation = c.engine.recommendation(c.facts);
    final today = c.todayHistory.toList();
    final todayCorrect = today.fold<int>(0, (s, e) => s + e.correctFirstTry);
    final todayErrors = today.fold<int>(0, (s, e) => s + e.incorrectAttempts);
    final todayTasks = today.fold<int>(0, (s, e) => s + e.total);
    final todayAvg = today.isEmpty
        ? 0.0
        : today.map((e) => e.averageResponseMs).fold<double>(0, (a, b) => a + b) / today.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Elternbereich')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _Section(
            title: 'Heute',
            child: Wrap(
              spacing: 22,
              runSpacing: 16,
              children: [
                _Metric('Aufgaben', '$todayTasks'),
                _Metric('direkt richtig', '$todayCorrect'),
                _Metric('Fehlversuche', '$todayErrors'),
                _Metric('Ø Antwort', _seconds(todayAvg)),
                _Metric('Plus Treffer', _percent(c.accuracyFor(MathOperation.plus))),
                _Metric('Minus Treffer', _percent(c.accuracyFor(MathOperation.minus))),
                _Metric('Plus Ø', _seconds(c.averageMsFor(MathOperation.plus))),
                _Metric('Minus Ø', _seconds(c.averageMsFor(MathOperation.minus))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Empfehlung',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(recommendation, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _startRecommended,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Jetzt passende Runde starten'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FactList(title: 'Schwierigste Aufgaben', facts: c.hardest()),
          const SizedBox(height: 16),
          _FactList(title: 'Sicherste Aufgaben', facts: c.safest()),
          const SizedBox(height: 16),
          _Section(
            title: 'Entwicklung',
            child: _Development(history: c.history),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Fortschritt zurücksetzen?'),
                  content: const Text('Alle Lernstatistiken und bisherigen Runden werden gelöscht.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Zurücksetzen')),
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
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              child,
            ],
          ),
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
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label),
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
                        title: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('Treffer ${(f.accuracy * 100).round()} % · Ø ${(f.averageResponseMs / 1000).toStringAsFixed(1)} s'),
                        trailing: Text('${(f.masteryScore * 100).round()} %'),
                      ),
                    )
                    .toList(),
              ),
      );
}

class _Development extends StatelessWidget {
  const _Development({required this.history});
  final List<TrainingSessionResult> history;

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) return const Text('Nach zwei Runden wird hier die Entwicklung sichtbar.');
    final first = history.last.averageResponseMs;
    final current = history.first.averageResponseMs;
    if (first == 0 || current == 0) return const Text('Noch nicht genug Zeitdaten.');
    final difference = (first - current) / 1000;
    return Text(
      'Erste Runde: Ø ${(first / 1000).toStringAsFixed(1)} s\n'
      'Aktuell: Ø ${(current / 1000).toStringAsFixed(1)} s\n'
      '${difference > 0 ? 'Das sind ${difference.toStringAsFixed(1)} s schneller.' : 'Im Moment zählt Sicherheit mehr als Tempo.'}',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
