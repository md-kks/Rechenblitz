import 'german_competency.dart';
import 'german_history_scope.dart';
import 'german_mistake_kind.dart';
import 'german_session.dart';
import 'german_task.dart';

class GermanMistakeFocusPattern {
  const GermanMistakeFocusPattern({
    required this.kind,
    required this.competencyId,
    required this.count,
    required this.latestAt,
  });

  final GermanMistakeKind kind;
  final GermanCompetencyId competencyId;
  final int count;
  final DateTime latestAt;
}

class GermanMistakeFocus {
  const GermanMistakeFocus(this.patterns);

  final List<GermanMistakeFocusPattern> patterns;

  bool get isEmpty => patterns.isEmpty;

  int priorityFor(GermanTask task) {
    var best = 0;
    for (final pattern in patterns) {
      var match = 0;
      if (task.competencyId == pattern.competencyId) {
        match = 3;
      } else if (_relatedCompetencies(
        pattern.kind,
      ).contains(task.competencyId)) {
        match = 2;
      }
      if (match == 0) continue;

      var score = match * 100 + (pattern.count > 9 ? 9 : pattern.count);
      if (_preferredInteraction(pattern.kind, task)) score += 20;
      if (score > best) best = score;
    }
    return best;
  }

  static bool _preferredInteraction(GermanMistakeKind kind, GermanTask task) =>
      switch (kind) {
        GermanMistakeKind.selectionMissing ||
        GermanMistakeKind.selectionExtra ||
        GermanMistakeKind.selectionSwap ||
        GermanMistakeKind.selectionMixed =>
          task.interaction == GermanTaskInteraction.tokenSelection,
        GermanMistakeKind.wordOrder ||
        GermanMistakeKind.alphabeticalOrder ||
        GermanMistakeKind.textSequence =>
          task.interaction == GermanTaskInteraction.wordOrder,
        GermanMistakeKind.wordBuilding =>
          task.interaction == GermanTaskInteraction.wordBuilder,
        GermanMistakeKind.listening => task.requiresSpeech,
        _ => false,
      };

  static Set<GermanCompetencyId> _relatedCompetencies(GermanMistakeKind kind) =>
      switch (kind) {
        GermanMistakeKind.capitalization => <GermanCompetencyId>{
          GermanCompetencyId.sentenceWriting,
          GermanCompetencyId.textRevision,
        },
        GermanMistakeKind.endingPunctuation => <GermanCompetencyId>{
          GermanCompetencyId.sentencePunctuation,
          GermanCompetencyId.sentenceTypes,
          GermanCompetencyId.sentenceWriting,
        },
        GermanMistakeKind.punctuation ||
        GermanMistakeKind.capitalizationAndPunctuation => <GermanCompetencyId>{
          GermanCompetencyId.sentencePunctuation,
          GermanCompetencyId.directSpeechPunctuation,
          GermanCompetencyId.sentenceConnections,
          GermanCompetencyId.sentenceWriting,
          GermanCompetencyId.textRevision,
        },
        GermanMistakeKind.wordOrder => <GermanCompetencyId>{
          GermanCompetencyId.sentenceWordOrder,
          GermanCompetencyId.sentenceWriting,
          GermanCompetencyId.sentenceConnections,
          GermanCompetencyId.textSequence,
        },
        GermanMistakeKind.spelling => <GermanCompetencyId>{
          GermanCompetencyId.spellingStrategies,
          GermanCompetencyId.sentenceWriting,
          GermanCompetencyId.textRevision,
        },
        GermanMistakeKind.missingWord ||
        GermanMistakeKind.extraWord => <GermanCompetencyId>{
          GermanCompetencyId.sentenceWriting,
          GermanCompetencyId.sentenceConnections,
          GermanCompetencyId.textRevision,
        },
        GermanMistakeKind.wordRecognition => <GermanCompetencyId>{
          GermanCompetencyId.wordRecognition,
        },
        GermanMistakeKind.letterSound => <GermanCompetencyId>{
          GermanCompetencyId.letterSoundMatch,
        },
        GermanMistakeKind.listening => <GermanCompetencyId>{
          GermanCompetencyId.listeningComprehension,
          GermanCompetencyId.conversationRules,
          GermanCompetencyId.oralRetelling,
          GermanCompetencyId.listeningMainIdeas,
          GermanCompetencyId.presentationStructure,
          GermanCompetencyId.discussionReasoning,
        },
        GermanMistakeKind.alphabeticalOrder => <GermanCompetencyId>{
          GermanCompetencyId.alphabeticalOrder,
          GermanCompetencyId.dictionarySkills,
        },
        GermanMistakeKind.textSequence => <GermanCompetencyId>{
          GermanCompetencyId.textSequence,
          GermanCompetencyId.oralRetelling,
          GermanCompetencyId.presentationStructure,
        },
        GermanMistakeKind.wordBuilding => <GermanCompetencyId>{
          GermanCompetencyId.wordBuilding,
          GermanCompetencyId.syllableSegmentation,
          GermanCompetencyId.spellingStrategies,
          GermanCompetencyId.compoundWords,
          GermanCompetencyId.verbInflection,
          GermanCompetencyId.verbTenses,
        },
        GermanMistakeKind.directSpeechPunctuation => <GermanCompetencyId>{
          GermanCompetencyId.directSpeechPunctuation,
        },
        GermanMistakeKind.sentenceConnection => <GermanCompetencyId>{
          GermanCompetencyId.sentenceConnections,
        },
        GermanMistakeKind.textRevision => <GermanCompetencyId>{
          GermanCompetencyId.textRevision,
        },
        GermanMistakeKind.selectionMissing ||
        GermanMistakeKind.selectionExtra ||
        GermanMistakeKind.selectionSwap ||
        GermanMistakeKind.selectionMixed => const <GermanCompetencyId>{},
      };
}

