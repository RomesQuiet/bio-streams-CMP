# Milestone 23: sleep continues while the game is closed (built, 18 Nov 2026)

Request (user, 18 Nov 2026): while the avatar sleeps, the player can turn off the phone or close the tab. When they come back, the game reads the device's date and time, sees how much real time has passed, and moves the sleep forward by that much.

## Is it viable?

Yes. Everything needed is already there:

- `SaveGame` already saves when the page is hidden or closed (`visibilitychange`, `NOTIFICATION_APPLICATION_PAUSED`, `FOCUS_OUT`), which is what happens when a phone screen turns off.
- Godot gives the device time with `Time.get_unix_time_from_system()` (seconds since 1970), on the web too.
- `Clock` already turns real seconds into avatar hours (`real_seconds_to_avatar_hours(seconds, true)`: 1 real minute = 5 avatar minutes of sleep), and `Simulation` already runs any amount of avatar time in fixed 5-minute steps, so a long catch-up gives the same results as playing it.

**It breaks two fixed rules in `CLAUDE.md`, so the user must confirm the change:** "The Clock never reads the device clock for game time" and "Closing the tab pauses time". The proposal changes them only for sleep; the day still pauses when the game is closed.

## Cheating

- Moving the phone's date **forward** can only end the sleep sooner. The sleep never goes past the hours chosen on the slider, so the player gets nothing they could not get by waiting.
- Moving the date **backward** gives a negative time: it is ignored (nothing happens).
- So the device clock is safe to trust here. (For the day it would not be, which is one more reason to keep the day paused.)

## Tasks

1. **Save the time.** `Clock.to_dict()` saves `closed_at` (device time) when the avatar is sleeping. Only used for the catch-up, never for the time of day in the game.
2. **Catch up.** When a save loads, or the page becomes visible again, and the phase is `SLEEPING`: elapsed = now − `closed_at`; if it is above 0, turn it into avatar hours, at most `sleep_target_hours − sleep_elapsed_hours`, and advance the Clock by that much (in pieces, so `Simulation` runs its normal steps). If the sleep is complete, it ends as usual and the Wake button is shown.
3. **Show it.** A short message on return, for example "Ana slept 3 h 20 min while you were away." (new translation keys, pt and en; the Portuguese is Claude's draft).
4. **Limits in config** (`time.offline_sleep`, placeholders): on or off, and the longest gap counted (for example 12 real hours).
5. **Tests** (`tests/offline_sleep_test.gd`): a gap of 0, a gap shorter than the sleep, longer than the sleep, a negative gap (date moved back), a gap during the day (nothing happens), and the same health results as sleeping with the game open.
6. **Check on a real phone:** start a sleep, lock the phone for some minutes, open it, see the sleep has moved forward.

## Questions for the user

- A (decision 73). Allow the device clock for sleep only (the day stays paused when closed)? (Proposal: yes.)
- B (decision 74). When the player comes back after the sleep ended, wait for the Wake button as now, or wake up by itself? (Proposal: keep the Wake button.)
- C (decision 75). Longest gap counted (proposal: no limit is needed, since the sleep itself is the limit; keep the config value only as a switch).

## Answers (user, 18 Nov 2026)

"Yes, build it": A yes (the device clock is read only during sleep; the day stays paused when the game is closed), B yes (the Wake button is kept), C (no limit on the gap; `time.offline_sleep_enabled` is a switch). Also: "it should be possible in every device and OS possible".

## Every device and OS

The catch-up does not rely on page events (`visibilitychange`, `pagehide`), which differ between iOS Safari, Android Chrome and computers, and can be skipped when a phone kills a background tab. It only compares two readings of the device clock:

- **Tab or app still open, phone locked or in the background:** the browser or system freezes the game. On the first frame after it comes back, the time since the last sleeping frame minus that frame's own time is the time away.
- **Tab closed, page reloaded or app killed:** the save holds `last_seen_unix` (written by every save while sleeping: page hide, close, the autosave timer). The first sleeping frame after loading compares with it. If no hide event came, at most the autosave interval is lost.

`Time.get_unix_time_from_system()` works in every Godot export: on the web it is the browser's `Date`, on Windows, macOS, Linux, Android and iOS the system clock. The same code runs everywhere.

## What was built

- `scripts/autoload/clock.gd`: `last_seen_unix` (saved in `to_dict()` only while sleeping), `now_unix()` (with `now_override` for tests), `_check_time_away()` on every sleeping frame, `catch_up_sleep(real_seconds)`: turns the real seconds into sleep hours (1 real minute = 5 avatar minutes), never past the hours chosen, sends them through `avatar_time_passed` so `Simulation` runs its normal 5-minute steps, emits `slept_while_away(hours)`, and ends the sleep (Wake button) when it is complete. A negative time (date moved back) does nothing. The day never uses the device clock.
- `data/config.json`: `time.offline_sleep_enabled` (true) and `time.offline_sleep_min_gap_seconds` (2), placeholders.
- `scripts/ui/main.gd`: the speech bubble says "Ana slept 3 h 20 min while you were away." (`SPEECH_SLEPT_AWAY`; the Portuguese is Claude's draft).
- `tests/offline_sleep_test.gd`: a short gap, a gap longer than the sleep, a date moved back, a tiny gap, the day not moving, save and load, and the same sleep debt and happiness as sleeping with the game open.

## Still to check

A real phone (lock it for a few minutes during a sleep, and close the tab during a sleep), on Android and on iOS.
