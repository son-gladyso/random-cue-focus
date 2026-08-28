import 'models.dart';
import 'study_protocol.dart';

enum MeasurementIssueSeverity { critical, high, medium, low }

class MeasurementIssue {
  const MeasurementIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.sessionId,
  });

  final String code;
  final MeasurementIssueSeverity severity;
  final String message;
  final String? sessionId;
}

class MeasurementQualityReport {
  const MeasurementQualityReport({
    required this.sessionCount,
    required this.eventCount,
    required this.issues,
  });

  final int sessionCount;
  final int eventCount;
  final List<MeasurementIssue> issues;

  bool get isAnalysisReady => issues.every(
    (issue) =>
        issue.severity != MeasurementIssueSeverity.critical &&
        issue.severity != MeasurementIssueSeverity.high,
  );
}

MeasurementQualityReport validateMeasurementData(
  List<FocusSession> sessions, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final issues = <MeasurementIssue>[];
  final ids = <String>{};
  final assignmentIds = <String>{};
  final studySessionIndexes = <String>{};
  final assignmentsByStudy = <String, List<StudySessionAssignment>>{};
  var eventCount = 0;

  for (final session in sessions) {
    eventCount += session.promptEvents.length;
    if (session.id.trim().isEmpty || !ids.add(session.id)) {
      issues.add(
        MeasurementIssue(
          code: 'invalid_or_duplicate_session_id',
          severity: MeasurementIssueSeverity.critical,
          message: 'Session identifiers must be present and unique.',
          sessionId: session.id,
        ),
      );
    }
    if (session.endedAt.isBefore(session.startedAt)) {
      issues.add(
        MeasurementIssue(
          code: 'session_time_reversed',
          severity: MeasurementIssueSeverity.critical,
          message: 'Session end precedes session start.',
          sessionId: session.id,
        ),
      );
    }
    if (session.startedAt.isAfter(clock.add(const Duration(minutes: 5)))) {
      issues.add(
        MeasurementIssue(
          code: 'future_session',
          severity: MeasurementIssueSeverity.high,
          message: 'Session starts more than five minutes in the future.',
          sessionId: session.id,
        ),
      );
    }
    if (session.plannedFocusSeconds <= 0 ||
        session.focusSeconds < 0 ||
        session.focusSeconds > session.plannedFocusSeconds) {
      issues.add(
        MeasurementIssue(
          code: 'invalid_focus_duration',
          severity: MeasurementIssueSeverity.high,
          message: 'Focus duration is outside the planned session bounds.',
          sessionId: session.id,
        ),
      );
    }
    final plannedOffsets = session.measurementContext.plannedPromptOffsets;
    if (plannedOffsets.toSet().length != plannedOffsets.length ||
        plannedOffsets.any(
          (offset) => offset <= 0 || offset >= session.plannedFocusSeconds,
        )) {
      issues.add(
        MeasurementIssue(
          code: 'invalid_planned_prompt_offsets',
          severity: MeasurementIssueSeverity.high,
          message:
              'Planned prompt offsets must be unique and inside the session.',
          sessionId: session.id,
        ),
      );
    }
    final assignment = session.measurementContext.studyAssignment;
    if (assignment != null) {
      assignmentsByStudy
          .putIfAbsent(assignment.studyId, () => <StudySessionAssignment>[])
          .add(assignment);
      final studyIndexKey = '${assignment.studyId}:${assignment.sessionIndex}';
      if (!assignmentIds.add(assignment.assignmentId) ||
          !studySessionIndexes.add(studyIndexKey)) {
        issues.add(
          MeasurementIssue(
            code: 'duplicate_study_assignment',
            severity: MeasurementIssueSeverity.critical,
            message:
                'Study assignments must be unique within a participant export.',
            sessionId: session.id,
          ),
        );
      }
      if (assignment.assignedAt.isAfter(session.startedAt)) {
        issues.add(
          MeasurementIssue(
            code: 'assignment_after_session_start',
            severity: MeasurementIssueSeverity.critical,
            message:
                'Study assignment must be persisted before session exposure.',
            sessionId: session.id,
          ),
        );
      }
      if (assignment.sessionIndex < 0) {
        issues.add(
          MeasurementIssue(
            code: 'negative_study_session_index',
            severity: MeasurementIssueSeverity.critical,
            message: 'Study session indexes cannot be negative.',
            sessionId: session.id,
          ),
        );
      }
      if (session.dataSchemaVersion < 5) {
        issues.add(
          MeasurementIssue(
            code: 'study_assignment_in_legacy_schema',
            severity: MeasurementIssueSeverity.high,
            message:
                'Study assignment requires measurement schema v5 or later.',
            sessionId: session.id,
          ),
        );
      }
      final context = session.measurementContext;
      if (session.dataSchemaVersion >= 6 &&
          (context.goalChecksEnabled == null ||
              context.minPromptIntervalSeconds == null ||
              context.maxPromptIntervalSeconds == null ||
              context.responseWindowSeconds == null)) {
        issues.add(
          MeasurementIssue(
            code: 'missing_prompt_settings_snapshot',
            severity: MeasurementIssueSeverity.high,
            message:
                'Schema v6 study sessions require the prompt settings snapshot.',
            sessionId: session.id,
          ),
        );
      }
      if (context.minPromptIntervalSeconds != null &&
          context.maxPromptIntervalSeconds != null &&
          context.minPromptIntervalSeconds! >
              context.maxPromptIntervalSeconds!) {
        issues.add(
          MeasurementIssue(
            code: 'invalid_prompt_interval_snapshot',
            severity: MeasurementIssueSeverity.high,
            message: 'Minimum prompt interval exceeds the maximum interval.',
            sessionId: session.id,
          ),
        );
      }
      if (assignment.condition == StudyCondition.noChecks &&
          context.goalChecksEnabled == true) {
        issues.add(
          MeasurementIssue(
            code: 'control_condition_checks_enabled',
            severity: MeasurementIssueSeverity.critical,
            message:
                'No-check control session has checks enabled in its snapshot.',
            sessionId: session.id,
          ),
        );
      }
      final shownCount = session.promptEvents
          .where((event) => event.type == PromptResponseType.shown)
          .length;
      if (assignment.condition == StudyCondition.noChecks &&
          (plannedOffsets.isNotEmpty || shownCount > 0)) {
        issues.add(
          MeasurementIssue(
            code: 'control_condition_exposed_to_checks',
            severity: MeasurementIssueSeverity.critical,
            message:
                'No-check control session contains planned or shown checks.',
            sessionId: session.id,
          ),
        );
      }
    }

    final eventsByPrompt = <String, List<PromptEvent>>{};
    final shownOffsets = <int>{};
    PromptEvent? previousEvent;
    for (final event in session.promptEvents) {
      if (previousEvent != null &&
          (event.elapsedSeconds < previousEvent.elapsedSeconds ||
              event.occurredAt.isBefore(previousEvent.occurredAt))) {
        issues.add(
          MeasurementIssue(
            code: 'prompt_event_order_reversed',
            severity: MeasurementIssueSeverity.high,
            message: 'Prompt events are not stored in chronological order.',
            sessionId: session.id,
          ),
        );
      }
      previousEvent = event;
      if (event.elapsedSeconds < 0 ||
          event.elapsedSeconds > session.plannedFocusSeconds) {
        issues.add(
          MeasurementIssue(
            code: 'event_outside_session_bounds',
            severity: MeasurementIssueSeverity.high,
            message: 'Prompt event elapsed time is outside session bounds.',
            sessionId: session.id,
          ),
        );
      }
      if (event.occurredAt.isBefore(
            session.startedAt.subtract(const Duration(minutes: 5)),
          ) ||
          event.occurredAt.isAfter(
            session.endedAt.add(const Duration(minutes: 5)),
          )) {
        issues.add(
          MeasurementIssue(
            code: 'event_wall_time_outside_session',
            severity: MeasurementIssueSeverity.high,
            message: 'Prompt event wall time is outside the session window.',
            sessionId: session.id,
          ),
        );
      }
      if (event.type == PromptResponseType.shown &&
          event.plannedOffsetSeconds != null &&
          plannedOffsets.isNotEmpty &&
          !plannedOffsets.contains(event.plannedOffsetSeconds)) {
        issues.add(
          MeasurementIssue(
            code: 'exposure_not_in_prompt_plan',
            severity: MeasurementIssueSeverity.high,
            message: 'Shown prompt does not match the stored session plan.',
            sessionId: session.id,
          ),
        );
      }
      if (event.type == PromptResponseType.shown) {
        final offset = event.plannedOffsetSeconds;
        if (session.dataSchemaVersion >= 4 &&
            plannedOffsets.isNotEmpty &&
            offset == null) {
          issues.add(
            MeasurementIssue(
              code: 'shown_prompt_missing_planned_offset',
              severity: MeasurementIssueSeverity.medium,
              message: 'Shown prompt is missing its planned offset.',
              sessionId: session.id,
            ),
          );
        } else if (offset != null && !shownOffsets.add(offset)) {
          issues.add(
            MeasurementIssue(
              code: 'duplicate_prompt_exposure_offset',
              severity: MeasurementIssueSeverity.high,
              message:
                  'More than one prompt was shown for the same plan offset.',
              sessionId: session.id,
            ),
          );
        }
      }
      if (event.promptId.isNotEmpty) {
        eventsByPrompt.putIfAbsent(event.promptId, () => []).add(event);
      } else if (session.dataSchemaVersion >= 4) {
        issues.add(
          MeasurementIssue(
            code: 'missing_prompt_id',
            severity: MeasurementIssueSeverity.medium,
            message: 'Schema v4 prompt event is missing its correlation id.',
            sessionId: session.id,
          ),
        );
      }
    }

    if (session.completed) {
      final missingOffsets = plannedOffsets
          .where((offset) => !shownOffsets.contains(offset))
          .length;
      if (missingOffsets > 0) {
        issues.add(
          MeasurementIssue(
            code: 'completed_session_missing_planned_exposure',
            severity: MeasurementIssueSeverity.medium,
            message:
                'Completed session did not show every stored planned prompt.',
            sessionId: session.id,
          ),
        );
      }
    }

    for (final entry in eventsByPrompt.entries) {
      final shown = entry.value
          .where((event) => event.type == PromptResponseType.shown)
          .toList(growable: false);
      final responses = entry.value
          .where(
            (event) =>
                event.type != PromptResponseType.shown &&
                event.type != PromptResponseType.ended,
          )
          .toList(growable: false);
      if (shown.length != 1) {
        issues.add(
          MeasurementIssue(
            code: 'invalid_prompt_exposure_count',
            severity: MeasurementIssueSeverity.high,
            message:
                'Each correlated prompt must have exactly one shown event.',
            sessionId: session.id,
          ),
        );
      }
      if (responses.length > 1) {
        issues.add(
          MeasurementIssue(
            code: 'duplicate_prompt_response',
            severity: MeasurementIssueSeverity.high,
            message: 'A prompt has more than one explicit response.',
            sessionId: session.id,
          ),
        );
      }
      if (shown.isNotEmpty && responses.isNotEmpty) {
        final response = responses.first;
        if (response.occurredAt.isBefore(shown.single.occurredAt) ||
            (response.responseLatencySeconds != null &&
                response.responseLatencySeconds! < 0)) {
          issues.add(
            MeasurementIssue(
              code: 'response_before_exposure',
              severity: MeasurementIssueSeverity.high,
              message: 'Prompt response precedes its recorded exposure.',
              sessionId: session.id,
            ),
          );
        }
        final expectedLatency =
            response.elapsedSeconds - shown.single.elapsedSeconds;
        if (response.responseLatencySeconds != null &&
            response.responseLatencySeconds != expectedLatency) {
          issues.add(
            MeasurementIssue(
              code: 'inconsistent_response_latency',
              severity: MeasurementIssueSeverity.medium,
              message: 'Stored response latency disagrees with elapsed time.',
              sessionId: session.id,
            ),
          );
        }
      }
    }

    final outcome = session.outcomeReport;
    if (outcome != null && !outcome.hasAnyAnswer) {
      issues.add(
        MeasurementIssue(
          code: 'empty_outcome_report',
          severity: MeasurementIssueSeverity.low,
          message: 'Outcome report exists without an explicit answer.',
          sessionId: session.id,
        ),
      );
    }
    if (outcome?.hasAnyAnswer == true && outcome?.answeredAt == null) {
      issues.add(
        MeasurementIssue(
          code: 'outcome_answer_missing_timestamp',
          severity: MeasurementIssueSeverity.medium,
          message: 'Answered outcome report is missing its response timestamp.',
          sessionId: session.id,
        ),
      );
    }
    if (outcome?.answeredAt != null &&
        outcome!.answeredAt!.isBefore(session.endedAt)) {
      issues.add(
        MeasurementIssue(
          code: 'outcome_answer_before_session_end',
          severity: MeasurementIssueSeverity.high,
          message:
              'Post-session outcome was answered before the session ended.',
          sessionId: session.id,
        ),
      );
    }
    if (outcome?.answeredAt != null &&
        outcome!.answeredAt!.isAfter(clock.add(const Duration(minutes: 5)))) {
      issues.add(
        MeasurementIssue(
          code: 'future_outcome_answer',
          severity: MeasurementIssueSeverity.high,
          message: 'Outcome response is more than five minutes in the future.',
          sessionId: session.id,
        ),
      );
    }
    if (outcome != null &&
        outcome.interruptionBurden != null &&
        (outcome.interruptionBurden! < 0 || outcome.interruptionBurden! > 4)) {
      issues.add(
        MeasurementIssue(
          code: 'invalid_burden_rating',
          severity: MeasurementIssueSeverity.high,
          message: 'Interruption burden must be between 0 and 4.',
          sessionId: session.id,
        ),
      );
    }
  }

  for (final assignments in assignmentsByStudy.values) {
    assignments.sort((a, b) => a.sessionIndex.compareTo(b.sessionIndex));
    for (var index = 1; index < assignments.length; index += 1) {
      final previous = assignments[index - 1];
      final current = assignments[index];
      if (current.sessionIndex == previous.sessionIndex + 1 &&
          current.condition == previous.condition) {
        issues.add(
          const MeasurementIssue(
            code: 'study_condition_failed_to_alternate',
            severity: MeasurementIssueSeverity.critical,
            message: 'Consecutive study assignments must alternate conditions.',
          ),
        );
      }
      if (current.sessionIndex > previous.sessionIndex + 1) {
        issues.add(
          const MeasurementIssue(
            code: 'study_assignment_index_gap',
            severity: MeasurementIssueSeverity.medium,
            message:
                'Study assignment indexes contain a gap; reconcile deletions or partial exports.',
          ),
        );
      }
    }
  }

  return MeasurementQualityReport(
    sessionCount: sessions.length,
    eventCount: eventCount,
    issues: List.unmodifiable(issues),
  );
}
