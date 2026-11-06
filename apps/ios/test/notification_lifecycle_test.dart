import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_cue_focus/focus_engine.dart';
import 'package:random_cue_focus/models.dart';
import 'package:random_cue_focus/notification_service.dart';
import 'package:random_cue_focus/stores.dart';

const _settings = FocusSettings(
  focusDurationMinutes: 15,
  minPromptIntervalMinutes: 5,
  maxPromptIntervalMinutes: 5,
  lockScreenNotifications: true,
  adaptiveCadence: false,
);

const _cues = [PromptCue(offsetSeconds: 300), PromptCue(offsetSeconds: 600)];

Future<void> _schedule(
  NotificationService service,
  String sessionId, {
  FocusSettings settings = _settings,
}) => service.scheduleFocusFallback(
  sessionId: sessionId,
  settings: settings,
  cues: _cues,
  elapsedSeconds: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NotificationCenter center;
  late TestDefaultBinaryMessenger messenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    center = _NotificationCenter();
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      _NotificationCenter.plugin,
      center.handlePlugin,
    );
    messenger.setMockMethodCallHandler(
      _NotificationCenter.queue,
      center.handleQueue,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (_) async => {'identifier': center.timezoneIdentifier},
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(_NotificationCenter.plugin, null);
    messenger.setMockMethodCallHandler(_NotificationCenter.queue, null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      null,
    );
  });

  test(
    'a new instance cancels all three reminders from the old instance',
    () async {
      center.addUnrelated();
      await _schedule(NotificationService(), 'A');
      expect(center.focus, hasLength(3));

      final restarted = NotificationService();
      await restarted.cancelScheduled();
      await restarted.cancelScheduled();

      expect(center.focus, isEmpty);
      expect(center.pending.keys, ['1073741824']);
    },
  );

  test(
    'starting B after restart replaces A without duplicate reminders',
    () async {
      center.addUnrelated();
      await _schedule(NotificationService(), 'A');
      await _schedule(
        NotificationService(),
        'B',
        settings: _settings.copyWith(sessionGoal: 'session B'),
      );

      expect(center.focus, hasLength(3));
      expect(
        center.focus.where((reminder) => reminder['body'] == '当前目标：session B'),
        hasLength(2),
      );
      expect(center.pending['1073741824']?['title'], '目标检查');
    },
  );

  test(
    'pause then immediate resume waits for cancellation before scheduling',
    () async {
      final engine = FocusEngine(
        settings: _settings,
        settingsStore: SettingsStore(preferences: _MemoryPreferences()),
        sessionStore: SessionStore(preferences: _MemoryPreferences()),
        notificationService: NotificationService(),
      );
      addTearDown(engine.dispose);
      await engine.startFocus();
      expect(center.focus, hasLength(3));
      final originalIds = center.focus.map((data) => data['id']).toSet();

      final cancellation = center.blockNextCancellation();
      engine.pause();
      await cancellation.entered.future;
      final resumed = engine.resume();
      // Let any competing method calls run while the old removal is blocked.
      await Future<void>.delayed(Duration.zero);
      final callsDuringRemoval = center.callsWhileBlocked;
      cancellation.release.complete();
      await resumed;

      expect(callsDuringRemoval, isEmpty);
      expect(engine.phase, SessionPhase.focusing);
      expect(center.focus, hasLength(3));
      expect(
        originalIds.intersection(
          center.focus.map((data) => data['id']).toSet(),
        ),
        isEmpty,
      );
    },
  );

  test(
    'cold cleanup also recognizes pre-upgrade reminders without a payload',
    () async {
      center.addUnrelated();
      center.pending['41'] = {
        'title': '目标检查',
        'platformSpecifics': {'threadIdentifier': 'random-cue-focus'},
      };
      center.pending['42'] = {
        'title': '专注结束',
        'platformSpecifics': {'threadIdentifier': 'random-cue-focus'},
        'payload': '',
      };
      await NotificationService().cancelScheduled();
      expect(center.pending.keys, ['1073741824']);
      expect(center.permissionRequests, 0);
    },
  );

  test(
    'disabled and denied reminders clean the old plan without adding a new one',
    () async {
      await _schedule(NotificationService(), 'A');
      final restarted = NotificationService();
      await _schedule(
        restarted,
        'B',
        settings: _settings.copyWith(lockScreenNotifications: false),
      );
      expect(center.focus, isEmpty);
      expect(center.permissionRequests, 1);

      center.grantPermission = false;
      await _schedule(restarted, 'C');
      expect(center.focus, isEmpty);
      expect(center.permissionRequests, 2);
    },
  );

  test(
    'a partial add is rolled back even when the failed add reached iOS',
    () async {
      center.addUnrelated();
      center.failScheduleAt = 2;
      final service = NotificationService();
      await expectLater(
        _schedule(service, 'A'),
        throwsA(isA<PlatformException>()),
      );
      expect(center.pending.keys, ['1073741824']);

      await _schedule(service, 'B');
      expect(center.focus, hasLength(3));
      expect(center.focus.map((data) => data['payload']).toSet(), {
        'random-cue-focus:v1:B',
      });
    },
  );

  test('an unknown timezone still allows reminders using UTC', () async {
    center.timezoneIdentifier = 'Unknown/Timezone';
    await _schedule(NotificationService(), 'A');
    expect(center.focus, hasLength(3));
    expect(center.focus.map((data) => data['timeZoneName']).toSet(), {
      'Etc/UTC',
    });
  });

  test(
    'a new instance recovers a partial add left by interrupted cleanup',
    () async {
      center.addUnrelated();
      center.failScheduleAt = 2;
      center.failRemoval = true;
      await expectLater(
        _schedule(NotificationService(), 'A'),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'add-failed',
          ),
        ),
      );
      expect(center.focus, hasLength(2));

      center.failRemoval = false;
      await NotificationService().cancelScheduled();
      expect(center.pending.keys, ['1073741824']);
    },
  );

  test(
    'partial cancellation is verified and retried before replacement',
    () async {
      final service = NotificationService();
      await _schedule(service, 'A');
      center.partialRemovalOnce = true;
      await _schedule(service, 'B');
      expect(center.removeCalls, 2);
      expect(center.focus, hasLength(3));
      expect(center.focus.map((data) => data['payload']).toSet(), {
        'random-cue-focus:v1:B',
      });
    },
  );

  test(
    'a persistent survivor prevents replacement and a later retry recovers',
    () async {
      final service = NotificationService();
      await _schedule(service, 'A');
      center.keepLastOnRemoval = true;
      await expectLater(_schedule(service, 'B'), throwsStateError);
      expect(center.focus.single['payload'], 'random-cue-focus:v1:A');
      expect(center.scheduleCalls, 3);
      expect(center.removeCalls, 3);

      center.keepLastOnRemoval = false;
      await _schedule(NotificationService(), 'C');
      expect(center.focus, hasLength(3));
      expect(center.focus.map((data) => data['payload']).toSet(), {
        'random-cue-focus:v1:C',
      });
    },
  );

  test(
    'a pause supersedes remaining adds in a plan already in flight',
    () async {
      final engine = FocusEngine(
        settings: _settings,
        settingsStore: SettingsStore(preferences: _MemoryPreferences()),
        sessionStore: SessionStore(preferences: _MemoryPreferences()),
        notificationService: NotificationService(),
      );
      addTearDown(engine.dispose);

      final gate = center.blockNextSchedule();
      final started = engine.startFocus();
      await gate.entered.future;
      engine.pause();
      final resumed = engine.resume();
      gate.release.complete();
      await Future.wait([started, resumed]);

      expect(center.scheduleCalls, 4);
      expect(center.focus, hasLength(3));
      expect(engine.phase, SessionPhase.focusing);
    },
  );

  test('enabling reminders while paused waits until resume', () async {
    final engine = FocusEngine(
      settings: _settings.copyWith(lockScreenNotifications: false),
      settingsStore: SettingsStore(preferences: _MemoryPreferences()),
      sessionStore: SessionStore(preferences: _MemoryPreferences()),
      notificationService: NotificationService(),
    );
    addTearDown(engine.dispose);
    await engine.startFocus();
    engine.pause();
    await engine.updateSettings(_settings);
    expect(center.permissionRequests, 0);
    expect(center.focus, isEmpty);

    await engine.resume();
    expect(center.focus, hasLength(3));
  });

  test(
    'stop records the session even when notification cleanup fails',
    () async {
      final store = SessionStore(preferences: _MemoryPreferences());
      final historical = FocusSession(
        id: 'previous',
        startedAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 1, 1, 0, 15),
        plannedFocusSeconds: 900,
        focusSeconds: 900,
        restSeconds: 0,
        completed: true,
        modeName: 'test',
        promptEvents: const [],
      );
      await store.appendSession(historical);
      final engine = FocusEngine(
        settings: _settings,
        settingsStore: SettingsStore(preferences: _MemoryPreferences()),
        sessionStore: store,
        notificationService: NotificationService(),
      );
      addTearDown(engine.dispose);
      await engine.startFocus();
      engine.advanceForTesting(300);
      engine.skipPrompt();
      center.failRemoval = true;
      await engine.stop();

      expect(engine.phase, SessionPhase.idle);
      final sessions = await store.loadSessions();
      expect(sessions, hasLength(2));
      expect(sessions.first.encode(), historical.encode());
      expect(sessions.last.completed, isFalse);
      expect(sessions.last.promptEvents.last.type, PromptResponseType.skipped);
      expect(center.focus, hasLength(3));

      center.failRemoval = false;
      await engine.startFocus();
      expect(center.focus, hasLength(3));
    },
  );
}

