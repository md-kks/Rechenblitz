import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/accessibility_preferences.dart';
import 'package:rechenblitz/core/assignments/subject_assignment_envelope.dart';
import 'package:rechenblitz/core/learning_app_theme.dart';
import 'package:rechenblitz/core/learning_subject.dart';
import 'package:rechenblitz/core/storage/subject_storage_keyspace.dart';
import 'package:rechenblitz/services/storage_service.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('subject ids and labels stay stable', () {
    expect(LearningSubject.mathematics.storageKey, 'math');
    expect(LearningSubject.mathematics.label, 'Mathematik');
    expect(LearningSubject.german.storageKey, 'german');
    expect(LearningSubject.german.label, 'Deutsch');
  });

  test('German and math have separate visual identities', () {
    final math = LearningSubject.mathematics.visuals;
    final german = LearningSubject.german.visuals;
    expect(math.seedColor, isNot(german.seedColor));
    expect(german.seedColor.r, greaterThan(german.seedColor.b));
  });

  test('subject storage keeps existing math keys and isolates German', () {
    const math = SubjectStorageKeyspace(LearningSubject.mathematics);
    const german = SubjectStorageKeyspace(LearningSubject.german);

    expect(math.profileKey('child', 'history_v1'), 'profile:child:history_v1');
    expect(
      german.profileKey('child', 'history_v1'),
      'profile:child:subject:german:history_v1',
    );
    expect(
      SubjectStorageKeyspace.anySubjectProfilePrefix('child'),
      'profile:child:',
    );
  });

  test('shared theme guarantees touch-sized controls', () {
    final theme = LearningAppTheme.build(
      subject: LearningSubject.german,
      accessibility: const AccessibilityPreferences(),
    );
    final filledSize = theme.filledButtonTheme.style!.minimumSize!.resolve(
      <WidgetState>{},
    )!;
    final iconSize = theme.iconButtonTheme.style!.minimumSize!.resolve(
      <WidgetState>{},
    )!;

    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(filledSize.height, greaterThanOrEqualTo(54));
    expect(iconSize.width, greaterThanOrEqualTo(48));
    expect(iconSize.height, greaterThanOrEqualTo(48));
  });

  test('German module has six learning domains', () {
    expect(GermanLearningDomain.values, hasLength(6));
    expect(GermanLearningDomain.reading.label, 'Lesen');
    expect(GermanLearningDomain.spelling.label, 'Rechtschreibung');
    expect(GermanLearningDomain.writing.label, 'Schreiben');
  });
  test('offline assignment envelope round-trips German without a server', () {
    final assignment = SubjectAssignmentEnvelope(
      subject: LearningSubject.german,
      data: <String, dynamic>{
        'grade': 'second',
        'domain': 'reading',
        'tasks': 12,
      },
    );

    final restored = SubjectAssignmentEnvelope.tryParse(assignment.toPayload());
    expect(restored, isNotNull);
    expect(restored!.subject, LearningSubject.german);
    expect(restored.data, assignment.data);
    expect(restored.assignmentId, assignment.assignmentId);
  });

  test('offline assignment envelope rejects unknown or broken payloads', () {
    expect(SubjectAssignmentEnvelope.tryParse('not-a-learning-qr'), isNull);
    expect(SubjectAssignmentEnvelope.tryParse('LB1:broken'), isNull);
  });
  test(
    'deleting a profile clears math and future German subject data',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profile:child:history_v1': 'math-data',
        'profile:child:subject:german:history_v1': 'german-data',
        'sound_enabled': true,
      });
      final storage = StorageService();

      await storage.deleteProfileData('child');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('profile:child:history_v1'), isFalse);
      expect(
        prefs.containsKey('profile:child:subject:german:history_v1'),
        isFalse,
      );
      expect(prefs.getBool('sound_enabled'), isTrue);
    },
  );
}
