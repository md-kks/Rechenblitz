import 'package:flutter/material.dart';

import '../models/training.dart';
import '../services/app_controller.dart';
import 'method_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(
                    controller.activeProfileName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(controller.gradeLevel.label),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(controller: controller),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('So rechnen wir'),
                  subtitle: const Text(
                    'Rechenwege aus der Schule für Hilfen und Erklärungen',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MethodScreen(controller: controller),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Lernrahmen',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<GradeLevel>(
            initialValue: controller.gradeLevel,
            decoration: const InputDecoration(
              labelText: 'Klassenstufe',
              border: OutlineInputBorder(),
            ),
            items: GradeLevel.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) controller.setGradeLevel(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<NumberRangeLevel>(
            key: ValueKey(
              'settings-range:${controller.gradeLevel.name}:${controller.numberRange.name}',
            ),
            initialValue: controller.numberRange,
            decoration: const InputDecoration(
              labelText: 'Zahlenraum',
              border: OutlineInputBorder(),
            ),
            items: controller.availableRanges
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) controller.setNumberRange(value);
            },
          ),
          const SizedBox(height: 18),
          SwitchListTile(
            title: const Text('Leiser Bestätigungston'),
            subtitle: const Text('Nur bei richtiger Antwort'),
            value: controller.soundEnabled,
            onChanged: controller.setSound,
          ),
          SwitchListTile(
            title: const Text('Haptisches Feedback'),
            subtitle: const Text('Kurze Rückmeldung bei richtiger Antwort'),
            value: controller.hapticEnabled,
            onChanged: controller.setHaptic,
          ),
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Rechenblitz arbeitet local first: Lernprofile, Lernfortschritt und Rechenwege bleiben auf diesem Gerät. Es ist kein Konto erforderlich.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Die Lernlogik priorisiert Verstehen, korrektes Rechnen und Sicherheit. Tempo wird erst wichtiger, wenn die Grundlagen stabil sind.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
