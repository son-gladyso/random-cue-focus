import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'models.dart';
import 'notification_adapter.dart';
import 'repositories.dart';

/// A wall-clock gap between ticks longer than this means the timer was
/// suspended (for example, the PC slept). Seconds replayed to catch up after
/// such a gap were never on screen.
const maxLiveTickGapSeconds = 3;

class FocusController extends ChangeNotifier {
  FocusController({
    required FocusSettings settings,
    required SessionRepository repository,
    required NotificationAdapter notificationAdapter,
    PromptPlanner planner = const PromptPlanner(),
  }) : _settings = settings.normalized(),
       _repository = repository,
       _notificationAdapter = notificationAdapter,
       _planner = planner {
    _answerSubscription = notificationAdapter.goalCheckAnswers.listen(
      recordNotificationAnswer,
    );
  }

  final SessionRepository _repository;
  final NotificationAdapter _notificationAdapter;
  final PromptPlanner _planner;

  Timer? _ticker;
  DateTime? _lastTick;
  FocusSettings _settings;
  SessionPhase _phase = SessionPhase.idle;
  SessionPhase? _phaseBeforePause;
  String? _activeSessionId;
  DateTime? _startedAt;
  int _focusElapsed = 0;
  int _restElapsed = 0;
  int _microBreakRemaining = 0;
  int _nextPromptIndex = 0;
  Future<void>? _sessionSaveFuture;
  String? _activePromptId;
  StreamSubscription<GoalCheckAnswer>? _answerSubscription;

  @visibleForTesting
  String? get activeSessionId => _activeSessionId;

  /// Wall clock for the ticker; replaceable so tests can simulate sleep.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;
  int? _activePromptStartedElapsed;
  MeasurementContext _measurementContext = const MeasurementContext();
  SessionOutcomeReport? _outcomeReport;
  List<PromptCue> _promptPlan = const [];
  final List<PromptEvent> _events = [];

  FocusSettings get settings => _settings;
  SessionPhase get phase => _phase;
  int get focusElapsed => _focusElapsed;
  int get restElapsed => _restElapsed;
  int get microBreakRemaining => _microBreakRemaining;
  List<PromptCue> get promptPlan => List.unmodifiable(_promptPlan);
  List<PromptEvent> get events => List.unmodifiable(_events);
  SessionOutcomeReport? get outcomeReport => _outcomeReport;
  StudySessionAssignment? get activeStudyAssignment =>
      _measurementContext.studyAssignment;

  bool get isActive =>
      _phase == SessionPhase.focusing ||
      _phase == SessionPhase.microBreak ||
      _phase == SessionPhase.paused ||
      _phase == SessionPhase.resting ||
      _phase == SessionPhase.completed;

  int get remainingSeconds {
    if (_phase == SessionPhase.resting) {
      return (_settings.restDurationSeconds - _restElapsed)
          .clamp(0, _settings.restDurationSeconds)
          .toInt();
    }
    if (_phase == SessionPhase.microBreak) return _microBreakRemaining;
    return (_settings.focusDurationSeconds - _focusElapsed)
        .clamp(0, _settings.focusDurationSeconds)
        .toInt();
  }

  int? get nextPromptRemainingSeconds {
    if (_phase != SessionPhase.focusing ||
        _nextPromptIndex >= _promptPlan.length) {
      return null;
    }
    return (_promptPlan[_nextPromptIndex].offsetSeconds - _focusElapsed)
        .clamp(0, _settings.focusDurationSeconds)
        .toInt();
  }

  double get progress {
    if (_phase == SessionPhase.resting) {
      if (_settings.restDurationSeconds == 0) return 0;
      return (_restElapsed / _settings.restDurationSeconds)
          .clamp(0, 1)
          .toDouble();
    }
    if (_settings.focusDurationSeconds == 0) return 0;
    return (_focusElapsed / _settings.focusDurationSeconds)
        .clamp(0, 1)
        .toDouble();
  }

  String get phaseLabel {
    switch (_phase) {
      case SessionPhase.idle:
        return '准备专注';
      case SessionPhase.focusing:
        return '专注中';
      case SessionPhase.paused:
        return '已暂停';
      case SessionPhase.microBreak:
        return '目标检查';
      case SessionPhase.resting:
        return '休息中';
      case SessionPhase.completed:
        return '已完成';
    }
  }

