import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_cue_focus_windows/models.dart';
import 'package:random_cue_focus_windows/repositories.dart';

void main() {
  late Directory directory;
  late SessionRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('随机目标-');
    repository = SessionRepository(baseDirectory: directory);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'atomic settings writes preserve unrelated fields and clean artifacts',
    () async {
      const original = FocusSettings(
        focusDurationMinutes: 75,
        restDurationMinutes: 15,
        notificationsEnabled: true,
        foregroundPromptSoundEnabled: true,
      );
      await repository.saveSettings(original);
      await repository.saveSettings(
        original.copyWith(sessionGoal: '  完成持久化测试  '),
      );

      final loaded = await repository.loadSettings();
      expect(loaded.sessionGoal, '完成持久化测试');
      expect(loaded.focusDurationMinutes, 75);
      expect(loaded.restDurationMinutes, 15);
      expect(loaded.notificationsEnabled, isTrue);
      expect(loaded.foregroundPromptSoundEnabled, isTrue);
      expect(
        File('${directory.path}\\settings.json.tmp').existsSync(),
        isFalse,
      );
      expect(
        File('${directory.path}\\settings.json.backup').existsSync(),
        isFalse,
      );
    },
  );

  test('valid backup restores settings when the primary is corrupt', () async {
    final target = File('${directory.path}\\settings.json');
    final backup = File('${target.path}.backup');
    await target.writeAsString('not-json', flush: true);
    await backup.writeAsString(
      const FocusSettings(sessionGoal: '来自备份').encode(),
      flush: true,
    );

    final loaded = await repository.loadSettings();
    expect(loaded.sessionGoal, '来自备份');
  });

  test('one corrupt session record does not hide valid history', () async {
    final valid = _session('valid');
    await File(
      '${directory.path}\\sessions.json',
    ).writeAsString(jsonEncode([valid.encode(), 'not-json']), flush: true);

    final loaded = await repository.loadSessions();
    expect(loaded.map((session) => session.id), ['valid']);
  });

  test(
    'session append uses the non-ASCII directory and leaves no artifacts',
    () async {
      await repository.appendSession(_session('one'));
      await repository.appendSession(_session('two'));

      expect((await repository.loadSessions()).length, 2);
      expect(
        File('${directory.path}\\sessions.json.tmp').existsSync(),
        isFalse,
      );
      expect(
        File('${directory.path}\\sessions.json.backup').existsSync(),
        isFalse,
      );
    },
  );

  test(
    'session outcome update is atomic and preserves session facts',
    () async {
      final original = _session('one');
      await repository.appendSession(original);

      await repository.updateSessionOutcome(
        'one',
        SessionOutcomeReport(
          meaningfulProgress: MeaningfulProgressResponse.no,
          interruptionBurden: 4,
          answeredAt: DateTime(2026, 1, 1, 1),
        ),
      );

      final updated = (await repository.loadSessions()).single;
      expect(updated.focusSeconds, original.focusSeconds);
      expect(
        updated.outcomeReport!.meaningfulProgress,
        MeaningfulProgressResponse.no,
      );
      expect(updated.outcomeReport!.interruptionBurden, 4);
      expect(
        File('${directory.path}\\sessions.json.tmp').existsSync(),
        isFalse,
      );
    },
  );
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
