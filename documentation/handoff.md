# Handoff — state of the project and how to continue

Last updated: 30 October 2026, when Milestone 11 was planned. Read this after `CLAUDE.md` when a new session starts. `CLAUDE.md` describes the game and the code; this file says **where the work stands, what was decided along the way, what is still open, and the lessons learned**, so nothing has to be found out again.

## 1. Where the work stands

- **Next: Milestone 11, settings panel and European Portuguese (`MILESTONE_11.md`), planned, not built.** It holds the decisions, the state of the code, how translation works and every task. Task 1 needs the user.
- **Name on phones: the pop-up box stays (user, 30 Oct 2026).** `fe5c4c3` (`window.prompt`) is confirmed on a real Android phone. The virtual keyboard attempt `adfe369` never reached GitHub and was reverted untested on a real phone. The pop-up box was reported as doing nothing on 28 Oct, for an unknown reason (a cached old page is possible). Always confirm a push with `git ls-remote origin refs/heads/main` and the published file size: that push from GitHub Desktop failed silently.
- **Milestone 10.5 is complete and pushed** (27 Oct 2026, published on GitHub Pages; the user checked the game in the Godot editor first; `MILESTONE_10_5.md`). It acts on the team's review of the Milestone 10 differences (`documentation/milestone10_review.md`): failure reads the target health, a 36-hour gap between strength sessions, a danger state for severe thinness, a better scenario test and a parity test that found the causes of the differences (`documentation/milestone10_calibration.md`).
- **Milestone 10** (food as an activity + the whole health system rebuilt to Health Calculation Architecture v1) is pushed (`e3e6a89`, plus the handoff commit `6d3639b`).
- **All 20 tests pass** (`tests/*_test.gd`; `calibration_test.gd` takes about 2.5 minutes and `parity_test.gd` about 5; the parity test prints numbers for the team and only fails if it crashes).
- **Waiting on the team:** the plan guesses, the training window, eating time and the hunger penalty, the danger-state and gap values (`documentation/milestone10_calibration.md`, "Proposals for the team"). No value was changed to fit the tests.

### Commit history of Milestone 10.5

| Commit | What |
|---|---|
| `f89926e` | Task 0: plan (`MILESTONE_10_5.md`) and a copy of the team's review |
| `2d9ac90` | Task 1: failure reads the target health (decision 10) |
| `47e5d0b` | Task 2: 36-hour minimum gap between strength sessions |
| `2b8fce2` | Task 3: danger state of severe thinness, Ill look, health bar warning, failure causes, thinness risk term |
| `e3c6f06` | Task 4: scenario test method (exact player rule, failure for every scenario, new scenarios and rules) |
| `1926e49` | Task 5: parity test and the causes of differences 1, 2 and 4; training window averaged per day |
| `d761cef` | Task 6: docs and web export |

### Commit history of Milestone 10

| Commit | What |
|---|---|
| `7040dc1` | Milestone 4 leftovers (habit cost, gradual vs sudden), committed before starting |
| `d68119c` | Plan: v1 copy, `MILESTONE_10.md`, `documentation/milestone10_plan.md` |
| `e356e50` | Task 1: v1 config groups, WHO tables, `who_tables.gd` |
| `480c0ce` | Task 2: 20-minute day, `Simulation` (5-minute steps), can-sleep rule |
| `d35e37a` | Task 3: food as an activity, hunger, meals, energy spent |
| `a9e96d9` | Task 4: weight, body growth, z, energy deficit U, Screens and Football |
| `c8dd219` | Task 5: training (capacity, recovery, overreaching) |
| `bb22f0f` | Task 6: v1 sleep debt, Sleep measure, tiredness |
| `882518a` | Task 7: diet (Q, C, A) and Happiness (Mental removed) |
| `44fdb90` | Task 8: v1 Physical, health, failure, risk, XP, avatar looks |
| `2aebbe3` | Task 9: saves (version 2; Milestone 4 saves ignored) |
| `71c3530` | Task 10: v1 scenario tests (Bases fundamental check) |
| `e3e6a89` | Task 11: hourly CSV log, debug view, docs, web export, CLAUDE.md rewrite |

