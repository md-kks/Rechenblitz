import 'guided_method.dart';

enum HelpAccess { all, hintAndVisual, hintOnly, none }

enum HelpPresentation { progressive, direct }

extension HelpAccessX on HelpAccess {
  String get label => switch (this) {
    HelpAccess.all => 'Alle Hilfen',
    HelpAccess.hintAndVisual => 'Hinweis + Darstellung',
    HelpAccess.hintOnly => 'Nur Denkhinweis',
    HelpAccess.none => 'Keine Hilfen',
  };

  HelpLevel? get maxLevel => switch (this) {
    HelpAccess.all => HelpLevel.guided,
    HelpAccess.hintAndVisual => HelpLevel.visual,
    HelpAccess.hintOnly => HelpLevel.nudge,
    HelpAccess.none => null,
  };
}

extension HelpPresentationX on HelpPresentation {
  String get label => switch (this) {
    HelpPresentation.progressive => 'Stufenweise',
    HelpPresentation.direct => 'Vollständige Hilfe sofort',
  };
}

class HelpPreferences {
  const HelpPreferences({
    this.access = HelpAccess.all,
    this.presentation = HelpPresentation.progressive,
  });

  final HelpAccess access;
  final HelpPresentation presentation;

  bool get enabled => access.maxLevel != null;
  HelpLevel? get maxLevel => access.maxLevel;

  HelpLevel? clamp(HelpLevel requested) {
    final maximum = maxLevel;
    if (maximum == null) return null;
    return requested.index <= maximum.index ? requested : maximum;
  }

  HelpLevel? get manualStartLevel {
    final maximum = maxLevel;
    if (maximum == null) return null;
    return presentation == HelpPresentation.direct ? maximum : HelpLevel.nudge;
  }

  HelpLevel? automaticStartLevel(HelpLevel requested) {
    if (presentation == HelpPresentation.direct) return maxLevel;
    return clamp(requested);
  }

  HelpPreferences copyWith({
    HelpAccess? access,
    HelpPresentation? presentation,
  }) => HelpPreferences(
    access: access ?? this.access,
    presentation: presentation ?? this.presentation,
  );

  Map<String, dynamic> toJson() => {
    'access': access.name,
    'presentation': presentation.name,
  };

  factory HelpPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HelpPreferences();
    final access = HelpAccess.values.where(
      (value) => value.name == json['access'],
    );
    final presentation = HelpPresentation.values.where(
      (value) => value.name == json['presentation'],
    );
    return HelpPreferences(
      access: access.isEmpty ? HelpAccess.all : access.first,
      presentation: presentation.isEmpty
          ? HelpPresentation.progressive
          : presentation.first,
    );
  }
}
