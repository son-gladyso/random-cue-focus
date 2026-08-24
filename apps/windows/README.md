# Random Cue Focus Windows

Random Cue Focus Windows is a Flutter desktop focus timer for study sessions.
It uses variable-interval prompts, short microbreaks, local statistics, Windows
toast notifications, and a system tray fallback.

## What is implemented

- Desktop-first dark UI with a large focus ring and compact control surface.
- Variable cue scheduler with default 3-5 minute prompts and 10 second
  microbreaks.
- Local adaptive cadence based on recent completion history.
- Local settings and session persistence.
- Windows notification adapter and tray controller.
- Statistics for today, total focus, completion rate, prompt responses, hourly
  distribution, and recent sessions.

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
- The default design is based on sustained-attention decline, microbreaks,
  variable intervals, and self-regulation.
- Data stays local in v1.
