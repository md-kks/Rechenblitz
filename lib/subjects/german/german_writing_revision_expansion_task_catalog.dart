import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_task.dart';

class GermanWritingRevisionExpansionTaskCatalog {
  const GermanWritingRevisionExpansionTaskCatalog._();

  static const tasks = <GermanTask>[
    GermanTask(
      id: 'g4-connect-frost-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Verbinde die Aussagen mit „weil“ zu einem Satz.',
      prompt: 'Die Wege sind glatt. · Es hat nachts gefroren.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Die Wege sind glatt, weil es nachts gefroren hat.',
        'Weil es nachts gefroren hat, sind die Wege glatt.',
      ],
    ),
    GermanTask(
      id: 'g4-connect-tired-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Verbinde die Aussagen mit „obwohl“ zu einem Satz.',
      prompt: 'Mia ist müde. · Mia liest noch ein Kapitel.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Obwohl Mia müde ist, liest sie noch ein Kapitel.',
        'Mia liest noch ein Kapitel, obwohl sie müde ist.',
      ],
    ),
    GermanTask(
      id: 'g4-connect-battery-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Verbinde die Aussagen mit „deshalb“ zu zwei passenden Sätzen.',
      prompt: 'Der Akku ist leer. · Das Tablet geht aus.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Der Akku ist leer. Deshalb geht das Tablet aus.',
        'Der Akku ist leer. Das Tablet geht deshalb aus.',
      ],
    ),
    GermanTask(
      id: 'g4-connect-jacket-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Verbinde die Aussagen mit „bevor“ zu einem Satz.',
      prompt: 'Ben zieht die Jacke an. · Ben geht nach draußen.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Bevor Ben nach draußen geht, zieht er die Jacke an.',
        'Ben zieht die Jacke an, bevor er nach draußen geht.',
      ],
    ),
    GermanTask(
      id: 'g4-connect-rain-stop-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Verbinde die Aussagen mit „danach“ zu zwei passenden Sätzen.',
      prompt: 'Der Regen hört auf. · Die Klasse geht auf den Hof.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Der Regen hört auf. Danach geht die Klasse auf den Hof.',
        'Der Regen hört auf. Die Klasse geht danach auf den Hof.',
      ],
    ),
    GermanTask(
      id: 'g4-connect-long-way-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Verbinde die Aussagen mit „aber“ zu einem Satz.',
      prompt: 'Der Weg ist lang. · Die Gruppe geht weiter.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Der Weg ist lang, aber die Gruppe geht weiter.',
        'Die Gruppe geht weiter, aber der Weg ist lang.',
      ],
    ),
    GermanTask(
      id: 'g4-connect-water-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Verbinde die Aussagen mit „denn“ zu einem Satz.',
      prompt: 'Lea gießt die Pflanzen. · Die Erde ist trocken.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Lea gießt die Pflanzen, denn die Erde ist trocken.',
      ],
    ),
    GermanTask(
      id: 'g4-connect-sun-cold-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Verbinde die Aussagen mit „obwohl“ zu einem Satz.',
      prompt: 'Die Sonne scheint. · Es ist kalt.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Obwohl die Sonne scheint, ist es kalt.',
        'Es ist kalt, obwohl die Sonne scheint.',
      ],
    ),
    GermanTask(
      id: 'g4-connect-bus-write',
      competencyId: GermanCompetencyId.sentenceConnections,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Verbinde die Aussagen mit „deshalb“ zu zwei passenden Sätzen.',
      prompt: 'Der Bus fällt aus. · Wir gehen zu Fuß.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Der Bus fällt aus. Deshalb gehen wir zu Fuß.',
        'Der Bus fällt aus. Wir gehen deshalb zu Fuß.',
      ],
    ),
    GermanTask(
      id: 'g4-revision-jacket-pronouns',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Überarbeite die Wiederholungen mit „ihre“ und „sie“.',
      prompt: 'Mia nimmt Mias Jacke. Mia zieht Mias Jacke an.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>['Mia nimmt ihre Jacke. Sie zieht sie an.'],
    ),
    GermanTask(
      id: 'g4-revision-dog-ran',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Ersetze „ging sehr schnell“ durch das genaue Verb „rannte“.',
      prompt: 'Der Hund ging sehr schnell zum Tor.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Der Hund rannte zum Tor.',
        'Zum Tor rannte der Hund.',
      ],
    ),
    GermanTask(
      id: 'g4-revision-whispered',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Ersetze „sagte sehr leise“ durch „flüsterte“.',
      prompt: 'Nora sagte sehr leise die Antwort.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>['Nora flüsterte die Antwort.'],
    ),
    GermanTask(
      id: 'g4-revision-bird-pronoun',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Ersetze die Wiederholungen nach dem ersten Satz durch „er“.',
      prompt:
          'Der Vogel sitzt auf dem Ast. Der Vogel singt. Der Vogel fliegt weg.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Der Vogel sitzt auf dem Ast. Er singt. Er fliegt weg.',
      ],
    ),
    GermanTask(
      id: 'g4-revision-bag-sequence',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Überarbeite mit „Zuerst“, „Dann“ und „Zum Schluss“.',
      prompt:
          'Ich öffnete den Ranzen. Ich legte das Heft hinein. Ich schloss ihn.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Zuerst öffnete ich den Ranzen. Dann legte ich das Heft hinein. Zum Schluss schloss ich ihn.',
      ],
    ),
    GermanTask(
      id: 'g4-revision-huge-tent',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Ersetze „sehr großes“ durch das genauere Wort „riesiges“.',
      prompt: 'Auf dem Platz steht ein sehr großes Zelt.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Auf dem Platz steht ein riesiges Zelt.',
        'Ein riesiges Zelt steht auf dem Platz.',
      ],
    ),
    GermanTask(
      id: 'g4-revision-exhausted',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Ersetze „sehr müde“ durch „erschöpft“.',
      prompt: 'Nach der Wanderung war Ben sehr müde.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Nach der Wanderung war Ben erschöpft.',
        'Ben war nach der Wanderung erschöpft.',
      ],
    ),
    GermanTask(
      id: 'g4-revision-apple-sequence',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Überarbeite mit „Zuerst“, „Danach“ und „Zum Schluss“ und vermeide Wiederholungen.',
      prompt:
          'Dann wusch Lea den Apfel. Dann schnitt Lea den Apfel. Dann aß Lea den Apfel.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Zuerst wusch Lea den Apfel. Danach schnitt sie ihn. Zum Schluss aß sie ihn.',
      ],
    ),
    GermanTask(
      id: 'g4-revision-wind-combine',
      competencyId: GermanCompetencyId.textRevision,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Verbinde die ersten beiden Aussagen mit „und“. Lass den dritten Satz stehen.',
      prompt:
          'Der Wind wird stärker. Die Wolken werden dunkel. Es beginnt zu regnen.',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>[
        'Der Wind wird stärker und die Wolken werden dunkel. Es beginnt zu regnen.',
      ],
    ),
  ];
}
