enum NumberRangeLevel { ten, twenty, hundred }

extension NumberRangeLevelX on NumberRangeLevel {
  int get maxValue => switch (this) {
        NumberRangeLevel.ten => 10,
        NumberRangeLevel.twenty => 20,
        NumberRangeLevel.hundred => 100,
      };

  String get label => 'bis $maxValue';
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
      };

  bool get isStructured =>
      this == TrainingMode.numberWall ||
      this == TrainingMode.missingNumber ||
      this == TrainingMode.neighbors ||
      this == TrainingMode.placeValue ||
      this == TrainingMode.doublesHalves ||
      this == TrainingMode.sequences ||
      this == TrainingMode.factFamilies;
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
    this.starsEarned = 1,
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
  final int starsEarned;

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
        starsEarned: starsEarned ?? this.starsEarned,
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
        'starsEarned': starsEarned,
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
        starsEarned: json['starsEarned'] as int? ?? 1,
      );
}
