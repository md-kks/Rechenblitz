import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/method_key_label.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/services/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('neue exakte Zehnerhilfe hat einen elterntauglichen Namen', () {
    expect(MethodKeyLabel.resolve('addition:toFullTen'), 'Zum vollen Zehner');
    expect(MethodKeyLabel.resolve('addition:bridgeToTen'), 'Erst zum Zehner');
  });

  test('dynamische Schulmethoden werden vollständig übersetzt', () {
    for (final strategy in SubtractionStrategy.values) {
      expect(MethodKeyLabel.resolve('subtraction:${strategy.name}'), strategy.label);
    }
    for (final strategy in MultiplicationStrategy.values) {
      expect(MethodKeyLabel.resolve('multiplication:${strategy.name}'), strategy.label);
    }
    for (final strategy in WrittenSubtractionStrategy.values) {
      expect(MethodKeyLabel.resolve('writtenSubtraction:${strategy.name}'), strategy.label);
    }
    for (final mode in TrainingMode.values) {
      expect(MethodKeyLabel.resolve('general:${mode.name}'), mode.title);
    }
  });

  test('unbekannte technische Methodenschlüssel werden nicht angezeigt', () {
    expect(MethodKeyLabel.resolve('future:internalToken'), isNull);
  });

  test('Elternhinweis zeigt lesbaren Namen statt internem Schlüssel', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      3,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 10, 10, index),
        correct: true,
        evidenceWeight: 0.65,
        source: MicroEvidenceSource.practice,
        usedHelp: true,
        helpLevel: 2,
        methodKey: 'addition:toFullTen',
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:17:3',
      ),
    );

    final insight = controller.methodSupportInsight(MicroCompetencyId.additionNoBridge);
    expect(insight, contains('Zum vollen Zehner'));
    expect(insight, contains('beobachteten Antworten richtig'));
    expect(insight, isNot(contains('toFullTen')));
    expect(insight, isNot(contains('direkt richtig gelöst')));
  });

  test('unbekannte Methode erzeugt keinen technischen Elterntext', () async {
    final controller = AppController();
    await controller.load();
    controller.gradeLevel = GradeLevel.second;
    controller.numberRange = NumberRangeLevel.hundred;
    controller.microObservations = List.generate(
      3,
      (index) => MicroCompetencyObservation(
        id: MicroCompetencyId.additionNoBridge,
        occurredAt: DateTime(2026, 9, 10, 11, index),
        correct: true,
        evidenceWeight: 1,
        source: MicroEvidenceSource.practice,
        usedHelp: true,
        helpLevel: 1,
        methodKey: 'future:internalToken',
        mode: TrainingMode.practice,
        gradeLevel: GradeLevel.second,
        numberRange: NumberRangeLevel.hundred,
        taskKey: 'plus:12:3',
      ),
    );

    expect(controller.methodSupportInsight(MicroCompetencyId.additionNoBridge), isNull);
  });
}
