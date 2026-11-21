# values.md — changed numbers (pass 3, 21 Nov 2026, final)

Every colour was read from the mockups' pixels with a script (the median of a 5 × 5 patch), not by eye, then rounded into one consistent set where mockups disagree. Positions and sizes are in `changes.md` (tables), all in the 720 × 1280 column.

## scripts/ui/ui_style.gd

```
EXERCISE_COLOR = #93f7e0         (was #84f2da)
SLEEP_COLOR = #d9c6fd            (was #cdbcf7)
EAT_COLOR = #fea6b5              (was #ffa6a6)
ENTERTAINMENT_COLOR = #ffe385    (was #ffe27a)
```

`PANEL_COLOR` (#232a6e), `INK`, `TRACK`, `SHADOW_COLOR`, `XP_COLOR`, `HEALTH_COLOR` and every size constant do not change.

## scripts/ui/sky_palette.gd (rows 0.0 and 4.75, the night)

```
0:00   top #151a5f  middle #1d2471  horizon #2b3184 (unchanged)  ground_top #252d85  ground_bottom #22287a  stars 1.0
4:45   top #151a5f  middle #1d2471  horizon #2b3184 (unchanged)  ground_top #252d85  ground_bottom #22287a  stars 1.0
(was   top #10164a  middle #1a2166  horizon #2b3184              ground_top #2a3388  ground_bottom #1b2163)
```

Every other row stays (the day ground keeps Milestone 26's green: `changes.md`, Q5).

## new

The first column is the short name used in the tables of `changes.md`; the second is the constant to add to `ui_style.gd`.

```
STOP          STOP_COLOR = #fd95b4             stop pills (face)
STOP_BASE     STOP_BASE = #e0668e              their thickness
UP            MINIGAME_UP_COLOR = #8afade      UP, Bite, Start, Continue, Take a break, Tap to run, Eat the plate
UP_BASE       MINIGAME_UP_BASE = #3db38b       their thickness; also the base of a chosen tile or card
DOWN          MINIGAME_DOWN_COLOR = #6c78c2    the DOWN button
DOWN_BASE     MINIGAME_DOWN_BASE = #4c56a0
SLEEP_BASE    SLEEP_BASE = #a98ce8             thickness of Wake up, Done, Keep watching, Back
ZONE          ZONE_COLOR = #6bf0b0             green zones of every timing bar
TILE          TILE_COLOR = #eef1fb             menu tiles, cards, Cancel
TILE_BASE     TILE_BASE = #9babde              their thickness; keycap base
BADGE         BADGE_COLOR = #22b573            the round "chosen" badge (a white check inside)
PLATE         PLATE_COLOR = #f4f6ff            the canteen plate; the plant pot
PLATE_RIM     PLATE_RIM = #b0c3ee              the plate's rim line
SLOT_LINE     SLOT_LINE = #7b8eba              dashed outline of an empty plate slot
SCREEN_FILL   SCREEN_FILL = #fed96d            the screen-time bar fill
SCREEN_TARGET SCREEN_TARGET = #fb627c          its target ring
STEPS_FILL    STEPS_FILL = #6df9cf             the cardio Steps bar
BREATH_FILL   BREATH_FILL = #29d3fd            the Breath bars
PASS          PASS_COLOR = #6cd6fd             football Pass
PASS_BASE     PASS_BASE = #2a9fd6
SHOOT         SHOOT_COLOR = #fd98a8            football Shoot / Tackle
SHOOT_BASE    SHOOT_BASE = #d9566f
STRIPE_A      FIELD_STRIPE_A = #2db576         field stripes (replace the current mint pitch)
STRIPE_B      FIELD_STRIPE_B = #25a56a
SUBTITLE      SUBTITLE_COLOR = #477297         card subtitles
SLIDER        (XP_COLOR, #2fc0f5)              the minutes slider fill: no new constant
WOOD          WOOD_COLOR = #cc8358             side table top
WOOD_DARK     WOOD_DARK = #a8643e              side table body
LAMP          LAMP_COLOR = #fdefbc             lamp shade
LEAF          (LEAF_GREEN, #38c172)            plant leaves: no new constant
PANEL_92      PANEL_COLOR at alpha 0.92        cardio and football panels
DOCK_BAND     PANEL_COLOR at alpha 0.85        the band behind the meal dock
WHITE_08 / WHITE_25 / WHITE_60                 white at alpha 0.08 / 0.25 / 0.60
CHIP          INK at alpha 0.35                key chips and the score capsule
TIMING_BOX    INK at alpha 0.35                the cardio timing box
SHADOW        INK at alpha 0.30 to 0.35        floor and plate shadows (alpha given per element)
```