class _NotificationCenter {
  static const plugin = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  static const queue = MethodChannel('random_cue_focus/pending_notifications');

  final pending = <String, Map<Object?, Object?>>{};
  final callsWhileBlocked = <String>[];
  _OperationGate? _removeGate;
  _OperationGate? _scheduleGate;
  var permissionRequests = 0;
  var scheduleCalls = 0;
  var removeCalls = 0;
  var grantPermission = true;
  var timezoneIdentifier = 'Asia/Shanghai';
  int? failScheduleAt;
  var failRemoval = false;
  var partialRemovalOnce = false;
  var keepLastOnRemoval = false;

  Iterable<Map<Object?, Object?>> get focus => pending.values.where(_isFocus);

  void addUnrelated() {
    pending['1073741824'] = {'title': '目标检查', 'body': 'Unrelated reminder'};
  }

  bool _isFocus(Map<Object?, Object?> data) {
    final details = data['platformSpecifics'] as Map?;
    return details?['threadIdentifier'] == 'random-cue-focus';
  }

  _OperationGate blockNextCancellation() => _removeGate = _OperationGate();

  _OperationGate blockNextSchedule() => _scheduleGate = _OperationGate();

  Future<Object?> handlePlugin(MethodCall call) async {
    _recordOverlap(call);
    switch (call.method) {
      case 'initialize':
        return true;
      case 'requestPermissions':
        permissionRequests++;
        return grantPermission;
      case 'zonedSchedule':
        scheduleCalls++;
        final gate = _scheduleGate;
        if (gate != null) {
          _scheduleGate = null;
          gate.entered.complete();
          await gate.release.future;
        }
        final data = call.arguments as Map<Object?, Object?>;
        pending['${data['id']}'] = data;
        if (failScheduleAt == scheduleCalls) {
          throw PlatformException(code: 'add-failed');
        }
        return null;
      case 'cancel':
        await _remove(['${call.arguments}']);
        return null;
      default:
        throw MissingPluginException(call.method);
    }
  }

