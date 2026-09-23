import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/models/curriculum_exercise.dart';
import 'package:rechenblitz/models/german_number_words.dart';
import 'package:rechenblitz/models/math_fact.dart';
import 'package:rechenblitz/models/micro_competency.dart';
import 'package:rechenblitz/models/structured_exercise.dart';
import 'package:rechenblitz/models/training.dart';
import 'package:rechenblitz/services/adaptive_engine.dart';
import 'package:rechenblitz/services/app_controller.dart';

List<String> _parts(String key) {
  if (key.startsWith('story:transfer:')) return key.split(':');
  return key
      .split(':')
      .where(
        (part) =>
            part != 'transfer' && part != 'context' && part != 'observation',
      )
      .toList();
}

int _i(String value) => int.parse(value);

int? _expectedNumeric(String key) {
  final p = _parts(key);
  if (p.isEmpty) return null;

  if (p[0] == 'wall' && p.length == 3 && p[1].contains('-')) {
    final values = p[1].split('-').map(_i).toList();
    final hidden = _i(p[2]);
    if (hidden >= 0 && hidden < values.length) return values[hidden];
  }
  if (p[0] == 'gap' && p.length >= 5) {
    final a = _i(p[2]);
    final b = _i(p[3]);
    return p[4] == 'b' ? b : a;
  }
  if (p[0] == 'neighbor' && p.length >= 3) {
    final n = _i(p[1]);
    return p[2] == 'before' ? n - 1 : n + 1;
  }
  if (p[0] == 'place' && p.length >= 2) return _i(p[1]);
  if (p[0] == 'double' && p.length >= 2) return _i(p[1]) * 2;
  if (p[0] == 'half' && p.length >= 2) return _i(p[1]) ~/ 2;
  if (p[0] == 'sequence' && p.length >= 4) {
    final start = _i(p[2]);
    final step = _i(p[3]);
    return p[1] == '+' ? start + step * 3 : start - step * 3;
  }

  if (p[0] == 'family' && p.length >= 4) {
    return _i(p[2]);
  }
  if (p[0] == 'geometry' && p.length >= 3) {
    const count = <String, int>{
      'triangle': 3,
      'square': 4,
      'rectangle': 4,
      'circle': 0,
    };
    if (p[1] == 'corners' || p[1] == 'sides') return count[p[2]];
  }

  if (key.startsWith('story:transfer:skill:')) {
    final raw = key.split(':');
    if (raw.length >= 8) {
      final op = raw[4];
      final a = _i(raw[6]);
      final b = _i(raw[7]);
      return switch (op) {
        '+' => a + b,
        '-' => a - b,
        'x' => a * b,
        'divide' => a ~/ b,
        _ => null,
      };
    }
  }
  if (p[0] == 'story' && p.length >= 2) {
    if ((p[1] == '+' || p[1] == '-' || p[1] == 'x') && p.length >= 5) {
      final a = _i(p[p.length - 2]);
      final b = _i(p[p.length - 1]);
      return p[1] == '+'
          ? a + b
          : p[1] == '-'
          ? a - b
          : a * b;
    }
    if (p[1] == 'divide' && p.length >= 5) {
      return _i(p[p.length - 2]) ~/ _i(p[p.length - 1]);
    }
    if (p[1] == 'sharing' && p.length >= 5) {
      return _i(p[p.length - 2]) ~/ _i(p[p.length - 1]);
    }
    if (p[1] == 'grouping' && p.length >= 5) {
      return _i(p[p.length - 2]) ~/ _i(p[p.length - 1]);
    }
    if (p[1] == 'calc' && p.length >= 5) {
      final op = p[2];
      final a = _i(p[3]);
      final b = _i(p[4]);
      return switch (op) {
        '+' => a + b,
        '-' => a - b,
        'x' => a * b,
        'divide' => a ~/ b,
        _ => null,
      };
    }
    if (p[1] == 'multi' && p.length >= 6) {
      if (p[2] == 'library') return _i(p[3]) + _i(p[4]) - _i(p[5]);
      if (p[2] == 'boxes') return _i(p[3]) * _i(p[4]) - _i(p[5]);
    }
    if (p[1] == 'transfer' && p.length >= 4) {
      if (p[2] == 'difference' && p.length >= 5) {
        return (_i(p[3]) - _i(p[4])).abs();
      }
      if (p[2] == 'reverse' && p.length >= 5) {
        return _i(p[3]) + _i(p[4]);
      }
    }
  }

  if (p[0] == 'money' && p.length >= 3) {
    if (p[1] == 'change' && p.length >= 5) return _i(p[3]) - _i(p[4]);
    if (p[1] == 'add' && p.length >= 5) return _i(p[3]) + _i(p[4]);
    if (p[1] == 'missing' && p.length >= 5) return _i(p[3]) - _i(p[4]);
    if (p[1] == 'coins' && p.length >= 4) return _i(p[3]);
    if (p[1] == 'convert' && p.length >= 4) return _i(p[3]) * 100;
    if (p[1] == 'euro' && p.length >= 3) return _i(p[2]) * 100;
  }

  if (p[0] == 'measure' && p.length >= 3) {
    if (p[1] == 'add' && p.length >= 5) return _i(p[3]) + _i(p[4]);
    if (p[1] == 'subtract' && p.length >= 5) return _i(p[3]) - _i(p[4]);
    if (p[1] == 'convert' && p.length >= 4) {
      final kind = p[2];
      final value = _i(p[3]);
      return switch (kind) {
        'dm-cm' => value * 10,
        'm-cm' => value * 100,
        'cm-mm' => value * 10,
        'cm-m' => value ~/ 100,
        _ => null,
      };
    }
  }

  if (p[0] == 'large' && p.length >= 3) {
    if (p[1] == 'neighbor') {
      final n = _i(p[2]);
      return p[3] == 'true' ? n + 1 : n - 1;
    }
    if (p[1] == 'place' && p.length >= 4) {
      final n = _i(p[2]);
      final place = _i(p[3]);
      return (n ~/ place) % 10;
    }
    if (p[1] == 'decompose') return _i(p[2]);
  }

  if (p[0] == 'roman' && p.length >= 3 && p[1] == 'read') {
    return _i(p[2]);
  }
  if (p[0] == 'round' && p.length >= 3) {
    final n = _i(p[1]);
    final place = _i(p[2]);
    return ((n + place ~/ 2) ~/ place) * place;
  }
  if (p[0] == 'mental' && p.length >= 4) {
    final a = _i(p[2]);
    final b = _i(p[3]);
    return p[1] == '+' ? a + b : a - b;
  }
  if (p[0] == 'written' && p.length >= 4) {
    final a = _i(p[p.length - 2]);
    final b = _i(p[p.length - 1]);
    return switch (p[1]) {
      '+' => a + b,
      '-' => a - b,
      'x' => a * b,
      'divide' => a ~/ b,
      _ => null,
    };
  }
  if (p[0] == 'law' && p.length >= 4 && p[1] == 'distribute') {
    final a = _i(p[2]);
    final b = _i(p[3]);
    final rounded = ((b + 9) ~/ 10) * 10;
    return a * (rounded - b);
  }

  if (p[0] == 'fraction' && p.length >= 3) {
    if (p[1] == 'half') return _i(p[2]) ~/ 2;
    if (p[1] == 'quarter') return _i(p[2]) ~/ 4;
    if (p[1] == 'parts' && p.length >= 5) {
      return _i(p[4]) ~/ _i(p[3]) * _i(p[2]);
    }
  }

  if (p[0] == 'length' && p.length >= 3) {
    final value = _i(p.last);
    return switch (p[1]) {
      'm' => value * 100,
      'km' => value * 1000,
      'cm-mm' => value * 10,
      _ => null,
    };
  }
  if (p[0] == 'mass' && p.length >= 3) {
    final value = _i(p.last);
    return p[1] == 'kg'
        ? value * 1000
        : p[1] == 't-kg'
        ? value * 1000
        : null;
  }
  if (p[0] == 'volume' && p.length == 3 && p[1] == 'l') {
    return _i(p[2]) * 1000;
  }
  if (p[0] == 'time' && p.length >= 3) {
    if (p[1] == 'min') return _i(p.last) ~/ 60;
    if (p[1] == 'seconds' && p.length >= 4) {
      if (p[2] == 'min-to-sec') return _i(p.last) * 60;
      if (p[2] == 'sec-to-min') return _i(p.last) ~/ 60;
    }
  }

  if (p[0] == 'duration' && p.length >= 3) {
    if (p[1] == 'weeks') return _i(p[2]) * 7;
    if (p[1] == 'days') return _i(p[2]) * 24;
    return _i(p[2]);
  }

  if (p[0] == 'data' && p.length >= 3) {
    if (p[1] == 'tally') return _i(p[2]);
    if (p[1] == 'max' || p[1] == 'sum' || p[1] == 'diff') {
      final values = p[2].split('-').map(_i).toList();
      if (p[1] == 'max') return values.reduce(max);
      if (p[1] == 'sum') return values.reduce((a, b) => a + b);
      return (values[0] - values[1]).abs();
    }
  }

  if (p[0] == 'combo' && p.length >= 5) {
    return _i(p[2]) * _i(p[3]) * _i(p[4]);
  }
  if (p[0] == 'proportion' && p.length >= 5) {
    return _i(p[2]) * _i(p[4]);
  }
  if (p[0] == 'rect' && p.length >= 5) {
    final width = _i(p[p.length - 2]);
    final height = _i(p[p.length - 1]);
    return p[1] == 'area' ? width * height : 2 * (width + height);
  }
  if (p[0] == 'plan' && p.length >= 4) {
    if (p[1] == 'path') return _i(p[2]) + _i(p[3]);
    if (p[1] == 'scale') return _i(p[2]) * _i(p[3]);
  }
  if (p[0] == 'volume' && p.length >= 4) {
    return _i(p[1]) * _i(p[2]) * _i(p[3]);
  }
  if (p[0] == 'body' && p.length >= 3) {
    if (p[1] == 'cube-net' && p[2] == 'faces') return 6;
    const properties = <String, Map<String, int>>{
      'Würfel': {'Ecken': 8, 'Kanten': 12, 'Flächen': 6},
      'Quader': {'Ecken': 8, 'Kanten': 12, 'Flächen': 6},
      'Kugel': {'Ecken': 0, 'Kanten': 0, 'Flächen': 1},
      'Zylinder': {'Ecken': 0, 'Kanten': 2, 'Flächen': 3},
      'Kegel': {'Ecken': 1, 'Kanten': 1, 'Flächen': 2},
      'Pyramide': {'Ecken': 5, 'Kanten': 8, 'Flächen': 5},
    };
    return properties[p[1]]?[p[2]];
  }
  if (p[0] == 'symmetry' && p.length == 2) {
    const axes = <String, int>{
      'Quadrat': 4,
      'Rechteck': 2,
      'gleichseitiges Dreieck': 3,
      'gleichschenkliges Dreieck': 1,
    };
    return axes[p[1]];
  }
  return null;
}

