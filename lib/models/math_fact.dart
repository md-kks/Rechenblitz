import 'dart:math';

enum MathOperation { plus, minus, multiply, divide }

extension MathOperationX on MathOperation {
  String get symbol => switch (this) {
        MathOperation.plus => '+',
        MathOperation.minus => '−',
        MathOperation.multiply => '×',
        MathOperation.divide => '÷',
      };

  String get title => switch (this) {
        MathOperation.plus => 'Plus',
        MathOperation.minus => 'Minus',
        MathOperation.multiply => 'Mal',
        MathOperation.divide => 'Geteilt',
      };
}

class MathFact {
  MathFact({
    required this.a,
    required this.b,
    required this.operation,
    this.attempts = 0,
    this.correctAttempts = 0,
    this.incorrectAttempts = 0,
    this.averageResponseMs = 0,
    this.lastResponseMs = 0,
    this.helpCount = 0,
    this.lastPracticed,
  });

  final int a;
  final int b;
  final MathOperation operation;
  int attempts;
  int correctAttempts;
  int incorrectAttempts;
  double averageResponseMs;
  int lastResponseMs;
  int helpCount;
  DateTime? lastPracticed;

  int get result => switch (operation) {
        MathOperation.plus => a + b,
        MathOperation.minus => a - b,
        MathOperation.multiply => a * b,
        MathOperation.divide => b == 0 ? 0 : a ~/ b,
      };

  String get key => '${operation.name}:$a:$b';
  String get symbol => operation.symbol;
  String get label => '$a $symbol $b';
  bool get isPlus => operation == MathOperation.plus;
  bool get isMinus => operation == MathOperation.minus;
  bool get isMultiply => operation == MathOperation.multiply;
  bool get isDivide => operation == MathOperation.divide;

  double get accuracy => attempts == 0 ? 0.5 : correctAttempts / attempts;

  /// 0 = noch unsicher, 1 = sehr sicher. Sicherheit zählt stärker als Tempo.
  double get masteryScore {
    if (attempts == 0) return 0.18;
    final accuracyScore = accuracy;
    final speedScore =
        (1 - ((averageResponseMs - 1800) / 8200)).clamp(0.0, 1.0).toDouble();
    final repetitionScore =
        (correctAttempts / 6).clamp(0.0, 1.0).toDouble();
    final helpPenalty =
        (helpCount / max(1, attempts)).clamp(0.0, 1.0).toDouble();
    return (accuracyScore * 0.58 +
            speedScore * 0.18 +
            repetitionScore * 0.24 -
            helpPenalty * 0.16)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void registerAttempt({
    required bool correct,
    required Duration responseTime,
    required bool usedHelp,
  }) {
    final boundedMs = min(responseTime.inMilliseconds, 30000);
    attempts += 1;
    if (correct) {
      correctAttempts += 1;
    } else {
      incorrectAttempts += 1;
    }
    if (usedHelp) helpCount += 1;
    lastResponseMs = boundedMs;
    averageResponseMs = attempts == 1
        ? boundedMs.toDouble()
        : ((averageResponseMs * (attempts - 1)) + boundedMs) / attempts;
    lastPracticed = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'a': a,
        'b': b,
        'operation': operation.name,
        'attempts': attempts,
        'correctAttempts': correctAttempts,
        'incorrectAttempts': incorrectAttempts,
        'averageResponseMs': averageResponseMs,
        'lastResponseMs': lastResponseMs,
        'helpCount': helpCount,
        'lastPracticed': lastPracticed?.toIso8601String(),
      };

  factory MathFact.fromJson(Map<String, dynamic> json) => MathFact(
        a: json['a'] as int,
        b: json['b'] as int,
        operation: MathOperation.values.byName(json['operation'] as String),
        attempts: json['attempts'] as int? ?? 0,
        correctAttempts: json['correctAttempts'] as int? ?? 0,
        incorrectAttempts: json['incorrectAttempts'] as int? ?? 0,
        averageResponseMs:
            (json['averageResponseMs'] as num?)?.toDouble() ?? 0,
        lastResponseMs: json['lastResponseMs'] as int? ?? 0,
        helpCount: json['helpCount'] as int? ?? 0,
        lastPracticed: json['lastPracticed'] == null
            ? null
            : DateTime.tryParse(json['lastPracticed'] as String),
      );
}
