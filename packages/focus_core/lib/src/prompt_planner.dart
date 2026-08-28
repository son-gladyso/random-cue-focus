import 'dart:math';

import 'models.dart';

const maxCuesPerSession = 8;

class CadenceDecision {
  const CadenceDecision({required this.factor, required this.reason});

  final double factor;
  final String reason;
}

class PromptPlanner {
  const PromptPlanner();

  List<PromptCue> planSession(
    FocusSettings rawSettings,
    List<FocusSession> history, {
    int? seed,
  }) {
    final settings = rawSettings.normalized();
    final decision = settings.adaptiveCadence
        ? cadenceDecisionFromHistory(history)
        : const CadenceDecision(factor: 1, reason: 'adaptive_cadence_disabled');
    return buildPromptPlan(
      settings,
      seed: seed,
      personalCadenceFactor: decision.factor,
    );
  }
}

List<PromptCue> buildPromptPlan(
  FocusSettings rawSettings, {
  int? seed,
  double personalCadenceFactor = 1,
}) {
  final settings = rawSettings.normalized();
  if (!settings.goalChecksEnabled) return const [];
  final random = Random(seed);
  final cues = <PromptCue>[];
  final focusSeconds = settings.focusDurationSeconds;
  final guardSeconds = max(settings.microBreakSeconds + 30, 120);
  final factor = personalCadenceFactor.clamp(0.9, 1.25).toDouble();

  var elapsed = 0;
  while (elapsed < focusSeconds - guardSeconds &&
      cues.length < maxCuesPerSession) {
    final minSeconds = max(
      5 * 60,
      (settings.minPromptIntervalSeconds * factor).round(),
    );
    final maxSeconds = max(
      minSeconds,
      (settings.maxPromptIntervalSeconds * factor).round(),
    );
    elapsed += minSeconds + random.nextInt(maxSeconds - minSeconds + 1);

    if (elapsed < focusSeconds - guardSeconds) {
      cues.add(PromptCue(offsetSeconds: elapsed));
    }
  }

  return List.unmodifiable(cues);
}

CadenceDecision cadenceDecisionFromHistory(List<FocusSession> sessions) {
  final recent = sessions.reversed.take(7).toList(growable: false);
  final responses = recent
      .expand((session) => session.promptEvents)
      .where(
        (event) =>
            event.type == PromptResponseType.onTask ||
            event.type == PromptResponseType.offTask ||
            event.type == PromptResponseType.acknowledged ||
            event.type == PromptResponseType.skipped,
      )
      .toList(growable: false);

  if (recent.length < 3 || responses.length < 6) {
    return const CadenceDecision(factor: 1, reason: 'insufficient_history');
  }

  final skipped = responses
      .where((event) => event.type == PromptResponseType.skipped)
      .length;
  final onTask = responses
      .where(
        (event) =>
            event.type == PromptResponseType.onTask ||
            event.type == PromptResponseType.acknowledged,
      )
      .length;
  final offTask = responses
      .where((event) => event.type == PromptResponseType.offTask)
      .length;

  if (skipped / responses.length >= 0.35) {
    return const CadenceDecision(factor: 1.25, reason: 'reduce_cue_burden');
  }
  if (onTask / responses.length >= 0.8) {
    return const CadenceDecision(factor: 1.12, reason: 'mostly_on_task');
  }
  if (offTask / responses.length >= 0.5) {
    return const CadenceDecision(
      factor: 1,
      reason: 'off_task_does_not_increase_cue_burden',
    );
  }
  return const CadenceDecision(factor: 1, reason: 'stable_cadence');
}

double cadenceFactorFromHistory(List<FocusSession> sessions) {
  return cadenceDecisionFromHistory(sessions).factor;
}