void _verifyTask({
  required String label,
  required String key,
  required int answer,
  required List<String>? choices,
  required List<String> failures,
  required int Function() checked,
  required void Function(int) setChecked,
}) {
  if (choices != null && choices.isNotEmpty) return;
  final expected = _expectedNumeric(key);
  if (expected == null) return;
  setChecked(checked() + 1);
  if (answer != expected) {
    failures.add('$label | $key | expected=$expected actual=$answer');
  }
}

void main() {
  test('generated numeric answers agree with independent key mathematics', () {
    final controller = AppController();
    final failures = <String>[];
    var checked = 0;

    for (final definition in MicroCompetencyCatalog.definitions) {
      final grade = definition.minGrade;
      final range = NumberRangeLevel.values.firstWhere(
        (value) =>
            value.index >= grade.recommendedRange.index &&
            value.index >= definition.minNumberRange.index,
      );
      final maxValue = range.maxValue;
      for (final transfer in <bool>[false, true]) {
        final mode = transfer
            ? controller.transferModeFor(definition.id)
            : definition.preferredMode;
        if (!mode.isStructured && !mode.isUpperPrimary) continue;
        for (var seed = 0; seed < 96; seed++) {
          final label = '${definition.id.name}/${transfer ? "T" : "N"}/$seed';
          if (mode.isStructured) {
            final task =
                StructuredExerciseGenerator(
                  random: Random(
                    1410000 +
                        definition.id.index * 1000 +
                        seed +
                        (transfer ? 500 : 0),
                  ),
                ).generate(
                  mode: mode,
                  gradeLevel: grade,
                  maxValue: maxValue,
                  targetCompetency: definition.id,
                  transferEmphasis: transfer,
                );
            _verifyTask(
              label: label,
              key: task.key,
              answer: task.answer,
              choices: task.choices,
              failures: failures,
              checked: () => checked,
              setChecked: (value) => checked = value,
            );
          } else {
            final task =
                CurriculumExerciseGenerator(
                  random: Random(
                    1510000 +
                        definition.id.index * 1000 +
                        seed +
                        (transfer ? 500 : 0),
                  ),
                ).generate(
                  mode: mode,
                  gradeLevel: grade,
                  maxValue: maxValue,
                  targetCompetency: definition.id,
                  transferEmphasis: transfer,
                );
            _verifyTask(
              label: label,
              key: task.key,
              answer: task.answer,
              choices: task.choices,
              failures: failures,
              checked: () => checked,
              setChecked: (value) => checked = value,
            );
          }
        }
      }
    }

    for (final grade in GradeLevel.values) {
      final maxValue = grade.recommendedRange.maxValue;
      for (final mode in TrainingMode.values) {
        if (!mode.isStructured && !mode.isUpperPrimary) continue;
        if (mode.isUpperPrimary && grade.index < GradeLevel.third.index) {
          continue;
        }
        for (var seed = 0; seed < 64; seed++) {
          final label = '${grade.name}/${mode.name}/$seed';
          if (mode.isStructured) {
            final task =
                StructuredExerciseGenerator(
                  random: Random(
                    1610000 + grade.index * 10000 + mode.index * 100 + seed,
                  ),
                ).generate(
                  mode: mode,
                  gradeLevel: grade,
                  maxValue: maxValue,
                  transferEmphasis:
                      mode == TrainingMode.wordProblems && seed.isOdd,
                );
            _verifyTask(
              label: label,
              key: task.key,
              answer: task.answer,
              choices: task.choices,
              failures: failures,
              checked: () => checked,
              setChecked: (value) => checked = value,
            );
          } else {
            final task = CurriculumExerciseGenerator(
              random: Random(
                1710000 + grade.index * 10000 + mode.index * 100 + seed,
              ),
            ).generate(mode: mode, gradeLevel: grade, maxValue: maxValue);
            _verifyTask(
              label: label,
              key: task.key,
              answer: task.answer,
              choices: task.choices,
              failures: failures,
              checked: () => checked,
              setChecked: (value) => checked = value,
            );
          }
        }
      }
    }

    expect(checked, greaterThan(4000));
    expect(failures, isEmpty, reason: failures.take(120).join('\n'));
  });
  _registerChoiceAudit();
  _registerFactAudit();
}

