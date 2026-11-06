import 'dart:io';

import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_cue_focus_windows/focus_controller.dart';
import 'package:random_cue_focus_windows/models.dart';
import 'package:random_cue_focus_windows/notification_adapter.dart';
import 'package:random_cue_focus_windows/repositories.dart';

void main() {
  late Directory directory;
  late SessionRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('focus-controller-');
    repository = SessionRepository(baseDirectory: directory);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  const settings = FocusSettings(
    focusDurationMinutes: 10,
    restDurationMinutes: 1,
    minPromptIntervalMinutes: 5,
    maxPromptIntervalMinutes: 5,
    microBreakSeconds: 5,
    adaptiveCadence: false,
  );

  test('responses and timeout are typed while focus keeps advancing', () async {
    final controller = _controller(settings, repository);
    await controller.startFocus();
    controller.advanceForTesting(300);
    expect(controller.phase, SessionPhase.microBreak);
    expect(controller.events.single.type, PromptResponseType.shown);

    controller.advanceForTesting(2);
    controller.recordOnTask();
    expect(controller.focusElapsed, 302);
    expect(controller.events.last.type, PromptResponseType.onTask);
    expect(controller.events.last.promptId, controller.events.first.promptId);
    expect(controller.events.last.responseLatencySeconds, 2);
    expect(controller.phase, SessionPhase.focusing);
    controller.dispose();

    final timedOut = _controller(settings, repository);
    await timedOut.startFocus();
    timedOut.advanceForTesting(305);
    expect(timedOut.events.map((event) => event.type), [
      PromptResponseType.shown,
      PromptResponseType.ended,
    ]);
    expect(timedOut.focusElapsed, 305);
    timedOut.dispose();
  });

  test('off-task, delay, and stop leave the goal-check phase', () async {
    final offTask = _controller(settings, repository);
    await offTask.startFocus();
    offTask.advanceForTesting(300);
    offTask.recordOffTask();
    expect(offTask.events.last.type, PromptResponseType.offTask);
    expect(offTask.phase, SessionPhase.focusing);
    offTask.dispose();

    final delayed = _controller(settings, repository);
    await delayed.startFocus();
    delayed.advanceForTesting(300);
    delayed.delayPrompt();
    expect(delayed.events.last.type, PromptResponseType.delayed);
    expect(delayed.phase, SessionPhase.focusing);
    await delayed.stop();
    expect(delayed.phase, SessionPhase.idle);
    delayed.dispose();
  });

  test('focus completion cannot remain in goal-check phase', () async {
    final controller = _controller(settings, repository);
    await controller.startFocus();
    controller.advanceForTesting(600);
    expect(controller.phase, SessionPhase.resting);
    expect(controller.phase, isNot(SessionPhase.microBreak));
    controller.dispose();
  });

  test(
    'completed session stores optional outcome and measurement context',
    () async {
      final controller = _controller(settings, repository);
      await controller.startFocus();
      controller.advanceForTesting(660);
      expect(controller.phase, SessionPhase.completed);

      await controller.recordMeaningfulProgress(
        MeaningfulProgressResponse.unsure,
      );
      await controller.recordInterruptionBurden(4);

      final saved = (await repository.loadSessions()).single;
      final measurement = saved.measurementContext;
      expect(measurement.platform, AppPlatform.windows);
      expect(saved.dataSchemaVersion, currentDataSchemaVersion);
      expect(measurement.goalChecksEnabled, isTrue);
      expect(measurement.minPromptIntervalSeconds, 300);
      expect(measurement.maxPromptIntervalSeconds, 300);
      expect(measurement.responseWindowSeconds, 5);
      expect(
        saved.outcomeReport!.meaningfulProgress,
        MeaningfulProgressResponse.unsure,
      );
      expect(saved.outcomeReport!.interruptionBurden, 4);
      controller.dispose();
    },
  );

  test('opt-in crossover persists assignment before any exposure', () async {
    final enrollment = createLocalFeasibilityEnrollment(
      participantCode: 'P-test',
      consentedAt: DateTime(2026, 8, 27),
      sequence: StudySequence.ab,
    );
    final controller = _controller(
      settings.copyWith(studyEnrollment: enrollment),
      repository,
    );

    await controller.startFocus();
    expect(
      controller.activeStudyAssignment!.condition,
      StudyCondition.noChecks,
    );
    expect(controller.promptPlan, isEmpty);
    expect(
      (await repository.loadSettings()).studyEnrollment!.nextSessionIndex,
      1,
    );
    controller.advanceForTesting(1);
    await controller.stop();

    final firstSession = (await repository.loadSessions()).single;
    expect(
      firstSession.measurementContext.studyAssignment!.condition,
      StudyCondition.noChecks,
    );
    expect(firstSession.measurementContext.goalChecksEnabled, isFalse);
    await controller.startFocus();
    expect(
      controller.activeStudyAssignment!.condition,
      StudyCondition.sparseChecks,
    );
    expect(controller.promptPlan, isNotEmpty);
    controller.dispose();
  });

  group('checks that cannot be seen', () {
    test('a check due during sleep is missed with no stale toast', () async {
      final adapter = _RecordingNotificationAdapter();
      final controller = FocusController(
        settings: settings,
        repository: repository,
        notificationAdapter: adapter,
      );
      await controller.startFocus();

      controller.tickAtForTesting(
        DateTime.now().add(const Duration(seconds: 400)),
      );

      expect(controller.events.map((event) => event.type), [
        PromptResponseType.missed,
      ]);
      expect(controller.events.single.plannedOffsetSeconds, 300);
      expect(controller.phase, SessionPhase.focusing);
      expect(controller.focusElapsed, inInclusiveRange(400, 401));
      expect(adapter.promptsShown, 0);
      controller.dispose();
    });

    test('a tick gap within tolerance is still live', () async {
      final adapter = _RecordingNotificationAdapter();
      final controller = FocusController(
        settings: settings,
        repository: repository,
        notificationAdapter: adapter,
      );
      await controller.startFocus();
      controller.advanceForTesting(298);

      controller.tickAtForTesting(
        DateTime.now().add(const Duration(seconds: maxLiveTickGapSeconds)),
      );

      expect(controller.events.single.type, PromptResponseType.shown);
      expect(controller.phase, SessionPhase.microBreak);
      expect(adapter.promptsShown, 1);
      controller.dispose();
    });

    test('a saved session with a missed check passes validation', () async {
      final controller = _controller(settings, repository);
      await controller.startFocus();
      controller.tickAtForTesting(
        DateTime.now().add(const Duration(seconds: 400)),
      );
      controller.advanceForTesting(660 - controller.focusElapsed);
      expect(controller.phase, SessionPhase.completed);
      await controller.recordMeaningfulProgress(MeaningfulProgressResponse.yes);

      final saved = (await repository.loadSessions()).single;
      expect(saved.promptEvents.map((event) => event.type), [
        PromptResponseType.missed,
      ]);
      final report = validateMeasurementData([
        saved,
      ], now: DateTime.now().add(const Duration(days: 1)));
      expect(report.issues, isEmpty);
      controller.dispose();
    });
  });

  group('answering from a toast', () {
    NotificationResponse button(String actionId, String promptId) {
      final arguments = goalCheckActionArguments(actionId, promptId);
      return NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        actionId: arguments,
        payload: arguments,
      );
    }

    test('the toast carries the prompt ID of the check on screen', () async {
      final adapter = _RecordingNotificationAdapter();
      final controller = FocusController(
        settings: settings,
        repository: repository,
        notificationAdapter: adapter,
      );
      await controller.startFocus();
      controller.advanceForTesting(300);

      expect(adapter.promptIds, [controller.events.single.promptId]);
      expect(
        adapter.promptIds.single,
        goalCheckPromptId(controller.activeSessionId!, 0),
      );
      controller.dispose();
    });

    test('a toast button answers the check on screen', () async {
      final adapter = _RecordingNotificationAdapter();
      final controller = FocusController(
        settings: settings,
        repository: repository,
        notificationAdapter: adapter,
      );
      await controller.startFocus();
      controller.advanceForTesting(302);

      adapter.handleResponse(
        button(goalCheckOnTaskActionId, adapter.promptIds.single),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.phase, SessionPhase.focusing);
      expect(controller.events.last.type, PromptResponseType.onTask);
      expect(controller.events.last.channel, PromptChannel.notification);
      expect(controller.events.last.responseLatencySeconds, 2);
      controller.dispose();
    });

    test('clicking the toast body is not an answer', () async {
      final adapter = _RecordingNotificationAdapter();
      final controller = FocusController(
        settings: settings,
        repository: repository,
        notificationAdapter: adapter,
      );
      await controller.startFocus();
      controller.advanceForTesting(302);

      adapter.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.phase, SessionPhase.microBreak);
      controller.dispose();
    });

    test('a check missed during sleep can be answered on waking', () async {
      var now = DateTime.now();
      final controller = _controller(settings, repository)..clock = () => now;
      await controller.startFocus();
      controller.advanceForTesting(0); // stop the real ticker
      final promptId = goalCheckPromptId(controller.activeSessionId!, 0);

      now = now.add(const Duration(seconds: 400));
      final recorded = controller.recordNotificationAnswer(
        GoalCheckAnswer(
          promptId: promptId,
          response: PromptResponseType.offTask,
        ),
      );

      expect(recorded, isTrue);
      expect(controller.events.map((event) => event.type), [
        PromptResponseType.missed,
        PromptResponseType.offTask,
      ]);
      expect(controller.events.last.responseLatencySeconds, 100);

      controller.advanceForTesting(660 - controller.focusElapsed);
      await controller.recordMeaningfulProgress(MeaningfulProgressResponse.yes);
      final saved = (await repository.loadSessions()).single;
      expect(saved.promptEvents.last.channel, PromptChannel.notification);
      final report = validateMeasurementData([
        saved,
      ], now: now.add(const Duration(days: 1)));
      expect(report.issues.map((issue) => issue.code), isEmpty);
      controller.dispose();
    });

    test('an answer after "ask later" is ignored', () async {
      final controller = _controller(settings, repository);
      await controller.startFocus();
      controller.advanceForTesting(300);
      final promptId = controller.events.single.promptId;
      controller.delayPrompt();

      expect(
        controller.recordNotificationAnswer(
          GoalCheckAnswer(
            promptId: promptId,
            response: PromptResponseType.onTask,
          ),
        ),
        isFalse,
      );
      controller.dispose();
    });
  });

  test('goal-check toast has two silent answer buttons', () {
    final details = goalCheckToastDetails('session:4');

    expect(details.audio?.isSilent, isTrue);
    expect(details.actions.map((action) => action.content), ['仍在目标', '刚刚走神']);
    expect(
      details.actions.map(
        (action) => parseGoalCheckAnswer(actionId: action.arguments),
      ),
      [
        const GoalCheckAnswer(
          promptId: 'session:4',
          response: PromptResponseType.onTask,
        ),
        const GoalCheckAnswer(
          promptId: 'session:4',
          response: PromptResponseType.offTask,
        ),
      ],
    );
  });
}

FocusController _controller(
  FocusSettings settings,
  SessionRepository repository,
) {
  return FocusController(
    settings: settings,
    repository: repository,
    notificationAdapter: _NoopNotificationAdapter(),
  );
}

class _NoopNotificationAdapter extends NotificationAdapter {
  @override
  Future<void> showPrompt({
    required FocusSettings settings,
    required String promptId,
  }) async {}

  @override
  Future<void> showSessionComplete() async {}
}

class _RecordingNotificationAdapter extends _NoopNotificationAdapter {
  var promptsShown = 0;
  final promptIds = <String>[];

  @override
  Future<void> showPrompt({
    required FocusSettings settings,
    required String promptId,
  }) async {
    promptsShown += 1;
    promptIds.add(promptId);
  }
}
