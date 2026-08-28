import 'package:focus_core/focus_core.dart';
import 'package:test/test.dart';

void main() {
  test('plan is deterministic, sparse, bounded, and inside session', () {
    const settings = FocusSettings(focusDurationMinutes: 120);
    final first = buildPromptPlan(settings, seed: 42);
    final second = buildPromptPlan(settings, seed: 42);

    expect(
      first.map((cue) => cue.offsetSeconds),
      orderedEquals(second.map((cue) => cue.offsetSeconds)),
    );
    expect(first.length, lessThanOrEqualTo(maxCuesPerSession));
    expect(first.first.offsetSeconds, greaterThanOrEqualTo(12 * 60));
    expect(first.last.offsetSeconds, lessThan(settings.focusDurationSeconds));
    for (var i = 1; i < first.length; i += 1) {
      expect(
        first[i].offsetSeconds - first[i - 1].offsetSeconds,
        inInclusiveRange(12 * 60, 18 * 60),
      );
    }
  });

  test('does not create a cue for a short session', () {
    const settings = FocusSettings(focusDurationMinutes: 10);

    expect(buildPromptPlan(settings, seed: 1), isEmpty);
  });

  test('allows all nonessential goal checks to be disabled', () {
    const settings = FocusSettings(
      focusDurationMinutes: 120,
      goalChecksEnabled: false,
    );

    expect(buildPromptPlan(settings, seed: 9), isEmpty);
  });

  test('skipped cues reduce future cue burden', () {
    final history = List.generate(
      3,
      (sessionIndex) => FocusSession(
        id: '$sessionIndex',
        startedAt: DateTime(2026, 1, sessionIndex + 1),
        endedAt: DateTime(2026, 1, sessionIndex + 1, 1),
        plannedFocusSeconds: 3000,
        focusSeconds: 2500,
        restSeconds: 0,
        completed: false,
        modeName: 'test',
        promptEvents: List.generate(
          2,
          (eventIndex) => PromptEvent(
            elapsedSeconds: 600 + eventIndex * 600,
            occurredAt: DateTime(2026, 1, sessionIndex + 1),
            type: PromptResponseType.skipped,
          ),
        ),
      ),
    );

    final decision = cadenceDecisionFromHistory(history);

    expect(decision.factor, 1.25);
    expect(decision.reason, 'reduce_cue_burden');
  });

  test('off-task reports never increase future cue burden', () {
    final history = List.generate(
      3,
      (sessionIndex) => FocusSession(
        id: 'off-task-$sessionIndex',
        startedAt: DateTime(2026, 1, sessionIndex + 1),
        endedAt: DateTime(2026, 1, sessionIndex + 1, 1),
        plannedFocusSeconds: 3000,
        focusSeconds: 2500,
        restSeconds: 0,
        completed: false,
        modeName: 'test',
        promptEvents: List.generate(
          2,
          (index) => PromptEvent(
            elapsedSeconds: 600 + index * 600,
            occurredAt: DateTime(2026, 1, sessionIndex + 1),
            type: PromptResponseType.offTask,
          ),
        ),
      ),
    );

    final decision = cadenceDecisionFromHistory(history);
    expect(decision.factor, greaterThanOrEqualTo(1));
    expect(decision.reason, 'off_task_does_not_increase_cue_burden');
  });
}
