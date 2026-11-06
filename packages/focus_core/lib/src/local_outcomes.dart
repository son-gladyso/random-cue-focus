import 'models.dart';

class LocalOutcomeSummary {
  const LocalOutcomeSummary({
    required this.sessionCount,
    required this.completedSessionCount,
    required this.cuesShown,
    this.cuesMissed = 0,
    this.missedChecksAnsweredByNotification = 0,
    this.notificationAnswers = 0,
    required this.onTaskResponses,
    required this.offTaskResponses,
    required this.skippedResponses,
    required this.learningReflections,
    required this.meaningfulProgressAnswers,
    required this.meaningfulProgressYes,
    required this.burdenAnswers,
    required this.highBurdenAnswers,
  });

  final int sessionCount;
  final int completedSessionCount;
  final int cuesShown;

  /// Planned checks that came due while the in-app card could not be seen.
  /// They are excluded from [cuesShown] and every response-rate denominator.
  final int cuesMissed;

  /// Missed checks later answered from the notification. Seeing and answering
  /// the notification is exposure, so these join [checksReached].
  final int missedChecksAnsweredByNotification;

  /// Answers given from a notification action, whether the in-app card was
  /// missed or had already timed out.
  final int notificationAnswers;
  final int onTaskResponses;
  final int offTaskResponses;
  final int skippedResponses;
  final int learningReflections;
  final int meaningfulProgressAnswers;
  final int meaningfulProgressYes;
  final int burdenAnswers;
  final int highBurdenAnswers;

  int get explicitResponses =>
      onTaskResponses + offTaskResponses + skippedResponses;

  /// Checks the person demonstrably saw: shown in the app, or answered from
  /// the notification after the in-app card was missed.
  int get checksReached => cuesShown + missedChecksAnsweredByNotification;

  double? get responseRate {
    if (checksReached == 0) return null;
    return (explicitResponses / checksReached).clamp(0, 1).toDouble();
  }

  double? get offTaskShare {
    final attentionResponses = onTaskResponses + offTaskResponses;
    if (attentionResponses == 0) return null;
    return offTaskResponses / attentionResponses;
  }

  double? get completionRate {
    if (sessionCount == 0) return null;
    return completedSessionCount / sessionCount;
  }

  double? get userValuedSessionRate {
    if (meaningfulProgressAnswers == 0) return null;
    return meaningfulProgressYes / meaningfulProgressAnswers;
  }

  double? get highBurdenRate {
    if (burdenAnswers == 0) return null;
    return highBurdenAnswers / burdenAnswers;
  }
}

LocalOutcomeSummary summarizeLocalOutcomes(List<FocusSession> sessions) {
  var completed = 0;
  var shown = 0;
  var missed = 0;
  var missedAnswered = 0;
  var notificationAnswers = 0;
  var onTask = 0;
  var offTask = 0;
  var skipped = 0;
  var reflections = 0;
  var meaningfulProgressAnswers = 0;
  var meaningfulProgressYes = 0;
  var burdenAnswers = 0;
  var highBurdenAnswers = 0;

  for (final session in sessions) {
    if (session.completed) completed += 1;
    if (session.recallResponse.trim().isNotEmpty ||
        session.reflection.trim().isNotEmpty) {
      reflections += 1;
    }
    final outcome = session.outcomeReport;
    if (outcome?.meaningfulProgress != null) {
      meaningfulProgressAnswers += 1;
      if (outcome!.meaningfulProgress == MeaningfulProgressResponse.yes) {
        meaningfulProgressYes += 1;
      }
    }
    if (outcome?.interruptionBurden != null) {
      burdenAnswers += 1;
      if (outcome!.interruptionBurden! >= 3) highBurdenAnswers += 1;
    }
    final missedPromptIds = {
      for (final event in session.promptEvents)
        if (event.type == PromptResponseType.missed) event.promptId,
    };
    for (final event in session.promptEvents) {
      if (event.channel == PromptChannel.notification) {
        notificationAnswers += 1;
        if (missedPromptIds.contains(event.promptId)) missedAnswered += 1;
      }
      switch (event.type) {
        case PromptResponseType.shown:
          shown += 1;
          break;
        case PromptResponseType.onTask:
        case PromptResponseType.acknowledged:
          onTask += 1;
          break;
        case PromptResponseType.offTask:
          offTask += 1;
          break;
        case PromptResponseType.skipped:
          skipped += 1;
          break;
        case PromptResponseType.missed:
          missed += 1;
          break;
        case PromptResponseType.delayed:
        case PromptResponseType.ended:
          break;
      }
    }
  }

  return LocalOutcomeSummary(
    sessionCount: sessions.length,
    completedSessionCount: completed,
    cuesShown: shown,
    cuesMissed: missed,
    missedChecksAnsweredByNotification: missedAnswered,
    notificationAnswers: notificationAnswers,
    onTaskResponses: onTask,
    offTaskResponses: offTask,
    skippedResponses: skipped,
    learningReflections: reflections,
    meaningfulProgressAnswers: meaningfulProgressAnswers,
    meaningfulProgressYes: meaningfulProgressYes,
    burdenAnswers: burdenAnswers,
    highBurdenAnswers: highBurdenAnswers,
  );
}
