# Measurement schema and data-quality contract

## Decision this data supports

The measurement system is designed to answer whether sparse, optional goal checks help users return to a chosen task without unacceptable interruption burden. It is not designed to infer cognition, productivity, learning, diagnosis, or health from elapsed time.

Schema `v6` is local-first. It retains v5 enrollment and assignment fields and adds the actual per-session goal-check settings snapshot needed to distinguish assignment from implementation. Free-text goals, recovery plans, recall prompts, answers, and reflections remain in the user's local history but are excluded from the privacy-preserving research export.

## Grains

| Record | Grain | Stable key | Interpretation |
| --- | --- | --- | --- |
| `FocusSession` | One started timer session | Local session ID | Timer behavior and the settings/algorithm snapshot used at start |
| `PromptEvent` | One state transition for one planned goal check | Local prompt ID + event type | `shown` is an in-app exposure; a response is self-report, not passive attention measurement |
| `SessionOutcomeReport` | Zero or one optional post-session report | Session ID | Explicit user-valued progress and interruption burden; missing is never converted to zero |
| `StudyEnrollment` | Zero or one local consent state | Study ID + pseudonymous participant code | Consent time, AB/BA starting sequence, next assignment index, and optional withdrawal time; absence means not enrolled |
| `StudySessionAssignment` | Zero or one assignment for a started session | Study ID + assignment ID | Protocol/version, participant-local session index, condition, and pre-exposure assignment time |
| Research export session | One de-identified local session | Participant code + session index | Relative day/time and structured measures only; no raw IDs, calendar dates, or free text |

## Schema v6 fields

### Measurement context

- `platform`, `appVersion`, and `algorithmVersion` identify implementation changes that may alter event mix.
- `plannedPromptOffsets` records intent separately from exposure.
- `adaptiveCadence`, `cadenceFactor`, and `cadenceReason` make every algorithm decision auditable.
- `notificationsEnabled` and `foregroundSoundEnabled` are the settings snapshot, not proof that the operating system delivered a notification or that the user noticed it.
- `goalChecksEnabled`, `minPromptIntervalSeconds`, `maxPromptIntervalSeconds`, and `responseWindowSeconds` record the actual configuration at session start. They are nullable on migrated v1-v5 rows and required for new v6 study rows.
- `timezoneOffsetMinutes` supports local time-of-day grouping without assuming UTC day boundaries.
- `studyAssignment`, when present, records the assigned condition independently from planned and actual exposure. A sparse assignment can legitimately have zero exposure if checks are disabled or the session is too short.

### Study enrollment and assignment

- `studyEnrollment` exists only after explicit confirmation. `withdrawnAt != null` makes it inactive without rewriting earlier sessions.
- `participantCode` is pseudonymous, not anonymous, and is stored locally. It is not an account or identity proof.
- `sequence` is a secure local draw of `ab` or `ba`; `nextSessionIndex` advances before prompt planning.
- `condition` is `noChecks` or `sparseChecks`. Assignment is the intention-to-treat field; `plannedPromptOffsets` and `shown` events describe actual implementation/exposure.
- Local assignment contains absolute `assignedAt` for audit. Research export v2 replaces it with `assignmentLeadMilliseconds` relative to session start.

### Prompt events

- `promptId` correlates one `shown` event with at most one explicit answer and an optional timeout/end transition.
- `plannedOffsetSeconds` belongs on the `shown` event and distinguishes the plan from actual elapsed exposure.
- `responseLatencySeconds` is derived from focus elapsed time so a wall-clock adjustment does not create a negative response interval.
- `onTask` and `offTask` are momentary self-reports. `skipped`, `delayed`, and `ended` are burden/nonresponse signals, not failure labels.

### Post-session outcomes

- `meaningfulProgress`: `yes`, `no`, or `unsure`; the denominator includes only sessions with an explicit selection.
- `interruptionBurden`: ordinal `0–4`; the current UI offers low-burden anchor choices `0`, `2`, and `4`.
- `answeredAt`: local audit timestamp. It is omitted from the privacy-preserving session row except inside the current local payload.

## Metric contracts

| Metric | Numerator | Denominator | Missing handling | Role |
| --- | --- | --- | --- | --- |
| User-valued session rate | Explicit `meaningfulProgress=yes` | Sessions with any explicit yes/no/unsure answer | Exclude unanswered; always report coverage by condition and completion status | Primary outcome candidate |
| Goal-return rate | Off-task answer followed by on-task at the next answered check in the same session | Off-task answers with a later answered check | Do not treat timeout/stop as return | Primary outcome candidate |
| High-burden rate | Burden rating `3–4` | Sessions with an explicit burden rating | Exclude unanswered; report offered anchors | Guardrail |
| Check response rate | On-task + off-task + acknowledged | In-app `shown` events eligible for response | Report skipped/delayed/timeout separately | Driver |
| Timer completion rate | Sessions reaching planned end | Started sessions with positive elapsed time | Never label as focus or learning success | Behavioral fact |

Every report must include schema/app/algorithm versions, eligible population, local timezone rule, observation window, response coverage, exclusions, and the number of users as well as sessions. Session-level rows are not independent observations when one user contributes several sessions.

### Local data-readiness profile

`buildLocalStudyDataProfile` produces a deterministic, local-only profile before analysis. It separates `noChecks` and `sparseChecks` assignments and reports completion, actual exposure, meaningful-progress response coverage, burden response coverage, high burden, and prompt response/adherence counts. A denominator with no eligible observations is serialized as `null`, never as a manufactured zero.

The current apps offer outcome questions only after a session reaches `completed`. Therefore incomplete/stopped sessions cannot currently provide these answers, and outcome missingness may depend on completion. Reports must stratify outcome coverage by both assigned condition and completion status. This profile exposes the bias; it does not correct it or establish causality.

## Automated quality gates

`validateMeasurementData` checks:

- present and unique session IDs;
- session and event time ordering, future dates, and duration bounds;
- one `shown` exposure per correlated prompt;
- no more than one explicit response per prompt;
- responses that do not precede exposure;
- prompt IDs on schema-v4-and-later events;
- interruption ratings inside `0–4`;
- unique study assignment IDs/indexes within a participant dataset;
- assignment at or before session start;
- zero planned or shown checks in the `noChecks` condition;
- v6 study settings snapshots and valid prompt-interval bounds;
- chronological event order, unique shown offsets, and planned offsets on shown prompts;
- outcome timestamps after session end and not in the future;
- alternating study conditions with contiguous participant-local indexes.

Critical/high issues make a dataset not analysis-ready. A clean report establishes structural validity, not causal validity or absence of selection bias.

## Evaluation design

1. Reliability: physical iPhone/Windows notification acceptance and event-reconciliation checks.
2. Usability: moderated comprehension and burden testing, including assistive technology and DND/Focus conditions.
3. Feasibility: the implemented, explicit-consent local protocol randomizes AB/BA starting order and alternates no checks versus sparse checks. Preserve assignment, exposure, and outcome separately; use intention-to-treat and participant-level/repeated-measures inference. See `LOCAL_CROSSOVER_PROTOCOL.md`.
4. Confirmatory: preregister the primary outcome, burden guardrail, exclusions, missing-data approach, minimum detectable effect, and stopping rule before examining condition differences.
5. Learning mode: use item-level immediate and delayed retrieval accuracy with a suitable no-retrieval comparison. Timer use and self-reported progress are not learning outcomes.

Do not enable silent experimentation, upload research exports, or adapt cadence against post-session outcomes without explicit consent, ethics/privacy review, a declared protocol, and a rollback path.
