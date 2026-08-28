import 'dart:convert';

import 'study_protocol.dart';

const currentDataSchemaVersion = 6;
const currentAlgorithmVersion = 'sparse-goal-check-v1';

enum SessionPhase { idle, focusing, paused, microBreak, resting, completed }

enum SoundPreset { softBell, gentleTap, clearChime, piano }

enum PromptResponseType {
  shown,
  onTask,
  offTask,
  acknowledged,
  skipped,
  delayed,
  ended,
}

enum AppPlatform { ios, windows, unknown }

enum MeaningfulProgressResponse { yes, no, unsure }

class MeasurementContext {
  const MeasurementContext({
    this.platform = AppPlatform.unknown,
    this.appVersion = 'unknown',
    this.algorithmVersion = currentAlgorithmVersion,
    this.timezoneOffsetMinutes = 0,
    this.plannedPromptOffsets = const [],
    this.adaptiveCadence = false,
    this.cadenceFactor = 1,
    this.cadenceReason = 'not_recorded',
    this.notificationsEnabled = false,
    this.foregroundSoundEnabled = false,
    this.goalChecksEnabled,
    this.minPromptIntervalSeconds,
    this.maxPromptIntervalSeconds,
    this.responseWindowSeconds,
    this.studyAssignment,
  });

  final AppPlatform platform;
  final String appVersion;
  final String algorithmVersion;
  final int timezoneOffsetMinutes;
  final List<int> plannedPromptOffsets;
  final bool adaptiveCadence;
  final double cadenceFactor;
  final String cadenceReason;
  final bool notificationsEnabled;
  final bool foregroundSoundEnabled;
  final bool? goalChecksEnabled;
  final int? minPromptIntervalSeconds;
  final int? maxPromptIntervalSeconds;
  final int? responseWindowSeconds;
  final StudySessionAssignment? studyAssignment;

  MeasurementContext normalized() {
    return MeasurementContext(
      platform: platform,
      appVersion: _bounded(appVersion, 40, fallback: 'unknown'),
      algorithmVersion: _bounded(
        algorithmVersion,
        80,
        fallback: currentAlgorithmVersion,
      ),
      timezoneOffsetMinutes: timezoneOffsetMinutes.clamp(-840, 840).toInt(),
      plannedPromptOffsets: plannedPromptOffsets
          .where((offset) => offset >= 0)
          .take(8)
          .toList(growable: false),
      adaptiveCadence: adaptiveCadence,
      cadenceFactor: cadenceFactor.clamp(0.9, 1.25).toDouble(),
      cadenceReason: _bounded(cadenceReason, 80, fallback: 'not_recorded'),
      notificationsEnabled: notificationsEnabled,
      foregroundSoundEnabled: foregroundSoundEnabled,
      goalChecksEnabled: goalChecksEnabled,
      minPromptIntervalSeconds: minPromptIntervalSeconds
          ?.clamp(300, 3600)
          .toInt(),
      maxPromptIntervalSeconds: maxPromptIntervalSeconds
          ?.clamp(300, 3600)
          .toInt(),
      responseWindowSeconds: responseWindowSeconds?.clamp(5, 180).toInt(),
      studyAssignment: studyAssignment,
    );
  }

  Map<String, Object?> toJson() {
    final value = normalized();
    return {
      'platform': value.platform.name,
      'appVersion': value.appVersion,
      'algorithmVersion': value.algorithmVersion,
      'timezoneOffsetMinutes': value.timezoneOffsetMinutes,
      'plannedPromptOffsets': value.plannedPromptOffsets,
      'adaptiveCadence': value.adaptiveCadence,
      'cadenceFactor': value.cadenceFactor,
      'cadenceReason': value.cadenceReason,
      'notificationsEnabled': value.notificationsEnabled,
      'foregroundSoundEnabled': value.foregroundSoundEnabled,
      'goalChecksEnabled': value.goalChecksEnabled,
      'minPromptIntervalSeconds': value.minPromptIntervalSeconds,
      'maxPromptIntervalSeconds': value.maxPromptIntervalSeconds,
      'responseWindowSeconds': value.responseWindowSeconds,
      'studyAssignment': value.studyAssignment?.toJson(),
    };
  }