String _fmt(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}

String _roman(int value) {
  const values = <(int, String)>[
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];
  var remaining = value;
  final out = StringBuffer();
  for (final item in values) {
    while (remaining >= item.$1) {
      out.write(item.$2);
      remaining -= item.$1;
    }
  }
  return out.toString();
}

String? _expectedChoiceText(String key) {
  final p = _parts(key);
  if (p.length >= 4 && p[0] == 'large' && p[1] == 'compare') {
    final a = _i(p[2]);
    final b = _i(p[3]);
    return a > b
        ? '>'
        : a < b
        ? '<'
        : '=';
  }
  if (p.length >= 3 && p[0] == 'large' && p[1] == 'order') {
    final values = p[2].split('-').map(_i).toList()..sort();
    return values.map(_fmt).join(' < ');
  }
  if (p.length >= 4 && p[0] == 'large' && p[1] == 'word' && p[2] == 'read') {
    return _fmt(_i(p[3]));
  }
  if (p.length >= 4 && p[0] == 'large' && p[1] == 'word' && p[2] == 'write') {
    return GermanNumberWords.spell(_i(p[3]));
  }
  if (p.length >= 3 && p[0] == 'roman' && p[1] == 'write') {
    return _roman(_i(p[2]));
  }
  if (p.length >= 4 && p[0] == 'written' && p[1] == 'divide-rest') {
    final dividend = _i(p[2]);
    final divisor = _i(p[3]);
    return '${dividend ~/ divisor} Rest ${dividend % divisor}';
  }
  if (p.length >= 4 && p[0] == 'estimate') {
    final a = _i(p[1]);
    final b = _i(p[2]);
    final place = _i(p[3]);
    final roundedA = ((a + place ~/ 2) ~/ place) * place;
    final roundedB = ((b + place ~/ 2) ~/ place) * place;
    return _fmt(roundedA + roundedB);
  }
  if (p.length >= 2 && p[0] == 'fraction') {
    if (p[1] == 'time') return '45 min';
    if (p[1] == 'volume') return '250 ml';
  }
  if (p.length >= 5 && p[0] == 'calendar' && p[1] == 'add') {
    final month = p[2];
    final start = _i(p[3]);
    final add = _i(p[4]);
    return '${start + add}. $month';
  }
  if (p.length >= 4 && p[0] == 'data' && p[1] == 'representation') {
    const choices = ['Strichliste', 'Tabelle', 'Balkendiagramm'];
    return choices[_i(p[2]) % 3];
  }
  if (p.length >= 3 && p[0] == 'prob') {
    if (p[1] == 'sure') return 'sicher';
    if (p[1] == 'possible') return 'möglich';
    if (p[1] == 'impossible') return 'unmöglich';
    if (p[1] == 'bag' && p.length >= 5) {
      final red = _i(p[p.length - 2]);
      final blue = _i(p[p.length - 1]);
      return red == blue
          ? 'gleich wahrscheinlich'
          : red > blue
          ? 'Rot wahrscheinlicher'
          : 'Blau wahrscheinlicher';
    }
    if (p[1] == 'experiment' && p.length >= 5) {
      if (p[2] == 'compare') {
        final red = _i(p[4]);
        final blue = _i(p[5]);
        return red == blue
            ? 'beide gleich oft'
            : red > blue
            ? 'Rot kam häufiger vor'
            : 'Blau kam häufiger vor';
      }
      if (p[2] == 'relative') {
        final trials = _i(p[3]);
        final red = _i(p[4]);
        return '${(red * 100 / trials).round()} %';
      }
    }
  }
  if (p.length >= 3 && p[0] == 'geomrel') {
    if (p[1] == 'lines') {
      return p[2] == 'parallel' ? 'parallel' : 'senkrecht';
    }
    if (p[1] == 'angle') {
      final relation = p[2];
      return switch (relation) {
        'smaller' => 'spitzer Winkel',
        'equal' || 'right' => 'rechter Winkel',
        'larger' => 'stumpfer Winkel',
        _ => null,
      };
    }
    if (p[1] == 'figure') {
      const figures = [
        'Quadrat',
        'Rechteck',
        'gleichseitiges Dreieck',
        'gleichschenkliges Dreieck',
      ];
      return figures[_i(p[2])];
    }
    if (p[1] == 'circle') {
      return switch (p[2]) {
        'radius' => 'Radius',
        'diameter' => 'Durchmesser',
        'center' => 'Mittelpunkt',
        _ => null,
      };
    }
  }
  if (p.length >= 3 && p[0] == 'body' && p[1] == 'cube-net') {
    if (p[2] == 'description') {
      return '6 Quadrate, die sich ohne Überlappung zum Würfel falten lassen';
    }
    if (p[2] == 'fold' && p.length >= 4) {
      return p[3] == 'yes'
          ? 'Ja, es lässt sich falten'
          : 'Nein, es lässt sich nicht falten';
    }
  }
  if (p.length >= 6 && p[0] == 'plan' && p[1] == 'route') {
    const direction = <String, String>{
      'right': 'nach rechts',
      'up': 'nach oben',
      'left': 'nach links',
      'down': 'nach unten',
    };
    return '${p[3]} Felder ${direction[p[2]]}, dann '
        '${p[5]} Felder ${direction[p[4]]}';
  }
  if (p.length >= 4 && p[0] == 'story') {
    if (p[1] == 'info') {
      if (p[2] == 'trip' && p.length >= 6) {
        return '${p[3]} Kinder und ${p[4]} Erwachsene';
      }
      if (p[2] == 'pencils' && p.length >= 6) {
        return '${p[3]} rote und ${p[4]} blaue Stifte';
      }
      if (p[2] == 'groups' && p.length >= 6) {
        return '${p[3]} und ${p[4]} Kinder';
      }
    }
    if (p[1] == 'operation' && p.length >= 3) {
      return switch (p[2]) {
        '+' => 'Plus (+)',
        '-' => 'Minus (−)',
        'x' => 'Mal (×)',
        'divide' => 'Geteilt (÷)',
        _ => null,
      };
    }
    if (p[1] == 'equation' && p.length >= 5) {
      final op = p[2];
      return '${p[3]} ${op == 'x'
          ? '×'
          : op == 'divide'
          ? '÷'
          : op == '-'
          ? '−'
          : '+'} ${p[4]}';
    }
    if (p[1] == 'interpret' && p.length >= 6) {
      final result = p[5];
      return p[2] == '+'
          ? 'Mara hat jetzt $result Sticker.'
          : 'Es bleiben $result Karten übrig.';
    }
    if (p[1] == 'transfer' && p.length >= 6 && p[2] == 'irrelevant') {
      return '${p[3]} + ${p[4]}';
    }
  }

  if (p.length >= 3 && p[0] == 'clock') {
    return '${p[1]}:${_i(p[2]).toString().padLeft(2, '0')} Uhr';
  }
  if (p.length >= 3 && p[0] == 'geometry' && p[1] == 'name') {
    return switch (p[2]) {
      'triangle' => 'Dreieck',
      'square' => 'Quadrat',
      'rectangle' => 'Rechteck',
      'circle' => 'Kreis',
      _ => null,
    };
  }
  return null;
}

