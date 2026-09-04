enum NumberRangeLevel { ten, twenty, hundred, thousand, tenThousand, million }

extension NumberRangeLevelX on NumberRangeLevel {
  int get maxValue => switch (this) {
        NumberRangeLevel.ten => 10,
        NumberRangeLevel.twenty => 20,
        NumberRangeLevel.hundred => 100,
        NumberRangeLevel.thousand => 1000,
        NumberRangeLevel.tenThousand => 10000,
        NumberRangeLevel.million => 1000000,
      };

  String get label => switch (this) {
        NumberRangeLevel.ten => 'bis 10',
        NumberRangeLevel.twenty => 'bis 20',
        NumberRangeLevel.hundred => 'bis 100',
        NumberRangeLevel.thousand => 'bis 1.000',
        NumberRangeLevel.tenThousand => 'bis 10.000',
        NumberRangeLevel.million => 'bis 1.000.000',
      };
}

enum GradeLevel { first, second, third, fourth }

extension GradeLevelX on GradeLevel {
  int get number => index + 1;

  String get label => 'Klasse $number';

  String get shortLabel => '$number';

  String get description => switch (this) {
        GradeLevel.first => 'Zahlvorstellungen und sichere Grundaufgaben aufbauen.',
        GradeLevel.second =>
          'Zahlenraum bis 100, Grundrechenarten und erste Sach- und Größenaufgaben.',
        GradeLevel.third =>
          'Zahlen erweitern, Rechenstrategien, schriftliche Verfahren und neue Sachbereiche.',
        GradeLevel.fourth =>
          'Sicher bis 1 Million arbeiten und Grundschulwissen vernetzen und anwenden.',
      };

  NumberRangeLevel get recommendedRange => switch (this) {
        GradeLevel.first => NumberRangeLevel.twenty,
        GradeLevel.second => NumberRangeLevel.hundred,
        GradeLevel.third => NumberRangeLevel.thousand,
        GradeLevel.fourth => NumberRangeLevel.million,
      };
}

enum TrainingMode {
  practice,
  minus,
  speed,
  tempo,
  blitz,
  numberFriends,
  multiply,
  divide,
  mixed,
  numberWall,
  missingNumber,
  neighbors,
  placeValue,
  doublesHalves,
  sequences,
  factFamilies,
  wordProblems,
  money,
  clock,
  measures,
  geometry,

  // Klassen 3/4 – Thüringer Grundschulcurriculum.
  largeNumbers,
  rounding,
  mentalStrategies,
  writtenAddSub,
  writtenMultiply,
  writtenDivide,
  estimation,
  arithmeticLaws,
  romanNumerals,
  fractions,
  advancedMeasures,
  timeDurations,
  dataCharts,
  probability,
  combinatorics,
  proportionality,
  perimeterArea,
  geometryBodies,
  symmetry,
  plansAndOrientation,
  volumeCubes,
}

