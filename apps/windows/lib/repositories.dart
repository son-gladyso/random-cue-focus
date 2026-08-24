import 'dart:convert';
import 'dart:io';

import 'models.dart';

class SessionRepository {
  SessionRepository({Directory? baseDirectory})
    : _baseDirectory = baseDirectory ?? _defaultBaseDirectory();

  final Directory _baseDirectory;

  File get _settingsFile => File('${_baseDirectory.path}\\settings.json');
  File get _sessionsFile => File('${_baseDirectory.path}\\sessions.json');

  Future<FocusSettings> loadSettings() async {
    try {
      final raw = await _settingsFile.readAsString();
      return FocusSettings.decode(raw);
    } catch (_) {
      return const FocusSettings();
    }
  }

  Future<void> saveSettings(FocusSettings settings) async {
    await _ensureDirectory();
    await _settingsFile.writeAsString(settings.normalized().encode());
  }

  Future<List<FocusSession>> loadSessions() async {
    try {
      final raw = await _sessionsFile.readAsString();
      final values = (jsonDecode(raw) as List).whereType<String>();
      final sessions = <FocusSession>[];
      for (final value in values) {
        try {
          sessions.add(FocusSession.decode(value));
        } catch (_) {
          continue;
        }
      }
      sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
      return sessions;
    } catch (_) {
      return const [];
    }
  }

  Future<void> appendSession(FocusSession session) async {
    await _ensureDirectory();
    final sessions = await loadSessions();
    sessions.add(session);
    final trimmed = sessions.length > 1000
        ? sessions.sublist(sessions.length - 1000)
        : sessions;
    await _sessionsFile.writeAsString(
      jsonEncode(trimmed.map((entry) => entry.encode()).toList()),
    );
  }

  Future<void> clearSessions() async {
    if (await _sessionsFile.exists()) {
      await _sessionsFile.delete();
    }
  }

  Future<void> _ensureDirectory() async {
    if (!await _baseDirectory.exists()) {
      await _baseDirectory.create(recursive: true);
    }
  }
}

Directory _defaultBaseDirectory() {
  final appData = Platform.environment['APPDATA'];
  if (appData != null && appData.isNotEmpty) {
    return Directory('$appData\\RandomCueFocusWindows');
  }
  return Directory('${Directory.current.path}\\data');
}

class StatsSummary {
  const StatsSummary({
    required this.todaySeconds,
    required this.totalSeconds,
    required this.completedSessions,
    required this.totalSessions,
    required this.promptCount,
    required this.skipCount,
    required this.hourSeconds,
  });

  final int todaySeconds;
  final int totalSeconds;
  final int completedSessions;
  final int totalSessions;
  final int promptCount;
  final int skipCount;
  final List<int> hourSeconds;

  int get completionPercent {
    if (totalSessions == 0) return 0;
    return (completedSessions / totalSessions * 100).round();
  }
}

class StatsQueryService {
  const StatsQueryService();

  StatsSummary summarize(List<FocusSession> sessions, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final hours = List<int>.filled(24, 0);
    var todaySeconds = 0;
    var totalSeconds = 0;
    var completed = 0;
    var promptCount = 0;
    var skipCount = 0;

    for (final session in sessions) {
      totalSeconds += session.focusSeconds;
      hours[session.startedAt.hour] += session.focusSeconds;
      promptCount += session.promptEvents.length;
      skipCount += session.promptEvents
          .where((event) => event.type == PromptResponseType.skipped)
          .length;
      if (session.completed) completed += 1;
      if (session.startedAt.year == clock.year &&
          session.startedAt.month == clock.month &&
          session.startedAt.day == clock.day) {
        todaySeconds += session.focusSeconds;
      }
    }

    return StatsSummary(
      todaySeconds: todaySeconds,
      totalSeconds: totalSeconds,
      completedSessions: completed,
      totalSessions: sessions.length,
      promptCount: promptCount,
      skipCount: skipCount,
      hourSeconds: hours,
    );
  }
}
