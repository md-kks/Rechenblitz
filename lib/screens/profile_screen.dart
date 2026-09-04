import 'package:flutter/material.dart';

import '../models/learner_profile.dart';
import '../models/training.dart';
import '../services/app_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  Future<void> _addProfile() async {
    final nameController = TextEditingController();
    var grade = GradeLevel.second;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lernprofil hinzufügen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: 'Name oder Spitzname',
                  hintText: 'z. B. Mia',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<GradeLevel>(
                initialValue: grade,
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
                  if (value != null) {
                    setDialogState(() => grade = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Anlegen'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await widget.controller.createProfile(
        name: nameController.text,
        grade: grade,
      );
      if (mounted) Navigator.of(context).pop();
    }
    nameController.dispose();
  }

  Future<void> _rename() async {
    final text = TextEditingController(text: widget.controller.activeProfileName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profilname ändern'),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLength: 24,
          decoration: const InputDecoration(labelText: 'Name oder Spitzname'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (value != null) await widget.controller.renameActiveProfile(value);
    text.dispose();
  }

  Future<void> _delete(String id, String name) async {
    if (widget.controller.profiles.length <= 1) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$name löschen?'),
        content: const Text(
          'Nur der lokale Lernstand dieses Profils wird gelöscht. Andere Profile bleiben erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.deleteProfile(id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Lernprofile')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProfile,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Profil hinzufügen'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Jedes Profil hat einen eigenen Lernstand, eigene Abzeichen und eigene Rechenwege. Alles bleibt lokal auf diesem Gerät.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...controller.profiles.map(
            (profile) {
              final active = profile.id == controller.activeProfileId;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      profile.name.trim().isEmpty
                          ? '?'
                          : profile.name.trim().substring(0, 1).toUpperCase(),
                    ),
                  ),
                  title: Text(
                    profile.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${profile.gradeLevel.label} · ${profile.state.label}'),
                  trailing: active
                      ? PopupMenuButton<String>(
                          tooltip: 'Profil verwalten',
                          onSelected: (value) {
                            if (value == 'rename') _rename();
                            if (value == 'delete') {
                              _delete(profile.id, profile.name);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Text('Umbenennen'),
                            ),
                            if (controller.profiles.length > 1)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Löschen'),
                              ),
                          ],
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  selected: active,
                  onTap: active
                      ? null
                      : () => controller.switchProfile(profile.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
