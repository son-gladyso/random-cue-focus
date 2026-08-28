import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'notification_service.dart';
import 'stores.dart';

class FocusEngine extends ChangeNotifier {
  FocusEngine({
    required FocusSettings settings,
    required SettingsStore settingsStore,
    required SessionStore sessionStore,
    required NotificationService notificationService,
  }) : _settings = settings,
       _settingsStore = settingsStore,
       _sessionStore = sessionStore,
       _notificationService = notificationService;

  final SettingsStore _settingsStore;
  final SessionStore _sessionStore;
  final NotificationService _notificationService;
  final _uuid = const Uuid();

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
        return '专注 >';
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
    final previous = _settings;
    _settings = settings.normalized();
    await _settingsStore.save(_settings);
    if (_activeSessionId != null &&
        previous.lockScreenNotifications != _settings.lockScreenNotifications) {
      if (_settings.lockScreenNotifications) {
        await _notificationService.scheduleFocusFallback(
          sessionId: _activeSessionId!,
          settings: _settings,
          cues: _promptPlan,
          elapsedSeconds: _focusElapsed,
        );
      } else {
        await _notificationService.cancelScheduled();
      }
    }
    notifyListeners();
  }

  Future<void> startFocus() async {
    if (_phase == SessionPhase.focusing || _phase == SessionPhase.microBreak) {
      return;
    }
    if (_phase == SessionPhase.paused) {
      await resume();
      return;
    }

    final sessions = await _sessionStore.loadSessions();
    final startedAt = DateTime.now();
    StudySessionAssignment? studyAssignment;
    var planningSettings = _settings;
    final enrollment = _settings.studyEnrollment;
    if (enrollment != null && enrollment.isActive) {
      studyAssignment = assignmentForNextStudySession(
        enrollment,
        assignedAt: startedAt,
      );
      final advancedSettings = _settings
          .copyWith(studyEnrollment: enrollment.advance())
          .normalized();
      await _settingsStore.save(advancedSettings);
      _settings = advancedSettings;
      if (studyAssignment.condition == StudyCondition.noChecks) {
        planningSettings = _settings.copyWith(goalChecksEnabled: false);
      }
    }
    final cadenceDecision = _settings.adaptiveCadence
        ? cadenceDecisionFromHistory(sessions)
        : const CadenceDecision(factor: 1, reason: 'adaptive_cadence_disabled');
    final sessionId = _uuid.v4();
    _activeSessionId = sessionId;
    _startedAt = startedAt;
    _focusElapsed = 0;
    _restElapsed = 0;
    _microBreakRemaining = 0;
    _nextPromptIndex = 0;
    _sessionSaveFuture = null;
    _outcomeReport = null;
    _events.clear();
    _promptPlan = buildPromptPlan(
      planningSettings,
      seed: _startedAt!.millisecondsSinceEpoch,
      personalCadenceFactor: cadenceDecision.factor,
    );
    _measurementContext = MeasurementContext(
      platform: AppPlatform.ios,
      appVersion: '0.2.0+2',
      timezoneOffsetMinutes: _startedAt!.timeZoneOffset.inMinutes,
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
    _lastTick = DateTime.now();

    try {
      await _notificationService.scheduleFocusFallback(
        sessionId: sessionId,
        settings: _settings,
        cues: _promptPlan,
        elapsedSeconds: _focusElapsed,
      );
    } catch (error) {
      debugPrint('Notification scheduling failed; timer continues: $error');
    }
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
    unawaited(_notificationService.cancelScheduled());
    notifyListeners();
  }

  Future<void> resume() async {
    if (_phase != SessionPhase.paused) return;
    _phase = _phaseBeforePause ?? SessionPhase.focusing;
    _phaseBeforePause = null;
    _lastTick = DateTime.now();
    _startTicker();
    final sessionId = _activeSessionId;
    if (sessionId != null) {
      await _notificationService.scheduleFocusFallback(
        sessionId: sessionId,
        settings: _settings,
        cues: _promptPlan,
        elapsedSeconds: _focusElapsed,
      );
    }
    notifyListeners();
  }

  Future<void> stop() async {
    _ticker?.cancel();
    await _notificationService.cancelScheduled();
    await _finalizeSession(completed: false);
    _reset();
    notifyListeners();
  }

  void recordOnTask() {
    _resolvePrompt(PromptResponseType.onTask);
  }

  void recordOffTask() {
    _resolvePrompt(PromptResponseType.offTask);
  }

  void skipPrompt() {
    _resolvePrompt(PromptResponseType.skipped);
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
    await _sessionStore.updateSessionOutcome(id, _outcomeReport!);
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
    await _sessionStore.updateSessionOutcome(id, _outcomeReport!);
    notifyListeners();
  }

  void _resolvePrompt(PromptResponseType response) {
    if (_phase != SessionPhase.microBreak) return;
    _events.add(
      PromptEvent(
        elapsedSeconds: _focusElapsed,
        occurredAt: DateTime.now(),
        type: response,
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
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final previous = _lastTick ?? now;
    final deltaSeconds = now.difference(previous).inSeconds;
    if (deltaSeconds <= 0) return;
    _lastTick = now;
    for (var i = 0; i < deltaSeconds; i += 1) {
      _advanceOneSecond();
    }
    notifyListeners();
  }

  void _advanceOneSecond() {
    switch (_phase) {
      case SessionPhase.focusing:
        _focusElapsed += 1;
        _maybeStartMicroBreak();
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
          unawaited(_playCue());
        }
        break;
      case SessionPhase.idle:
      case SessionPhase.paused:
      case SessionPhase.completed:
        break;
    }
  }

  @visibleForTesting
  void advanceForTesting(int seconds) {
    assert(seconds >= 0);
    _ticker?.cancel();
    for (var i = 0; i < seconds; i += 1) {
      _advanceOneSecond();
    }
    _ticker?.cancel();
    notifyListeners();
  }

  void _maybeStartMicroBreak() {
    if (_nextPromptIndex >= _promptPlan.length) return;
    final nextCue = _promptPlan[_nextPromptIndex];
    if (_focusElapsed < nextCue.offsetSeconds) return;

    final promptId = '${_activeSessionId ?? 'session'}:$_nextPromptIndex';
    _nextPromptIndex += 1;
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
    unawaited(_playCue());
  }

  void _completeFocus() {
    _ticker?.cancel();
    _phase = SessionPhase.resting;
    _restElapsed = 0;
    unawaited(_notificationService.cancelScheduled());
    unawaited(_playCue());
    _lastTick = DateTime.now();
    _startTicker();
  }

  Future<void> _finalizeSession({required bool completed}) async {
    final existingSave = _sessionSaveFuture;
    if (existingSave != null) return existingSave;
    final id = _activeSessionId;
    final startedAt = _startedAt;
    if (id == null || startedAt == null || _focusElapsed <= 0) return;
    final save = _sessionStore.appendSession(
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

  Future<void> _playCue() async {
    if (!_settings.foregroundPromptSoundEnabled) return;
    switch (_settings.soundPreset) {
      case SoundPreset.softBell:
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.selectionClick();
        break;
      case SoundPreset.gentleTap:
        await SystemSound.play(SystemSoundType.click);
        await HapticFeedback.lightImpact();
        break;
      case SoundPreset.clearChime:
        await SystemSound.play(SystemSoundType.alert);
        await Future<void>.delayed(const Duration(milliseconds: 140));
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.mediumImpact();
        break;
      case SoundPreset.piano:
        await SystemSound.play(SystemSoundType.click);
        await Future<void>.delayed(const Duration(milliseconds: 90));
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.selectionClick();
        break;
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
    super.dispose();
  }
}
