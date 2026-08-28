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

  Future<void> showPrompt({required FocusSettings settings}) async {
    await initialize();
    if (settings.foregroundPromptSoundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.selectionClick();
    }
    if (!settings.desktopNotifications) return;
    try {
      await _channel.invokeMethod<void>('notify', {
        'title': '目标检查',
        'body': settings.sessionGoal.isEmpty
            ? '还在做刚才决定的事吗？可忽略；应用不会把未响应当作失败。'
            : '当前目标：${settings.sessionGoal}',
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
        'body': '这一轮计时已结束。你可以按自己的计划休息，或先记录下一步。',
      });
    } catch (error) {
      debugPrint('Native notification failed: $error');
    }
  }
}
