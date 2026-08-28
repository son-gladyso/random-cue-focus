# Local-only AI handoff: Random Cue Focus A+ candidate

This document is the canonical handoff for the next AI. That AI is assumed to have **no GitHub access, no GitHub connector, and no product/research plugins**. Everything assigned below can be completed from the local filesystem and local toolchain. Do not wait for, simulate, or claim any remote GitHub result.

Last updated: 2026-08-28 (Asia/Shanghai)

## 1. Exact workspace state

- Repository: `D:\ZANSHI\CK3\random-cue-focus`
- Active branch: `codex/a-plus-evidence-upgrade`
- Base commit: `153fed7d04e91c078800bb3c160c57cb2a92065e`
- The original `G:\CK3` workspace is temporarily unavailable. Do not move work back there.
- The working tree is intentionally dirty and contains the current upgrade. **Do not reset, checkout over, clean, delete, or recreate it.**
- A shallow Flutter stable checkout exists at `D:\ZANSHI\CK3\.tools\flutter` (outside the repo and therefore not committable).
- The local SDK is initialized: Flutter 3.47.1 stable, Dart 3.13.1, engine `5d53178869`, DevTools 2.60.0. The four official Windows engine archives were size/MD5 checked before extraction.
- Local format, strict analysis, shared/iOS/Windows tests, and the Windows release build pass. No iOS binary build is claimed from Windows.
- `git diff --check` has no whitespace errors. It prints only expected Windows LF/CRLF conversion warnings.

### 1.1 Continuation result (2026-08-28)

- Shared core: format 0 changed, `dart analyze --fatal-infos` clean, 25/25 tests passed.
- iOS Dart layer on Windows: format 0 changed, `flutter analyze --fatal-infos` clean, 15/15 tests passed.
- Windows: format 0 changed, `flutter analyze --fatal-infos` clean, 13/13 tests passed, `flutter build windows --release` passed. This checkout still emits Flutter's generic `runner/Release` success line, but the verified executable is at `apps/windows/build/windows/x64/runner_workaround/Release/random_cue_focus_windows.exe`.
- The Windows runner now compiles source as UTF-8. The repository did not contain the `.ico` referenced by `Runner.rc`, so the window and tray use the Windows application icon as a reliable fallback until a reviewed product icon is supplied.
- Windows Computer Use could not attach because its native pipe was unavailable. No GUI clicks, screenshots, toast/tray acceptance, or physical Windows claims were fabricated; those boxes remain unchecked in `docs/DEVICE_ACCEPTANCE.md`.
- Measurement schema v6 retains the v5 enrollment/assignment contract and adds the actual goal-check enabled, interval, and response-window settings snapshot for every new study session; migrated v1-v5 rows keep these fields nullable.
- Both apps implement an off-by-default exploratory crossover with a secure AB/BA starting-order draw, alternating no-check/sparse-check sessions, withdrawal, assignment persistence before exposure, and no automatic upload. It is not an effectiveness result or external preregistration.
- Shared core validates duplicate/post-start assignments, control-arm exposure, v6 settings snapshots, event chronology, outcome timing, and assignment alternation. `buildLocalStudyDataProfile` reports completion, exposure, outcome coverage, burden, and prompt adherence separately by assigned condition without replacing unavailable denominators with zero.
- The current apps offer outcome questions only after completed sessions. Outcomes for incomplete/stopped sessions are therefore structurally missing and complete-case arm differences must not be described as causal effects. Coverage must be reported by condition and completion status.
- Privacy-preserving research export v2 excludes raw session IDs, session calendar dates, absolute assignment timestamps, and free text by default. Metric definitions and experiment boundaries are in `docs/DATA_DICTIONARY.md` and `docs/LOCAL_CROSSOVER_PROTOCOL.md`.
- iOS now continues the timer if optional notification scheduling fails, and a failed enrollment write does not consume the next assignment.
- Physical iPhone gates, iOS build/signing, GitHub push/PR/Actions, and remote release checks remain intentionally untouched.

Start every work session with:

```powershell
Set-Location 'D:\ZANSHI\CK3\random-cue-focus'
git branch --show-current
git status --short
git diff --check
```

Expected branch is exactly `codex/a-plus-evidence-upgrade`. If it is not, stop and inspect before editing. Preserve every existing modification and untracked file listed by `git status`.

## 2. Product decision that must not be reversed casually

The prototype used frequent random audible cues and a mandatory 10-second “microbreak.” The evidence review found that this was too strong and potentially disruptive as a default. The intended `0.2.0` product is:

