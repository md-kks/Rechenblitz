import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/teacher_assignment.dart';
import '../models/training.dart';
import '../services/app_controller.dart';
import '../services/assignment_launcher.dart';

class AssignmentScannerScreen extends StatefulWidget {
  const AssignmentScannerScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<AssignmentScannerScreen> createState() =>
      _AssignmentScannerScreenState();
}

class _AssignmentScannerScreenState extends State<AssignmentScannerScreen> {
  final MobileScannerController scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final TextEditingController codeController = TextEditingController();
  bool handling = false;
  String? errorText;

  @override
  void initState() {
    super.initState();
    unawaited(scanner.start());
  }

  @override
  void dispose() {
    scanner.dispose();
    codeController.dispose();
    super.dispose();
  }

  Future<void> _handlePayload(String raw) async {
    if (handling) return;
    final assignment = TeacherAssignment.tryParse(raw);
    if (assignment == null) {
      setState(() {
        errorText = 'Das ist kein gültiger Rechenblitz-Auftrag.';
      });
      return;
    }

    handling = true;
    await scanner.stop();
    if (!mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schulauftrag erkannt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.summary,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              assignment.gradeLevel == widget.controller.gradeLevel
                  ? 'Der Auftrag passt zur Klassenstufe dieses Profils.'
                  : 'Der Auftrag ist für ${assignment.gradeLevel.label}, dieses Profil aber für ${widget.controller.gradeLevel.label}. Er wird nicht in das Profil übernommen.',
            ),
            const SizedBox(height: 10),
            const Text(
              'Der QR-Code enthält keine persönlichen Schülerdaten.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed:
                assignment.gradeLevel == widget.controller.gradeLevel
                    ? () => Navigator.of(context).pop(true)
                    : null,
            child: const Text('Auftrag starten'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (accepted == true) {
      await launchTeacherAssignment(
        context,
        widget.controller,
        assignment,
      );
    }
    handling = false;
    if (mounted) await scanner.start();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Schulauftrag scannen')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Scanne den QR-Code der Lehrkraft. Der Auftrag wird nur für diese Runde verwendet und verändert deine persönlichen Profileinstellungen nicht.',
                ),
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 310,
                child: MobileScanner(
                  controller: scanner,
                  onDetect: (capture) {
                    for (final barcode in capture.barcodes) {
                      final raw = barcode.rawValue;
                      if (raw != null && raw.startsWith(TeacherAssignment.prefix)) {
                        _handlePayload(raw);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Alternativ Auftragscode einfügen',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'RB1:…',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _handlePayload(codeController.text),
              icon: const Icon(Icons.input_rounded),
              label: const Text('Code prüfen'),
            ),
          ],
        ),
      );
}
