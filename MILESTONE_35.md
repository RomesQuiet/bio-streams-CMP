# Milestone 35: the video game (screens minigame, 21 Nov 2026)

Request (user, 21 Nov 2026): "now milestone 35. the screens - now videogame - minigame will be a dinossaur like chrome's, but not pixelated that will jump from one cloud to another like a sky with geometry dash mechanics, if it falls, dies, if it goes to a cloud in side, the cloud doesn't move and it falls, the clouds are like platforms in geometry dash, and the is one input type, a button at the bottom of the screen, following the in-game art. There should be score for that moment, and a specific highscore for that avatar, and a leaderboard for all the avatars in that device. The clouds are ramdomly generated, and the game should become more dificult as time goes by just as chrome's, don't worry very much with specific dinossaur's art."

The number 35 is the user's: there are no Milestones 31 to 34.

## What it is

- **Screens is now "Video game"** (option id `screens` kept, so saves, the health model and the scenario tests are unchanged). Choosing it with the minutes slider opens **Cloud jump** where the avatar stands, in a screen with a navy frame.
- **A dinosaur** (simple shapes, not pixels: green body, belly, head, eye, arm, legs that move while it runs) runs to the right by itself over white clouds in a day sky, with faint clouds far behind moving slower and a sun.
- **One input:** a big **Jump** button at the bottom, drawn like the four main buttons (gold, the entertainment colour, an arrow up). On a computer Space, the arrow up, W or Enter also jump, and P pauses. Holding Jump jumps again on every landing, as in Geometry Dash.
- **Clouds are platforms:** landing on a cloud's top is safe; running into a cloud's side (or jumping into its underside) stops the dinosaur where it is, the cloud does not move, and it falls straight down. Falling under the view ends the run. Feet just under a cloud's top (12 units) step onto it instead of hitting it. A press just before landing (0.12 s) or just after running off a cloud (0.08 s) still jumps, so it feels fair.
- **Harder with time, like Chrome's dinosaur:** the speed starts at 420 units a second and grows by 3.5 every second up to 900 (after about 137 s). Clouds come further apart, narrower, and with higher steps up and down as the speed grows.
- **Random but always possible:** every cloud is made from the last one so that a jump from the very edge clears its side (if it is higher) and lands on it. A test bot that jumps at every edge survives 25 random courses for 200 s, past the highest speed.
- **Score:** one point per 40 units run (about 10 a second at the start), shown at the top right with the avatar's **Best**, and under the game ("Score N").
- **Cards:** before the first jump, "Cloud jump", the rules and "Press Jump to start"; after a run, "Game over", the score, "New record!" when it is the avatar's best, and "Press Jump to play again" (after 0.8 s). Both show **"Best on this device"**, the leaderboard, with the current avatar's row in gold. While the day is paused a card says "Paused: press play next to the clock" (Jump does nothing then, as in the other minigames).

## Decisions (Claude's proposals from the user's words; the team checks them)

| # | Decision |
|---|---|
| 103 | **The score never changes health.** Screen time counts exactly as before, played or not (the session never waits, never stops by itself, and screens keep METy 1.3 and the happiness rules). |
| 104 | **The avatar's best** (`GameState.sky_best`) is saved with the avatar. Each avatar gets a random id (`GameState.avatar_id`, saved; an older save gets one when it loads) so two avatars with the same name are told apart. |
| 105 | **The leaderboard belongs to the device** (`Settings.sky_leaderboard`, in `user://settings.json` and localStorage, like the language): the best score of each avatar, best first, at most `minigame.sky.leaderboard_size` (5). An avatar that was deleted or failed keeps its place. |
| 106 | **A run that is cut short counts:** when the activity ends (its minutes run out, or Stop) during a run, its score is recorded too. A reload starts a new run (a run is not saved). |
| 107 | **Avatar time is not slowed** while playing (`minigame.sky.time_slowdown` 1; football uses 6.67): 60 minutes of video game still last about 64 real seconds. The team can raise it. |
| 108 | **"Video game" in the texts:** the option is "Video game" / "Videojogo", the wish "Can I play a video game?" / "Posso jogar um videojogo?" and "You never let me play video games." / "Nunca me deixas jogar videojogos." (they were about watching). The failure screen's habit stays "Screens" (screen time). |

All numbers are placeholders in the new config group `minigame.sky` (owner Pessoa 4). Open for the team: the METy of a sitting video game (1.3 is "watching TV", Youth Compendium), the game's numbers after people play it, and the Portuguese (Claude's draft).

## Files

- `scripts/health/sky_run.gd` (new): one run, fixed steps of 1/120 s and a seeded random generator, no screen and no health; clouds, jumping, landing, side and underside hits, falling, the score and the speed.
- `scripts/autoload/minigame.gd`: kind `sky`, `jump(down)`, `run`, `run_seed`, signal `sky_run_ended(score, best)`, never waiting, records the score.
- `scripts/autoload/game_state.gd`: `sky_best`, `avatar_id`. `scripts/autoload/settings.gd`: `sky_leaderboard`, `record_sky_score()`.
- `scripts/ui/sky_game.gd` (new): the screen, sky, clouds, dinosaur, score and cards. `scripts/ui/main.gd`: the view instead of the avatar, the Jump button, keys, status and score. `scenes/main.tscn`: `SkyGame` in the stage, `JumpButton` in the minigame panel.
- `scripts/ui/action_button.gd`, `ui_style.gd`, `ui_icons.gd`: the "jump" kind (gold, an arrow up).
- `data/activities.json` (`"minigame": "sky"` on screens), `data/config.json` (`minigame.sky`), `translations/strings.csv` (`SKY_*`, the three changed texts).
- `tests/sky_test.gd` (new); `tests/minigame_test.gd` (screens are now a session) and `tests/translation_test.gd` (reads `sky_game.gd` and `SKY_` keys).

## Checked

`sky_test` (new, 42 checks): waiting for the first press, speed and score, jumping and landing, falling off the last cloud, a side hit stops the dinosaur and it falls straight down, stepping onto a cloud a little higher, an underside hit, the restart delay, the same seed gives the same clouds, every course is reachable (the bot), harder clouds at the highest speed (at the start: width 410, gap 135, step 42; at the highest speed: width 326, gap 430, step 95), the leaderboard (5 kept, one per avatar, saved), the session (screen time counts before, during and between runs; the best and the board are written; Stop during a run records it; no player means plain screen time), and the save (best and id kept; an older save gets an id).

Also run, all pass: `config_test` (no number in the health scripts), `settings_test`, `settings_panel_test`, `save_test`, `minigame_test`, `measures_test`, `failure_test`, `minutes_slider_test`, `scenery_test`, `interface_test`, `requests_test`, `translation_test`, `football_test`, `activities_test`. The scenario tests were not run: nothing in the health model changed, and they have no player, so screens stay plain screen time there.

**Web build** (exported to `docs/`) checked in the browser pane: a new avatar, Entertainment → Video game for 240 minutes, the start card, a run with the button and with Space, a crash, the game-over card with "New record!" and the board, a reload in the middle (the activity goes on, the best and the board are kept, a new run waits) and the paused card. No console errors. Not played by a person yet; a real phone is not confirmed.
