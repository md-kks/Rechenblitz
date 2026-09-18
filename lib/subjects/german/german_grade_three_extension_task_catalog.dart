import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_task.dart';

class GermanGradeThreeExtensionTaskCatalog {
  const GermanGradeThreeExtensionTaskCatalog._();

  static const tasks = <GermanTask>[
    GermanTask(
      id: 'g3-word-family-write',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Welche Wörter gehören zur selben Wortfamilie?',
      prompt: 'Achte auf den gemeinsamen Wortstamm „schreib-“.',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['schreiben · Schreiber · Schreibheft'],
      choices: <String>[
        'schreiben · Schreiber · Schreibheft',
        'schreiben · schreien · Schreiber',
        'Schreiber · Scheibe · Schreibheft',
      ],
    ),
    GermanTask(
      id: 'g3-word-family-play',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Welche drei Wörter sind miteinander verwandt?',
      prompt: 'Finde die Wortfamilie.',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['spielen · Spieler · Spielplatz'],
      choices: <String>[
        'spielen · Spieler · Spielplatz',
        'spielen · Spiegel · Spieler',
        'Spieler · spülen · Spielplatz',
      ],
    ),
    GermanTask(
      id: 'g3-retell-missed-bus',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Welche Nacherzählung enthält Ursache und Lösung?',
      prompt: 'Hör die Geschichte an und wähle die passende Kurzfassung.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Mila verpasst den Bus. Sie geht zur nächsten Haltestelle und fährt von dort weiter.',
      ],
      choices: <String>[
        'Mila verpasst den Bus. Sie geht zur nächsten Haltestelle und fährt von dort weiter.',
        'Mila wartet den ganzen Tag an derselben Haltestelle.',
        'Mila fährt zuerst mit dem Bus und verpasst danach die Haltestelle.',
      ],
      spokenText:
          'Mila läuft morgens zur Haltestelle, doch der Bus fährt gerade ab. Sie wartet nicht lange, sondern geht zur nächsten Haltestelle. Dort erreicht sie wenig später einen anderen Bus und kommt noch rechtzeitig an.',
    ),
    GermanTask(
      id: 'g3-retell-project-sequence',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Welche Nacherzählung gibt den Ablauf richtig wieder?',
      prompt: 'Hör genau zu und achte auf die Reihenfolge.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Zuerst sammelt die Gruppe Ideen, dann baut sie das Modell, danach testet sie es und verbessert es am Schluss.',
      ],
      choices: <String>[
        'Zuerst sammelt die Gruppe Ideen, dann baut sie das Modell, danach testet sie es und verbessert es am Schluss.',
        'Zuerst verbessert die Gruppe das Modell, dann sammelt sie Ideen und baut es zuletzt.',
        'Die Gruppe testet zuerst ein fertiges Modell und beginnt danach mit dem Plan.',
      ],
      spokenText:
          'Für das Klassenprojekt sammelt die Gruppe zuerst Ideen. Danach baut sie aus Karton ein Modell. Beim Test merkt sie, dass ein Teil nicht hält. Zum Schluss verstärkt die Gruppe diese Stelle.',
    ),
    GermanTask(
      id: 'g3-order-room-separable',
      competencyId: GermanCompetencyId.sentenceWordOrder,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Baue den Satz so, dass er mit „Morgen“ beginnt.',
      prompt: 'Morgen · räumt · Ben · sein Zimmer · auf',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>['Morgen räumt Ben sein Zimmer auf'],
      choices: <String>['Morgen', 'räumt', 'Ben', 'sein Zimmer', 'auf'],
    ),
    GermanTask(
      id: 'g3-order-reading-separable',
      competencyId: GermanCompetencyId.sentenceWordOrder,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Baue den Satz so, dass er mit „Nach dem Essen“ beginnt.',
      prompt:
          'Nach dem Essen · liest · Lea · ihrem Bruder · eine Geschichte · vor',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>[
        'Nach dem Essen liest Lea ihrem Bruder eine Geschichte vor',
      ],
      choices: <String>[
        'Nach dem Essen',
        'liest',
        'Lea',
        'ihrem Bruder',
        'eine Geschichte',
        'vor',
      ],
    ),
  ];
}
