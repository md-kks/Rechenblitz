import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  SpeechService();

  FlutterTts? _tts;
  bool _configured = false;

  FlutterTts get _engine => _tts ??= FlutterTts();

  Future<void> _ensureConfigured(double rate) async {
    final tts = _engine;
    if (!_configured) {
      await tts.setLanguage('de-DE');
      await tts.setPitch(1.0);
      _configured = true;
    }
    await tts.setSpeechRate(rate);
  }

  Future<void> speak(
    String text, {
    double rate = 0.45,
  }) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    await _ensureConfigured(rate);
    final tts = _engine;
    await tts.stop();
    await tts.speak(cleaned);
  }

  Future<void> stop() async {
    final tts = _tts;
    if (tts == null) return;
    await tts.stop();
  }
}
