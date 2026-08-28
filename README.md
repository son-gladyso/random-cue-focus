# Random Cue Focus

Random Cue Focus is a local-first Flutter focus companion for iOS and Windows. Version `0.2.0` replaces the prototype's frequent, mandatory “microbreak” framing with sparse, skippable goal checks that are silent and non-notifying by default.

The product is **evidence-informed, not clinically validated**. It helps a person state a concrete goal, occasionally check whether they are still pursuing it, and use a simple if–then recovery plan after distraction. It does not claim to diagnose attention, increase productivity, or improve learning from timer usage alone.

## What is implemented

- One shared, tested Dart package for settings, session models, migration, cue planning, adaptive burden reduction, opt-in crossover assignment, local outcome summaries, condition-stratified data-readiness profiling, data-quality checks, and privacy-preserving research export.
- iOS and Windows apps with focus/pause/rest/stop states, goal checks, local history, and platform adapters.
- Fresh-install defaults: 50-minute focus, 10-minute rest, 12–18-minute check range, 20-second response window, notifications off, foreground sound off.
- Explicit responses: “still on goal”, “just distracted”, or “skip”; focus time continues during the check.
- Nonessential goal checks can be disabled for an entire session; off-task reports never cause the heuristic to increase interruption frequency.
- The goal, distraction trigger, and next recovery action are user-editable instead of being treated as a universal script.
- Local-only storage with no account, server, API key, advertising SDK, or remote analytics.
- Optional post-session progress and interruption-burden answers are stored locally and remain missing when the user does not answer.
- An experimental local crossover is available only after explicit consent. It alternates no-check and sparse-check sessions, persists assignment before exposure, never uploads automatically, and can be left at any time.
- CI for shared-core tests, both app analyzers/tests, Windows release build, and iOS simulator build.

Existing version `0.1.x` settings and session events are migrated rather than silently discarded. Schema version `6` retains all earlier migrations, explicit study enrollment, and per-session assignment while adding the actual goal-check enabled, interval, and response-window snapshot for new study sessions. Research export schema v2 removes the absolute assignment timestamp as well as raw session IDs, dates, and free text. The adaptive cadence is a deterministic, inspectable heuristic—not a machine-learning model—and waits for at least three sessions and six responses before changing an interval.

## Evidence boundary

The design gives the most weight to direct, converging findings and makes indirect inference explicit:

- Alerts can disrupt an active task, so external notification and sound defaults are off.
- Short breaks show more consistent benefits for vigor/fatigue than for cognitive performance, so a check is optional and no performance benefit is promised.
- User-authored implementation intentions and self-monitoring are plausible recovery supports, but modern bias-robust estimates are smaller than early meta-analytic estimates, and this exact app and its 12–18-minute default have not been validated in a randomized product trial.
- Retrieval practice and spacing have stronger learning evidence, but a timer is not a retrieval-practice intervention by itself.

See [Evidence base](docs/EVIDENCE_BASE.md), [Measurement plan](docs/MEASUREMENT_PLAN.md), [data dictionary](docs/DATA_DICTIONARY.md), [local crossover protocol](docs/LOCAL_CROSSOVER_PROTOCOL.md), and [experimental learning-mode specification](docs/LEARNING_MODE_SPEC.md) for the claim-to-feature matrix, limitations, evaluation design, schema contract, and the minimum evidence-valid learning loop.

## Repository layout

```text
packages/focus_core/  shared domain model, migration, planner, outcomes, tests
apps/ios/             Flutter iOS app and local-notification adapter
apps/windows/         Flutter Windows app and native toast/tray adapter
docs/                 evidence, architecture, privacy, and release acceptance
.github/               CI, dependency updates, and contribution gates
```

## Develop

Install the current stable Flutter SDK.

```powershell
cd packages\focus_core
dart pub get
dart analyze --fatal-infos
dart test

cd ..\..\apps\windows
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d windows
```

Run the equivalent analyze/test commands inside `apps/ios`. Building iOS requires Xcode on macOS; signing and physical-device notification verification require an Apple development setup.

## Release status

| Gate | Status |
|---|---|
| Shared core tests | Automated in CI |
| iOS analyze/tests | Automated in CI |
| iOS simulator build | Automated in CI |
| Windows analyze/tests/release build | Automated in CI |
| Physical iPhone notification lifecycle | **Pending** |
| Physical Windows toast, Focus Assist, sleep/wake, and tray behavior | **Pending** |
| Product-level effectiveness trial | **Not performed** |

This is an A+-candidate engineering upgrade, not an A+ release declaration. Release acceptance remains blocked until the checks in [Device acceptance](docs/DEVICE_ACCEPTANCE.md) are run on named hardware and the evidence is attached.

## Privacy and security

See [Privacy](docs/PRIVACY.md), [Security policy](SECURITY.md), and [Architecture](docs/ARCHITECTURE.md). All current product data stays on the device and can be removed by clearing history or uninstalling the app.
