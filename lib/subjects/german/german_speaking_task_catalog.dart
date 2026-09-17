import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_task.dart';

class GermanSpeakingTaskCatalog {
  const GermanSpeakingTaskCatalog._();

  static const tasks = <GermanTask>[
    GermanTask(
      id: 'g1-talk-wait-turn',
      competencyId: GermanCompetencyId.conversationRules,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Was passt zu einem guten Gespräch?',
      prompt: 'Hör dir die Situation an und wähle.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>['Ich warte, bis Mia fertig ist.'],
      choices: <String>[
        'Ich warte, bis Mia fertig ist.',
        'Ich rede sofort dazwischen.',
        'Ich gehe einfach weg.',
      ],
      spokenText:
          'Mia erzählt gerade von ihrem Wochenende. Du möchtest auch etwas sagen.',
    ),
    GermanTask(
      id: 'g1-talk-listen',
      competencyId: GermanCompetencyId.conversationRules,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Wie zeigst du, dass du zuhörst?',
      prompt: 'Hör genau hin und wähle.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>['Ich schaue Ben an und höre zu.'],
      choices: <String>[
        'Ich schaue Ben an und höre zu.',
        'Ich spiele nebenbei weiter.',
        'Ich rufe etwas durch den Raum.',
      ],
      spokenText: 'Ben erklärt dir, wie sein Spiel funktioniert.',
    ),
    GermanTask(
      id: 'g1-talk-clarify',
      competencyId: GermanCompetencyId.conversationRules,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Was kannst du sagen, wenn du etwas nicht verstanden hast?',
      prompt: 'Hör die Situation und wähle eine passende Reaktion.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>['Kannst du das bitte noch einmal sagen?'],
      choices: <String>[
        'Kannst du das bitte noch einmal sagen?',
        'Das ist mir egal.',
        'Ich sage einfach irgendetwas.',
      ],
      spokenText:
          'Eine Mitschülerin erklärt etwas, aber du hast den letzten Satz nicht verstanden.',
    ),
    GermanTask(
      id: 'g2-retell-trip',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Welche Nacherzählung hat die richtige Reihenfolge?',
      prompt: 'Hör die kurze Geschichte an und wähle.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Zuerst packt Leni, dann fährt sie los, zuletzt kommt sie an.',
      ],
      choices: <String>[
        'Zuerst packt Leni, dann fährt sie los, zuletzt kommt sie an.',
        'Zuerst kommt Leni an, dann packt sie, zuletzt fährt sie los.',
        'Zuerst fährt Leni los, dann kommt sie an, zuletzt packt sie.',
      ],
      spokenText:
          'Leni packt ihren Rucksack. Danach fährt sie mit dem Bus. Am Ende kommt sie bei ihrer Oma an.',
    ),
    GermanTask(
      id: 'g2-retell-important',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Welche Nacherzählung enthält das Wichtigste?',
      prompt: 'Hör zu und wähle die verständliche Kurzfassung.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Noah verliert den Schlüssel und findet ihn später unter der Bank.',
      ],
      choices: <String>[
        'Noah verliert den Schlüssel und findet ihn später unter der Bank.',
        'Noah trägt eine blaue Jacke und die Bank ist aus Holz.',
        'Noah sieht eine Bank und geht danach nach Hause.',
      ],
      spokenText:
          'Noah merkt auf dem Schulhof, dass sein Schlüssel weg ist. Er sucht überall. Schließlich entdeckt er ihn unter einer Bank.',
    ),
    GermanTask(
      id: 'g2-retell-ending',
      competencyId: GermanCompetencyId.oralRetelling,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Welcher Satz passt als Schluss der Nacherzählung?',
      prompt: 'Hör die Geschichte und wähle den passenden Schluss.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Am Ende bringt Sami den Igel vorsichtig ins Gebüsch.',
      ],
      choices: <String>[
        'Am Ende bringt Sami den Igel vorsichtig ins Gebüsch.',
        'Am Anfang kauft Sami ein Fahrrad.',
        'Danach beginnt plötzlich der Winter.',
      ],
      spokenText:
          'Sami entdeckt einen Igel auf dem Weg. Er wartet, bis keine Fahrräder mehr kommen. Dann trägt er den Igel vorsichtig ins Gebüsch.',
    ),
    GermanTask(
      id: 'g3-present-opening',
      competencyId: GermanCompetencyId.presentationStructure,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Welcher Einstieg macht das Thema sofort klar?',
      prompt: 'Hör den Auftrag und wähle einen guten Anfang.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Ich erkläre euch heute, wie Bienen Honig machen.',
      ],
      choices: <String>[
        'Ich erkläre euch heute, wie Bienen Honig machen.',
        'Also, ähm, ich weiß nicht genau.',
        'Das Ende erzähle ich zuerst.',
      ],
      spokenText:
          'Du sollst deiner Klasse einen kurzen Vortrag darüber halten, wie Bienen Honig machen.',
    ),
    GermanTask(
      id: 'g3-present-order',
      competencyId: GermanCompetencyId.presentationStructure,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Welche Reihenfolge passt zu einem kurzen Vortrag?',
      prompt: 'Hör den Vortragauftrag und wähle die klare Gliederung.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Thema nennen – wichtige Punkte erklären – kurz abschließen',
      ],
      choices: <String>[
        'Thema nennen – wichtige Punkte erklären – kurz abschließen',
        'Abschluss – Nebensache – Thema nennen',
        'Alles gleichzeitig erzählen – plötzlich aufhören',
      ],
      spokenText:
          'Du möchtest deinen Mitschülern in zwei Minuten dein Lieblingstier vorstellen.',
    ),
    GermanTask(
      id: 'g3-present-clear',
      competencyId: GermanCompetencyId.presentationStructure,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Was hilft den Zuhörenden am meisten?',
      prompt: 'Hör die Situation und wähle.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Ich spreche deutlich und erkläre einen Punkt nach dem anderen.',
      ],
      choices: <String>[
        'Ich spreche deutlich und erkläre einen Punkt nach dem anderen.',
        'Ich spreche möglichst schnell ohne Pause.',
        'Ich lasse die wichtigsten Informationen weg.',
      ],
      spokenText:
          'Du erklärst der Klasse die Regeln eines neuen Spiels. Alle sollen danach wissen, wie es funktioniert.',
    ),
    GermanTask(
      id: 'g4-discuss-reason',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Welche Antwort enthält eine begründete Meinung?',
      prompt: 'Hör die Frage und wähle den passenden Gesprächsbeitrag.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Ich finde längere Pausen gut, weil wir uns danach besser konzentrieren können.',
      ],
      choices: <String>[
        'Ich finde längere Pausen gut, weil wir uns danach besser konzentrieren können.',
        'Längere Pausen sind halt besser.',
        'Das ist so, weil ich das sage.',
      ],
      spokenText:
          'In der Klasse wird darüber gesprochen, ob die Hofpause etwas länger sein sollte.',
    ),
    GermanTask(
      id: 'g4-discuss-disagree',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Wie kannst du höflich widersprechen?',
      prompt: 'Hör die Aussage und wähle eine passende Reaktion.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Ich sehe das anders, weil nicht alle Kinder denselben Weg zur Schule haben.',
      ],
      choices: <String>[
        'Ich sehe das anders, weil nicht alle Kinder denselben Weg zur Schule haben.',
        'Das ist Unsinn, du liegst falsch.',
        'Ich höre gar nicht erst zu.',
      ],
      spokenText: 'Ein Kind sagt: Alle sollten immer zu Fuß zur Schule kommen.',
    ),
    GermanTask(
      id: 'g4-discuss-connect',
      competencyId: GermanCompetencyId.discussionReasoning,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Welche Antwort greift den vorherigen Beitrag auf?',
      prompt: 'Hör den Beitrag und wähle eine gute Fortsetzung.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>[
        'Du sagst, dass Bücher Ruhe brauchen. Ich ergänze: Eine Leseecke könnte dabei helfen.',
      ],
      choices: <String>[
        'Du sagst, dass Bücher Ruhe brauchen. Ich ergänze: Eine Leseecke könnte dabei helfen.',
        'Ich rede jetzt über etwas ganz anderes.',
        'Deinen Beitrag habe ich nicht beachtet.',
      ],
      spokenText:
          'Eine Mitschülerin schlägt vor, in der Klasse einen ruhigeren Platz zum Lesen einzurichten.',
    ),
  ];
}
