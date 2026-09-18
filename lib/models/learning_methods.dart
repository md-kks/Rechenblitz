enum MethodSelectionPreference { schoolMethod, automatic }

extension MethodSelectionPreferenceX on MethodSelectionPreference {
  String get label => switch (this) {
        MethodSelectionPreference.schoolMethod => 'Schulmethode',
        MethodSelectionPreference.automatic => 'Automatisch / weiß ich nicht',
      };
}

enum AdditionStrategy { bridgeToTen, compensate }

extension AdditionStrategyX on AdditionStrategy {
  String get label => switch (this) {
        AdditionStrategy.bridgeToTen => 'Erst zum Zehner',
        AdditionStrategy.compensate => 'Runden & ausgleichen',
      };

  String get description => switch (this) {
        AdditionStrategy.bridgeToTen =>
          'Den zweiten Summanden so zerlegen, dass zuerst der nächste volle Zehner erreicht wird.',
        AdditionStrategy.compensate =>
          'Den zweiten Summanden zum nächsten Zehner aufrunden, die leichtere Hilfsaufgabe rechnen und den Überschuss wieder abziehen.',
      };
}

enum SubtractionStrategy { bridgeToTen, takeAway, complement }

extension SubtractionStrategyX on SubtractionStrategy {
  String get label => switch (this) {
        SubtractionStrategy.bridgeToTen => 'Erst zum Zehner',
        SubtractionStrategy.takeAway => 'Schrittweise wegnehmen',
        SubtractionStrategy.complement => 'Ergänzen',
      };

  String get description => switch (this) {
        SubtractionStrategy.bridgeToTen =>
          'Bis zum nächsten Zehner rechnen und danach den Rest abziehen.',
        SubtractionStrategy.takeAway =>
          'Den Subtrahenden in passende Schritte zerlegen und nacheinander wegnehmen.',
        SubtractionStrategy.complement =>
          'Von der kleineren Zahl aus bis zur größeren ergänzen.',
      };
}

enum MultiplicationStrategy { groups, decompose, neighborFacts }

extension MultiplicationStrategyX on MultiplicationStrategy {
  String get label => switch (this) {
        MultiplicationStrategy.groups => 'Gleich große Gruppen',
        MultiplicationStrategy.decompose => 'Zerlegen',
        MultiplicationStrategy.neighborFacts => 'Nachbaraufgaben',
      };

  String get description => switch (this) {
        MultiplicationStrategy.groups =>
          'Malaufgaben als gleich große Gruppen oder Punktefelder verstehen.',
        MultiplicationStrategy.decompose =>
          'Einen Faktor zerlegen und Teilprodukte zusammenrechnen.',
        MultiplicationStrategy.neighborFacts =>
          'Von bekannten Aufgaben wie ×5 oder ×10 zu Nachbaraufgaben gelangen.',
      };
}

enum WrittenSubtractionStrategy { regroup, complement }

extension WrittenSubtractionStrategyX on WrittenSubtractionStrategy {
  String get label => switch (this) {
        WrittenSubtractionStrategy.regroup => 'Entbündeln',
        WrittenSubtractionStrategy.complement => 'Ergänzungsverfahren',
      };

  String get description => switch (this) {
        WrittenSubtractionStrategy.regroup =>
          'Bei Bedarf einen höheren Stellenwert entbündeln und dann Stelle für Stelle abziehen.',
        WrittenSubtractionStrategy.complement =>
          'Stelle für Stelle ergänzen und Überträge nach dem in der Schule genutzten Ergänzungsverfahren notieren.',
      };
}

class MethodPreferences {
  const MethodPreferences({
    this.addition = AdditionStrategy.bridgeToTen,
    this.subtraction = SubtractionStrategy.bridgeToTen,
    this.multiplication = MultiplicationStrategy.groups,
    this.writtenSubtraction = WrittenSubtractionStrategy.regroup,
    this.selectionPreference = MethodSelectionPreference.schoolMethod,
  });

  final AdditionStrategy addition;
  final SubtractionStrategy subtraction;
  final MultiplicationStrategy multiplication;
  final WrittenSubtractionStrategy writtenSubtraction;
  final MethodSelectionPreference selectionPreference;

  MethodPreferences copyWith({
    AdditionStrategy? addition,
    SubtractionStrategy? subtraction,
    MultiplicationStrategy? multiplication,
    WrittenSubtractionStrategy? writtenSubtraction,
    MethodSelectionPreference? selectionPreference,
  }) =>
      MethodPreferences(
        addition: addition ?? this.addition,
        subtraction: subtraction ?? this.subtraction,
        multiplication: multiplication ?? this.multiplication,
        writtenSubtraction: writtenSubtraction ?? this.writtenSubtraction,
        selectionPreference: selectionPreference ?? this.selectionPreference,
      );

  Map<String, dynamic> toJson() => {
        'addition': addition.name,
        'subtraction': subtraction.name,
        'multiplication': multiplication.name,
        'writtenSubtraction': writtenSubtraction.name,
        'selectionPreference': selectionPreference.name,
      };

  factory MethodPreferences.fromJson(Map<String, dynamic> json) =>
      MethodPreferences(
        addition: AdditionStrategy.values.firstWhere(
          (value) => value.name == json['addition'],
          orElse: () => AdditionStrategy.bridgeToTen,
        ),
        subtraction: SubtractionStrategy.values.firstWhere(
          (value) => value.name == json['subtraction'],
          orElse: () => SubtractionStrategy.bridgeToTen,
        ),
        multiplication: MultiplicationStrategy.values.firstWhere(
          (value) => value.name == json['multiplication'],
          orElse: () => MultiplicationStrategy.groups,
        ),
        writtenSubtraction: WrittenSubtractionStrategy.values.firstWhere(
          (value) => value.name == json['writtenSubtraction'],
          orElse: () => WrittenSubtractionStrategy.regroup,
        ),
        selectionPreference: MethodSelectionPreference.values.firstWhere(
          (value) => value.name == json['selectionPreference'],
          orElse: () => MethodSelectionPreference.schoolMethod,
        ),
      );
  AdditionStrategy effectiveAddition({required String taskKey}) {
    if (selectionPreference == MethodSelectionPreference.schoolMethod) {
      return addition;
    }
    // Der Zehnerstopp ist der sichere automatische Einstieg. Weitere Wege
    // bleiben in der geöffneten Hilfe bewusst auswählbar.
    return AdditionStrategy.bridgeToTen;
  }

  SubtractionStrategy effectiveSubtraction({required String taskKey}) {
    if (selectionPreference == MethodSelectionPreference.schoolMethod) {
      return subtraction;
    }
    final variants = SubtractionStrategy.values;
    return variants[taskKey.hashCode.abs() % variants.length];
  }

  MultiplicationStrategy effectiveMultiplication({required String taskKey}) {
    if (selectionPreference == MethodSelectionPreference.schoolMethod) {
      return multiplication;
    }
    final variants = MultiplicationStrategy.values;
    return variants[taskKey.hashCode.abs() % variants.length];
  }

  String get selectionLabel => selectionPreference.label;

}
