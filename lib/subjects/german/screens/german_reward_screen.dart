import 'package:flutter/material.dart';

import '../../../core/grade_level.dart';
import '../german_rewards.dart';
import '../german_session.dart';

class GermanRewardScreen extends StatelessWidget {
  const GermanRewardScreen({
    super.key,
    required this.gradeLevel,
    required this.history,
  });

  final GradeLevel gradeLevel;
  final List<GermanSessionResult> history;

  @override
  Widget build(BuildContext context) {
    final summary = GermanRewardSummary.fromHistory(
      gradeLevel: gradeLevel,
      history: history,
    );
    final nextGoal = ((summary.stars ~/ 10) + 1) * 10;
    final previousGoal = nextGoal - 10;
    final progress = ((summary.stars - previousGoal) / 10).clamp(0.0, 1.0);
    final remaining = nextGoal - summary.stars;

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Deutsch-Erfolge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 34),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.star_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${summary.stars} Sterne',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    remaining == 1
                        ? 'Noch 1 Stern bis zum nächsten Ziel'
                        : 'Noch $remaining Sterne bis zum nächsten Ziel',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Deine Deutsch-Abzeichen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (summary.badges.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Hier erscheinen deine Deutsch-Abzeichen nach den ersten abgeschlossenen Runden.',
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summary.badges.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: constraints.maxWidth < 390 ? 1.0 : 1.15,
                  ),
                  itemBuilder: (_, index) =>
                      _GermanBadgeCard(badge: summary.badges[index]),
                );
              },
            ),
          const SizedBox(height: 22),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Diese Erfolge entstehen aus den Deutsch-Runden dieses Lernprofils und bleiben beim Wechsel in eine höhere Klassenstufe erhalten. Mathe-Sterne und Mathe-Abzeichen werden hier nicht mitgezählt.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GermanBadgeCard extends StatelessWidget {
  const _GermanBadgeCard({required this.badge});

  final GermanRewardBadge badge;

  IconData get icon => switch (badge.iconKey) {
    'flag' => Icons.flag_rounded,
    'courage' => Icons.psychology_alt_rounded,
    'explore' => Icons.explore_rounded,
    'domains' => Icons.auto_stories_rounded,
    'secure' => Icons.check_circle_rounded,
    'mastery' => Icons.workspace_premium_rounded,
    'stairs' => Icons.stairs_rounded,
    'rounds' => Icons.repeat_rounded,
    'perfect' => Icons.star_rounded,
    _ => Icons.emoji_events_rounded,
  };

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(icon, size: 42),
          title: Text(badge.title, textAlign: TextAlign.center),
          content: Text(badge.description, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fertig'),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(radius: 24, child: Icon(icon)),
            const SizedBox(height: 10),
            Text(
              badge.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    ),
  );
}
