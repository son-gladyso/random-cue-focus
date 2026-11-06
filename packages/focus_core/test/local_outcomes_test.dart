import 'package:focus_core/focus_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'keeps attention, burden, completion, and learning metrics separate',
    () {
      final session = FocusSession(
        id: 'one',
        startedAt: DateTime(2026),
        endedAt: DateTime(2026, 1, 1, 1),
        plannedFocusSeconds: 3000,
        focusSeconds: 3000,
        restSeconds: 600,
        completed: true,
        modeName: 'test',
        recallResponse: 'A closed-book explanation',
        outcomeReport: SessionOutcomeReport(
          meaningfulProgress: MeaningfulProgressResponse.yes,
          interruptionBurden: 4,
          answeredAt: DateTime(2026, 1, 1, 1),
        ),
        promptEvents: [
          PromptEvent(
            elapsedSeconds: 600,
            occurredAt: DateTime(2026),
            type: PromptResponseType.shown,
          ),
          PromptEvent(
            elapsedSeconds: 600,
            occurredAt: DateTime(2026),
            type: PromptResponseType.offTask,
          ),
        ],
      );

      final summary = summarizeLocalOutcomes([session]);

      expect(summary.completionRate, 1);
      expect(summary.responseRate, 1);
      expect(summary.offTaskShare, 1);
      expect(summary.learningReflections, 1);
      expect(summary.userValuedSessionRate, 1);
      expect(summary.highBurdenRate, 1);
    },
  );

  test('outcome rates stay null without explicit answers', () {
    final summary = summarizeLocalOutcomes(const []);

    expect(summary.userValuedSessionRate, isNull);
    expect(summary.highBurdenRate, isNull);
  });

  test('missed checks are counted apart from shown checks', () {
    PromptEvent at(PromptResponseType type) => PromptEvent(
      elapsedSeconds: 600,
      occurredAt: DateTime(2026),
      type: type,
    );
    final summary = summarizeLocalOutcomes([
      FocusSession(
        id: 'missed',
        startedAt: DateTime(2026),
        endedAt: DateTime(2026, 1, 1, 1),
        plannedFocusSeconds: 3000,
        focusSeconds: 3000,
        restSeconds: 0,
        completed: true,
        modeName: 'test',
        promptEvents: [
          at(PromptResponseType.missed),
          at(PromptResponseType.missed),
          at(PromptResponseType.shown),
          at(PromptResponseType.onTask),
        ],
      ),
    ]);

    expect(summary.cuesMissed, 2);
    expect(summary.cuesShown, 1);
    expect(summary.responseRate, 1);
  });
}
