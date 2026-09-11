import 'package:flutter/material.dart';

import '../models/reward_badge.dart';
import '../services/app_controller.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final badges = controller.badges;
    final goal = controller.nextStarGoal;
    final previousGoal = goal - 10;
    final progress = ((controller.stars - previousGoal) / 10).clamp(0.0, 1.0);
    final remaining = (goal - controller.stars).clamp(0, 10);

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Erfolge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 34),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${controller.stars} Sterne',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress.toDouble(),
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
            'Deine Abzeichen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (badges.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hier erscheinen deine Abzeichen, wenn du beim Üben neue Ziele erreichst.',
                      ),
                    ),
                  ],
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
                  itemCount: badges.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: constraints.maxWidth < 390 ? 1.0 : 1.15,
                  ),
                  itemBuilder: (_, index) => _BadgeCard(badge: badges[index]),
                );
              },
            ),
          const SizedBox(height: 22),
          const Card(
            child: ExpansionTile(
              key: ValueKey('reward-how-it-works'),
              leading: Icon(Icons.info_outline_rounded),
              title: Text('Wie bekomme ich Sterne und Abzeichen?'),
              childrenPadding: EdgeInsets.fromLTRB(18, 0, 18, 14),
              children: [
                _RewardRule(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Runden abschließen',
                  text:
                      'Eine abgeschlossene Runde bringt mindestens einen Stern.',
                ),
                _RewardRule(
                  icon: Icons.trending_up_rounded,
                  title: 'Fortschritte machen',
                  text:
                      'Wenn etwas deutlich besser klappt, kann ein Zusatzstern dazukommen.',
                ),
                _RewardRule(
                  icon: Icons.psychology_alt_rounded,
                  title: 'Dranbleiben',
                  text:
                      'Auch eine schwierige Runde zu Ende zu bringen kann belohnt werden.',
                ),
                _RewardRule(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Abzeichen sammeln',
                  text:
                      'Sicheres und abwechslungsreiches Üben schaltet Abzeichen frei.',
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Schneller zu sein gibt keine Extra-Sterne.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final RewardBadge badge;

  IconData get icon => switch (badge.iconKey) {
    'explore' => Icons.explore_rounded,
    'courage' => Icons.psychology_alt_rounded,
    'weak_spot' => Icons.extension_rounded,
    'range' => Icons.pin_rounded,
    'operation' => Icons.calculate_rounded,
    'mastery' => Icons.workspace_premium_rounded,
    'grade' => Icons.school_rounded,
    _ => Icons.star_rounded,
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
          actions: [
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
          children: [
            CircleAvatar(radius: 24, child: Icon(icon)),
            const SizedBox(height: 10),
            Text(
              badge.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 5),
            Text(
              '+${badge.stars} Sterne',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

class _RewardRule extends StatelessWidget {
  const _RewardRule({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(text),
            ],
          ),
        ),
      ],
    ),
  );
}
