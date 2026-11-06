# Changelog

## 0.2.0 - Unreleased

- Upgraded the local measurement schema to v4 with algorithm/version snapshots, planned-versus-shown prompt timing, correlated responses, elapsed-time latency, and optional post-session progress/burden feedback.
- Added structural data-quality validation and a research export that excludes raw session IDs, calendar dates, and free text by default.
- Added cross-platform persistence and UI for optional local outcome feedback; unanswered outcomes remain missing rather than being scored as failure.
- Upgraded the local schema to v5 with explicit-consent study enrollment, randomized AB/BA starting order, alternating no-check/sparse-check assignment, and assignment persistence before exposure.
- Added protocol quality gates for duplicate or post-start assignment and any control-arm prompt exposure, plus a versioned exploratory protocol that prohibits silent enrollment, upload, outcome-conditioned exclusion, and outcome-driven tuning.
- Upgraded research export to v2 so study condition remains analyzable without exporting the absolute assignment timestamp.
- Upgraded the local schema to v6 with per-session goal-check, interval, and response-window snapshots while retaining nullable migration for older rows.
- Added condition-stratified local study profiling for assignment, completion, exposure, outcome coverage, burden, and prompt adherence; unavailable rates remain null instead of becoming false zeros.
- Expanded structural gates for settings snapshots, event chronology, planned exposure, outcome timing, and alternating contiguous assignments.
- Documented completion-dependent outcome missingness and prohibited complete-case differences from being described as causal effects.

### Fixed

- Seconds replayed after the iOS app returned from the background, or after either app's timer was suspended (sleep), no longer log checks the user never saw as `shown` + `ended`. They are now recorded as a new `missed` event that is not exposure, and no stale sound or Windows toast is played. iOS now observes the app lifecycle.
- Adaptive cadence now counts timeouts (`ended`) and Windows “ask later” (`delayed`) as unanswered burden alongside skips, and counts them toward the six-check minimum. Previously the most common outcome under silent defaults, a timeout, was invisible to the burden rule, so it could never lengthen cadence. Missed checks and legacy 0.1 microbreak ends are ignored.
- The structural validator, local outcome summary (`cuesMissed`), and study profile (`missedChecks`) understand `missed` prompts. Architecture documentation now states schema v6.

### Changed

- Reframed mandatory microbreaks as sparse, skippable goal checks.
- Changed fresh defaults to 50/10-minute sessions, 12–18-minute checks, a 20-second window, and notifications/sound off.
- Added explicit on-task, off-task, skip, and typed lifecycle events.
- Added concrete session goals and an implementation-intention recovery plan.
- Made the distraction trigger and recovery action user-editable and added an explicit whole-session goal-check switch.
- Changed adaptation so off-task self-reports never increase future interruption frequency; high skip burden still lengthens cadence.
- Centralized cross-platform models, migration, planner, adaptation, and outcome summaries in `focus_core`.
- Reworded statistics so timer behavior is not presented as attention or learning effectiveness.
- Added recoverable Windows JSON writes and neutralized unsupported “brain processing” rest copy.

### Quality

- Added unit/widget coverage for controller event sequences, uninterrupted focus timing, response timeout, stop/completion cleanup, seeded-plan parity, goal normalization, accessible actions, partial corruption, and atomic persistence.
- Expanded the evidence audit with interruption counterexamples, probe-reactivity limits, modern planning estimates, classroom retrieval, feedback, retention, transfer, and a non-marketed learning-mode specification.
- Added GitHub Actions for core/app quality, Windows release build, and iOS simulator build.
- Added evidence, measurement, privacy, architecture, contribution, security, and physical-device acceptance documentation.

### Pending before release

- Physical iPhone notification lifecycle acceptance.
- Physical Windows toast/tray/Focus Assist/sleep-wake acceptance.
