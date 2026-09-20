import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_task.dart';

class GermanReadingDiversityTaskCatalog {
  const GermanReadingDiversityTaskCatalog._();

  static const tasks = <GermanTask>[
    GermanTask(
      id: 'g1-read-evidence-frog-stone',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Wer sitzt und wo?',
      prompt: 'Der Frosch sitzt auf dem Stein.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Der Frosch', 'auf dem Stein'],
      choices: <String>['Der Frosch', 'sitzt', 'auf dem Stein'],
    ),
    GermanTask(
      id: 'g1-read-evidence-mia-hat',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Wer trägt und was?',
      prompt: 'Mia trägt eine rote Mütze.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Mia', 'eine rote Mütze'],
      choices: <String>['Mia', 'trägt', 'eine rote Mütze'],
    ),
    GermanTask(
      id: 'g1-read-evidence-grandpa-evening',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Wer gießt und wann?',
      prompt: 'Opa gießt abends die Blumen.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Opa', 'abends'],
      choices: <String>['Opa', 'gießt', 'abends', 'die Blumen'],
    ),
    GermanTask(
      id: 'g1-read-evidence-book-lamp',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Was liegt und wo?',
      prompt: 'Das Buch liegt neben der Lampe.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Das Buch', 'neben der Lampe'],
      choices: <String>['Das Buch', 'liegt', 'neben der Lampe'],
    ),
    GermanTask(
      id: 'g1-read-evidence-lina-dog',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Wer füttert und wen?',
      prompt: 'Lina füttert den Hund im Garten.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Lina', 'den Hund'],
      choices: <String>['Lina', 'füttert', 'den Hund', 'im Garten'],
    ),
    GermanTask(
      id: 'g1-read-evidence-train-station',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Markiere: Was hält und wo?',
      prompt: 'Der Zug hält am Bahnhof.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Der Zug', 'am Bahnhof'],
      choices: <String>['Der Zug', 'hält', 'am Bahnhof'],
    ),
    GermanTask(
      id: 'g2-read-info-museum',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction:
          'Markiere: Wann startet der Besuch und was sieht die Klasse zuerst?',
      prompt:
          'Um neun Uhr beginnt der Museumsbesuch. Zuerst sieht die Klasse ein großes Dinosaurierskelett. Danach geht sie in die Steinzeitabteilung.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Um neun Uhr beginnt der Museumsbesuch.',
        'Zuerst sieht die Klasse ein großes Dinosaurierskelett.',
      ],
      choices: <String>[
        'Um neun Uhr beginnt der Museumsbesuch.',
        'Zuerst sieht die Klasse ein großes Dinosaurierskelett.',
        'Danach geht sie in die Steinzeitabteilung.',
      ],
    ),
    GermanTask(
      id: 'g2-read-info-trip-meeting',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere Treffpunkt und Treffzeit.',
      prompt:
          'Die Klasse trifft sich am Freitag um halb acht vor der Schule. Der Bus fährt um acht Uhr los.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['um halb acht', 'vor der Schule'],
      choices: <String>[
        'am Freitag',
        'um halb acht',
        'vor der Schule',
        'um acht Uhr',
      ],
    ),
    GermanTask(
      id: 'g2-read-info-sandwich',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere den ersten und den letzten Arbeitsschritt.',
      prompt:
          'Zuerst bestreicht Ben das Brot mit Frischkäse. Danach legt er Gurkenscheiben darauf. Zum Schluss klappt er die zweite Scheibe Brot darauf.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Zuerst bestreicht Ben das Brot mit Frischkäse.',
        'Zum Schluss klappt er die zweite Scheibe Brot darauf.',
      ],
      choices: <String>[
        'Zuerst bestreicht Ben das Brot mit Frischkäse.',
        'Danach legt er Gurkenscheiben darauf.',
        'Zum Schluss klappt er die zweite Scheibe Brot darauf.',
      ],
    ),
    GermanTask(
      id: 'g2-read-info-weather',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere, wie das Wetter am Morgen und am Nachmittag ist.',
      prompt:
          'Am Morgen ist es neblig. Gegen Mittag löst sich der Nebel auf. Am Nachmittag scheint die Sonne.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Am Morgen ist es neblig.',
        'Am Nachmittag scheint die Sonne.',
      ],
      choices: <String>[
        'Am Morgen ist es neblig.',
        'Gegen Mittag löst sich der Nebel auf.',
        'Am Nachmittag scheint die Sonne.',
      ],
    ),
    GermanTask(
      id: 'g2-read-info-library-return',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction:
          'Markiere, was Nora ausleiht und wann sie es zurückgeben soll.',
      prompt:
          'Nora leiht ein Buch über Planeten aus. Auf dem Zettel steht als Rückgabetag der 18. Oktober. Eine Zeitschrift nimmt sie nicht mit.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['ein Buch über Planeten', 'der 18. Oktober'],
      choices: <String>[
        'ein Buch über Planeten',
        'der 18. Oktober',
        'eine Zeitschrift',
      ],
    ),
    GermanTask(
      id: 'g2-read-info-football',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Markiere, wer das Tor schießt und wie das Spiel endet.',
      prompt:
          'Kurz vor Schluss schießt Amir das entscheidende Tor. Seine Mannschaft gewinnt mit 2 zu 1. Danach jubeln alle zusammen.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>['Amir', 'mit 2 zu 1'],
      choices: <String>[
        'Amir',
        'das entscheidende Tor',
        'mit 2 zu 1',
        'alle zusammen',
      ],
    ),
    GermanTask(
      id: 'g4-read-main-breakfast',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die Aussagen, die die Kernaussage tragen.',
      prompt:
          'Ein ausgewogenes Frühstück liefert dem Körper Energie. Wer morgens etwas isst, kann sich in der Schule oft besser konzentrieren. Manche Müslischalen sind blau.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Ein ausgewogenes Frühstück liefert dem Körper Energie.',
        'Wer morgens etwas isst, kann sich in der Schule oft besser konzentrieren.',
      ],
      choices: <String>[
        'Ein ausgewogenes Frühstück liefert dem Körper Energie.',
        'Wer morgens etwas isst, kann sich in der Schule oft besser konzentrieren.',
        'Manche Müslischalen sind blau.',
      ],
    ),
    GermanTask(
      id: 'g4-read-main-repair',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die Aussagen, die die Kernaussage tragen.',
      prompt:
          'Kaputte Dinge müssen nicht sofort weggeworfen werden. Eine Reparatur spart oft Rohstoffe und Geld. Werkzeugkästen können viele Fächer haben.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Kaputte Dinge müssen nicht sofort weggeworfen werden.',
        'Eine Reparatur spart oft Rohstoffe und Geld.',
      ],
      choices: <String>[
        'Kaputte Dinge müssen nicht sofort weggeworfen werden.',
        'Eine Reparatur spart oft Rohstoffe und Geld.',
        'Werkzeugkästen können viele Fächer haben.',
      ],
    ),
    GermanTask(
      id: 'g4-read-main-trees',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die Aussagen, die die Kernaussage tragen.',
      prompt:
          'Bäume spenden an heißen Tagen Schatten und kühlen ihre Umgebung. Mehr Bäume auf Schulhöfen können deshalb das Klima dort angenehmer machen. Manche Blätter sind gezackt.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Bäume spenden an heißen Tagen Schatten und kühlen ihre Umgebung.',
        'Mehr Bäume auf Schulhöfen können deshalb das Klima dort angenehmer machen.',
      ],
      choices: <String>[
        'Bäume spenden an heißen Tagen Schatten und kühlen ihre Umgebung.',
        'Mehr Bäume auf Schulhöfen können deshalb das Klima dort angenehmer machen.',
        'Manche Blätter sind gezackt.',
      ],
    ),
    GermanTask(
      id: 'g4-read-main-reading',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die Aussagen, die die Kernaussage tragen.',
      prompt:
          'Regelmäßiges Lesen erweitert den Wortschatz und hilft, Texte schneller zu verstehen. Schon kurze tägliche Lesezeiten können dabei nützlich sein. Bücher gibt es in verschiedenen Formaten.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Regelmäßiges Lesen erweitert den Wortschatz und hilft, Texte schneller zu verstehen.',
        'Schon kurze tägliche Lesezeiten können dabei nützlich sein.',
      ],
      choices: <String>[
        'Regelmäßiges Lesen erweitert den Wortschatz und hilft, Texte schneller zu verstehen.',
        'Schon kurze tägliche Lesezeiten können dabei nützlich sein.',
        'Bücher gibt es in verschiedenen Formaten.',
      ],
    ),
    GermanTask(
      id: 'g4-read-main-movement',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die Aussagen, die die Kernaussage tragen.',
      prompt:
          'Kurze Bewegungspausen lockern den Körper und können neue Konzentration bringen. Deshalb ist es sinnvoll, langes Sitzen immer wieder zu unterbrechen. Turnschuhe haben oft Schnürsenkel.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Kurze Bewegungspausen lockern den Körper und können neue Konzentration bringen.',
        'Deshalb ist es sinnvoll, langes Sitzen immer wieder zu unterbrechen.',
      ],
      choices: <String>[
        'Kurze Bewegungspausen lockern den Körper und können neue Konzentration bringen.',
        'Deshalb ist es sinnvoll, langes Sitzen immer wieder zu unterbrechen.',
        'Turnschuhe haben oft Schnürsenkel.',
      ],
    ),
    GermanTask(
      id: 'g4-read-main-compost',
      competencyId: GermanCompetencyId.textMainIdea,
      recommendedFromGrade: GradeLevel.fourth,
      instruction: 'Markiere die Aussagen, die die Kernaussage tragen.',
      prompt:
          'Aus geeigneten Küchen- und Gartenabfällen kann Kompost entstehen. Dieser liefert dem Boden später Nährstoffe und verbessert ihn. Kompostbehälter sind häufig dunkel.',
      interaction: GermanTaskInteraction.tokenSelection,
      acceptedAnswers: <String>[
        'Aus geeigneten Küchen- und Gartenabfällen kann Kompost entstehen.',
        'Dieser liefert dem Boden später Nährstoffe und verbessert ihn.',
      ],
      choices: <String>[
        'Aus geeigneten Küchen- und Gartenabfällen kann Kompost entstehen.',
        'Dieser liefert dem Boden später Nährstoffe und verbessert ihn.',
        'Kompostbehälter sind häufig dunkel.',
      ],
    ),
  ];
}
