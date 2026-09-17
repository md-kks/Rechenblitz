import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/grade_level.dart';
import '../german_round_feedback.dart';
import '../german_session.dart';
import '../german_support_catalog.dart';
import '../german_task.dart';

typedef GermanSpeak = Future<void> Function(String text);
typedef GermanSessionComplete = void Function(GermanSessionResult result);

class GermanTrainingScreen extends StatefulWidget {
  const GermanTrainingScreen({
    super.key,
    required this.gradeLevel,
    required this.tasks,
    required this.speak,
    this.speakCompletion = false,
    this.onComplete,
  }) : assert(tasks.length > 0);

  final GradeLevel gradeLevel;
  final List<GermanTask> tasks;
  final GermanSpeak speak;
  final bool speakCompletion;
  final GermanSessionComplete? onComplete;

  @override
  State<GermanTrainingScreen> createState() => _GermanTrainingScreenState();
}

class _GermanTrainingScreenState extends State<GermanTrainingScreen> {
  final TextEditingController _answerController = TextEditingController();
  final List<GermanTaskResult> _results = <GermanTaskResult>[];
  final List<String> _orderedWords = <String>[];

  late final DateTime _startedAt;
  late DateTime _taskStartedAt;
  int _index = 0;
  int _incorrectAttempts = 0;
  bool _completed = false;
  GermanSessionResult? _completedResult;
  String? _feedback;

  GermanTask get _task => widget.tasks[_index];

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _taskStartedAt = _startedAt;
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submit(String answer) {
    if (_completed) return;
    if (!_task.accepts(answer)) {
      setState(() {
        _incorrectAttempts += 1;
        _feedback = 'Noch nicht. Versuch es noch einmal.';
      });
      return;
    }

    final now = DateTime.now();
    _results.add(
      GermanTaskResult(
        taskId: _task.id,
        competencyId: _task.competencyId,
        correctFirstTry: _incorrectAttempts == 0,
        incorrectAttempts: _incorrectAttempts,
        responseMs: now.difference(_taskStartedAt).inMilliseconds,
      ),
    );

    if (_index == widget.tasks.length - 1) {
      final result = GermanSessionResult(
        gradeLevel: widget.gradeLevel,
        startedAt: _startedAt,
        finishedAt: now,
        taskResults: List<GermanTaskResult>.unmodifiable(_results),
      );
      setState(() {
        _completed = true;
        _completedResult = result;
        _feedback = null;
      });
      widget.onComplete?.call(result);
      if (widget.speakCompletion) {
        unawaited(
          widget.speak(GermanRoundFeedback.forSession(result).spokenText),
        );
      }
      return;
    }

    setState(() {
      _index += 1;
      _incorrectAttempts = 0;
      _feedback = null;
      _answerController.clear();
      _orderedWords.clear();
      _taskStartedAt = now;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return _buildCompleted(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Deutsch üben')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            LinearProgressIndicator(value: (_index + 1) / widget.tasks.length),
            const SizedBox(height: 24),
            Text(
              '${_index + 1} von ${widget.tasks.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _task.instruction,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _task.prompt,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInteraction(context),
            if (_feedback != null) ...<Widget>[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  _feedback!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
            if (_incorrectAttempts > 0) ...<Widget>[
              const SizedBox(height: 12),
              _buildSupportCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    final hint = _incorrectAttempts >= 2
        ? GermanSupportCatalog.secondHint(_task.competencyId)
        : GermanSupportCatalog.firstHint(_task.competencyId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Denkhinweis', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(hint),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('german-hint-speak'),
                onPressed: () => widget.speak(hint),
                icon: const Icon(Icons.volume_up_outlined),
                label: const Text('Hinweis anhören'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteraction(BuildContext context) => switch (_task.interaction) {
    GermanTaskInteraction.singleChoice => _buildChoices(),
    GermanTaskInteraction.listeningChoice => _buildListening(),
    GermanTaskInteraction.wordOrder => _buildWordOrder(context),
    GermanTaskInteraction.typedText => _buildTypedAnswer(),
  };

  Widget _buildChoices() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: _task.choices
        .map(
          (choice) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton.tonal(
              onPressed: () => _submit(choice),
              child: Text(choice),
            ),
          ),
        )
        .toList(),
  );

  Widget _buildListening() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      FilledButton.icon(
        onPressed: () => widget.speak(_task.spokenText!),
        icon: const Icon(Icons.volume_up_rounded),
        label: const Text('Anhören'),
      ),
      const SizedBox(height: 16),
      _buildChoices(),
    ],
  );

  Widget _buildWordOrder(BuildContext context) {
    final available = _task.choices
        .where((word) => !_orderedWords.contains(word))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _orderedWords.isEmpty
                ? 'Tippe die Wörter der Reihe nach an.'
                : _orderedWords.join(' '),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: available
              .map(
                (word) => FilledButton.tonal(
                  onPressed: () => setState(() {
                    _orderedWords.add(word);
                    _feedback = null;
                  }),
                  child: Text(word),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: _orderedWords.isEmpty
                    ? null
                    : () => setState(() {
                        _orderedWords.clear();
                        _feedback = null;
                      }),
                child: const Text('Neu ordnen'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _orderedWords.length != _task.choices.length
                    ? null
                    : () => _submit(_orderedWords.join(' ')),
                child: const Text('Prüfen'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypedAnswer() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TextField(
        controller: _answerController,
        minLines: 1,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Deine Antwort',
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) _submit(value);
        },
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: () {
          final value = _answerController.text;
          if (value.trim().isNotEmpty) _submit(value);
        },
        child: const Text('Prüfen'),
      ),
    ],
  );

  Widget _buildCompleted(BuildContext context) {
    final result = _completedResult!;
    final percent = (result.accuracy * 100).round();
    final feedback = GermanRoundFeedback.forSession(result);
    return Scaffold(
      appBar: AppBar(title: const Text('Runde geschafft')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.check_circle_outline_rounded, size: 72),
                const SizedBox(height: 20),
                Text(
                  'Runde geschafft',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  '${result.correctFirstTry} von ${result.total} beim ersten Versuch · $percent %',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (result.incorrectAttempts > 0) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    '${result.incorrectAttempts} zusätzliche Versuche – du bist drangeblieben.',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  feedback.headline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(feedback.detail, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const ValueKey('german-round-feedback-replay'),
                  onPressed: () => widget.speak(feedback.spokenText),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Feedback anhören'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('german-round-done'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fertig'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
