import 'package:focus_core/focus_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'profiles assignment, missing outcomes, burden, and exposure by arm',
    () {
      final started = DateTime.utc(2026, 8, 27, 8);
      final sessions = [
        _studySession(
          index: 0,
          condition: StudyCondition.noChecks,
          started: started,
          completed: false,
        ),
        _studySession(
          index: 1,
          condition: StudyCondition.sparseChecks,
          started: started.add(const Duration(days: 1)),
          completed: true,
          withCheck: true,
          outcome: SessionOutcomeReport(
            meaningfulProgress: MeaningfulProgressResponse.yes,
            interruptionBurden: 4,
            answeredAt: started.add(const Duration(days: 1, minutes: 21)),
          ),
        ),
        _studySession(
          index: 2,
          condition: StudyCondition.noChecks,
          started: started.add(const Duration(days: 2)),
          completed: true,
          outcome: SessionOutcomeReport(
            meaningfulProgress: MeaningfulProgressResponse.no,
            interruptionBurden: 0,
            answeredAt: started.add(const Duration(days: 2, minutes: 21)),
          ),
        ),
      ];

      final profile = buildLocalStudyDataProfile(
        sessions,
        now: DateTime.utc(2026, 8, 30),
      );

      expect(profile.qualityReport.isAnalysisReady, isTrue);
      expect(profile.hasBothConditions, isTrue);
      expect(profile.pairedBlocks, 1);
      expect(profile.noChecks.assignedSessions, 2);
      expect(profile.noChecks.completedSessions, 1);
      expect(profile.noChecks.meaningfulProgressResponseCoverage, 0.5);
      expect(profile.noChecks.userValuedSessionRate, 0);
      expect(profile.sparseChecks.assignedSessions, 1);
      expect(profile.sparseChecks.exposureRate, 1);
      expect(profile.sparseChecks.checkResponseRate, 1);
      expect(profile.sparseChecks.highBurdenRate, 1);
    },
  );

  test('keeps unavailable denominators null instead of manufacturing zero', () {
    final profile = buildLocalStudyDataProfile(const []);

    expect(profile.hasBothConditions, isFalse);
    expect(profile.isStructurallyReady, isFalse);
    expect(profile.noChecks.meaningfulProgressResponseCoverage, isNull);
    expect(profile.sparseChecks.checkResponseRate, isNull);
  });
}

FocusSession _studySession({
  required int index,
  required StudyCondition condition,
  required DateTime started,
  required bool completed,
  bool withCheck = false,
  SessionOutcomeReport? outcome,
}) {
  final plannedOffsets = withCheck ? const [600] : const <int>[];
  final events = withCheck
      ? [
          PromptEvent(
            promptId: 'prompt-$index',
            plannedOffsetSeconds: 600,
            elapsedSeconds: 600,
            occurredAt: started.add(const Duration(minutes: 10)),
            type: PromptResponseType.shown,
          ),
          PromptEvent(
            promptId: 'prompt-$index',
            responseLatencySeconds: 2,
            elapsedSeconds: 602,
            occurredAt: started.add(const Duration(minutes: 10, seconds: 2)),
            type: PromptResponseType.onTask,
          ),
        ]
      : const <PromptEvent>[];
  return FocusSession(
    id: 'session-$index',
    startedAt: started,
    endedAt: started.add(const Duration(minutes: 20)),
    plannedFocusSeconds: 1200,
    focusSeconds: completed ? 1200 : 600,
    restSeconds: 0,
    completed: completed,
    modeName: 'test',
    promptEvents: events,
    measurementContext: MeasurementContext(
      platform: AppPlatform.windows,
      appVersion: '0.2.0+2',
      plannedPromptOffsets: plannedOffsets,
      goalChecksEnabled: condition == StudyCondition.sparseChecks,
      minPromptIntervalSeconds: 600,
      maxPromptIntervalSeconds: 900,
      responseWindowSeconds: 20,
      studyAssignment: StudySessionAssignment(
        studyId: localFeasibilityStudyId,
        protocolVersion: localFeasibilityProtocolVersion,
        assignmentId: '$localFeasibilityStudyId:$index',
        sessionIndex: index,
        condition: condition,
        assignedAt: started.subtract(const Duration(milliseconds: 10)),
      ),
    ),
    outcomeReport: outcome,
  );
}
