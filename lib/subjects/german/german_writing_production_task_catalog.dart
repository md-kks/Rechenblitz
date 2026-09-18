import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_task.dart';

class GermanWritingProductionTaskCatalog {
  const GermanWritingProductionTaskCatalog._();

  static const tasks = <GermanTask>[
    GermanTask(
      id: 'g3-write-afternoon-tower',
      competencyId: GermanCompetencyId.sentenceWriting,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Schreibe aus den Satzbausteinen einen vollständigen Satz.',
      prompt: 'am Nachmittag · baut Leo · einen hohen Turm',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>['Am Nachmittag baut Leo einen hohen Turm.'],
    ),
    GermanTask(
      id: 'g3-write-science-feather',
      competencyId: GermanCompetencyId.sentenceWriting,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Schreibe aus den Satzbausteinen einen vollständigen Satz.',
      prompt: 'im Sachunterricht · untersucht die Klasse · eine Feder',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Im Sachunterricht untersucht die Klasse eine Feder.',
      ],
    ),
    GermanTask(
      id: 'g3-write-favorite-book',
      competencyId: GermanCompetencyId.sentenceWriting,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Schreibe aus den Satzbausteinen einen vollständigen Satz.',
      prompt: 'morgen · bringt Sara · ihr Lieblingsbuch · mit',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>['Morgen bringt Sara ihr Lieblingsbuch mit.'],
    ),
    GermanTask(
      id: 'g3-write-after-rain',
      competencyId: GermanCompetencyId.sentenceWriting,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Schreibe aus den Satzbausteinen einen vollständigen Satz.',
      prompt: 'nach dem Regen · glänzen · die Straßen',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>['Nach dem Regen glänzen die Straßen.'],
    ),
    GermanTask(
      id: 'g4-connect-rain-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Verbinde die Aussagen mit „deshalb“ zu zwei passenden Sätzen.',
      prompt: 'Es regnet stark. · Mia nimmt einen Schirm mit.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Es regnet stark. Deshalb nimmt Mia einen Schirm mit.',
      ],
    ),
    GermanTask(
      id: 'g4-connect-sick-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Verbinde die Aussagen mit „weil“ zu einem Satz.',
      prompt: 'Ben bleibt heute zu Hause. · Ben ist krank.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Ben bleibt heute zu Hause, weil er krank ist.',
      ],
    ),
    GermanTask(
      id: 'g4-connect-contrast-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Verbinde die Aussagen mit „aber“ zu einem Satz.',
      prompt: 'Es regnet stark. · Die Kinder spielen draußen weiter.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Es regnet stark, aber die Kinder spielen draußen weiter.',
      ],
    ),
    GermanTask(
      id: 'g4-revision-pronoun-write',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Überarbeite den zweiten Satz. Ersetze die Wiederholung durch „er“.',
      prompt: 'Der Hund läuft zum Tor. Der Hund wartet dort.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>['Der Hund läuft zum Tor. Er wartet dort.'],
    ),
    GermanTask(
      id: 'g4-revision-precise-write',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Überarbeite den Satz. Ersetze „bewegte sich sehr schnell“ durch „rannte“.',
      prompt: 'Der Fuchs bewegte sich sehr schnell über die Wiese.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>['Der Fuchs rannte über die Wiese.'],
    ),
    GermanTask(
      id: 'g4-revision-sequence-write',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Überarbeite den Ablauf mit „Zuerst“, „Dann“ und „Danach“.',
      prompt: 'Ich zog die Schuhe an. Ich band die Schnürsenkel. Ich ging los.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Zuerst zog ich die Schuhe an. Dann band ich die Schnürsenkel. Danach ging ich los.',
      ],
    ),
  ];
}
