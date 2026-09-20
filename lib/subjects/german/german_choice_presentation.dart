import 'dart:math';

import 'german_competency.dart';
import 'german_task.dart';

class GermanChoicePresentation {
  const GermanChoicePresentation._();

  static List<String> present({
    required GermanTask task,
    required String seedMaterial,
  }) {
    final choices = List<String>.from(task.choices);
    if (choices.length < 2) return choices;
    if (task.interaction == GermanTaskInteraction.tokenSelection &&
        !_shouldShuffleTokenSelection(task)) {
      return choices;
    }

    choices.shuffle(Random(_stableSeed(seedMaterial)));

    if ((task.interaction == GermanTaskInteraction.wordOrder ||
            task.interaction == GermanTaskInteraction.wordBuilder) &&
        _sameOrder(choices, task.choices)) {
      final first = choices.removeAt(0);
      choices.add(first);
    }

    if (task.interaction == GermanTaskInteraction.tokenSelection) {
      _breakAnswerBlock(task, choices);
    }
    return choices;
  }

  static bool preservesTokenOrder(GermanTask task) =>
      task.interaction == GermanTaskInteraction.tokenSelection &&
      !_shouldShuffleTokenSelection(task);

  static bool _shouldShuffleTokenSelection(GermanTask task) =>
      switch (task.competencyId) {
        GermanCompetencyId.listeningComprehension ||
        GermanCompetencyId.conversationRules ||
        GermanCompetencyId.listeningMainIdeas ||
        GermanCompetencyId.discussionReasoning ||
        GermanCompetencyId.textInformation ||
        GermanCompetencyId.textMainIdea ||
        GermanCompetencyId.readingInference ||
        GermanCompetencyId.wordFamilies => true,
        _ => false,
      };

  static void _breakAnswerBlock(GermanTask task, List<String> choices) {
    if (choices.length < 3) return;
    final accepted = task.acceptedAnswers.map(_normalize).toSet();
    final answerCount = accepted.length;
    if (answerCount <= 0 || answerCount >= choices.length) return;
    if (!_hasAnswerBlockAtEdge(choices, accepted, answerCount)) return;

    final original = List<String>.from(choices);
    for (var shift = 1; shift < original.length; shift++) {
      final rotated = <String>[
        ...original.skip(shift),
        ...original.take(shift),
      ];
      if (_hasAnswerBlockAtEdge(rotated, accepted, answerCount)) continue;
      choices
        ..clear()
        ..addAll(rotated);
      return;
    }
  }

  static bool _hasAnswerBlockAtEdge(
    List<String> choices,
    Set<String> accepted,
    int answerCount,
  ) =>
      _allAccepted(choices.take(answerCount), accepted) ||
      _allAccepted(choices.skip(choices.length - answerCount), accepted);

  static bool _allAccepted(Iterable<String> values, Set<String> accepted) {
    final normalized = values.map(_normalize).toSet();
    return normalized.length == accepted.length &&
        accepted.containsAll(normalized);
  }

  static int _stableSeed(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