- a local-first focus timer;
- a concrete session goal plus an if–then recovery plan;
- sparse, skippable goal checks;
- explicit self-report: `onTask`, `offTask`, or `skipped`;
- focus time continues while the check is visible;
- 50-minute focus, 10-minute rest, 12–18-minute check range, and 20-second response window on a fresh install;
- notifications and foreground sound off on a fresh install;
- a transparent local heuristic that waits for at least 3 sessions and 6 answers, and reduces prompt burden when skip rate is high;
- no claim that timer completion equals attention, productivity, learning, or health improvement.

Do not reintroduce mandatory breaks, high-priority notifications, default sound, “dopamine reset,” left/right-brain or learning-style claims, clinical language, or guaranteed learning/productivity claims. Read `docs/EVIDENCE_BASE.md` before changing any default or rationale.

## 3. What is already implemented

### Shared core

New package: `packages/focus_core`

- `lib/src/models.dart`: schema version 6, safe normalization, fresh defaults, typed/correlated prompt responses, legacy notification-key compatibility, legacy `microbreak_start/end` migration, session goal/recovery/learning fields, measurement context, optional outcome reports, study enrollment/assignment, migrated whole-session goal-check switch, and per-session study settings snapshots.
- `lib/src/prompt_planner.dart`: deterministic seeded planning, eight-check cap, session-end guard, optional cadence adaptation, minimum history requirement, burden-reduction rule, and no checks when the user disables them. Off-task reports never increase future prompt burden.
- `lib/src/local_outcomes.dart`: separates timer completion, checks shown, answers/skips, and learning reflections; never turns timer minutes into cognition scores.
- `lib/src/measurement.dart`: validates session keys, timing/bounds, correlated exposure/response counts, burden ratings, study settings snapshots, event/outcome chronology, and assignment continuity before analysis.
- `lib/src/study_metrics.dart`: builds a local, condition-stratified data-readiness profile with explicit eligible denominators and nullable unavailable rates.
- `lib/src/study_protocol.dart`: defines versioned consent enrollment, pseudonymous participant codes, secure AB/BA start order, alternating assignment, and withdrawal behavior.
- `lib/src/research_export.dart`: creates a structured, explicit export without local IDs, session dates, absolute assignment time, or free text.
- Tests exist for model migration, round-trip safety, planning bounds/determinism, adaptive burden reduction, metric separation, study assignment, structural validation, privacy export, and data-readiness profiling.

Both applications now depend on this package through `path: ../../packages/focus_core`. Their old `models.dart` and planner files re-export the shared API so existing imports remain stable.

### iOS

- Engine now records typed `shown/onTask/offTask/skipped/ended` events.
- Goal-check time no longer pauses focus elapsed time.
- Goal, if–then plan, and recall prompt are saved with sessions.
- Focus screen shows a goal-check card with three 44-point actions.
- Settings allow a concrete goal, user-authored distraction trigger and recovery action, 5–45-minute configurable intervals, 5–60-second check window, whole-session check disable, opt-in sound/notification, and an adaptive-burden switch.
- Notification request no longer requests sound permission; scheduled checks use default importance and no sound.
- Notification copy is neutral and says the check may be ignored.
- iOS permission usage text is updated.

### Windows

- Controller records the same typed responses and preserves focus time during the check.
- Dashboard shows the current goal and `仍在目标 / 刚刚走神 / 稍后再问` actions.
- Settings include the session goal, editable distraction trigger/recovery action, the if–then plan, and whole-session check disable.
- Settings and sessions use same-directory temporary files plus backup recovery; corrupt individual session entries no longer hide readable history, and first-session append is mutable and tested.
- Notifications and foreground sound are labeled default-off; notification copy is neutral.
- Statistics were renamed to behavioral facts such as `计时完成率` and `检查显示`.

### Quality, research, and governance files

- `.github/workflows/ci.yml` describes remote gates but is not assigned to this local-only AI to run remotely.
- `.github/dependabot.yml` and `.github/pull_request_template.md` exist.
- `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md` exist.
- `docs/EVIDENCE_BASE.md`, `docs/MEASUREMENT_PLAN.md`, `docs/DEVICE_ACCEPTANCE.md`, `docs/PRIVACY.md`, and `docs/ARCHITECTURE.md` exist.

## 4. Your local-only mission, in order

Do not jump directly to visual polish. Complete the stages in order because later work depends on earlier compilation.

### Stage A — resume the local SDK and establish facts

