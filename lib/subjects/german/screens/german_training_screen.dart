import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/grade_level.dart';
import '../../../models/active_response_timer.dart';
import '../german_round_draft.dart';
import '../german_round_feedback.dart';
import '../german_session.dart';
import '../german_support_catalog.dart';
import '../german_task.dart';

typedef GermanSpeak = Future<void> Function(String text);
typedef GermanNow = DateTime Function();
typedef GermanSessionComplete = void Function(GermanSessionResult result);
typedef GermanDraftChanged = void Function(GermanRoundDraft draft);

class GermanTrainingScreen extends StatefulWidget {
  const GermanTrainingScreen({
    super.key,
    required this.gradeLevel,
    required this.tasks,
    required this.speak,
    this.autoSpeak,
    this.speakCompletion = false,
    this.sessionKind = GermanSessionKind.practice,
    this.supportEnabled = true,
    this.now = DateTime.now,
    this.draft,
    this.onDraftChanged,
    this.onComplete,
  }) : assert(tasks.length > 0);

  final GradeLevel gradeLevel;
  final List<GermanTask> tasks;
  final GermanSpeak speak;
  final GermanSpeak? autoSpeak;
  final bool speakCompletion;
  final GermanSessionKind sessionKind;
  final bool supportEnabled;
  final GermanNow now;
  final GermanRoundDraft? draft;
  final GermanDraftChanged? onDraftChanged;
  final GermanSessionComplete? onComplete;

  @override
  State<GermanTrainingScreen> createState() => _GermanTrainingScreenState();
}

