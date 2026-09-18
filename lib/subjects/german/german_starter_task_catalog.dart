import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_learning_domain.dart';
import 'german_task.dart';

class GermanStarterTaskCatalog {
  const GermanStarterTaskCatalog._();

  static const tasks = <GermanTask>[
    GermanTask(
      id: 'g1-letter-sound-m',
      competencyId: GermanCompetencyId.letterSoundMatch,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Welcher Buchstabe passt zum Laut?',
      prompt: 'mmm',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['M'],
      choices: <String>['M', 'L', 'S'],
    ),
    GermanTask(
      id: 'g1-vowel-a',
      competencyId: GermanCompetencyId.vowelConsonantRecognition,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Welcher Buchstabe ist ein Selbstlaut?',
      prompt: 'Wähle den Selbstlaut.',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['A'],
      choices: <String>['A', 'M', 'T'],
    ),
    GermanTask(
      id: 'g1-alpha-cat-dog',
      competencyId: GermanCompetencyId.alphabeticalOrder,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Welches Wort kommt im Alphabet zuerst?',
      prompt: 'Hund · Katze · Maus',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['Hund'],
      choices: <String>['Hund', 'Katze', 'Maus'],
    ),
    GermanTask(
      id: 'g1-syllables-lampe',
      competencyId: GermanCompetencyId.syllableSegmentation,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Welches Wort hat zwei Sprechsilben?',
      prompt: 'Sprich die Wörter langsam.',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['Lampe'],
      choices: <String>['Lampe', 'Haus', 'Ball'],
    ),
    GermanTask(
      id: 'g1-read-word-sonne',
      competencyId: GermanCompetencyId.wordRecognition,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Welches Wort passt zum Bild?',
      prompt: 'Bild: ☀️',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['Sonne'],
      choices: <String>['Sonne', 'Mond', 'Stern'],
    ),
    GermanTask(
      id: 'g1-sentence-understand-dog',
      competencyId: GermanCompetencyId.sentenceComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Was macht der Hund?',
      prompt: 'Der Hund schläft im Korb.',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['Er schläft.'],
      choices: <String>['Er schläft.', 'Er rennt.', 'Er frisst.'],
    ),
    GermanTask(
      id: 'g1-listen-cat',
      competencyId: GermanCompetencyId.listeningComprehension,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Hör genau zu. Welches Tier hörst du?',
      prompt: 'Tippe auf Lautsprecher und wähle dann das Tier.',
      interaction: GermanTaskInteraction.listeningChoice,
      acceptedAnswers: <String>['Katze'],
      choices: <String>['Katze', 'Hund', 'Maus'],
      spokenText: 'Die Katze sitzt auf dem Fensterbrett.',
    ),
    GermanTask(
      id: 'g1-order-bird-flies',
      competencyId: GermanCompetencyId.sentenceWordOrder,
      recommendedFromGrade: GradeLevel.first,
      instruction: 'Bringe die Wörter in die richtige Reihenfolge.',
      prompt: 'fliegt · Der Vogel · hoch',
      interaction: GermanTaskInteraction.wordOrder,
      acceptedAnswers: <String>['Der Vogel fliegt hoch'],
      choices: <String>['Der Vogel', 'fliegt', 'hoch'],
    ),
    GermanTask(
      id: 'g2-noun-article-tree',
      competencyId: GermanCompetencyId.nounArticle,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Welcher Artikel passt?',
      prompt: '___ Baum',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['der'],
      choices: <String>['der', 'die', 'das'],
    ),
    GermanTask(
      id: 'g2-plural-house',
      competencyId: GermanCompetencyId.singularPlural,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Wie lautet die Mehrzahl?',
      prompt: 'das Haus',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['die Häuser'],
      choices: <String>['die Häuser', 'die Hunde', 'die Bäume'],
    ),
    GermanTask(
      id: 'g2-adjective-green',
      competencyId: GermanCompetencyId.adjectiveRecognition,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Welches Wort beschreibt eine Eigenschaft?',
      prompt: 'Der grüne Ball rollt.',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['grüne'],
      choices: <String>['grüne', 'Ball', 'rollt'],
    ),
    GermanTask(
      id: 'g2-verb-runs',
      competencyId: GermanCompetencyId.verbRecognition,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Welches Wort sagt, was jemand tut?',
      prompt: 'Mia rennt schnell.',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['rennt'],
      choices: <String>['Mia', 'rennt', 'schnell'],
    ),
    GermanTask(
      id: 'g2-verb-inflect-play',
      competencyId: GermanCompetencyId.verbInflection,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Welche Form passt in den Satz?',
      prompt: 'Wir ___ im Hof. · Grundform: spielen',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['spielen'],
      choices: <String>['spielen', 'spielt', 'spielst'],
    ),
    GermanTask(
      id: 'g2-punctuation-question',
      competencyId: GermanCompetencyId.sentencePunctuation,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Welches Satzzeichen gehört ans Ende?',
      prompt: 'Wo ist mein Heft',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['?'],
      choices: <String>['.', '?', '!'],
    ),
    GermanTask(
      id: 'g2-sentence-type-question',
      competencyId: GermanCompetencyId.sentenceTypes,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Welche Satzart ist das?',
      prompt: 'Kommst du heute mit?',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['Fragesatz'],
      choices: <String>['Fragesatz', 'Aussagesatz', 'Aufforderungssatz'],
    ),
    GermanTask(
      id: 'g2-word-family-drive',
      competencyId: GermanCompetencyId.wordFamilies,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Welches Wort gehört zur Wortfamilie von „fahren“?',
      prompt: 'fahren',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['Fahrer'],
      choices: <String>['Fahrer', 'Maler', 'Leser'],
    ),
    GermanTask(
      id: 'g2-text-info-school',
      competencyId: GermanCompetencyId.textInformation,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Lies den Text. Wann beginnt die Schule?',
      prompt: 'Lina geht um sieben Uhr los. Die Schule beginnt um acht Uhr.',
      interaction: GermanTaskInteraction.singleChoice,
      acceptedAnswers: <String>['um acht Uhr'],
      choices: <String>['um sieben Uhr', 'um acht Uhr', 'um neun Uhr'],
    ),
    GermanTask(
      id: 'g2-write-sentence-rain',
      competencyId: GermanCompetencyId.sentenceWriting,
      recommendedFromGrade: GradeLevel.second,
      instruction: 'Schreibe aus den Wörtern einen vollständigen Satz.',
      prompt: 'heute · regnet · es',
      interaction: GermanTaskInteraction.typedText,
      acceptedAnswers: <String>['Heute regnet es.', 'Es regnet heute.'],
    ),
  ];

  static List<GermanTask> forGrade(GradeLevel grade) => tasks
      .where((task) => task.recommendedFromGrade.index <= grade.index)
      .toList();

  static List<GermanTask> forDomain(
    GermanLearningDomain domain,
    GradeLevel grade,
  ) => forGrade(grade)
      .where(
        (task) =>
            GermanCompetencyCatalog.definition(task.competencyId).domain ==
            domain,
      )
      .toList();

  static List<GermanTask> forCompetency(GermanCompetencyId competencyId) =>
      tasks.where((task) => task.competencyId == competencyId).toList();
}
