# Random Cue Focus

[简体中文](docs/i18n/README.zh-CN.md) · English · [日本語](docs/i18n/README.ja.md) · [한국어](docs/i18n/README.ko.md) · [Español](docs/i18n/README.es.md) · [Français](docs/i18n/README.fr.md) · [Deutsch](docs/i18n/README.de.md) · [Português (Brasil)](docs/i18n/README.pt-BR.md) · [Русский](docs/i18n/README.ru.md) · [繁體中文](docs/i18n/README.zh-TW.md)

> You sat down to write chapter 3. Forty minutes later you're reading about the history of the stapler.
>
> Most focus apps answer that with *more*: more alarms, forced breaks, streaks, guilt. This one does less. Every so often it quietly asks: **"Still on the thing you chose?"** You answer in one tap, or ignore it, and your timer keeps running.

A local-first Flutter focus companion for **iOS and Windows**. No account, no server, no ads, no analytics. Notifications and sound are **off** by default.

**Evidence-informed, not clinically validated.** It doesn't claim to diagnose attention, raise productivity or improve learning just because a timer ran.

[A session](#a-session-in-practice) · [Develop](#develop) · [Release status](#release-status) · [FAQ](#faq) · [Contribute](#contribute) · [For AI agents](#-for-ai-agents)

---

## 👋 For humans

### A session in practice

1. Write a concrete goal and your own recovery line: *"If I drift to my phone, then I re-read the last paragraph I wrote."*
2. Start focusing. Default: 50 min focus, 10 min rest.
3. Somewhere every 12–18 minutes, a goal check appears for 20 seconds: **still on goal** / **just distracted** / **skip**. Focus time never stops.
4. Pause, rest or stop whenever you like. Optionally note progress and how annoying the interruptions were.
5. Look back at your history, which is stored only on your device.

Don't want checks today? Turn off nonessential checks for the whole session.

### What makes it different

- **It never punishes honesty.** Saying "I got distracted" never makes it nag you more often.
- **Your words, not a script.** The goal, the distraction trigger and the recovery action are yours to edit.
- **Boring on purpose.** The cadence adapts with a deterministic, inspectable heuristic, not an ML model, and only after at least 3 sessions and 6 responses.
- **Missing means missing.** If you skip the post-session questions, they're stored as unanswered, not zero.

### Why it's designed this way

| Finding | Design consequence |
|---|---|
| Alerts can disrupt an active task | Notification and sound defaults are off |
| Short breaks help vigor/fatigue more consistently than cognitive performance | Checks are optional; no performance promise |
| Implementation intentions and self-monitoring are plausible supports, but modern bias-robust effects are smaller than early estimates | If–then plan included, with no claim that this app or the 12–18 min default is proven |
| Retrieval practice and spacing have stronger learning evidence | A timer alone isn't a learning intervention |

Details: [Evidence base](docs/EVIDENCE_BASE.md) · [Measurement plan](docs/MEASUREMENT_PLAN.md) · [Data dictionary](docs/DATA_DICTIONARY.md) · [Local crossover protocol](docs/LOCAL_CROSSOVER_PROTOCOL.md) · [Learning-mode spec](docs/LEARNING_MODE_SPEC.md)

### Want to test whether it helps *you*?

There's an **opt-in** local crossover experiment. It alternates no-check and sparse-check sessions, saves each assignment before the session starts, never uploads anything, and you can leave any time. Research export (schema v2) strips session IDs, dates, absolute assignment timestamps and free text.

### Release status

| Gate | Status |
|---|---|
| Shared core tests · iOS analyze/tests · iOS simulator build · Windows analyze/tests/release build | ✅ Automated in CI |
| Physical iPhone notification lifecycle | ⏳ **Pending** |
| Physical Windows toast, Focus Assist, sleep/wake, tray | ⏳ **Pending** |
| Product-level effectiveness trial | ❌ **Not performed** |

Version `0.2.0` is an A+-*candidate* engineering upgrade, not an A+ release. Release stays blocked until [Device acceptance](docs/DEVICE_ACCEPTANCE.md) runs on named hardware with evidence attached.

### FAQ

**Is this a mandatory break timer?** No. A goal check never stops focus time, and rest is a separate state.
**Why don't I hear anything?** Sound and notifications are off on fresh installs. Turn them on deliberately; OS permissions and background behavior still need per-platform verification.
**Can I build the iPhone app on Windows?** You can edit and test Dart there, but building and signing need Xcode on macOS. See the [iOS guide](apps/ios/README.md).
**Does my history prove I learned more?** No. Duration, completion and self-reports aren't objective outcomes.
**Do I have to join the experiment?** No. It needs explicit consent.

### Develop

Install stable Flutter. Use Windows for the Windows app, macOS + Xcode for iOS.

```powershell
cd packages\focus_core
dart pub get; dart analyze --fatal-infos; dart test

cd ..\..\apps\windows
flutter pub get; flutter analyze --fatal-infos; flutter test
flutter run -d windows
```

**First win:** build, enter a goal and recovery action, start a session, pause, resume, and watch the state change. That's a local walkthrough, not lock-screen, sleep/wake or native-notification acceptance. Platform guides: [Windows](apps/windows/README.md) · [iOS](apps/ios/README.md).

```text
packages/focus_core/  shared domain model, migration, planner, outcomes, tests
apps/ios/             Flutter iOS app + local-notification adapter
apps/windows/         Flutter Windows app + native toast/tray adapter
docs/                 evidence, architecture, privacy, release acceptance
```

Privacy: [PRIVACY.md](docs/PRIVACY.md) · [SECURITY.md](SECURITY.md) · [ARCHITECTURE.md](docs/ARCHITECTURE.md). All data stays on the device; clear history or uninstall to remove it.

### Contribute

Especially welcome: accessibility, migration safety, platform notification behavior, clearer goal-check interactions. Start with [CONTRIBUTING.md](CONTRIBUTING.md) and the module's tests. For device testing, record hardware, OS version, commit, steps and observed result per [DEVICE_ACCEPTANCE.md](docs/DEVICE_ACCEPTANCE.md). For bigger changes, open an [issue](https://github.com/son-gladyso/random-cue-focus/issues). Never submit personal goals, history or research exports as examples.

---

## 🤖 For AI agents

**Read first:** [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/EVIDENCE_BASE.md`](docs/EVIDENCE_BASE.md), [`docs/DATA_DICTIONARY.md`](docs/DATA_DICTIONARY.md). [`docs/AI_HANDOFF_LOCAL.md`](docs/AI_HANDOFF_LOCAL.md) is a historical local handoff: its Windows paths and branch names describe one machine, so don't execute its commands blindly.

**Where code goes:** shared behavior lives in `packages/focus_core`, platform behavior in its app adapter (`apps/ios/lib`, `apps/windows/lib`). Don't duplicate domain logic in an app.

**Product invariants (don't reverse casually):**

- Fresh-install defaults: 50 min focus, 10 min rest, 12–18 min check range, 20 s response window, notifications off, foreground sound off.
- Goal checks never pause focus time; nonessential checks can be disabled per session.
- Off-task self-reports must **never** increase interruption frequency.
- The adaptive cadence stays deterministic and inspectable; it waits for ≥3 sessions and ≥6 responses.
- Unanswered outcomes stay missing (null), never zero.
- No account, server, API key, ad SDK or remote analytics.

**Data contracts:** settings/session schema is v6. Keep all prior migrations; never silently drop 0.1.x data. Crossover assignment is persisted before exposure; a failed enrollment write must not consume the next assignment. Research export v2 excludes raw session IDs, calendar dates, absolute assignment timestamps and free text. Outcomes are only asked after completed sessions, so complete-case arm differences must **not** be described as causal.

**Claims discipline:** don't write "improves focus/productivity/learning". Don't mark a physical-device gate done from a simulator, mock or CI. Report checks run *and* checks not run.

**Verify:**

```powershell
cd packages/focus_core; dart format --set-exit-if-changed .; dart analyze --fatal-infos; dart test
cd apps/windows;        flutter analyze --fatal-infos; flutter test
cd apps/ios;            flutter analyze --fatal-infos; flutter test
```
