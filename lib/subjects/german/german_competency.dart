import '../../core/grade_level.dart';
import 'german_learning_domain.dart';

enum GermanCompetencyId {
  letterSoundMatch,
  vowelConsonantRecognition,
  alphabeticalOrder,
  syllableSegmentation,
  wordBuilding,
  wordFamilies,
  nounArticle,
  singularPlural,
  adjectiveRecognition,
  verbRecognition,
  verbInflection,
  sentenceWordOrder,
  sentencePunctuation,
  sentenceTypes,
  wordRecognition,
  sentenceComprehension,
  textInformation,
  listeningComprehension,
  sentenceWriting,
}

class GermanCompetencyDefinition {
  const GermanCompetencyDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.domain,
    required this.recommendedFromGrade,
    this.prerequisites = const <GermanCompetencyId>[],
  });

  final GermanCompetencyId id;
  final String label;
  final String description;
  final GermanLearningDomain domain;
  final GradeLevel recommendedFromGrade;
  final List<GermanCompetencyId> prerequisites;

  bool isRecommendedFor(GradeLevel grade) =>
      grade.index >= recommendedFromGrade.index;
}
