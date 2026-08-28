import 'package:flutter_test/flutter_test.dart';
import 'package:random_cue_focus/models.dart';
import 'package:random_cue_focus/stores.dart';

void main() {
  test('settings store migrates legacy notification keys', () async {
    final preferences = _MemoryPreferences({
      'focus.settings.v1':
          '{"focusDurationMinutes":25,"lockScreenNotifications":true}',
    });

    final settings = await SettingsStore(preferences: preferences).load();
    expect(settings.focusDurationMinutes, 25);
    expect(settings.notificationsEnabled, isTrue);
  });

  test('one corrupt session does not hide valid history', () async {
    final valid = _session('valid').encode();
    final preferences = _MemoryPreferences({
      'focus.sessions.v1': <String>[valid, 'not-json', valid],
    });

    final sessions = await SessionStore(
      preferences: preferences,
    ).loadSessions();
    expect(sessions.map((session) => session.id), ['valid', 'valid']);
  });

  test('session outcome update preserves the rest of the session', () async {
    final original = _session('one');
    final preferences = _MemoryPreferences({
      'focus.sessions.v1': <String>[original.encode()],
    });
    final store = SessionStore(preferences: preferences);

    await store.updateSessionOutcome(
      'one',
      SessionOutcomeReport(
        meaningfulProgress: MeaningfulProgressResponse.yes,
        interruptionBurden: 2,
        answeredAt: DateTime(2026, 1, 1, 1),
      ),
    );

    final updated = (await store.loadSessions()).single;
    expect(updated.focusSeconds, original.focusSeconds);
    expect(
      updated.outcomeReport!.meaningfulProgress,
      MeaningfulProgressResponse.yes,
    );
    expect(updated.outcomeReport!.interruptionBurden, 2);
  });
}

class _MemoryPreferences implements PreferencesBackend {
  _MemoryPreferences(Map<String, Object> values) : _values = Map.of(values);

  final Map<String, Object> _values;

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = _values[key] as List<String>?;
    return value == null ? null : List.of(value);
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _values[key] = List.of(value);
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

FocusSession _session(String id) {
  return FocusSession(
    id: id,
    startedAt: DateTime(2026, 1, 1),
    endedAt: DateTime(2026, 1, 1, 1),
    plannedFocusSeconds: 600,
    focusSeconds: 300,
    restSeconds: 0,
    completed: false,
    modeName: 'test',
    promptEvents: const [],
  );
}
