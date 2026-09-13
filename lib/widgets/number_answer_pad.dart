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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = screenHeight < 720;
    final maxPadWidth = compact ? 420.0 : 520.0;
    final keyHeight = compact ? 44.0 : 58.0;
    final gap = compact ? 5.0 : 10.0;
    final inputHeight = compact ? 48.0 : 64.0;

    if (widget.maxValue <= 10) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxPadWidth),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              mainAxisExtent: compact ? 48 : 64,
            ),
            itemCount: widget.maxValue + 1,
            itemBuilder: (_, i) => FilledButton.tonal(
              onPressed: () => widget.onAnswer(i),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: TextStyle(
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text('$i'),
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxPadWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: const ValueKey('number-pad-input'),
              width: double.infinity,
              constraints: BoxConstraints(minHeight: inputHeight),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 18,
                vertical: compact ? 6 : 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(compact ? 14 : 18),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                input.isEmpty ? 'Antwort eingeben' : input,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: compact ? 24 : null,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            SizedBox(height: compact ? 7 : 12),
            GridView.count(
              key: const ValueKey('number-pad-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              mainAxisExtent: keyHeight,
              children: [
                for (final digit in [1, 2, 3, 4, 5, 6, 7, 8, 9])
                  FilledButton.tonal(
                    onPressed: () => _addDigit(digit),
                    child: Text(
                      '$digit',
                      style: TextStyle(
                        fontSize: compact ? 23 : 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                FilledButton.tonal(
                  onPressed: _backspace,
                  child: const _PadActionLabel(
                    icon: Icons.backspace_outlined,
                    label: 'Löschen',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => _addDigit(0),
                  child: Text(
                    '0',
                    style: TextStyle(
                      fontSize: compact ? 23 : 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton(
                  key: const ValueKey('number-pad-submit'),
                  onPressed: input.isEmpty ? null : _submit,
                  child: const _PadActionLabel(
                    icon: Icons.check_rounded,
                    label: 'OK',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PadActionLabel extends StatelessWidget {
  const _PadActionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      );
}