  factory MeasurementContext.fromJson(Map<String, Object?> json) {
    return MeasurementContext(
      platform: AppPlatform.values.firstWhere(
        (value) => value.name == json['platform'],
        orElse: () => AppPlatform.unknown,
      ),
      appVersion: json['appVersion'] as String? ?? 'unknown',
      algorithmVersion:
          json['algorithmVersion'] as String? ?? currentAlgorithmVersion,
      timezoneOffsetMinutes:
          (json['timezoneOffsetMinutes'] as num?)?.toInt() ?? 0,
      plannedPromptOffsets:
          ((json['plannedPromptOffsets'] as List?) ?? const [])
              .whereType<num>()
              .map((value) => value.toInt())
              .toList(growable: false),
      adaptiveCadence: json['adaptiveCadence'] as bool? ?? false,
      cadenceFactor: (json['cadenceFactor'] as num?)?.toDouble() ?? 1,
      cadenceReason: json['cadenceReason'] as String? ?? 'not_recorded',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      foregroundSoundEnabled: json['foregroundSoundEnabled'] as bool? ?? false,
      goalChecksEnabled: json['goalChecksEnabled'] as bool?,
      minPromptIntervalSeconds: (json['minPromptIntervalSeconds'] as num?)
          ?.toInt(),
      maxPromptIntervalSeconds: (json['maxPromptIntervalSeconds'] as num?)
          ?.toInt(),
      responseWindowSeconds: (json['responseWindowSeconds'] as num?)?.toInt(),
      studyAssignment: json['studyAssignment'] is Map
          ? StudySessionAssignment.fromJson(
              (json['studyAssignment'] as Map).cast<String, Object?>(),
            )
          : null,
    ).normalized();
  }
}

class SessionOutcomeReport {
  const SessionOutcomeReport({
    this.meaningfulProgress,
    this.interruptionBurden,
    this.answeredAt,
  });

  final MeaningfulProgressResponse? meaningfulProgress;
  final int? interruptionBurden;
  final DateTime? answeredAt;

  bool get hasAnyAnswer =>
      meaningfulProgress != null || interruptionBurden != null;

  SessionOutcomeReport normalized() {
    return SessionOutcomeReport(
      meaningfulProgress: meaningfulProgress,
      interruptionBurden: interruptionBurden?.clamp(0, 4).toInt(),
      answeredAt: answeredAt,
    );
  }

  Map<String, Object?> toJson() {
    final value = normalized();
    return {
      'meaningfulProgress': value.meaningfulProgress?.name,
      'interruptionBurden': value.interruptionBurden,
      'answeredAt': value.answeredAt?.toIso8601String(),
    };
  }

  factory SessionOutcomeReport.fromJson(Map<String, Object?> json) {
    final rawProgress = json['meaningfulProgress'];
    return SessionOutcomeReport(
      meaningfulProgress: _meaningfulProgressFromJson(rawProgress),
      interruptionBurden: (json['interruptionBurden'] as num?)?.toInt(),
      answeredAt: DateTime.tryParse(json['answeredAt'] as String? ?? ''),
    ).normalized();
  }
}

MeaningfulProgressResponse? _meaningfulProgressFromJson(Object? rawValue) {
  for (final value in MeaningfulProgressResponse.values) {
    if (value.name == rawValue) return value;
  }
  return null;
}

extension SoundPresetLabel on SoundPreset {
  String get label {
    switch (this) {
      case SoundPreset.softBell:
        return '柔和铃';
      case SoundPreset.gentleTap:
        return '轻提示';
      case SoundPreset.clearChime:
        return '清亮铃';
      case SoundPreset.piano:
        return '短钢琴';
    }
  }
}

class FocusSettings {
  const FocusSettings({
    this.focusDurationMinutes = 50,
    this.restDurationMinutes = 10,
    this.minPromptIntervalMinutes = 12,
    this.maxPromptIntervalMinutes = 18,
    this.microBreakSeconds = 20,
    bool notificationsEnabled = false,
    bool? lockScreenNotifications,
    bool? desktopNotifications,
    this.trayEnabled = true,
    this.foregroundPromptSoundEnabled = false,
    this.soundPreset = SoundPreset.softBell,
    this.modeName = '稀疏目标检查',
    this.adaptiveCadence = true,
    this.goalChecksEnabled = true,
    this.sessionGoal = '',
    this.distractionTrigger = '我发现自己偏离当前任务',
    this.recoveryAction = '查看当前小目标，并完成下一步最小动作',
    this.learningMode = false,
    this.recallPrompt = '',
    this.studyEnrollment,
  }) : notificationsEnabled =
           lockScreenNotifications ??
           desktopNotifications ??
           notificationsEnabled;

