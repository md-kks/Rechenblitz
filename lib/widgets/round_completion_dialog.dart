import 'package:flutter/material.dart';

import '../models/reward_badge.dart';

Future<void> showRoundCompletionDialog(
  BuildContext context, {
  required int completed,
  required int correctFirstTry,
  required int starsEarned,
  String? rewardReason,
  List<RewardBadge> newBadges = const <RewardBadge>[],
  double? averageSeconds,
}) => showDialog<void>(
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
            '$correctFirstTry von $completed direkt richtig',
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
          if (starsEarned > 0) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded),
                const SizedBox(width: 6),
                Text(
                  '+$starsEarned Sterne',
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
