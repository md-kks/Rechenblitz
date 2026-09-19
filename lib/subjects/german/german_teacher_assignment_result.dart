import '../../core/assignments/subject_result_envelope.dart';
import '../../core/grade_level.dart';
import '../../core/learning_subject.dart';
import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_learning_domain.dart';
import 'german_session.dart';
import 'german_teacher_assignment.dart';

class GermanAssignmentCompetencyResult {
  const GermanAssignmentCompetencyResult({
    required this.competencyId,
    required this.completedTasks,
    required this.correctFirstTry,
    required this.incorrectAttempts,
    int? independentCorrectFirstTry,
    this.readAloudAssistedTasks = 0,
  }) : independentCorrectFirstTry =
           independentCorrectFirstTry ?? correctFirstTry;

  final GermanCompetencyId competencyId;
  final int completedTasks;
  final int correctFirstTry;
  final int independentCorrectFirstTry;
  final int readAloudAssistedTasks;
  final int incorrectAttempts;

  int get independentTasks => completedTasks - readAloudAssistedTasks;

  double get accuracy =>
      independentTasks == 0 ? 0 : independentCorrectFirstTry / independentTasks;

  String get label => GermanCompetencyCatalog.definition(competencyId).label;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': competencyId.name,
    'n': completedTasks,
    'c': correctFirstTry,
    's': independentCorrectFirstTry,
    'r': readAloudAssistedTasks,
    'i': incorrectAttempts,
  };

  static GermanAssignmentCompetencyResult fromJson(Map<String, dynamic> json) =>
      GermanAssignmentCompetencyResult(
        competencyId: GermanCompetencyId.values.byName(json['id'] as String),
        completedTasks: (json['n'] as num).toInt(),
        correctFirstTry: (json['c'] as num).toInt(),
        independentCorrectFirstTry:
            (json['s'] as num?)?.toInt() ?? (json['c'] as num).toInt(),
        readAloudAssistedTasks: (json['r'] as num?)?.toInt() ?? 0,
        incorrectAttempts: (json['i'] as num).toInt(),
      );
}

class GermanTeacherAssignmentResult {
  const GermanTeacherAssignmentResult({
    required this.assignmentId,
    required this.gradeLevel,
    required this.domain,
    required this.requestedTasks,
    required this.completedTasks,
    required this.correctFirstTry,
    required this.incorrectAttempts,
    required this.averageResponseMs,
    int? independentCorrectFirstTry,
    this.readAloudAssistedTasks = 0,
    this.targetCompetency,
    this.competencyBreakdown = const <GermanAssignmentCompetencyResult>[],
  }) : independentCorrectFirstTry =
           independentCorrectFirstTry ?? correctFirstTry;

  // Compact QR codes are a persisted wire format. Keep these codebooks
  // stable: append new values, never reorder existing entries.
  static const _gradeCodes = <GradeLevel>[
    GradeLevel.first,
    GradeLevel.second,
    GradeLevel.third,
    GradeLevel.fourth,
  ];
  static const _domainCodes = <GermanLearningDomain>[
    GermanLearningDomain.reading,
    GermanLearningDomain.spelling,
    GermanLearningDomain.language,
    GermanLearningDomain.vocabulary,
    GermanLearningDomain.listening,
    GermanLearningDomain.writing,
  ];
  static const _competencyCodes = <GermanCompetencyId>[
    GermanCompetencyId.letterSoundMatch,
    GermanCompetencyId.vowelConsonantRecognition,
    GermanCompetencyId.alphabeticalOrder,
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
    GermanCompetencyId.sentenceTypes,
    GermanCompetencyId.wordRecognition,
    GermanCompetencyId.sentenceComprehension,
    GermanCompetencyId.textInformation,
    GermanCompetencyId.listeningComprehension,
    GermanCompetencyId.conversationRules,
    GermanCompetencyId.oralRetelling,
    GermanCompetencyId.sentenceWriting,
    GermanCompetencyId.spellingStrategies,
    GermanCompetencyId.dictionarySkills,
    GermanCompetencyId.compoundWords,
    GermanCompetencyId.subjectPredicate,
    GermanCompetencyId.sentenceConstituents,
    GermanCompetencyId.verbTenses,
    GermanCompetencyId.readingInference,
    GermanCompetencyId.textSequence,
    GermanCompetencyId.textMainIdea,
    GermanCompetencyId.sentenceConnections,
    GermanCompetencyId.textRevision,
    GermanCompetencyId.listeningMainIdeas,
    GermanCompetencyId.presentationStructure,
    GermanCompetencyId.discussionReasoning,
    GermanCompetencyId.directSpeechPunctuation,
  ];

