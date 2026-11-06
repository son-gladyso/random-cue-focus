import 'package:focus_core/focus_core.dart';
import 'package:test/test.dart';

void main() {
  final start = DateTime.utc(2026, 8, 27, 8);

  PromptEvent at(
    int elapsed,
    PromptResponseType type, {
    String id = 's:0',
    int? planned,
    int? latency,
    PromptChannel channel = PromptChannel.inApp,
  }) {
    return PromptEvent(
      elapsedSeconds: elapsed,
      occurredAt: start.add(Duration(seconds: elapsed)),
      type: type,
      promptId: id,
      plannedOffsetSeconds: planned,
      responseLatencySeconds: latency,
      channel: channel,
    );
  }

  group('parseGoalCheckAnswer', () {
    test('reads iOS action identifiers with the prompt in the payload', () {
      expect(
        parseGoalCheckAnswer(actionId: goalCheckOnTaskActionId, payload: 's:1'),
        const GoalCheckAnswer(
          promptId: 's:1',
          response: PromptResponseType.onTask,
        ),
      );
      expect(
        parseGoalCheckAnswer(
          actionId: goalCheckOffTaskActionId,
          payload: 's:2',
        ),
        const GoalCheckAnswer(
          promptId: 's:2',
          response: PromptResponseType.offTask,
        ),
      );
    });

    test('reads Windows toast arguments that carry both parts', () {
      final arguments = goalCheckActionArguments(
        goalCheckOffTaskActionId,
        'session-uuid:3',
      );
      expect(
        parseGoalCheckAnswer(actionId: arguments, payload: arguments),
        const GoalCheckAnswer(
          promptId: 'session-uuid:3',
          response: PromptResponseType.offTask,
        ),
      );
    });

    test('ignores taps, other actions, and missing prompt IDs', () {
      expect(parseGoalCheckAnswer(actionId: null, payload: 's:1'), isNull);
      expect(parseGoalCheckAnswer(actionId: '', payload: 's:1'), isNull);
      expect(parseGoalCheckAnswer(actionId: 'skip', payload: 's:1'), isNull);
      expect(
        parseGoalCheckAnswer(actionId: goalCheckOnTaskActionId, payload: ''),
        isNull,
      );
      expect(
        parseGoalCheckAnswer(actionId: '$goalCheckOnTaskActionId|'),
        isNull,
      );
    });

    test('prompt IDs match the engines\' correlation format', () {
      expect(goalCheckPromptId('abc', 2), 'abc:2');
    });
  });

  group('lateNotificationAnswerEvent', () {
    const onTask = GoalCheckAnswer(
      promptId: 's:0',
      response: PromptResponseType.onTask,
    );

    test('answers a missed check, timing from when it came due', () {
      final event = lateNotificationAnswerEvent(
        events: [at(300, PromptResponseType.missed, planned: 300)],
        answer: onTask,
        elapsedSeconds: 420,
        at: start.add(const Duration(seconds: 420)),
      );

      expect(event, isNotNull);
      expect(event!.type, PromptResponseType.onTask);
      expect(event.promptId, 's:0');
      expect(event.channel, PromptChannel.notification);
      expect(event.responseLatencySeconds, 120);
      expect(event.plannedOffsetSeconds, isNull);
    });

    test('answers a check that timed out on screen', () {
      final event = lateNotificationAnswerEvent(
        events: [
          at(300, PromptResponseType.shown, planned: 300),
          at(320, PromptResponseType.ended, latency: 20),
        ],
        answer: onTask,
        elapsedSeconds: 400,
        at: start.add(const Duration(seconds: 400)),
      );

      expect(event!.responseLatencySeconds, 100);
    });

    test('first answer wins: an answered or skipped check is ignored', () {
      for (final response in [
        PromptResponseType.offTask,
        PromptResponseType.skipped,
        PromptResponseType.delayed,
      ]) {
        expect(
          lateNotificationAnswerEvent(
            events: [
              at(300, PromptResponseType.shown, planned: 300),
              at(305, response, latency: 5),
            ],
            answer: onTask,
            elapsedSeconds: 400,
            at: start,
          ),
          isNull,
          reason: response.name,
        );
      }
    });

    test('a check still on screen is left to the engine', () {
      expect(
        lateNotificationAnswerEvent(
          events: [at(300, PromptResponseType.shown, planned: 300)],
          answer: onTask,
          elapsedSeconds: 305,
          at: start,
        ),
        isNull,
      );
    });

    test('unknown or not-yet-due checks are ignored', () {
      expect(
        lateNotificationAnswerEvent(
          events: [at(300, PromptResponseType.missed, id: 'other:0')],
          answer: onTask,
          elapsedSeconds: 400,
          at: start,
        ),
        isNull,
      );
      expect(
        lateNotificationAnswerEvent(
          events: const [],
          answer: onTask,
          elapsedSeconds: 10,
          at: start,
        ),
        isNull,
      );
    });
  });

  group('channel storage', () {
    test('round-trips and defaults legacy rows to in-app', () {
      final answer = at(
        420,
        PromptResponseType.onTask,
        latency: 120,
        channel: PromptChannel.notification,
      );
      final restored = PromptEvent.fromJson(answer.toJson());
      expect(restored.channel, PromptChannel.notification);

      final legacy = PromptEvent.fromJson({
        'elapsedSeconds': 1,
        'occurredAt': start.toIso8601String(),
        'type': 'onTask',
      });
      expect(legacy.channel, PromptChannel.inApp);
    });

    test('research export keeps the channel', () {
      final export = buildPrivacyPreservingResearchExport(
        [
          _session(start, [
            at(300, PromptResponseType.missed, planned: 300),
            at(
              420,
              PromptResponseType.onTask,
              latency: 120,
              channel: PromptChannel.notification,
            ),
          ]),
        ],
        participantCode: 'p-1',
        exportedAt: start.add(const Duration(days: 1)),
      );
      final events =
          ((export['sessions'] as List).single as Map)['promptEvents'] as List;
      expect((events.last as Map)['channel'], 'notification');
    });
  });

  group('measurement with notification answers', () {
    test('a missed check answered from its notification is valid', () {
      final report = validateMeasurementData([
        _session(start, [
          at(300, PromptResponseType.missed, planned: 300),
          at(
            420,
            PromptResponseType.onTask,
            latency: 120,
            channel: PromptChannel.notification,
          ),
        ]),
      ], now: start.add(const Duration(days: 1)));

      expect(report.issues, isEmpty);
    });

    test('a timed-out check answered late from its notification is valid', () {
      final report = validateMeasurementData([
        _session(start, [
          at(300, PromptResponseType.shown, planned: 300),
          at(320, PromptResponseType.ended, latency: 20),
          at(
            400,
            PromptResponseType.offTask,
            latency: 100,
            channel: PromptChannel.notification,
          ),
        ]),
      ], now: start.add(const Duration(days: 1)));

      expect(report.issues, isEmpty);
    });

    test('a notification can only carry an on- or off-task answer', () {
      final report = validateMeasurementData([
        _session(start, [
          at(300, PromptResponseType.missed, planned: 300),
          at(
            420,
            PromptResponseType.skipped,
            latency: 120,
            channel: PromptChannel.notification,
          ),
        ]),
      ], now: start.add(const Duration(days: 1)));

      expect(
        report.issues.map((issue) => issue.code),
        containsAll([
          'invalid_notification_event',
          'invalid_missed_prompt_record',
        ]),
      );
    });

    test('a missed check cannot get two notification answers', () {
      final report = validateMeasurementData([
        _session(start, [
          at(300, PromptResponseType.missed, planned: 300),
          at(
            420,
            PromptResponseType.onTask,
            latency: 120,
            channel: PromptChannel.notification,
          ),
          at(
            430,
            PromptResponseType.offTask,
            latency: 130,
            channel: PromptChannel.notification,
          ),
        ]),
      ], now: start.add(const Duration(days: 1)));

      expect(
        report.issues.map((issue) => issue.code),
        contains('invalid_missed_prompt_record'),
      );
    });

    test('a wrong latency on a notification answer is flagged', () {
      final report = validateMeasurementData([
        _session(start, [
          at(300, PromptResponseType.missed, planned: 300),
          at(
            420,
            PromptResponseType.onTask,
            latency: 5,
            channel: PromptChannel.notification,
          ),
        ]),
      ], now: start.add(const Duration(days: 1)));

      expect(
        report.issues.map((issue) => issue.code),
        contains('inconsistent_response_latency'),
      );
    });
  });

  group('summaries count notification exposure', () {
    final answeredMissed = [
      at(300, PromptResponseType.missed, id: 's:0', planned: 300),
      at(
        420,
        PromptResponseType.onTask,
        id: 's:0',
        latency: 120,
        channel: PromptChannel.notification,
      ),
      at(600, PromptResponseType.missed, id: 's:1', planned: 600),
    ];

    test('local outcomes treat an answered notification as reached', () {
      final summary = summarizeLocalOutcomes([_session(start, answeredMissed)]);

      expect(summary.cuesShown, 0);
      expect(summary.cuesMissed, 2);
      expect(summary.missedChecksAnsweredByNotification, 1);
      expect(summary.notificationAnswers, 1);
      expect(summary.checksReached, 1);
      expect(summary.responseRate, 1);
    });

    test('cadence counts a late notification answer once, as answered', () {
      // Each check timed out on screen and was then answered from the
      // notification. Counted per event, half would look unanswered.
      final history = List.generate(3, (session) {
        final events = <PromptEvent>[];
        for (var i = 0; i < 2; i += 1) {
          final id = 'h$session:$i';
          final shownAt = 300 * (i + 1);
          events
            ..add(
              at(shownAt, PromptResponseType.shown, id: id, planned: shownAt),
            )
            ..add(
              at(shownAt + 20, PromptResponseType.ended, id: id, latency: 20),
            )
            ..add(
              at(
                shownAt + 60,
                PromptResponseType.onTask,
                id: id,
                latency: 60,
                channel: PromptChannel.notification,
              ),
            );
        }
        return _session(
          start.add(Duration(days: session)),
          events,
          id: 'h$session',
        );
      });

      final decision = cadenceDecisionFromHistory(history);

      expect(decision.reason, 'mostly_on_task');
      expect(decision.factor, 1.12);
    });
  });
}

FocusSession _session(
  DateTime start,
  List<PromptEvent> events, {
  String id = 's',
}) {
  final planned = [
    for (final event in events)
      if (event.plannedOffsetSeconds != null) event.plannedOffsetSeconds!,
  ];
  return FocusSession(
    id: id,
    startedAt: start,
    endedAt: start.add(const Duration(minutes: 20)),
    plannedFocusSeconds: 1200,
    focusSeconds: 1200,
    restSeconds: 0,
    completed: true,
    modeName: 'test',
    promptEvents: events,
    measurementContext: MeasurementContext(plannedPromptOffsets: planned),
  );
}