  Future<void> updateSettings(FocusSettings settings) async {
    _settings = settings.normalized();
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> startOrResume() async {
    if (_phase == SessionPhase.focusing || _phase == SessionPhase.microBreak) {
      pause();
      return;
    }
    if (_phase == SessionPhase.paused) {
      resume();
      return;
    }
    await startFocus();
  }

  Future<void> startFocus() async {
    if (_phase == SessionPhase.focusing || _phase == SessionPhase.microBreak) {
      return;
    }
    final sessions = await _repository.loadSessions();
    final now = DateTime.now();
    StudySessionAssignment? studyAssignment;
    var planningSettings = _settings;
    final enrollment = _settings.studyEnrollment;
    if (enrollment != null && enrollment.isActive) {
      studyAssignment = assignmentForNextStudySession(
        enrollment,
        assignedAt: now,
      );
      final advancedSettings = _settings
          .copyWith(studyEnrollment: enrollment.advance())
          .normalized();
      await _repository.saveSettings(advancedSettings);
      _settings = advancedSettings;
      if (studyAssignment.condition == StudyCondition.noChecks) {
        planningSettings = _settings.copyWith(goalChecksEnabled: false);
      }
    }
    _activeSessionId = _sessionId(now);
    _startedAt = now;
    _focusElapsed = 0;
    _restElapsed = 0;
    _microBreakRemaining = 0;
    _nextPromptIndex = 0;
    _sessionSaveFuture = null;
    _outcomeReport = null;
    _events.clear();
    final cadenceDecision = _settings.adaptiveCadence
        ? cadenceDecisionFromHistory(sessions)
        : const CadenceDecision(factor: 1, reason: 'adaptive_cadence_disabled');
    _promptPlan = _planner.planSession(
      planningSettings,
      sessions,
      seed: now.millisecondsSinceEpoch,
    );
    _measurementContext = MeasurementContext(
      platform: AppPlatform.windows,
      appVersion: '0.2.0+2',
      timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
      plannedPromptOffsets: _promptPlan
          .map((cue) => cue.offsetSeconds)
          .toList(growable: false),
      adaptiveCadence: _settings.adaptiveCadence,
      cadenceFactor: cadenceDecision.factor,
      cadenceReason: cadenceDecision.reason,
      notificationsEnabled: _settings.notificationsEnabled,
      foregroundSoundEnabled: _settings.foregroundPromptSoundEnabled,
      goalChecksEnabled: planningSettings.goalChecksEnabled,
      minPromptIntervalSeconds: planningSettings.minPromptIntervalSeconds,
      maxPromptIntervalSeconds: planningSettings.maxPromptIntervalSeconds,
      responseWindowSeconds: planningSettings.microBreakSeconds,
      studyAssignment: studyAssignment,
    );
    _phase = SessionPhase.focusing;
    _lastTick = clock();
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (_phase != SessionPhase.focusing && _phase != SessionPhase.microBreak) {
      return;
    }
    _phaseBeforePause = _phase;
    _phase = SessionPhase.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_phase != SessionPhase.paused) return;
    _phase = _phaseBeforePause ?? SessionPhase.focusing;
    _phaseBeforePause = null;
    _lastTick = clock();
    _startTicker();
    notifyListeners();
  }

  Future<void> stop() async {
    _ticker?.cancel();
    await _finalizeSession(completed: false);
    _reset();
    notifyListeners();
  }

  void recordOnTask() {
    _finishPrompt(PromptResponseType.onTask);
  }

  void recordOffTask() {
    _finishPrompt(PromptResponseType.offTask);
  }

  void skipPrompt() {
    _finishPrompt(PromptResponseType.skipped);
  }

  Future<void> recordMeaningfulProgress(
    MeaningfulProgressResponse response,
  ) async {
    if (_phase != SessionPhase.completed) return;
    await _finalizeSession(completed: true);
    final id = _activeSessionId;
    if (id == null) return;
    _outcomeReport = SessionOutcomeReport(
      meaningfulProgress: response,
      interruptionBurden: _outcomeReport?.interruptionBurden,
      answeredAt: DateTime.now(),
    );
    await _repository.updateSessionOutcome(id, _outcomeReport!);
    notifyListeners();
  }

  Future<void> recordInterruptionBurden(int rating) async {
    if (_phase != SessionPhase.completed) return;
    await _finalizeSession(completed: true);
    final id = _activeSessionId;
    if (id == null) return;
    _outcomeReport = SessionOutcomeReport(
      meaningfulProgress: _outcomeReport?.meaningfulProgress,
      interruptionBurden: rating,
      answeredAt: DateTime.now(),
    ).normalized();
    await _repository.updateSessionOutcome(id, _outcomeReport!);
    notifyListeners();
  }

