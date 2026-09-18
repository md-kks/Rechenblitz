import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/learning_subject.dart';
import '../../core/storage/subject_storage_keyspace.dart';
import 'german_history_scope.dart';
import 'german_round_draft.dart';
import 'german_session.dart';

class GermanStorageService {
  const GermanStorageService({required this.profileId});

  static const _keyspace = SubjectStorageKeyspace(LearningSubject.german);
  static const _historyKey = 'history_v1';
  static const _roundDraftKey = 'round_draft_v1';
  static const _introCompleteKey = 'intro_complete_v1';
  static final Map<String, Future<void>> _historyMutations =
      <String, Future<void>>{};
  static final Map<String, Future<void>> _draftMutations =
      <String, Future<void>>{};

  final String profileId;

  String get _profileHistoryKey => _keyspace.profileKey(profileId, _historyKey);
  String get _profileRoundDraftKey =>
      _keyspace.profileKey(profileId, _roundDraftKey);
  String get _profileIntroCompleteKey =>
      _keyspace.profileKey(profileId, _introCompleteKey);

  Future<List<GermanSessionResult>> loadHistory() async {
    final pending = _historyMutations[_profileHistoryKey];
    if (pending != null) {
      try {
        await pending;
      } catch (_) {
        // A failed prior write must not make local progress unreadable.
      }
    }
    return _loadHistoryUnlocked();
  }

  Future<List<GermanSessionResult>> _loadHistoryUnlocked() async {
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
      results.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
      return GermanHistoryScope.unique(
        results,
      ).take(300).toList(growable: false);
    } catch (_) {
      return <GermanSessionResult>[];
    }
  }

  Future<void> saveHistory(Iterable<GermanSessionResult> history) {
    final snapshot = history.toList(growable: false);
    return _enqueueHistoryMutation(() => _saveHistoryUnlocked(snapshot));
  }

  Future<void> _saveHistoryUnlocked(
    Iterable<GermanSessionResult> history,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final values = GermanHistoryScope.unique(history)
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    await prefs.setString(
      _profileHistoryKey,
      jsonEncode(values.take(300).map((session) => session.toJson()).toList()),
    );
  }

  Future<void> appendSession(GermanSessionResult result) =>
      _enqueueHistoryMutation(() async {
        final history = await _loadHistoryUnlocked();
        if (history.any(
          (existing) => existing.evidenceIdentity == result.evidenceIdentity,
        )) {
          return;
        }
        await _saveHistoryUnlocked(<GermanSessionResult>[result, ...history]);
      });

  Future<void> _enqueueHistoryMutation(Future<void> Function() mutation) {
    final key = _profileHistoryKey;
    final previous = _historyMutations[key] ?? Future<void>.value();
    late final Future<void> operation;
    operation = previous
        .catchError((_) {})
        .then((_) => mutation())
        .whenComplete(() {
          if (identical(_historyMutations[key], operation)) {
            _historyMutations.remove(key);
          }
        });
    _historyMutations[key] = operation;
    return operation;
  }

  Future<GermanRoundDraft?> loadRoundDraft() async {
    final pending = _draftMutations[_profileRoundDraftKey];
    if (pending != null) {
      try {
        await pending;
      } catch (_) {
        // A failed draft write must not make the profile unreadable.
      }
    }
    return _loadRoundDraftUnlocked();
  }

  Future<GermanRoundDraft?> _loadRoundDraftUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileRoundDraftKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return GermanRoundDraft.fromJson(decoded);
    } catch (_) {
      await prefs.remove(_profileRoundDraftKey);
      return null;
    }
  }

  Future<void> saveRoundDraft(GermanRoundDraft draft) {
    final encoded = jsonEncode(draft.toJson());
    return _enqueueDraftMutation(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileRoundDraftKey, encoded);
    });
  }

  Future<void> clearRoundDraft() => _enqueueDraftMutation(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileRoundDraftKey);
  });

  Future<void> _enqueueDraftMutation(Future<void> Function() mutation) {
    final key = _profileRoundDraftKey;
    final previous = _draftMutations[key] ?? Future<void>.value();
    late final Future<void> operation;
    operation = previous
        .catchError((_) {})
        .then((_) => mutation())
        .whenComplete(() {
          if (identical(_draftMutations[key], operation)) {
            _draftMutations.remove(key);
          }
        });
    _draftMutations[key] = operation;
    return operation;
  }

  Future<bool> loadIntroComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileIntroCompleteKey) ?? false;
  }

  Future<void> setIntroComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileIntroCompleteKey, value);
  }

  Future<void> clear() async {
    await _enqueueHistoryMutation(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileHistoryKey);
    });
    await clearRoundDraft();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileIntroCompleteKey);
  }
}