String? _expectedCheckpointText(String taskKey, String checkpointKey) {
  final p = _parts(taskKey);
  if (checkpointKey == 'inverseOperationChoice' && p.length >= 4) {
    final b = p.last;
    if (p[0] == 'family' && p[1] == 'x') return '÷$b';
    if (p[0] == 'family' && p[1] == '+') return '−$b';
  }
  if (checkpointKey == 'sequenceStepSize' && p.length >= 4) {
    return 'immer ${p[1] == '+' ? '+' : '−'}${p[3]}';
  }
  if (checkpointKey == 'doubleHalfMeaning') {
    return p[0] == 'double'
        ? 'zweimal dieselbe Menge zusammen'
        : p[0] == 'half'
        ? 'in zwei gleich große Teile teilen'
        : null;
  }
  if (checkpointKey == 'divisionTargetQuantity' && p.length >= 2) {
    if (p[1] == 'sharing') return 'Menge in jeder Gruppe';
    if (p[1] == 'grouping') return 'Anzahl der Gruppen';
  }
  if (checkpointKey == 'moneyOperationChoice' && p.length >= 2) {
    return p[1] == 'add' ? 'Plus (+)' : 'Minus (−)';
  }
  if (checkpointKey == 'measureOperationChoice' && p.length >= 2) {
    return p[1] == 'add' ? 'Plus (+)' : 'Minus (−)';
  }
  if (checkpointKey == 'wallOperationChoice' &&
      p.length == 3 &&
      p[0] == 'wall') {
    return _i(p[2]) >= 3 ? 'Plus (+)' : 'Minus (−)';
  }
  return null;
}

