import 'dart:async';

import 'package:flutter/material.dart';

import '../models/learning_path.dart';
import '../models/reward_badge.dart';

Future<void> showRoundCompletionDialog(
  BuildContext context, {
  required int completed,
  required int correctFirstTry,
  required int starsEarned,
  String? rewardReason,
  List<RewardBadge> newBadges = const <RewardBadge>[],
  double? averageSeconds,
  String? adaptiveNote,
  LearningCompletionInsight? learningInsight,
  String? spokenFeedback,
  bool autoSpeakSpokenFeedback = false,
  Future<void> Function()? onSpeakSpokenFeedback,
}) {
  final spoken = spokenFeedback?.trim();
  if (autoSpeakSpokenFeedback &&
      spoken != null &&
      spoken.isNotEmpty &&
      onSpeakSpokenFeedback != null) {
    unawaited(onSpeakSpokenFeedback());
  }
  return showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (dialogContext) => AlertDialog(
    icon: Icon(
      Icons.check_circle_rounded,
      size: 54,
      color: Theme.of(dialogContext).colorScheme.primary,
    ),
    title: const Text('Runde geschafft!', textAlign: TextAlign.center),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$correctFirstTry von $completed beim ersten Versuch richtig',
            textAlign: TextAlign.center,
            style: Theme.of(dialogContext).textTheme.titleMedium,
          ),
          if (averageSeconds != null) ...[
            const SizedBox(height: 6),
            Text(
              'Im Schnitt ${averageSeconds.toStringAsFixed(1)} Sekunden',
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
          if (learningInsight != null) ...[
            const SizedBox(height: 12),
            Card(
              key: const ValueKey('round-learning-insight'),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          learningInsight.fluency
                              ? Icons.autorenew_rounded
                              : Icons.insights_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            learningInsight.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(learningInsight.detail),
                    const SizedBox(height: 6),
                    Text(
                      learningInsight.nextStep,
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (spoken != null && spoken.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              key: const ValueKey('round-spoken-feedback'),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.record_voice_over_outlined, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        spoken,
                        key: const ValueKey('round-spoken-feedback-text'),
                      ),
                    ),
                    if (onSpeakSpokenFeedback != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        key: const ValueKey('round-spoken-feedback-replay'),
                        tooltip: 'Nochmal anhören',
                        onPressed: () => unawaited(onSpeakSpokenFeedback()),
                        icon: const Icon(Icons.volume_up_outlined),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (adaptiveNote != null && adaptiveNote.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              key: const ValueKey('round-adaptive-note'),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(adaptiveNote, textAlign: TextAlign.center),
              ),
            ),
          ],
          if (starsEarned > 0) ...[
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                const Icon(Icons.star_rounded),
                Text(
                  '+$starsEarned Sterne',
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.titleLarge,
                ),
              ],
            ),
            if (rewardReason != null && rewardReason.trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                rewardReason,
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ],
          if (newBadges.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              newBadges.length == 1 ? 'Neues Abzeichen' : 'Neue Abzeichen',
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...newBadges.map(
              (badge) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 20),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        badge.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      FilledButton(
        key: const ValueKey('round-completion-done'),
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Zurück'),
      ),
    ],
  ),
);
}
