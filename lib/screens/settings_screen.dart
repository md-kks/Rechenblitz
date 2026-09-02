import 'package:flutter/material.dart';

import '../models/training.dart';
import '../services/app_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Einstellungen')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Zahlenraum',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SegmentedButton<NumberRangeLevel>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: NumberRangeLevel.ten, label: Text('bis 10')),
                ButtonSegment(
                    value: NumberRangeLevel.twenty, label: Text('bis 20')),
                ButtonSegment(
                    value: NumberRangeLevel.hundred, label: Text('bis 100')),
              ],
              selected: {widget.controller.numberRange},
              onSelectionChanged: (values) async {
                await widget.controller.setNumberRange(values.first);
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              title: const Text('Leiser Bestätigungston'),
              subtitle: const Text('Nur bei richtiger Antwort'),
              value: widget.controller.soundEnabled,
              onChanged: (v) async {
                await widget.controller.setSound(v);
                if (mounted) setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Haptisches Feedback'),
              subtitle: const Text('Kurze Rückmeldung bei richtiger Antwort'),
              value: widget.controller.hapticEnabled,
              onChanged: (v) async {
                await widget.controller.setHaptic(v);
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 14),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Rechenblitz arbeitet vollständig offline. Lernfortschritt und Einstellungen bleiben auf diesem Gerät.',
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Die Lernlogik priorisiert korrektes und sicheres Rechnen. Tempo wird erst wichtiger, wenn die Grundlagen stabil sind.',
                ),
              ),
            ),
          ],
        ),
      );
}
