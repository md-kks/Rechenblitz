import 'package:flutter/material.dart';

class NumberAnswerPad extends StatefulWidget {
  const NumberAnswerPad({
    super.key,
    required this.maxValue,
    required this.onAnswer,
  });

  final int maxValue;
  final ValueChanged<int> onAnswer;

  @override
  State<NumberAnswerPad> createState() => _NumberAnswerPadState();
}

class _NumberAnswerPadState extends State<NumberAnswerPad> {
  String input = '';

  void _addDigit(int digit) {
    final next = '$input$digit';
    final parsed = int.tryParse(next);
    if (parsed == null || parsed > widget.maxValue) return;
    setState(() => input = next);
  }

  void _backspace() {
    if (input.isEmpty) return;
    setState(() => input = input.substring(0, input.length - 1));
  }

  void _submit() {
    final value = int.tryParse(input);
    if (value == null) return;
    widget.onAnswer(value);
    setState(() => input = '');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.maxValue <= 10) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
        ),
        itemCount: widget.maxValue + 1,
        itemBuilder: (_, i) => FilledButton.tonal(
          onPressed: () => widget.onAnswer(i),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            textStyle:
                const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          child: Text('$i'),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            input.isEmpty ? 'Antwort eingeben' : input,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            for (final digit in [1, 2, 3, 4, 5, 6, 7, 8, 9])
              FilledButton.tonal(
                onPressed: () => _addDigit(digit),
                child: Text('$digit',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800)),
              ),
            FilledButton.tonalIcon(
              onPressed: _backspace,
              icon: const Icon(Icons.backspace_outlined),
              label: const Text('Löschen'),
            ),
            FilledButton.tonal(
              onPressed: () => _addDigit(0),
              child: const Text('0',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            ),
            FilledButton.icon(
              onPressed: input.isEmpty ? null : _submit,
              icon: const Icon(Icons.check_rounded),
              label: const Text('OK'),
            ),
          ],
        ),
      ],
    );
  }
}
