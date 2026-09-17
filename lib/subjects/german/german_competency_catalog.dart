import '../../core/grade_level.dart';
import 'german_competency.dart';
import 'german_learning_domain.dart';

class GermanCompetencyCatalog {
  const GermanCompetencyCatalog._();

  static const definitions = <GermanCompetencyDefinition>[
    GermanCompetencyDefinition(
      id: GermanCompetencyId.letterSoundMatch,
      label: 'Laute und Buchstaben verbinden',
      description: 'Gehörte Laute passenden Buchstaben zuordnen.',
      domain: GermanLearningDomain.spelling,
      recommendedFromGrade: GradeLevel.first,
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.vowelConsonantRecognition,
      label: 'Selbstlaute und Mitlaute unterscheiden',
      description: 'Vokale und Konsonanten in Wörtern erkennen.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.first,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.letterSoundMatch],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.alphabeticalOrder,
      label: 'Alphabetisch ordnen',
      description: 'Buchstaben und einfache Wörter nach dem Alphabet ordnen.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.first,
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.syllableSegmentation,
      label: 'Wörter in Silben gliedern',
      description: 'Wörter hören und sicher in Sprechsilben zerlegen.',
      domain: GermanLearningDomain.spelling,
      recommendedFromGrade: GradeLevel.first,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.letterSoundMatch],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.wordBuilding,
      label: 'Wörter aufbauen und verändern',
      description: 'Laute, Buchstaben und Wortbausteine gezielt verändern.',
      domain: GermanLearningDomain.vocabulary,
      recommendedFromGrade: GradeLevel.first,
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.wordRecognition,
      label: 'Wörter sicher lesen',
      description: 'Häufige und lautgetreue Wörter zunehmend sicher erkennen.',
      domain: GermanLearningDomain.reading,
      recommendedFromGrade: GradeLevel.first,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.letterSoundMatch],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.sentenceComprehension,
      label: 'Sätze verstehen',
      description: 'Informationen aus kurzen Sätzen sicher entnehmen.',
      domain: GermanLearningDomain.reading,
      recommendedFromGrade: GradeLevel.first,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.wordRecognition],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.listeningComprehension,
      label: 'Genau zuhören und verstehen',
      description:
          'Informationen aus gesprochenen Wörtern und Sätzen entnehmen.',
      domain: GermanLearningDomain.listening,
      recommendedFromGrade: GradeLevel.first,
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.sentenceWordOrder,
      label: 'Sätze sinnvoll aufbauen',
      description: 'Wörter zu verständlichen einfachen Sätzen ordnen.',
      domain: GermanLearningDomain.writing,
      recommendedFromGrade: GradeLevel.first,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.wordRecognition],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.nounArticle,
      label: 'Nomen und Artikel erkennen',
      description: 'Nomen erkennen und einen passenden Artikel zuordnen.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.second,
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.singularPlural,
      label: 'Einzahl und Mehrzahl bilden',
      description: 'Nomen zwischen Singular und Plural verändern.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.second,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.nounArticle],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.adjectiveRecognition,
      label: 'Adjektive erkennen',
      description: 'Eigenschaftswörter in einfachen Sätzen erkennen.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.second,
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.verbRecognition,
      label: 'Verben erkennen',
      description: 'Tätigkeitswörter in einfachen Sätzen erkennen.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.second,
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.verbInflection,
      label: 'Verben passend verändern',
      description: 'Grundform und einfache gebeugte Verbformen unterscheiden.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.second,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.verbRecognition],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.sentencePunctuation,
      label: 'Satzschlusszeichen setzen',
      description: 'Punkt, Fragezeichen und Ausrufezeichen passend verwenden.',
      domain: GermanLearningDomain.spelling,
      recommendedFromGrade: GradeLevel.second,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.sentenceWordOrder],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.sentenceTypes,
      label: 'Satzarten unterscheiden',
      description: 'Aussage-, Frage- und Aufforderungssätze unterscheiden.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.second,
      prerequisites: <GermanCompetencyId>[
        GermanCompetencyId.sentencePunctuation,
      ],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.wordFamilies,
      label: 'Wortfamilien erkennen',
      description: 'Verwandte Wörter über gemeinsame Wortbausteine erkennen.',
      domain: GermanLearningDomain.vocabulary,
      recommendedFromGrade: GradeLevel.second,
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.textInformation,
      label: 'Informationen aus Texten entnehmen',
      description: 'Wichtige Informationen in kurzen Texten finden.',
      domain: GermanLearningDomain.reading,
      recommendedFromGrade: GradeLevel.second,
      prerequisites: <GermanCompetencyId>[
        GermanCompetencyId.sentenceComprehension,
      ],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.sentenceWriting,
      label: 'Eigene Sätze schreiben',
      description: 'Kurze verständliche Sätze vollständig formulieren.',
      domain: GermanLearningDomain.writing,
      recommendedFromGrade: GradeLevel.second,
      prerequisites: <GermanCompetencyId>[
        GermanCompetencyId.sentenceWordOrder,
        GermanCompetencyId.sentencePunctuation,
      ],
    ),
  ];

  static GermanCompetencyDefinition definition(GermanCompetencyId id) =>
      definitions.firstWhere((definition) => definition.id == id);

  static List<GermanCompetencyDefinition> recommendedFor(GradeLevel grade) =>
      definitions
          .where((definition) => definition.isRecommendedFor(grade))
          .toList();
  static List<GermanCompetencyDefinition> forDomain(
    GermanLearningDomain domain,
    GradeLevel grade,
  ) => definitions
      .where(
        (definition) =>
            definition.domain == domain && definition.isRecommendedFor(grade),
      )
      .toList();
}
