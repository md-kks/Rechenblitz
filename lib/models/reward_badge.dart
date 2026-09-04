import 'training.dart';

class RewardBadge {
  const RewardBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.stars,
    required this.iconKey,
  });

  final String id;
  final String title;
  final String description;
  final int stars;
  final String iconKey;
}

class RewardCatalog {
  const RewardCatalog._();

  static RewardBadge fromId(String id) {
    if (id == 'explorer') {
      return const RewardBadge(
        id: 'explorer',
        title: 'Entdecker',
        description: 'Fünf verschiedene Lernwelten ausprobiert.',
        stars: 2,
        iconKey: 'explore',
      );
    }
    if (id == 'courage') {
      return const RewardBadge(
        id: 'courage',
        title: 'Drangeblieben',
        description: 'Auch nach schwierigen Aufgaben eine Runde zu Ende gebracht.',
        stars: 2,
        iconKey: 'courage',
      );
    }
    if (id == 'weak_spot') {
      return const RewardBadge(
        id: 'weak_spot',
        title: 'Knacknuss geknackt',
        description: 'Eine zuvor unsichere Rechenaufgabe sicher gemeistert.',
        stars: 3,
        iconKey: 'weak_spot',
      );
    }
    if (id.startsWith('grade:')) {
      final name = id.substring('grade:'.length);
      final grade = GradeLevel.values.firstWhere(
        (value) => value.name == name,
        orElse: () => GradeLevel.second,
      );
      final stars = switch (grade) {
        GradeLevel.first => 4,
        GradeLevel.second => 5,
        GradeLevel.third => 7,
        GradeLevel.fourth => 9,
      };
      return RewardBadge(
        id: id,
        title: '${grade.label} gemeistert',
        description:
            'In ${grade.label} wurden mehrere Lehrplanbereiche sicher bearbeitet.',
        stars: stars,
        iconKey: 'grade',
      );
    }
    if (id.startsWith('range:')) {
      final name = id.substring('range:'.length);
      final range = NumberRangeLevel.values.firstWhere(
        (value) => value.name == name,
        orElse: () => NumberRangeLevel.ten,
      );
      return RewardBadge(
        id: id,
        title: 'Zahlenraum ${range.label}',
        description: 'Im Zahlenraum ${range.label} über mehrere Runden sicher gerechnet.',
        stars: switch (range) {
          NumberRangeLevel.ten => 3,
          NumberRangeLevel.twenty => 3,
          NumberRangeLevel.hundred => 5,
          NumberRangeLevel.thousand => 6,
          NumberRangeLevel.tenThousand => 7,
          NumberRangeLevel.million => 8,
        },
        iconKey: 'range',
      );
    }
    if (id.startsWith('operation:')) {
      final name = id.substring('operation:'.length);
      final titles = <String, String>{
        'plus': 'Plus-Profi',
        'minus': 'Minus-Profi',
        'multiply': 'Einmaleins-Profi',
        'divide': 'Teilen-Profi',
      };
      return RewardBadge(
        id: id,
        title: titles[name] ?? 'Rechen-Profi',
        description: 'Diese Rechenart wurde über viele Aufgaben hinweg sicher gelöst.',
        stars: 3,
        iconKey: 'operation',
      );
    }
    if (id.startsWith('mastery:')) {
      final parts = id.split(':');
      if (parts.length == 3) {
        final mode = TrainingMode.values.firstWhere(
          (value) => value.name == parts[1],
          orElse: () => TrainingMode.practice,
        );
        final range = NumberRangeLevel.values.firstWhere(
          (value) => value.name == parts[2],
          orElse: () => NumberRangeLevel.ten,
        );
        return RewardBadge(
          id: id,
          title: '${mode.title} gemeistert',
          description: '${mode.title} wurde ${range.label} in mehreren Runden sicher gelöst.',
          stars: 2,
          iconKey: 'mastery',
        );
      }
    }
    return RewardBadge(
      id: id,
      title: 'Erfolg',
      description: 'Ein Lernziel wurde erreicht.',
      stars: 1,
      iconKey: 'star',
    );
  }
}
