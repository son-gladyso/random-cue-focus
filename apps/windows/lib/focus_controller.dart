import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'models.dart';
import 'notification_adapter.dart';
import 'prompt_planner.dart';
import 'repositories.dart';

class FocusController extends ChangeNotifier {
  FocusController({
    required FocusSettings settings,
    required SessionRepository repository,
    required NotificationAdapter notificationAdapter,
    PromptPlanner planner = const PromptPlanner(),
  }) : _settings = settings.normalized(),
       _repository = repository,
       _notificationAdapter = notificationAdapter,
       _planner = planner;

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
  bool _sessionSaved = false;
  List<PromptCue> _promptPlan = const [];
  final List<PromptEvent> _events = [];

  FocusSettings get settings => _settings;
  SessionPhase get phase => _phase;
  int get focusElapsed => _focusElapsed;
  int get restElapsed => _restElapsed;
  int get microBreakRemaining => _microBreakRemaining;
  List<PromptCue> get promptPlan => List.unmodifiable(_promptPlan);
  List<PromptEvent> get events => List.unmodifiable(_events);

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
        return '微休息';
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
    _activeSessionId = _sessionId(now);
    _startedAt = now;
    _focusElapsed = 0;
    _restElapsed = 0;
    _microBreakRemaining = 0;
    _nextPromptIndex = 0;
    _sessionSaved = false;
    _events.clear();
    _promptPlan = _planner.planSession(
      _settings,
      sessions,
      seed: now.millisecondsSinceEpoch,
    );
    _phase = SessionPhase.focusing;
    _lastTick = now;
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
    _lastTick = DateTime.now();
    _startTicker();
    notifyListeners();
  }

  Future<void> stop() async {
    _ticker?.cancel();
    await _finalizeSession(completed: false);
    _reset();
    notifyListeners();
  }

  void acknowledgePrompt() {
    if (_phase != SessionPhase.microBreak) return;
    _events.add(
      PromptEvent(
        elapsedSeconds: _focusElapsed,
        occurredAt: DateTime.now(),
        type: PromptResponseType.acknowledged,
      ),
    );
    _microBreakRemaining = 1;
    notifyListeners();
  }

  void skipPrompt() {
    if (_phase != SessionPhase.microBreak) return;
    _events.add(
      PromptEvent(
        elapsedSeconds: _focusElapsed,
        occurredAt: DateTime.now(),
        type: PromptResponseType.skipped,
      ),
    );
    _microBreakRemaining = 0;
    _phase = SessionPhase.focusing;
    notifyListeners();
  }

  void delayPrompt() {
    if (_phase != SessionPhase.microBreak) return;
    _events.add(
      PromptEvent(
        elapsedSeconds: _focusElapsed,
        occurredAt: DateTime.now(),
        type: PromptResponseType.delayed,
      ),
    );
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
        _microBreakRemaining -= 1;
        if (_microBreakRemaining <= 0) {
          _events.add(
            PromptEvent(
              elapsedSeconds: _focusElapsed,
              occurredAt: DateTime.now(),
              type: PromptResponseType.ended,
            ),
          );
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

  void _maybeStartMicroBreak() {
    if (_nextPromptIndex >= _promptPlan.length) return;
    final nextCue = _promptPlan[_nextPromptIndex];
    if (_focusElapsed < nextCue.offsetSeconds) return;

    _nextPromptIndex += 1;
    _microBreakRemaining = _settings.microBreakSeconds;
    _phase = SessionPhase.microBreak;
    _events.add(
      PromptEvent(
        elapsedSeconds: _focusElapsed,
        occurredAt: DateTime.now(),
        type: PromptResponseType.shown,
      ),
    );
    unawaited(
      _notificationAdapter.showPrompt(
        settings: _settings,
        remainingMicroBreakSeconds: _settings.microBreakSeconds,
      ),
    );
  }

  void _completeFocus() {
    _ticker?.cancel();
    _phase = SessionPhase.resting;
    _restElapsed = 0;
    _lastTick = DateTime.now();
    unawaited(_notificationAdapter.showSessionComplete());
    _startTicker();
  }

  Future<void> _finalizeSession({required bool completed}) async {
    if (_sessionSaved) return;
    final id = _activeSessionId;
    final startedAt = _startedAt;
    if (id == null || startedAt == null || _focusElapsed <= 0) return;
    _sessionSaved = true;
    await _repository.appendSession(
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
      ),
    );
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
    _sessionSaved = false;
    _promptPlan = const [];
    _events.clear();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _sessionId(DateTime now) {
    final random = Random(now.microsecondsSinceEpoch);
    return '${now.microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
  }
}
