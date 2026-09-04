import 'training.dart';

enum GermanState {
  badenWuerttemberg,
  bavaria,
  berlin,
  brandenburg,
  bremen,
  hamburg,
  hesse,
  mecklenburgVorpommern,
  lowerSaxony,
  northRhineWestphalia,
  rhinelandPalatinate,
  saarland,
  saxony,
  saxonyAnhalt,
  schleswigHolstein,
  thuringia,
}

extension GermanStateX on GermanState {
  String get label => switch (this) {
        GermanState.badenWuerttemberg => 'Baden-Württemberg',
        GermanState.bavaria => 'Bayern',
        GermanState.berlin => 'Berlin',
        GermanState.brandenburg => 'Brandenburg',
        GermanState.bremen => 'Bremen',
        GermanState.hamburg => 'Hamburg',
        GermanState.hesse => 'Hessen',
        GermanState.mecklenburgVorpommern => 'Mecklenburg-Vorpommern',
        GermanState.lowerSaxony => 'Niedersachsen',
        GermanState.northRhineWestphalia => 'Nordrhein-Westfalen',
        GermanState.rhinelandPalatinate => 'Rheinland-Pfalz',
        GermanState.saarland => 'Saarland',
        GermanState.saxony => 'Sachsen',
        GermanState.saxonyAnhalt => 'Sachsen-Anhalt',
        GermanState.schleswigHolstein => 'Schleswig-Holstein',
        GermanState.thuringia => 'Thüringen',
      };
}

class LearnerProfile {
  const LearnerProfile({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.createdAt,
    this.state = GermanState.thuringia,
    this.onboardingComplete = true,
    this.assessmentCompletedAt,
  });

  final String id;
  final String name;
  final GradeLevel gradeLevel;
  final DateTime createdAt;
  final GermanState state;
  final bool onboardingComplete;
  final DateTime? assessmentCompletedAt;

  LearnerProfile copyWith({
    String? name,
    GradeLevel? gradeLevel,
    GermanState? state,
    bool? onboardingComplete,
    DateTime? assessmentCompletedAt,
    bool clearAssessment = false,
  }) =>
      LearnerProfile(
        id: id,
        name: name ?? this.name,
        gradeLevel: gradeLevel ?? this.gradeLevel,
        createdAt: createdAt,
        state: state ?? this.state,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        assessmentCompletedAt: clearAssessment
            ? null
            : assessmentCompletedAt ?? this.assessmentCompletedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gradeLevel': gradeLevel.name,
        'createdAt': createdAt.toIso8601String(),
        'state': state.name,
        'onboardingComplete': onboardingComplete,
        'assessmentCompletedAt': assessmentCompletedAt?.toIso8601String(),
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

    final rawState = json['state'] as String?;
    var state = GermanState.thuringia;
    for (final value in GermanState.values) {
      if (value.name == rawState) {
        state = value;
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
      state: state,
      // Profiles created by versions before Lernstart are considered complete
      // so existing users are never forced through a new onboarding flow.
      onboardingComplete: json['onboardingComplete'] as bool? ?? true,
      assessmentCompletedAt:
          DateTime.tryParse(json['assessmentCompletedAt'] as String? ?? ''),
    );
  }
}
