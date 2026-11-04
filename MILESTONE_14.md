# Milestone 14 — The football minigame

**Status: pushed up to `2ce404d`, with the third and fourth rounds (1 and 2 November 2026).** The user played them and is happy with them (4 Nov 2026). A real phone is not confirmed.

**Third round, after the user played the second (1 Nov 2026):** "a little bit easy", 80% of the pace, a smarter enemy, and the tackle loop.

| # | Question | Decision |
|---|---|---|
| 49 | How fast is the match? | **80% of the speed it had** (`match_pace`): players, ball and timers. |
| 50 | Who decides for blue? | **The player.** Blue computer players never tackle or shoot by themselves. Shoot makes a team-mate with the ball shoot. Tackle uses the avatar if it is close enough, otherwise the nearest blue player in reach. Blue still passes alone to escape pressure, and stops near goal to wait for the button (Claude's choice). |
| 51 | How does a tackle end? | **Always, in one try:** the tackler wins the ball or fails. The loser is pushed back and stands still for 1.5 s. The avatar is never frozen; it just cannot tackle back at once. |

**The loop:** a tackler stood on top of the player it took the ball from, so a second later that player tackled back, for ever. Decision 51 ends it; `tests/football_test.gd` plays 16 matches and the same two players never exchange the ball more than twice in a row.

**The smarter red team (Claude's choices, placeholders):** the nearest defender stands on the side of its goal, the last one guards the goal, and the others mark the blue attackers, so fewer team-mates are free. With the ball, red goes around a blue player, passes only forward and never through a blue player, and shoots when it has a clear view. A defender on the line of a shot halves its chance, for both teams. Blue computer players defend more simply, on purpose.

**Fourth round (2 Nov 2026), after the user played the third:** "goals are too rare, almost never", and red "almost never passes or approaches the area".

- **Why goals were rare:** red's last defender always stands on the line between the ball and the goal, so every shot counted as blocked and kept half of a 45% chance. The last defender no longer blocks (the goal chance already includes a goalkeeper), and a good shot now scores 60% of the time when clear.
- **Why red stalled:** the blue computer player nearest the ball stood in front of the red carrier and followed it at the same speed. It now follows from behind, still close enough for the Tackle button.
- **Why red rarely passed:** a blue player right behind the passer counted as being in the way of every pass, and red's attackers stayed level with the ball. Players behind the passer no longer count, and attackers now run ahead of the ball (`support_push` 7), so forward passes are possible. Red passes forward more often (`pass_gain` 2, `cpu_pass_chance` 0.6, `cpu_press_radius` 4, `forward_weight` 1).
- **Result with the human-like test player at Normal speed:** about 6 to 8 in 7 minutes (it was 2 to 7.6). Red makes about 15 passes and 35 shots and has the ball near the blue goal for about a minute. The test now checks that red passes and reaches the area.

**Retuned:** the player's tackle was too strong (it won 0.6 of the time from 2.5 away, every second): now 0.4, 2 away, every 1.2 s. The human-like test player now loses about 2 to 7.6 at Normal speed and 1.4 to 6.4 at Very hard speed (it lost 2.5 to 5 before, and the user found that a little easy).

**Changes made while building (beyond the plan):**

- A missed or saved shot restarts play like a goal does (the other team kicks off). Without this a strong player kept the ball at the goal and scored 18 times a match.
- The avatar's tackles have a wait and a chance to win the ball, for the same reason (`tackle_seconds`, `tackle_chance`).
- The match stops completely while the avatar waits, so nobody scores against a player who stopped.
- A saved match keeps its score, Breath and timing, but restarts from a kick-off.
- The pad reads touches itself (`scripts/ui/football_pad.gd`), because Godot's Button only hears the first finger.
- The speech bubble is hidden during a match, so the minutes are in the status line.

**Second round, after the user played it (31 Oct 2026):** "5x more time playing", "it isn't very intuitive", an explanation the first time, and better play on a computer.

| # | Question | Decision |
|---|---|---|
| 47 | How long does a match last? | **Avatar time runs 5 times slower while the avatar plays** (`time_slowdown`), so 60 minutes last about 7 real minutes. Not while it waits. Energy, training and Breath stay per avatar minute, so a move costs a fifth of its Breath. |
| 48 | The explanation | **It opens the first time someone plays football on this device** (`Settings.football_help_seen`, kept apart from the avatar) and the day pauses. The ? button or H opens it again. |

Choices Claude made for "work for it", to confirm:

- **The first computer team was far too strong.** A test player with human reactions lost about 2 to 23 in 7 minutes. A new test player with slower reactions set the values: it now loses about 2.5 to 5 at Normal speed and 1.9 to 5.9 at Very hard speed. A real player should do better.
- A player who just got the ball cannot be tackled for 1 second. The match stops 2 seconds after a goal or a miss.
- **New rule:** while a team-mate has the ball, Pass becomes **Ask for ball**, so the player is never left with nothing to do.
- On the field: arrows up the field, the green shot zone, a line showing where a pass goes, a ring on the player with the ball that turns green in tackle reach, YOU over the avatar, a small map of the whole field, a line saying what to do next, and short messages such as "Good pass!".
- Computer: no joystick, a list of keys and a larger field. WASD or arrows, Z or J to pass, X, K or Space to shoot or tackle, P to pause, H for help. The first touch brings the joystick back.

**Checked in the web build (31 Oct 2026, computer size, after the second round):** the explanation, Play, WASD, X, P, the field, messages, Ask for ball. Keys were sent by a script.

**Checked in the web build (browser pane, 31 Oct 2026, phone size):** the field, waiting, the joystick and a second finger on Pass at the same time (scripted touches), and Tackle replacing Shoot. The user then played it by hand on 31 Oct. **Not confirmed:** a real phone. Difficulty still needs people: a perfect test player wins about 8 to 0, and the human-like one above loses.

Goal: football becomes a real arcade match, with the core loop of Nintendo World Cup seen from above and played from bottom to top. Only the idea is used: the art, names, characters and code are original (concept document).

Read `CLAUDE.md`, `documentation/handoff.md`, `MILESTONE_12.md` and `MILESTONE_13.md` first. The rules of those milestones still hold: a session only exists with a player, so the scenario tests and every health number stay as they are.

## Decisions (user, 31 Oct 2026)

| # | Question | Decision |
|---|---|---|
| 39 | What does it look like? | **The Nintendo World Cup core loop, seen from above, bottom to top.** This replaces decision 29 (no football minigame). |
| 40 | Controls | **A full on-screen joystick**, plus action buttons. |
| 41 | Teams | **4 a side; the player always controls the avatar.** Team-mates and opponents are computer players. |
| 42 | Score | **Half timing, half staying active.** |
| 43 | Timing | **Pressing at the right moment:** a pass to a free team-mate or a shot close to goal is good. Fitness sets how wide those chances are. |
| 44 | Fatigue | **Bursts and recovery:** moves cost Breath and quiet moments refill a little. At an empty bar the avatar jogs until it partly recovers. Fitness, weight and sleepiness set how long it lasts. |
| 45 | Goals | **A match score against a computer team, with no effect on health.** Winning does not count; playing well does. |
| 46 | Defending | **Steer into the opponent and press Tackle** (it takes the place of Shoot). Tackling costs Breath. No fouls or injuries. |

## How it plays

The chosen minutes are the match: 60 avatar minutes last about 86 real seconds. The field is portrait and scrolls with the avatar, whose team attacks upwards.

- **With the ball:** the joystick moves the avatar, and the two buttons are Pass and Shoot.
- **Team-mate has the ball:** the avatar runs into space, and the computer player passes or shoots.
- **Opponent has the ball:** the buttons become Pass (disabled) and Tackle.
- **After a goal:** kick-off from the centre.

The panel shows the match score, the time left and the Breath bar. Sprinting into moves empties Breath faster; at 0 the avatar jogs more slowly and at `walk_mety` until `run_again_at`.

## Assumptions to confirm

- The player stops (not asked this time): same as cardio and strength. After 3 seconds with no input the avatar stands still and nothing counts, and 20 seconds later the activity ends.
- A short session is very short: 5 avatar minutes is 7 real seconds. A session that short may need a higher slider minimum for football.
- Computer players get no tuning from the avatar's difficulty. Only the avatar's body changes the match.

## The science (Task 1)

Read as search summaries of the abstracts, not as full papers.

| Fact | Source | Used for |
|---|---|---|
| Italian national-team U10 players covered 3,386 m in a match, 1,369 m of it at high intensity; U8 players 2,354 m and 887 m. | U8 and U10 match running study (air.unimi.it/handle/2434/301628) | Football is stop-and-go, with a large high-intensity share, so bursts and recovery fit (decision 44). |
| High-intensity distance is linked with 20 m shuttle-run performance (r² 0.62). | Same study | Fitness sets how long the avatar lasts. |
| Match running rises with age and depends on position; there is no clear consensus that activity falls during a match, and match formats differ between studies. | Systematic review of 50 studies, Sports Medicine 2019 (clok.uclan.ac.uk/24825) | Fatigue is a game design choice with placeholder sizes, not a measured curve. |
| Prepubertal children recover from hard exercise quickly. | Birat 2018 (`MILESTONE_12.md`) | Quiet moments refill a little Breath. |
| The Youth Compendium gives youth METs by age group. | Butte 2018 | METy 7.5 stays. **Not confirmed in this search:** the football row itself was not read here. |

**Not found:** walking and jogging shares for ages 10 to 12, and small-sided game data for 4 a side. Every football number is therefore a placeholder for the team. No study supports a specific Breath cost per move.

## The tasks

Each task is reviewed, tested and committed on its own. Nothing is pushed.

**Task 1 — Science.** Read real sources on children's football: how much is walking, jogging and sprinting, and small-sided games. Check that METy 7.5 and the bursts-and-recovery model fit. Record what was read and what could not be. Every number that has no source is a placeholder.

**Task 2 — Load model.** `scripts/health/football_load.gd`, values in the config group `minigame`: capacity from fitness, weight and sleepiness; avatar speed; Breath cost of moves; chance width. Tests for each difficulty.

**Task 3 — Match logic without a screen.** `scripts/health/football_match.gd`: positions, ball, possession, computer players, pass, shot, tackle, goals, kick-off. Fixed steps and a seeded random generator, so tests repeat exactly.

**Task 4 — Connect to Minigame.** A `FOOTBALL` kind: score, active share, Breath, waiting, jogging at `walk_mety`, saving in the middle of a match. Done when: without a player every number is exactly as before.

**Task 5 — Field and joystick.** A drawn top-down field that scrolls, a touch joystick with keyboard arrows, Pass and Shoot or Tackle, kick-off messages. Texts in both languages. Placeholder shapes only.

**Task 6 — Review and finish.** Read the whole change again, run all tests and stop on any failure, compare the scenario test with the version before, check the web build at phone width with touch, export, update the documents. The user plays it.

Also in Task 1: fix `tests/difficulty_test.gd`, which reads the player's real save and fails when one exists.

## Out of scope

Minigames for screens and meals, special shots, tournaments, and any health value.