class GermanMistakeFocusAnalyzer {
  const GermanMistakeFocusAnalyzer._();

  static GermanMistakeFocus analyze({
    required Iterable<GermanSessionResult> history,
    DateTime? now,
    Duration window = const Duration(days: 21),
    int minimumOccurrences = 2,
    int cleanEvidenceToResolve = 2,
    Duration minimumConfirmationDelay = const Duration(hours: 12),
  }) {
    final sessions = GermanHistoryScope.unique(history).toList(growable: false);
    if (sessions.isEmpty) {
      return const GermanMistakeFocus(<GermanMistakeFocusPattern>[]);
    }

    final latestSession = sessions
        .map((session) => session.finishedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final reference = now ?? latestSession;
    final cutoff = reference.subtract(window);
    final recent = sessions
        .where(
          (session) =>
              !session.finishedAt.isAfter(reference) &&
              !session.finishedAt.isBefore(cutoff),
        )
        .toList(growable: false);

    final stats =
        <
          ({GermanMistakeKind kind, GermanCompetencyId competency}),
          _MistakeStats
        >{};
    for (final session in recent) {
      for (final result in session.taskResults) {
        final kind = result.firstMistakeKind;
        if (kind == null) continue;
        final key = (kind: kind, competency: result.competencyId);
        final stat = stats.putIfAbsent(key, _MistakeStats.new);
        stat.count += 1;
        if (stat.latestAt == null ||
            session.finishedAt.isAfter(stat.latestAt!)) {
          stat.latestAt = session.finishedAt;
        }
      }
    }

    final patterns = <GermanMistakeFocusPattern>[];
    for (final entry in stats.entries) {
      final stat = entry.value;
      final latestAt = stat.latestAt;
      if (stat.count < minimumOccurrences || latestAt == null) continue;

      // A recurring error is not considered resolved by immediate retry
      // success. Require later, independent evidence and count distinct tasks
      // so memorising one answer cannot clear the focus by itself.
      final confirmationCutoff = latestAt.add(minimumConfirmationDelay);
      final cleanTaskIds = <String>{};
      for (final session in recent) {
        if (session.finishedAt.isBefore(confirmationCutoff)) continue;
        for (final result in session.taskResults) {
          if (result.competencyId != entry.key.competency) continue;
          if (result.independentCorrectFirstTry &&
              result.incorrectAttempts == 0 &&
              result.firstMistakeKind == null) {
            cleanTaskIds.add(result.taskId);
          }
        }
      }
      if (cleanTaskIds.length >= cleanEvidenceToResolve) continue;

      patterns.add(
        GermanMistakeFocusPattern(
          kind: entry.key.kind,
          competencyId: entry.key.competency,
          count: stat.count,
          latestAt: latestAt,
        ),
      );
    }

    patterns.sort((a, b) {
      final count = b.count.compareTo(a.count);
      if (count != 0) return count;
      final recency = b.latestAt.compareTo(a.latestAt);
      if (recency != 0) return recency;
      final kind = a.kind.index.compareTo(b.kind.index);
      if (kind != 0) return kind;
      return a.competencyId.index.compareTo(b.competencyId.index);
    });
    return GermanMistakeFocus(
      List<GermanMistakeFocusPattern>.unmodifiable(patterns),
    );
  }
}

class _MistakeStats {
  int count = 0;
  DateTime? latestAt;
}
