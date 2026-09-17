import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/accessibility_preferences.dart';
import '../models/assessment.dart';
import '../models/beta_feedback.dart';
import '../models/error_diagnosis.dart';
import '../models/learner_profile.dart';
import '../models/learning_methods.dart';
import '../models/learning_path.dart';
import '../models/math_fact.dart';
import '../models/micro_competency.dart';
import '../models/remediation_path.dart';
import '../models/support_session_progress.dart';
import '../models/training_session_progress.dart';
import '../models/training.dart';
import 'micro_evidence_retention.dart';

class StorageService {
  static const _factsKey = 'facts_v1';
  static const _historyKey = 'history_v1';
  static const _soundKey = 'sound_enabled';
  static const _hapticKey = 'haptic_enabled';
  static const _numberRangeKey = 'number_range_v1';
  static const _gradeLevelKey = 'grade_level_v1';
  static const _badgesKey = 'reward_badges_v1';
  static const _recoveredWeakFactsKey = 'recovered_weak_facts_v1';
  static const _methodsKey = 'method_preferences_v1';
  static const _diagnosticsKey = 'diagnostics_v1';
  static const _remediationKey = 'remediation_progress_v1';
  static const _taskDiversityKey = 'task_diversity_v1';
  static const _microCompetencyKey = 'micro_competency_v1';
  static const _guidedRoundKey = 'guided_round_v1';
  static const _assessmentProgressKey = 'assessment_progress_v1';
  static const _remediationSessionKey = 'remediation_session_v1';
  static const _stepRecoverySessionKey = 'step_recovery_session_v1';
  static const _coreTrainingSessionKey = 'core_training_session_v1';
  static const _accessibilityKey = 'accessibility_preferences_v1';
  static const _betaFeedbackKey = 'beta_feedback_v1';

  static const _profilesKey = 'learner_profiles_v1';
  static const _activeProfileKey = 'active_learner_profile_v1';

  String _activeProfileId = 'default';

  String get activeProfileId => _activeProfileId;

  String _profileKey(String key) => 'profile:$_activeProfileId:$key';

