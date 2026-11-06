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

/// Minimum number of resolved (displayed) checks before cadence may change.
const minResolvedChecksForCadence = 6;

/// Share of resolved checks left unanswered at which cadence is lengthened.
const unansweredBurdenThreshold = 0.35;

/// Chooses a cadence factor from how recently displayed checks were resolved.
///
/// Each check a person saw resolves once: an explicit answer (`onTask`,
/// `offTask`, `acknowledged`) or a non-answer (`skipped`, `delayed`, or a
/// timeout `ended`). Non-answers are burden signals, so a person who lets
/// checks expire gets fewer checks, never more. When one check has several
/// resolutions (it timed out, then was answered from its notification), the
/// answer wins, so the check is counted once.
///
/// `missed` checks were never displayed and carry no burden or attention
/// information, so they are ignored unless later answered from the
/// notification. Legacy `ended` events without a prompt ID come from the 0.1
/// mandatory microbreak, which ended on its own; they are not timeouts and are
/// ignored too.
CadenceDecision cadenceDecisionFromHistory(List<FocusSession> sessions) {
  final recent = sessions.reversed.take(7).toList(growable: false);
  final resolved = _checkResolutions(
    recent.expand((session) => session.promptEvents),
  );

  if (recent.length < 3 || resolved.length < minResolvedChecksForCadence) {
    return const CadenceDecision(factor: 1, reason: 'insufficient_history');
  }

  final unanswered = resolved
      .where(
        (type) =>
            type == PromptResponseType.skipped ||
            type == PromptResponseType.delayed ||
            type == PromptResponseType.ended,
      )
      .length;
  final onTask = resolved
      .where(
        (type) =>
            type == PromptResponseType.onTask ||
            type == PromptResponseType.acknowledged,
      )
      .length;
  final offTask = resolved
      .where((type) => type == PromptResponseType.offTask)
      .length;

  if (unanswered / resolved.length >= unansweredBurdenThreshold) {
    return const CadenceDecision(factor: 1.25, reason: 'reduce_cue_burden');
  }
  if (onTask / resolved.length >= 0.8) {
    return const CadenceDecision(factor: 1.12, reason: 'mostly_on_task');
  }
  if (offTask / resolved.length >= 0.5) {
    return const CadenceDecision(
      factor: 1,
      reason: 'off_task_does_not_increase_cue_burden',
    );
  }
  return const CadenceDecision(factor: 1, reason: 'stable_cadence');
}

/// One resolution per check: correlated events are grouped by prompt ID and
/// the strongest resolution kept; legacy uncorrelated rows count one each.
List<PromptResponseType> _checkResolutions(Iterable<PromptEvent> events) {
  final uncorrelated = <PromptResponseType>[];
  final byPrompt = <String, PromptResponseType>{};
  for (final event in events) {
    final rank = _resolutionRank(event.type);
    if (rank == 0) continue;
    if (event.promptId.isEmpty) {
      // Legacy rows: a prompt-less `ended` is the 0.1 microbreak ending.
      if (event.type != PromptResponseType.ended) uncorrelated.add(event.type);
      continue;
    }
    final previous = byPrompt[event.promptId];
    if (previous == null || rank > _resolutionRank(previous)) {
      byPrompt[event.promptId] = event.type;
    }
  }
  return [...uncorrelated, ...byPrompt.values];
}

/// 0 = not a resolution; higher wins when one check has several.
int _resolutionRank(PromptResponseType type) {
  switch (type) {
    case PromptResponseType.onTask:
    case PromptResponseType.offTask:
    case PromptResponseType.acknowledged:
      return 3;
    case PromptResponseType.skipped:
    case PromptResponseType.delayed:
      return 2;
    case PromptResponseType.ended:
      return 1;
    case PromptResponseType.shown:
    case PromptResponseType.missed:
      return 0;
  }
}

double cadenceFactorFromHistory(List<FocusSession> sessions) {
  return cadenceDecisionFromHistory(sessions).factor;
}
