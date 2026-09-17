import 'german_competency.dart';
import 'german_competency_catalog.dart';
import 'german_progress.dart';
import 'german_session.dart';

class GermanCompetencyUnlockStatus {
  const GermanCompetencyUnlockStatus({
    required this.definition,
    required this.prerequisites,
    required this.unmetPrerequisites,
    required this.nextRequired,
    required this.reason,
    this.confirmedByOwnEvidence = false,
  });

  final GermanCompetencyDefinition definition;
  final List<GermanCompetencyDefinition> prerequisites;
  final List<GermanCompetencyDefinition> unmetPrerequisites;
  final GermanCompetencyDefinition? nextRequired;
  final String reason;
  final bool confirmedByOwnEvidence;

  bool get isUnlocked => unmetPrerequisites.isEmpty;
  bool get hasPrerequisites => prerequisites.isNotEmpty;
}

class GermanPrerequisiteResolver {
  const GermanPrerequisiteResolver._();

  static GermanCompetencyUnlockStatus status(
    GermanCompetencyId id,
    Iterable<GermanSessionResult> history,
  ) {
    final definition = GermanCompetencyCatalog.definition(id);
    final prerequisites = definition.prerequisites
        .map(GermanCompetencyCatalog.definition)
        .toList(growable: false);
    final ownProgress = GermanProgressAnalyzer.forCompetency(id, history);
    final confirmedByOwnEvidence =
        prerequisites.isNotEmpty &&
        ownProgress.state == GermanCompetencyState.secure;
    if (confirmedByOwnEvidence) {
      return GermanCompetencyUnlockStatus(
        definition: definition,
        prerequisites: prerequisites,
        unmetPrerequisites: const <GermanCompetencyDefinition>[],
        nextRequired: null,
        confirmedByOwnEvidence: true,
        reason:
            'Dieser Lernschritt wurde bereits mit verschiedenen Aufgaben sicher gezeigt.',
      );
    }

    final unmet = definition.prerequisites
        .where(
          (prerequisite) => !_competencyAndPrerequisitesReady(
            prerequisite,
            history,
            <GermanCompetencyId>{},
          ),
        )
        .map(GermanCompetencyCatalog.definition)
        .toList(growable: false);
    final nextId = _nextUnmetPrerequisite(id, history, <GermanCompetencyId>{});
    final next = nextId == null
        ? null
        : GermanCompetencyCatalog.definition(nextId);

    final reason = prerequisites.isEmpty
        ? 'Dieser Lernschritt hat keine vorgelagerte Pflicht-Grundlage.'
        : unmet.isEmpty
        ? 'Die benötigten Grundlagen sind sicher.'
        : next == null
        ? 'Zuerst müssen die benötigten Grundlagen sicher werden.'
        : 'Als Nächstes hilft zuerst „${next.label}“.';

    return GermanCompetencyUnlockStatus(
      definition: definition,
      prerequisites: prerequisites,
      unmetPrerequisites: unmet,
      nextRequired: next,
      reason: reason,
    );
  }

  static bool _competencyAndPrerequisitesReady(
    GermanCompetencyId id,
    Iterable<GermanSessionResult> history,
    Set<GermanCompetencyId> visiting,
  ) {
    if (!visiting.add(id)) return false;
    final progress = GermanProgressAnalyzer.forCompetency(id, history);
    if (progress.state != GermanCompetencyState.secure) {
      visiting.remove(id);
      return false;
    }
    final definition = GermanCompetencyCatalog.definition(id);
    for (final prerequisite in definition.prerequisites) {
      if (!_competencyAndPrerequisitesReady(prerequisite, history, visiting)) {
        visiting.remove(id);
        return false;
      }
    }
    visiting.remove(id);
    return true;
  }

  static GermanCompetencyId? _nextUnmetPrerequisite(
    GermanCompetencyId id,
    Iterable<GermanSessionResult> history,
    Set<GermanCompetencyId> visiting,
  ) {
    if (!visiting.add(id)) return null;
    final definition = GermanCompetencyCatalog.definition(id);
    for (final prerequisite in definition.prerequisites) {
      if (_competencyAndPrerequisitesReady(
        prerequisite,
        history,
        <GermanCompetencyId>{},
      )) {
        continue;
      }
      final deeper = _nextUnmetPrerequisite(prerequisite, history, visiting);
      visiting.remove(id);
      return deeper ?? prerequisite;
    }
    visiting.remove(id);
    return null;
  }
}
