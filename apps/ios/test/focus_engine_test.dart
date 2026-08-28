import 'package:flutter_test/flutter_test.dart';
import 'package:random_cue_focus/focus_engine.dart';
import 'package:random_cue_focus/models.dart';
import 'package:random_cue_focus/notification_service.dart';
import 'package:random_cue_focus/stores.dart';

void main() {
  const settings = FocusSettings(
    focusDurationMinutes: 10,
    restDurationMinutes: 1,
    minPromptIntervalMinutes: 5,
    maxPromptIntervalMinutes: 5,
    microBreakSeconds: 5,
    adaptiveCadence: false,
  );

  test(
    'goal check records response while focus time keeps advancing',
    () async {
      final engine = _engine(settings);
      await engine.startFocus();

      engine.advanceForTesting(300);
      expect(engine.phase, SessionPhase.microBreak);
      expect(engine.events.map((event) => event.type), [
        PromptResponseType.shown,
      ]);
      engine.advanceForTesting(2);
      engine.recordOffTask();
      expect(engine.focusElapsed, 302);
      expect(engine.phase, SessionPhase.focusing);
      expect(engine.events.map((event) => event.type), [
        PromptResponseType.shown,
        PromptResponseType.offTask,
      ]);
      expect(engine.events.last.promptId, engine.events.first.promptId);
      expect(engine.events.last.responseLatencySeconds, 2);
      engine.dispose();
    },
  );

  test('goal check can be answered, skipped, or time out', () async {
    for (final response in [
      PromptResponseType.onTask,
      PromptResponseType.skipped,
    ]) {
      final engine = _engine(settings);
      await engine.startFocus();
      engine.advanceForTesting(300);
      if (response == PromptResponseType.onTask) {
        engine.recordOnTask();
      } else {
        engine.skipPrompt();
      }
      expect(engine.events.last.type, response);
      expect(engine.phase, SessionPhase.focusing);
      engine.dispose();
    }

    final timedOut = _engine(settings);
    await timedOut.startFocus();
    timedOut.advanceForTesting(305);
    expect(timedOut.events.map((event) => event.type), [
      PromptResponseType.shown,
      PromptResponseType.ended,
    ]);
    expect(timedOut.focusElapsed, 305);
    expect(timedOut.phase, SessionPhase.focusing);
    timedOut.dispose();
  });

  test('stop and focus completion leave the goal-check phase', () async {
    final stopped = _engine(settings);
    await stopped.startFocus();
    stopped.advanceForTesting(300);
    await stopped.stop();
    expect(stopped.phase, SessionPhase.idle);
    stopped.dispose();

    final completed = _engine(settings);
    await completed.startFocus();
    completed.advanceForTesting(600);
    expect(completed.phase, SessionPhase.resting);
    expect(completed.phase, isNot(SessionPhase.microBreak));
    completed.dispose();
  });

  test('disabled adaptive cadence ignores high-skip history', () async {
    final history = List.generate(
      3,
      (index) => FocusSession(
        id: '$index',
        startedAt: DateTime(2026, 1, index + 1),
        endedAt: DateTime(2026, 1, index + 1, 1),
        plannedFocusSeconds: 600,
        focusSeconds: 600,
        restSeconds: 0,
        completed: true,
        modeName: 'test',
        promptEvents: List.generate(
          2,
          (_) => PromptEvent(
            elapsedSeconds: 300,
            occurredAt: DateTime(2026, 1, index + 1),
            type: PromptResponseType.skipped,
          ),
        ),
      ),
    );
    final engine = FocusEngine(
      settings: settings,
      settingsStore: _MemorySettingsStore(),
      sessionStore: _MemorySessionStore(history),
      notificationService: _NoopNotificationService(),
    );

    await engine.startFocus();
    expect(engine.promptPlan.first.offsetSeconds, 300);
    engine.dispose();
  });

  test('completed session accepts optional local outcome feedback', () async {
    final store = _MemorySessionStore();
    final engine = FocusEngine(
      settings: settings,
      settingsStore: _MemorySettingsStore(),
      sessionStore: store,
      notificationService: _NoopNotificationService(),
    );
    await engine.startFocus();
    engine.advanceForTesting(660);
    expect(engine.phase, SessionPhase.completed);

    await engine.recordMeaningfulProgress(MeaningfulProgressResponse.yes);
    await engine.recordInterruptionBurden(2);

    final session = store.sessions.single;
    final measurement = session.measurementContext;
    expect(measurement.platform, AppPlatform.ios);
    expect(session.dataSchemaVersion, currentDataSchemaVersion);
    expect(measurement.goalChecksEnabled, isTrue);
    expect(measurement.minPromptIntervalSeconds, 300);
    expect(measurement.maxPromptIntervalSeconds, 300);
    expect(measurement.responseWindowSeconds, 5);
    expect(
      store.sessions.single.outcomeReport!.meaningfulProgress,
      MeaningfulProgressResponse.yes,
    );
    expect(store.sessions.single.outcomeReport!.interruptionBurden, 2);
    engine.dispose();
  });

  test('opt-in crossover assignment is saved before exposure', () async {
    final enrollment = createLocalFeasibilityEnrollment(
      participantCode: 'P-test',
      consentedAt: DateTime(2026, 8, 27),
      sequence: StudySequence.ab,
    );
    final settingsStore = _MemorySettingsStore();
    final sessionStore = _MemorySessionStore();
    final engine = FocusEngine(
      settings: settings.copyWith(studyEnrollment: enrollment),
      settingsStore: settingsStore,
      sessionStore: sessionStore,
      notificationService: _NoopNotificationService(),
    );

    await engine.startFocus();
    expect(engine.activeStudyAssignment!.condition, StudyCondition.noChecks);
    expect(engine.promptPlan, isEmpty);
    expect(settingsStore.saved!.studyEnrollment!.nextSessionIndex, 1);
    engine.advanceForTesting(1);
    await engine.stop();

    expect(
      sessionStore
          .sessions
          .single
          .measurementContext
          .studyAssignment!
          .condition,
      StudyCondition.noChecks,
    );
    expect(
      sessionStore.sessions.single.measurementContext.goalChecksEnabled,
      isFalse,
    );
    await engine.startFocus();
    expect(
      engine.activeStudyAssignment!.condition,
      StudyCondition.sparseChecks,
    );
    expect(engine.promptPlan, isNotEmpty);
    engine.dispose();
  });

  test('notification scheduling failure does not stop the timer', () async {
    final engine = FocusEngine(
      settings: settings.copyWith(lockScreenNotifications: true),
      settingsStore: _MemorySettingsStore(),
      sessionStore: _MemorySessionStore(),
      notificationService: _ThrowingNotificationService(),
    );

    await engine.startFocus();

    expect(engine.phase, SessionPhase.focusing);
    engine.advanceForTesting(1);
    expect(engine.focusElapsed, 1);
    engine.dispose();
  });

  test('failed enrollment write does not consume an assignment', () async {
    final enrollment = createLocalFeasibilityEnrollment(
      participantCode: 'P-retry',
      consentedAt: DateTime(2026, 8, 27),
      sequence: StudySequence.ab,
    );
    final settingsStore = _FailOnceSettingsStore();
    final engine = FocusEngine(
      settings: settings.copyWith(studyEnrollment: enrollment),
      settingsStore: settingsStore,
      sessionStore: _MemorySessionStore(),
      notificationService: _NoopNotificationService(),
    );

    await expectLater(engine.startFocus(), throwsStateError);
    expect(engine.settings.studyEnrollment!.nextSessionIndex, 0);
    expect(engine.activeStudyAssignment, isNull);

    await engine.startFocus();
    expect(engine.activeStudyAssignment!.sessionIndex, 0);
    expect(engine.activeStudyAssignment!.condition, StudyCondition.noChecks);
    engine.dispose();
  });
}

