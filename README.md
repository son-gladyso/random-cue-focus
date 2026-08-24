# Random Cue Focus

Random Cue Focus is a local-first focus timer built around variable-interval cues and short microbreaks. The repository contains two Flutter applications that share the same product idea while using platform-specific notification and desktop behavior.

## Applications

- `apps/ios`: iOS-first timer with local notifications, haptics, persistence, and session statistics.
- `apps/windows`: Windows desktop timer with toast/tray adapters, persistence, statistics, and hourly summaries.

## Core behavior

- Focus, pause, microbreak, rest, and stop states.
- Random cue scheduling inside a configurable interval range.
- Short microbreaks after cues.
- Local adaptive cadence based on recent completion history.
- Local settings, session history, and summary statistics.
- No account, cloud service, API key, or remote analytics.

The adaptive cadence is a small deterministic personalization rule, not a machine-learning model. The project intentionally avoids claiming that one reminder interval improves attention for every user.

## Develop

Install a current Flutter SDK, then work inside either application directory.

```powershell
cd apps\windows
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

For iOS development, run the same `pub get`, `analyze`, and `test` commands inside `apps/ios`. Building and signing the iOS application requires Xcode on macOS.

## Privacy

All settings and session records stay on the local device in the current version. The repository excludes local caches, generated build output, IDE state, and application data.

## Status

Version `0.1.0` is a functional prototype. Platform notification behavior should still be verified on a physical iPhone and a Windows desktop before release.