  final String assignmentId;
  final GradeLevel gradeLevel;
  final GermanLearningDomain domain;
  final int requestedTasks;
  final int completedTasks;
  final int correctFirstTry;
  final int independentCorrectFirstTry;
  final int readAloudAssistedTasks;
  final int incorrectAttempts;
  final double averageResponseMs;
  final GermanCompetencyId? targetCompetency;
  final List<GermanAssignmentCompetencyResult> competencyBreakdown;

  int get independentTasks => completedTasks - readAloudAssistedTasks;

  double get accuracy =>
      independentTasks == 0 ? 0 : independentCorrectFirstTry / independentTasks;

  String get targetLabel => targetCompetency == null
      ? domain.label
      : GermanCompetencyCatalog.definition(targetCompetency!).label;

  String get summary {
    final evidence = independentTasks == 0
        ? 'noch keine selbstständige Beobachtung'
        : '$independentCorrectFirstTry/$independentTasks '
              'selbstständig direkt richtig';
    final base = 'Auftrag $assignmentId · $targetLabel · $evidence';
    return readAloudAssistedTasks == 0
        ? base
        : '$base · $readAloudAssistedTasks mit Vorlesen';
  }

  SubjectResultEnvelope toEnvelope() => SubjectResultEnvelope(
    subject: LearningSubject.german,
    data: <String, dynamic>{
      'kind': 'assignmentResult',
      'assignmentId': assignmentId,
      'grade': gradeLevel.name,
      'domain': domain.name,
      'requestedTasks': requestedTasks,
      'completedTasks': completedTasks,
      'correctFirstTry': correctFirstTry,
      'independentCorrectFirstTry': independentCorrectFirstTry,
      'readAloudAssistedTasks': readAloudAssistedTasks,
      'incorrectAttempts': incorrectAttempts,
      'averageResponseMs': averageResponseMs.round(),
      'target': targetCompetency?.name,
      if (competencyBreakdown.isNotEmpty)
        'breakdown': competencyBreakdown
            .map((entry) => entry.toJson())
            .toList(growable: false),
    },
  );

  SubjectResultEnvelope _toCompactEnvelope() => SubjectResultEnvelope(
    subject: LearningSubject.german,
    data: <String, dynamic>{
      'k': 'r',
      'a': assignmentId,
      'g': _codeFor(_gradeCodes, gradeLevel),
      'd': _codeFor(_domainCodes, domain),
      'q': requestedTasks,
      'n': completedTasks,
      'c': correctFirstTry,
      's': independentCorrectFirstTry,
      'r': readAloudAssistedTasks,
      'i': incorrectAttempts,
      'm': averageResponseMs.round(),
      if (targetCompetency != null)
        't': _codeFor(_competencyCodes, targetCompetency!),
      if (competencyBreakdown.isNotEmpty)
        'b': competencyBreakdown
            .map(
              (entry) => <int>[
                _codeFor(_competencyCodes, entry.competencyId),
                entry.completedTasks,
                entry.correctFirstTry,
                entry.independentCorrectFirstTry,
                entry.readAloudAssistedTasks,
                entry.incorrectAttempts,
              ],
            )
            .toList(growable: false),
    },
  );

  String toPayload() => _toCompactEnvelope().toPayload();

