class ActiveResponseTimer {
  ActiveResponseTimer({DateTime? startedAt})
    : _startedAt = startedAt ?? DateTime.now();

  DateTime _startedAt;
  DateTime? _pausedAt;

  bool get isPaused => _pausedAt != null;

  void reset({DateTime? at}) {
    _startedAt = at ?? DateTime.now();
    _pausedAt = null;
  }

  void pause({DateTime? at}) {
    _pausedAt ??= at ?? DateTime.now();
  }

  void resume({DateTime? at}) {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    final resumedAt = at ?? DateTime.now();
    if (resumedAt.isAfter(pausedAt)) {
      _startedAt = _startedAt.add(resumedAt.difference(pausedAt));
    }
    _pausedAt = null;
  }

  Duration elapsed({DateTime? at}) {
    final reference = _pausedAt ?? at ?? DateTime.now();
    final value = reference.difference(_startedAt);
    return value.isNegative ? Duration.zero : value;
  }
}
