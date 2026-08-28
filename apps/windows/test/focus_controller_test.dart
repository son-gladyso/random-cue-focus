import 'dart:io';

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
  Future<void> showPrompt({required FocusSettings settings}) async {}

  @override
  Future<void> showSessionComplete() async {}
}
