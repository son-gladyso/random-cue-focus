import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// Goal-check notification category with answer buttons.
///
/// Both actions open the app (`foreground`), so the answer is handled by the
/// running engine in the main isolate and never needs a background isolate to
/// hand data across. Dismissing the notification is the way to not answer.
final goalCheckCategory = DarwinNotificationCategory(
  goalCheckNotificationCategory,
  actions: [
    DarwinNotificationAction.plain(
      goalCheckOnTaskActionId,
      '仍在目标',
      options: const {DarwinNotificationActionOption.foreground},
    ),
    DarwinNotificationAction.plain(
      goalCheckOffTaskActionId,
      '刚刚走神',
      options: const {DarwinNotificationActionOption.foreground},
    ),
  ],
);

/// One scheduled goal-check notification.
class PlannedGoalCheckNotification {
  const PlannedGoalCheckNotification({
    required this.id,
    required this.promptId,
    required this.secondsFromNow,
  });

  final int id;

  /// Payload; equals the engine's prompt ID for the same check.
  final String promptId;
  final int secondsFromNow;
}

/// Which goal checks still need a notification, keeping each check's index in
/// the full plan so its payload matches the engine's prompt ID even when the
/// session resumes part-way through.
List<PlannedGoalCheckNotification> plannedGoalCheckNotifications({
  required String sessionId,
  required List<PromptCue> cues,
  required int elapsedSeconds,
  int limit = 48,
}) {
  final planned = <PlannedGoalCheckNotification>[];
  for (var index = 0; index < cues.length && planned.length < limit; index++) {
    final cue = cues[index];
    if (cue.offsetSeconds <= elapsedSeconds) continue;
    planned.add(
      PlannedGoalCheckNotification(
        id: stableNotificationId(sessionId, cue.offsetSeconds),
        promptId: goalCheckPromptId(sessionId, index),
        secondsFromNow: cue.offsetSeconds - elapsedSeconds,
      ),
    );
  }
  return planned;
}

int stableNotificationId(String sessionId, int offset) {
  return (sessionId.hashCode ^ offset.hashCode) & 0x7fffffff;
}

class NotificationService {
  NotificationService()
    : _plugin = FlutterLocalNotificationsPlugin(),
      _scheduledIds = <int>[];

  final FlutterLocalNotificationsPlugin _plugin;
  final List<int> _scheduledIds;
  final _answers = StreamController<GoalCheckAnswer>.broadcast();
  var _initialized = false;

  /// Answers chosen from goal-check notification buttons.
  Stream<GoalCheckAnswer> get goalCheckAnswers => _answers.stream;

  /// Routes a notification response to [goalCheckAnswers]. Plain taps and
  /// other notifications are ignored.
  @visibleForTesting
  void handleResponse(NotificationResponse response) {
    final answer = parseGoalCheckAnswer(
      actionId: response.actionId,
      payload: response.payload,
    );
    if (answer != null) _answers.add(answer);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [goalCheckCategory],
    );
    final settings = InitializationSettings(iOS: darwin);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: handleResponse,
    );
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
    for (final check in plannedGoalCheckNotifications(
      sessionId: sessionId,
      cues: cues,
      elapsedSeconds: elapsedSeconds,
    )) {
      _scheduledIds.add(check.id);
      await _plugin.zonedSchedule(
        id: check.id,
        title: '目标检查',
        body: settings.sessionGoal.isEmpty
            ? '还在做刚才决定的事吗？可忽略；未响应不会被视为失败。'
            : '当前目标：${settings.sessionGoal}',
        scheduledDate: tz.TZDateTime.from(
          now.add(Duration(seconds: check.secondsFromNow)),
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
            categoryIdentifier: goalCheckNotificationCategory,
          ),
        ),
        payload: check.promptId,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    final remainingFocus = settings.focusDurationSeconds - elapsedSeconds;
    if (remainingFocus > 0) {
      final endId = stableNotificationId(sessionId, 999999);
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

  /// Removes a goal-check notification once its check has been answered in
  /// the app, so its now-stale buttons cannot be pressed later.
  Future<void> clearGoalCheck({
    required String sessionId,
    required int offsetSeconds,
  }) async {
    final id = stableNotificationId(sessionId, offsetSeconds);
    if (!_scheduledIds.remove(id)) return;
    await initialize();
    await _plugin.cancel(id: id);
  }
}
