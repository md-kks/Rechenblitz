import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  SpeechService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  Future<void> _ensureConfigured(double rate) async {
    if (!_configured) {
      await _tts.setLanguage('de-DE');
      await _tts.setPitch(1.0);
      _configured = true;
    }
    await _tts.setSpeechRate(rate);
  }

  Future<void> speak(
    String text, {
    double rate = 0.45,
  }) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    await _ensureConfigured(rate);
    await _tts.stop();
    await _tts.speak(cleaned);
  }

  Future<void> stop() => _tts.stop();
}
