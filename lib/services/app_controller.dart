import 'package:flutter/foundation.dart';

import '../models/math_fact.dart';
import '../models/training.dart';
import 'adaptive_engine.dart';
import 'storage_service.dart';

class AppController extends ChangeNotifier {
  AppController({StorageService? storage, AdaptiveEngine? engine})
      : storage = storage ?? StorageService(),
        engine = engine ?? AdaptiveEngine();

  final StorageService storage;
  final AdaptiveEngine engine;
  List<MathFact> facts = [];
  List<TrainingSessionResult> history = [];
  bool soundEnabled = false;
  bool hapticEnabled = true;
  bool loaded = false;
  NumberRangeLevel numberRange = NumberRangeLevel.twenty;

  int get maxValue => numberRange.maxValue;

  Future<void> load() async {
    final pool = AdaptiveEngine.buildFactPool(maxValue: 100);
    final saved = await storage.loadFacts();
    facts = pool.map((fresh) => saved[fresh.key] ?? fresh).toList();
    history = await storage.loadHistory();
    soundEnabled = await storage.soundEnabled();
    hapticEnabled = await storage.hapticEnabled();
    numberRange = await storage.numberRange();
    loaded = true;
    notifyListeners();
  }

  Future<void> recordAttempt(
    MathFact fact, {
    required bool correct,
    required Duration responseTime,
    required bool usedHelp,
  }) async {
    fact.registerAttempt(
      correct: correct,
      responseTime: responseTime,
      usedHelp: usedHelp,
    );
    notifyListeners();
    await storage.saveFacts(facts);
  }

  Future<void> addSession(TrainingSessionResult result) async {
    history.insert(0, result);
    if (history.length > 300) history = history.take(300).toList();
    notifyListeners();
    await storage.saveHistory(history);
  }

  Iterable<TrainingSessionResult> get todayHistory {
    final now = DateTime.now();
    return history.where((h) =>
        h.startedAt.year == now.year &&
        h.startedAt.month == now.month &&
        h.startedAt.day == now.day);
  }

  int get todayTasks => todayHistory.fold(0, (sum, e) => sum + e.total);
  int get stars => history.fold(0, (sum, e) => sum + e.starsEarned);

  int rewardStarsForSession(TrainingSessionResult result) {
    if (result.total == 0) return 0;
    var value = 1;
    if (result.total >= 5 && result.accuracy >= 0.80) value += 1;
    if (!history.any((entry) => entry.mode == result.mode)) value += 1;
    return value.clamp(1, 3).toInt();
  }

  String rewardReasonForSession(TrainingSessionResult result) {
    final firstMode = !history.any((entry) => entry.mode == result.mode);
    if (firstMode && result.accuracy >= 0.80) {
      return 'Neue Lernwelt entdeckt und sicher gerechnet.';
    }
    if (firstMode) return 'Neue Lernwelt entdeckt.';
    if (result.accuracy >= 0.80) return 'Viele Aufgaben direkt sicher gelöst.';
    return 'Runde konzentriert abgeschlossen.';
  }

  double averageMsFor(MathOperation operation) {
    final tried = facts
        .where((f) =>
            f.operation == operation &&
            f.attempts > 0 &&
            AdaptiveEngine.isValid(f, maxValue: maxValue))
        .toList();
    if (tried.isEmpty) return 0;
    return tried.map((e) => e.averageResponseMs).reduce((a, b) => a + b) /
        tried.length;
  }

  double accuracyFor(MathOperation operation) {
    final tried = facts.where((f) =>
        f.operation == operation &&
        f.attempts > 0 &&
        AdaptiveEngine.isValid(f, maxValue: maxValue));
    final attempts = tried.fold<int>(0, (s, f) => s + f.attempts);
    final correct = tried.fold<int>(0, (s, f) => s + f.correctAttempts);
    return attempts == 0 ? 0 : correct / attempts;
  }

  double modeAccuracy(TrainingMode mode) {
    final sessions = history
        .where((h) =>
            h.mode == mode && h.total > 0 && h.numberRange == numberRange)
        .take(12);
    final total = sessions.fold<int>(0, (sum, e) => sum + e.total);
    final correct =
        sessions.fold<int>(0, (sum, e) => sum + e.correctFirstTry);
    return total == 0 ? 0 : correct / total;
  }

  List<MathFact> hardest({int count = 5}) {
    final tried = facts
        .where((f) =>
            f.attempts > 0 && AdaptiveEngine.isValid(f, maxValue: maxValue))
        .toList()
      ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
    return tried.take(count).toList();
  }

  List<MathFact> safest({int count = 5}) {
    final tried = facts
        .where((f) =>
            f.attempts > 0 && AdaptiveEngine.isValid(f, maxValue: maxValue))
        .toList()
      ..sort((a, b) => b.masteryScore.compareTo(a.masteryScore));
    return tried.take(count).toList();
  }

  TrainingMode recommendedMode() {
    final text = engine.recommendation(facts, maxValue: maxValue);
    if (text.contains('Minus-Runde')) return TrainingMode.minus;
    if (text.contains('Schnell rechnen')) return TrainingMode.speed;
    if (text.contains('Rechencheck')) return TrainingMode.tempo;
    return TrainingMode.practice;
  }

  Future<void> setNumberRange(NumberRangeLevel value) async {
    numberRange = value;
    notifyListeners();
    await storage.setNumberRange(value);
  }

  Future<void> setSound(bool value) async {
    soundEnabled = value;
    notifyListeners();
    await storage.setSoundEnabled(value);
  }

  Future<void> setHaptic(bool value) async {
    hapticEnabled = value;
    notifyListeners();
    await storage.setHapticEnabled(value);
  }

  Future<void> resetProgress() async {
    await storage.clear();
    facts = AdaptiveEngine.buildFactPool(maxValue: 100);
    history = [];
    notifyListeners();
  }
}