void _verifyChoices({
  required String label,
  required String key,
  required int answer,
  required List<String>? choices,
  required List<String> failures,
  required void Function() counted,
}) {
  if (choices == null || choices.isEmpty) return;
  final expected = _expectedChoiceText(key);
  if (expected == null) return;
  counted();
  if (answer < 0 || answer >= choices.length || choices[answer] != expected) {
    failures.add(
      '$label | $key | expectedChoice=$expected '
      'actualIndex=$answer choices=$choices',
    );
  }
}

void _verifyCheckpoints({
  required String label,
  required String taskKey,
  required List<ExerciseCheckpoint> checkpoints,
  required List<String> failures,
  required void Function() counted,
}) {
  for (final checkpoint in checkpoints) {
    final expected = _expectedCheckpointText(taskKey, checkpoint.key);
    if (expected == null) continue;
    counted();
    final index = checkpoint.correctChoice;
    if (index < 0 ||
        index >= checkpoint.choices.length ||
        checkpoint.choices[index] != expected) {
      failures.add(
        '$label | $taskKey | checkpoint=${checkpoint.key} '
        'expected=$expected actual=$index choices=${checkpoint.choices}',
      );
    }
  }
}

void _registerChoiceAudit() {
  test(
    'generated choice answers and checkpoints match independent semantics',
    () {
      final controller = AppController();
      final failures = <String>[];
      var choiceChecked = 0;
      var checkpointChecked = 0;

      for (final definition in MicroCompetencyCatalog.definitions) {
        final grade = definition.minGrade;
        final range = NumberRangeLevel.values.firstWhere(
          (value) =>
              value.index >= grade.recommendedRange.index &&
              value.index >= definition.minNumberRange.index,
        );
        final maxValue = range.maxValue;
        for (final transfer in <bool>[false, true]) {
          final mode = transfer
              ? controller.transferModeFor(definition.id)
              : definition.preferredMode;
          if (!mode.isStructured && !mode.isUpperPrimary) continue;
          for (var seed = 0; seed < 96; seed++) {
            final label = '${definition.id.name}/${transfer ? "T" : "N"}/$seed';
            if (mode.isStructured) {
              final task =
                  StructuredExerciseGenerator(
                    random: Random(
                      1810000 +
                          definition.id.index * 1000 +
                          seed +
                          (transfer ? 500 : 0),
                    ),
                  ).generate(
                    mode: mode,
                    gradeLevel: grade,
                    maxValue: maxValue,
                    targetCompetency: definition.id,
                    transferEmphasis: transfer,
                  );
              _verifyChoices(
                label: label,
                key: task.key,
                answer: task.answer,
                choices: task.choices,
                failures: failures,
                counted: () => choiceChecked++,
              );
              _verifyCheckpoints(
                label: label,
                taskKey: task.key,
                checkpoints: task.checkpoints,
                failures: failures,
                counted: () => checkpointChecked++,
              );
            } else {
              final task =
                  CurriculumExerciseGenerator(
                    random: Random(
                      1910000 +
                          definition.id.index * 1000 +
                          seed +
                          (transfer ? 500 : 0),
                    ),
                  ).generate(
                    mode: mode,
                    gradeLevel: grade,
                    maxValue: maxValue,
                    targetCompetency: definition.id,
                    transferEmphasis: transfer,
                  );
              _verifyChoices(
                label: label,
                key: task.key,
                answer: task.answer,
                choices: task.choices,
                failures: failures,
                counted: () => choiceChecked++,
              );
            }
          }
        }
      }

      expect(choiceChecked, greaterThan(1000));
      expect(checkpointChecked, greaterThan(300));
      expect(failures, isEmpty, reason: failures.take(120).join('\n'));
    },
  );
}

void _registerFactAudit() {
  test('fact pool results match independent arithmetic', () {
    final facts = AdaptiveEngine.buildFactPool(maxValue: 100);
    expect(facts, isNotEmpty);
    for (final fact in facts) {
      final expected = switch (fact.operation) {
        MathOperation.plus => fact.a + fact.b,
        MathOperation.minus => fact.a - fact.b,
        MathOperation.multiply => fact.a * fact.b,
        MathOperation.divide => fact.b == 0 ? 0 : fact.a ~/ fact.b,
      };
      expect(
        fact.result,
        expected,
        reason: '${fact.operation.name}:${fact.a}:${fact.b}',
      );
    }
  });
}
