import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

class NotificationAdapter {
  NotificationAdapter();

  static const _channel = MethodChannel('random_cue_focus/windows');
  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _channel.invokeMethod<void>('initialize');
    } catch (error) {
      debugPrint('Native init failed: $error');
    }
    _initialized = true;
  }

  Future<void> showPrompt({
    required FocusSettings settings,
    required int remainingMicroBreakSeconds,
  }) async {
    await initialize();
    if (settings.foregroundPromptSoundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.selectionClick();
    }
    if (!settings.desktopNotifications) return;
    try {
      await _channel.invokeMethod<void>('notify', {
        'title': '微休息提示',
        'body': '停 $remainingMicroBreakSeconds 秒，放松视线，然后回到当前小目标。',
      });
    } catch (error) {
      debugPrint('Native notification failed: $error');
    }
  }

  Future<void> showSessionComplete() async {
    await initialize();
    try {
      await _channel.invokeMethod<void>('notify', {
        'title': '专注结束',
        'body': '这一轮完成了。进入休息，让大脑整理刚刚处理的信息。',
      });
    } catch (error) {
      debugPrint('Native notification failed: $error');
    }
  }
}