class _GermanTrainingScreenState extends State<GermanTrainingScreen>
    with WidgetsBindingObserver {
  final TextEditingController _answerController = TextEditingController();
  final List<GermanTaskResult> _results = <GermanTaskResult>[];
  final List<String> _orderedWords = <String>[];

  late final DateTime _startedAt;
  late final ActiveResponseTimer _responseTimer;
  int _index = 0;
  int _incorrectAttempts = 0;
  bool _completed = false;
  GermanSessionResult? _completedResult;
  String? _feedback;

  GermanTask get _task => widget.tasks[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialNow = widget.now();
    final draft = widget.draft;
    if (draft != null &&
        draft.gradeLevel == widget.gradeLevel &&
        draft.sessionKind == widget.sessionKind &&
        draft.taskIds.length == widget.tasks.length &&
        draft.taskIds.asMap().entries.every(
          (entry) => widget.tasks[entry.key].id == entry.value,
        ) &&
        draft.currentIndex >= 0 &&
        draft.currentIndex < widget.tasks.length &&
        draft.completedResults.length == draft.currentIndex) {
      _startedAt = draft.startedAt;
      _index = draft.currentIndex;
      _incorrectAttempts = draft.incorrectAttempts;
      _results.addAll(draft.completedResults);
      _responseTimer = ActiveResponseTimer(startedAt: initialNow);
    } else {
      _startedAt = initialNow;
      _responseTimer = ActiveResponseTimer(startedAt: initialNow);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_autoReadCurrentTask());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final now = widget.now();
    if (state == AppLifecycleState.resumed) {
      _responseTimer.resume(at: now);
    } else {
      _responseTimer.pause(at: now);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _answerController.dispose();
    super.dispose();
  }

  void _emitDraft([DateTime? now]) {
    final callback = widget.onDraftChanged;
    if (callback == null || _completed) return;
    callback(
      GermanRoundDraft(
        gradeLevel: widget.gradeLevel,
        taskIds: widget.tasks.map((task) => task.id).toList(growable: false),
        currentIndex: _index,
        startedAt: _startedAt,
        updatedAt: now ?? widget.now(),
        completedResults: List<GermanTaskResult>.unmodifiable(_results),
        incorrectAttempts: _incorrectAttempts,
        assignmentPayload: widget.draft?.assignmentPayload,
        sessionKind: widget.sessionKind,
      ),
    );
  }

  Future<void> _speakWithoutTiming(String text) =>
      _speakWith(widget.speak, text);

  Future<void> _speakWith(GermanSpeak speaker, String text) async {
    final pausedAt = widget.now();
    _responseTimer.pause(at: pausedAt);
    try {
      await speaker(text);
    } finally {
      _responseTimer.resume(at: widget.now());
    }
  }

  Future<void> _autoReadCurrentTask() async {
    final speaker = widget.autoSpeak;
    if (speaker == null || _completed) return;
    final text = _task.requiresSpeech
        ? _task.spokenText!
        : '${_task.instruction} ${_task.prompt}';
    await _speakWith(speaker, text);
  }

  void _submit(String answer) {
    if (_completed) return;
    if (!_task.accepts(answer)) {
      setState(() {
        _incorrectAttempts += 1;
        _feedback = 'Noch nicht. Versuch es noch einmal.';
      });
      _emitDraft();
      return;
    }

    final now = widget.now();
    _results.add(
      GermanTaskResult(
        taskId: _task.id,
        competencyId: _task.competencyId,
        correctFirstTry: _incorrectAttempts == 0,
        incorrectAttempts: _incorrectAttempts,
        responseMs: _responseTimer.elapsed(at: now).inMilliseconds,
      ),
    );

    if (_index == widget.tasks.length - 1) {
      final result = GermanSessionResult(
        gradeLevel: widget.gradeLevel,
        startedAt: _startedAt,
        finishedAt: now,
        taskResults: List<GermanTaskResult>.unmodifiable(_results),
        kind: widget.sessionKind,
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
      _responseTimer.reset(at: now);
    });
    _emitDraft(now);
    unawaited(_autoReadCurrentTask());
  }

  String get _screenTitle => switch (widget.sessionKind) {
    GermanSessionKind.practice => 'Deutsch üben',
    GermanSessionKind.assessment => 'Deutsch-Lerncheck',
    GermanSessionKind.teacherAssignment => 'Deutsch-Schulauftrag',
  };

  String get _completionTitle => switch (widget.sessionKind) {
    GermanSessionKind.practice => 'Runde geschafft',
    GermanSessionKind.assessment => 'Lerncheck geschafft',
    GermanSessionKind.teacherAssignment => 'Schulauftrag geschafft',
  };

  @override
  Widget build(BuildContext context) {
    if (_completed) return _buildCompleted(context);
    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
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
            if (widget.supportEnabled && _incorrectAttempts > 0) ...<Widget>[
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
                onPressed: () => unawaited(_speakWithoutTiming(hint)),
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

  List<String> _presentedChoices() {
    final choices = List<String>.from(_task.choices);
    if (choices.length < 2) return choices;
    final seed = _stablePresentationSeed(
      '${_startedAt.microsecondsSinceEpoch}:$_index:${_task.id}',
    );
    choices.shuffle(Random(seed));
    if (_task.interaction == GermanTaskInteraction.wordOrder &&
        _sameOrder(choices, _task.choices)) {
      final first = choices.removeAt(0);
      choices.add(first);
    }
    return choices;
  }

  int _stablePresentationSeed(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  Widget _buildChoices() {
    final choices = _presentedChoices();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: choices
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton.tonal(
                key: ValueKey('german-choice-${_task.id}-${entry.key}'),
                onPressed: () => _submit(entry.value),
                child: Text(entry.value),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildListening() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      FilledButton.icon(
        onPressed: () => unawaited(_speakWithoutTiming(_task.spokenText!)),
        icon: const Icon(Icons.volume_up_rounded),
        label: const Text('Anhören'),
      ),
      const SizedBox(height: 16),
      _buildChoices(),
    ],
  );

  Widget _buildWordOrder(BuildContext context) {
    final remainingUsed = <String, int>{};
    for (final word in _orderedWords) {
      remainingUsed[word] = (remainingUsed[word] ?? 0) + 1;
    }
    final available = <String>[];
    for (final word in _presentedChoices()) {
      final used = remainingUsed[word] ?? 0;
      if (used > 0) {
        remainingUsed[word] = used - 1;
      } else {
        available.add(word);
      }
    }
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
              .asMap()
              .entries
              .map(
                (entry) => FilledButton.tonal(
                  key: ValueKey('german-word-choice-${_task.id}-${entry.key}'),
                  onPressed: () => setState(() {
                    _orderedWords.add(entry.value);
                    _feedback = null;
                  }),
                  child: Text(entry.value),
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
      appBar: AppBar(title: Text(_completionTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minimumHeight = max(0.0, constraints.maxHeight - 48);
            return SingleChildScrollView(
              key: const ValueKey('german-completion-scroll'),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minimumHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.check_circle_outline_rounded, size: 72),
                      const SizedBox(height: 20),
                      Text(
                        _completionTitle,
                        textAlign: TextAlign.center,
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
                        onPressed: () =>
                            Navigator.of(context).pop(_completedResult),
                        child: const Text('Fertig'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
