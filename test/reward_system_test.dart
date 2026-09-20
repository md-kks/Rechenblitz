import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

TrainingSessionResult session({
  required TrainingMode mode,
  required NumberRangeLevel range,
  int total = 10,
  int correct = 8,
  int errors = 0,
  GradeLevel grade = GradeLevel.second,
  List<TrainingAttemptReview>? attemptReviews,
}) =>
    TrainingSessionResult(
      mode: mode,
      startedAt: DateTime(2026, 9, 2, 10),
      finishedAt: DateTime(2026, 9, 2, 10, 5),
      total: total,
      correctFirstTry: correct,
      incorrectAttempts: errors,
      plusCorrect: 0,
      plusTotal: 0,
      minusCorrect: 0,
      minusTotal: 0,
      averageResponseMs: 3000,
      numberRange: range,
      gradeLevel: grade,
      starsEarned: 1,
      attemptReviews: attemptReviews,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('deutlicher Fortschritt gibt einen zusätzlichen Stern', () {
    final controller = AppController();
    controller.history = [
      session(
        mode: TrainingMode.numberWall,
        range: NumberRangeLevel.twenty,
        correct: 5,
      ),
    ];
    final improved = session(
      mode: TrainingMode.numberWall,
      range: NumberRangeLevel.twenty,
      correct: 8,
    );
    expect(controller.rewardStarsForSession(improved), greaterThanOrEqualTo(3));
    expect(controller.rewardReasonForSession(improved), contains('verbessert'));
  });

  test('mehr Fehlversuche erzeugen keinen wiederholbaren Stern-Vorteil', () {
    final controller = AppController();
    controller.history = [
      session(
        mode: TrainingMode.practice,
        range: NumberRangeLevel.twenty,
        correct: 7,
      ),
    ];
    final cleanRound = session(
      mode: TrainingMode.practice,
      range: NumberRangeLevel.twenty,
      correct: 7,
      errors: 0,
    );
    final hardRound = session(
      mode: TrainingMode.practice,
      range: NumberRangeLevel.twenty,
      correct: 7,
      errors: 3,
    );

    expect(
      controller.rewardStarsForSession(hardRound),
      controller.rewardStarsForSession(cleanRound),
    );
    expect(controller.rewardReasonForSession(hardRound), contains('drangeblieben'));
  });

  test('Sicherheitsstern verlangt stabile Runde ohne viele Retries', () {
    final controller = AppController();
    controller.history = [
      session(
        mode: TrainingMode.practice,
        range: NumberRangeLevel.twenty,
        correct: 8,
      ),
    ];
    final stable = session(
      mode: TrainingMode.practice,
      range: NumberRangeLevel.twenty,
      total: 10,
      correct: 9,
      errors: 1,
    );
    final retryHeavy = session(
      mode: TrainingMode.practice,
      range: NumberRangeLevel.twenty,
      total: 10,
      correct: 9,
      errors: 3,
    );

    final stableStars = controller.rewardStarsForSession(stable);
    expect(stableStars, 3);
    expect(controller.rewardReasonForSession(stable), contains('sicher gerechnet'));
    expect(controller.rewardStarsForSession(retryHeavy), stableStars - 1);
    expect(
      controller.rewardReasonForSession(retryHeavy),
      isNot(contains('sicher gerechnet')),
    );
  });

  test('dokumentierte Hilfe blockiert den Sicherheitsstern', () {
    final controller = AppController();
    controller.history = [
      session(
        mode: TrainingMode.numberWall,
        range: NumberRangeLevel.twenty,
        correct: 8,
      ),
    ];
    final supported = session(
      mode: TrainingMode.numberWall,
      range: NumberRangeLevel.twenty,
      total: 10,
      correct: 9,
      errors: 1,
      attemptReviews: const [
        TrainingAttemptReview(
          taskNumber: 4,
          taskKey: 'wall:review',
          prompt: 'Ergänze die Zahlenmauer.',
          correctAnswer: '8',
          firstAnswer: '7',
          wrongAnswerAttempts: 1,
          usedHelp: true,
        ),
      ],
    );

    final independent = session(
      mode: TrainingMode.numberWall,
      range: NumberRangeLevel.twenty,
      total: 10,
      correct: 9,
      errors: 1,
    );
    expect(
      controller.rewardStarsForSession(supported),
      controller.rewardStarsForSession(independent) - 1,
    );
    expect(
      controller.rewardReasonForSession(supported),
      isNot(contains('sicher gerechnet')),
    );
  });

  test('Dranbleiben schaltet Mut-Abzeichen nur einmal frei', () async {
    final controller = AppController();
    final hardRound = session(
      mode: TrainingMode.practice,
      range: NumberRangeLevel.twenty,
      total: 10,
      correct: 7,
      errors: 3,
    );

    await controller.addSession(hardRound);
    expect(controller.unlockedBadges, contains('courage'));
    final badgeStars = controller.badgeStars;
    expect(badgeStars, 2);

    await controller.addSession(hardRound);
    expect(controller.badgeStars, badgeStars);
    expect(
      controller.unlockedBadges.where((id) => id == 'courage'),
      hasLength(1),
    );
  });

  test('fünf Lernwelten schalten Entdecker nur einmal frei', () async {
    final controller = AppController();
    for (final mode in [
      TrainingMode.practice,
      TrainingMode.numberWall,
      TrainingMode.money,
      TrainingMode.clock,
      TrainingMode.geometry,
    ]) {
      await controller.addSession(
        session(mode: mode, range: NumberRangeLevel.twenty),
      );
    }
    expect(controller.unlockedBadges, contains('explorer'));
    final before = controller.badgeStars;
    await controller.addSession(
      session(mode: TrainingMode.measures, range: NumberRangeLevel.twenty),
    );
    expect(controller.badgeStars, greaterThanOrEqualTo(before));
    expect(controller.unlockedBadges.where((id) => id == 'explorer'), hasLength(1));
  });

  test('sichere vielfältige Runden schalten Zahlenraum-Abzeichen frei', () async {
    final controller = AppController();
    await controller.addSession(session(
      mode: TrainingMode.practice,
      range: NumberRangeLevel.twenty,
      total: 10,
      correct: 9,
    ));
    await controller.addSession(session(
      mode: TrainingMode.numberWall,
      range: NumberRangeLevel.twenty,
      total: 10,
      correct: 9,
    ));
    await controller.addSession(session(
      mode: TrainingMode.money,
      range: NumberRangeLevel.twenty,
      total: 10,
      correct: 9,
    ));
    expect(controller.unlockedBadges, contains('range:twenty'));
  });

  test('drei sichere Runden schalten Lernwelt-Meisterschaft frei', () async {
    final controller = AppController();
    for (var i = 0; i < 3; i++) {
      await controller.addSession(session(
        mode: TrainingMode.numberWall,
        range: NumberRangeLevel.twenty,
        total: 10,
        correct: 9,
      ));
    }
    expect(
      controller.unlockedBadges,
      contains('mastery:numberWall:twenty'),
    );
  });

  test('wiederholt sichere Rechenart schaltet Profi-Abzeichen frei', () async {
    final controller = AppController();
    final fact = MathFact(a: 8, b: 4, operation: MathOperation.plus);
    for (var i = 0; i < 20; i++) {
      fact.registerAttempt(
        correct: i < 18,
        responseTime: const Duration(seconds: 2),
        usedHelp: false,
      );
    }
    controller.facts = [fact];
    await controller.addSession(
      session(mode: TrainingMode.practice, range: NumberRangeLevel.twenty),
    );
    expect(controller.unlockedBadges, contains('operation:plus'));
  });

  test('frühere Schwachstelle kann nach mehreren Erfolgen gemeistert werden', () async {
    final controller = AppController();
    final fact = MathFact(
      a: 9,
      b: 6,
      operation: MathOperation.minus,
      attempts: 4,
      correctAttempts: 1,
      incorrectAttempts: 3,
      averageResponseMs: 9000,
      helpCount: 3,
    );
    controller.facts = [fact];

    for (var i = 0; i < 15 && !controller.unlockedBadges.contains('weak_spot'); i++) {
      await controller.recordAttempt(
        fact,
        correct: true,
        responseTime: const Duration(seconds: 2),
        usedHelp: false,
      );
    }

    expect(controller.recoveredWeakFacts, contains(fact.key));
    expect(controller.unlockedBadges, contains('weak_spot'));
  });

  test('vielfältige sichere Arbeit schaltet Klassenstufen-Abzeichen frei', () async {
    final controller = AppController();
    for (final mode in [
      TrainingMode.largeNumbers,
      TrainingMode.rounding,
      TrainingMode.writtenAddSub,
      TrainingMode.advancedMeasures,
      TrainingMode.dataCharts,
      TrainingMode.geometryBodies,
    ]) {
      await controller.addSession(
        session(
          mode: mode,
          range: NumberRangeLevel.thousand,
          total: 10,
          correct: 9,
          grade: GradeLevel.third,
        ),
      );
    }
    expect(controller.unlockedBadges, contains('grade:third'));
  });

}