  static GermanTeacherAssignmentResult fromSession({
    required GermanTeacherAssignment assignment,
    required GermanSessionResult session,
  }) {
    final grouped = <GermanCompetencyId, List<GermanTaskResult>>{};
    for (final taskResult in session.taskResults) {
      grouped
          .putIfAbsent(taskResult.competencyId, () => <GermanTaskResult>[])
          .add(taskResult);
    }
    final breakdown =
        grouped.entries
            .map((entry) {
              final values = entry.value;
              return GermanAssignmentCompetencyResult(
                competencyId: entry.key,
                completedTasks: values.length,
                correctFirstTry: values
                    .where((value) => value.correctFirstTry)
                    .length,
                independentCorrectFirstTry: values
                    .where((value) => value.independentCorrectFirstTry)
                    .length,
                readAloudAssistedTasks: values
                    .where((value) => value.usedReadAloud)
                    .length,
                incorrectAttempts: values.fold<int>(
                  0,
                  (sum, value) => sum + value.incorrectAttempts,
                ),
              );
            })
            .toList(growable: false)
          ..sort(
            (a, b) => a.competencyId.index.compareTo(b.competencyId.index),
          );

    return GermanTeacherAssignmentResult(
      assignmentId: assignment.assignmentId,
      gradeLevel: assignment.gradeLevel,
      domain: assignment.domain,
      requestedTasks: assignment.tasks,
      completedTasks: session.total,
      correctFirstTry: session.correctFirstTry,
      independentCorrectFirstTry: session.independentCorrectFirstTry,
      readAloudAssistedTasks: session.readAloudAssistedAttempts,
      incorrectAttempts: session.incorrectAttempts,
      averageResponseMs: session.averageResponseMs,
      targetCompetency: assignment.targetCompetency,
      competencyBreakdown: breakdown,
    );
  }

  static int _codeFor<T>(List<T> values, T value) {
    final code = values.indexOf(value);
    if (code < 0) throw StateError('value missing from compact codebook');
    return code;
  }

  static int _compactInt(Object? raw) {
    if (raw is! num || !raw.isFinite) {
      throw const FormatException('compact integer is not numeric');
    }
    final value = raw.toInt();
    if (raw != value) {
      throw const FormatException('compact integer is not integral');
    }
    return value;
  }

  static T _enumAt<T>(List<T> values, Object? raw) {
    final index = _compactInt(raw);
    if (index < 0 || index >= values.length) {
      throw const FormatException('enum index out of range');
    }
    return values[index];
  }

