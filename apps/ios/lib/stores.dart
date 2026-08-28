import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

abstract interface class PreferencesBackend {
  Future<String?> getString(String key);
  Future<List<String>?> getStringList(String key);
  Future<void> setString(String key, String value);
  Future<void> setStringList(String key, List<String> value);
  Future<void> remove(String key);
}

class SharedPreferencesBackend implements PreferencesBackend {
  SharedPreferencesBackend({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<List<String>?> getStringList(String key) {
    return _preferences.getStringList(key);
  }

  @override
  Future<void> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  @override
  Future<void> setStringList(String key, List<String> value) {
    return _preferences.setStringList(key, value);
  }

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}

class SettingsStore {
  SettingsStore({PreferencesBackend? preferences})
    : _preferences = preferences ?? SharedPreferencesBackend();

  static const _settingsKey = 'focus.settings.v1';

  final PreferencesBackend _preferences;

  Future<FocusSettings> load() async {
    final raw = await _preferences.getString(_settingsKey);
    if (raw == null) return const FocusSettings();
    try {
      return FocusSettings.decode(raw);
    } catch (_) {
      return const FocusSettings();
    }
  }

  Future<void> save(FocusSettings settings) {
    return _preferences.setString(_settingsKey, settings.normalized().encode());
  }
}

class SessionStore {
  SessionStore({PreferencesBackend? preferences})
    : _preferences = preferences ?? SharedPreferencesBackend();

  static const _sessionsKey = 'focus.sessions.v1';

  final PreferencesBackend _preferences;

  Future<List<FocusSession>> loadSessions() async {
    final raw = await _preferences.getStringList(_sessionsKey) ?? const [];
    final sessions = <FocusSession>[];
    for (final value in raw) {
      try {
        sessions.add(FocusSession.decode(value));
      } catch (_) {
        continue;
      }
    }
    sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return sessions;
  }

  Future<void> appendSession(FocusSession session) async {
    final sessions = await loadSessions();
    sessions.add(session);
    final trimmed = sessions.length > 500
        ? sessions.sublist(sessions.length - 500)
        : sessions;
    await _preferences.setStringList(
      _sessionsKey,
      trimmed.map((entry) => entry.encode()).toList(),
    );
  }

  Future<void> updateSessionOutcome(
    String sessionId,
    SessionOutcomeReport outcome,
  ) async {
    final sessions = await loadSessions();
    final index = sessions.indexWhere((session) => session.id == sessionId);
    if (index < 0) return;
    sessions[index] = sessions[index].copyWith(outcomeReport: outcome);
    await _preferences.setStringList(
      _sessionsKey,
      sessions.map((entry) => entry.encode()).toList(),
    );
  }

  Future<void> clear() {
    return _preferences.remove(_sessionsKey);
  }
}