extension TrainingModeX on TrainingMode {
  String get title => switch (this) {
        TrainingMode.practice => 'Plus & Minus',
        TrainingMode.minus => 'Minus üben',
        TrainingMode.speed => 'Schnell rechnen',
        TrainingMode.tempo => 'Rechencheck',
        TrainingMode.blitz => '5 Blitzaufgaben',
        TrainingMode.numberFriends => 'Zahlenfreunde',
        TrainingMode.multiply => 'Malnehmen',
        TrainingMode.divide => 'Teilen',
        TrainingMode.mixed => 'Gemischt rechnen',
        TrainingMode.numberWall => 'Zahlenmauern',
        TrainingMode.missingNumber => 'Lückenaufgaben',
        TrainingMode.neighbors => 'Nachbarzahlen',
        TrainingMode.placeValue => 'Zehner & Einer',
        TrainingMode.doublesHalves => 'Doppelt & Hälfte',
        TrainingMode.sequences => 'Zahlenfolgen',
        TrainingMode.factFamilies => 'Rechenfamilien',
        TrainingMode.wordProblems => 'Sachaufgaben',
        TrainingMode.money => 'Geld',
        TrainingMode.clock => 'Uhrzeit',
        TrainingMode.measures => 'Längen & Größen',
        TrainingMode.geometry => 'Geometrie',
        TrainingMode.largeNumbers => 'Große Zahlen',
        TrainingMode.rounding => 'Runden',
        TrainingMode.mentalStrategies => 'Halbschriftlich rechnen',
        TrainingMode.writtenAddSub => 'Schriftlich + / −',
        TrainingMode.writtenMultiply => 'Schriftlich mal',
        TrainingMode.writtenDivide => 'Schriftlich teilen',
        TrainingMode.estimation => 'Überschlag',
        TrainingMode.arithmeticLaws => 'Rechenvorteile',
        TrainingMode.romanNumerals => 'Römische Zahlen',
        TrainingMode.fractions => 'Bruchteile',
        TrainingMode.advancedMeasures => 'Größen umwandeln',
        TrainingMode.timeDurations => 'Zeitspannen',
        TrainingMode.dataCharts => 'Daten & Diagramme',
        TrainingMode.probability => 'Wahrscheinlichkeit',
        TrainingMode.combinatorics => 'Kombinatorik',
        TrainingMode.proportionality => 'Zuordnungen',
        TrainingMode.perimeterArea => 'Umfang & Fläche',
        TrainingMode.geometryBodies => 'Körper & Netze',
        TrainingMode.symmetry => 'Symmetrie',
        TrainingMode.plansAndOrientation => 'Pläne & Wege',
        TrainingMode.volumeCubes => 'Rauminhalt',
      };

  bool get isStructured =>
      this == TrainingMode.numberWall ||
      this == TrainingMode.missingNumber ||
      this == TrainingMode.neighbors ||
      this == TrainingMode.placeValue ||
      this == TrainingMode.doublesHalves ||
      this == TrainingMode.sequences ||
      this == TrainingMode.factFamilies ||
      this == TrainingMode.wordProblems ||
      this == TrainingMode.money ||
      this == TrainingMode.clock ||
      this == TrainingMode.measures ||
      this == TrainingMode.geometry;

  bool get isUpperPrimary =>
      this == TrainingMode.largeNumbers ||
      this == TrainingMode.rounding ||
      this == TrainingMode.mentalStrategies ||
      this == TrainingMode.writtenAddSub ||
      this == TrainingMode.writtenMultiply ||
      this == TrainingMode.writtenDivide ||
      this == TrainingMode.estimation ||
      this == TrainingMode.arithmeticLaws ||
      this == TrainingMode.romanNumerals ||
      this == TrainingMode.fractions ||
      this == TrainingMode.advancedMeasures ||
      this == TrainingMode.timeDurations ||
      this == TrainingMode.dataCharts ||
      this == TrainingMode.probability ||
      this == TrainingMode.combinatorics ||
      this == TrainingMode.proportionality ||
      this == TrainingMode.perimeterArea ||
      this == TrainingMode.geometryBodies ||
      this == TrainingMode.symmetry ||
      this == TrainingMode.plansAndOrientation ||
      this == TrainingMode.volumeCubes;

  bool get isEverydayMath =>
      this == TrainingMode.wordProblems ||
      this == TrainingMode.money ||
      this == TrainingMode.clock ||
      this == TrainingMode.measures ||
      this == TrainingMode.geometry ||
      this == TrainingMode.advancedMeasures ||
      this == TrainingMode.timeDurations ||
      this == TrainingMode.proportionality ||
      this == TrainingMode.perimeterArea;
}

