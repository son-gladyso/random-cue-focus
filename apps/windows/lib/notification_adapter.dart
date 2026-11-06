import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_local_notifications_windows/flutter_local_notifications_windows.dart';

import 'models.dart';

/// Identity under which Windows shows and routes this app's toasts.
const toastAppUserModelId = 'RandomCueFocus.Desktop';

/// COM activation GUID for toast button presses. It must stay stable across
/// releases, or Windows can no longer route presses back to the app.
const toastActivationGuid = '2ac925c6-f9d0-493d-951b-7933e7fd2791';

/// Toast details for a goal check: two answer buttons and no sound.
///
/// Dismissing the toast is the way to not answer. Sound stays off here;
/// the optional foreground sound is a separate setting played by the app.
WindowsNotificationDetails goalCheckToastDetails(String promptId) {
  return WindowsNotificationDetails(
    actions: [
      WindowsAction(
        content: '仍在目标',
        arguments: goalCheckActionArguments(goalCheckOnTaskActionId, promptId),
      ),
      WindowsAction(
        content: '刚刚走神',
        arguments: goalCheckActionArguments(goalCheckOffTaskActionId, promptId),
      ),
    ],
    audio: WindowsNotificationAudio.silent(),
  );
}

class NotificationAdapter {
  NotificationAdapter();

  static const _channel = MethodChannel('random_cue_focus/windows');
  final _answers = StreamController<GoalCheckAnswer>.broadcast();
  FlutterLocalNotificationsWindows? _toasts;
  var _initialized = false;
  var _nextToastId = 1;

  /// Answers chosen from goal-check toast buttons.
  Stream<GoalCheckAnswer> get goalCheckAnswers => _answers.stream;

  /// Whether toasts with buttons are available. When `false`, notifications
  /// fall back to the tray balloon, which cannot carry buttons.
  bool get supportsAnswerButtons => _toasts != null;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _channel.invokeMethod<void>('initialize');
    } catch (error) {
      debugPrint('Native init failed: $error');
    }
    try {
      final toasts = FlutterLocalNotificationsWindows();
      final ready = await toasts.initialize(
        settings: const WindowsInitializationSettings(
          appName: 'Random Cue Focus',
          appUserModelId: toastAppUserModelId,
          guid: toastActivationGuid,
        ),
        onDidReceiveNotificationResponse: handleResponse,
      );
      if (ready) _toasts = toasts;
    } catch (error) {
      debugPrint('Toast notifications unavailable; using tray balloon: $error');
    }
  }

  /// Routes a toast activation to [goalCheckAnswers]. Clicking the toast body
  /// or any other notification is ignored.
  @visibleForTesting
  void handleResponse(NotificationResponse response) {
    final answer = parseGoalCheckAnswer(
      actionId: response.actionId,
      payload: response.payload,
    );
    if (answer != null) _answers.add(answer);
  }

  Future<void> showPrompt({
    required FocusSettings settings,
    required String promptId,
  }) async {
    await initialize();
    if (settings.foregroundPromptSoundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.selectionClick();
    }
    if (!settings.desktopNotifications) return;
    final title = '目标检查';
    final body = settings.sessionGoal.isEmpty
        ? '还在做刚才决定的事吗？可忽略；应用不会把未响应当作失败。'
        : '当前目标：${settings.sessionGoal}';
    final toasts = _toasts;
    if (toasts != null) {
      try {
        await toasts.show(
          id: _nextToastId++,
          title: title,
          body: body,
          notificationDetails: goalCheckToastDetails(promptId),
        );
        return;
      } catch (error) {
        debugPrint('Toast failed; using tray balloon: $error');
      }
    }
    await _showBalloon(title, body);
  }

  Future<void> showSessionComplete() async {
    await initialize();
    const title = '专注结束';
    const body = '这一轮计时已结束。你可以按自己的计划休息，或先记录下一步。';
    final toasts = _toasts;
    if (toasts != null) {
      try {
        await toasts.show(
          id: _nextToastId++,
          title: title,
          body: body,
          notificationDetails: WindowsNotificationDetails(
            audio: WindowsNotificationAudio.silent(),
          ),
        );
        return;
      } catch (error) {
        debugPrint('Toast failed; using tray balloon: $error');
      }
    }
    await _showBalloon(title, body);
  }

  Future<void> _showBalloon(String title, String body) async {
    try {
      await _channel.invokeMethod<void>('notify', {
        'title': title,
        'body': body,
      });
    } catch (error) {
      debugPrint('Native notification failed: $error');
    }
  }
}