```powershell
$Flutter = 'D:\ZANSHI\CK3\.tools\flutter\bin\flutter.bat'
$Dart = 'D:\ZANSHI\CK3\.tools\flutter\bin\dart.bat'

& $Flutter --version
& $Flutter doctor -v
```

Allow the first command to finish downloading the official Dart/engine cache. If it fails, capture the exact error and retry only when the failure is plausibly transient. Do not delete the tool directory as a first response. Record Flutter and Dart versions in your final handoff note.

`flutter doctor` may report missing Android tooling; Android is out of scope. A missing Visual Studio C++ desktop workload blocks the Windows build but does not block shared/iOS Dart analysis. Report the precise component, not a generic “environment problem.”

### Stage B — format and validate the shared core first

```powershell
Push-Location 'packages\focus_core'
& $Dart pub get
& $Dart format lib test
& $Dart analyze --fatal-infos
& $Dart test
Pop-Location
```

Fix root causes with the smallest coherent patch. Do not weaken lints or delete a failing assertion merely to make the suite green. Add a regression test for every behavior bug you find.

Required invariants:

- fresh defaults normalize to 50/10 minutes, 12–18 minutes, 20 seconds, sound/notification off;
- old notification keys still load;
- old microbreak strings become typed events;
- a plan never schedules outside the focus session or more than eight checks;
- the same seed and inputs produce the same plan;
- insufficient history produces a factor of 1;
- many skips lengthen, rather than shorten, the cadence;
- output metrics remain nullable when no valid denominator exists and never exceed `[0, 1]`.

### Stage C — format, analyze, and test both Flutter apps

Run iOS app checks on Windows even though an iOS binary cannot be built there:

```powershell
Push-Location 'apps\ios'
& $Flutter pub get
& $Dart format lib test
& $Flutter analyze --fatal-infos
& $Flutter test
Pop-Location
```

Then Windows:

```powershell
Push-Location 'apps\windows'
& $Flutter pub get
& $Dart format lib test
& $Flutter analyze --fatal-infos
& $Flutter test
Pop-Location
```

Pay special attention to likely first-pass failures:

1. `flutter_local_notifications` API compatibility for `initialize`, `zonedSchedule`, Darwin details, and cancellation.
2. `CupertinoTextField` API/semantics and small-screen layout after adding `GoalCheckCard`.
3. Re-export imports from the shared path package.
4. `PromptEvent` constructor migrations in all tests and production code.
5. Async callbacks used where Flutter expects `void` callbacks.
6. Line formatting introduced by the current patch.

Search after fixes:

```powershell
rg -n "event:|microbreak_start|microbreak_end|停 10 秒|随机提示音（默认）|完成率|guarantee|dopamine|learning styles" apps packages README.md docs
```

Legacy strings may remain only inside migration tests/parsers or evidence/history explanations. A label such as `计时完成率` is allowed; a bare metric implying focus success is not.

### Stage D — add missing local regression and accessibility tests

At minimum, add or improve tests for:

- iOS/Windows wrappers produce the same seeded plan as `focus_core`;
- starting, responding to, skipping, and timing out a goal check produces the expected typed event sequence;
- focus elapsed seconds continue during the response window;
- stopping/completing does not leave the controller in a goal-check phase;
- goal text is normalized to the documented maximum length;
- the iOS goal-check actions expose readable semantics and at least 44x44 logical-pixel hit targets;
- Windows settings accept/save a goal without resetting unrelated settings;
- corrupt individual session records do not make all history unreadable.

Prefer controller/domain tests over long real-time sleeps. Introduce an injectable clock/ticker only if necessary and keep the design comprehensible. Do not add network telemetry or a large state-management framework.

### Stage E — improve local persistence reliability

Review `apps/windows/lib/repositories.dart`. Its writes currently go directly to `settings.json` and `sessions.json`. Implement a tested, recoverable write strategy (temporary file in the same directory, flush, replace/backup, cleanup, and restoration on failure) without risking deletion outside the app-data directory. Verify non-ASCII paths and individually corrupt session entries.

Review `apps/ios/lib/stores.dart`. Preserve safe fallback behavior but add tests proving settings migration and partial session corruption handling. Do not silently label unreadable data as valid. If you add diagnostics, keep them local and free of goal text.

### Stage F — Windows build and local executable QA

```powershell
& $Flutter config --enable-windows-desktop
Push-Location 'apps\windows'
& $Flutter build windows --release
Pop-Location
```

If the build succeeds, run the release app from this checkout's generated `build\windows\x64\runner_workaround\Release` directory. If you can control the GUI, inspect at minimum:

