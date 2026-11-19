# Milestone 26: fixes after the review of the new look (19 Nov 2026)

The user asked "Do you like the new look?". Claude rendered the main screen (`tools/render_ui_states.gd`) and listed five problems. The user said: "yes, and also, it is possible to lose xp, fix it too, and make the xp level numbers change". Built as small patches, each committed on its own.

## Decisions

- **90 (user, 19 Nov 2026): XP is never lost.** It replaces the "down" half of decision 72. A rise in target health above the highest target health reached so far (`GameState.xp_health`, now a high-water mark) gives `progress.per_health_point` x the rise. A fall takes nothing. Climbing back up to the earlier best gives nothing, so health that goes up and down cannot farm XP. The hourly bonus at 4.5 or more is unchanged. The level never goes down. (User's answer: "XP only goes up".)
- **91: the XP level numbers.** The user said the level "doesn't change at all". The code was checked headlessly (+150 XP rolls the display from 0 to 1) and in a web build (99 XP plus a +10 XP rise rolls "0 → 1" to "1 → 2", with "+10 XP" under the bar). No display bug was found. The likely cause is the old rule: XP went up and down with health, so the level rarely crossed a boundary or fell back. With decision 90 the level only climbs.

- **92 (user, 19 Nov 2026): farming XP is allowed.** "It should be possible to farm XP... imagine someone is on the health 5 maximum... it doesn't gain any more XP. That shouldn't be possible." It replaces the high-water mark of decision 90: every rise in target health gives XP, also after a fall, and a fall still takes nothing. At 4.5 or more the hourly bonus also gives XP.

## Patches

1. `8b91875` XP is never lost (`scripts/health/progress.gd`, `tests/health_xp_test.gd`).
2. The sun and moon pass above the avatar's head: a higher arch (`arch_share` 0.86) that rises sooner and is flatter on top (`arch_roundness` 0.45, `SkyBodies.point()`).
3. The meal minigame shows a ring around the mouth instead of a see-through box over the face (`scripts/ui/meal_fork.gd`).
4. `75884a5` A greener ground by day (the 07:30 to 16:30 ground colours in `scripts/ui/sky_palette.gd`; dawn, dusk and night unchanged) and the 12-hour clock without a leading zero ("7:15 PM", `Clock.clock_text_12h()`).

Not changed: the keyboard hints ("Bite! [Space]") are already hidden on touch screens (`football_pad.touch_mode`); the review's render ran on a computer, so they showed.

5. Decision 92: `xp_health` is again the last step's target health; only rises give XP.

## Still to check

A real phone. The team may want to confirm the greener ground, since the specification's mockups have a blue ground (decision 85).
