import 'dart:convert';

import 'models.dart';

Map<String, Object?> buildPrivacyPreservingResearchExport(
  List<FocusSession> sessions, {
  required String participantCode,
  DateTime? exportedAt,
}) {
  final normalizedCode = participantCode.trim();
  if (normalizedCode.isEmpty || normalizedCode.length > 80) {
    throw const FormatException(
      'Participant code must contain 1-80 characters.',
    );
  }
  final ordered = [...sessions]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final firstDay = ordered.isEmpty
      ? null
      : DateTime(
          ordered.first.startedAt.year,
          ordered.first.startedAt.month,
          ordered.first.startedAt.day,
        );

  return {
    'exportSchemaVersion': 2,
    'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'participantCode': normalizedCode,
    'privacy': {
      'rawSessionIdsIncluded': false,
      'calendarDatesIncluded': false,
      'freeTextIncluded': false,
    },
    'sessions': [
      for (var index = 0; index < ordered.length; index += 1)
        _exportSession(ordered[index], index, firstDay),
    ],
  };
}

String encodePrivacyPreservingResearchExport(
  List<FocusSession> sessions, {
  required String participantCode,
  DateTime? exportedAt,
}) {
  return jsonEncode(
    buildPrivacyPreservingResearchExport(
      sessions,
      participantCode: participantCode,
      exportedAt: exportedAt,
    ),
  );
}

Map<String, Object?> _exportSession(
  FocusSession session,
  int index,
  DateTime? firstDay,
) {
  final promptAliases = <String, String>{};
  var nextPromptAlias = 0;
  String aliasFor(PromptEvent event) {
    if (event.promptId.isEmpty) return '';
    return promptAliases.putIfAbsent(
      event.promptId,
      () => 'p${nextPromptAlias++}',
    );
  }

  final localDay = DateTime(
    session.startedAt.year,
    session.startedAt.month,
    session.startedAt.day,
  );
  return {
    'sessionIndex': index,
    'dayOffset': firstDay == null ? 0 : localDay.difference(firstDay).inDays,
    'localStartMinuteOfDay':
        session.startedAt.hour * 60 + session.startedAt.minute,
    'dataSchemaVersion': session.dataSchemaVersion,
    'plannedFocusSeconds': session.plannedFocusSeconds,
    'focusSeconds': session.focusSeconds,
    'restSeconds': session.restSeconds,
    'completed': session.completed,
    'goalPresent': session.goal.trim().isNotEmpty,
    'recoveryPlanPresent': session.ifThenPlan.trim().isNotEmpty,
    'learningPromptPresent': session.recallPrompt.trim().isNotEmpty,
    'measurementContext': _exportMeasurementContext(session),
    'outcome': session.outcomeReport?.toJson(),
    'promptEvents': [
      for (final event in session.promptEvents)
        {
          'promptId': aliasFor(event),
          'type': event.type.name,
          'elapsedSeconds': event.elapsedSeconds,
          'plannedOffsetSeconds': event.plannedOffsetSeconds,
          'responseLatencySeconds': event.responseLatencySeconds,
        },
    ],
  };
}

Map<String, Object?> _exportMeasurementContext(FocusSession session) {
  final context = session.measurementContext;
  final assignment = context.studyAssignment;
  final exported = Map<String, Object?>.from(context.toJson());
  exported['studyAssignment'] = assignment == null
      ? null
      : {
          'studyId': assignment.studyId,
          'protocolVersion': assignment.protocolVersion,
          'assignmentId': assignment.assignmentId,
          'sessionIndex': assignment.sessionIndex,
          'condition': assignment.condition.name,
          'assignmentLeadMilliseconds': session.startedAt
              .difference(assignment.assignedAt)
              .inMilliseconds,
        };
  return exported;
}
