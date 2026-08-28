import 'package:flutter_test/flutter_test.dart';
import 'package:focus_core/focus_core.dart' as core;
import 'package:random_cue_focus_windows/models.dart';

void main() {
  test('app wrapper produces the shared seeded plan', () {
    const settings = FocusSettings();
    final wrapper = buildPromptPlan(settings, seed: 42);
    final shared = core.buildPromptPlan(settings, seed: 42);

    expect(
      wrapper.map((cue) => cue.offsetSeconds),
      shared.map((cue) => cue.offsetSeconds),
    );
  });

  test('prompt plan stays inside focus session and respects default range', () {
    const settings = FocusSettings();
    final plan = buildPromptPlan(settings, seed: 7);

    expect(plan, isNotEmpty);
    expect(plan.first.offsetSeconds, greaterThanOrEqualTo(12 * 60));
    expect(plan.last.offsetSeconds, lessThan(settings.focusDurationSeconds));
    for (var i = 1; i < plan.length; i += 1) {
      final gap = plan[i].offsetSeconds - plan[i - 1].offsetSeconds;
      expect(gap, greaterThanOrEqualTo(12 * 60));
      expect(gap, lessThanOrEqualTo(18 * 60));
    }
  });

  test('history factor stretches cadence after repeated skipped prompts', () {
    final sessions = List.generate(
      4,
      (index) => FocusSession(
        id: '$index',
        startedAt: DateTime(2026, 1, index + 1),
        endedAt: DateTime(2026, 1, index + 1, 1),
        plannedFocusSeconds: 5400,
        focusSeconds: 4200,
        restSeconds: 0,
        completed: false,
        modeName: '稀疏目标检查',
        promptEvents: List.generate(
          3,
          (event) => PromptEvent(
            elapsedSeconds: 180 + event * 240,
            occurredAt: DateTime(2026, 1, index + 1),
            type: PromptResponseType.skipped,
          ),
        ),
      ),
    );

    expect(cadenceFactorFromHistory(sessions), greaterThan(1));
  });
}
