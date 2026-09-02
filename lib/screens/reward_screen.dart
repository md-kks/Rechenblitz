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

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Erfolge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 38,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        '${controller.stars} Sterne',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Nächstes Sternenziel: $goal'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.toDouble(),
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sterne belohnen Üben, Sicherheit, Fortschritt und Dranbleiben. Reine Geschwindigkeit gibt keine Extra-Sterne.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Abzeichen',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (badges.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Noch kein Abzeichen – schon nach den ersten unterschiedlichen Übungsrunden können die ersten Erfolge erscheinen.',
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
                    childAspectRatio: constraints.maxWidth < 390 ? 0.86 : 1.05,
                  ),
                  itemBuilder: (_, index) => _BadgeCard(badge: badges[index]),
                );
              },
            ),
          const SizedBox(height: 22),
          Text(
            'So entstehen Erfolge',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  _RewardRule(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Runde geschafft',
                    text: 'Jede abgeschlossene Runde gibt mindestens einen Stern.',
                  ),
                  _RewardRule(
                    icon: Icons.trending_up_rounded,
                    title: 'Fortschritt',
                    text: 'Deutlich bessere Ergebnisse als in den letzten vergleichbaren Runden geben einen Zusatzstern.',
                  ),
                  _RewardRule(
                    icon: Icons.psychology_alt_rounded,
                    title: 'Drangeblieben',
                    text: 'Eine schwierige Runde trotz Fehlern ordentlich zu Ende zu bringen wird ebenfalls belohnt.',
                  ),
                  _RewardRule(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Meisterschaft',
                    text: 'Mehrere sichere Runden in derselben Lernwelt schalten ein Meisterschaftsabzeichen frei.',
                  ),
                  _RewardRule(
                    icon: Icons.explore_outlined,
                    title: 'Entdecken',
                    text: 'Verschiedene Lernwelten auszuprobieren schaltet Entdecker-Abzeichen frei.',
                  ),
                ],
              ),
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
        _ => Icons.star_rounded,
      };

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23,
                child: Icon(icon),
              ),
              const SizedBox(height: 10),
              Text(
                badge.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Text(
                  badge.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 6),
              Text('+${badge.stars} ★'),
            ],
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      );
}
