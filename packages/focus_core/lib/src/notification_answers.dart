import 'models.dart';

/// Action identifier for "still on goal" on a goal-check notification.
const goalCheckOnTaskActionId = 'goal_check_on_task';

/// Action identifier for "just distracted" on a goal-check notification.
const goalCheckOffTaskActionId = 'goal_check_off_task';

/// Notification category registered for goal checks (iOS).
const goalCheckNotificationCategory = 'goal_check';

const _argumentSeparator = '|';

/// The stable correlation ID of the check at [cueIndex] in a session plan.
///
/// The engines use it for in-app events and the notification layer uses it as
/// the payload, so an answer from a notification finds its in-app record.
String goalCheckPromptId(String sessionId, int cueIndex) =>
    '$sessionId:$cueIndex';

/// An answer chosen from a goal-check notification's action button.
class GoalCheckAnswer {
  const GoalCheckAnswer({required this.promptId, required this.response});

  final String promptId;

  /// Always [PromptResponseType.onTask] or [PromptResponseType.offTask].
  final PromptResponseType response;

  @override
  bool operator ==(Object other) =>
      other is GoalCheckAnswer &&
      other.promptId == promptId &&
      other.response == response;

  @override
  int get hashCode => Object.hash(promptId, response);

  @override
  String toString() => 'GoalCheckAnswer($promptId, ${response.name})';
}

/// Encodes an action and its prompt into one string, for platforms (Windows
/// toasts) where a button carries a single argument string.
String goalCheckActionArguments(String actionId, String promptId) =>
    '$actionId$_argumentSeparator$promptId';

/// Reads a notification response into an answer, or `null` when it is not a
/// goal-check answer (a plain tap, another notification, a malformed value).
///
/// iOS delivers the action in [actionId] and the prompt in [payload]. Windows
/// delivers [goalCheckActionArguments] in [actionId].
GoalCheckAnswer? parseGoalCheckAnswer({String? actionId, String? payload}) {
  var action = actionId ?? '';
  var promptId = payload ?? '';
  final separator = action.indexOf(_argumentSeparator);
  if (separator >= 0) {
    promptId = action.substring(separator + 1);
    action = action.substring(0, separator);
  }
  if (promptId.isEmpty) return null;
  switch (action) {
    case goalCheckOnTaskActionId:
      return GoalCheckAnswer(
        promptId: promptId,
        response: PromptResponseType.onTask,
      );
    case goalCheckOffTaskActionId:
      return GoalCheckAnswer(
        promptId: promptId,
        response: PromptResponseType.offTask,
      );
    default:
      return null;
  }
}

/// Builds the event for a notification answer to a check that is no longer on
/// screen, or returns `null` when the answer must be ignored.
///
/// The check must already be resolved as `missed` (the card was never seen) or
/// `ended` (the card timed out). It is ignored if the check is unknown, not
/// yet due, or already has an explicit response: one answer per check, first
/// answer wins. A check currently on screen is the engine's job to resolve
/// directly, so it is ignored here as well.
///
/// Latency is measured in focus seconds from the check's `shown` or `missed`
/// event, so for a missed check it is time since the check came due, not time
/// since the person saw the notification (which is unknown).
PromptEvent? lateNotificationAnswerEvent({
  required List<PromptEvent> events,
  required GoalCheckAnswer answer,
  required int elapsedSeconds,
  required DateTime at,
}) {
  PromptEvent? anchor;
  var closed = false;
  for (final event in events) {
    if (event.promptId != answer.promptId) continue;
    switch (event.type) {
      case PromptResponseType.shown:
      case PromptResponseType.missed:
        anchor ??= event;
        if (event.type == PromptResponseType.missed) closed = true;
        break;
      case PromptResponseType.ended:
        closed = true;
        break;
      case PromptResponseType.onTask:
      case PromptResponseType.offTask:
      case PromptResponseType.acknowledged:
      case PromptResponseType.skipped:
      case PromptResponseType.delayed:
        return null;
    }
  }
  if (anchor == null || !closed) return null;
  return PromptEvent(
    elapsedSeconds: elapsedSeconds,
    occurredAt: at,
    type: answer.response,
    promptId: answer.promptId,
    responseLatencySeconds: elapsedSeconds - anchor.elapsedSeconds,
    channel: PromptChannel.notification,
  );
}
