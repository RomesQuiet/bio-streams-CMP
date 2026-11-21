# Milestone 30: football restarts (21 Nov 2026)

Request (user, 21 Nov 2026): "football, when someone fails, it goes directly to the midfield, it should wait some time, or people who are trying to tackle spamming, they just start always with shot at the goal".

## Causes found

- After a missed shot the match restarted with a kick-off in the middle of the field, as after a goal.
- The protection of a player who just got the ball (`protect_seconds`) only stopped computer tackles. The player's own Tackle button ignored it, and also worked while the match was stopped, so pressing Tackle again and again won the ball straight from the restart, close to goal.

## Decisions (decision 102, Claude's proposal from the user's words; placeholders)

- **A miss gives a goal kick:** the team that restarts gets the ball at its keeper (its deepest player), not in the middle. A goal still restarts with a kick-off in the middle.
- **The match waits longer after a goal or a miss:** `restart_seconds` 2 → 3 real seconds.
- **After a restart the kicker is protected from every tackle, the player's too,** for `restart_protect_seconds` (3 s, new) once the match goes on; nobody tackles while the match stops. During play, a player who just got the ball is protected for `protect_seconds` (1 s) from the player's tackles too, not only the computer's. The tackle ring and hint only show "in reach" when a tackle is allowed.

## Files

`scripts/health/football_match.gd` (`kick_off(ours, stop, goal_kick)`, `_deepest()`, `can_tackle()`, `in_tackle_reach()`), `data/config.json` (`minigame.football.restart_seconds`, `restart_protect_seconds`, `protect_seconds` comment), `tests/football_test.gd` (new checks: no tackle while stopped, the kicker protected from the player, a goal kick goes to the keeper of each team; the tackle checks that start right after a kick-off now skip the protection).

## Checked

`football_test`, `minigame_test`, `interface_test`: all pass. Not played by a person yet.
