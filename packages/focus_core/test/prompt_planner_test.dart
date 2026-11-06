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

  group('cadence burden counts every displayed non-answer', () {
    test('timeouts lengthen cadence like skips do', () {
      final decision = cadenceDecisionFromHistory(
        _history(sessions: 3, perSession: [_ended, _ended]),
      );

      expect(decision.factor, 1.25);
      expect(decision.reason, 'reduce_cue_burden');
    });

    test('timeouts count toward the minimum-history requirement', () {
      // Two answers plus four timeouts: six resolved checks. Before the fix,
      // timeouts were invisible, so this stayed at insufficient_history.
      final decision = cadenceDecisionFromHistory([
        ..._history(sessions: 1, perSession: [_onTask, _onTask]),
        ..._history(sessions: 2, perSession: [_ended, _ended], idOffset: 1),
      ]);

      expect(decision.reason, 'reduce_cue_burden');
      expect(decision.factor, 1.25);
    });

    test('Windows "ask later" (delayed) is a burden signal', () {
      final decision = cadenceDecisionFromHistory(
        _history(sessions: 3, perSession: [_delayed, _onTask]),
      );

      expect(decision.factor, 1.25);
      expect(decision.reason, 'reduce_cue_burden');
    });

    test('mostly answered checks below the threshold do not reduce', () {
      // 2 of 9 resolved checks unanswered = 22% < 35%.
      final decision = cadenceDecisionFromHistory([
        ..._history(sessions: 2, perSession: [_onTask, _onTask, _onTask]),
        ..._history(
          sessions: 1,
          perSession: [_ended, _skipped, _onTask],
          idOffset: 2,
        ),
      ]);

      expect(decision.reason, isNot('reduce_cue_burden'));
      expect(decision.factor, lessThan(1.25));
    });

    test('missed checks are neither burden nor dilution', () {
      // 3 timeouts + 3 answers = 50% unanswered. If the 12 missed checks were
      // counted as resolved, the ratio would fall to 17% and hide the burden.
      final decision = cadenceDecisionFromHistory(
        _history(
          sessions: 3,
          perSession: [_ended, _onTask, _missed, _missed, _missed, _missed],
        ),
      );

      expect(decision.factor, 1.25);
      expect(decision.reason, 'reduce_cue_burden');
    });

    test('only missed checks never change cadence', () {
      final decision = cadenceDecisionFromHistory(
        _history(sessions: 4, perSession: [_missed, _missed, _missed]),
      );

      expect(decision.factor, 1);
      expect(decision.reason, 'insufficient_history');
    });

    test('legacy 0.1 microbreak ends are not treated as timeouts', () {
      // Migrated `microbreak_end` rows become `ended` without a prompt ID;
      // that microbreak finished by design and says nothing about burden.
      final legacy = FocusSession.fromJson({
        'id': 'legacy',
        'startedAt': DateTime(2026, 1, 1).toIso8601String(),
        'endedAt': DateTime(2026, 1, 1, 1).toIso8601String(),
        'plannedFocusSeconds': 3000,
        'focusSeconds': 3000,
        'restSeconds': 0,
        'completed': true,
        'modeName': 'legacy',
        'promptEvents': [
          for (var i = 0; i < 4; i += 1) ...[
            {
              'elapsedSeconds': 600 * (i + 1),
              'occurredAt': DateTime(2026, 1, 1).toIso8601String(),
              'event': 'microbreak_start',
            },
            {
              'elapsedSeconds': 600 * (i + 1) + 10,
              'occurredAt': DateTime(2026, 1, 1).toIso8601String(),
              'event': 'microbreak_end',
            },
          ],
        ],
      });
      expect(
        legacy.promptEvents.where((e) => e.type == PromptResponseType.ended),
        hasLength(4),
      );

      final decision = cadenceDecisionFromHistory([legacy, legacy, legacy]);

      expect(decision.factor, 1);
      expect(decision.reason, 'insufficient_history');
    });
  });
}

const _onTask = PromptResponseType.onTask;
const _skipped = PromptResponseType.skipped;
const _delayed = PromptResponseType.delayed;
const _ended = PromptResponseType.ended;
const _missed = PromptResponseType.missed;

/// Builds sessions whose prompt events mirror what the engines record: each
/// resolution carries the correlated prompt ID of its check.
List<FocusSession> _history({
  required int sessions,
  required List<PromptResponseType> perSession,
  int idOffset = 0,
}) {
  return List.generate(sessions, (index) {
    final sessionIndex = index + idOffset;
    final day = DateTime(2026, 1, sessionIndex + 1);
    return FocusSession(
      id: 'history-$sessionIndex',
      startedAt: day,
      endedAt: day.add(const Duration(hours: 1)),
      plannedFocusSeconds: 3000,
      focusSeconds: 3000,
      restSeconds: 0,
      completed: true,
      modeName: 'test',
      promptEvents: [
        for (var i = 0; i < perSession.length; i += 1)
          PromptEvent(
            elapsedSeconds: 300 * (i + 1),
            occurredAt: day,
            type: perSession[i],
            promptId: 'history-$sessionIndex:$i',
          ),
      ],
    );
  });
}
