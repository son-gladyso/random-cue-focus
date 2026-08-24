import 'package:flutter_test/flutter_test.dart';
import 'package:random_cue_focus/models.dart';
import 'package:random_cue_focus/prompt_algorithm.dart';

void main() {
  test('prompt plan stays inside focus session and respects default range', () {
    const settings = FocusSettings();
    final plan = buildPromptPlan(settings, seed: 7);

    expect(plan, isNotEmpty);
    expect(plan.first.offsetSeconds, greaterThanOrEqualTo(180));
    expect(plan.last.offsetSeconds, lessThan(settings.focusDurationSeconds));
    for (var i = 1; i < plan.length; i += 1) {
      final gap = plan[i].offsetSeconds - plan[i - 1].offsetSeconds;
      expect(gap, greaterThanOrEqualTo(180));
      expect(gap, lessThanOrEqualTo(8 * 60));
    }
  });

  test('history factor stretches cadence after stable completion', () {
    final sessions = List.generate(
      5,
      (index) => FocusSession(
        id: '$index',
        startedAt: DateTime(2026, 1, index + 1),
        endedAt: DateTime(2026, 1, index + 1, 1),
        plannedFocusSeconds: 5400,
        focusSeconds: 5400,
        restSeconds: 0,
        completed: true,
        modeName: '随机提示音',
        promptEvents: List.generate(
          5,
          (event) => PromptEvent(
            elapsedSeconds: 180 + event * 240,
            occurredAt: DateTime(2026, 1, index + 1),
            event: 'microbreak_start',
          ),
        ),
      ),
    );

    expect(cadenceFactorFromHistory(sessions), greaterThan(1));
  });
}
