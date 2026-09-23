import 'german_task.dart';

class GermanTaskChallenge {
  const GermanTaskChallenge._();

  static int score(GermanTask task) {
    var score = switch (task.interaction) {
      GermanTaskInteraction.singleChoice => 2 + _extraChoices(task, 3),
      GermanTaskInteraction.listeningChoice => 2 + _extraChoices(task, 3),
      GermanTaskInteraction.tokenSelection =>
        2 + task.acceptedAnswers.length * 2 + _extraChoices(task, 4),
      GermanTaskInteraction.wordOrder => 2 + task.choices.length,
      GermanTaskInteraction.wordBuilder =>
        2 + task.choices.length + (_shortestAcceptedLength(task) ~/ 7),
      GermanTaskInteraction.typedText =>
        2 + _shortestAcceptedWordCount(task) * 2,
    };

    final spoken = task.spokenText;
    if (spoken != null && spoken.trim().isNotEmpty) {
      score += _wordCount(spoken) ~/ 10;
    }
    return score;
  }

  static int _extraChoices(GermanTask task, int baseline) =>
      task.choices.length > baseline ? task.choices.length - baseline : 0;

  static int _shortestAcceptedLength(GermanTask task) => task.acceptedAnswers
      .map((answer) => answer.trim().length)
      .reduce((a, b) => a < b ? a : b);

  static int _shortestAcceptedWordCount(GermanTask task) =>
      task.acceptedAnswers.map(_wordCount).reduce((a, b) => a < b ? a : b);

  static int _wordCount(String text) =>
      text.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).length;
}