  final int focusDurationMinutes;
  final int restDurationMinutes;
  final int minPromptIntervalMinutes;
  final int maxPromptIntervalMinutes;
  final int microBreakSeconds;
  final bool notificationsEnabled;
  final bool trayEnabled;
  final bool foregroundPromptSoundEnabled;
  final SoundPreset soundPreset;
  final String modeName;
  final bool adaptiveCadence;
  final bool goalChecksEnabled;
  final String sessionGoal;
  final String distractionTrigger;
  final String recoveryAction;
  final bool learningMode;
  final String recallPrompt;
  final StudyEnrollment? studyEnrollment;

  bool get lockScreenNotifications => notificationsEnabled;
  bool get desktopNotifications => notificationsEnabled;
  int get focusDurationSeconds => focusDurationMinutes * 60;
  int get restDurationSeconds => restDurationMinutes * 60;
  int get minPromptIntervalSeconds => minPromptIntervalMinutes * 60;
  int get maxPromptIntervalSeconds => maxPromptIntervalMinutes * 60;

  String get ifThenPlan {
    return '如果${distractionTrigger.trim()}，那么${recoveryAction.trim()}。';
  }

  FocusSettings normalized() {
    final focus = focusDurationMinutes.clamp(10, 240).toInt();
    final rest = restDurationMinutes.clamp(1, 60).toInt();
    final minInterval = minPromptIntervalMinutes.clamp(5, 45).toInt();
    final maxInterval = maxPromptIntervalMinutes.clamp(minInterval, 60).toInt();
    final promptWindow = microBreakSeconds.clamp(5, 180).toInt();

    return FocusSettings(
      focusDurationMinutes: focus,
      restDurationMinutes: rest,
      minPromptIntervalMinutes: minInterval,
      maxPromptIntervalMinutes: maxInterval,
      microBreakSeconds: promptWindow,
      notificationsEnabled: notificationsEnabled,
      trayEnabled: trayEnabled,
      foregroundPromptSoundEnabled: foregroundPromptSoundEnabled,
      soundPreset: soundPreset,
      modeName: _bounded(modeName, 40, fallback: '稀疏目标检查'),
      adaptiveCadence: adaptiveCadence,
      goalChecksEnabled: goalChecksEnabled,
      sessionGoal: _bounded(sessionGoal, 160),
      distractionTrigger: _bounded(
        distractionTrigger,
        160,
        fallback: '我发现自己偏离当前任务',
      ),
      recoveryAction: _bounded(
        recoveryAction,
        160,
        fallback: '查看当前小目标，并完成下一步最小动作',
      ),
      learningMode: learningMode,
      recallPrompt: _bounded(recallPrompt, 240),
      studyEnrollment: studyEnrollment?.normalized(),
    );
  }

  FocusSettings copyWith({
    int? focusDurationMinutes,
    int? restDurationMinutes,
    int? minPromptIntervalMinutes,
    int? maxPromptIntervalMinutes,
    int? microBreakSeconds,
    bool? notificationsEnabled,
    bool? lockScreenNotifications,
    bool? desktopNotifications,
    bool? trayEnabled,
    bool? foregroundPromptSoundEnabled,
    SoundPreset? soundPreset,
    String? modeName,
    bool? adaptiveCadence,
    bool? goalChecksEnabled,
    String? sessionGoal,
    String? distractionTrigger,
    String? recoveryAction,
    bool? learningMode,
    String? recallPrompt,
    StudyEnrollment? studyEnrollment,
    bool clearStudyEnrollment = false,
  }) {
    return FocusSettings(
      focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
      restDurationMinutes: restDurationMinutes ?? this.restDurationMinutes,
      minPromptIntervalMinutes:
          minPromptIntervalMinutes ?? this.minPromptIntervalMinutes,
      maxPromptIntervalMinutes:
          maxPromptIntervalMinutes ?? this.maxPromptIntervalMinutes,
      microBreakSeconds: microBreakSeconds ?? this.microBreakSeconds,
      notificationsEnabled:
          lockScreenNotifications ??
          desktopNotifications ??
          notificationsEnabled ??
          this.notificationsEnabled,
      trayEnabled: trayEnabled ?? this.trayEnabled,
      foregroundPromptSoundEnabled:
          foregroundPromptSoundEnabled ?? this.foregroundPromptSoundEnabled,
      soundPreset: soundPreset ?? this.soundPreset,
      modeName: modeName ?? this.modeName,
      adaptiveCadence: adaptiveCadence ?? this.adaptiveCadence,
      goalChecksEnabled: goalChecksEnabled ?? this.goalChecksEnabled,
      sessionGoal: sessionGoal ?? this.sessionGoal,
      distractionTrigger: distractionTrigger ?? this.distractionTrigger,
      recoveryAction: recoveryAction ?? this.recoveryAction,
      learningMode: learningMode ?? this.learningMode,
      recallPrompt: recallPrompt ?? this.recallPrompt,
      studyEnrollment: clearStudyEnrollment
          ? null
          : studyEnrollment ?? this.studyEnrollment,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': currentDataSchemaVersion,
      'focusDurationMinutes': focusDurationMinutes,
      'restDurationMinutes': restDurationMinutes,
      'minPromptIntervalMinutes': minPromptIntervalMinutes,
      'maxPromptIntervalMinutes': maxPromptIntervalMinutes,
      'microBreakSeconds': microBreakSeconds,
      'notificationsEnabled': notificationsEnabled,
      'lockScreenNotifications': notificationsEnabled,
      'desktopNotifications': notificationsEnabled,
      'trayEnabled': trayEnabled,
      'foregroundPromptSoundEnabled': foregroundPromptSoundEnabled,
      'soundPreset': soundPreset.name,
      'modeName': modeName,
      'adaptiveCadence': adaptiveCadence,
      'goalChecksEnabled': goalChecksEnabled,
      'sessionGoal': sessionGoal,
      'distractionTrigger': distractionTrigger,
      'recoveryAction': recoveryAction,
      'learningMode': learningMode,
      'recallPrompt': recallPrompt,
      'studyEnrollment': studyEnrollment?.toJson(),
    };
  }

