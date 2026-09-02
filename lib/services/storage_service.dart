import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/math_fact.dart';
import '../models/training.dart';

class StorageService {
  static const _factsKey = 'facts_v1';
  static const _historyKey = 'history_v1';
  static const _soundKey = 'sound_enabled';
  static const _hapticKey = 'haptic_enabled';
  static const _numberRangeKey = 'number_range_v1';

  Future<Map<String, MathFact>> loadFacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_factsKey);
    if (raw == null) return {};
    final values = jsonDecode(raw) as List<dynamic>;
    final result = <String, MathFact>{};
    for (final value in values) {
      final fact = MathFact.fromJson(value as Map<String, dynamic>);
      result[fact.key] = fact;
    }
    return result;
  }

  Future<void> saveFacts(Iterable<MathFact> facts) async {
    final prefs = await SharedPreferences.getInstance();
    final practiced = facts.where((f) => f.attempts > 0).toList();
    await prefs.setString(
      _factsKey,
      jsonEncode(practiced.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<TrainingSessionResult>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => TrainingSessionResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHistory(List<TrainingSessionResult> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(history.take(300).map((e) => e.toJson()).toList()),
    );
  }

  Future<bool> soundEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_soundKey) ?? false;

  Future<bool> hapticEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_hapticKey) ?? true;

  Future<NumberRangeLevel> numberRange() async {
    final raw =
        (await SharedPreferences.getInstance()).getString(_numberRangeKey);
    if (raw == null) return NumberRangeLevel.twenty;
    for (final value in NumberRangeLevel.values) {
      if (value.name == raw) return value;
    }
    return NumberRangeLevel.twenty;
  }

  Future<void> setSoundEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_soundKey, value);

  Future<void> setHapticEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_hapticKey, value);

  Future<void> setNumberRange(NumberRangeLevel value) async =>
      (await SharedPreferences.getInstance())
          .setString(_numberRangeKey, value.name);

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_factsKey);
    await prefs.remove(_historyKey);
  }
}
