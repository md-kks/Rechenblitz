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
    GermanCompetencyDefinition(
      id: GermanCompetencyId.spellingStrategies,
      label: 'Rechtschreibstrategien anwenden',
      description:
          'Wörter durch Verlängern, Ableiten und Wortverwandtschaft prüfen.',
      domain: GermanLearningDomain.spelling,
      recommendedFromGrade: GradeLevel.third,
      prerequisites: <GermanCompetencyId>[
        GermanCompetencyId.syllableSegmentation,
        GermanCompetencyId.wordFamilies,
      ],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.dictionarySkills,
      label: 'Wörterbuch sicher nutzen',
      description: 'Wörter alphabetisch und über ihre Grundform nachschlagen.',
      domain: GermanLearningDomain.spelling,
      recommendedFromGrade: GradeLevel.third,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.alphabeticalOrder],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.compoundWords,
      label: 'Zusammengesetzte Wörter verstehen',
      description:
          'Zusammengesetzte Wörter bilden, zerlegen und in ihrer Bedeutung erfassen.',
      domain: GermanLearningDomain.vocabulary,
      recommendedFromGrade: GradeLevel.third,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.wordFamilies],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.subjectPredicate,
      label: 'Subjekt und Prädikat bestimmen',
      description:
          'Den Satzkern mit Wer-oder-was-Frage und Verbprobe erkennen.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.third,
      prerequisites: <GermanCompetencyId>[
        GermanCompetencyId.nounArticle,
        GermanCompetencyId.verbRecognition,
      ],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.sentenceConstituents,
      label: 'Satzglieder untersuchen',
      description:
          'Zusammengehörige Satzteile mit W-Fragen und Umstellprobe erkennen.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.third,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.subjectPredicate],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.verbTenses,
      label: 'Zeitformen von Verben verwenden',
      description:
          'Gegenwart und einfache Vergangenheitsformen passend unterscheiden und bilden.',
      domain: GermanLearningDomain.language,
      recommendedFromGrade: GradeLevel.third,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.verbInflection],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.readingInference,
      label: 'Zwischen den Zeilen lesen',
      description:
          'Aus mehreren Textsignalen eine begründete Schlussfolgerung ziehen.',
      domain: GermanLearningDomain.reading,
      recommendedFromGrade: GradeLevel.third,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.textInformation],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.textSequence,
      label: 'Textabläufe ordnen',
      description:
          'Ereignisse und Handlungsschritte in ihrer Reihenfolge erfassen.',
      domain: GermanLearningDomain.reading,
      recommendedFromGrade: GradeLevel.third,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.textInformation],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.textMainIdea,
      label: 'Kernaussage eines Textes erfassen',
      description:
          'Wichtige Aussagen von Einzelheiten unterscheiden und passend zusammenfassen.',
      domain: GermanLearningDomain.reading,
      recommendedFromGrade: GradeLevel.fourth,
      prerequisites: <GermanCompetencyId>[
        GermanCompetencyId.readingInference,
        GermanCompetencyId.textSequence,
      ],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.sentenceConnections,
      label: 'Sätze sinnvoll verknüpfen',
      description:
          'Gedanken mit passenden Verbindungswörtern logisch miteinander verbinden.',
      domain: GermanLearningDomain.writing,
      recommendedFromGrade: GradeLevel.fourth,
      prerequisites: <GermanCompetencyId>[GermanCompetencyId.sentenceWriting],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.textRevision,
      label: 'Texte gezielt überarbeiten',
      description:
          'Verständlichkeit, Wortwahl, Reihenfolge und sprachliche Form verbessern.',
      domain: GermanLearningDomain.writing,
      recommendedFromGrade: GradeLevel.fourth,
      prerequisites: <GermanCompetencyId>[
        GermanCompetencyId.sentenceWriting,
        GermanCompetencyId.sentenceConnections,
      ],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.listeningMainIdeas,
      label: 'Wichtiges beim Zuhören erfassen',
      description:
          'Kernaussagen aus längeren gesprochenen Informationen herausfiltern.',
      domain: GermanLearningDomain.listening,
      recommendedFromGrade: GradeLevel.fourth,
      prerequisites: <GermanCompetencyId>[
        GermanCompetencyId.listeningComprehension,
      ],
    ),
    GermanCompetencyDefinition(
      id: GermanCompetencyId.directSpeechPunctuation,
      label: 'Wörtliche Rede kennzeichnen',
      description:
          'Begleitsatz, Doppelpunkt und Anführungszeichen passend verwenden.',
      domain: GermanLearningDomain.spelling,
      recommendedFromGrade: GradeLevel.fourth,
      prerequisites: <GermanCompetencyId>[
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
