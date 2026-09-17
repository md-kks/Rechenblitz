import '../learning_subject.dart';

class SubjectStorageKeyspace {
  const SubjectStorageKeyspace(this.subject);

  final LearningSubject subject;

  String profileKey(String profileId, String key) {
    if (subject == LearningSubject.mathematics) {
      // Rechenblitz must keep its existing local keys unchanged.
      return 'profile:$profileId:$key';
    }
    return 'profile:$profileId:subject:${subject.storageKey}:$key';
  }

  static String anySubjectProfilePrefix(String profileId) =>
      'profile:$profileId:';
}
