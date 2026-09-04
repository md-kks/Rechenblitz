import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/beta_feedback.dart';
import '../services/app_controller.dart';

class BetaFeedbackScreen extends StatefulWidget {
  const BetaFeedbackScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<BetaFeedbackScreen> createState() => _BetaFeedbackScreenState();
}

class _BetaFeedbackScreenState extends State<BetaFeedbackScreen> {
  BetaTesterRole role = BetaTesterRole.parent;
  BetaFeedbackArea area = BetaFeedbackArea.tasks;
  double rating = 4;
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    noteController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final note = noteController.text.trim();
    await widget.controller.addBetaFeedback(
      BetaFeedbackEntry(
        createdAt: DateTime.now(),
        role: role,
        area: area,
        rating: rating.round(),
        note: note,
      ),
    );
    noteController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Beta-Feedback lokal gespeichert.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.controller.betaFeedbackEntries;
    final average = entries.isEmpty
        ? 0.0
        : entries.fold<int>(0, (sum, entry) => sum + entry.rating) /
            entries.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Beta-Test')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Hier können echte Testpersonen strukturiertes Feedback hinterlassen. Rechenblitz speichert dabei weder Name noch Profil-ID noch Lernverlauf im Feedback.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<BetaTesterRole>(
            initialValue: role,
            decoration: const InputDecoration(
              labelText: 'Wer testet?',
              border: OutlineInputBorder(),
            ),
            items: BetaTesterRole.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => role = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BetaFeedbackArea>(
            initialValue: area,
            decoration: const InputDecoration(
              labelText: 'Bereich',
              border: OutlineInputBorder(),
            ),
            items: BetaFeedbackArea.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => area = value);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Bewertung: ${rating.round()} / 5',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Slider(
            min: 1,
            max: 5,
            divisions: 4,
            value: rating,
            onChanged: (value) => setState(() => rating = value),
          ),
          TextField(
            controller: noteController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Was war gut, unklar oder schwierig?',
              hintText:
                  'Bitte keine Namen oder andere persönliche Daten eintragen.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Feedback lokal speichern'),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _Metric('Einträge', '${entries.length}'),
                  _Metric(
                    'Ø Bewertung',
                    entries.isEmpty ? '–' : average.toStringAsFixed(1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: entries.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: widget.controller.betaFeedbackExport(),
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Beta-Export kopiert. Automatisch werden keine Profil- oder Lerndaten angehängt.'),
                      ),
                    );
                  },
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Beta-Export kopieren'),
          ),
          TextButton.icon(
            onPressed: entries.isEmpty
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Beta-Feedback löschen?'),
                        content: const Text(
                          'Alle lokal gespeicherten Beta-Testnotizen werden entfernt.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text('Abbrechen'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text('Löschen'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await widget.controller.clearBetaFeedback();
                    }
                  },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Beta-Feedback löschen'),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label),
        ],
      );
}
