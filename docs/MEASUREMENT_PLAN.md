# Measurement and evaluation plan

## Purpose

Evaluate whether sparse goal checks help users return to a chosen task without creating unacceptable interruption burden. Local activity is not automatically evidence of attention, productivity, learning, or well-being.

## KPI hierarchy

### Primary outcome KPIs

1. **User-valued session rate** — sessions with an explicit post-session answer that meaningful progress was made / sessions with a post-session answer. This reflection is proposed and must not be inferred from completion.
2. **Goal-return rate** — off-task responses followed by an on-task response at the next answered check in the same session / off-task responses with a subsequent answered check.
3. **Four-week retained usefulness** — participants still using the feature at week four who rate it useful / participants who started an evaluation. Use only in an opt-in study, not silent telemetry.

### Driver metrics

- Check response rate = on-task + off-task + acknowledged responses / checks shown.
- Off-task self-report share = off-task responses / answered checks.
- Planned-session completion rate and timer minutes, labeled only as behavior.
- Recovery-plan presence and goal presence at session start.

### Guardrails

- Skip rate and “turn feature off” rate.
- Notification permission denial after an in-context request.
- Prompt timing outside configured bounds, duplicate/stale notifications, crash-free sessions.
- Whole-session check disable rate, repeated timeout burden, and any cadence change caused by a self-report.
- Accessibility violations, battery complaints, and data-loss reports.
- A notification opt-in increase is not itself a success metric.

## Metric contract

Every metric must specify: event types, numerator, denominator, eligible population, time window, timezone, missing-response handling, schema version, and whether it is an outcome, driver, or guardrail. `FocusSession.completed` means the timer reached its planned end; it is not a successful-focus label. `PromptResponseType.onTask/offTask` is self-report, not passive cognitive measurement.

Schema `v6` retains correlated prompt IDs, planned-versus-shown offsets, elapsed-time response latency, platform/app/algorithm snapshots, transparent cadence reasons, optional post-session progress/burden answers, explicit local enrollment, and pre-exposure assignment. It adds the actual goal-check enabled state, configured interval bounds, and response-window snapshot for each new study session. See `DATA_DICTIONARY.md` and `LOCAL_CROSSOVER_PROTOCOL.md`. The structural validator and local study profile must run before analysis; passing them does not remove self-selection, nonresponse, measurement-reactivity, carryover, or repeated-measures bias.

## Evaluation sequence

1. **Reliability phase:** pass unit/build gates and physical-device notification acceptance; inspect timing and migration failures.
2. **Usability phase:** moderated sessions across keyboard, screen reader/text scaling, Focus/DND, and interrupted workflows. Measure comprehension and burden.
3. **Feasibility phase:** opt-in within-person crossover comparing no checks with sparse checks. The implementation supports randomized AB/BA starting order, alternation, and assignment-first persistence; freeze and externally preregister a cohort-specific analysis plan before examining real condition differences.
4. **Confirmatory phase:** only if feasibility is positive, run a sufficiently powered randomized evaluation with a user-valued outcome and burden guardrails.

Do not tune the cadence against completion minutes or short-term app opens alone. That would optimize timer/app adherence, not the stated outcome. Off-task responses must never trigger more interruptions; only burden signals such as repeated skips may lengthen cadence. There is no evidence-backed universal optimum for the 12–18-minute default, so frequency changes require a preregistered comparison with burden guardrails.

Observational product logs can identify reliability and usability problems, but they cannot establish that a cadence caused better outcomes. In experiments, store assignment before exposure, distinguish assignment from actual exposure, analyze repeated sessions at the participant level, report missing-outcome coverage by arm and completion status, and do not condition the primary analysis on answering a prompt.

The current outcome questions are available only after completed sessions. Consequently, incomplete sessions have structurally missing outcomes and the observed outcome subset can be selected on completion. Until outcome collection is redesigned and usability-tested for stopped sessions, report this limitation prominently; do not impute failure/success or describe complete-case differences as the intervention effect.

The implemented local protocol is exploratory infrastructure, not proof of effectiveness. Its primary analysis contract is intention to treat by assignment; actual prompt exposure is an implementation diagnostic. Never silently enroll existing users, automatically export data, or use interim outcome differences to change defaults or stop collection.

## Learning-mode rule

Learning claims require actual retrieval prompts tied to studied material and a delayed retention measure. If implemented, report accuracy by retention interval and material—not “study time”—and preserve a no-retrieval comparison. Until the loop in `LEARNING_MODE_SPEC.md` exists, learning mode remains an experimental domain model, not a marketed feature.
