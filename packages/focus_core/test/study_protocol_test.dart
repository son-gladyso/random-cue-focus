import 'package:focus_core/focus_core.dart';
import 'package:test/test.dart';

void main() {
  test('AB and BA sequences are balanced and assigned before exposure', () {
    final consentedAt = DateTime.utc(2026, 8, 27, 8);
    final assignedAt = consentedAt.add(const Duration(minutes: 1));
    var ab = createLocalFeasibilityEnrollment(
      participantCode: 'P-AB',
      consentedAt: consentedAt,
      sequence: StudySequence.ab,
    );
    var ba = createLocalFeasibilityEnrollment(
      participantCode: 'P-BA',
      consentedAt: consentedAt,
      sequence: StudySequence.ba,
    );

    expect(
      assignmentForNextStudySession(ab, assignedAt: assignedAt).condition,
      StudyCondition.noChecks,
    );
    expect(
      assignmentForNextStudySession(ba, assignedAt: assignedAt).condition,
      StudyCondition.sparseChecks,
    );
    ab = ab.advance();
    ba = ba.advance();
    expect(
      assignmentForNextStudySession(ab, assignedAt: assignedAt).condition,
      StudyCondition.sparseChecks,
    );
    expect(
      assignmentForNextStudySession(ba, assignedAt: assignedAt).condition,
      StudyCondition.noChecks,
    );
  });

  test('withdrawal prevents further assignment and round-trips', () {
    final enrollment = createLocalFeasibilityEnrollment(
      participantCode: localParticipantCode(1, 2),
      consentedAt: DateTime.utc(2026, 8, 27),
      sequence: StudySequence.ba,
    ).advance().withdraw(DateTime.utc(2026, 8, 28));

    final decoded = StudyEnrollment.fromJson(enrollment.toJson());

    expect(decoded.isActive, isFalse);
    expect(decoded.nextSessionIndex, 1);
    expect(decoded.participantCode, 'P-0000000100000002');
    expect(
      () => assignmentForNextStudySession(
        decoded,
        assignedAt: DateTime.utc(2026, 8, 29),
      ),
      throwsStateError,
    );
  });

  test('malformed study enrollment does not erase valid settings', () {
    final settings = FocusSettings.fromJson(const {
      'focusDurationMinutes': 75,
      'studyEnrollment': {'participantCode': 'missing-consent'},
    });

    expect(settings.focusDurationMinutes, 75);
    expect(settings.studyEnrollment, isNull);
  });
}
