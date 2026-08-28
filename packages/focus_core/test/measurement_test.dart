import 'package:focus_core/focus_core.dart';
import 'package:test/test.dart';

void main() {
  test('valid correlated prompt data is analysis ready', () {
    final started = DateTime.utc(2026, 8, 27, 8);
    final report = validateMeasurementData([
      _session(
        id: 'session-1',
        started: started,
        events: [
          PromptEvent(
            promptId: 'p1',
            plannedOffsetSeconds: 600,
            elapsedSeconds: 600,
            occurredAt: started.add(const Duration(minutes: 10)),
            type: PromptResponseType.shown,
          ),
          PromptEvent(
            promptId: 'p1',
            responseLatencySeconds: 4,
            elapsedSeconds: 604,
            occurredAt: started.add(const Duration(minutes: 10, seconds: 4)),
            type: PromptResponseType.onTask,
          ),
        ],
      ),
    ], now: DateTime.utc(2026, 8, 28));

    expect(report.isAnalysisReady, isTrue);
    expect(report.issues, isEmpty);
  });

  test('duplicate sessions and responses are rejected', () {
    final started = DateTime.utc(2026, 8, 27, 8);
    final events = [
      PromptEvent(
        promptId: 'p1',
        elapsedSeconds: 600,
        occurredAt: started.add(const Duration(minutes: 10)),
        type: PromptResponseType.shown,
      ),
      PromptEvent(
        promptId: 'p1',
        elapsedSeconds: 601,
        occurredAt: started.add(const Duration(minutes: 10, seconds: 1)),
        type: PromptResponseType.onTask,
      ),
      PromptEvent(
        promptId: 'p1',
        elapsedSeconds: 602,
        occurredAt: started.add(const Duration(minutes: 10, seconds: 2)),
        type: PromptResponseType.skipped,
      ),
    ];
    final report = validateMeasurementData([
      _session(id: 'same', started: started, events: events),
      _session(id: 'same', started: started, events: const []),
    ], now: DateTime.utc(2026, 8, 28));

    expect(report.isAnalysisReady, isFalse);
    expect(
      report.issues.map((issue) => issue.code),
      containsAll([
        'duplicate_prompt_response',
        'invalid_or_duplicate_session_id',
      ]),
    );
  });

  test('plan/exposure drift and inconsistent latency are visible', () {
    final started = DateTime.utc(2026, 8, 27, 8);
    final report = validateMeasurementData([
      FocusSession(
        id: 'drift',
        startedAt: started,
        endedAt: started.add(const Duration(minutes: 20)),
        plannedFocusSeconds: 1200,
        focusSeconds: 1200,
        restSeconds: 0,
        completed: true,
        modeName: 'test',
        measurementContext: const MeasurementContext(
          plannedPromptOffsets: [300, 300],
        ),
        promptEvents: [
          PromptEvent(
            promptId: 'p1',
            plannedOffsetSeconds: 600,
            elapsedSeconds: 600,
            occurredAt: started.add(const Duration(minutes: 10)),
            type: PromptResponseType.shown,
          ),
          PromptEvent(
            promptId: 'p1',
            responseLatencySeconds: 1,
            elapsedSeconds: 604,
            occurredAt: started.add(const Duration(minutes: 10, seconds: 4)),
            type: PromptResponseType.onTask,
          ),
        ],
      ),
    ], now: DateTime.utc(2026, 8, 28));

    expect(
      report.issues.map((issue) => issue.code),
      containsAll([
        'invalid_planned_prompt_offsets',
        'exposure_not_in_prompt_plan',
        'inconsistent_response_latency',
      ]),
    );
  });

  test('experiment assignment must precede start and match exposure', () {
    final started = DateTime.utc(2026, 8, 27, 8);
    final assignment = StudySessionAssignment(
      studyId: localFeasibilityStudyId,
      protocolVersion: localFeasibilityProtocolVersion,
      assignmentId: 'assignment-0',
      sessionIndex: 0,
      condition: StudyCondition.noChecks,
      assignedAt: started.add(const Duration(seconds: 1)),
    );
    final session = FocusSession(
      id: 'study-session',
      startedAt: started,
      endedAt: started.add(const Duration(minutes: 20)),
      plannedFocusSeconds: 1200,
      focusSeconds: 1200,
      restSeconds: 0,
      completed: true,
      modeName: 'test',
      measurementContext: MeasurementContext(
        plannedPromptOffsets: const [600],
        studyAssignment: assignment,
      ),
      promptEvents: [
        PromptEvent(
          promptId: 'p1',
          plannedOffsetSeconds: 600,
          elapsedSeconds: 600,
          occurredAt: started.add(const Duration(minutes: 10)),
          type: PromptResponseType.shown,
        ),
      ],
    );

    final report = validateMeasurementData([
      session,
    ], now: DateTime.utc(2026, 8, 28));

    expect(
      report.issues.map((issue) => issue.code),
      containsAll([
        'assignment_after_session_start',
        'control_condition_exposed_to_checks',
      ]),
    );
    expect(report.isAnalysisReady, isFalse);
  });

  test(
    'study data exposes missing snapshots, timing, order, and alternation',
    () {
      final started = DateTime.utc(2026, 8, 27, 8);
      StudySessionAssignment assignment(int index, StudyCondition condition) {
        return StudySessionAssignment(
          studyId: localFeasibilityStudyId,
          protocolVersion: localFeasibilityProtocolVersion,
          assignmentId: '$localFeasibilityStudyId:$index',
          sessionIndex: index,
          condition: condition,
          assignedAt: started.subtract(const Duration(milliseconds: 10)),
        );
      }

      FocusSession studySession(
        int index,
        StudyCondition condition, {
        bool settingsSnapshot = true,
        List<PromptEvent> events = const [],
        SessionOutcomeReport? outcome,
      }) {
        return FocusSession(
          id: 'study-$index',
          startedAt: started,
          endedAt: started.add(const Duration(minutes: 20)),
          plannedFocusSeconds: 1200,
          focusSeconds: 1200,
          restSeconds: 0,
          completed: true,
          modeName: 'test',
          promptEvents: events,
          measurementContext: MeasurementContext(
            plannedPromptOffsets: condition == StudyCondition.sparseChecks
                ? const [600]
                : const [],
            goalChecksEnabled: settingsSnapshot
                ? condition == StudyCondition.sparseChecks
                : null,
            minPromptIntervalSeconds: settingsSnapshot ? 600 : null,
            maxPromptIntervalSeconds: settingsSnapshot ? 900 : null,
            responseWindowSeconds: settingsSnapshot ? 20 : null,
            studyAssignment: assignment(index, condition),
          ),
          outcomeReport: outcome,
        );
      }

      final report = validateMeasurementData([
        studySession(
          0,
          StudyCondition.noChecks,
          outcome: SessionOutcomeReport(
            meaningfulProgress: MeaningfulProgressResponse.yes,
            answeredAt: started.add(const Duration(minutes: 19)),
          ),
        ),
        studySession(1, StudyCondition.noChecks),
        studySession(
          2,
          StudyCondition.sparseChecks,
          settingsSnapshot: false,
          events: [
            PromptEvent(
              promptId: 'p2',
              responseLatencySeconds: 1,
              elapsedSeconds: 601,
              occurredAt: started.add(const Duration(minutes: 10, seconds: 1)),
              type: PromptResponseType.onTask,
            ),
            PromptEvent(
              promptId: 'p2',
              plannedOffsetSeconds: 600,
              elapsedSeconds: 600,
              occurredAt: started.add(const Duration(minutes: 10)),
              type: PromptResponseType.shown,
            ),
          ],
        ),
      ], now: DateTime.utc(2026, 8, 28));

      expect(
        report.issues.map((issue) => issue.code),
        containsAll([
          'outcome_answer_before_session_end',
          'study_condition_failed_to_alternate',
          'missing_prompt_settings_snapshot',
          'prompt_event_order_reversed',
        ]),
      );
      expect(report.isAnalysisReady, isFalse);
    },
  );
}

FocusSession _session({
  required String id,
  required DateTime started,
  required List<PromptEvent> events,
}) {
  return FocusSession(
    id: id,
    startedAt: started,
    endedAt: started.add(const Duration(minutes: 20)),
    plannedFocusSeconds: 1200,
    focusSeconds: 1200,
    restSeconds: 0,
    completed: true,
    modeName: 'test',
    promptEvents: events,
  );
}
