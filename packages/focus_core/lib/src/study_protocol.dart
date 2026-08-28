const localFeasibilityStudyId = 'rcf-local-crossover';
const localFeasibilityProtocolVersion = '1.0.0';

enum StudyCondition { noChecks, sparseChecks }

enum StudySequence { ab, ba }

class StudyEnrollment {
  const StudyEnrollment({
    required this.studyId,
    required this.protocolVersion,
    required this.participantCode,
    required this.consentedAt,
    required this.sequence,
    this.nextSessionIndex = 0,
    this.withdrawnAt,
  });

  final String studyId;
  final String protocolVersion;
  final String participantCode;
  final DateTime consentedAt;
  final StudySequence sequence;
  final int nextSessionIndex;
  final DateTime? withdrawnAt;

  bool get isActive => withdrawnAt == null;

  StudyEnrollment normalized() {
    return StudyEnrollment(
      studyId: _bounded(studyId, 80, fallback: localFeasibilityStudyId),
      protocolVersion: _bounded(
        protocolVersion,
        40,
        fallback: localFeasibilityProtocolVersion,
      ),
      participantCode: _bounded(participantCode, 80, fallback: 'invalid'),
      consentedAt: consentedAt,
      sequence: sequence,
      nextSessionIndex: nextSessionIndex.clamp(0, 1000000).toInt(),
      withdrawnAt: withdrawnAt,
    );
  }

  StudyEnrollment advance() {
    final value = normalized();
    return StudyEnrollment(
      studyId: value.studyId,
      protocolVersion: value.protocolVersion,
      participantCode: value.participantCode,
      consentedAt: value.consentedAt,
      sequence: value.sequence,
      nextSessionIndex: value.nextSessionIndex + 1,
      withdrawnAt: value.withdrawnAt,
    );
  }

  StudyEnrollment withdraw(DateTime at) {
    final value = normalized();
    return StudyEnrollment(
      studyId: value.studyId,
      protocolVersion: value.protocolVersion,
      participantCode: value.participantCode,
      consentedAt: value.consentedAt,
      sequence: value.sequence,
      nextSessionIndex: value.nextSessionIndex,
      withdrawnAt: at,
    );
  }

  Map<String, Object?> toJson() {
    final value = normalized();
    return {
      'studyId': value.studyId,
      'protocolVersion': value.protocolVersion,
      'participantCode': value.participantCode,
      'consentedAt': value.consentedAt.toIso8601String(),
      'sequence': value.sequence.name,
      'nextSessionIndex': value.nextSessionIndex,
      'withdrawnAt': value.withdrawnAt?.toIso8601String(),
    };
  }

  factory StudyEnrollment.fromJson(Map<String, Object?> json) {
    final consentedAt = DateTime.tryParse(json['consentedAt'] as String? ?? '');
    if (consentedAt == null) {
      throw const FormatException('Study consent timestamp is required.');
    }
    return StudyEnrollment(
      studyId: json['studyId'] as String? ?? localFeasibilityStudyId,
      protocolVersion:
          json['protocolVersion'] as String? ?? localFeasibilityProtocolVersion,
      participantCode: json['participantCode'] as String? ?? 'invalid',
      consentedAt: consentedAt,
      sequence: StudySequence.values.firstWhere(
        (value) => value.name == json['sequence'],
        orElse: () => StudySequence.ab,
      ),
      nextSessionIndex: (json['nextSessionIndex'] as num?)?.toInt() ?? 0,
      withdrawnAt: DateTime.tryParse(json['withdrawnAt'] as String? ?? ''),
    ).normalized();
  }
}

class StudySessionAssignment {
  const StudySessionAssignment({
    required this.studyId,
    required this.protocolVersion,
    required this.assignmentId,
    required this.sessionIndex,
    required this.condition,
    required this.assignedAt,
  });

  final String studyId;
  final String protocolVersion;
  final String assignmentId;
  final int sessionIndex;
  final StudyCondition condition;
  final DateTime assignedAt;

  Map<String, Object?> toJson() {
    return {
      'studyId': _bounded(studyId, 80, fallback: localFeasibilityStudyId),
      'protocolVersion': _bounded(
        protocolVersion,
        40,
        fallback: localFeasibilityProtocolVersion,
      ),
      'assignmentId': _bounded(assignmentId, 120, fallback: 'invalid'),
      'sessionIndex': sessionIndex.clamp(0, 1000000).toInt(),
      'condition': condition.name,
      'assignedAt': assignedAt.toIso8601String(),
    };
  }

  factory StudySessionAssignment.fromJson(Map<String, Object?> json) {
    return StudySessionAssignment(
      studyId: json['studyId'] as String? ?? localFeasibilityStudyId,
      protocolVersion:
          json['protocolVersion'] as String? ?? localFeasibilityProtocolVersion,
      assignmentId: json['assignmentId'] as String? ?? 'invalid',
      sessionIndex: (json['sessionIndex'] as num?)?.toInt() ?? 0,
      condition: StudyCondition.values.firstWhere(
        (value) => value.name == json['condition'],
        orElse: () => StudyCondition.noChecks,
      ),
      assignedAt:
          DateTime.tryParse(json['assignedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

StudyEnrollment createLocalFeasibilityEnrollment({
  required String participantCode,
  required DateTime consentedAt,
  required StudySequence sequence,
}) {
  final code = participantCode.trim();
  if (code.isEmpty || code.length > 80) {
    throw const FormatException(
      'Participant code must contain 1-80 characters.',
    );
  }
  return StudyEnrollment(
    studyId: localFeasibilityStudyId,
    protocolVersion: localFeasibilityProtocolVersion,
    participantCode: code,
    consentedAt: consentedAt,
    sequence: sequence,
  );
}

String localParticipantCode(int firstRandomPart, int secondRandomPart) {
  String part(int value) {
    return (value & 0x7fffffff).toRadixString(16).padLeft(8, '0');
  }

  return 'P-${part(firstRandomPart)}${part(secondRandomPart)}';
}

StudySessionAssignment assignmentForNextStudySession(
  StudyEnrollment rawEnrollment, {
  required DateTime assignedAt,
}) {
  final enrollment = rawEnrollment.normalized();
  if (!enrollment.isActive) {
    throw StateError('Cannot assign a session after study withdrawal.');
  }
  final evenSession = enrollment.nextSessionIndex.isEven;
  final condition = switch (enrollment.sequence) {
    StudySequence.ab =>
      evenSession ? StudyCondition.noChecks : StudyCondition.sparseChecks,
    StudySequence.ba =>
      evenSession ? StudyCondition.sparseChecks : StudyCondition.noChecks,
  };
  return StudySessionAssignment(
    studyId: enrollment.studyId,
    protocolVersion: enrollment.protocolVersion,
    assignmentId: '${enrollment.studyId}:${enrollment.nextSessionIndex}',
    sessionIndex: enrollment.nextSessionIndex,
    condition: condition,
    assignedAt: assignedAt,
  );
}

String _bounded(String value, int maxLength, {required String fallback}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return fallback;
  if (trimmed.length <= maxLength) return trimmed;
  return trimmed.substring(0, maxLength);
}
