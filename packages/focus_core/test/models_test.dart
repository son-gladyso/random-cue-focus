import 'package:focus_core/focus_core.dart';
import 'package:test/test.dart';

void main() {
  group('FocusSettings', () {
    test('uses interruption-minimizing defaults', () {
      const settings = FocusSettings();

      expect(settings.notificationsEnabled, isFalse);
      expect(settings.foregroundPromptSoundEnabled, isFalse);
      expect(settings.goalChecksEnabled, isTrue);
      expect(settings.minPromptIntervalMinutes, greaterThanOrEqualTo(10));
      expect(settings.maxPromptIntervalMinutes, greaterThanOrEqualTo(15));
    });

    test('migrates both legacy platform notification keys', () {
      final ios = FocusSettings.fromJson(const {
        'lockScreenNotifications': true,
      });
      final windows = FocusSettings.fromJson(const {
        'desktopNotifications': true,
      });

      expect(ios.notificationsEnabled, isTrue);
      expect(windows.notificationsEnabled, isTrue);
      expect(ios.goalChecksEnabled, isTrue);
    });

    test('round trips planning fields', () {
      const original = FocusSettings(
        sessionGoal: 'Draft the methods section',
        distractionTrigger: 'I open a social feed',
        recoveryAction: 'close it and write one sentence',
        learningMode: true,
        goalChecksEnabled: false,
        recallPrompt: 'Explain the core mechanism without notes',
      );

      final decoded = FocusSettings.decode(original.encode());

      expect(decoded.sessionGoal, original.sessionGoal);
      expect(decoded.ifThenPlan, contains('那么'));
      expect(decoded.learningMode, isTrue);
      expect(decoded.goalChecksEnabled, isFalse);
      expect(decoded.recallPrompt, original.recallPrompt);
    });

    test('normalizes goal text to the documented maximum length', () {
      final normalized = FocusSettings(
        sessionGoal: '  ${List.filled(200, '目').join()}  ',
      ).normalized();

      expect(normalized.sessionGoal.length, 160);
      expect(normalized.sessionGoal.startsWith(' '), isFalse);
      expect(normalized.sessionGoal.endsWith(' '), isFalse);
    });
  });

  test('schema v6 measurement and study fields round-trip and normalize', () {
    final started = DateTime.utc(2026, 8, 27, 8);
    final session = FocusSession(
      id: 's1',
      startedAt: started,
      endedAt: started.add(const Duration(minutes: 20)),
      plannedFocusSeconds: 1200,
      focusSeconds: 1200,
      restSeconds: 0,
      completed: true,
      modeName: 'test',
      promptEvents: [
        PromptEvent(
          promptId: 'p1',
          plannedOffsetSeconds: 600,
          responseLatencySeconds: 3,
          elapsedSeconds: 603,
          occurredAt: started.add(const Duration(seconds: 603)),
          type: PromptResponseType.onTask,
        ),
      ],
      measurementContext: MeasurementContext(
        platform: AppPlatform.windows,
        plannedPromptOffsets: [600],
        cadenceFactor: 9,
        cadenceReason: 'test',
        goalChecksEnabled: true,
        minPromptIntervalSeconds: 600,
        maxPromptIntervalSeconds: 1200,
        responseWindowSeconds: 20,
        studyAssignment: StudySessionAssignment(
          studyId: localFeasibilityStudyId,
          protocolVersion: localFeasibilityProtocolVersion,
          assignmentId: 'a1',
          sessionIndex: 0,
          condition: StudyCondition.sparseChecks,
          assignedAt: DateTime(2026, 8, 27, 7, 59),
        ),
      ),
      outcomeReport: SessionOutcomeReport(
        meaningfulProgress: MeaningfulProgressResponse.yes,
        interruptionBurden: 9,
        answeredAt: started.add(const Duration(minutes: 21)),
      ),
    );

    final decoded = FocusSession.decode(session.encode());

    expect(decoded.dataSchemaVersion, currentDataSchemaVersion);
    expect(decoded.measurementContext.platform, AppPlatform.windows);
    expect(decoded.measurementContext.cadenceFactor, 1.25);
    expect(decoded.measurementContext.goalChecksEnabled, isTrue);
    expect(decoded.measurementContext.minPromptIntervalSeconds, 600);
    expect(decoded.measurementContext.maxPromptIntervalSeconds, 1200);
    expect(decoded.measurementContext.responseWindowSeconds, 20);
    expect(
      decoded.measurementContext.studyAssignment!.condition,
      StudyCondition.sparseChecks,
    );
    expect(decoded.promptEvents.single.promptId, 'p1');
    expect(
      decoded.outcomeReport!.meaningfulProgress,
      MeaningfulProgressResponse.yes,
    );
    expect(decoded.outcomeReport!.interruptionBurden, 4);
  });

  test('legacy iOS microbreak strings migrate to typed events', () {
    final event = PromptEvent.fromJson({
      'elapsedSeconds': 30,
      'occurredAt': DateTime(2026).toIso8601String(),
      'event': 'microbreak_end',
    });

    expect(event.type, PromptResponseType.ended);
  });
}
