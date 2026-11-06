import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

class NotificationService {
  static const _pendingNotifications = MethodChannel(
    'random_cue_focus/pending_notifications',
  );
  static const _notificationDetails = NotificationDetails(
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
      threadIdentifier: 'random-cue-focus',
    ),
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  var _initialized = false;
  Future<void> _queue = Future<void>.value();
  Object? _latestCommand;
  int _nextNotificationId = 0x40000000;

  Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
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

  Future<void> cancelScheduled() => _enqueue((_) async {
    await _clearPendingFocus();
  });

  Future<void> scheduleFocusFallback({
    required String sessionId,
    required FocusSettings settings,
    required List<PromptCue> cues,
    required int elapsedSeconds,
  }) {
    final requestedAt = DateTime.now();
    final futureCues = cues
        .where((cue) => cue.offsetSeconds > elapsedSeconds)
        .take(48)
        .toList();
    return _enqueue((command) async {
      final occupiedIds = await _clearPendingFocus();
      if (!settings.lockScreenNotifications || command != _latestCommand) {
        return;
      }

      await _initialize();
      if (command != _latestCommand) return;
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: false);
      if (granted != true || command != _latestCommand) return;

      Future<void> schedule(int offset, String title, String body) async {
        final deadline = requestedAt.add(
          Duration(seconds: offset - elapsedSeconds),
        );
        if (command != _latestCommand || !deadline.isAfter(DateTime.now())) {
          return;
        }
        await _plugin.zonedSchedule(
          id: _allocateId(occupiedIds),
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(deadline, tz.local),
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'random-cue-focus:v1:$sessionId',
        );
      }

      try {
        for (final cue in futureCues) {
          if (command != _latestCommand) return;
          await schedule(
            cue.offsetSeconds,
            '目标检查',
            settings.sessionGoal.isEmpty
                ? '还在做刚才决定的事吗？可忽略；未响应不会被视为失败。'
                : '当前目标：${settings.sessionGoal}',
          );
        }
        await schedule(
          settings.focusDurationSeconds,
          '专注结束',
          '这一轮计时已结束。你可以休息，或先记录下一步。',
        );
      } catch (_) {
        // A failed add may already have reached iOS. Reconcile by ownership.
        try {
          await _clearPendingFocus();
        } catch (error) {
          debugPrint('Notification rollback failed: $error');
        }
        rethrow;
      }
    });
  }

  Future<void> _enqueue(Future<void> Function(Object) operation) {
    final command = Object();
    _latestCommand = command;
    final result = _queue.then((_) => operation(command));
    // Report the original failure to the caller and keep accepting commands.
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<Set<String>> _clearPendingFocus() async {
    var pending = await _readPending();
    for (
      var attempt = 0;
      pending.containsValue(true) && attempt < 3;
      attempt++
    ) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await _pendingNotifications.invokeMethod<void>('removePendingFocus');
      pending = await _readPending();
    }
    if (pending.containsValue(true)) {
      throw StateError('Focus reminders are still pending after cancellation.');
    }
    return pending.keys.toSet();
  }

  Future<Map<String, bool>> _readPending() async {
    final pending = await _pendingNotifications.invokeMapMethod<String, bool>(
      'pending',
    );
    if (pending == null) {
      throw StateError('iOS did not return the pending notification queue.');
    }
    return pending;
  }

  int _allocateId(Set<String> occupiedIds) {
    // Avoid IDs currently used by any other pending notification and avoid
    // reusing IDs from an earlier plan in the same process.
    while (true) {
      final id = _nextNotificationId;
      _nextNotificationId = id == 0x7fffffff ? 0x40000000 : id + 1;
      if (occupiedIds.add(id.toString())) return id;
    }
  }
}
