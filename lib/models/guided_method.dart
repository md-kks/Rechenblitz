import 'dart:math';

import 'learning_methods.dart';
import 'math_fact.dart';
import 'micro_competency.dart';
import 'training.dart';

enum HelpLevel { none, nudge, visual, guided }

extension HelpLevelX on HelpLevel {
  int get value => index;

  String get label => switch (this) {
        HelpLevel.none => 'Ohne Hilfe',
        HelpLevel.nudge => 'Denkhinweis',
        HelpLevel.visual => 'Darstellung',
        HelpLevel.guided => 'Geführter Rechenweg',
      };
}

class GuidedMethodStep {
  const GuidedMethodStep({
    required this.title,
    required this.instruction,
    this.question,
    this.choices = const <String>[],
    this.correctChoice,
  });

  final String title;
  final String instruction;
  final String? question;
  final List<String> choices;
  final int? correctChoice;

  bool get isInteractive =>
      question != null && choices.isNotEmpty && correctChoice != null;
}

class GuidedMethodGuide {
  const GuidedMethodGuide({
    required this.methodKey,
    required this.methodLabel,
    required this.nudge,
    required this.steps,
  });

  final String methodKey;
  final String methodLabel;
  final String nudge;
  final List<GuidedMethodStep> steps;
}

class GuidedMethodFactory {
  const GuidedMethodFactory._();