## 2. Decisions taken by the user (keep them)

Recorded in `MILESTONE_10.md` ("Decisions") and `documentation/milestone10_plan.md` ("Approval").

| # | Decision |
|---|---|
| 1 | Keep the slow health bar: v1 health is the **target**; the bar moves `health.alpha_bar` (0.37) of the way once per avatar day, when a sleep ends. |
| 2 | A meal takes avatar time (0.5 h, placeholder). |
| 3 | Only two meals for now: healthy meal and fast-food meal. |
| 4 | Entertainment has Screens and Football. |
| 5 | Minigame score fixed at 1 until minigames exist. |
| 6 | Saves from Milestone 4 or earlier do not load (save version 2). |
| 7 | Very hard starts with happiness **0.30** (not v1's 0.15), so it is playable; Very hard starts at health 1.49. |
| 8 | The body grows only inside its age group (child stops at 12 y 11 m, teenager at 18 y 11 m). |
| 9 | Diseases: only the risk index and hidden damage, in the debug panel; no stages. |
| A | CSV log: one line per avatar hour. |
| B | Rename Mental to Happiness in English only; Portuguese and English translations in a later milestone. |
| Task 5 | A strength session that starts below 60% recovery is "too soon": **no effective minutes**, only overreaching. |
| Task 0 | A meal counts when it ends, in proportion to the time eaten (planned as spread over the half hour; changed in Task 3, recorded in the plan). |
| 10 | (Milestone 10.5) Failure reads the **target health**, not the slow bar (replaces the failure part of decision 1; XP still uses the bar). |
| 11 | (Milestone 10.5) The danger state of severe thinness ends **only when z is back at −3 or above**. |
| 12 | (Milestone 10.5) Scenario plans: use what we know (our plans + the review's corrections) and list every guessed detail for the team. |
| 13 | (Milestone 10.5) Work through all tasks in a row, committing each; no push; the user reviews at the end. |
| 14 | (Milestone 11) Settings hold the language and "Start a new avatar" with a confirmation. Music and sound wait for the music. |
| 15 | (Milestone 11) First start follows the browser's language (any Portuguese gives Portuguese, otherwise English); the creation screen also has PT and EN buttons. |
| 16 | (Milestone 11) All tasks in a row, each committed; no push; the user reviews at the end. |

Other team decisions that still hold: k = 10 (applies to sleep debt too); there is no death, only failure; p = 0.5 for health. The team's review (27 Oct 2026) added the 36-hour strength gap, the danger state (z −3, 72 h, z −4) and the thinness risk term (placeholders).

## 3. What is still open

**For the team** (with numbers and proposals in `documentation/milestone10_calibration.md`, Milestone 10.5): the causes of the six differences are found. (1) The severe diet: the scenario's screens hour blocks one hungry moment a day (without it the game eats exactly v1's 2.33 meals and 1,145 kcal); not a model difference. (2) Happiness: mostly plan details v1 does not describe (30 min of football in the guideline activity, 2 h of screens without sport), plus half-hour meals and the hunger penalty for 4 h of cardio. (3) Resolved by the review. (4) Guideline strength: the 24-hour training window makes strength rise and fall through the week; a one-week window gives 0.76. (5) Decision 1 only. (6) Compared with the wrong row. To decide: the plan guesses, `train.average_window_h`, eating time and METy, the hunger penalty with fixed portions, the danger-state and gap values.

**Not decided** (do not guess; see `CLAUDE.md`, "Not decided yet"): researched values for every placeholder; failure effect; diseases; food menus and tastes; full entertainment menu; whether football counts toward the 60 minutes (it does for now); activity durations; avatar art; settings contents; translations; server and accounts.

**Likely after Milestone 11** (ask the user): the team's answers to the Milestone 10.5 proposals; failure effect and screen; minigames; menus; the lobby screen; plasticine art. (A 45-minute strength option would not raise strength: Milestone 10.5 parity run.)

**Placeholders added in Milestone 10.5:** the Ill look (pale, greenish body), the health bar warning (red bar, "Health: danger") and the failure messages by cause; the review's numbers (`train.strength_min_gap_h` 36, `fail.danger_z` −3, `fail.danger_hours` 72, `fail.danger_failure_z` −4, `risk.thin_weight` 0.4, `risk.thin_from` −2, `risk.thin_range` 2).

**Placeholders added by Claude during Milestone 10** (not in v1; the team should check them): starting habituation A = 1 − Q; new avatar's hunger 0.8 meals; `risk.safe_level` 0.3 and `risk.damage_tau_days` 365; owners (Pessoa 1 to 4) of every new config value; METy while eating 1.5; default sex female before the player chooses; which activities count as cardio, strength, football, screens and exercise.

## 4. How to work with this user (what worked)

- The user is a 9th-grade student. Plain language, exact steps, and after each step: what changed, how to run it, what to check.
- **One task at a time.** The user replies "Commit Task N, then start Task N+1" (or "Commit Task N"). Each task ends with a summary, the test results and the question whether to commit; nothing is committed without that. Exception: for Milestones 10.5 and 11 the user chose "all tasks in a row, each committed, review at the end" (decisions 13 and 16); ask again at the start of each milestone.
- When a new team decision contradicts an earlier user decision (example: the review said failure should read the true health, decision 1 said the bar), ask the user before changing it, with a proposed default.
- **Never push without asking.** Pushing publishes the game on GitHub Pages. (This shell has no GitHub login, so the user pushes from GitHub Desktop: give them the steps, then confirm with `git ls-remote origin refs/heads/main`. The commit "Milestone 10.5: status pushed" and earlier ones went up that way.)
- When a test result differs from v1 or a rule fails, **do not change values to make it pass**: report the numbers, propose options, and let the user decide (example: the too-soon strength rule in Task 5).
- Questions to the user go with a proposed default; record their answers in the milestone file.
- Be honest about own mistakes and fix them (example: the CLAUDE.md cut-off in Task 8, found and repaired in Task 11).

## 5. Lessons learned (technical)

- **Godot binary:** `"/Applications/Godot 2.app/Contents/MacOS/Godot"`. Check scripts: `... --headless --path . --quit`.
- **Tests hang on script errors.** A test that hits a script error never calls `quit()`, so Godot runs it forever. Always run tests with a time limit:
  `perl -e 'alarm 300; exec @ARGV' "/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . -s res://tests/<name>_test.gd`
- **Scripts in `scripts/health/` use the autoloads (`Config`, `GameState`, …).** A test script is compiled before the autoloads exist, so tests must `load()` these scripts at run time, not `preload` them. Game scripts (autoloads, UI) can preload them.
- **No numbers in the health scripts** (`tests/config_test.gd` checks with a regex; only 0 and 1 are allowed). Even `2.0` in `pow(x, 2.0)` or `1e-6` fails; use the `units` group in config, `x * x`, or `log(0) = -inf`.
- **Autoload order matters.** `Simulation` is listed before `Activities`, so it hears each frame's time while the activity still runs; it splits a frame at the end of a day activity, and `Activities.changing` (emitted just before an activity starts or ends) flushes the pending minutes. Without this, the last minutes of an activity get the wrong METy.
- **Loading a save repeats events.** `Clock.from_dict()` emits `phase_changed` and `Activities.from_dict()` emits `started`; `SaveGame.load_game()` sets `Simulation.loading` so no new day or activity start runs again, and resets `Simulation` first.
- **JSON reads every number as a decimal.** Convert whole numbers back on load (the `hour` of the hourly windows, the `day` of log entries); compare saved values with a tolerance.
- **Hourly windows** (`scripts/health/hour_window.gd`) keep one slot per hour plus one; the oldest counts only for the part still inside the 24 hours, so sums are true sliding sums. New windows are pre-filled so a new avatar starts in balance (energy) or steady (training).
- **Simulated players in scenario tests must eat when the avatar is hungry** (as a real player), not at fixed times; fixed meals left the avatar hungry and unhappy and gave wrong conclusions (found in Task 7).
- **Web build check:** start the `web-build` server in `.claude/launch.json` (port 8060). In the browser, Godot reads single key presses, not pasted text (the name field needs key presses).
- **Scripted edits of documents:** after a Python replace, check the end of the file still exists (`grep -n "^## " CLAUDE.md`); in Task 8 a slice without its tail cut CLAUDE.md in half.
- The data files `foods.json` and the WHO tables are included in the web export through `include_filter="data/*.json"` in `export_presets.cfg`.
- **A test can extend another test.** `tests/parity_test.gd` starts with `extends "res://tests/calibration_test.gd"`, overrides `_process` and `_record_step` (calling `super(...)`), and changes config values in memory through `Config._data` (never the file). Activity lengths can be changed in memory in `Activities.definitions`.
- **Scenario tests: find the cause before blaming the model.** In Milestone 10.5 two of the "model" differences were how the scenario was played: a planned activity blocked a hungry moment (the player cannot answer during an activity), and the 24-hour training window made the day-21 value depend on the weekday. Print counts (meals, skips, too-soon sessions, minutes beyond capacity) and day-by-day values, and change one thing at a time.
- **k = 10 magnifies small energy differences:** 20 kcal a day (half an hour of eating at METy 1.5 instead of idle 1.7) is about 0.4 kg in 21 avatar days.
- **Activities must not run into the end of the awake period** in tests: the 0-hour rule starts a new day. The scenario test cuts an activity 0.01 h before the end.
- **New test scripts get their `.uid` file only when the Godot editor scans the project**; commit the `.uid` files it creates.
- **Translations:** after changing `translations/strings.csv`, run `Godot --headless --path . --import` before headless tests; the `.translation` files are ignored by git (`MILESTONE_11.md`).
- **Shell:** macOS `sed` has no `\b`; use `perl -pi -e`. The Edit tool needs the file read first with the Read tool.
- **Text fields on phones (web):** any new text field needs the pop-up box of `scripts/ui/creation.gd` (web + touch screen: the field never takes focus, a tap calls `window.prompt` through `JavaScriptBridge.eval`). Without it the keyboard opens but no letters arrive. The alternative, the export option `html/experimental_virtual_keyboard`, worked in phone emulation but was never tried on a real phone; if it is ever used, its text arrives through `set_text`, which does not emit `text_changed`, and the option is stored in `index.html`, not the .pck. GitHub Pages lets phones keep old files for up to 10 minutes.
- **Testing phone input in the browser pane:** `resize_window` preset mobile (the page then reports a touch screen), a fresh origin (a new port such as `127.0.0.1:8062`; the game re-saves when the page closes, so an origin with a save skips the creation screen), refresh cached files with `fetch(url, {cache: 'reload'})` for `'/'`, `index.html` and `index.pck`, then check `GODOT_CONFIG` really says `experimentalVK: true`. Send a real touch (`new TouchEvent('touchstart'/'touchend')` with a `Touch` on the canvas), check that a hidden `INPUT` is the `document.activeElement`, and type with the `computer` tool. A real Android phone is still the only full test.

## 6. Commands

```
"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . --quit
for t in tests/*_test.gd; do perl -e 'alarm 400; exec @ARGV' "/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . -s "res://$t" 2>&1 | grep -E "ALL PASSED|SOME FAILED" | sed "s|^|$t: |"; done
"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . --export-release "Web" docs/index.html
```

Debug keys in the editor: F6 reload config, F7 debug panel, F9 time speed. The debug CSV log is in `~/Library/Application Support/Godot/app_userdata/Plasticine Tamagotchi/health_log.csv`; the save is `save.json` in the same folder (delete it to start a new avatar).
