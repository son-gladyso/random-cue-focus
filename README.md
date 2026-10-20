# Random Cue Focus

[简体中文](docs/i18n/README.zh-CN.md) · English · [日本語](docs/i18n/README.ja.md) · [한국어](docs/i18n/README.ko.md) · [Español](docs/i18n/README.es.md) · [Français](docs/i18n/README.fr.md) · [Deutsch](docs/i18n/README.de.md) · [Português (Brasil)](docs/i18n/README.pt-BR.md)

**Return to the task you chose, without making every focus session a stream of alerts.**

Random Cue Focus is a local-first Flutter companion for people who want an occasional, optional reminder of their own goal on iOS or Windows. Version `0.2.0` replaces the prototype's frequent, mandatory “microbreak” framing with sparse, skippable goal checks that are silent and non-notifying by default.

The product is **evidence-informed, not clinically validated**. It helps a person state a concrete goal, occasionally check whether they are still pursuing it, and use a simple if–then recovery plan after distraction. It does not claim to diagnose attention, increase productivity, or improve learning from timer usage alone.

[Try a session](#a-session-in-practice) · [Developer setup](#develop) · [Release readiness](#release-status) · [FAQ](#common-questions) · [Contribute](#help-make-it-easier-to-use-and-verify)

## When it may fit

Use it when you want a lightweight way to reconnect with your own task, without turning every focus session into a stream of alerts.

- State a concrete goal before starting.
- Keep working through an occasional, optional goal check.
- If you notice distraction, use a recovery action you wrote yourself.
- Review local session history without creating an account.

You can skip a check or disable nonessential checks for a session. The goal is to make self-checking available without making interruption mandatory; whether it helps you is not established by a timer or session count.

## A session in practice

1. Set a goal and a simple “if I get distracted, then…” recovery action.
2. Start a focus session. Fresh installs keep notifications and foreground sound off.
3. When a goal check appears, choose “still on goal”, “just distracted”, or “skip”. Focus time continues.
4. Pause, rest, or stop as needed, then optionally record progress and interruption burden.
5. Inspect the history stored on your device.

Build and run instructions are in [Develop](#develop). No device recording is included here yet; the [release status](#release-status) distinguishes automated checks from physical-device work that remains pending.

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

## Common questions

**How is this different from a mandatory break timer?** A goal check does not stop focus time. You can respond, skip it, or disable nonessential checks for the whole session. Rest remains a separate state.

**Will it interrupt me more if I report being distracted?** The documented burden-reduction heuristic does not increase interruption frequency after off-task self-reports. It is deterministic and inspectable, not a learned attention model.

**Why am I not hearing reminders?** Fresh installs keep foreground sound and external notifications off. Check settings deliberately rather than assuming a silent session has failed. OS permissions and background behavior also need platform-specific verification.

**Can I install the iPhone app from Windows?** You can edit and test Dart code there, but a real iPhone build/signing step requires Xcode on macOS. See the [iOS guide](apps/ios/README.md).

**Does history prove I learned more?** No. Timer duration, completion, and self-reports are not objective learning or productivity outcomes. Optional outcome answers stay missing when unanswered.

**Must I join the experiment?** No. The local crossover requires explicit consent, can be left, and does not upload automatically. See the [protocol](docs/LOCAL_CROSSOVER_PROTOCOL.md) before using it.

## Repository layout

```text
packages/focus_core/  shared domain model, migration, planner, outcomes, tests
apps/ios/             Flutter iOS app and local-notification adapter
apps/windows/         Flutter Windows app and native toast/tray adapter
docs/                 evidence, architecture, privacy, and release acceptance
.github/               CI, dependency updates, and contribution gates
```

## Develop

Install the current stable Flutter SDK and the tooling for your target platform. Use a Windows development host for the Windows app, or macOS with Xcode for iOS builds. The commands below start from the repository root; the platform guides cover [Windows](apps/windows/README.md) and [iOS](apps/ios/README.md) details.

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

**First successful action:** run a local app build, enter a goal and recovery action, start a session, then pause and resume it. Confirm the displayed session state changes. This is a basic local walkthrough, not acceptance of lock-screen, sleep/wake, or native-notification behavior.

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

## Help make it easier to use and verify

Focused contributions are welcome, especially around accessibility, migration safety, platform notification behavior, and clearer goal-check interactions.

- Start with [CONTRIBUTING.md](CONTRIBUTING.md) and the tests for the module you want to change.
- Keep shared behavior in `packages/focus_core`; keep platform-specific behavior in its app adapter.
- For device testing, use [DEVICE_ACCEPTANCE.md](docs/DEVICE_ACCEPTANCE.md) and record the hardware, software version, commit, steps, and observed result.
- Describe both the checks you ran and the checks you could not run.

| Work you want to improve | Entry point | Verification to include |
| --- | --- | --- |
| Cue planning and settings migration | `packages/focus_core` | Domain tests, migration inputs, and unchanged privacy/default contracts. |
| iOS session UI or notifications | `apps/ios/lib`, `apps/ios/test` | Analyzer/widget tests; name any real-device checks separately. |
| Windows control, persistence, or tray behavior | `apps/windows/lib`, `apps/windows/test` | Relevant controller/repository tests and explicit platform evidence. |
| Product explanations | `docs/EVIDENCE_BASE.md`, `docs/PRIVACY.md` | Consistency with actual defaults and the evidence/claim boundary. |

For an interface change, also consider repeated actions, pause/resume, a skipped check, and interrupted sessions. Do not mark a physical-device gate complete based only on a simulator or mocked adapter.

Open an [issue](https://github.com/son-gladyso/random-cue-focus/issues) to discuss a larger change. Do not submit personal goals, history, or research exports as public examples. Contributions must preserve optional checks, privacy, and the distinction between an implemented heuristic and a demonstrated benefit.