  factory FocusSettings.fromJson(Map<String, Object?> json) {
    final notifications =
        json['notificationsEnabled'] as bool? ??
        json['lockScreenNotifications'] as bool? ??
        json['desktopNotifications'] as bool? ??
        false;

    return FocusSettings(
      focusDurationMinutes:
          (json['focusDurationMinutes'] as num?)?.toInt() ?? 50,
      restDurationMinutes: (json['restDurationMinutes'] as num?)?.toInt() ?? 10,
      minPromptIntervalMinutes:
          (json['minPromptIntervalMinutes'] as num?)?.toInt() ?? 12,
      maxPromptIntervalMinutes:
          (json['maxPromptIntervalMinutes'] as num?)?.toInt() ?? 18,
      microBreakSeconds: (json['microBreakSeconds'] as num?)?.toInt() ?? 20,
      notificationsEnabled: notifications,
      trayEnabled: json['trayEnabled'] as bool? ?? true,
      foregroundPromptSoundEnabled:
          json['foregroundPromptSoundEnabled'] as bool? ?? false,
      soundPreset: SoundPreset.values.firstWhere(
        (preset) => preset.name == json['soundPreset'],
        orElse: () => SoundPreset.softBell,
      ),
      modeName: json['modeName'] as String? ?? '稀疏目标检查',
      adaptiveCadence: json['adaptiveCadence'] as bool? ?? true,
      goalChecksEnabled: json['goalChecksEnabled'] as bool? ?? true,
      sessionGoal: json['sessionGoal'] as String? ?? '',
      distractionTrigger:
          json['distractionTrigger'] as String? ?? '我发现自己偏离当前任务',
      recoveryAction: json['recoveryAction'] as String? ?? '查看当前小目标，并完成下一步最小动作',
      learningMode: json['learningMode'] as bool? ?? false,
      recallPrompt: json['recallPrompt'] as String? ?? '',
      studyEnrollment: json['studyEnrollment'] is Map
          ? _studyEnrollmentFromJson(
              (json['studyEnrollment'] as Map).cast<String, Object?>(),
            )
          : null,
    ).normalized();
  }

  String encode() => jsonEncode(toJson());

