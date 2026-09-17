import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/learning_subject.dart';
import '../../core/storage/subject_storage_keyspace.dart';
import 'german_session.dart';

class GermanStorageService {
  const GermanStorageService({required this.profileId});

  static const _keyspace = SubjectStorageKeyspace(LearningSubject.german);
  static const _historyKey = 'history_v1';

  final String profileId;

  String get _profileHistoryKey => _keyspace.profileKey(profileId, _historyKey);

  Future<List<GermanSessionResult>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileHistoryKey);
    if (raw == null) return <GermanSessionResult>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return <GermanSessionResult>[];
      final results = <GermanSessionResult>[];
      for (final value in decoded) {
        if (value is! Map<String, dynamic>) continue;
        try {
          results.add(GermanSessionResult.fromJson(value));
        } catch (_) {
          // One damaged session must not hide the remaining local progress.
        }
      }
      return results;
    } catch (_) {
      return <GermanSessionResult>[];
    }
  }

  Future<void> saveHistory(Iterable<GermanSessionResult> history) async {
    final prefs = await SharedPreferences.getInstance();
    final values = history.toList()
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    await prefs.setString(
      _profileHistoryKey,
      jsonEncode(values.take(300).map((session) => session.toJson()).toList()),
    );
  }

  Future<void> appendSession(GermanSessionResult result) async {
    final history = await loadHistory();
    await saveHistory(<GermanSessionResult>[result, ...history]);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileHistoryKey);
  }
}
