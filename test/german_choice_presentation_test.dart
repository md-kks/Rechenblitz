import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_choice_presentation.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';
import 'package:rechenblitz/subjects/german/screens/german_training_screen.dart';

bool _isAnswerBlockAtStart(GermanTask task, List<String> choices) {
  final accepted = task.acceptedAnswers
      .map((value) => value.toLowerCase())
      .toSet();
  final block = choices
      .take(accepted.length)
      .map((value) => value.toLowerCase())
      .toSet();
  return block.length == accepted.length && accepted.containsAll(block);
}

bool _isAnswerBlockAtEnd(GermanTask task, List<String> choices) {
  final accepted = task.acceptedAnswers
      .map((value) => value.toLowerCase())
      .toSet();
  final block = choices
      .skip(choices.length - accepted.length)
      .map((value) => value.toLowerCase())
      .toSet();
  return block.length == accepted.length && accepted.containsAll(block);
}

void main() {
  test('source-order grammar selections stay in sentence order', () {
    final task = GermanTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-subpred-letter-perfect',
    );

    expect(GermanChoicePresentation.preservesTokenOrder(task), isTrue);
    for (var seed = 0; seed < 20; seed++) {
      expect(
        GermanChoicePresentation.present(
          task: task,
          seedMaterial: 'grammar-$seed',
        ),
        task.choices,
      );
    }
  });

  test('independent evidence choices vary while staying deterministic', () {
    final task = GermanTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-inference-evidence-power-outage',
    );

    expect(GermanChoicePresentation.preservesTokenOrder(task), isFalse);
    final orders = <String>{};
    for (var seed = 0; seed < 30; seed++) {
      final material = 'evidence-$seed';
      final first = GermanChoicePresentation.present(
        task: task,
        seedMaterial: material,
      );
      final second = GermanChoicePresentation.present(
        task: task,
        seedMaterial: material,
      );
      expect(first, second);
      expect(first.toSet(), task.choices.toSet());
      expect(_isAnswerBlockAtStart(task, first), isFalse);
      expect(_isAnswerBlockAtEnd(task, first), isFalse);
      orders.add(first.join('|'));
    }
    expect(orders.length, greaterThan(1));
  });

  test(
    'all shuffled token selections avoid an answer block at either edge',
    () {
      final tasks = GermanTaskCatalog.tasks.where(
        (task) =>
            task.interaction == GermanTaskInteraction.tokenSelection &&
            !GermanChoicePresentation.preservesTokenOrder(task),
      );
      expect(tasks, isNotEmpty);

      for (final task in tasks) {
        for (var seed = 0; seed < 12; seed++) {
          final presented = GermanChoicePresentation.present(
            task: task,
            seedMaterial: '${task.id}-$seed',
          );
          expect(
            _isAnswerBlockAtStart(task, presented),
            isFalse,
            reason: '${task.id} seed $seed starts with all answers',
          );
          expect(
            _isAnswerBlockAtEnd(task, presented),
            isFalse,
            reason: '${task.id} seed $seed ends with all answers',
          );
        }
      }
    },
  );

  test('word order still never presents the ready-made solution order', () {
    final task = GermanTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g4-sequence-protocol-order',
    );
    for (var seed = 0; seed < 30; seed++) {
      final presented = GermanChoicePresentation.present(
        task: task,
        seedMaterial: 'sequence-$seed',
      );
      expect(presented, isNot(equals(task.choices)));
      expect(presented.toSet(), task.choices.toSet());
    }
  });

  testWidgets('training screen renders the same stable mixed token order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final task = GermanTaskCatalog.tasks.firstWhere(
      (task) => task.id == 'g2-family-mark-write',
    );
    final now = DateTime(2026, 9, 20, 12, 34, 56, 789);
    final expected = GermanChoicePresentation.present(
      task: task,
      seedMaterial: '${now.microsecondsSinceEpoch}:0:${task.id}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GermanTrainingScreen(
          gradeLevel: GradeLevel.second,
          tasks: <GermanTask>[task],
          speak: (_) async {},
          now: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rendered = tester
        .widgetList<FilterChip>(find.byType(FilterChip))
        .map((chip) => (chip.label as Text).data!)
        .toList(growable: false);
    expect(rendered, expected);
    expect(_isAnswerBlockAtStart(task, rendered), isFalse);
    expect(_isAnswerBlockAtEnd(task, rendered), isFalse);
  });
}