  /// Applies an answer chosen from a goal-check toast button.
  ///
  /// Time is settled first, so a check that came due while the PC slept is
  /// already recorded as `missed` before the answer arrives. The check on
  /// screen is resolved directly; a check that was missed or timed out gets a
  /// late answer; anything else (unknown, already answered, session over) is
  /// ignored. Returns whether the answer was recorded.
  bool recordNotificationAnswer(GoalCheckAnswer answer) {
    if (_activeSessionId == null ||
        _phase == SessionPhase.idle ||
        _phase == SessionPhase.completed) {
      return false;
    }
    _tick();
    if (_activePromptId == answer.promptId &&
        (_phase == SessionPhase.microBreak ||
            _phaseBeforePause == SessionPhase.microBreak)) {
      _finishPrompt(answer.response, channel: PromptChannel.notification);
      return true;
    }
    final event = lateNotificationAnswerEvent(
      events: _events,
      answer: answer,
      elapsedSeconds: _focusElapsed,
      at: DateTime.now(),
    );
    if (event == null) return false;
    _events.add(event);
    notifyListeners();
    return true;
  }

  void _finishPrompt(
    PromptResponseType response, {
    PromptChannel channel = PromptChannel.inApp,
  }) {
    final paused =
        _phase == SessionPhase.paused &&
        _phaseBeforePause == SessionPhase.microBreak;
    if (_phase != SessionPhase.microBreak && !paused) return;
    _events.add(
      PromptEvent(
        elapsedSeconds: _focusElapsed,
        occurredAt: DateTime.now(),
        type: response,
        promptId: _activePromptId ?? '',
        responseLatencySeconds: _activePromptStartedElapsed == null
            ? null
            : _focusElapsed - _activePromptStartedElapsed!,
        channel: channel,
      ),
    );
    _activePromptId = null;
    _activePromptStartedElapsed = null;
    _microBreakRemaining = 0;
    if (paused) {
      _phaseBeforePause = SessionPhase.focusing;
    } else {
      _phase = SessionPhase.focusing;
    }
    notifyListeners();
  }

