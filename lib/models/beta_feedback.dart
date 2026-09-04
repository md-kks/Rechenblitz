enum BetaTesterRole { child, parent, teacher }

extension BetaTesterRoleX on BetaTesterRole {
  String get label => switch (this) {
        BetaTesterRole.child => 'Kind',
        BetaTesterRole.parent => 'Elternteil',
        BetaTesterRole.teacher => 'Lehrkraft / Pädagogik',
      };
}

enum BetaFeedbackArea {
  tasks,
  explanations,
  myRound,
  teacherMode,
  accessibility,
  navigation,
  other,
}

extension BetaFeedbackAreaX on BetaFeedbackArea {
  String get label => switch (this) {
        BetaFeedbackArea.tasks => 'Aufgaben & Varianz',
        BetaFeedbackArea.explanations => 'Hilfen & Rechenwege',
        BetaFeedbackArea.myRound => 'Meine Runde',
        BetaFeedbackArea.teacherMode => 'Schul-/QR-Modus',
        BetaFeedbackArea.accessibility => 'Lesen & Darstellung',
        BetaFeedbackArea.navigation => 'Bedienung',
        BetaFeedbackArea.other => 'Sonstiges',
      };
}

class BetaFeedbackEntry {
  const BetaFeedbackEntry({
    required this.createdAt,
    required this.role,
    required this.area,
    required this.rating,
    required this.note,
  });

  final DateTime createdAt;
  final BetaTesterRole role;
  final BetaFeedbackArea area;
  final int rating;
  final String note;

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt.toIso8601String(),
        'role': role.name,
        'area': area.name,
        'rating': rating,
        'note': note,
      };

  factory BetaFeedbackEntry.fromJson(Map<String, dynamic> json) =>
      BetaFeedbackEntry(
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime(2026, 1, 1),
        role: BetaTesterRole.values.byName(json['role'] as String),
        area: BetaFeedbackArea.values.byName(json['area'] as String),
        rating: (json['rating'] as num?)?.toInt() ?? 3,
        note: json['note'] as String? ?? '',
      );
}
