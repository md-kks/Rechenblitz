import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_task.dart';

class GermanReadingEvidenceTaskCatalog {
  const GermanReadingEvidenceTaskCatalog._();

  static const tasks = <GermanTask>[
    GermanTask(
      id: 'g1-evidence-dog-basket',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Wer schläft und wo?',
      prompt: 'Der Hund schläft im Korb.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Der Hund', 'im Korb'],
      choices: <String>['Der Hund', 'schläft', 'im Korb'],
    ),
    GermanTask(
      id: 'g1-evidence-lina-park',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Wer fährt und wohin?',
      prompt: 'Lina fährt mit dem Rad zum Park.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Lina', 'zum Park'],
      choices: <String>['Lina', 'fährt', 'mit dem Rad', 'zum Park'],
    ),
    GermanTask(
      id: 'g1-evidence-tom-cocoa',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Wer trinkt und was?',
      prompt: 'Tom trinkt morgens einen Kakao.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Tom', 'einen Kakao'],
      choices: <String>['Tom', 'trinkt', 'morgens', 'einen Kakao'],
    ),
    GermanTask(
      id: 'g1-evidence-ball-table',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Was liegt und wo?',
      prompt: 'Der Ball liegt unter dem Tisch.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Der Ball', 'unter dem Tisch'],
      choices: <String>['Der Ball', 'liegt', 'unter dem Tisch'],
    ),
    GermanTask(
      id: 'g1-evidence-grandma-cake',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Wer backt und was?',
      prompt: 'Oma backt einen Kuchen für Mia.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Oma', 'einen Kuchen'],
      choices: <String>['Oma', 'backt', 'einen Kuchen', 'für Mia'],
    ),
    GermanTask(
      id: 'g1-evidence-cat-sofa',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Wer sitzt und wo?',
      prompt: 'Die Katze sitzt ruhig auf dem Sofa.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Die Katze', 'auf dem Sofa'],
      choices: <String>['Die Katze', 'sitzt', 'ruhig', 'auf dem Sofa'],
    ),
    GermanTask(
      id: 'g2-evidence-school-time',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction:
          'Markiere die zwei Textstellen, die zeigen, wann Lina losgeht und wann die Schule beginnt.',
      prompt: 'Lina geht um sieben Uhr los. Die Schule beginnt um acht Uhr.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['um sieben Uhr', 'um acht Uhr'],
      choices: <String>['Lina', 'um sieben Uhr', 'die Schule', 'um acht Uhr'],
    ),
    GermanTask(
      id: 'g2-evidence-zoo-order',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction:
          'Markiere die beiden Textstellen, die die Reihenfolge der Tiere zeigen.',
      prompt:
          'Nia besucht den Zoo. Zuerst sieht sie die Giraffen. Danach geht sie zu den Pinguinen.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Zuerst sieht sie die Giraffen.',
        'Danach geht sie zu den Pinguinen.',
      ],
      choices: <String>[
        'Nia besucht den Zoo.',
        'Zuerst sieht sie die Giraffen.',
        'Danach geht sie zu den Pinguinen.',
      ],
    ),
    GermanTask(
      id: 'g2-evidence-bus-school',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction:
          'Markiere die zwei Textstellen, die zeigen, wann Amir losgeht und wie er fährt.',
      prompt:
          'Amir verlässt um halb acht das Haus. Zur Schule fährt er mit dem Bus.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['um halb acht', 'mit dem Bus'],
      choices: <String>['Amir', 'um halb acht', 'zur Schule', 'mit dem Bus'],
    ),
    GermanTask(
      id: 'g2-evidence-cake-family',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction:
          'Markiere die Textstellen: Wer backt und was passiert danach?',
      prompt:
          'Mia deckt den Tisch. Ihr Vater backt einen Kuchen. Danach essen beide zusammen.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Ihr Vater backt einen Kuchen.',
        'Danach essen beide zusammen.',
      ],
      choices: <String>[
        'Mia deckt den Tisch.',
        'Ihr Vater backt einen Kuchen.',
        'Danach essen beide zusammen.',
      ],
    ),
    GermanTask(
      id: 'g2-evidence-swimming-day',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction:
          'Markiere die zwei Textstellen, die Montag und Dienstag unterscheiden.',
      prompt: 'Am Montag malt Mila. Am Dienstag geht sie schwimmen.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Am Montag malt Mila.',
        'Am Dienstag geht sie schwimmen.',
      ],
      choices: <String>[
        'Am Montag malt Mila.',
        'Am Dienstag geht sie schwimmen.',
        'Mila hat frei.',
      ],
    ),
    GermanTask(
      id: 'g2-evidence-library-book',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction:
          'Markiere die Textstellen: Wohin geht Ben und was leiht er aus?',
      prompt: 'Ben geht in die Bücherei. Er leiht ein Buch über Tiere aus.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['in die Bücherei', 'ein Buch über Tiere'],
      choices: <String>[
        'Ben',
        'in die Bücherei',
        'ein Buch über Tiere',
        'am Nachmittag',
      ],
    ),
    GermanTask(
      id: 'g3-evidence-inference-rain',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.third,
      instruction:
          'Markiere alle Hinweise, aus denen du schließen kannst, dass es regnet oder gerade geregnet hat.',
      prompt:
          'Der Gehweg glänzt. Lina spannt ihren Schirm auf. Sie springt über eine Pfütze. Ihr Rucksack ist blau.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Der Gehweg glänzt.',
        'Lina spannt ihren Schirm auf.',
        'Sie springt über eine Pfütze.',
      ],
      choices: <String>[
        'Der Gehweg glänzt.',
        'Lina spannt ihren Schirm auf.',
        'Sie springt über eine Pfütze.',
        'Ihr Rucksack ist blau.',
      ],
    ),
    GermanTask(
      id: 'g3-evidence-inference-birthday',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.third,
      instruction:
          'Markiere die Hinweise, die dafür sprechen, dass Jonas Geburtstag hat.',
      prompt:
          'Jonas pustet acht Kerzen aus. Auf dem Tisch liegen Buntstifte. Danach wird Kuchen verteilt. Das Fenster steht offen.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Jonas pustet acht Kerzen aus.',
        'Danach wird Kuchen verteilt.',
      ],
      choices: <String>[
        'Jonas pustet acht Kerzen aus.',
        'Auf dem Tisch liegen Buntstifte.',
        'Danach wird Kuchen verteilt.',
        'Das Fenster steht offen.',
      ],
    ),
    GermanTask(
      id: 'g3-evidence-inference-cold',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.third,
      instruction:
          'Markiere die Hinweise, aus denen du schließen kannst, dass es draußen kalt ist.',
      prompt:
          'Lea zieht Mütze und Schal an. Sie nimmt dicke Handschuhe mit. Ihr Rucksack ist blau.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Lea zieht Mütze und Schal an.',
        'Sie nimmt dicke Handschuhe mit.',
      ],
      choices: <String>[
        'Lea zieht Mütze und Schal an.',
        'Sie nimmt dicke Handschuhe mit.',
        'Ihr Rucksack ist blau.',
      ],
    ),
    GermanTask(
      id: 'g3-evidence-inference-sleep',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.third,
      instruction: 'Markiere alle Hinweise, die zeigen, dass Paul schläft.',
      prompt:
          'Im Zimmer ist es dunkel. Paul liegt im Bett. Er schnarcht leise. Auf dem Stuhl liegt ein Buch.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Im Zimmer ist es dunkel.',
        'Paul liegt im Bett.',
        'Er schnarcht leise.',
      ],
      choices: <String>[
        'Im Zimmer ist es dunkel.',
        'Paul liegt im Bett.',
        'Er schnarcht leise.',
        'Auf dem Stuhl liegt ein Buch.',
      ],
    ),
    GermanTask(
      id: 'g4-evidence-inference-wet-dog',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere alle Hinweise, die dafür sprechen, dass der Hund gerade draußen im Regen war.',
      prompt:
          'Das Fenster steht offen. Auf dem Boden sind nasse Pfotenabdrücke. Der Hund schüttelt Wasser aus seinem Fell. Seine Futterschüssel ist leer.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Das Fenster steht offen.',
        'Auf dem Boden sind nasse Pfotenabdrücke.',
        'Der Hund schüttelt Wasser aus seinem Fell.',
      ],
      choices: <String>[
        'Das Fenster steht offen.',
        'Auf dem Boden sind nasse Pfotenabdrücke.',
        'Der Hund schüttelt Wasser aus seinem Fell.',
        'Seine Futterschüssel ist leer.',
      ],
    ),
    GermanTask(
      id: 'g4-evidence-inference-early-sport',
      competencyId: GermanCompetencyId.readingInference,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Hinweise, die dafür sprechen, dass Paul am nächsten Morgen früh Sport hat.',
      prompt:
          'Paul legt am Abend seine Sportsachen neben die Tür. Er stellt den Wecker eine Stunde früher als sonst. Auf dem Tisch steht ein Glas Wasser.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Paul legt am Abend seine Sportsachen neben die Tür.',
        'Er stellt den Wecker eine Stunde früher als sonst.',
      ],
      choices: <String>[
        'Paul legt am Abend seine Sportsachen neben die Tür.',
        'Er stellt den Wecker eine Stunde früher als sonst.',
        'Auf dem Tisch steht ein Glas Wasser.',
      ],
    ),
    GermanTask(
      id: 'g4-evidence-mainidea-water',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Aussagen, die die Kernaussage des Textes tragen.',
      prompt:
          'Beim Zähneputzen läuft oft unnötig Wasser. Wer den Hahn zwischendurch schließt, kann jeden Tag viele Liter sparen. Zahnbürsten gibt es in vielen Farben.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Beim Zähneputzen läuft oft unnötig Wasser.',
        'Wer den Hahn zwischendurch schließt, kann jeden Tag viele Liter sparen.',
      ],
      choices: <String>[
        'Beim Zähneputzen läuft oft unnötig Wasser.',
        'Wer den Hahn zwischendurch schließt, kann jeden Tag viele Liter sparen.',
        'Zahnbürsten gibt es in vielen Farben.',
      ],
    ),
    GermanTask(
      id: 'g4-evidence-mainidea-hedgehog',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Aussagen, die die Kernaussage des Textes tragen.',
      prompt:
          'Igel finden in Laubhaufen Schutz für den Winter. Wer im Herbst etwas Laub liegen lässt, kann ihnen helfen. Igel haben viele Stacheln.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Igel finden in Laubhaufen Schutz für den Winter.',
        'Wer im Herbst etwas Laub liegen lässt, kann ihnen helfen.',
      ],
      choices: <String>[
        'Igel finden in Laubhaufen Schutz für den Winter.',
        'Wer im Herbst etwas Laub liegen lässt, kann ihnen helfen.',
        'Igel haben viele Stacheln.',
      ],
    ),
    GermanTask(
      id: 'g4-evidence-mainidea-reading',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Aussagen, die die Kernaussage des Textes tragen.',
      prompt:
          'Wer regelmäßig liest, begegnet vielen neuen Wörtern. Mit der Zeit fällt es oft leichter, längere Texte zu verstehen. Die Bücherei schließt um sechs Uhr.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Wer regelmäßig liest, begegnet vielen neuen Wörtern.',
        'Mit der Zeit fällt es oft leichter, längere Texte zu verstehen.',
      ],
      choices: <String>[
        'Wer regelmäßig liest, begegnet vielen neuen Wörtern.',
        'Mit der Zeit fällt es oft leichter, längere Texte zu verstehen.',
        'Die Bücherei schließt um sechs Uhr.',
      ],
    ),
    GermanTask(
      id: 'g4-evidence-mainidea-bees',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Aussagen, die die Kernaussage des Textes tragen.',
      prompt:
          'Bienen bestäuben viele Blüten. Dadurch helfen sie Pflanzen, Früchte und Samen zu bilden. Eine Biene hat sechs Beine.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Bienen bestäuben viele Blüten.',
        'Dadurch helfen sie Pflanzen, Früchte und Samen zu bilden.',
      ],
      choices: <String>[
        'Bienen bestäuben viele Blüten.',
        'Dadurch helfen sie Pflanzen, Früchte und Samen zu bilden.',
        'Eine Biene hat sechs Beine.',
      ],
    ),
    GermanTask(
      id: 'g4-evidence-mainidea-recycling',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Aussagen, die die Kernaussage des Textes tragen.',
      prompt:
          'Die Klasse sammelt eine Woche lang Altpapier. Sie will weniger Papier wegwerfen und Rohstoffe sparen. Am Freitag trägt Ben eine rote Jacke.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Die Klasse sammelt eine Woche lang Altpapier.',
        'Sie will weniger Papier wegwerfen und Rohstoffe sparen.',
      ],
      choices: <String>[
        'Die Klasse sammelt eine Woche lang Altpapier.',
        'Sie will weniger Papier wegwerfen und Rohstoffe sparen.',
        'Am Freitag trägt Ben eine rote Jacke.',
      ],
    ),
    GermanTask(
      id: 'g4-evidence-mainidea-birds',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction:
          'Markiere die Aussagen, die die Kernaussage des Textes tragen.',
      prompt:
          'Viele Zugvögel fliegen im Herbst in wärmere Gebiete. Dort finden sie im Winter leichter Nahrung. Im Frühling kehren viele Arten zurück. Ein Vogel sitzt auf dem Gartenzaun.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Viele Zugvögel fliegen im Herbst in wärmere Gebiete.',
        'Dort finden sie im Winter leichter Nahrung.',
        'Im Frühling kehren viele Arten zurück.',
      ],
      choices: <String>[
        'Viele Zugvögel fliegen im Herbst in wärmere Gebiete.',
        'Dort finden sie im Winter leichter Nahrung.',
        'Im Frühling kehren viele Arten zurück.',
        'Ein Vogel sitzt auf dem Gartenzaun.',
      ],
    ),
  ];
}
