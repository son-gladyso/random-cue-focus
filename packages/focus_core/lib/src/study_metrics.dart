import 'measurement.dart';
import 'models.dart';
import 'study_protocol.dart';

class StudyConditionMetrics {
  const StudyConditionMetrics({
    required this.condition,
    required this.assignedSessions,
    required this.completedSessions,
    required this.exposedSessions,
    required this.meaningfulProgressAnswers,
    required this.meaningfulProgressYes,
    required this.burdenAnswers,
    required this.highBurdenAnswers,
    required this.plannedChecks,
    required this.shownChecks,
    required this.answeredChecks,
    required this.skippedOrDelayedChecks,
  });

  final StudyCondition condition;
  final int assignedSessions;
  final int completedSessions;
  final int exposedSessions;
  final int meaningfulProgressAnswers;
  final int meaningfulProgressYes;
  final int burdenAnswers;
  final int highBurdenAnswers;
  final int plannedChecks;
  final int shownChecks;
  final int answeredChecks;
  final int skippedOrDelayedChecks;

  double? get completionRate => _ratio(completedSessions, assignedSessions);
  double? get exposureRate => _ratio(exposedSessions, assignedSessions);
  double? get meaningfulProgressResponseCoverage =>
      _ratio(meaningfulProgressAnswers, assignedSessions);
  double? get userValuedSessionRate =>
      _ratio(meaningfulProgressYes, meaningfulProgressAnswers);
  double? get burdenResponseCoverage => _ratio(burdenAnswers, assignedSessions);
  double? get highBurdenRate => _ratio(highBurdenAnswers, burdenAnswers);
  double? get checkResponseRate => _ratio(answeredChecks, shownChecks);

  Map<String, Object?> toJson() {
    return {
      'condition': condition.name,
      'assignedSessions': assignedSessions,
      'completedSessions': completedSessions,
      'exposedSessions': exposedSessions,
      'meaningfulProgressAnswers': meaningfulProgressAnswers,
      'meaningfulProgressYes': meaningfulProgressYes,
      'burdenAnswers': burdenAnswers,
      'highBurdenAnswers': highBurdenAnswers,
      'plannedChecks': plannedChecks,
      'shownChecks': shownChecks,
      'answeredChecks': answeredChecks,
      'skippedOrDelayedChecks': skippedOrDelayedChecks,
      'completionRate': completionRate,
      'exposureRate': exposureRate,
      'meaningfulProgressResponseCoverage': meaningfulProgressResponseCoverage,
      'userValuedSessionRate': userValuedSessionRate,
      'burdenResponseCoverage': burdenResponseCoverage,
      'highBurdenRate': highBurdenRate,
      'checkResponseRate': checkResponseRate,
    };
  }
}

class LocalStudyDataProfile {
  const LocalStudyDataProfile({
    required this.qualityReport,
    required this.unassignedSessions,
    required this.pairedBlocks,
    required this.noChecks,
    required this.sparseChecks,
    required this.schemaVersions,
    required this.appVersions,
    required this.algorithmVersions,
    required this.platforms,
    required this.protocolVersions,
  });

  final MeasurementQualityReport qualityReport;
  final int unassignedSessions;
  final int pairedBlocks;
  final StudyConditionMetrics noChecks;
  final StudyConditionMetrics sparseChecks;
  final List<int> schemaVersions;
  final List<String> appVersions;
  final List<String> algorithmVersions;
  final List<AppPlatform> platforms;
  final List<String> protocolVersions;

  int get assignedSessions =>
      noChecks.assignedSessions + sparseChecks.assignedSessions;

  bool get hasBothConditions =>
      noChecks.assignedSessions > 0 && sparseChecks.assignedSessions > 0;

  bool get isStructurallyReady =>
      qualityReport.isAnalysisReady && hasBothConditions;

