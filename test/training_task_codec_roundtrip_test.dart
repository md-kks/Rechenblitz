import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/error_diagnosis.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/models/training_session_progress.dart';
import 'package:rechenblitz/services/app_controller.dart';

Map<String, dynamic> _jsonRoundTrip(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>,
    );

void main() {
  test('complete core training session survives a JSON round trip', () {
    final startedAt = DateTime.utc(2026, 9, 19, 12);
    final updatedAt = startedAt.add(const Duration(minutes: 4));
    const task = StructuredExercise(
      mode: TrainingMode.wordProblems,
      prompt: 'Welche Rechnung passt?',
      answer: 1,
      hint: 'Achte auf die Handlung.',
      key: 'story:operation:+:8:7',
      choices: <String>['Minus (−)', 'Plus (+)'],
      maxAnswerValue: 20,
      checkpoints: <ExerciseCheckpoint>[
        ExerciseCheckpoint(
          key: 'operation',
          question: 'Wird die Menge größer oder kleiner?',
          choices: <String>['größer', 'kleiner'],
          correctChoice: 0,
          competencyId: MicroCompetencyId.wordProblemOperation,
          evidenceWeight: 0.4,
        ),
      ],
    );
    final progress = CoreTrainingSessionProgress(
      kind: CoreTrainingKind.structured,
      mode: TrainingMode.wordProblems,
      targetTasks: 12,
      targetCompetency: MicroCompetencyId.wordProblemOperation,
      reviewEmphasis: true,
      transferEmphasis: true,
      fluencyEmphasis: false,
      scaffoldFading: true,
      adaptiveLength: true,
      gradeLevel: GradeLevel.second,
      numberRange: NumberRangeLevel.hundred,
      teacherAssignmentActive: true,
      teacherAssignmentId: 'assignment-roundtrip',
      timeLimitMs: 90000,
      startedAt: startedAt,
      updatedAt: updatedAt,
      currentTask: encodeStructuredExercise(task),
      elapsedActiveMs: 4321,
      completed: 3,
      incorrectAttempts: 2,
      correctFirstTry: 2,
      wrongOnCurrent: 1,
      segmentUsedHelp: true,
      assistanceVisible: true,
      usedHelp: true,
      useTouchInput: false,
      helpLevel: 2,
      activeMethodKey: 'story:operation',
      currentErrorPattern: ErrorPattern.operationChoice,
      checkpointIndex: 0,
      checkpointAttempted: <int>[0],
      checkpointWrongAttempts: <int, int>{0: 1},
      hadCheckpointError: true,
      taskFirstAttemptRecorded: true,
      helpCountedForCurrent: true,
      pendingFirstAttemptEvidence: const PendingFirstAttemptEvidence(
        id: 'roundtrip:pending',
        taskKey: 'story:operation:+:8:7',
        expected: 1,
        actual: 0,
        responseMs: 1700,
        usedHelp: true,
        helpLevel: 2,
        methodKey: 'story:operation',
        source: MicroEvidenceSource.transfer,
      ),
      responseTimes: <int>[1200, 1800, 1600],
      plusTotal: 2,
      plusCorrect: 2,
      minusTotal: 1,
      minusCorrect: 0,
      multiplyTotal: 0,
      multiplyCorrect: 0,
      divideTotal: 0,
      divideCorrect: 0,
      taskResolved: false,
    );

    final json = _jsonRoundTrip(progress.toJson());
    final restored = CoreTrainingSessionProgress.fromJson(json);

    expect(restored.toJson(), equals(json));
    expect(
      encodeStructuredExercise(decodeStructuredExercise(restored.currentTask)),
      equals(progress.currentTask),
    );
    expect(
      restored.hasSaneState(now: updatedAt.add(const Duration(seconds: 1))),
      isTrue,
    );
  });

  test('audit generated task codecs across normal and transfer tasks', () {
    final controller = AppController();
    final failures = <String>[];

    for (final definition in MicroCompetencyCatalog.definitions) {
      final grade = definition.minGrade;
      final range = NumberRangeLevel.values.firstWhere(
        (value) =>
            value.index >= grade.recommendedRange.index &&
            value.index >= definition.minNumberRange.index,
      );
      final maxValue = range.maxValue;
      final transferMode = controller.transferModeFor(definition.id);

      for (final transfer in <bool>[false, true]) {
        final mode = transfer ? transferMode : definition.preferredMode;
        if (!mode.isStructured && !mode.isUpperPrimary) continue;

        for (var seed = 0; seed < 64; seed++) {
          final label =
              '${definition.id.name}/${transfer ? "transfer" : "normal"}/$seed';
          try {
            if (mode.isStructured) {
              final task =
                  StructuredExerciseGenerator(
                    random: Random(
                      1200000 +
                          definition.id.index * 1000 +
                          seed +
                          (transfer ? 500 : 0),
                    ),
                  ).generate(
                    mode: mode,
                    gradeLevel: grade,
                    maxValue: maxValue,
                    targetCompetency: definition.id,
                    transferEmphasis: transfer,
                  );
              final encoded = encodeStructuredExercise(task);
              final decoded = decodeStructuredExercise(_jsonRoundTrip(encoded));
              final reencoded = encodeStructuredExercise(decoded);
              if (jsonEncode(encoded) != jsonEncode(reencoded)) {
                failures.add('$label: structured mismatch ${task.key}');
              }
            } else {
              final task =
                  CurriculumExerciseGenerator(
                    random: Random(
                      1300000 +
                          definition.id.index * 1000 +
                          seed +
                          (transfer ? 500 : 0),
                    ),
                  ).generate(
                    mode: mode,
                    gradeLevel: grade,
                    maxValue: maxValue,
                    targetCompetency: definition.id,
                    transferEmphasis: transfer,
                  );
              final encoded = encodeCurriculumExercise(task);
              final decoded = decodeCurriculumExercise(_jsonRoundTrip(encoded));
              final reencoded = encodeCurriculumExercise(decoded);
              if (jsonEncode(encoded) != jsonEncode(reencoded)) {
                failures.add('$label: curriculum mismatch ${task.key}');
              }
            }
          } catch (error) {
            failures.add('$label: $error');
          }
        }
      }
    }

    expect(failures, isEmpty, reason: failures.take(120).join('\n'));
  });
}
