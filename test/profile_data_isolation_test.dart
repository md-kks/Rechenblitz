import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileKeys = <String>[
  'facts_v1',
  'history_v1',
  'number_range_v1',
  'grade_level_v1',
  'reward_badges_v1',
  'recovered_weak_facts_v1',
  'method_preferences_v1',
  'diagnostics_v1',
  'remediation_progress_v1',
  'task_diversity_v1',
  'micro_competency_v1',
  'guided_round_v1',
  'assessment_progress_v1',
  'remediation_session_v1',
  'step_recovery_session_v1',
  'core_training_session_v1',
  'active_teacher_assignment_v1',
];
const _progressKeys = <String>[
  'facts_v1',
  'history_v1',
  'reward_badges_v1',
  'recovered_weak_facts_v1',
  'diagnostics_v1',
  'remediation_progress_v1',
  'task_diversity_v1',
  'micro_competency_v1',
  'guided_round_v1',
  'assessment_progress_v1',
  'remediation_session_v1',
  'step_recovery_session_v1',
  'core_training_session_v1',
  'active_teacher_assignment_v1',
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Profil löschen entfernt alle Profilbereiche und nichts Fremdes',
    () async {
      final initial = <String, Object>{
        for (final key in _profileKeys) 'profile:delete:$key': 'delete-$key',
        for (final key in _profileKeys) 'profile:keep:$key': 'keep-$key',
        'sound_enabled': true,
        'haptic_enabled': false,
        'accessibility_preferences_v1': '{}',
        'beta_feedback_v1': '[]',
        'profile:delete:future_feature_v99': 'future-delete',
        'profile:keep:future_feature_v99': 'future-keep',
      };
      SharedPreferences.setMockInitialValues(initial);
      final storage = StorageService();

      await storage.deleteProfileData('delete');

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      expect(keys.where((key) => key.startsWith('profile:delete:')), isEmpty);
      for (final key in _profileKeys) {
        expect(prefs.getString('profile:keep:$key'), 'keep-$key', reason: key);
      }
      expect(prefs.getBool('sound_enabled'), isTrue);
      expect(prefs.getBool('haptic_enabled'), isFalse);
      expect(prefs.getString('accessibility_preferences_v1'), '{}');
      expect(prefs.getString('beta_feedback_v1'), '[]');
      expect(prefs.getString('profile:keep:future_feature_v99'), 'future-keep');
    },
  );

  test('Fortschritt zurücksetzen bewahrt Lernkontext und Rechenwege', () async {
    final initial = <String, Object>{
      for (final key in _profileKeys) 'profile:child:$key': 'value-$key',
    };
    SharedPreferences.setMockInitialValues(initial);
    final storage = StorageService();
    await storage.setActiveProfileId('child');

    await storage.clear();

    final prefs = await SharedPreferences.getInstance();
    for (final key in _progressKeys) {
      expect(prefs.containsKey('profile:child:$key'), isFalse, reason: key);
    }
    for (final key in const <String>[
      'grade_level_v1',
      'number_range_v1',
      'method_preferences_v1',
    ]) {
      expect(prefs.getString('profile:child:$key'), 'value-$key', reason: key);
    }
  });

  test('Löschen des aktiven Profils bleibt nach Neustart isoliert', () async {
    final controller = AppController();
    await controller.load();
    final firstId = controller.activeProfileId;
    await controller.setNumberRange(NumberRangeLevel.twenty);
    await controller.setSubtractionStrategy(SubtractionStrategy.bridgeToTen);

    await controller.createProfile(
      name: 'Zweites Profil',
      grade: GradeLevel.fourth,
    );
    final deletedId = controller.activeProfileId;
    await controller.setNumberRange(NumberRangeLevel.million);
    await controller.setSubtractionStrategy(SubtractionStrategy.complement);

    final prefsBefore = await SharedPreferences.getInstance();
    await prefsBefore.setString(
      'profile:$deletedId:diagnostics_v1',
      jsonEncode(<Object>[]),
    );

    await controller.deleteProfile(deletedId);

    expect(controller.activeProfileId, firstId);
    expect(controller.numberRange, NumberRangeLevel.twenty);
    expect(
      controller.methodPreferences.subtraction,
      SubtractionStrategy.bridgeToTen,
    );
    final prefsAfter = await SharedPreferences.getInstance();
    expect(
      prefsAfter.getKeys().where(
        (key) => key.startsWith('profile:$deletedId:'),
      ),
      isEmpty,
    );

    final reloaded = AppController();
    await reloaded.load();

    expect(reloaded.activeProfileId, firstId);
    expect(
      reloaded.profiles.map((profile) => profile.id),
      isNot(contains(deletedId)),
    );
    expect(reloaded.numberRange, NumberRangeLevel.twenty);
    expect(
      reloaded.methodPreferences.subtraction,
      SubtractionStrategy.bridgeToTen,
    );
  });
}