  Map<String, Object?> toJson() {
    final issuesBySeverity = <String, int>{};
    for (final issue in qualityReport.issues) {
      issuesBySeverity.update(
        issue.severity.name,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return {
      'assignedSessions': assignedSessions,
      'unassignedSessions': unassignedSessions,
      'pairedBlocks': pairedBlocks,
      'hasBothConditions': hasBothConditions,
      'isStructurallyReady': isStructurallyReady,
      'qualityIssuesBySeverity': issuesBySeverity,
      'schemaVersions': schemaVersions,
      'appVersions': appVersions,
      'algorithmVersions': algorithmVersions,
      'platforms': platforms.map((value) => value.name).toList(),
      'protocolVersions': protocolVersions,
      'conditions': {
        StudyCondition.noChecks.name: noChecks.toJson(),
        StudyCondition.sparseChecks.name: sparseChecks.toJson(),
      },
    };
  }
}

LocalStudyDataProfile buildLocalStudyDataProfile(
  List<FocusSession> sessions, {
  DateTime? now,
}) {
  final qualityReport = validateMeasurementData(sessions, now: now);
  final assigned = sessions
      .where((session) => session.measurementContext.studyAssignment != null)
      .toList(growable: false);
  final blocks = <int, Set<StudyCondition>>{};
  for (final session in assigned) {
    final assignment = session.measurementContext.studyAssignment!;
    blocks
        .putIfAbsent(assignment.sessionIndex ~/ 2, () => <StudyCondition>{})
        .add(assignment.condition);
  }

  List<T> sorted<T extends Comparable<Object>>(Iterable<T> values) {
    final result = values.toSet().toList()..sort();
    return List.unmodifiable(result);
  }

  final platformValues =
      assigned
          .map((session) => session.measurementContext.platform)
          .toSet()
          .toList()
        ..sort((a, b) => a.index.compareTo(b.index));

  return LocalStudyDataProfile(
    qualityReport: qualityReport,
    unassignedSessions: sessions.length - assigned.length,
    pairedBlocks: blocks.values
        .where(
          (conditions) => conditions.length == StudyCondition.values.length,
        )
        .length,
    noChecks: _conditionMetrics(assigned, StudyCondition.noChecks),
    sparseChecks: _conditionMetrics(assigned, StudyCondition.sparseChecks),
    schemaVersions: sorted(
      assigned.map((session) => session.dataSchemaVersion),
    ),
    appVersions: sorted(
      assigned.map((session) => session.measurementContext.appVersion),
    ),
    algorithmVersions: sorted(
      assigned.map((session) => session.measurementContext.algorithmVersion),
    ),
    platforms: List.unmodifiable(platformValues),
    protocolVersions: sorted(
      assigned.map(
        (session) =>
            session.measurementContext.studyAssignment!.protocolVersion,
      ),
    ),
  );
}

StudyConditionMetrics _conditionMetrics(
  List<FocusSession> sessions,
  StudyCondition condition,
) {
  final eligible = sessions
      .where(
        (session) =>
            session.measurementContext.studyAssignment!.condition == condition,
      )
      .toList(growable: false);
  var completedSessions = 0;
  var exposedSessions = 0;
  var meaningfulProgressAnswers = 0;
  var meaningfulProgressYes = 0;
  var burdenAnswers = 0;
  var highBurdenAnswers = 0;
  var plannedChecks = 0;
  var shownChecks = 0;
  var answeredChecks = 0;
  var skippedOrDelayedChecks = 0;

  for (final session in eligible) {
    if (session.completed) completedSessions += 1;
    plannedChecks += session.measurementContext.plannedPromptOffsets.length;
    final shown = session.promptEvents
        .where((event) => event.type == PromptResponseType.shown)
        .length;
    shownChecks += shown;
    if (shown > 0) exposedSessions += 1;
    answeredChecks += session.promptEvents
        .where(
          (event) =>
              event.type == PromptResponseType.onTask ||
              event.type == PromptResponseType.offTask ||
              event.type == PromptResponseType.acknowledged,
        )
        .length;
    skippedOrDelayedChecks += session.promptEvents
        .where(
          (event) =>
              event.type == PromptResponseType.skipped ||
              event.type == PromptResponseType.delayed,
        )
        .length;

    final outcome = session.outcomeReport;
    if (outcome?.meaningfulProgress != null) {
      meaningfulProgressAnswers += 1;
      if (outcome!.meaningfulProgress == MeaningfulProgressResponse.yes) {
        meaningfulProgressYes += 1;
      }
    }
    if (outcome?.interruptionBurden != null) {
      burdenAnswers += 1;
      if (outcome!.interruptionBurden! >= 3) highBurdenAnswers += 1;
    }
  }

  return StudyConditionMetrics(
    condition: condition,
    assignedSessions: eligible.length,
    completedSessions: completedSessions,
    exposedSessions: exposedSessions,
    meaningfulProgressAnswers: meaningfulProgressAnswers,
    meaningfulProgressYes: meaningfulProgressYes,
    burdenAnswers: burdenAnswers,
    highBurdenAnswers: highBurdenAnswers,
    plannedChecks: plannedChecks,
    shownChecks: shownChecks,
    answeredChecks: answeredChecks,
    skippedOrDelayedChecks: skippedOrDelayedChecks,
  );
}

double? _ratio(int numerator, int denominator) {
  if (denominator <= 0) return null;
  return numerator / denominator;
}
