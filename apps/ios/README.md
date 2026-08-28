# Random Cue Focus

Random Cue Focus is a local-first Flutter goal timer for iOS. It uses sparse,
skippable, silent-by-default goal checks and optional iOS local notifications.

## What is implemented

- Focus timer with focus, optional goal-check, pause, rest, and stop states.
- Fresh defaults of 50/10 minutes, 12–18-minute checks, and a 20-second response window.
- Whole-session check control and a local burden heuristic that never increases frequency after an off-task self-report.
- iOS local notification fallback for background and lock screen.
- Dark iOS-style UI inspired by the provided samples.
- Settings for a user-authored goal/recovery plan, durations, check range/window, sound, and lock-screen reminders.
- Local session persistence and basic statistics.

## Develop on Windows

This repository already includes the Flutter `ios` platform folder. On Windows
you can edit the Dart code, run pure Dart and Flutter analyzer checks, and
prepare the project files:

```powershell
cd apps\ios
flutter pub get
flutter analyze
flutter test
```

## Self-sign on iPhone

Windows can edit and test the Dart side, but the final install to a real iPhone
must be signed in Xcode on a Mac or cloud Mac.

1. Sign in to Xcode with your Apple ID.
2. Open `ios/Runner.xcworkspace`.
3. Select the `Runner` target.
4. Turn on `Automatically manage signing`.
5. Choose `Personal Team`.
6. Keep the bundle id as `com.ilisa.randomcuefocus` unless Xcode says it is
   already taken.
7. Connect the iPhone, trust the computer, and turn on `Developer Mode` on the
   device if iOS asks for it.
8. Run the app.

If you want to use the command line on macOS first:

```bash
flutter pub get
flutter run -d ios
```

For this project, the Flutter code and project files are ready for self-signing;
the last signing step is the part that must happen in Xcode.

## iOS notes

- Foreground sound/haptics are opt-in and off on a fresh install.
- Background and lock-screen prompts use local notifications.
- iOS does not allow arbitrary precise timers to keep running forever in the
  background, so this app pre-schedules the prompt plan for the current session.
- Notification permission is requested only when a focus session starts and
  lock-screen notifications are enabled.

## Scientific framing

The app avoids claiming that random prompts universally increase focus. The
default design is based on practical evidence-aware constraints:

- notifications can themselves disrupt an active task, so checks are quiet, optional, and suppressible;
- brief breaks more consistently affect fatigue than complex cognitive performance;
- self-reports are not objective attention measurements;
- no reviewed evidence establishes a universal best check interval or validates timer minutes as learning.