- default-off notification/sound and default-on tray settings;
- goal entry/save and preservation after restart;
- idle, focusing, paused, goal-check, resting, completed, and stopped states;
- all three goal-check responses;
- narrow/short window, 100%, 150%, and 200% scaling, keyboard-only navigation, focus visibility, long Chinese goal text, and high contrast where available;
- one explicit opt-in toast, Focus Assist/Do Not Disturb suppression, minimize-to-tray, sleep/wake, stop, and rapid restart;
- no duplicate or stale toast after stop/completion;
- local history labels say behavior, not effectiveness.

For a practical manual goal check, set focus to 15 minutes and both check intervals to 5 minutes. Do not add a production-only secret shortcut merely to speed QA. Record evidence and update only the Windows section of `docs/DEVICE_ACCEPTANCE.md` for checks actually run on identifiable hardware. Leave unavailable checks unchecked with a concise reason.

### Stage G — local documentation and diff audit

After code behavior stabilizes:

1. Make README commands match the commands that actually passed.
2. Update `CHANGELOG.md` for material changes you made.
3. Update architecture/privacy/device-acceptance documents if storage or notification behavior changed.
4. Check that every evidence link is syntactically valid; do not fabricate a source or quote.
5. Check `.github/workflows/ci.yml` for YAML/path consistency only. Do not claim it ran.
6. Run:

```powershell
git diff --check
git status --short
git diff --stat
git diff -- README.md CHANGELOG.md docs
```

Fix whitespace errors. Do not normalize every file's line endings or create a noisy whole-repository diff.

## 5. Explicit non-tasks for this AI

The following require GitHub access, another OS/device, or external authority and are **not your responsibility**:

- pushing the branch;
- creating, editing, merging, or commenting on a pull request;
- viewing or rerunning GitHub Actions;
- changing branch protections, secrets, repository settings, releases, tags, or Dependabot configuration through GitHub;
- claiming iOS simulator/build success from Windows;
- signing an iOS app;
- marking physical iPhone notification acceptance complete;
- claiming physical Windows checks that you did not personally execute;
- merging to `main`;
- adding cloud telemetry, accounts, sync, or external services;
- commissioning or claiming a randomized effectiveness trial.

Do not spend time searching for unavailable GitHub/plugin tools. Work locally and leave a precise evidence-backed handoff for the agent that has them.

## 6. Files most likely to need careful review

- `packages/focus_core/lib/src/models.dart`
- `packages/focus_core/lib/src/prompt_planner.dart`
- `packages/focus_core/lib/src/local_outcomes.dart`
- `apps/ios/lib/focus_engine.dart`
- `apps/ios/lib/screens.dart`
- `apps/ios/lib/notification_service.dart`
- `apps/ios/lib/stores.dart`
- `apps/windows/lib/focus_controller.dart`
- `apps/windows/lib/dashboard.dart`
- `apps/windows/lib/notification_adapter.dart`
- `apps/windows/lib/repositories.dart`
- both app test directories and `packages/focus_core/test`

Avoid editing generated Flutter platform files unless a verified build or plugin integration requires it.

## 7. Local definition of done

Your local work is complete only when all achievable items are true:

- shared core format/analyze/tests pass;
- iOS Dart format/analyze/tests pass on Windows;
- Windows format/analyze/tests pass;
- Windows release build passes, or the exact external toolchain blocker is documented;
- new controller/persistence/accessibility regression tests pass;
- no known claim says timing equals cognitive/learning effectiveness;
- `git diff --check` has no errors;
- device checks are marked only with real evidence;
- no existing user change was discarded;
- you provide exact command results, changed files, unresolved blockers, and the next single action.

Do not describe the product as “A+ complete.” The strongest honest status before physical iPhone and Windows notification acceptance is **A+-candidate, local engineering checks passed, physical release gates pending**.

## 8. Final response template for the local-only AI

Use this compact structure so the GitHub-capable follow-up can act without re-auditing everything:

```text
Local outcome: [passed / partially passed / blocked]

Verified
- Flutter/Dart versions:
- Shared core: format __, analyze __, tests __/__
- iOS on Windows: format __, analyze __, tests __/__ (no iOS build claimed)
- Windows: format __, analyze __, tests __/__, release build __
- Manual Windows checks actually run:

Changed after handoff
- file: reason

Still unresolved
- exact issue, evidence/error, and why it remains

Remote/physical gates intentionally untouched
- GitHub push/PR/Actions
- physical iPhone acceptance
- any unrun Windows hardware cases

Next single action for GitHub-capable AI
- inspect local diff, commit/push branch, open PR, and monitor CI; do not merge until physical gates are explicit
```
