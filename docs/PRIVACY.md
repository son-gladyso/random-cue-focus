# Privacy

Random Cue Focus `0.2.0` is local-first. It has no account, cloud sync, advertising SDK, remote analytics, or external model/API call.

## Stored data

- Settings: durations, interval range, whole-session goal-check choice, notification/sound choices, session goal, user-authored recovery plan, and—only after explicit study consent—a pseudonymous participant code, protocol/version, AB/BA sequence, assignment index, consent time, and optional withdrawal time.
- Session history: timestamps, planned and elapsed seconds, completion state, correlated goal-check events and response latency, the platform/app/algorithm/settings snapshot, optional study assignment, optional post-session progress/burden answers, optional goal/recall/reflection fields, and data schema version.
- iOS stores these values through platform shared preferences; Windows stores JSON under the user's application-data directory.

Goal-check responses are self-reports and may be sensitive. They are used only for local summaries and the transparent cadence heuristic. The app should not export, sync, or add telemetry without a separate design review, explicit consent, retention policy, deletion path, and documentation update.

The shared core provides an explicit research-export builder, but the apps do not upload it. Export schema v2 removes raw session IDs, session calendar dates, the absolute study-assignment time, mode names, goals, recovery plans, recall prompts/answers, and reflections. It retains a user-supplied participant code, relative day, local minute-of-day, structured settings, assignment condition/index and relative lead time, exposures, responses, and outcomes. The file-level export timestamp remains for provenance. Users or researchers must still review the resulting JSON because combinations of timing, platform, and study codes may be identifying in small samples.

Windows writes settings/history through a same-directory temporary file and recoverable backup replacement. Backup and temporary files use only the fixed app-data filenames and are cleaned after success; a valid backup may be read if the primary file is missing or corrupt.

## Control and deletion

History can be cleared in the product where exposed. Uninstalling/clearing app data removes current local records according to the operating system's behavior. Before public release, physical-device acceptance must verify deletion and migration paths on both platforms.

Leaving the optional local crossover immediately prevents future assignment but does not rewrite existing session history. Enrollment and withdrawal are distinct from data deletion. Any external study must give participants a clear retention/deletion procedure before consent; the current app does not transmit withdrawal or deletion requests because it has no server.

## Notification privacy

Lock-screen/desktop notification text can reveal the session goal. Notifications therefore default off. Users should avoid placing confidential information in a goal if they enable external notifications.
