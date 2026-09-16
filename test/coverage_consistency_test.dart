import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/assessment.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/learning_methods.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/remediation_path.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/touch_interaction.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';

void main() {
  test('Mikro-Kompetenz-Katalog ist vollständig und eindeutig', () {
    final ids = MicroCompetencyCatalog.definitions.map((d) => d.id).toList();
    expect(ids.toSet(), MicroCompetencyId.values.toSet());
    expect(ids.length, MicroCompetencyId.values.length);
    for (final definition in MicroCompetencyCatalog.definitions) {
      expect(definition.label.trim(), isNotEmpty, reason: definition.id.name);
      expect(definition.description.trim(), isNotEmpty, reason: definition.id.name);
      expect(definition.prerequisites.toSet().length, definition.prerequisites.length,
          reason: definition.id.name);
      expect(definition.prerequisites, isNot(contains(definition.id)),
          reason: definition.id.name);
    }
  });

  test('gezielte Generatoren erzeugen wirklich die angeforderte Kompetenz', () {
    final structured = StructuredExerciseGenerator(random: Random(26091601));
    final curriculum = CurriculumExerciseGenerator(random: Random(26091602));
    final adaptive = AdaptiveEngine(random: Random(26091603));
    final failures = <String>[];

    for (final definition in MicroCompetencyCatalog.definitions) {
      final mode = definition.preferredMode;
      final grade = definition.minGrade;
      final maxValue = max(
        grade.recommendedRange.maxValue,
        definition.minNumberRange.maxValue,
      );
      for (var sample = 0; sample < 20; sample++) {
        String key;
        MathFact? fact;
        if (mode.isUpperPrimary) {
          final exercise = curriculum.generate(
            mode: mode,
            gradeLevel: grade,
            maxValue: maxValue,
            targetCompetency: definition.id,
          );
          key = exercise.key;
        } else if (mode.isStructured) {
          final exercise = structured.generate(
            mode: mode,
            gradeLevel: grade,
            maxValue: maxValue,
            targetCompetency: definition.id,
          );
          key = exercise.key;
        } else {
          final factMax = min(maxValue, 100);
          fact = adaptive.selectNext(
            facts: AdaptiveEngine.buildFactPool(maxValue: factMax),
            mode: mode,
            maxValue: factMax,
            targetCompetency: definition.id,
          );
          key = fact.key;
        }
        final tags = MicroCompetencyCatalog.tagsForTask(
          mode: mode,
          taskKey: key,
          fact: fact,
        );
        if (!tags.any((tag) => tag.id == definition.id)) {
          failures.add('${definition.id.name}: ${mode.name}: $key -> '
              '${tags.map((tag) => tag.id.name).join(',')}');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.take(80).join('\n'));
  });

  test('Lerncheck verbucht nur Kompetenzen die der konkrete Task trägt', () {
    final failures = <String>[];
    for (final grade in GradeLevel.values) {
      for (var seed = 0; seed < 60; seed++) {
        final tasks = AssessmentGenerator(
          random: Random(26091610 + grade.index * 1000 + seed),
        ).generate(grade: grade, range: grade.recommendedRange);
        if (tasks.length != 12) {
          failures.add('${grade.name}/$seed: count=${tasks.length}');
        }
        if (tasks.map((t) => t.taskKey).toSet().length != tasks.length) {
          failures.add('${grade.name}/$seed: duplicate task key');
        }
        for (final task in tasks) {
          final target = task.targetCompetency;
          if (target == null) {
            failures.add('${grade.name}/$seed: ${task.taskKey}: no target');
            continue;
          }
          final tags = MicroCompetencyCatalog.tagsForTask(
            mode: task.mode,
            taskKey: task.taskKey,
            fact: task.fact,
          );
          if (!tags.any((tag) => tag.id == target)) {
            failures.add('${grade.name}/$seed: ${task.taskKey}: '
                'target=${target.name} tags=${tags.map((t) => t.id.name).join(',')}');
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.take(80).join('\n'));
  });

  test('Fördertasks bleiben fachlich an ihre Zielkompetenz gekoppelt', () {
    const modes = <ErrorPattern, TrainingMode>{
      ErrorPattern.countingStep: TrainingMode.neighbors,
      ErrorPattern.tenBridge: TrainingMode.practice,
      ErrorPattern.carryOmitted: TrainingMode.practice,
      ErrorPattern.borrowAvoided: TrainingMode.minus,
      ErrorPattern.partialOperand: TrainingMode.minus,
      ErrorPattern.numberBond: TrainingMode.numberFriends,
      ErrorPattern.operationChoice: TrainingMode.wordProblems,
      ErrorPattern.placeValue: TrainingMode.placeValue,
      ErrorPattern.multiplicationFact: TrainingMode.multiply,
      ErrorPattern.multiplicationAsAddition: TrainingMode.multiply,
      ErrorPattern.divisionFact: TrainingMode.divide,
      ErrorPattern.divisionAsSubtraction: TrainingMode.divide,
      ErrorPattern.inverseOperation: TrainingMode.missingNumber,
      ErrorPattern.numberRelations: TrainingMode.numberWall,
      ErrorPattern.patternRule: TrainingMode.sequences,
      ErrorPattern.wordProblem: TrainingMode.wordProblems,
      ErrorPattern.wordProblemRelevantInformation: TrainingMode.wordProblems,
      ErrorPattern.wordProblemModel: TrainingMode.wordProblems,
      ErrorPattern.wordProblemInterpretation: TrainingMode.wordProblems,
      ErrorPattern.representationTranslation: TrainingMode.wordProblems,
      ErrorPattern.moneyCalculation: TrainingMode.money,
      ErrorPattern.clockReading: TrainingMode.clock,
      ErrorPattern.unitConversion: TrainingMode.measures,
      ErrorPattern.geometryProperty: TrainingMode.geometryRelations,
      ErrorPattern.roundingPlace: TrainingMode.rounding,
      ErrorPattern.mentalStrategy: TrainingMode.mentalStrategies,
      ErrorPattern.writtenRegrouping: TrainingMode.writtenAddSub,
      ErrorPattern.writtenProcedure: TrainingMode.writtenMultiply,
      ErrorPattern.estimation: TrainingMode.estimation,
      ErrorPattern.arithmeticLaw: TrainingMode.arithmeticLaws,
      ErrorPattern.romanNumeral: TrainingMode.romanNumerals,
      ErrorPattern.fractionPart: TrainingMode.fractions,
      ErrorPattern.timeDuration: TrainingMode.timeDurations,
      ErrorPattern.dataReading: TrainingMode.dataCharts,
      ErrorPattern.probabilityReasoning: TrainingMode.probability,
      ErrorPattern.combinatorics: TrainingMode.combinatorics,
      ErrorPattern.proportionalReasoning: TrainingMode.proportionality,
      ErrorPattern.perimeterArea: TrainingMode.perimeterArea,
      ErrorPattern.spatialReasoning: TrainingMode.geometryBodies,
      ErrorPattern.symmetry: TrainingMode.symmetry,
      ErrorPattern.planScale: TrainingMode.plansAndOrientation,
      ErrorPattern.volume: TrainingMode.volumeCubes,
    };
    final failures = <String>[];
    for (final pattern in ErrorPattern.values.where((p) => p != ErrorPattern.unknown)) {
      for (var seed = 0; seed < 8; seed++) {
        final plan = RemediationGenerator(
          random: Random(26091680 + pattern.index * 100 + seed),
        ).generate(
          pattern: pattern,
          preferredMode: modes[pattern]!,
          grade: GradeLevel.fourth,
          range: NumberRangeLevel.million,
          methods: const MethodPreferences(),
        );
        for (final task in plan.tasks) {
          final target = task.effectiveTargetCompetency;
          if (target == null) {
            failures.add('${pattern.name}: ${task.sourceTaskKey}: no target');
            continue;
          }
          final tags = MicroCompetencyCatalog.tagsForTask(
            mode: task.mode,
            taskKey: task.sourceTaskKey,
          );
          if (!tags.any((tag) => tag.id == target)) {
            failures.add('${pattern.name}: ${task.sourceTaskKey}: '
                'target=${target.name} tags=${tags.map((t) => t.id.name).join(',')}');
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.take(100).join('\n'));
  });
  test('gezielte Aufgaben liefern immer ein konkretes Fehlermuster', () {
    final structured = StructuredExerciseGenerator(random: Random(26091701));
    final curriculum = CurriculumExerciseGenerator(random: Random(26091702));
    final adaptive = AdaptiveEngine(random: Random(26091703));
    final failures = <String>[];
    for (final definition in MicroCompetencyCatalog.definitions) {
      final mode = definition.preferredMode;
      final grade = definition.minGrade;
      final maxValue = max(grade.recommendedRange.maxValue, definition.minNumberRange.maxValue);
      for (var sample = 0; sample < 16; sample++) {
        String key; int expected; List<String>? choices; MathFact? fact;
        if (mode.isUpperPrimary) {
          final exercise = curriculum.generate(mode: mode, gradeLevel: grade, maxValue: maxValue, targetCompetency: definition.id);
          key = exercise.key; expected = exercise.answer; choices = exercise.choices;
        } else if (mode.isStructured) {
          final exercise = structured.generate(mode: mode, gradeLevel: grade, maxValue: maxValue, targetCompetency: definition.id);
          key = exercise.key; expected = exercise.answer; choices = exercise.choices;
        } else {
          final factMax = min(maxValue, 100);
          fact = adaptive.selectNext(facts: AdaptiveEngine.buildFactPool(maxValue: factMax), mode: mode, maxValue: factMax, targetCompetency: definition.id);
          key = fact.key; expected = mode == TrainingMode.numberFriends ? fact.b : fact.result;
        }
        final actual = choices != null && choices.length > 1 ? (expected + 1) % choices.length : expected == 0 ? 1 : expected - 1;
        final pattern = ErrorClassifier.classify(mode: mode, taskKey: key, expected: expected, actual: actual, fact: fact);
        if (pattern == null || pattern == ErrorPattern.unknown) failures.add('${definition.id.name}: ${mode.name}: $key');
      }
    }
    expect(failures, isEmpty, reason: failures.take(80).join('\n'));
  });

  test('wiederholte Lernchecks rotieren Fachbereiche bei stabilen Kernmodi', () {
    const cores = <GradeLevel, Set<TrainingMode>>{
      GradeLevel.first: {
        TrainingMode.practice,
        TrainingMode.minus,
        TrainingMode.numberFriends,
      },
      GradeLevel.second: {
        TrainingMode.practice,
        TrainingMode.minus,
        TrainingMode.multiply,
        TrainingMode.divide,
      },
      GradeLevel.third: {
        TrainingMode.multiply,
        TrainingMode.divide,
        TrainingMode.largeNumbers,
        TrainingMode.writtenAddSub,
      },
      GradeLevel.fourth: {
        TrainingMode.largeNumbers,
        TrainingMode.writtenAddSub,
        TrainingMode.writtenMultiply,
        TrainingMode.writtenDivide,
      },
    };

    for (final grade in GradeLevel.values) {
      final seenModes = <TrainingMode>{};
      for (var seed = 0; seed < 64; seed++) {
        final tasks = AssessmentGenerator(
          random: Random(26091900 + grade.index * 1000 + seed),
        ).generate(grade: grade, range: grade.recommendedRange);
        final modes = tasks.map((task) => task.mode).toSet();
        expect(modes, containsAll(cores[grade]!), reason: '${grade.name}/$seed');
        expect(modes, hasLength(6), reason: '${grade.name}/$seed');
        for (final mode in modes) {
          expect(
            tasks.where((task) => task.mode == mode),
            hasLength(2),
            reason: '${grade.name}/$seed/${mode.name}',
          );
        }
        seenModes.addAll(modes);
      }
      expect(
        seenModes.length,
        greaterThanOrEqualTo(9),
        reason: '${grade.name}: ${seenModes.map((mode) => mode.name).join(', ')}',
      );
    }
  });

  test('Lerncheck bewahrt Interaktionsmetadaten für Uhr und Zahlenmauer', () {
    AssessmentTask? clock;
    AssessmentTask? wall;
    for (var seed = 0; seed < 160 && (clock == null || wall == null); seed++) {
      final tasks = AssessmentGenerator(random: Random(26092000 + seed)).generate(
        grade: GradeLevel.first,
        range: GradeLevel.first.recommendedRange,
      );
      for (final task in tasks) {
        if (task.mode == TrainingMode.clock) clock ??= task;
        if (task.mode == TrainingMode.numberWall) wall ??= task;
      }
    }
    expect(clock, isNotNull);
    expect(clock!.clockHour, isNotNull);
    expect(clock.clockMinute, isNotNull);
    expect(
      TouchInteractionPlan.forTask(
        mode: clock.mode,
        taskKey: clock.taskKey,
        answer: clock.answer,
        maxValue: clock.maxAnswerValue,
        choices: clock.choices,
        clockHour: clock.clockHour,
        clockMinute: clock.clockMinute,
      ),
      isNotNull,
    );

    expect(wall, isNotNull);
    expect(wall!.wallValues, isNotNull);
    expect(wall.hiddenWallIndex, isNotNull);
    expect(
      TouchInteractionPlan.forTask(
        mode: wall.mode,
        taskKey: wall.taskKey,
        answer: wall.answer,
        maxValue: wall.maxAnswerValue,
        wallValues: wall.wallValues,
        hiddenWallIndex: wall.hiddenWallIndex,
      ),
      isNotNull,
    );
  });

  test('Lerncheck nutzt Touch wo sinnvoll und nie Förder-Fortsetzungsmodus', () {
    const classic = <MicroCompetencyId>{
      MicroCompetencyId.additionNoBridge, MicroCompetencyId.additionTenBridge,
      MicroCompetencyId.subtractionNoBridge, MicroCompetencyId.subtractionTenBridge,
      MicroCompetencyId.multiplicationFacts, MicroCompetencyId.divisionFacts,
      MicroCompetencyId.numberWordReading, MicroCompetencyId.wordProblemCalculation,
    };
    final failures = <String>[];
    for (final grade in GradeLevel.values) {
      for (var seed = 0; seed < 40; seed++) {
        final tasks = AssessmentGenerator(random: Random(26091800 + grade.index * 100 + seed)).generate(grade: grade, range: grade.recommendedRange);
        for (final task in tasks) {
          final plan = TouchInteractionPlan.forTask(mode: task.mode, taskKey: task.taskKey, answer: task.answer, maxValue: task.maxAnswerValue, wallValues: task.wallValues, hiddenWallIndex: task.hiddenWallIndex, choices: task.choices, clockHour: task.clockHour, clockMinute: task.clockMinute, answerSuffix: task.answerSuffix);
          final target = task.targetCompetency;
          if (plan == null && target != null && !classic.contains(target)) failures.add('${grade.name}: ${target.name}: ${task.taskKey}: no touch');
          if (plan != null && (plan.dataOperation?.contains('skip') ?? false)) failures.add('${grade.name}: ${task.taskKey}: skipped=${plan.dataOperation ?? ''}');
          if (plan != null && plan.dataOperation == 'operation-checked') failures.add('${grade.name}: ${task.taskKey}: operation prechecked');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.take(80).join('\n'));
  });

}