  static GermanTeacherAssignmentResult? tryParse(String payload) {
    final envelope = SubjectResultEnvelope.tryParse(payload);
    if (envelope == null || envelope.subject != LearningSubject.german) {
      return null;
    }
    try {
      final data = envelope.data;
      final compact = data['k'] == 'r';
      if (!compact && data['kind'] != 'assignmentResult') return null;

      final breakdown = <GermanAssignmentCompetencyResult>[];
      final rawBreakdown = compact ? data['b'] : data['breakdown'];
      if (rawBreakdown != null) {
        if (rawBreakdown is! List<dynamic>) return null;
        for (final raw in rawBreakdown) {
          if (compact) {
            if (raw is! List<dynamic> || raw.length != 6) return null;
            breakdown.add(
              GermanAssignmentCompetencyResult(
                competencyId: _enumAt(_competencyCodes, raw[0]),
                completedTasks: _compactInt(raw[1]),
                correctFirstTry: _compactInt(raw[2]),
                independentCorrectFirstTry: _compactInt(raw[3]),
                readAloudAssistedTasks: _compactInt(raw[4]),
                incorrectAttempts: _compactInt(raw[5]),
              ),
            );
          } else {
            if (raw is! Map<String, dynamic>) return null;
            breakdown.add(GermanAssignmentCompetencyResult.fromJson(raw));
          }
        }
      }

      final correctFirstTry = compact
          ? _compactInt(data['c'])
          : (data['correctFirstTry'] as num).toInt();
      final result = GermanTeacherAssignmentResult(
        assignmentId: (compact ? data['a'] : data['assignmentId']) as String,
        gradeLevel: compact
            ? _enumAt(_gradeCodes, data['g'])
            : GradeLevel.values.byName(data['grade'] as String),
        domain: compact
            ? _enumAt(_domainCodes, data['d'])
            : GermanLearningDomain.values.byName(data['domain'] as String),
        requestedTasks: compact
            ? _compactInt(data['q'])
            : (data['requestedTasks'] as num).toInt(),
        completedTasks: compact
            ? _compactInt(data['n'])
            : (data['completedTasks'] as num).toInt(),
        correctFirstTry: correctFirstTry,
        independentCorrectFirstTry: compact
            ? _compactInt(data['s'])
            : (data['independentCorrectFirstTry'] as num?)?.toInt() ??
                  correctFirstTry,
        readAloudAssistedTasks: compact
            ? _compactInt(data['r'])
            : (data['readAloudAssistedTasks'] as num?)?.toInt() ?? 0,
        incorrectAttempts: compact
            ? _compactInt(data['i'])
            : (data['incorrectAttempts'] as num).toInt(),
        averageResponseMs:
            (compact ? data['m'] : data['averageResponseMs'] as num).toDouble(),
        targetCompetency: compact
            ? data['t'] == null
                  ? null
                  : _enumAt(_competencyCodes, data['t'])
            : data['target'] == null
            ? null
            : GermanCompetencyId.values.byName(data['target'] as String),
        competencyBreakdown:
            List<GermanAssignmentCompetencyResult>.unmodifiable(breakdown),
      );
      if (result.assignmentId.trim().isEmpty ||
          result.requestedTasks < 1 ||
          result.requestedTasks > 30 ||
          result.completedTasks < 0 ||
          result.completedTasks > result.requestedTasks ||
          result.correctFirstTry < 0 ||
          result.correctFirstTry > result.completedTasks ||
          result.independentCorrectFirstTry < 0 ||
          result.independentCorrectFirstTry > result.correctFirstTry ||
          result.independentCorrectFirstTry > result.independentTasks ||
          result.readAloudAssistedTasks < 0 ||
          result.readAloudAssistedTasks > result.completedTasks ||
          result.correctFirstTry - result.independentCorrectFirstTry >
              result.readAloudAssistedTasks ||
          result.incorrectAttempts < 0 ||
          result.averageResponseMs < 0) {
        return null;
      }
      final target = result.targetCompetency;
      if (target != null) {
        final definition = GermanCompetencyCatalog.definition(target);
        if (definition.domain != result.domain ||
            !definition.isRecommendedFor(result.gradeLevel)) {
          return null;
        }
      }

      if (result.competencyBreakdown.isNotEmpty) {
        final seen = <GermanCompetencyId>{};
        var completed = 0;
        var correct = 0;
        var independentCorrect = 0;
        var readAloudAssisted = 0;
        var incorrect = 0;
        for (final entry in result.competencyBreakdown) {
          if (!seen.add(entry.competencyId) ||
              entry.completedTasks < 1 ||
              entry.correctFirstTry < 0 ||
              entry.correctFirstTry > entry.completedTasks ||
              entry.independentCorrectFirstTry < 0 ||
              entry.independentCorrectFirstTry > entry.correctFirstTry ||
              entry.independentCorrectFirstTry > entry.independentTasks ||
              entry.readAloudAssistedTasks < 0 ||
              entry.readAloudAssistedTasks > entry.completedTasks ||
              entry.correctFirstTry - entry.independentCorrectFirstTry >
                  entry.readAloudAssistedTasks ||
              entry.incorrectAttempts < 0) {
            return null;
          }
          final definition = GermanCompetencyCatalog.definition(
            entry.competencyId,
          );
          if (definition.domain != result.domain ||
              !definition.isRecommendedFor(result.gradeLevel) ||
              (target != null && entry.competencyId != target)) {
            return null;
          }
          completed += entry.completedTasks;
          correct += entry.correctFirstTry;
          independentCorrect += entry.independentCorrectFirstTry;
          readAloudAssisted += entry.readAloudAssistedTasks;
          incorrect += entry.incorrectAttempts;
        }
        if (completed != result.completedTasks ||
            correct != result.correctFirstTry ||
            independentCorrect != result.independentCorrectFirstTry ||
            readAloudAssisted != result.readAloudAssistedTasks ||
            incorrect != result.incorrectAttempts) {
          return null;
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}
