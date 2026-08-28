import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

class NotificationService {
  NotificationService()
    : _plugin = FlutterLocalNotificationsPlugin(),
      _scheduledIds = <int>[];

  final FlutterLocalNotificationsPlugin _plugin;
  final List<int> _scheduledIds;
  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(iOS: darwin);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> requestPermissionsIfNeeded() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: false);
  }

  Future<void> cancelScheduled() async {
    await initialize();
    for (final id in _scheduledIds) {
      await _plugin.cancel(id: id);
    }
    _scheduledIds.clear();
  }

  Future<void> scheduleFocusFallback({
    required String sessionId,
    required FocusSettings settings,
    required List<PromptCue> cues,
    required int elapsedSeconds,
  }) async {
    if (!settings.lockScreenNotifications) return;
    await requestPermissionsIfNeeded();
    await cancelScheduled();

    final now = DateTime.now();
    final futureCues = cues
        .where((cue) => cue.offsetSeconds > elapsedSeconds)
        .take(48);
    for (final cue in futureCues) {
      final secondsFromNow = cue.offsetSeconds - elapsedSeconds;
      final id = _stableNotificationId(sessionId, cue.offsetSeconds);
      _scheduledIds.add(id);
      await _plugin.zonedSchedule(
        id: id,
        title: '目标检查',
        body: settings.sessionGoal.isEmpty
            ? '还在做刚才决定的事吗？可忽略；未响应不会被视为失败。'
            : '当前目标：${settings.sessionGoal}',
        scheduledDate: tz.TZDateTime.from(
          now.add(Duration(seconds: secondsFromNow)),
          tz.local,
        ),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'focus_timers',
            'Focus timers',
            channelDescription: 'Random cue focus timer reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: false,
            threadIdentifier: 'random-cue-focus',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    final remainingFocus = settings.focusDurationSeconds - elapsedSeconds;
    if (remainingFocus > 0) {
      final endId = _stableNotificationId(sessionId, 999999);
      _scheduledIds.add(endId);
      await _plugin.zonedSchedule(
        id: endId,
        title: '专注结束',
        body: '这一轮计时已结束。你可以休息，或先记录下一步。',
        scheduledDate: tz.TZDateTime.from(
          now.add(Duration(seconds: remainingFocus)),
          tz.local,
        ),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'focus_timers',
            'Focus timers',
            channelDescription: 'Random cue focus timer reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: false,
            threadIdentifier: 'random-cue-focus',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  int _stableNotificationId(String sessionId, int offset) {
    return (sessionId.hashCode ^ offset.hashCode) & 0x7fffffff;
  }
}
