import 'dart:convert';

enum SessionPhase { idle, focusing, paused, microBreak, resting, completed }

enum SoundPreset { softBell, gentleTap, clearChime, piano }

extension SoundPresetLabel on SoundPreset {
  String get label {
    switch (this) {
      case SoundPreset.softBell:
        return '铃声';
      case SoundPreset.gentleTap:
        return '轻提';
      case SoundPreset.clearChime:
        return '清铃';
      case SoundPreset.piano:
        return '钢琴';
    }
  }
}

class FocusSettings {
  const FocusSettings({
    this.focusDurationMinutes = 90,
    this.restDurationMinutes = 20,
    this.minPromptIntervalMinutes = 3,
    this.maxPromptIntervalMinutes = 5,
    this.microBreakSeconds = 10,
    this.lockScreenNotifications = true,
    this.foregroundPromptSoundEnabled = true,
    this.soundPreset = SoundPreset.softBell,
    this.modeName = '随机提示音',
  });

  final int focusDurationMinutes;
  final int restDurationMinutes;
  final int minPromptIntervalMinutes;
  final int maxPromptIntervalMinutes;
  final int microBreakSeconds;
  final bool lockScreenNotifications;
  final bool foregroundPromptSoundEnabled;
  final SoundPreset soundPreset;
  final String modeName;

  int get focusDurationSeconds => focusDurationMinutes * 60;
  int get restDurationSeconds => restDurationMinutes * 60;
  int get minPromptIntervalSeconds => minPromptIntervalMinutes * 60;
  int get maxPromptIntervalSeconds => maxPromptIntervalMinutes * 60;

  FocusSettings normalized() {
    final focus = focusDurationMinutes.clamp(5, 240).toInt();
    final rest = restDurationMinutes.clamp(1, 60).toInt();
    final minInterval = minPromptIntervalMinutes.clamp(1, 30).toInt();
    final maxInterval = maxPromptIntervalMinutes.clamp(minInterval, 45).toInt();
    final micro = microBreakSeconds.clamp(3, 60).toInt();
    return FocusSettings(
      focusDurationMinutes: focus,
      restDurationMinutes: rest,
      minPromptIntervalMinutes: minInterval,
      maxPromptIntervalMinutes: maxInterval,
      microBreakSeconds: micro,
      lockScreenNotifications: lockScreenNotifications,
      foregroundPromptSoundEnabled: foregroundPromptSoundEnabled,
      soundPreset: soundPreset,
      modeName: modeName,
    );
  }

  FocusSettings copyWith({
    int? focusDurationMinutes,
    int? restDurationMinutes,
    int? minPromptIntervalMinutes,
    int? maxPromptIntervalMinutes,
    int? microBreakSeconds,
    bool? lockScreenNotifications,
    bool? foregroundPromptSoundEnabled,
    SoundPreset? soundPreset,
    String? modeName,
  }) {
    return FocusSettings(
      focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
      restDurationMinutes: restDurationMinutes ?? this.restDurationMinutes,
      minPromptIntervalMinutes:
          minPromptIntervalMinutes ?? this.minPromptIntervalMinutes,
      maxPromptIntervalMinutes:
          maxPromptIntervalMinutes ?? this.maxPromptIntervalMinutes,
      microBreakSeconds: microBreakSeconds ?? this.microBreakSeconds,
      lockScreenNotifications:
          lockScreenNotifications ?? this.lockScreenNotifications,
      foregroundPromptSoundEnabled:
          foregroundPromptSoundEnabled ?? this.foregroundPromptSoundEnabled,
      soundPreset: soundPreset ?? this.soundPreset,
      modeName: modeName ?? this.modeName,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'focusDurationMinutes': focusDurationMinutes,
      'restDurationMinutes': restDurationMinutes,
      'minPromptIntervalMinutes': minPromptIntervalMinutes,
      'maxPromptIntervalMinutes': maxPromptIntervalMinutes,
      'microBreakSeconds': microBreakSeconds,
      'lockScreenNotifications': lockScreenNotifications,
      'foregroundPromptSoundEnabled': foregroundPromptSoundEnabled,
      'soundPreset': soundPreset.name,
      'modeName': modeName,
    };
  }

