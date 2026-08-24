import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class SettingsStore {
  SettingsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _settingsKey = 'focus.settings.v1';

  final SharedPreferencesAsync _preferences;

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
  SessionStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _sessionsKey = 'focus.sessions.v1';

  final SharedPreferencesAsync _preferences;

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

  Future<void> clear() {
    return _preferences.remove(_sessionsKey);
  }
}
