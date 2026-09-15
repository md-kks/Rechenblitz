import 'training.dart';

enum AdaptiveSegmentStopKind { confirmed, overload }

extension AdaptiveSegmentStopKindX on AdaptiveSegmentStopKind {
  String get label => switch (this) {
    AdaptiveSegmentStopKind.confirmed => 'Schon sicher bestätigt',
    AdaptiveSegmentStopKind.overload => 'Für heute genug',
  };
}

class AdaptiveSegmentDecision {
  const AdaptiveSegmentDecision.continueSegment()
    : shouldStop = false,
      kind = null,
      message = null;

  const AdaptiveSegmentDecision.stop({
    required this.kind,
    required this.message,
  }) : shouldStop = true;

  final bool shouldStop;
  final AdaptiveSegmentStopKind? kind;
  final String? message;
}

class AdaptiveSegmentPolicy {
  const AdaptiveSegmentPolicy._();

  static AdaptiveSegmentDecision evaluate({
    required bool enabled,
    required TrainingMode mode,
    required int plannedTasks,
    required int completed,
    required int correctFirstTry,
    required int incorrectAttempts,
    required bool usedHelp,
    required bool targetStable,
    required bool reviewEmphasis,
    required bool transferEmphasis,
  }) {
    if (!enabled || completed >= plannedTasks || plannedTasks < 5) {
      return const AdaptiveSegmentDecision.continueSegment();
    }
    if (mode == TrainingMode.speed ||
        mode == TrainingMode.tempo ||
        mode == TrainingMode.blitz) {
      return const AdaptiveSegmentDecision.continueSegment();
    }
    if (completed < 3) {
      return const AdaptiveSegmentDecision.continueSegment();
    }

    final accuracy = completed == 0 ? 0.0 : correctFirstTry / completed;
    if (incorrectAttempts >= 3 && accuracy < 0.67) {
      return AdaptiveSegmentDecision.stop(
        kind: AdaptiveSegmentStopKind.overload,
        message:
            'Drei Aufgaben reichen für diesen Teil heute. Die Antworten zeigen, dass weiteres Wiederholen gerade wenig bringt; die nächste Runde setzt gezielter an.',
      );
    }

    if (!reviewEmphasis &&
        !transferEmphasis &&
        targetStable &&
        !usedHelp &&
        incorrectAttempts == 0 &&
        correctFirstTry == completed) {
      return AdaptiveSegmentDecision.stop(
        kind: AdaptiveSegmentStopKind.confirmed,
        message:
            'Drei selbstständige Aufgaben waren direkt richtig. Der Teilschritt ist aktuell sicher bestätigt; zwei weitere Wiederholungen sind heute nicht nötig.',
      );
    }

    return const AdaptiveSegmentDecision.continueSegment();
  }
}
