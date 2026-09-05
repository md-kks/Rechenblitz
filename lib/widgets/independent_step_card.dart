import 'package:flutter/material.dart';

class IndependentStepCard extends StatelessWidget {
  const IndependentStepCard({
    super.key,
    required this.question,
    required this.choices,
    required this.index,
    required this.total,
    required this.feedback,
    required this.locked,
    required this.onChoice,
  });

  final String question;
  final List<String> choices;
  final int index;
  final int total;
  final String feedback;
  final bool locked;
  final ValueChanged<int> onChoice;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Schritt ${index + 1} von $total',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                question,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...List.generate(
                choices.length,
                (choiceIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonal(
                    onPressed: locked
                        ? null
                        : () => onChoice(choiceIndex),
                    child: Text(choices[choiceIndex]),
                  ),
                ),
              ),
              if (feedback.isNotEmpty)
                Text(
                  feedback,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
      );
}
