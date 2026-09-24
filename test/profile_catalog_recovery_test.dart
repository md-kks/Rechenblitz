import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/help_preferences.dart';
import 'package:rechenblitz/models/learner_profile.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test(
    'beschädigter Profilkatalog wird exakt aus Sicherheitskopie repariert',
    () async {
      final profile = LearnerProfile(
        id: 'p_1790251200000000',
        name: 'Mia',
        gradeLevel: GradeLevel.third,
        createdAt: DateTime(2026, 9, 24, 12),
        state: GermanState.bavaria,
        onboardingComplete: true,
        assessmentCompletedAt: DateTime(2026, 9, 23, 18),
        helpPreferences: const HelpPreferences(
          access: HelpAccess.hintOnly,
          presentation: HelpPresentation.direct,
        ),
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'learner_profiles_v1': '{kaputt',
        'learner_profiles_backup_v1': jsonEncode(<Object>[profile.toJson()]),
        'active_learner_profile_v1': profile.id,
        'profile:${profile.id}:grade_level_v1': GradeLevel.third.name,
        'profile:${profile.id}:number_range_v1': NumberRangeLevel.thousand.name,
      });

      final storage = StorageService();
      final restored = await storage.initializeProfiles();

      expect(restored, hasLength(1));
      expect(restored.single.id, profile.id);
      expect(restored.single.name, 'Mia');
      expect(restored.single.gradeLevel, GradeLevel.third);
      expect(restored.single.state, GermanState.bavaria);
      expect(
        restored.single.assessmentCompletedAt,
        profile.assessmentCompletedAt,
      );
      expect(
        restored.single.helpPreferences.access,
        profile.helpPreferences.access,
      );
      expect(
        restored.single.helpPreferences.presentation,
        profile.helpPreferences.presentation,
      );
      expect(storage.activeProfileId, profile.id);

      final prefs = await SharedPreferences.getInstance();
      final primary = prefs.getString('learner_profiles_v1');
      final backup = prefs.getString('learner_profiles_backup_v1');
      expect(primary, isNotNull);
      expect(primary, backup);
      final decoded = jsonDecode(primary!) as List<dynamic>;
      expect(decoded, hasLength(1));
      expect(
        LearnerProfile.fromJson(
          Map<String, dynamic>.from(decoded.single as Map<dynamic, dynamic>),
        ).name,
        'Mia',
      );
    },
  );

  test(
    'verwaiste Profildaten werden ohne intakten Katalog wieder zugänglich',
    () async {
      final created = DateTime(2026, 9, 20, 8, 30);
      final activeId = 'p_${created.microsecondsSinceEpoch}';
      const secondId = 'legacy_child';
      final fact = MathFact(a: 9, b: 6, operation: MathOperation.minus);
      fact.registerAttempt(
        correct: true,
        responseTime: const Duration(seconds: 2),
        usedHelp: false,
      );

      SharedPreferences.setMockInitialValues(<String, Object>{
        'learner_profiles_v1': 'defekt',
        'learner_profiles_backup_v1': '[auch defekt',
        'active_learner_profile_v1': activeId,
        'profile:$activeId:grade_level_v1': GradeLevel.fourth.name,
        'profile:$activeId:number_range_v1': NumberRangeLevel.million.name,
        'profile:$activeId:facts_v1': jsonEncode(<Object>[fact.toJson()]),
        'profile:$secondId:grade_level_v1': GradeLevel.second.name,
        'profile:$secondId:history_v1': '[]',
        'profile:bad!id:facts_v1': '[]',
        'profile:ohne_trenner': 'ignorieren',
      });

      final storage = StorageService();
      final restored = await storage.initializeProfiles();

      expect(restored.map((profile) => profile.id), <String>[
        activeId,
        secondId,
      ]);
      expect(storage.activeProfileId, activeId);
      expect(restored.first.gradeLevel, GradeLevel.fourth);
      expect(restored.first.name, startsWith('Wiederhergestelltes Profil'));
      expect(restored.first.onboardingComplete, isTrue);
      expect(restored.first.createdAt.year, created.year);
      expect(restored.first.createdAt.month, created.month);
      expect(restored.first.createdAt.day, created.day);
      expect(restored[1].gradeLevel, GradeLevel.second);
      expect(restored.map((profile) => profile.id), isNot(contains('bad!id')));

      final facts = await storage.loadFacts();
      expect(facts.keys, contains(fact.key));
      expect(facts[fact.key]!.attempts, 1);
      expect(await storage.numberRange(), NumberRangeLevel.million);

      final prefs = await SharedPreferences.getInstance();
      final primary = prefs.getString('learner_profiles_v1');
      final backup = prefs.getString('learner_profiles_backup_v1');
      expect(primary, isNotNull);
      expect(primary, backup);
      expect((jsonDecode(primary!) as List<dynamic>), hasLength(2));

      final secondStorage = StorageService();
      final secondLoad = await secondStorage.initializeProfiles();
      expect(secondLoad.map((profile) => profile.id), <String>[
        activeId,
        secondId,
      ]);
      expect(secondStorage.activeProfileId, activeId);
    },
  );
}