  void delayPrompt() {
    if (_phase != SessionPhase.microBreak) return;
    _events.add(
      PromptEvent(
        elapsedSeconds: _focusElapsed,
        occurredAt: DateTime.now(),
        type: PromptResponseType.delayed,
        promptId: _activePromptId ?? '',
        responseLatencySeconds: _activePromptStartedElapsed == null
            ? null
            : _focusElapsed - _activePromptStartedElapsed!,
      ),
    );
    _activePromptId = null;
    _activePromptStartedElapsed = null;
    _microBreakRemaining = 0;
    _phase = SessionPhase.focusing;
    _promptPlan = [
      ..._promptPlan.take(_nextPromptIndex),
      PromptCue(
        offsetSeconds: (_focusElapsed + 120)
            .clamp(0, _settings.focusDurationSeconds - 30)
            .toInt(),
      ),
      ..._promptPlan.skip(_nextPromptIndex),
    ];
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick([DateTime? at]) {
    final now = at ?? clock();
    final previous = _lastTick ?? now;
    final deltaSeconds = now.difference(previous).inSeconds;
    if (deltaSeconds <= 0) return;
    _lastTick = now;
    // After a suspension (sleep/hibernate), replayed seconds were never on
    // screen: checks that came due then are `missed`, not `shown` + `ended`.
    final promptsVisible = deltaSeconds <= maxLiveTickGapSeconds;
    for (var i = 0; i < deltaSeconds; i += 1) {
      _advanceOneSecond(promptsVisible: promptsVisible);
    }
    notifyListeners();
  }

  void _advanceOneSecond({required bool promptsVisible}) {
    switch (_phase) {
      case SessionPhase.focusing:
        _focusElapsed += 1;
        _maybeStartMicroBreak(visible: promptsVisible);
        if (_focusElapsed >= _settings.focusDurationSeconds) {
          _completeFocus();
        }
        break;
      case SessionPhase.microBreak:
        _focusElapsed += 1;
        _microBreakRemaining -= 1;
        if (_focusElapsed >= _settings.focusDurationSeconds) {
          _completeFocus();
          break;
        }
        if (_microBreakRemaining <= 0) {
          _events.add(
            PromptEvent(
              elapsedSeconds: _focusElapsed,
              occurredAt: DateTime.now(),
              type: PromptResponseType.ended,
              promptId: _activePromptId ?? '',
              responseLatencySeconds: _activePromptStartedElapsed == null
                  ? null
                  : _focusElapsed - _activePromptStartedElapsed!,
            ),
          );
          _activePromptId = null;
          _activePromptStartedElapsed = null;
          _phase = SessionPhase.focusing;
        }
        break;
      case SessionPhase.resting:
        _restElapsed += 1;
        if (_restElapsed >= _settings.restDurationSeconds) {
          _ticker?.cancel();
          _phase = SessionPhase.completed;
          unawaited(_finalizeSession(completed: true));
        }
        break;
      case SessionPhase.idle:
      case SessionPhase.paused:
      case SessionPhase.completed:
        break;
    }
  }

  /// Advances live (on-screen) seconds one by one, as the ticker would.
  @visibleForTesting
  void advanceForTesting(int seconds) {
    assert(seconds >= 0);
    _ticker?.cancel();
    for (var i = 0; i < seconds; i += 1) {
      _advanceOneSecond(promptsVisible: true);
    }
    _ticker?.cancel();
    notifyListeners();
  }

  /// Runs one ticker callback as if the wall clock now read [now].
  @visibleForTesting
  void tickAtForTesting(DateTime now) {
    _ticker?.cancel();
    _tick(now);
    _ticker?.cancel();
  }

  void _maybeStartMicroBreak({required bool visible}) {
    if (_nextPromptIndex >= _promptPlan.length) return;
    final nextCue = _promptPlan[_nextPromptIndex];
    if (_focusElapsed < nextCue.offsetSeconds) return;

    final promptId = goalCheckPromptId(
      _activeSessionId ?? 'session',
      _nextPromptIndex,
    );
    _nextPromptIndex += 1;
    if (!visible) {
      // No card, sound, or toast: a stale alert after waking would be noise.
      _events.add(
        PromptEvent(
          elapsedSeconds: _focusElapsed,
          occurredAt: DateTime.now(),
          type: PromptResponseType.missed,
          promptId: promptId,
          plannedOffsetSeconds: nextCue.offsetSeconds,
        ),
      );
      return;
    }
    _microBreakRemaining = _settings.microBreakSeconds;
    _phase = SessionPhase.microBreak;
    _activePromptId = promptId;
    _activePromptStartedElapsed = _focusElapsed;
    _events.add(
      PromptEvent(
        elapsedSeconds: _focusElapsed,
        occurredAt: DateTime.now(),
        type: PromptResponseType.shown,
        promptId: promptId,
        plannedOffsetSeconds: nextCue.offsetSeconds,
      ),
    );
    unawaited(
      _notificationAdapter.showPrompt(settings: _settings, promptId: promptId),
    );
  }

  void _completeFocus() {
    _ticker?.cancel();
    _phase = SessionPhase.resting;
    _restElapsed = 0;
    _lastTick = clock();
    unawaited(_notificationAdapter.showSessionComplete());
    _startTicker();
  }

  Future<void> _finalizeSession({required bool completed}) async {
    final existingSave = _sessionSaveFuture;
    if (existingSave != null) return existingSave;
    final id = _activeSessionId;
    final startedAt = _startedAt;
    if (id == null || startedAt == null || _focusElapsed <= 0) return;
    final save = _repository.appendSession(
      FocusSession(
        id: id,
        startedAt: startedAt,
        endedAt: DateTime.now(),
        plannedFocusSeconds: _settings.focusDurationSeconds,
        focusSeconds: _focusElapsed
            .clamp(0, _settings.focusDurationSeconds)
            .toInt(),
        restSeconds: _restElapsed
            .clamp(0, _settings.restDurationSeconds)
            .toInt(),
        completed: completed,
        modeName: _settings.modeName,
        promptEvents: List.unmodifiable(_events),
        goal: _settings.sessionGoal,
        ifThenPlan: _settings.ifThenPlan,
        recallPrompt: _settings.recallPrompt,
        measurementContext: _measurementContext,
      ),
    );
    _sessionSaveFuture = save;
    try {
      await save;
    } catch (_) {
      _sessionSaveFuture = null;
      rethrow;
    }
  }

  void _reset() {
    _activeSessionId = null;
    _startedAt = null;
    _phase = SessionPhase.idle;
    _phaseBeforePause = null;
    _focusElapsed = 0;
    _restElapsed = 0;
    _microBreakRemaining = 0;
    _nextPromptIndex = 0;
    _sessionSaveFuture = null;
    _outcomeReport = null;
    _activePromptId = null;
    _activePromptStartedElapsed = null;
    _measurementContext = const MeasurementContext();
    _promptPlan = const [];
    _events.clear();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_answerSubscription?.cancel());
    super.dispose();
  }

  String _sessionId(DateTime now) {
    final random = Random(now.microsecondsSinceEpoch);
    return '${now.microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
  }
}
