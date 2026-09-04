import 'training.dart';

class LearnerProfile {
  const LearnerProfile({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.createdAt,
  });

  final String id;
  final String name;
  final GradeLevel gradeLevel;
  final DateTime createdAt;

  LearnerProfile copyWith({
    String? name,
    GradeLevel? gradeLevel,
  }) =>
      LearnerProfile(
        id: id,
        name: name ?? this.name,
        gradeLevel: gradeLevel ?? this.gradeLevel,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gradeLevel': gradeLevel.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    final rawGrade = json['gradeLevel'] as String?;
    GradeLevel? grade;
    for (final value in GradeLevel.values) {
      if (value.name == rawGrade) {
        grade = value;
        break;
      }
    }
    return LearnerProfile(
      id: json['id'] as String? ?? 'default',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Lernprofil',
      gradeLevel: grade ?? GradeLevel.second,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime(2026, 1, 1),
    );
  }
}
