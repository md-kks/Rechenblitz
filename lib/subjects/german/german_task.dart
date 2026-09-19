import '../../core/grade_level.dart';
import 'german_competency.dart';

enum GermanTaskInteraction {
  singleChoice,
  wordOrder,
  wordBuilder,
  typedText,
  listeningChoice,
}

class GermanTask {
  const GermanTask({
    required this.id,
    required this.competencyId,
    required this.recommendedFromGrade,
    required this.instruction,
    required this.prompt,
    required this.interaction,
    required this.acceptedAnswers,
    this.choices = const <String>[],
    this.spokenText,
    this.accessiblePrompt,
  });

  final String id;
  final GermanCompetencyId competencyId;
  final GradeLevel recommendedFromGrade;
  final String instruction;
  final String prompt;
  final GermanTaskInteraction interaction;
  final List<String> acceptedAnswers;
  final List<String> choices;
  final String? spokenText;

  /// Optional non-visual description for prompts such as symbols or images.
  ///
  /// It is used for semantics and automatic read-aloud instead of [prompt].
  final String? accessiblePrompt;

  String get promptForSpeech => accessiblePrompt ?? prompt;

  bool get requiresSpeech =>
      interaction == GermanTaskInteraction.listeningChoice;
  bool accepts(String answer) {
    if (interaction == GermanTaskInteraction.typedText) {
      final normalized = _normalizeTyped(answer);
      return acceptedAnswers.any(
        (value) => _normalizeTyped(value) == normalized,
      );
    }
    final normalized = _normalize(answer);
    return acceptedAnswers.any((value) => _normalize(value) == normalized);
  }

  bool get isWellFormed {
    if (id.trim().isEmpty ||
        instruction.trim().isEmpty ||
        prompt.trim().isEmpty) {
      return false;
    }
    if (acceptedAnswers.isEmpty ||
        acceptedAnswers.any((answer) => answer.trim().isEmpty) ||
        !_allUniqueNormalized(acceptedAnswers)) {
      return false;
    }
    if (choices.any((choice) => choice.trim().isEmpty) ||
        !_allUniqueNormalized(choices)) {
      return false;
    }
    if (requiresSpeech && (spokenText?.trim().isEmpty ?? true)) return false;
    if (accessiblePrompt != null && accessiblePrompt!.trim().isEmpty) {
      return false;
    }

    switch (interaction) {
      case GermanTaskInteraction.singleChoice:
      case GermanTaskInteraction.listeningChoice:
        return _singleChoiceAnswersValid();
      case GermanTaskInteraction.wordOrder:
        return choices.length >= 2 &&
            acceptedAnswers.every(_canBuildAnswerFromChoices);
      case GermanTaskInteraction.wordBuilder:
        return choices.length >= 2 &&
            acceptedAnswers.every(_canBuildJoinedAnswerFromChoices);
      case GermanTaskInteraction.typedText:
        return choices.isEmpty;
    }
  }

  bool _singleChoiceAnswersValid() {
    if (choices.length < 2 || acceptedAnswers.length != 1) return false;
    final accepted = _normalize(acceptedAnswers.single);
    return choices.where((choice) => _normalize(choice) == accepted).length ==
        1;
  }

  bool _canBuildAnswerFromChoices(String answer) {
    final target = _normalize(answer);
    final normalizedChoices = choices.map(_normalize).toList(growable: false);
    return _matchesChoiceSequence(
      target,
      normalizedChoices,
      List<bool>.filled(normalizedChoices.length, false),
      0,
    );
  }

  bool _canBuildJoinedAnswerFromChoices(String answer) {
    final target = _normalize(answer);
    final normalizedChoices = choices.map(_normalize).toList(growable: false);
    return _matchesJoinedChoiceSequence(
      target,
      normalizedChoices,
      List<bool>.filled(normalizedChoices.length, false),
    );
  }

  static bool _matchesChoiceSequence(
    String target,
    List<String> chunks,
    List<bool> used,
    int usedCount,
  ) {
    if (usedCount == chunks.length) return target.isEmpty;
    for (var index = 0; index < chunks.length; index++) {
      if (used[index]) continue;
      final chunk = chunks[index];
      if (target == chunk) {
        if (usedCount + 1 == chunks.length) return true;
        continue;
      }
      final prefix = '$chunk ';
      if (!target.startsWith(prefix)) continue;
      used[index] = true;
      if (_matchesChoiceSequence(
        target.substring(prefix.length),
        chunks,
        used,
        usedCount + 1,
      )) {
        return true;
      }
      used[index] = false;
    }
    return false;
  }

  static bool _matchesJoinedChoiceSequence(
    String target,
    List<String> chunks,
    List<bool> used,
  ) {
    if (target.isEmpty) return true;
    for (var index = 0; index < chunks.length; index++) {
      if (used[index]) continue;
      final chunk = chunks[index];
      if (!target.startsWith(chunk)) continue;
      used[index] = true;
      if (_matchesJoinedChoiceSequence(
        target.substring(chunk.length),
        chunks,
        used,
      )) {
        return true;
      }
      used[index] = false;
    }
    return false;
  }

  static bool _allUniqueNormalized(List<String> values) {
    final seen = <String>{};
    for (final value in values) {
      if (!seen.add(_normalize(value))) return false;
    }
    return true;
  }

  static String _normalizeTyped(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String _normalize(String value) =>
      _normalizeTyped(value).toLowerCase();
}