  factory FocusSettings.decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) return const FocusSettings();
    return FocusSettings.fromJson(decoded.cast<String, Object?>());
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
    required this.type,
    this.promptId = '',
    this.plannedOffsetSeconds,
    this.responseLatencySeconds,
  });

  final int elapsedSeconds;
  final DateTime occurredAt;
  final PromptResponseType type;
  final String promptId;
  final int? plannedOffsetSeconds;
  final int? responseLatencySeconds;

  Map<String, Object?> toJson() {
    return {
      'elapsedSeconds': elapsedSeconds,
      'occurredAt': occurredAt.toIso8601String(),
      'type': type.name,
      'promptId': promptId,
      'plannedOffsetSeconds': plannedOffsetSeconds,
      'responseLatencySeconds': responseLatencySeconds,
    };
  }

  factory PromptEvent.fromJson(Map<String, Object?> json) {
    final rawType = json['type'] ?? json['event'];
    return PromptEvent(
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      type: _responseTypeFromLegacy(rawType),
      promptId: _bounded(json['promptId'] as String? ?? '', 120),
      plannedOffsetSeconds: (json['plannedOffsetSeconds'] as num?)?.toInt(),
      responseLatencySeconds: (json['responseLatencySeconds'] as num?)?.toInt(),
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
    this.goal = '',
    this.ifThenPlan = '',
    this.recallPrompt = '',
    this.recallResponse = '',
    this.reflection = '',
    this.measurementContext = const MeasurementContext(),
    this.outcomeReport,
    this.dataSchemaVersion = currentDataSchemaVersion,
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
  final String goal;
  final String ifThenPlan;
  final String recallPrompt;
  final String recallResponse;
  final String reflection;
  final MeasurementContext measurementContext;
  final SessionOutcomeReport? outcomeReport;
  final int dataSchemaVersion;

  double get completionRate {
    if (plannedFocusSeconds <= 0) return 0;
    return (focusSeconds / plannedFocusSeconds).clamp(0, 1).toDouble();
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': currentDataSchemaVersion,
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'plannedFocusSeconds': plannedFocusSeconds,
      'focusSeconds': focusSeconds,
      'restSeconds': restSeconds,
      'completed': completed,
      'modeName': modeName,
      'promptEvents': promptEvents.map((event) => event.toJson()).toList(),
      'goal': goal,
      'ifThenPlan': ifThenPlan,
      'recallPrompt': recallPrompt,
      'recallResponse': recallResponse,
      'reflection': reflection,
      'measurementContext': measurementContext.toJson(),
      'outcomeReport': outcomeReport?.toJson(),
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
      modeName: json['modeName'] as String? ?? '稀疏目标检查',
      promptEvents: ((json['promptEvents'] as List?) ?? const [])
          .whereType<Map>()
          .map((event) => PromptEvent.fromJson(event.cast<String, Object?>()))
          .toList(growable: false),
      goal: json['goal'] as String? ?? '',
      ifThenPlan: json['ifThenPlan'] as String? ?? '',
      recallPrompt: json['recallPrompt'] as String? ?? '',
      recallResponse: json['recallResponse'] as String? ?? '',
      reflection: json['reflection'] as String? ?? '',
      measurementContext: json['measurementContext'] is Map
          ? MeasurementContext.fromJson(
              (json['measurementContext'] as Map).cast<String, Object?>(),
            )
          : const MeasurementContext(),
      outcomeReport: json['outcomeReport'] is Map
          ? SessionOutcomeReport.fromJson(
              (json['outcomeReport'] as Map).cast<String, Object?>(),
            )
          : null,
      dataSchemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }

  FocusSession copyWith({SessionOutcomeReport? outcomeReport}) {
    return FocusSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      plannedFocusSeconds: plannedFocusSeconds,
      focusSeconds: focusSeconds,
      restSeconds: restSeconds,
      completed: completed,
      modeName: modeName,
      promptEvents: promptEvents,
      goal: goal,
      ifThenPlan: ifThenPlan,
      recallPrompt: recallPrompt,
      recallResponse: recallResponse,
      reflection: reflection,
      measurementContext: measurementContext,
      outcomeReport: outcomeReport ?? this.outcomeReport,
      dataSchemaVersion: dataSchemaVersion,
    );
  }

  String encode() => jsonEncode(toJson());

  factory FocusSession.decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Session payload must be a JSON object.');
    }
    return FocusSession.fromJson(decoded.cast<String, Object?>());
  }
}

PromptResponseType _responseTypeFromLegacy(Object? rawType) {
  final value = rawType?.toString() ?? '';
  if (value == 'microbreak_start') return PromptResponseType.shown;
  if (value == 'microbreak_end') return PromptResponseType.ended;
  return PromptResponseType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => PromptResponseType.shown,
  );
}

StudyEnrollment? _studyEnrollmentFromJson(Map<String, Object?> json) {
  try {
    return StudyEnrollment.fromJson(json);
  } catch (_) {
    return null;
  }
}

String _bounded(String value, int maxLength, {String fallback = ''}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return fallback;
  if (trimmed.length <= maxLength) return trimmed;
  return trimmed.substring(0, maxLength);
}