  factory FocusSettings.fromJson(Map<String, Object?> json) {
    return FocusSettings(
      focusDurationMinutes:
          (json['focusDurationMinutes'] as num?)?.toInt() ?? 90,
      restDurationMinutes: (json['restDurationMinutes'] as num?)?.toInt() ?? 20,
      minPromptIntervalMinutes:
          (json['minPromptIntervalMinutes'] as num?)?.toInt() ?? 3,
      maxPromptIntervalMinutes:
          (json['maxPromptIntervalMinutes'] as num?)?.toInt() ?? 5,
      microBreakSeconds: (json['microBreakSeconds'] as num?)?.toInt() ?? 10,
      lockScreenNotifications: json['lockScreenNotifications'] as bool? ?? true,
      foregroundPromptSoundEnabled:
          json['foregroundPromptSoundEnabled'] as bool? ?? true,
      soundPreset: SoundPreset.values.firstWhere(
        (preset) => preset.name == json['soundPreset'],
        orElse: () => SoundPreset.softBell,
      ),
      modeName: json['modeName'] as String? ?? '随机提示音',
    ).normalized();
  }

  String encode() => jsonEncode(toJson());

  factory FocusSettings.decode(String value) {
    return FocusSettings.fromJson(jsonDecode(value) as Map<String, Object?>);
  }
}

class PromptCue {
  const PromptCue({required this.offsetSeconds});

  final int offsetSeconds;

  Map<String, Object?> toJson() => {'offsetSeconds': offsetSeconds};

  factory PromptCue.fromJson(Map<String, Object?> json) {
    return PromptCue(
      offsetSeconds: (json['offsetSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class PromptEvent {
  const PromptEvent({
    required this.elapsedSeconds,
    required this.occurredAt,
    required this.event,
  });

  final int elapsedSeconds;
  final DateTime occurredAt;
  final String event;

  Map<String, Object?> toJson() {
    return {
      'elapsedSeconds': elapsedSeconds,
      'occurredAt': occurredAt.toIso8601String(),
      'event': event,
    };
  }

  factory PromptEvent.fromJson(Map<String, Object?> json) {
    return PromptEvent(
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      event: json['event'] as String? ?? 'cue',
    );
  }
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.plannedFocusSeconds,
    required this.focusSeconds,
    required this.restSeconds,
    required this.completed,
    required this.modeName,
    required this.promptEvents,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int plannedFocusSeconds;
  final int focusSeconds;
  final int restSeconds;
  final bool completed;
  final String modeName;
  final List<PromptEvent> promptEvents;

  double get completionRate {
    if (plannedFocusSeconds <= 0) return 0;
    return (focusSeconds / plannedFocusSeconds).clamp(0, 1).toDouble();
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'plannedFocusSeconds': plannedFocusSeconds,
      'focusSeconds': focusSeconds,
      'restSeconds': restSeconds,
      'completed': completed,
      'modeName': modeName,
      'promptEvents': promptEvents.map((event) => event.toJson()).toList(),
    };
  }

  factory FocusSession.fromJson(Map<String, Object?> json) {
    return FocusSession(
      id: json['id'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endedAt:
          DateTime.tryParse(json['endedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      plannedFocusSeconds: (json['plannedFocusSeconds'] as num?)?.toInt() ?? 1,
      focusSeconds: (json['focusSeconds'] as num?)?.toInt() ?? 0,
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      modeName: json['modeName'] as String? ?? '随机提示音',
      promptEvents: ((json['promptEvents'] as List?) ?? const [])
          .whereType<Map>()
          .map((event) => PromptEvent.fromJson(event.cast<String, Object?>()))
          .toList(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory FocusSession.decode(String value) {
    return FocusSession.fromJson(jsonDecode(value) as Map<String, Object?>);
  }
}
