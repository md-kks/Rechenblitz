import '../../core/grade_level.dart';
import 'german_competency.dart';

enum GermanTaskInteraction {
  singleChoice,
  wordOrder,
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

  bool get requiresSpeech =>
      interaction == GermanTaskInteraction.listeningChoice;
  bool accepts(String answer) {
    final normalized = _normalize(answer);
    return acceptedAnswers.any((value) => _normalize(value) == normalized);
  }

  bool get isWellFormed {
    if (id.trim().isEmpty || instruction.trim().isEmpty) return false;
    if (acceptedAnswers.isEmpty) return false;
    if (requiresSpeech && (spokenText?.trim().isEmpty ?? true)) return false;
    if (interaction == GermanTaskInteraction.singleChoice || requiresSpeech) {
      if (choices.length < 2) return false;
      if (!acceptedAnswers.every(choices.contains)) return false;
    }
    if (interaction == GermanTaskInteraction.wordOrder && choices.length < 2) {
      return false;
    }
    return true;
  }

  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