FocusEngine _engine(FocusSettings settings) {
  return FocusEngine(
    settings: settings,
    settingsStore: _MemorySettingsStore(),
    sessionStore: _MemorySessionStore(),
    notificationService: _NoopNotificationService(),
  );
}

class _MemorySettingsStore extends SettingsStore {
  _MemorySettingsStore() : super(preferences: _MemoryPreferences());

  FocusSettings? saved;

  @override
  Future<void> save(FocusSettings settings) async {
    saved = settings;
  }
}

class _FailOnceSettingsStore extends _MemorySettingsStore {
  var _shouldFail = true;

  @override
  Future<void> save(FocusSettings settings) async {
    if (_shouldFail) {
      _shouldFail = false;
      throw StateError('simulated settings write failure');
    }
    await super.save(settings);
  }
}

class _MemorySessionStore extends SessionStore {
  _MemorySessionStore([Iterable<FocusSession> initial = const []])
    : sessions = List.of(initial),
      super(preferences: _MemoryPreferences());

  final List<FocusSession> sessions;

  @override
  Future<List<FocusSession>> loadSessions() async => List.of(sessions);

  @override
  Future<void> appendSession(FocusSession session) async {
    sessions.add(session);
  }

  @override
  Future<void> updateSessionOutcome(
    String sessionId,
    SessionOutcomeReport outcome,
  ) async {
    final index = sessions.indexWhere((session) => session.id == sessionId);
    if (index >= 0) {
      sessions[index] = sessions[index].copyWith(outcomeReport: outcome);
    }
  }
}

class _MemoryPreferences implements PreferencesBackend {
  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<List<String>?> getStringList(String key) async => null;

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> setString(String key, String value) async {}

  @override
  Future<void> setStringList(String key, List<String> value) async {}
}

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> cancelScheduled() async {}

  @override
  Future<void> scheduleFocusFallback({
    required String sessionId,
    required FocusSettings settings,
    required List<PromptCue> cues,
    required int elapsedSeconds,
  }) async {}
}

class _ThrowingNotificationService extends _NoopNotificationService {
  @override
  Future<void> scheduleFocusFallback({
    required String sessionId,
    required FocusSettings settings,
    required List<PromptCue> cues,
    required int elapsedSeconds,
  }) async {
    throw StateError('simulated scheduling failure');
  }
}