  Future<List<LearnerProfile>> initializeProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);

    if (raw != null) {
      final profiles = _decodeProfiles(raw);
      if (profiles.isNotEmpty) {
        final requested = prefs.getString(_activeProfileKey);
        final active = profiles.any((p) => p.id == requested)
            ? requested!
            : profiles.first.id;
        _activeProfileId = active;
        await prefs.setString(_activeProfileKey, active);
        return profiles;
      }
    }

    final hadLegacyData = [
      _factsKey,
      _historyKey,
      _gradeLevelKey,
      _numberRangeKey,
      _badgesKey,
      _recoveredWeakFactsKey,
    ].any(prefs.containsKey);

    final legacyGrade = _parseGrade(prefs.getString(_gradeLevelKey)) ??
        GradeLevel.second;
    final legacyRange = _parseRange(prefs.getString(_numberRangeKey)) ??
        legacyGrade.recommendedRange;

    final profile = LearnerProfile(
      id: 'default',
      name: 'Lernprofil',
      gradeLevel: legacyGrade,
      createdAt: DateTime.now(),
      onboardingComplete: hadLegacyData,
    );

    _activeProfileId = profile.id;
    await prefs.setString(
      _profilesKey,
      jsonEncode([profile.toJson()]),
    );
    await prefs.setString(_activeProfileKey, profile.id);
    await prefs.setString(_profileKey(_gradeLevelKey), legacyGrade.name);
    await prefs.setString(_profileKey(_numberRangeKey), legacyRange.name);

    await _copyLegacyString(prefs, _factsKey);
    await _copyLegacyString(prefs, _historyKey);
    await _copyLegacyStringList(prefs, _badgesKey);
    await _copyLegacyStringList(prefs, _recoveredWeakFactsKey);

    return [profile];
  }

  Future<List<LearnerProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);
    if (raw == null) return initializeProfiles();
    final profiles = _decodeProfiles(raw);
    return profiles.isEmpty ? initializeProfiles() : profiles;
  }

  Future<void> saveProfiles(List<LearnerProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
    );
  }

  Future<void> setActiveProfileId(String id) async {
    _activeProfileId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProfileKey, id);
  }

  Future<void> deleteProfileData(String id) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _factsKey,
      _historyKey,
      _numberRangeKey,
      _gradeLevelKey,
      _badgesKey,
      _recoveredWeakFactsKey,
      _methodsKey,
      _diagnosticsKey,
      _remediationKey,
      _taskDiversityKey,
      _microCompetencyKey,
      _guidedRoundKey,
      _assessmentProgressKey,
      _remediationSessionKey,
      _stepRecoverySessionKey,
      _coreTrainingSessionKey,
    ]) {
      await prefs.remove('profile:$id:$key');
    }
  }

  Future<Map<String, MathFact>> loadFacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(_factsKey));
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return {};
      final result = <String, MathFact>{};
      for (final value in decoded) {
        if (value is! Map<String, dynamic>) continue;
        try {
          final fact = MathFact.fromJson(value);
          result[fact.key] = fact;
        } catch (_) {
          // A single damaged legacy fact must not block the whole profile.
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveFacts(Iterable<MathFact> facts) async {
    final prefs = await SharedPreferences.getInstance();
    final practiced = facts.where((f) => f.attempts > 0).toList();
    await prefs.setString(
      _profileKey(_factsKey),
      jsonEncode(practiced.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<DiagnosticAttempt>> loadDiagnostics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(_diagnosticsKey));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return [];
      final result = <DiagnosticAttempt>[];
      for (final value in decoded) {
        if (value is! Map<String, dynamic>) continue;
        try {
          result.add(DiagnosticAttempt.fromJson(value));
        } catch (_) {
          // Ignore only the damaged legacy record.
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDiagnostics(List<DiagnosticAttempt> diagnostics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profileKey(_diagnosticsKey),
      jsonEncode(
        diagnostics.take(500).map((entry) => entry.toJson()).toList(),
      ),
    );
  }

  Future<List<RemediationProgress>> loadRemediationProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(_remediationKey));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return [];
      final result = <RemediationProgress>[];
      for (final value in decoded) {
        if (value is! Map<String, dynamic>) continue;
        try {
          result.add(RemediationProgress.fromJson(value));
        } catch (_) {
          // Preserve the remaining remediation history.
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRemediationProgress(
    List<RemediationProgress> progress,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profileKey(_remediationKey),
      jsonEncode(progress.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<Map<String, List<String>>> loadTaskDiversity() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(_taskDiversityKey));
    if (raw == null) return <String, List<String>>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, List<String>>{};
      final result = <String, List<String>>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! List<dynamic>) continue;
        final tasks = value.whereType<String>().toList(growable: false);
        if (tasks.isNotEmpty) result[entry.key] = tasks;
      }
      return result;
    } catch (_) {
      return <String, List<String>>{};
    }
  }

  Future<void> saveTaskDiversity(
    Map<String, List<String>> recentByMode,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profileKey(_taskDiversityKey),
      jsonEncode(recentByMode),
    );
  }

  Future<List<MicroCompetencyObservation>>
      loadMicroCompetencyObservations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(_microCompetencyKey));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return [];
      final observations = <MicroCompetencyObservation>[];
      for (final value in decoded) {
        if (value is! Map<String, dynamic>) continue;
        try {
          observations.add(MicroCompetencyObservation.fromJson(value));
        } catch (_) {
          // Do not discard valid evidence because one legacy row is damaged.
        }
      }
      return MicroEvidenceRetention.compact(observations);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMicroCompetencyObservations(
    List<MicroCompetencyObservation> observations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profileKey(_microCompetencyKey),
      jsonEncode(
        MicroEvidenceRetention.compact(observations)
            .map((entry) => entry.toJson())
            .toList(),
      ),
    );
  }

  Future<List<TrainingSessionResult>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(_historyKey));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return [];
      final result = <TrainingSessionResult>[];
      for (final value in decoded) {
        if (value is! Map<String, dynamic>) continue;
        try {
          result.add(TrainingSessionResult.fromJson(value));
        } catch (_) {
          // Keep valid sessions even if one old entry is malformed.
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<TrainingSessionResult> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profileKey(_historyKey),
      jsonEncode(history.take(300).map((e) => e.toJson()).toList()),
    );
  }

  Future<bool> soundEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_soundKey) ?? false;

  Future<bool> hapticEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_hapticKey) ?? true;

  Future<NumberRangeLevel?> numberRange() async {
    final raw = (await SharedPreferences.getInstance())
        .getString(_profileKey(_numberRangeKey));
    return _parseRange(raw);
  }

  Future<GuidedRoundProgress?> loadGuidedRoundProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _profileKey(_guidedRoundKey);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return GuidedRoundProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      await prefs.remove(key);
      return null;
    }
  }

  Future<void> saveGuidedRoundProgress(GuidedRoundProgress progress) async =>
      (await SharedPreferences.getInstance()).setString(
        _profileKey(_guidedRoundKey),
        jsonEncode(progress.toJson()),
      );

  Future<void> clearGuidedRoundProgress() async =>
      (await SharedPreferences.getInstance())
          .remove(_profileKey(_guidedRoundKey));

  Future<AssessmentProgress?> loadAssessmentProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _profileKey(_assessmentProgressKey);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return AssessmentProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      await prefs.remove(key);
      return null;
    }
  }

  Future<void> saveAssessmentProgress(AssessmentProgress progress) async =>
      (await SharedPreferences.getInstance()).setString(
        _profileKey(_assessmentProgressKey),
        jsonEncode(progress.toJson()),
      );

  Future<void> clearAssessmentProgress() async =>
      (await SharedPreferences.getInstance())
          .remove(_profileKey(_assessmentProgressKey));

  Future<RemediationSessionProgress?> loadRemediationSession() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _profileKey(_remediationSessionKey);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return RemediationSessionProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      await prefs.remove(key);
      return null;
    }
  }

  Future<void> saveRemediationSession(
    RemediationSessionProgress progress,
  ) async =>
      (await SharedPreferences.getInstance()).setString(
        _profileKey(_remediationSessionKey),
        jsonEncode(progress.toJson()),
      );

  Future<void> clearRemediationSession() async =>
      (await SharedPreferences.getInstance())
          .remove(_profileKey(_remediationSessionKey));

  Future<StepRecoverySessionProgress?> loadStepRecoverySession() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _profileKey(_stepRecoverySessionKey);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return StepRecoverySessionProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      await prefs.remove(key);
      return null;
    }
  }

  Future<void> saveStepRecoverySession(
    StepRecoverySessionProgress progress,
  ) async =>
      (await SharedPreferences.getInstance()).setString(
        _profileKey(_stepRecoverySessionKey),
        jsonEncode(progress.toJson()),
      );

  Future<void> clearStepRecoverySession() async =>
      (await SharedPreferences.getInstance())
          .remove(_profileKey(_stepRecoverySessionKey));

  Future<CoreTrainingSessionProgress?> loadCoreTrainingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _profileKey(_coreTrainingSessionKey);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return CoreTrainingSessionProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      await prefs.remove(key);
      return null;
    }
  }

  Future<void> saveCoreTrainingSession(
    CoreTrainingSessionProgress progress,
  ) async =>
      (await SharedPreferences.getInstance()).setString(
        _profileKey(_coreTrainingSessionKey),
        jsonEncode(progress.toJson()),
      );

  Future<void> clearCoreTrainingSession() async =>
      (await SharedPreferences.getInstance())
          .remove(_profileKey(_coreTrainingSessionKey));

  Future<GradeLevel?> storedGradeLevel() async {
    final raw = (await SharedPreferences.getInstance())
        .getString(_profileKey(_gradeLevelKey));
    return _parseGrade(raw);
  }

  Future<MethodPreferences> methodPreferences() async {
    final raw = (await SharedPreferences.getInstance())
        .getString(_profileKey(_methodsKey));
    if (raw == null) return const MethodPreferences();
    try {
      return MethodPreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const MethodPreferences();
    }
  }

  Future<Set<String>> rewardBadges() async =>
      (await SharedPreferences.getInstance())
          .getStringList(_profileKey(_badgesKey))
          ?.toSet() ??
      <String>{};

  Future<Set<String>> recoveredWeakFacts() async =>
      (await SharedPreferences.getInstance())
          .getStringList(_profileKey(_recoveredWeakFactsKey))
          ?.toSet() ??
      <String>{};

  Future<void> setGradeLevel(GradeLevel value) async =>
      (await SharedPreferences.getInstance())
          .setString(_profileKey(_gradeLevelKey), value.name);

  Future<void> setNumberRange(NumberRangeLevel value) async =>
      (await SharedPreferences.getInstance())
          .setString(_profileKey(_numberRangeKey), value.name);

  Future<void> setMethodPreferences(MethodPreferences value) async =>
      (await SharedPreferences.getInstance()).setString(
        _profileKey(_methodsKey),
        jsonEncode(value.toJson()),
      );

  Future<List<BetaFeedbackEntry>> betaFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_betaFeedbackKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map(
            (entry) => BetaFeedbackEntry.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setBetaFeedback(
    List<BetaFeedbackEntry> entries,
  ) async =>
      (await SharedPreferences.getInstance()).setString(
        _betaFeedbackKey,
        jsonEncode(entries.map((entry) => entry.toJson()).toList()),
      );

  Future<AccessibilityPreferences> accessibilityPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accessibilityKey);
    if (raw == null) return const AccessibilityPreferences();
    try {
      return AccessibilityPreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const AccessibilityPreferences();
    }
  }

  Future<void> setAccessibilityPreferences(
    AccessibilityPreferences value,
  ) async =>
      (await SharedPreferences.getInstance()).setString(
        _accessibilityKey,
        jsonEncode(value.toJson()),
      );

  Future<void> setSoundEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_soundKey, value);

  Future<void> setHapticEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_hapticKey, value);

  Future<void> setRewardBadges(Set<String> values) async =>
      (await SharedPreferences.getInstance())
          .setStringList(_profileKey(_badgesKey), values.toList()..sort());

  Future<void> setRecoveredWeakFacts(Set<String> values) async =>
      (await SharedPreferences.getInstance()).setStringList(
        _profileKey(_recoveredWeakFactsKey),
        values.toList()..sort(),
      );

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey(_factsKey));
    await prefs.remove(_profileKey(_historyKey));
    await prefs.remove(_profileKey(_badgesKey));
    await prefs.remove(_profileKey(_recoveredWeakFactsKey));
    await prefs.remove(_profileKey(_diagnosticsKey));
    await prefs.remove(_profileKey(_remediationKey));
    await prefs.remove(_profileKey(_taskDiversityKey));
    await prefs.remove(_profileKey(_microCompetencyKey));
    await prefs.remove(_profileKey(_guidedRoundKey));
    await prefs.remove(_profileKey(_assessmentProgressKey));
    await prefs.remove(_profileKey(_remediationSessionKey));
    await prefs.remove(_profileKey(_stepRecoverySessionKey));
    await prefs.remove(_profileKey(_coreTrainingSessionKey));
  }

  List<LearnerProfile> _decodeProfiles(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return [];
      final result = <LearnerProfile>[];
      final ids = <String>{};
      for (final value in decoded) {
        if (value is! Map<String, dynamic>) continue;
        try {
          final profile = LearnerProfile.fromJson(value);
          if (ids.add(profile.id)) result.add(profile);
        } catch (_) {
          // Salvage the remaining profiles instead of resetting all children.
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  GradeLevel? _parseGrade(String? raw) {
    if (raw == null) return null;
    for (final value in GradeLevel.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  NumberRangeLevel? _parseRange(String? raw) {
    if (raw == null) return null;
    for (final value in NumberRangeLevel.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  Future<void> _copyLegacyString(
    SharedPreferences prefs,
    String key,
  ) async {
    final value = prefs.getString(key);
    if (value != null && !prefs.containsKey(_profileKey(key))) {
      await prefs.setString(_profileKey(key), value);
    }
  }

  Future<void> _copyLegacyStringList(
    SharedPreferences prefs,
    String key,
  ) async {
    final value = prefs.getStringList(key);
    if (value != null && !prefs.containsKey(_profileKey(key))) {
      await prefs.setStringList(_profileKey(key), value);
    }
  }
}