  Future<Object?> handleQueue(MethodCall call) async {
    _recordOverlap(call);
    switch (call.method) {
      case 'pending':
        return pending.map((id, data) => MapEntry(id, _isFocus(data)));
      case 'removePendingFocus':
        await _remove(
          pending.keys.where((id) => _isFocus(pending[id]!)).toList(),
        );
        return null;
      default:
        throw MissingPluginException(call.method);
    }
  }

  void _recordOverlap(MethodCall call) {
    final gate = _removeGate;
    if (gate != null && gate.entered.isCompleted && !gate.release.isCompleted) {
      callsWhileBlocked.add(call.method);
    }
  }

  Future<void> _remove(List<String> ids) async {
    removeCalls++;
    final gate = _removeGate;
    if (gate != null && !gate.entered.isCompleted) {
      gate.entered.complete();
      await gate.release.future;
      _removeGate = null;
    }
    if (failRemoval) throw PlatformException(code: 'remove-failed');
    if ((partialRemovalOnce || keepLastOnRemoval) && ids.isNotEmpty) {
      partialRemovalOnce = false;
      ids = ids.take(ids.length - 1).toList();
    }
    ids.forEach(pending.remove);
  }
}

class _OperationGate {
  final entered = Completer<void>();
  final release = Completer<void>();
}

class _MemoryPreferences implements PreferencesBackend {
  final _values = <String, Object>{};

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<List<String>?> getStringList(String key) async =>
      _values[key] as List<String>?;

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _values[key] = List.of(value);
  }
}
