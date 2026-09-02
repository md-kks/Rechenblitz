enum TrainingMode { practice, minus, speed, tempo, blitz, numberFriends }

extension TrainingModeX on TrainingMode {
  String get title => switch (this) {
        TrainingMode.practice => 'Sicher üben',
        TrainingMode.minus => 'Minus üben',
        TrainingMode.speed => 'Schnell rechnen',
        TrainingMode.tempo => 'Tempotest',
        TrainingMode.blitz => '5 Blitzaufgaben',
        TrainingMode.numberFriends => 'Zahlenfreunde',
      };
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
  final double averageResponseMs;

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
        'averageResponseMs': averageResponseMs,
      };

  factory TrainingSessionResult.fromJson(Map<String, dynamic> json) =>
      TrainingSessionResult(
        mode: TrainingMode.values.byName(json['mode'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        total: json['total'] as int,
        correctFirstTry: json['correctFirstTry'] as int,
        incorrectAttempts: json['incorrectAttempts'] as int,
        plusCorrect: json['plusCorrect'] as int,
        plusTotal: json['plusTotal'] as int,
        minusCorrect: json['minusCorrect'] as int,
        minusTotal: json['minusTotal'] as int,
        averageResponseMs: (json['averageResponseMs'] as num).toDouble(),
      );
}
