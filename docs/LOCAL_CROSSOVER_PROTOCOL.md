# Local crossover feasibility protocol

Protocol ID: `rcf-local-crossover`

Protocol version: `1.0.0`

Status: **implemented protocol draft; not externally preregistered and no effectiveness result exists**

## Purpose and decision

This exploratory, opt-in study asks whether sparse, skippable goal checks are sufficiently useful and low-burden to justify a larger evaluation. It compares them with otherwise equivalent sessions in which no goal check is shown. It does not test a diagnosis, treatment, neuroscience mechanism, learning outcome, or universal productivity benefit.

The decision after feasibility is one of: stop the feature, revise its burden/measurement, or design a separately preregistered and adequately powered confirmatory study. App use, timer minutes, and statistical significance alone are not go criteria.

## Consent and scope

- Enrollment is off by default and requires an explicit confirmation dialog.
- The dialog explains both conditions, local storage, optional outcome questions, no automatic upload, and the right to leave at any time.
- Enrollment creates a pseudonymous local participant code. The app has no account and does not collect identity fields.
- Leaving the study stops future assignment immediately. Existing local sessions remain until the user clears app data/history or follows the operating system's removal path.
- Research export is a separate explicit action in the shared domain API; neither app uploads data.
- Product use must remain available to people who decline or leave.

This implementation is suitable for personal feasibility work and protocol testing. Recruitment of other people, data transfer, publication, or institutional work requires the applicable ethics, privacy, consent, retention, and security review before collection begins.

## Conditions and assignment

| Condition | Behavior | Interpretation |
| --- | --- | --- |
| `noChecks` | No goal checks are planned or shown; timer and other user-selected behavior remain available | Control session for the incremental effect and burden of checks |
| `sparseChecks` | The current bounded, skippable goal-check planner is used | Assigned intervention; actual exposure may still be zero if the user disabled checks or the session is too short |

At consent, a cryptographically secure local draw chooses starting sequence `AB` or `BA`, where A is `noChecks` and B is `sparseChecks`. Sessions then alternate conditions. This balances starting order but is not population-level randomization unless many independently enrolled participants contribute data.

Before prompt planning or exposure, the app:

1. derives the next assignment from the stored sequence and index;
2. saves the advanced enrollment state locally;
3. stores the assignment in the session measurement context;
4. plans prompts using the assigned condition.

The assignment record includes protocol/version, assignment ID, participant-local session index, condition, and assignment time. A write failure must prevent exposure rather than silently create an unrecorded assignment. Duplicate assignment IDs, assignment after session start, or any planned/shown check in `noChecks` are critical data-quality errors.

## Measures

Candidate primary feasibility outcome:

- user-valued session rate: explicit `meaningfulProgress=yes` divided by sessions with an explicit yes/no/unsure answer.

Primary burden guardrail:

- high-burden rate: burden `3–4` divided by sessions with an explicit burden answer.

Supporting measures include outcome response coverage, checks planned/shown, response/skip/timeout mix, response latency, session completion as a behavioral fact, whole-session check disabling, and protocol violations. Goal-return rate is exploratory because it exists only in sessions with multiple answered checks and cannot be compared naively with a no-check arm.

Post-session answers are optional. Missing answers remain missing; they are never scored as failure or success. Every arm-level result must show both participant and session counts, eligible denominators, and outcome-response coverage. Because the current UI asks only after completed sessions, coverage must also be stratified by completion status and complete-case outcome differences must not be presented as causal effects.

## Analysis contract

Before examining condition differences for any real cohort, freeze a dated analysis plan containing the estimand, minimum sample/precision target, exclusions, missing-data strategy, stopping rule, and multiplicity treatment. This repository document is not that preregistration.

- Primary analysis follows intention to treat by stored assignment.
- Report actual prompt exposure separately as an adherence/implementation diagnostic, not as a replacement for assignment.
- Account for repeated sessions within a participant using participant-level paired summaries or an appropriate repeated-measures model. Do not treat sessions as independent people.
- Include sequence/order, session index, app/algorithm version, and platform in diagnostics. Carryover and time trends are plausible; alternating sessions do not eliminate them.
- Do not exclude sessions because the outcome, prompt answer, or burden answer was unfavorable or missing.
- Do not tune cadence, stop collection, or select a primary outcome after viewing an arm difference.
- Report uncertainty and effect sizes. A small exploratory p-value does not establish effectiveness.
- Analyze Windows and iOS delivery/exposure differences before pooling. OS notification delivery is not inferred from scheduling records.

## Planned data-quality gates

Before analysis, run the shared structural validator and `buildLocalStudyDataProfile`, then reconcile:

- unique session and assignment keys within each participant export;
- assignment timestamp at or before session start;
- no exposure in assigned `noChecks` sessions;
- planned-versus-shown prompt counts and timing;
- exactly one explicit response at most per shown prompt;
- valid outcome ranges and missingness by condition;
- completion, actual exposure, outcome-response coverage, and high burden separately by condition;
- v6 goal-check enabled, interval, and response-window snapshots for new study sessions;
- schema, app, algorithm, protocol, platform, and export versions;
- physical device acceptance for the platform behavior being studied.

Critical/high structural issues make the affected data not analysis-ready. Passing these checks does not remove self-selection, demand characteristics, probe reactivity, attrition, or carryover bias.

## Privacy-preserving export

Research export schema v2 removes raw session IDs, free text, mode names, session calendar dates, and the absolute assignment timestamp. It retains the explicitly supplied participant code, relative day, local minute of day, assignment condition/index, and assignment lead time relative to session start. The export timestamp remains as file provenance. Small-sample combinations can still be identifying and require review before sharing.

## Stop and rollback rules

Pause collection and investigate if there is consent-state loss, assignment after exposure, a check in the control arm, duplicate/stale notifications, data loss, a material accessibility regression, or unexpected sensitive-data export. The local feature can be disabled without changing ordinary timer use. No collected result may silently enable checks, notifications, uploads, or outcome-driven personalization for other users.

## Learning boundary

This study concerns goal checks and user-valued session experience only. Learning claims require actual studied material, unaided retrieval, verification/correction, delayed retention, and transfer measures under the separate learning-mode specification.
