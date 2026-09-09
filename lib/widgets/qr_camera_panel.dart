import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

class QrCameraPanel extends StatefulWidget {
  const QrCameraPanel({super.key, required this.onPayload, this.cameraProbe});

  final ValueChanged<String> onPayload;
  final Future<List<CameraDescription>> Function()? cameraProbe;

  @override
  State<QrCameraPanel> createState() => _QrCameraPanelState();
}

class _QrCameraPanelState extends State<QrCameraPanel> {
  bool checking = true;
  String? unavailableText;

  @override
  void initState() {
    super.initState();
    _checkCamera();
  }

  Future<void> _checkCamera() async {
    setState(() {
      checking = true;
      unavailableText = null;
    });

    try {
      final cameras = await (widget.cameraProbe ?? availableCameras)();
      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() {
          checking = false;
          unavailableText =
              'Auf diesem Gerät ist keine Kamera verfügbar. '
              'Nutze unten die Code-Eingabe.';
        });
        return;
      }

      setState(() => checking = false);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        checking = false;
        unavailableText = _messageForCameraException(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        checking = false;
        unavailableText =
            'Die Kamera konnte nicht vorbereitet werden. '
            'Nutze unten die Code-Eingabe.';
      });
    }
  }

  String _messageForCameraException(CameraException error) {
    final code = error.code.toLowerCase();
    if (code.contains('denied') || code.contains('restricted')) {
      return 'Der Kamerazugriff wurde nicht erlaubt. '
          'Du kannst den Code unten manuell eingeben.';
    }
    return 'Die Kamera konnte nicht geöffnet werden. '
        'Nutze unten die Code-Eingabe.';
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const _CameraMessage(
        icon: Icons.camera_alt_outlined,
        text: 'Kamera wird vorbereitet …',
      );
    }

    final message = unavailableText;
    if (message != null) {
      return _CameraUnavailable(message: message, onRetry: _checkCamera);
    }

    return ReaderWidget(
      codeFormat: Format.qrCode,
      showGallery: false,
      showToggleCamera: false,
      onControllerCreated: (controller, error) {
        if (error == null || !mounted) return;
        setState(() {
          unavailableText = error is CameraException
              ? _messageForCameraException(error)
              : 'Die Kamera konnte nicht geöffnet werden. '
                    'Nutze unten die Code-Eingabe.';
        });
      },
      onScan: (code) {
        final raw = code.text;
        if (raw != null) widget.onPayload(raw);
      },
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _CameraMessage(
    icon: Icons.no_photography_outlined,
    text: message,
    action: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Erneut versuchen'),
    ),
  );
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    ),
  );
}
