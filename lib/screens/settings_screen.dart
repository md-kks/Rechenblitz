import 'package:flutter/material.dart';

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
              subtitle: const Text('Kurzes Antippen bei richtiger Antwort'),
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
                  'Die App arbeitet vollständig offline. Lernfortschritt und Einstellungen bleiben nur auf diesem Gerät.',
                ),
              ),
            ),
          ],
        ),
      );
}
