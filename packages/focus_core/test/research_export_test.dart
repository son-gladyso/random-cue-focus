import 'dart:convert';

import 'package:focus_core/focus_core.dart';
import 'package:test/test.dart';

void main() {
  test('research export strips identifiers, calendar dates, and free text', () {
    final started = DateTime(2026, 8, 27, 9, 37);
    final session = FocusSession(
      id: 'private-session-id',
      startedAt: started,
      endedAt: started.add(const Duration(minutes: 30)),
      plannedFocusSeconds: 1800,
      focusSeconds: 1800,
      restSeconds: 0,
      completed: true,
      modeName: 'private mode name',
      promptEvents: [
        PromptEvent(
          promptId: 'private-session-id:0',
          elapsedSeconds: 720,
          occurredAt: started.add(const Duration(minutes: 12)),
          type: PromptResponseType.shown,
        ),
      ],
      goal: 'secret goal',
      ifThenPlan: 'secret recovery plan',
      recallPrompt: 'secret study prompt',
      recallResponse: 'secret answer',
      reflection: 'secret reflection',
      measurementContext: MeasurementContext(
        platform: AppPlatform.windows,
        studyAssignment: StudySessionAssignment(
          studyId: localFeasibilityStudyId,
          protocolVersion: localFeasibilityProtocolVersion,
          assignmentId: '$localFeasibilityStudyId:0',
          sessionIndex: 0,
          condition: StudyCondition.noChecks,
          assignedAt: started.subtract(const Duration(milliseconds: 250)),
        ),
      ),
    );

    final encoded = encodePrivacyPreservingResearchExport(
      [session],
      participantCode: 'P-001',
      exportedAt: DateTime.utc(2026, 8, 28),
    );
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    final exportedSession = (decoded['sessions'] as List).single;

    expect(encoded, isNot(contains('private-session-id')));
    expect(encoded, isNot(contains('secret')));
    expect(encoded, isNot(contains('2026-08-27')));
    expect(decoded['exportSchemaVersion'], 2);
    expect(exportedSession['dayOffset'], 0);
    expect(exportedSession['localStartMinuteOfDay'], 9 * 60 + 37);
    expect(exportedSession['goalPresent'], isTrue);
    final exportedAssignment =
        exportedSession['measurementContext']['studyAssignment'];
    expect(exportedAssignment['condition'], 'noChecks');
    expect(exportedAssignment['assignmentLeadMilliseconds'], 250);
    expect(exportedAssignment, isNot(contains('assignedAt')));
  });

  test('participant code is required and bounded', () {
    expect(
      () => buildPrivacyPreservingResearchExport(
        const [],
        participantCode: '   ',
      ),
      throwsFormatException,
    );
  });
}