class TrainingSessionResult {
  TrainingSessionResult({
    required this.mode,
    required this.startedAt,
    required this.finishedAt,
    required this.total,
    required this.correctFirstTry,
    required this.incorrectAttempts,
    required this.plusCorrect,
    required this.plusTotal,
    required this.minusCorrect,
    required this.minusTotal,
    required this.averageResponseMs,
    this.multiplyCorrect = 0,
    this.multiplyTotal = 0,
    this.divideCorrect = 0,
    this.divideTotal = 0,
    this.numberRange = NumberRangeLevel.ten,
    this.gradeLevel = GradeLevel.second,
    this.starsEarned = 1,
    this.isAssessment = false,
  });

  final TrainingMode mode;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int total;
  final int correctFirstTry;
  final int incorrectAttempts;
  final int plusCorrect;
  final int plusTotal;
  final int minusCorrect;
  final int minusTotal;
  final int multiplyCorrect;
  final int multiplyTotal;
  final int divideCorrect;
  final int divideTotal;
  final double averageResponseMs;
  final NumberRangeLevel numberRange;
  final GradeLevel gradeLevel;
  final int starsEarned;
  final bool isAssessment;

  double get accuracy => total == 0 ? 0 : correctFirstTry / total;

  TrainingSessionResult copyWith({int? starsEarned}) => TrainingSessionResult(
        mode: mode,
        startedAt: startedAt,
        finishedAt: finishedAt,
        total: total,
        correctFirstTry: correctFirstTry,
        incorrectAttempts: incorrectAttempts,
        plusCorrect: plusCorrect,
        plusTotal: plusTotal,
        minusCorrect: minusCorrect,
        minusTotal: minusTotal,
        multiplyCorrect: multiplyCorrect,
        multiplyTotal: multiplyTotal,
        divideCorrect: divideCorrect,
        divideTotal: divideTotal,
        averageResponseMs: averageResponseMs,
        numberRange: numberRange,
        gradeLevel: gradeLevel,
        starsEarned: starsEarned ?? this.starsEarned,
        isAssessment: isAssessment,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'total': total,
        'correctFirstTry': correctFirstTry,
        'incorrectAttempts': incorrectAttempts,
        'plusCorrect': plusCorrect,
        'plusTotal': plusTotal,
        'minusCorrect': minusCorrect,
        'minusTotal': minusTotal,
        'multiplyCorrect': multiplyCorrect,
        'multiplyTotal': multiplyTotal,
        'divideCorrect': divideCorrect,
        'divideTotal': divideTotal,
        'averageResponseMs': averageResponseMs,
        'numberRange': numberRange.name,
        'gradeLevel': gradeLevel.name,
        'starsEarned': starsEarned,
        'isAssessment': isAssessment,
      };

  factory TrainingSessionResult.fromJson(Map<String, dynamic> json) =>
      TrainingSessionResult(
        mode: TrainingMode.values.byName(json['mode'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        total: json['total'] as int,
        correctFirstTry: json['correctFirstTry'] as int,
        incorrectAttempts: json['incorrectAttempts'] as int,
        plusCorrect: json['plusCorrect'] as int? ?? 0,
        plusTotal: json['plusTotal'] as int? ?? 0,
        minusCorrect: json['minusCorrect'] as int? ?? 0,
        minusTotal: json['minusTotal'] as int? ?? 0,
        multiplyCorrect: json['multiplyCorrect'] as int? ?? 0,
        multiplyTotal: json['multiplyTotal'] as int? ?? 0,
        divideCorrect: json['divideCorrect'] as int? ?? 0,
        divideTotal: json['divideTotal'] as int? ?? 0,
        averageResponseMs:
            (json['averageResponseMs'] as num?)?.toDouble() ?? 0,
        numberRange: json['numberRange'] == null
            ? NumberRangeLevel.ten
            : NumberRangeLevel.values.byName(json['numberRange'] as String),
        gradeLevel: json['gradeLevel'] == null
            ? GradeLevel.second
            : GradeLevel.values.byName(json['gradeLevel'] as String),
        starsEarned: json['starsEarned'] as int? ?? 1,
        isAssessment: json['isAssessment'] as bool? ?? false,
      );
}
