class GermanNumberWords {
  const GermanNumberWords._();

  static String spell(int value) {
    if (value < 0 || value > 1000000) {
      throw RangeError.range(value, 0, 1000000, 'value');
    }
    if (value == 1000000) return 'eine Million';
    if (value == 0) return 'null';
    return _underMillion(value);
  }

  static String _underMillion(int value) {
    if (value < 1000) return _underThousand(value);
    final thousands = value ~/ 1000;
    final rest = value % 1000;
    final prefix = thousands == 1
        ? 'eintausend'
        : '${_compoundUnderThousand(thousands)}tausend';
    return rest == 0 ? prefix : '$prefix${_underThousand(rest)}';
  }

  static String _compoundUnderThousand(int value) {
    if (value == 1) return 'ein';
    return _underThousand(value, compoundOne: true);
  }

  static String _underThousand(
    int value, {
    bool compoundOne = false,
  }) {
    if (value < 100) return _underHundred(value, compoundOne: compoundOne);
    final hundreds = value ~/ 100;
    final rest = value % 100;
    final prefix = hundreds == 1
        ? 'einhundert'
        : '${_unit(hundreds, compound: true)}hundert';
    if (rest == 0) return prefix;
    return '$prefix${_underHundred(rest, compoundOne: true)}';
  }

  static String _underHundred(
    int value, {
    bool compoundOne = false,
  }) {
    if (value < 10) return _unit(value, compound: compoundOne);
    const direct = <int, String>{
      10: 'zehn',
      11: 'elf',
      12: 'zwölf',
      13: 'dreizehn',
      14: 'vierzehn',
      15: 'fünfzehn',
      16: 'sechzehn',
      17: 'siebzehn',
      18: 'achtzehn',
      19: 'neunzehn',
    };
    final directValue = direct[value];
    if (directValue != null) return directValue;

    const tensWords = <int, String>{
      2: 'zwanzig',
      3: 'dreißig',
      4: 'vierzig',
      5: 'fünfzig',
      6: 'sechzig',
      7: 'siebzig',
      8: 'achtzig',
      9: 'neunzig',
    };
    final tens = value ~/ 10;
    final ones = value % 10;
    if (ones == 0) return tensWords[tens]!;
    return '${_unit(ones, compound: true)}und${tensWords[tens]}';
  }

  static String _unit(int value, {required bool compound}) => switch (value) {
        0 => '',
        1 => compound ? 'ein' : 'eins',
        2 => 'zwei',
        3 => 'drei',
        4 => 'vier',
        5 => 'fünf',
        6 => 'sechs',
        7 => 'sieben',
        8 => 'acht',
        9 => 'neun',
        _ => throw RangeError.range(value, 0, 9, 'value'),
      };
}
