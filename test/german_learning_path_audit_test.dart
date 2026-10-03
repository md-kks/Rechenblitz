import 'package:flutter_test/flutter_test.dart';
import 'package:rechenblitz/core/grade_level.dart';
import 'package:rechenblitz/subjects/german/german_competency.dart';
import 'package:rechenblitz/subjects/german/german_competency_catalog.dart';
import 'package:rechenblitz/subjects/german/german_learning_domain.dart';
import 'package:rechenblitz/subjects/german/german_task.dart';
import 'package:rechenblitz/subjects/german/german_task_catalog.dart';

void main() {
  test('all 36 competencies have deep and varied task pools', () {
    expect(GermanCompetencyId.values, hasLength(36));
    for (final competency in GermanCompetencyId.values) {
      final tasks = GermanTaskCatalog.forCompetency(competency);
      expect(tasks.length, greaterThanOrEqualTo(18), reason: competency.name);
      expect(
        tasks.map((task) => task.id).toSet().length,
        tasks.length,
        reason: competency.name,
      );
      expect(
        tasks.every((task) => task.isWellFormed),
        isTrue,
        reason: competency.name,
      );
    }
  });

  test('each grade has broad curriculum coverage', () {
    for (final grade in GradeLevel.values) {
      final recommended = GermanCompetencyId.values
          .where(
            (id) =>
                GermanCompetencyCatalog.definition(id).isRecommendedFor(grade),
          )
          .toSet();
      final available = GermanTaskCatalog.forGrade(
        grade,
      ).map((task) => task.competencyId).toSet();
      expect(available.containsAll(recommended), isTrue, reason: grade.name);
      for (final domain in GermanLearningDomain.values) {
        expect(
          GermanTaskCatalog.forDomain(domain, grade),
          isNotEmpty,
          reason: '${grade.name}/${domain.name}',
        );
      }
    }
  });

  test('active language competencies are not selection-only', () {
    const active = <GermanCompetencyId>{
      GermanCompetencyId.syllableSegmentation,
      GermanCompetencyId.wordBuilding,
      GermanCompetencyId.wordFamilies,
      GermanCompetencyId.nounArticle,
      GermanCompetencyId.singularPlural,
      GermanCompetencyId.adjectiveRecognition,
      GermanCompetencyId.verbRecognition,
      GermanCompetencyId.verbInflection,
      GermanCompetencyId.sentenceWordOrder,
      GermanCompetencyId.sentencePunctuation,
      GermanCompetencyId.sentenceWriting,
      GermanCompetencyId.spellingStrategies,
      GermanCompetencyId.compoundWords,
      GermanCompetencyId.subjectPredicate,
      GermanCompetencyId.sentenceConstituents,
      GermanCompetencyId.verbTenses,
      GermanCompetencyId.textSequence,
      GermanCompetencyId.sentenceConnections,
      GermanCompetencyId.textRevision,
      GermanCompetencyId.directSpeechPunctuation,
    };
    for (final competency in active) {
      final interactions = GermanTaskCatalog.forCompetency(
        competency,
      ).map((task) => task.interaction).toSet();
      expect(
        interactions.any(
          (interaction) => interaction != GermanTaskInteraction.singleChoice,
        ),
        isTrue,
        reason: competency.name,
      );
    }
  });

  test(
    'early reading uses recognition while later reading requires evidence marking',
    () {
      final wordRecognition = GermanTaskCatalog.forCompetency(
        GermanCompetencyId.wordRecognition,
      );
      expect(
        wordRecognition.every(
          (task) => task.interaction == GermanTaskInteraction.singleChoice,
        ),
        isTrue,
        reason: 'picture-to-word recognition is intentionally selection-based',
      );

      for (final competency in <GermanCompetencyId>[
        GermanCompetencyId.textInformation,
        GermanCompetencyId.readingInference,
        GermanCompetencyId.textMainIdea,
      ]) {
        final tasks = GermanTaskCatalog.forCompetency(competency);
        expect(
          tasks
              .where(
                (task) =>
                    task.interaction == GermanTaskInteraction.tokenSelection,
              )
              .length,
          greaterThanOrEqualTo(6),
          reason: competency.name,
        );
      }
    },
  );

  test('listening competencies keep a genuine auditory pool', () {
    const listening = <GermanCompetencyId>{
      GermanCompetencyId.letterSoundMatch,
      GermanCompetencyId.listeningComprehension,
      GermanCompetencyId.conversationRules,
      GermanCompetencyId.oralRetelling,
      GermanCompetencyId.listeningMainIdeas,
      GermanCompetencyId.presentationStructure,
      GermanCompetencyId.discussionReasoning,
    };
    for (final competency in listening) {
      final tasks = GermanTaskCatalog.forCompetency(competency);
      expect(
        tasks.where((task) => task.requiresSpeech).length,
        greaterThanOrEqualTo(6),
        reason: competency.name,
      );
    }
  });

  test('productive upper-primary writing has two full fresh rounds', () {
    const productive = <GermanCompetencyId>{
      GermanCompetencyId.sentenceWriting,
      GermanCompetencyId.sentenceConnections,
      GermanCompetencyId.textRevision,
    };
    for (final competency in productive) {
      final typed = GermanTaskCatalog.forCompetency(competency)
          .where((task) => task.interaction == GermanTaskInteraction.typedText)
          .toList();
      expect(typed.length, greaterThanOrEqualTo(12), reason: competency.name);
    }
  });
}