  static GuidedMethodGuide forTask({
    required TrainingMode mode,
    required String taskKey,
    required int expected,
    required MethodPreferences preferences,
    MicroCompetencyId? targetCompetency,
    MathFact? fact,
  }) {
    if (taskKey.startsWith('process:strategy:')) {
      return _strategyChoiceGuide(taskKey);
    }

    if (taskKey.startsWith('process:error:')) {
      return _errorCheckingGuide(taskKey);
    }

    if (taskKey.startsWith('process:plausibility:')) {
      return _plausibilityGuide(taskKey);
    }

    if (taskKey.startsWith('process:representation:')) {
      return _representationGuide(taskKey);
    }

    if (fact != null &&
        fact.operation == MathOperation.minus &&
        _needsSubtractionBridge(fact)) {
      return _subtractionBridge(fact, preferences);
    }

    if (fact != null && fact.operation == MathOperation.multiply) {
      return _multiplication(fact, preferences);
    }

    if (mode == TrainingMode.writtenAddSub &&
        taskKey.contains(':-:')) {
      final numbers = _numbers(taskKey);
      if (numbers.length >= 2) {
        return _writtenSubtraction(
          numbers[numbers.length - 2],
          numbers.last,
          expected,
          preferences,
        );
      }
    }

    if (mode == TrainingMode.wordProblems ||
        targetCompetency == MicroCompetencyId.wordProblemOperation ||
        taskKey.startsWith('story:')) {
      return _wordProblem(taskKey);
    }

    if (mode == TrainingMode.advancedMeasures ||
        mode == TrainingMode.measures ||
        targetCompetency == MicroCompetencyId.unitConversion) {
      return _unitConversion(taskKey);
    }

    if (mode == TrainingMode.fractions ||
        targetCompetency == MicroCompetencyId.fractionEqualParts) {
      return _fraction(taskKey, expected);
    }

    if (mode == TrainingMode.timeDurations ||
        targetCompetency == MicroCompetencyId.timeDuration) {
      return _timeDuration();
    }

    if (mode == TrainingMode.perimeterArea) {
      return _perimeterArea(taskKey);
    }

    return GuidedMethodGuide(
      methodKey: 'general:${mode.name}',
      methodLabel: mode.title,
      nudge: 'Was weißt du schon? Teile die Aufgabe in einen kleinen ersten Schritt.',
      steps: const [
        GuidedMethodStep(
          title: 'Aufgabe lesen',
          instruction: 'Markiere, was gesucht ist und welche Angaben du wirklich brauchst.',
        ),
        GuidedMethodStep(
          title: 'Kleinen Schritt wählen',
          instruction: 'Beginne mit einem Teil, den du sicher lösen kannst.',
        ),
        GuidedMethodStep(
          title: 'Kontrollieren',
          instruction: 'Prüfe, ob dein Ergebnis zur Aufgabe und zum Zahlenraum passt.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _representationGuide(String taskKey) {
    final parts = taskKey.split(':');
    final kind = parts.length > 2 ? parts[2] : '';

    if (kind == 'place' || kind == 'decompose') {
      final number = parts.length > 3 ? int.tryParse(parts[3]) : null;
      return GuidedMethodGuide(
        methodKey: 'representation:placeValue',
        methodLabel: 'Stellenwerte lesen',
        nudge:
            'Lies jede Stelle einzeln: Einer, Zehner, Hunderter und weiter nach links.',
        steps: [
          const GuidedMethodStep(
            title: 'Stellen benennen',
            instruction:
                'Ordne jede sichtbare Ziffer zuerst ihrer Stelle zu. Eine 0 hält eine Stelle frei und darf nicht übersprungen werden.',
          ),
          GuidedMethodStep(
            title: 'Wert zusammensetzen',
            instruction: number == null
                ? 'Setze die Stellenwerte anschließend wieder zu einer Zahl oder Zerlegung zusammen.'
                : 'Die Stellenwertdarstellung gehört zu $number. Prüfe, wie jeder Ziffernwert in der Zerlegung erscheint.',
          ),
          const GuidedMethodStep(
            title: 'Darstellungen vergleichen',
            instruction:
                'Kontrolliere, ob Zahl, Stellenwerttafel und Zerlegung exakt dieselben Stellenwerte enthalten.',
          ),
        ],
      );
    }

    final groups = parts.length > 3 ? int.tryParse(parts[3]) : null;
    final each = parts.length > 4 ? int.tryParse(parts[4]) : null;
    return GuidedMethodGuide(
      methodKey: 'representation:equalGroups',
      methodLabel: 'Gleiche Gruppen lesen',
      nudge:
          'Zähle zuerst die Gruppen und danach, wie viele Punkte in jeder Gruppe liegen.',
      steps: [
        GuidedMethodStep(
          title: 'Gruppen zählen',
          instruction: groups == null
              ? 'Bestimme, wie viele gleich große Gruppen dargestellt sind.'
              : 'Es sind $groups gleich große Gruppen.',
        ),
        GuidedMethodStep(
          title: 'Inhalt jeder Gruppe',
          instruction: each == null
              ? 'Bestimme, wie viele Punkte in jeder Gruppe liegen.'
              : 'In jeder Gruppe liegen $each Punkte.',
        ),
        GuidedMethodStep(
          title: 'In Symbolsprache übersetzen',
          instruction: groups == null || each == null
              ? 'Schreibe: Anzahl der Gruppen × Anzahl je Gruppe.'
              : '$groups Gruppen mit je $each Punkten entsprechen $groups × $each.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _subtractionBridge(
    MathFact fact,
    MethodPreferences preferences,
  ) {
    final a = fact.a;
    final b = fact.b;
    final result = a - b;
    final toTen = a % 10;
    final bridge = a - toTen;
    final rest = b - toTen;

    final strategy = preferences.effectiveSubtraction(taskKey: fact.key);
    switch (strategy) {
      case SubtractionStrategy.bridgeToTen:
        final choices1 = _numberChoices(toTen, maxValue: max(10, b));
        final choices2 = _numberChoices(rest, maxValue: max(10, b));
        final choices3 = _numberChoices(result, maxValue: max(20, a));
        return GuidedMethodGuide(
          methodKey: 'subtraction:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Wo liegt der nächste volle Zehner unter $a?',
          steps: [
            GuidedMethodStep(
              title: 'Bis zum Zehner',
              instruction: 'Von $a bis $bridge fehlen $toTen.',
              question: 'Wie viel musst du zuerst wegnehmen?',
              choices: choices1,
              correctChoice: choices1.indexOf('$toTen'),
            ),
            GuidedMethodStep(
              title: 'Rest bestimmen',
              instruction: 'Von den $b wurden schon $toTen weggenommen.',
              question: 'Wie viel musst du noch wegnehmen?',
              choices: choices2,
              correctChoice: choices2.indexOf('$rest'),
            ),
            GuidedMethodStep(
              title: 'Weiterrechnen',
              instruction: '$bridge − $rest = $result.',
              question: 'Wie lautet das Ergebnis?',
              choices: choices3,
              correctChoice: choices3.indexOf('$result'),
            ),
          ],
        );

      case SubtractionStrategy.takeAway:
        final first = min(b, max(1, b ~/ 2));
        final second = b - first;
        final middle = a - first;
        final choices1 = _numberChoices(middle, maxValue: max(20, a));
        final choices2 = _numberChoices(result, maxValue: max(20, a));
        return GuidedMethodGuide(
          methodKey: 'subtraction:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Zerlege $b in zwei gut rechenbare Teile.',
          steps: [
            GuidedMethodStep(
              title: 'Ersten Teil wegnehmen',
              instruction: '$a − $first = $middle.',
              question: 'Wo landest du nach dem ersten Schritt?',
              choices: choices1,
              correctChoice: choices1.indexOf('$middle'),
            ),
            GuidedMethodStep(
              title: 'Rest wegnehmen',
              instruction: 'Jetzt fehlen noch $second.',
              question: '$middle − $second = ?',
              choices: choices2,
              correctChoice: choices2.indexOf('$result'),
            ),
          ],
        );

      case SubtractionStrategy.complement:
        final firstJump = bridge - b;
        final secondJump = a - bridge;
        final choices = _numberChoices(result, maxValue: max(20, a));
        return GuidedMethodGuide(
          methodKey: 'subtraction:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Starte bei $b und ergänze schrittweise bis $a.',
          steps: [
            GuidedMethodStep(
              title: 'Bis zum Zehner ergänzen',
              instruction: 'Von $b bis $bridge sind es $firstJump.',
            ),
            GuidedMethodStep(
              title: 'Bis zur größeren Zahl',
              instruction: 'Von $bridge bis $a sind es noch $secondJump.',
            ),
            GuidedMethodStep(
              title: 'Sprünge zusammenzählen',
              instruction: '$firstJump + $secondJump = $result.',
              question: 'Wie groß ist der Unterschied?',
              choices: choices,
              correctChoice: choices.indexOf('$result'),
            ),
          ],
        );
    }
  }

  static GuidedMethodGuide _multiplication(
    MathFact fact,
    MethodPreferences preferences,
  ) {
    final a = fact.a;
    final b = fact.b;
    final result = a * b;
    final strategy = preferences.effectiveMultiplication(taskKey: fact.key);

    switch (strategy) {
      case MultiplicationStrategy.groups:
        final choices = _numberChoices(result, maxValue: max(100, result + 10));
        return GuidedMethodGuide(
          methodKey: 'multiplication:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Stell dir $a gleich große Gruppen mit je $b Dingen vor.',
          steps: [
            GuidedMethodStep(
              title: 'Gruppen sehen',
              instruction: '$a Gruppen enthalten jeweils $b.',
            ),
            GuidedMethodStep(
              title: 'Zusammenfassen',
              instruction: '${List.filled(min(a, 6), '$b').join(' + ')}${a > 6 ? ' + …' : ''}',
            ),
            GuidedMethodStep(
              title: 'Ergebnis',
              instruction: '$a × $b = $result.',
              question: 'Wie viele sind es zusammen?',
              choices: choices,
              correctChoice: choices.indexOf('$result'),
            ),
          ],
        );

      case MultiplicationStrategy.decompose:
        final left = b ~/ 2;
        final right = b - left;
        final p1 = a * left;
        final p2 = a * right;
        final choices = _numberChoices(result, maxValue: max(100, result + 10));
        return GuidedMethodGuide(
          methodKey: 'multiplication:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Zerlege $b in $left und $right.',
          steps: [
            GuidedMethodStep(
              title: 'Erstes Teilprodukt',
              instruction: '$a × $left = $p1.',
            ),
            GuidedMethodStep(
              title: 'Zweites Teilprodukt',
              instruction: '$a × $right = $p2.',
            ),
            GuidedMethodStep(
              title: 'Zusammenfügen',
              instruction: '$p1 + $p2 = $result.',
              question: 'Wie lautet das Produkt?',
              choices: choices,
              correctChoice: choices.indexOf('$result'),
            ),
          ],
        );

      case MultiplicationStrategy.neighborFacts:
        final anchor = b <= 7 ? 5 : 10;
        final anchorProduct = a * anchor;
        final difference = b - anchor;
        final delta = a * difference.abs();
        return GuidedMethodGuide(
          methodKey: 'multiplication:${strategy.name}',
          methodLabel: strategy.label,
          nudge: 'Nimm eine leichte Nachbaraufgabe mit ×$anchor als Start.',
          steps: [
            GuidedMethodStep(
              title: 'Ankeraufgabe',
              instruction: '$a × $anchor = $anchorProduct.',
            ),
            GuidedMethodStep(
              title: 'Zur Zielaufgabe',
              instruction: difference >= 0
                  ? 'Für ×$b kommen $delta dazu.'
                  : 'Für ×$b gehen $delta weg.',
            ),
            GuidedMethodStep(
              title: 'Ergebnis',
              instruction: '$a × $b = $result.',
            ),
          ],
        );
    }
  }

  static GuidedMethodGuide _writtenSubtraction(
    int a,
    int b,
    int expected,
    MethodPreferences preferences,
  ) {
    final strategy = preferences.writtenSubtraction;
    return GuidedMethodGuide(
      methodKey: 'writtenSubtraction:${strategy.name}',
      methodLabel: strategy.label,
      nudge: 'Schreibe Einer unter Einer, Zehner unter Zehner und Hunderter unter Hunderter.',
      steps: [
        const GuidedMethodStep(
          title: 'Stellen ausrichten',
          instruction: 'Kontrolliere zuerst die Spalten E, Z, H und gegebenenfalls T.',
        ),
        GuidedMethodStep(
          title: strategy == WrittenSubtractionStrategy.regroup
              ? 'Entbündeln'
              : 'Ergänzen',
          instruction: strategy.description,
        ),
        GuidedMethodStep(
          title: 'Probe',
          instruction: 'Prüfe dein Ergebnis $expected mit der passenden Umkehraufgabe.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _wordProblem(String key) {
    final operation = key.startsWith('story:+:')
        ? 'Plus'
        : key.startsWith('story:-:')
            ? 'Minus'
            : key.startsWith('story:x:')
                ? 'Mal'
                : key.startsWith('story:divide:')
                    ? 'Geteilt'
                    : 'die passende Rechenart';
    return GuidedMethodGuide(
      methodKey: 'wordProblem:meaning',
      methodLabel: 'Text zuerst verstehen',
      nudge: 'Was verändert sich in der Geschichte: wird etwas mehr, weniger, gruppiert oder verteilt?',
      steps: [
        const GuidedMethodStep(
          title: 'Frage finden',
          instruction: 'Lies zuerst nur den letzten Satz: Was wird gesucht?',
        ),
        GuidedMethodStep(
          title: 'Handlung erkennen',
          instruction: 'Hier passt $operation.',
        ),
        const GuidedMethodStep(
          title: 'Angaben prüfen',
          instruction: 'Nimm nur die Zahlen, die für die Frage wirklich gebraucht werden.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _unitConversion(String key) =>
      const GuidedMethodGuide(
        methodKey: 'measure:unitLadder',
        methodLabel: 'Einheitenleiter',
        nudge: 'Welche Einheit hast du – und zu welcher Einheit willst du?',
        steps: [
          GuidedMethodStep(
            title: 'Start markieren',
            instruction: 'Markiere die Ausgangseinheit.',
          ),
          GuidedMethodStep(
            title: 'Ziel markieren',
            instruction: 'Markiere die gesuchte Einheit.',
          ),
          GuidedMethodStep(
            title: 'Schrittweise umwandeln',
            instruction: 'Nutze die bekannte Beziehung zwischen benachbarten Einheiten.',
          ),
        ],
      );

  static GuidedMethodGuide _fraction(String key, int expected) =>
      GuidedMethodGuide(
        methodKey: 'fraction:equalParts',
        methodLabel: 'Gleich große Teile',
        nudge: 'Wie viele gleich große Teile hat das Ganze?',
        steps: [
          const GuidedMethodStep(
            title: 'Ganzes erkennen',
            instruction: 'Bestimme zuerst die gesamte Menge.',
          ),
          const GuidedMethodStep(
            title: 'Gleichmäßig teilen',
            instruction: 'Teile das Ganze in gleich große Teile.',
          ),
          GuidedMethodStep(
            title: 'Gesuchten Anteil nehmen',
            instruction: 'Ein gesuchter Teil hat hier den Wert $expected.',
          ),
        ],
      );

  static GuidedMethodGuide _timeDuration() => const GuidedMethodGuide(
        methodKey: 'time:timeline',
        methodLabel: 'Zeitlinie',
        nudge: 'Gehe vom Start zuerst zur nächsten gut erreichbaren Uhrzeit.',
        steps: [
          GuidedMethodStep(
            title: 'Start markieren',
            instruction: 'Markiere die Startzeit.',
          ),
          GuidedMethodStep(
            title: 'In Etappen gehen',
            instruction: 'Gehe zuerst zu einer vollen oder halben Stunde.',
          ),
          GuidedMethodStep(
            title: 'Etappen addieren',
            instruction: 'Zähle die Minuten aller Etappen zusammen.',
          ),
        ],
      );

  static GuidedMethodGuide _perimeterArea(String key) {
    final area = key.contains('area');
    return GuidedMethodGuide(
      methodKey: area ? 'geometry:area' : 'geometry:perimeter',
      methodLabel: area ? 'Fläche = Inneres' : 'Umfang = Rand',
      nudge: area
          ? 'Gesucht ist das Innere der Figur.'
          : 'Gesucht ist die Länge des Randes.',
      steps: [
        GuidedMethodStep(
          title: area ? 'Innenfläche markieren' : 'Rand nachfahren',
          instruction: area
              ? 'Markiere die Fläche innerhalb des Rechtecks.'
              : 'Fahre alle vier Seiten einmal entlang.',
        ),
        GuidedMethodStep(
          title: 'Passende Rechnung',
          instruction: area
              ? 'Länge × Breite.'
              : 'Alle Seiten addieren oder 2 × (Länge + Breite).',
        ),
      ],
    );
  }

  static GuidedMethodGuide _strategyChoiceGuide(String key) {
    final numbers = _numbers(key);
    final anchor = numbers.isEmpty ? null : numbers.last;
    return GuidedMethodGuide(
      methodKey: 'process:strategyChoice',
      methodLabel: 'Günstigen Rechenweg wählen',
      nudge: anchor == null
          ? 'Suche eine runde Zwischenzahl, die das Rechnen einfacher macht.'
          : 'Welche Zerlegung bringt dich zuerst genau zu $anchor?',
      steps: [
        const GuidedMethodStep(
          title: 'Zielzahl erkennen',
          instruction:
              'Suche einen glatten Zehner, Hunderter oder Tausender in der Nähe.',
        ),
        const GuidedMethodStep(
          title: 'Passend zerlegen',
          instruction:
              'Zerlege nur so viel vom zweiten Summanden, wie bis zur Zielzahl fehlt.',
        ),
        const GuidedMethodStep(
          title: 'Rest weiterrechnen',
          instruction:
              'Rechne danach nur noch den verbleibenden Rest weiter.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _errorCheckingGuide(String key) {
    final numbers = _numbers(key);
    final shown = numbers.length >= 3 ? numbers.last : null;
    return GuidedMethodGuide(
      methodKey: 'process:errorChecking',
      methodLabel: 'Rechenfehler finden',
      nudge: shown == null
          ? 'Prüfe zuerst die Stellen, statt die ganze Aufgabe sofort neu zu rechnen.'
          : 'Prüfe, ob $shown zu Einer- und Zehnerstelle der Aufgabe passen kann.',
      steps: const [
        GuidedMethodStep(
          title: 'Einer prüfen',
          instruction:
              'Vergleiche zuerst nur die Einerstelle mit der vorgegebenen Rechnung.',
        ),
        GuidedMethodStep(
          title: 'Zehner prüfen',
          instruction:
              'Prüfe danach Zehner und mögliche Überträge oder Entbündelungen.',
        ),
        GuidedMethodStep(
          title: 'Fehler beschreiben',
          instruction:
              'Benenne möglichst genau, ob das Ergebnis zu groß, zu klein oder korrekt ist.',
        ),
      ],
    );
  }

  static GuidedMethodGuide _plausibilityGuide(String key) {
    final numbers = _numbers(key);
    final candidate = numbers.length >= 3 ? numbers[numbers.length - 2] : null;
    return GuidedMethodGuide(
      methodKey: 'process:plausibility',
      methodLabel: 'Mit Überschlag kontrollieren',
      nudge: candidate == null
          ? 'Runde die Ausgangszahlen grob und vergleiche die Größenordnung.'
          : 'Passt $candidate ungefähr zu den gerundeten Ausgangszahlen?',
      steps: const [
        GuidedMethodStep(
          title: 'Ausgangszahlen runden',
          instruction:
              'Runde beide Zahlen auf eine sinnvolle Stelle, ohne exakt auszurechnen.',
        ),
        GuidedMethodStep(
          title: 'Überschlag bilden',
          instruction:
              'Rechne mit den gerundeten Zahlen eine grobe Erwartung.',
        ),
        GuidedMethodStep(
          title: 'Vergleichen',
          instruction:
              'Liegt das vorgeschlagene Ergebnis in derselben Größenordnung?',
        ),
      ],
    );
  }

  static bool _needsSubtractionBridge(MathFact fact) =>
      (fact.a % 10) < (fact.b % 10);

  static List<int> _numbers(String value) => RegExp(r'\d+')
      .allMatches(value)
      .map((match) => int.parse(match.group(0)!))
      .toList();

  static List<String> _numberChoices(
    int correct, {
    required int maxValue,
  }) {
    final values = <int>{correct};
    for (final offset in [1, -1, 2, -2, 10, -10]) {
      final candidate = correct + offset;
      if (candidate >= 0 && candidate <= maxValue) values.add(candidate);
      if (values.length >= 4) break;
    }
    var next = 0;
    while (values.length < 4) {
      if (next <= maxValue) values.add(next);
      next += 1;
    }
    final list = values.take(4).toList()..sort();
    return list.map((value) => '$value').toList();
  }
}
