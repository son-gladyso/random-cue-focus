# Random Cue Focus Windows

Random Cue Focus Windows is a local-first Flutter goal timer. It uses sparse,
skippable, silent-by-default goal checks, behavioral history, optional Windows
toasts, and a system tray fallback.

## What is implemented

- Desktop-first dark UI with a large focus ring and compact control surface.
- Fresh defaults of 50/10 minutes, 12–18-minute checks, and a 20-second response window.
- Whole-session check control and a local burden heuristic that never increases frequency after an off-task self-report.
- Recoverable local settings/session persistence with partial-corruption handling.
- Windows notification adapter and tray controller.
- Behavioral statistics for timer duration/completion, checks shown, and recent sessions.

## Develop on Windows

```powershell
cd apps\windows
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

## Notes

- The app avoids claiming that random prompts universally improve focus.
- Notifications can themselves interrupt work, so sound/toasts are opt-in and off on a fresh install.
- Self-reports are not objective attention measures, and timer minutes are not learning/productivity outcomes.
- Data stays local in `0.2.0`.
