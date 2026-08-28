# Physical-device release acceptance

Status: **physical/device acceptance not run**. The local Windows release build passed on Windows 11 25H2, but build success does not satisfy these gates. Windows Computer Use could not attach because its native pipe was unavailable, so no GUI checkbox below is marked from automation alone.

Record app commit SHA, app version, OS build, device model, locale, timezone, power state, and tester for every run. Attach screenshots or screen recordings plus relevant logs. A checkbox without evidence is not acceptance.

## iPhone matrix

- [ ] Fresh install: notification is not requested on launch and defaults remain off.
- [ ] User enables lock-screen checks: permission request occurs in context; denial leaves the timer usable.
- [ ] Allowed permission: one expected check appears within timing tolerance; title/body match the current goal; no sound plays.
- [ ] Foreground, background, locked screen, app force-quit, and device restart behavior documented.
- [ ] Pause, stop, or completion cancels stale scheduled checks; starting a new session does not duplicate old checks.
- [ ] Focus mode, Scheduled Summary, Low Power Mode, and notification settings interactions documented without claiming guaranteed delivery.
- [ ] Timezone change and daylight-saving transition do not shift or duplicate a check unexpectedly.
- [ ] VoiceOver labels/actions, Dynamic Type, contrast, and 44x44-point targets checked on the goal-check card.
- [ ] Completed-session progress/burden feedback is reachable, optional, clearly announced, and persists after relaunch without blocking a new session.
- [ ] Local study defaults off; consent text is readable with VoiceOver/Dynamic Type; joining persists the chosen sequence; leaving immediately prevents the next assignment without blocking ordinary sessions.
- [ ] A `noChecks` study session shows the control-round explanation and produces no in-app or notification check; the following `sparseChecks` round is labeled and uses the normal user-controlled planner.
- [ ] Migration from a real `0.1.x` data set preserves settings and readable session history.

## Windows matrix

- [ ] Fresh install: desktop notifications and foreground sound default off; tray defaults on.
- [ ] Opt-in toast appears once with the current goal; clicking/dismissing behavior is documented.
- [ ] Foreground, minimized, tray-only, locked, sleep/wake, restart, and multiple-monitor behavior checked.
- [ ] Focus Assist/Do Not Disturb suppression is respected and does not block timer completion.
- [ ] Pause, stop, completion, and rapid session restart do not create duplicate or stale prompts.
- [ ] Standard user account, non-ASCII Windows username, and missing/unwritable app-data failure behavior checked.
- [ ] Keyboard-only navigation, screen reader naming, 200% scaling, high contrast, and minimum hit targets checked.
- [ ] Completed-session progress/burden feedback is reachable by keyboard, remains optional, and persists atomically after relaunch.
- [ ] Local study defaults off; consent is reachable by keyboard/screen reader; joining survives relaunch; leaving immediately prevents the next assignment without blocking ordinary sessions.
- [ ] A `noChecks` study session shows the control-round explanation and produces no in-app/toast check; the following `sparseChecks` round is labeled and uses the normal user-controlled planner.
- [ ] Release artifact launches without a development environment and native toast/tray adapters initialize cleanly.
- [ ] Migration from a real `0.1.x` data set preserves settings and readable session history.

## Exit criteria

- No severity-1 or severity-2 defect.
- No duplicate or misleading notification.
- No loss of readable pre-upgrade records.
- Every failed or unavailable platform behavior has a documented fallback.
- Evidence is attached to the release issue and references the exact commit.
