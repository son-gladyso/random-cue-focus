import 'dart:math';

import 'models.dart';

class PromptPlanner {
  const PromptPlanner();

  List<PromptCue> planSession(
    FocusSettings rawSettings,
    List<FocusSession> history, {
    int? seed,
  }) {
    final settings = rawSettings.normalized();
    final factor = cadenceFactorFromHistory(history);
    return buildPromptPlan(settings, seed: seed, personalCadenceFactor: factor);
  }
}

List<PromptCue> buildPromptPlan(
  FocusSettings rawSettings, {
  int? seed,
  double personalCadenceFactor = 1,
}) {
  final settings = rawSettings.normalized();
  final random = Random(seed);
  final cues = <PromptCue>[];
  final focusSeconds = settings.focusDurationSeconds;
  final guardSeconds = max(settings.microBreakSeconds + 15, 30);
  final factor = personalCadenceFactor.clamp(0.85, 1.25).toDouble();

  var elapsed = 0;
  while (elapsed < focusSeconds - guardSeconds) {
    final lateSessionStretch = elapsed >= 35 * 60 ? 1.22 : 1.0;
    final minSeconds = max(
      30,
      (settings.minPromptIntervalSeconds * factor * lateSessionStretch).round(),
    );
    final maxSeconds = max(
      minSeconds,
      (settings.maxPromptIntervalSeconds * factor * lateSessionStretch).round(),
    );
    elapsed += minSeconds + random.nextInt(maxSeconds - minSeconds + 1);

    if (elapsed < focusSeconds - guardSeconds) {
      cues.add(PromptCue(offsetSeconds: elapsed));
    }
  }

  return cues;
}

double cadenceFactorFromHistory(List<FocusSession> sessions) {
  final recent = sessions.reversed.take(7).toList();
  if (recent.length < 3) return 1;

  final averageCompletion =
      recent.map((session) => session.completionRate).reduce((a, b) => a + b) /
      recent.length;
  final averagePromptCount =
      recent
          .map((session) => session.promptEvents.length)
          .reduce((a, b) => a + b) /
      recent.length;
  final averageSkipCount =
      recent
          .map(
            (session) => session.promptEvents
                .where((event) => event.type == PromptResponseType.skipped)
                .length,
          )
          .reduce((a, b) => a + b) /
      recent.length;

  if (averageSkipCount >= 2) return 1.18;
  if (averageCompletion >= 0.85 && averagePromptCount >= 4) return 1.12;
  if (averageCompletion <= 0.45) return 0.92;
  return 1;
}
