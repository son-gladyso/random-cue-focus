# Random Cue Focus

Random Cue Focus is a Flutter iOS-first focus timer for study sessions. It uses
variable-interval prompts, short microbreaks, local statistics, and iOS local
notifications as a background fallback.

## What is implemented

- Focus timer with focus, microbreak, pause, rest, and stop states.
- Variable cue scheduler with default 3-5 minute prompts and 10 second
  microbreaks.
- Local adaptive cadence factor based on recent completion history.
- iOS local notification fallback for background and lock screen.
- Dark iOS-style UI inspired by the provided samples.
- Settings for session length, rest length, cue range, microbreak length, sound
  preset, and lock-screen reminders.
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

- Foreground prompts use system sound and haptic feedback.
- Background and lock-screen prompts use local notifications.
- iOS does not allow arbitrary precise timers to keep running forever in the
  background, so this app pre-schedules the prompt plan for the current session.
- Notification permission is requested only when a focus session starts and
  lock-screen notifications are enabled.

## Scientific framing

The app avoids claiming that random prompts universally increase focus. The
default design is based on practical evidence-aware constraints:

- sustained attention commonly declines over time;
- brief breaks can reduce perceived fatigue;
- variable intervals reduce predictability compared with fixed timers;
- local personalization is safer than assuming one universal interval.
