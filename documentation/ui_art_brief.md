# UI art brief: every button, bar, panel and icon

Written 18 November 2026 for the image generator (for example GPT Image) that will design the
whole interface of the game. It lists **what to deliver, at what size, in which colour, and
how each file must be laid out** so the pictures can be cut and put into the game without
redrawing them.

Everything here comes from the game as it is now (Godot project, Milestones 1 to 21). Where
this brief proposes something new (colours, the new creation screen, a few size changes), it
says **Proposal** and the user or the team has to confirm it (list in section 14).

How to use it:

1. Give the image generator **section 1 (the game), section 2 (the style), section 3 (the
   colours) and the "Master prompt" in section 12** every time, so every picture matches.
2. Then ask for **one sheet at a time** with its own prompt from section 12 (icon sheets,
   button skins, bars, panels, food, backgrounds) and the mockups in section 13.
3. Check each result against the checklist in section 12.4 before using it.

---

## 0. The two kinds of picture we need

| Kind | What it is | Used for |
|---|---|---|
| **Mockups** | A full picture of one screen, as it should look, with text written in. | A reference only: Claude builds the screen in Godot from it. Mockups are never cut. |
| **Assets** | Separate, cut-ready pieces on a fixed grid: blank button shapes, bars, panels, icons, food pictures, backgrounds. | Put into the game. |

**The most important rule for assets: no text inside them.** The game is in Portuguese and
English and every word is written by the game on top of the art. Button shapes, bars, panels,
badges and ribbons are blank. Only mockups have text.

---

## 1. The game (give this to the image generator)

- Name: **Plasticine Tamagotchi**. A free web game for a European science competition
  (Bio-Streams) about **childhood obesity**. Made by a 9th-grade student team. Everything is
  public and free to use (art: CC BY 4.0).
- The player looks after an avatar, a school student (child 6 to 12 or teenager 13 to 18,
  girl or boy), and raises its health (1 to 5) with **sport, sleep and food**.
- Players are children and teenagers aged about 9 to 16, on **phones first** (Android and
  iPhone in a browser), also tablets and computers.
- Tone: friendly, calm, clear and respectful. Scientific, not childish. **No body shaming**:
  nothing in the interface mocks weight or makes fun of food choices.
- The screen is **portrait, 720 x 1280** (9:16). On wide screens the game stays in a centred
  column of that shape.
- Two languages: **Portuguese (Portugal)** and **English**. Portuguese words are usually longer
  (see section 4.3).
- The avatar's own pictures (bodies and faces) already exist; **do not draw the avatar** in
  any asset. In mockups, draw a simple friendly cartoon student standing in the centre as a
  stand-in.

---

## 2. Style: "minimal tactile"

The interface should look like **soft, chunky, physical keys and cards that you want to press**,
drawn in a clean flat way.

### 2.1 Do

- **Flat colour shapes** with **large rounded corners**.
- A **dark outline** around every button, bar, panel and icon (ink colour `#1B1F2A`).
- A **solid "lip" under each button**: a darker band of the same colour along the bottom edge,
  as if the button were a thick key standing on the screen (section 5.2). This is what makes it
  "tactile".
- A **very soft highlight** along the top inner edge of buttons (a lighter band, about 15% lighter
  than the face, 1/6 of the height, no gradient banding). Optional, but the same on every
  button.
- **Chunky, simple icons**: thick rounded strokes, round line ends, few details, recognisable
  at 24 pixels.
- Lots of **empty space**; one clear action per button.
- One **light direction** for everything: light from the **top**, so the lip and shadows are
  always at the bottom.

### 2.2 Do not

- No glossy, glassy, metallic or 3D-rendered look. No strong gradients. No neon glows.
- **No texture or noise on button shapes, bars and panels** (they are stretched in the game,
  and a texture would stretch and blur). Food pictures and backgrounds may have a very faint
  matte clay feel ("plasticine"), but stay clean.
- No blurry drop shadows outside the shape (the lip replaces the shadow). A small hard shadow
  under panels is allowed (section 7.2).
- No text, letters or numbers inside assets.
- No real brands or logos (no fast-food chains, no soft-drink brands, no console or TV brands,
  no football club badges). Foods and objects are generic.
- No copying of another game's interface or characters.
- No thin hairlines: the thinnest line is the outline.

---

## 3. Colours: each function has its own colour

The player must understand a button by its colour **and** its icon **and** its word. Colour is
never the only signal (some players are colour-blind), so every coloured button also has an
icon.

### 3.1 Colour roles (Proposal, from the user's brief: stop and cancel are red)

| Role | Face | Lip (bottom band) | Text and icon on it | Meaning, where used |
|---|---|---|---|---|
| **go** | `#2E9E4A` green | `#217135` | white `#FFFFFF` | Start, continue, confirm, play: Start, Continue, Play, Eat the plate, Done (meal), Sleep (confirm in the sleep panel), New avatar (menu, first visit). Also the health colour. |
| **stop** | `#D93A2F` red | `#9C2921` | white | Stop and cancel only: Stop, Cancel (every panel), the health box in the danger state. |
| **danger** | `#9E1F17` dark red | `#711610` | white | Actions that delete or cannot be undone, after a warning: "Yes, delete", "Yes, start again". Always with the warning icon. |
| **exercise** | `#F28A1E` orange | `#AE6315` | ink `#1B1F2A` | Exercise button, its options (cardio, squats, push-ups, sit-ups), the cardio and strength minigame buttons (Tap to run, Down, Up), Shoot and Tackle in football, the Physical bar. |
| **sleep** | `#4C56CF` indigo | `#363D95` | white | Sleep button, the sleep panel, the Sleep amount bar. |
| **eat** | `#F6C343` warm yellow | `#B18C30` | ink | Eat button, Bite, Skip meal, the canteen header. |
| **fun** | `#B33E8E` magenta | `#802C66` | white | Entertainment button and its options (screens, football), the Happiness bar. |
| **wake** | `#5BBDF5` morning sky blue | `#4188B0` | ink | The Wake button (start the new day). |
| **team** | `#2F6FE0` blue | `#214FA1` | white | Football: Pass and Ask for ball (the avatar's team is blue). |
| **gold** | `#F2B705` gold | `#AE8303` | ink | XP: the XP level box and the XP bar fill. |
| **neutral (day)** | `#FFF8EC` warm white | `#B7B2A9` | ink | Everything that only moves around or changes a setting: Back, Close, Settings, Pause, Main menu, Details, About, Avatars, Load a backup, Backup, Help, language buttons, choice buttons that are not chosen. |
| **neutral (night)** | `#2E3340` charcoal | `#21242E` | white | The same neutral buttons while it is night in the game (section 3.3). |
| **disabled** | `#C9CCD3` grey | `#909297` | grey `#6B7280` | Any button that cannot be pressed now (for example Wake before the sleep ends, Start before a choice). |

Contrast (checked, WCAG 2.1): white on red 4.6, on indigo 5.9, on magenta 5.3, on blue 4.7,
on dark red 7.9, on green 3.4 (only for large bold text, 24 px or more, which all green
buttons use); ink on orange 6.6, on yellow 10.0, on sky blue 7.9, on gold 9.1, on warm white 15.6.

### 3.2 Other colours

| Name | Hex | Used for |
|---|---|---|
| ink | `#1B1F2A` | All outlines, dark text, icon outlines. |
| health green | `#2E9E4A` | Health bar fill, health level box, health heart. Same as **go**. |
| danger red | `#D93A2F` | Health bar fill and health box in the danger state ("Health: danger"), the failure screen header. |
| bar track (empty part) | `#2B3040` | The empty part of every bar. |
| minigame bar fill | `#B8BCC6` light grey | Breath, Muscle and Tummy bars (they change colour by state in the game, see 7.1). |
| healthy food | `#4DB85F` | Frame and title of the healthy food chooser in the canteen. |
| less healthy food | `#F08C3C` | Frame and title of the "bad food" chooser. Orange, **not red** (red means stop). |
| panel (day) | `#FFF8EC` with ink outline | Every panel and card by day. |
| panel (night) | `#262A35` with a `#4A5060` outline | Panels at night. |
| dim | black at 60% | Behind panels that cover the screen. |
| sky (day) | `#4D73A0` | Placeholder sky colour now. |
| sky (night) | `#0F1224` | Placeholder night sky now. |
| ground | `#808085` grey | The ground under the avatar's feet, to the bottom of the screen. |
| XP gain | `#7CF07C` | "+37 XP" floating text. |
| XP loss | `#FF8073` | "−20 XP" floating text. |

### 3.3 Day and night

The game has a sky that turns dark at night. Now, buttons are white by day and black at night.

- **Coloured buttons keep their colour day and night** (only one set of art).
- **Neutral buttons have two versions**: warm white by day, charcoal at night.
- **Panels have two versions**: warm white by day, charcoal at night.
- Outlines stay ink. At night, the charcoal pieces use a lighter outline `#4A5060` so they stay
  visible on the dark sky.

---

## 4. Canvas, scale and text

### 4.1 Sizes

- Game screen: **720 x 1280** pixels ("1x"). All sizes in this brief are 1x.
- **Deliver every asset at 2x** (twice the size), so it stays sharp on phone screens. A button
  of 328 x 120 at 1x is drawn at 656 x 240. The asset sheets in section 12 already use 2x or
  larger cells.
- Screen margins (main screen): 24 px left, right and top, 32 px at the bottom. The usable
  width is **672 px**. Gaps between buttons: **16 px**.
- Smallest touch target: **56 x 56 px** (most are 64 or more).

### 4.2 Font (for mockups; the game writes the real text)

- **Proposal:** a rounded, friendly sans-serif with Portuguese accents (ã, õ, ç, á, é, ê, í, ó, ú):
  **Nunito** (SIL Open Font Licence, free), ExtraBold for buttons and titles, Bold for other text.
  Alternative: Fredoka (also OFL). The game now uses Godot's default font.
- Sizes used at 1x: buttons 26 (bold), small buttons 22, labels 20 to 22, panel titles 32,
  screen titles 40, menu title 52, bar labels 20 with a 4 px ink outline (white text).

### 4.3 Longest words (leave room for them)

Every button must fit the **longer** of the two languages:

| English | Portuguese (longer) |
|---|---|
| Entertainment | Entretenimento |
| Skip meal | Saltar a refeição |
| Start a new avatar | Criar um novo avatar |
| Load a backup | Carregar cópia |
| Ask for ball | Pedir bola |
| Done | Já chega |
| Wake | Acordar |
| Sleep amount | Quantidade de sono |
| Fast-food meal | Refeição de fast food |
| Yes, start again | Sim, recomeçar |
| Tap to run | Toca para correr |

---

## 5. Button anatomy (all rectangular buttons)

### 5.1 Shape

- Rounded rectangle, **corner radius 18 px** (36 at 2x) on buttons 56 px tall or more; buttons
  under 56 px use 14 px.
- **Outline 3 px ink** (6 at 2x), all around, including around the lip.
- **Face**: the role colour, flat, with the optional soft top highlight (section 2.1).
- **Lip**: 6 px tall (12 at 2x) along the bottom, inside the outline, in the role's lip colour.
  The face and the lip are separated only by the colour change (no line).
- Total height includes the lip: a 120 px button is 114 px of face and 6 px of lip.

### 5.2 States

| State | Look | Who makes it |
|---|---|---|
| **normal** | As above. | Image generator. |
| **pressed** | No lip; the face moves down by 4 px, so the button looks pushed into the screen. The face is 4% darker. Outline unchanged. | Image generator. |
| **hover** (computer mouse) | Normal, face 8% lighter. | Godot (brightens normal). |
| **disabled** | The disabled grey face and lip, grey text and icon. | Image generator (one grey skin for all). |
| **selected** (choice and language buttons) | Neutral face, a **4 px green `#2E9E4A` ring** just inside the outline and a **green check badge** (28 px circle) in the top-right corner. | Image generator: the ring and the badge as separate overlays (section 12, sheet K). |
| **focus** (keyboard on a computer) | A 3 px ink dashed or light ring 4 px outside the button. | Godot. |

### 5.3 Content of a button

- **Icon + word**, always both (except Pause and Settings, which are icon-only, with a tooltip).
- Two layouts:
  - **Stacked** (big square-ish buttons, 120 px tall): icon on top, centred, word under it.
  - **Inline** (wide, 56 to 96 px tall): icon on the left, word next to it, both centred as a
    group (option buttons: left-aligned, icon 24 px from the left edge).
- Icon colour = text colour of the role (white or ink). Icons are delivered **white** and the
  game tints them (section 9.1).

### 5.4 How the game uses the shapes (for the cutting)

Every blank button shape is used as a **9-slice**: the four corners stay as drawn, the edges and
the centre stretch. So:

- The shape must be **the same along each edge** (no decoration that would stretch).
- The corners must be **inside the outer 56 px** of the 2x cell on the left, right and top, and
  the **outer 64 px** at the bottom (lip included).
- In the 256 x 256 cell of sheets S1 and S2 (section 12), the shape fills x 16 to 240 and
  y 16 to 240 exactly. The 16 px around it are empty and transparent.

---

## 6. Every screen and every button

Positions are x, y of the top-left corner at 1x, size is width x height at 1x. "Fixed" means the
position comes from the user's sketch and must not move.

### 6.1 Main game screen (day and night)

Layout from top to bottom, 720 x 1280:

```
 y=24  [Health box][ Health bar ][   XP bar   ]   [XP box]
       88x88       220x40        248x40           88x88
 y=64              [measures panel, opens here]   [clock 88x40]
                                                   [pause 88x64]
                                                   [settings 88x64]
                                                   [wake 88x56]
 y=286           [ speech bubble 440x70 ]
 y=386-836              ( avatar 330x450, feet on the ground line y=836 )
 y=836 ---------------- ground line (grey ground to the bottom) ----------
 y=912 [                    Stop 672x64 (only during an activity)        ]
 y=992 [ Exercise 328x120 ]  [ Sleep 328x120 ]
 y=1128[ Eat 328x120      ]  [ Entertainment 328x120 ]
```

#### Top bar (fixed positions)

| Element | Position, size | Colour role | Content | Notes |
|---|---|---|---|---|
| **Health level box** (a button) | 24, 24, 88 x 88 | **go** green; **stop** red in the danger state | Top: the word **"HEALTH" / "SAÚDE"** (14 px, extra bold, capitals) in a band 24 px tall. Under it: a small heart icon (20 px) left of the **number 1 to 5** (40 px). | **New (user's request):** players thought it was only a number. Pressing it opens the measures panel. |
| **Health bar** (inside a flat button) | 120, 24, 220 x 40 | track `#2B3040`, fill health green (red in danger) | The word "Health" or "Health: danger" centred, white, ink outline. | Bar shape: section 7.1. Pressing it opens the measures panel. |
| **XP bar** | 352, 24, 248 x 40 | track `#2B3040`, fill **gold** | A star icon (24 px) at the left inside the bar, then "XP 37 / 100" centred. | Under it the floating "+37 XP" or "−20 XP" (26 px, rises and fades). Now white; gold is the **Proposal**. |
| **XP level box** | 608, 24, 88 x 88 | **gold** | Top band: **"XP LEVEL" / "NÍVEL XP"** (13 px capitals). Under it: a star icon (20 px) and the **level number** (36 px). | **New (user's request):** today it says only "Lv". Not pressable; drawn like a panel (no lip) or like a button with no pressed state. |
| **Clock** | 608, 120, 88 x 40 | neutral pill (day or night) | "07:00" (22 px) and a tiny sun or moon (16 px) on the left. | Not pressable. |
| **Pause** | 608, 168, 88 x 64 | neutral | Pause icon 40 px (two bars). While paused, a play icon. | Icon only. |
| **Settings** | 608, 240, 88 x 64 | neutral | Gear icon 40 px. | Icon only. |
| **Wake** | 608, 312, 88 x 56 | **wake** sky blue; disabled grey until a sleep ends | Stacked: a rising-sun icon (24 px) above the word "Wake" / "Acordar" (17 px). | Enabled only after a sleep. When it becomes enabled it should look inviting (the brightest thing on the night screen). |

#### Panels opened from the top bar

| Element | Position, size | Look | Content |
|---|---|---|---|
| **Measures panel** | 120, 64, 300 x 236 (touches the health bar, no gap) | panel (day or night), square top-left corner where it meets the bar | Three rows, each: icon 28 px + name (22 px) above a bar 30 px tall. **Physical** (body icon, orange fill), **Happiness** (smiley icon, magenta fill), **Sleep amount** (moon icon, indigo fill). The Physical bar is pressable (opens the values panel). |
| **Physical values panel** | 428, 64, **Proposal: 268 x 340** (now 160 wide and too narrow) | panel | Seven rows, each 44 px: icon 28 px, name (18 px), value right-aligned (20 px bold): Calories spent (flame), Strength (dumbbell), Fitness (lungs), Weight (scale), Height (ruler), BMI-for-age z (gauge), Diet quality (apple). |

#### The avatar's area

| Element | Position, size | Look |
|---|---|---|
| **Speech bubble** | centred, 140, 286, 440 x 70 | White `#FFFFFF` rounded rectangle (radius 22), 3 px ink outline, a **tail** 32 x 20 pointing down at the centre towards the avatar's head. Text in ink, 22 px. A **request picture** 60 x 60 on the left when the avatar asks for something (section 10.1). Grows in height for two lines. |
| **Avatar** | 195, 386, 330 x 450, feet on the ground line y = 836 | Existing art, not part of this brief. |
| **Ground** | from y = 836 to the bottom, full width | Grey `#808085`, flat. |
| **Stop button** | 24, 912, 672 x 64 | **stop** red, inline: stop icon (square, 32 px) + "Stop" / "Parar". Only visible during an activity, above the four buttons. |

#### The four action buttons (fixed: 2 x 2 grid at the bottom)

All 328 x 120, gap 16, stacked layout (icon 56 px on top, word 24 px extra bold under it).

| Button | Position | Colour role | Icon | Words |
|---|---|---|---|---|
| **Exercise** | 24, 992 | exercise orange | running figure | Exercise / Exercício |
| **Sleep** | 368, 992 | sleep indigo | moon with "z z" | Sleep / Dormir |
| **Eat** | 24, 1128 | eat yellow | fork and knife | Eat / Comer |
| **Entertainment** | 368, 1128 | fun magenta | TV with a ball | Entertainment / Entretenimento |

While an activity runs the four buttons are locked (disabled grey, icons still visible).

### 6.2 Activity options panel (Exercise and Entertainment)

Centred panel 600 x 340 or taller (60, 400 at 1x on the main screen). Padding 24.

| Element | Size | Look |
|---|---|---|
| **Header band** | full width x 64 | The activity's colour (orange or magenta) with its icon (40 px) and title ("Exercise", 32 px) in that role's text colour. Top corners rounded, bottom straight. **Proposal.** |
| **Minutes label** | text | "Minutes: 30" (22 px). |
| **Minutes slider** | 552 x 48 | Track 16 px tall, rounded, `#2B3040` with ink outline; the filled part in the activity colour; knob 44 px circle, warm white with ink outline and the activity colour inside (a 20 px dot). Range 5 to 240 minutes. |
| **Option buttons** | 552 x 72 each, gap 12 | Activity colour, inline, icon 48 px on the left. Exercise: **Cardio** (running shoe), **Squats** (squatting figure), **Push-ups** (push-up figure), **Sit-ups** (sit-up figure). Entertainment: **Screens** (tablet with play sign), **Football** (ball). |
| **Cancel** | 552 x 64 | **stop** red, X icon + "Cancel" / "Cancelar". |

### 6.3 Sleep panel

Centred panel 600 x 340.

| Element | Size | Look |
|---|---|---|
| Header band | 600 x 64 | Indigo, moon icon, "How many hours of sleep?" (28 px, white). |
| Sleep slider | 552 x 48 | Like the minutes slider, filled part indigo. |
| Info text | 2 lines, 20 px | "8 h of sleep · At most 11 h now." |
| **Cancel** | 268 x 64 | **stop** red, X icon. |
| **Sleep** (confirm) | 268 x 64 | **Proposal: indigo** with the moon icon, so everything about sleep has one colour; or **go** green like every other confirm (question 3 in section 14). |

### 6.4 Canteen (the Eat button opens it)

A panel over the whole screen: 696 x 1232 at 12, 24. Padding 14. Gap 8.

| Element | Size | Look |
|---|---|---|
| Header band | 668 x 64 | **eat** yellow, fork-and-knife icon, "Canteen" / "Cantina" (32 px, ink). |
| "Healthy food" title | text, 24 px | Healthy green `#4DB85F` with the apple icon (`diet`, 24 px). |
| Healthy food grid | 5 columns x 2 rows of food tiles | Each **food tile** 118 x 128: a **food picture 76 x 76** in a rounded frame (radius 18, 3 px outline in **healthy green**) and the food's name under it (16 px, two lines at most). Tiles are flat (no lip), they lift by 2 px when pressed. |
| "Bad food" title | text, 24 px | Orange `#F08C3C`, no icon (no warning sign: the choice is taught, not punished). |
| Bad food grid | 5 x 2 food tiles | The same tile, the frame in **orange**. |
| "Your plate (2 of 4)" | text, 24 px | |
| Hint | 18 px | "Tap a food to add it. Tap it on the plate to take it off." |
| **Plate** | a round plate picture about 360 x 140 seen from slightly above, with **4 places** | Each place 76 x 76: empty = a dashed white circle (40% white); full = the food picture. **Proposal:** draw the plate as one picture (section 10.3); today the places are four empty squares. |
| **Eat the plate** | 668 x 72 | **go** green, fork icon + "Eat the plate" / "Comer o prato". Disabled while the plate is empty. |
| **Skip meal** | 328 x 64 | **eat** yellow, skip-meal icon. Only when the avatar is hungry. |
| **Cancel** | 328 x 64 | **stop** red, X icon. |

When the plate is full, the food tiles fade to 40%.

### 6.5 The minigame panel (replaces the four buttons during a minigame)

The panel is 672 wide and 256 tall at the bottom (24, 992). Rows:

| Row | Size | Look |
|---|---|---|
| Status row | 672 x 40 | Left: status text (22 px), e.g. "Running", "Resting", "Set 2 of 3". Right: counter (22 px), e.g. "Steps: 40 / 120". In football a **Help** button "?" (**Proposal: 56 x 56**, now 44 x 40, too small; neutral). |
| Reserve bar | label + bar 28 px tall | Label with icon: **Breath** (wind icon) for cardio and football, **Muscle** (flexed arm) for strength. Bar: grey fill. |
| Beat bar | 672 x 36 | Track `#1C2130`; a **green zone** `#4DB37A` (when to tap); a white marker 8 px wide that runs along it; the marker turns `#F28066` after a tap off the beat. In the meal it is the **Tummy bar**: fill orange, green zone from 6 of 10 bites. |
| Controls | 672 x 120 | One of the four below. |

**Cardio:** one **Tap to run** button 672 x 120, **exercise** orange, stacked: a footprint or
running-shoe icon (56 px) + "Tap to run" / "Toca para correr". On a computer the word adds
"(Space)".

**Strength (squats, push-ups, sit-ups):** **Down** and **Up**, each 328 x 120, **exercise**
orange, a big arrow icon (56 px, down or up) + the word. Only the expected one can be pressed
(the other is disabled grey).

**Meal:** **Bite!** 328 x 120, **eat** yellow, fork-with-food icon. **Done** / "Já chega"
328 x 120, **go** green, check icon (the avatar is full).

**Football** (the controls are 672 x 170):

| Element | Size | Look |
|---|---|---|
| Joystick base (phones and tablets) | a circle 170 px (on the left 302 px) | Charcoal `#1C2130` at 90%, 3 px ink outline, four small arrow hints inside at the edges. |
| Joystick knob | a circle 68 px | Warm white with an ink outline and a soft top highlight; moves inside the base. |
| Keys list (computer, instead of the joystick) | text | "Move: arrows or WASD ..." (20 px). |
| **Pass** / **Ask for ball** | 362 x 81, top right | **team** blue, inline: pass icon (two arrows) or raised-hand icon, + "Pass (Z)". |
| **Shoot** / **Tackle** | 362 x 81, bottom right | **exercise** orange (**not red**, red means stop), inline: shoot icon (ball with speed lines) or tackle icon (boot). |
| Disabled | | grey, as all disabled buttons. |

The football field itself (the stage) is drawn by the game (players as blue and red dots, the
ball, the goals). Its art is optional (section 11).

### 6.6 Football help (opens the first time)

A dim over the screen, a panel 640 wide. Title "Football" (32 px). Rows 72 px tall: a picture
64 x 64 on the left (joystick, pass, shoot, tackle, ask, breath icons), text on the right
(22 px). The keys in yellow `#FFD94D`. A **Play** button 592 x 76, **go** green, play icon.

### 6.7 Settings (the gear button)

Dim at 50% over the screen, panel 600 x 420 centred.

| Element | Size | Colour role | Content |
|---|---|---|---|
| Header band | 600 x 64 | neutral, gear icon | "Settings" / "Definições" (32 px). |
| "Language" label | text, globe icon | | |
| **Português** / **English** | 268 x 72 each | neutral; the chosen one in the **selected** state | The words only (the game writes them). No flags (a flag is a country, not a language). |
| **Start a new avatar** | 552 x 72 | neutral, plus-person icon | Opens the warning. |
| Warning (after the first press) | text, 22 px | warning icon in red | "This avatar will be lost. This cannot be undone." |
| **Cancel** | 268 x 72 | **stop** red, X | |
| **Yes, start again** | 268 x 72 | **danger** dark red, warning icon | |
| **Main menu** | 552 x 64 | neutral, house icon | |
| **Close** | 552 x 64 | neutral, X icon | **Proposal:** Close is neutral, not red: it only closes the panel. (Section 14.) |

### 6.8 Failure screen

Dim at 60%, panel 620 wide, centred.

| Element | Look |
|---|---|
| Header band 620 x 72 | **danger red** `#D93A2F`, "Failure" / "Falha" (40 px, white). |
| Avatar picture 165 x 225 | Existing art. |
| Phrase | "Ana lost too much weight." (30 px, bold). |
| End text | "The game ends here. You can start again with a new avatar." (22 px). |
| **Details** / **Hide details** | 278 x 72, neutral, magnifier icon. |
| **Start a new avatar** | 278 x 72, **go** green, plus-person icon. |
| Details (scrolls, 556 wide, 560 tall) | Section titles (24 px). **Tiles** in rows of three, each about 176 x 96, like the level boxes (panel colour, radius 18, outline), an icon 28 px, a big value (30 px) and a caption (16 px): days lived (calendar), level (star), highest health (heart with up arrow), weight (scale), BMI-for-age z (gauge), last health (heart). **Measure rows**: name + bar 30 px (Physical orange, Happiness magenta, Sleep indigo) + a verdict word ("too low", "could be better", "good"). **Habit gauges**: a bar 30 px tall with the recommended zone in green at 60%, a round white marker 22 px with an ink outline for the avatar's value; icons sleep, exercise, screens, meals; the meals gauge is a green and orange split bar. |

### 6.9 Main menu (the first screen)

720 x 1280: sky over the top, grey ground from y = 700, the last avatar standing on it.

| Element | Position, size | Colour role | Content |
|---|---|---|---|
| Title | centred, y = 70, 52 px | white with a 10 px ink outline | "Plasticine Tamagotchi". **Proposal:** a title logo picture 600 x 140 (section 10.4), in the same style, no other words. |
| Subtitle | y = 150, 24 px | white | "Sport, sleep and food: keep your avatar healthy". |
| **Continue** | 60, 810, 600 x 96 | **go** green, play icon | Two lines: "Continue" (28 px) and "Ana · level 3 · health 3.2 · 4.5 days" (18 px). Only when there is an avatar. |
| **New avatar** | 600 x 76 when Continue is shown: left half 293 x 76 | neutral, plus-person icon | **Proposal (first visit):** when there is no avatar yet, Continue is hidden and **New avatar becomes the big green 600 x 96 button** in its place, with the words "New avatar" and "Start playing" under it, so a new player sees one obvious button. |
| **Avatars** | 293 x 76 | neutral, people icon | |
| **Load a backup** | 293 x 76 | neutral, upload icon | |
| **About** | 293 x 76 | neutral, "i" icon | |
| **Português** / **English** | 293 x 64 each | neutral, chosen one selected | |

Gaps 14 px. The buttons sit from y = 810 down (the area ends at 1240).

**Avatars page** (a dim and a panel 640 wide, title "Avatars" 32 px): three **avatar cards**
(each 592 x 140: a panel with the avatar picture 88 x 120 on the left, a line of text, and buttons
56 px tall):

| Card state | Buttons |
|---|---|
| Empty place | **New avatar** (go green, plus-person). Text "Empty place" in grey. |
| An avatar | **Play** (go green, play icon), **Backup** (neutral, download icon), **Delete** (**Proposal:** neutral with a red trash icon, because the real delete comes after a second press; question 4 in section 14). |
| Asking to delete | Text "Delete Ana for good? This cannot be undone." **Cancel** (stop red, X) and **Yes, delete** (danger dark red, warning icon). |
| A failed avatar | Its text in `#FF8073`; the same buttons. |

Under the cards a message line (20 px) and **Back** 592 x 64, neutral, back arrow.

**About page:** the same panel, a scrolling text (20 px, 560 wide, 760 tall) and **Back**.

### 6.10 Avatar creation (NEW layout, Proposal)

Goal (user): making an avatar should feel **almost automatic, fast and easy to understand** for
someone who opens the game for the first time. Today it is a form with seven groups of plain
buttons (name, age, sex, four difficulties, start). The new layout keeps the same choices (the
game needs name, age group, sex and difficulty) but:

- **one tap chooses age group and sex together**, by tapping a picture of the avatar;
- the **difficulty is already set to Normal** (marked "Recommended");
- the **name can be suggested** by a dice button (**Proposal**: needs a list of names in
  `data/`), or typed;
- numbered steps (1, 2, 3) turn into green ticks as they are done, so the player sees what is
  left;
- one big green **Start** at the bottom.

So a new player can do: tap a picture → tap the dice → Start. Three taps.

Layout, 720 x 1280, background sky (or a soft warm `#F3EDE2` card colour), margins 24:

```
 y=24   [< Back 64x56]                          [ PT | EN ] 160x56
 y=96              Create your avatar   (40 px, centred)
 y=160  (1) Who is your avatar?                  (24 px, step badge)
 y=200  [card][card][card][card]   4 cards 156x236, gap 16
 y=452  (2) Name
 y=492  [ name field 584x72              ][dice 72x72]
 y=580  (3) How hard?
 y=620  [Easy][Normal*][Hard][Very hard]   4 cards 156x132, gap 16
 y=768  [ difficulty text box 672x120, 20 px, 3 to 4 lines         ]
 y=1144 [ ▶ Start                                     672x96 green ]
```

| Element | Size | Look |
|---|---|---|
| **Back** | 64 x 56 | neutral, back-arrow icon only (tooltip "Back"). |
| **Language toggle** | 160 x 56, two halves of 80 | One neutral pill split in two, "PT" and "EN"; the chosen half is filled ink with white letters. |
| **Step badge** | circle 36 px | Not done: ink outline, the number in ink (20 px), warm white inside. Done: green `#2E9E4A` with a white check. Blank in the art; the game writes the number. |
| **Avatar cards** (step 1) | 4 cards, each 156 x 236 | A panel card (warm white, radius 18, outline, lip like a button so it looks pressable). Inside: the avatar's healthy happy picture 140 x 170 (existing art) on a soft circle of light sky colour, then two lines of text (18 px bold) written by the game: the age group with its ages ("Child 6–12" / "Criança 6–12", "Teenager 13–18" / "Adolescente 13–18") and the sex ("Female" or "Male" / "Feminino" or "Masculino"). Order: child female, child male, teenager female, teenager male. **Selected:** green ring + check badge (section 5.2). |
| **Name field** | 584 x 72 | White `#FFFFFF`, radius 18, 3 px ink outline, no lip (a field, not a button). Hint text in grey `#8A8F99` (24 px): "Type a name" or, on phones, "Tap to type a name". A pencil icon 28 px inside at the right. **Focused:** outline green 4 px. |
| **Dice** (suggest a name) | 72 x 72 | neutral button, a dice icon (48 px). **Proposal.** |
| **Difficulty cards** (step 3) | 4 cards, 156 x 132 | Neutral cards with lip. Inside: a **hill icon** (48 px) that is steeper for each level (four different icons), the name (20 px bold: Easy, Normal, Hard, Very hard / Fácil, Normal, Difícil, Muito difícil) and **1 to 4 small filled dots** (10 px) under it. **Normal** has a small green **"Recommended"** ribbon (blank in the art, 100 x 26) over its top edge and starts selected. |
| **Difficulty text** | 672 x 120 | A light panel (no lip) with the description of the chosen difficulty (20 px). |
| **Start** | 672 x 96 | **go** green, play icon (40 px) + "Start" / "Começar" (32 px). Disabled grey until an avatar card is chosen and the name is not empty. |

The old "Child (6 to 12 years)", "Male" and "Female" buttons are replaced by the four cards. The
creation choices and what is saved do not change.

---

## 7. Things that are not buttons

### 7.1 Bars

Same shape for every bar: rounded rectangle, radius = half the height (a pill), **3 px ink
outline**, the empty part `#2B3040`, the fill a pill inside the outline (2 px gap), with a
lighter top band (15% lighter, a third of the height) for the tactile feel. Text on bars is white
with a 4 px ink outline.

| Bar | Size (1x) | Fill |
|---|---|---|
| Health | 220 x 40 | health green `#2E9E4A`; danger `#D93A2F` |
| XP | 248 x 40 | gold `#F2B705` |
| Physical | 268 x 30 | exercise orange `#F28A1E` |
| Happiness | 268 x 30 | fun magenta `#B33E8E` |
| Sleep amount | 268 x 30 | sleep indigo `#4C56CF` |
| Breath, Muscle (minigames) | about 560 x 28 | light grey `#B8BCC6`; the game can make it orange when low |
| Beat and Tummy bar | 672 x 36 | a track with a green zone and a marker (section 6.5) |
| Failure measure bars and habit gauges | about 300 x 30 | as above, with a green zone at 60% and a round marker 22 px |

Deliver the bars as **separate track and fill pieces** (sheet B, section 12) so the game can
fill them from 0 to 100%.

### 7.2 Panels and cards

- **Panel:** warm white `#FFF8EC` (day) or charcoal `#262A35` (night), radius 24, 3 px ink outline,
  a hard shadow 6 px straight down in black at 25% (no blur). Used for: measures, values, options,
  sleep, settings, canteen, failure, menu pages, avatar cards, football help.
- **Header band:** the top 64 px of a panel in the role colour, the same outline, top corners
  round, bottom edge straight. Drawn by the game in the role colour; no picture needed.
- **Card** (avatar cards, difficulty cards, failure tiles): a panel that is smaller, radius 18;
  pressable cards get the button lip.
- **Dim:** black at 50 to 60% behind panels that cover the screen. Done by the game.

### 7.3 Speech bubble

White bubble, radius 22, 3 px ink outline, a tail 32 x 20 (separate piece) pointing down at the
centre, merged with the bubble's outline (no line between them). Text ink, 22 px.

### 7.4 Sliders

Track 16 px tall pill (outline, empty `#2B3040`), filled part in the activity colour, knob a
44 px circle: warm white, ink outline, a 20 px coloured dot in the middle (the game tints the dot),
a 4 px lip at its bottom.

### 7.5 Text field

White, radius 18, 3 px ink outline, no lip, the inner part 2 px lower than the outline (a slight
inset, the opposite of a button). Focus: 4 px green outline.

### 7.6 Small marks

| Mark | Size (1x) | Look |
|---|---|---|
| Selected ring | fits any button | A 4 px green ring inside the outline, the same radius. |
| Check badge | 28 px circle | Green, white check, ink outline. Top-right corner of selected cards. |
| Recommended ribbon | 100 x 26 | A green rounded tag, white space for the word. |
| Step badge | 36 px circle | Two versions: empty (warm white with ink outline) and done (green with a white check). |
| Clock pill | 88 x 40 | A neutral panel pill (day and night). |
| Scroll bar | 8 px wide | Grabber a pill in `#8A8F99`, no track. |

---

## 8. Size table of every button (quick reference)

| Screen | Button | Size (1x) | Role | Icon |
|---|---|---|---|---|
| Main | Health level box | 88 x 88 | go / stop | heart |
| Main | Health bar (flat) | 220 x 40 | bar | none |
| Main | Pause | 88 x 64 | neutral | pause / play |
| Main | Settings | 88 x 64 | neutral | gear |
| Main | Wake | 88 x 56 | wake | sunrise |
| Main | Stop | 672 x 64 | stop | stop square |
| Main | Exercise | 328 x 120 | exercise | runner |
| Main | Sleep | 328 x 120 | sleep | moon z |
| Main | Eat | 328 x 120 | eat | fork and knife |
| Main | Entertainment | 328 x 120 | fun | TV and ball |
| Main | Physical bar (flat) | 268 x 30 | bar | body |
| Options | Cardio, Squats, Push-ups, Sit-ups | 552 x 72 | exercise | each its own |
| Options | Screens, Football | 552 x 72 | fun | tablet, ball |
| Options | Cancel | 552 x 64 | stop | X |
| Sleep | Cancel | 268 x 64 | stop | X |
| Sleep | Sleep | 268 x 64 | sleep (or go) | moon |
| Canteen | Food tile (x 20) | 118 x 128 | flat tile | food picture |
| Canteen | Plate place (x 4) | 76 x 76 | flat | food or empty |
| Canteen | Eat the plate | 668 x 72 | go | fork |
| Canteen | Skip meal | 328 x 64 | eat | skip meal |
| Canteen | Cancel | 328 x 64 | stop | X |
| Cardio | Tap to run | 672 x 120 | exercise | footprint |
| Strength | Down, Up | 328 x 120 | exercise | arrows |
| Meal | Bite! | 328 x 120 | eat | fork with food |
| Meal | Done | 328 x 120 | go | check |
| Football | Pass / Ask for ball | 362 x 81 | team | pass / hand |
| Football | Shoot / Tackle | 362 x 81 | exercise | shoot / boot |
| Football | Help "?" | 56 x 56 | neutral | question mark |
| Football help | Play | 592 x 76 | go | play |
| Settings | Português, English | 268 x 72 | neutral (selected) | none |
| Settings | Start a new avatar | 552 x 72 | neutral | plus-person |
| Settings | Cancel | 268 x 72 | stop | X |
| Settings | Yes, start again | 268 x 72 | danger | warning |
| Settings | Main menu | 552 x 64 | neutral | house |
| Settings | Close | 552 x 64 | neutral | X |
| Failure | Details / Hide details | 278 x 72 | neutral | magnifier |
| Failure | Start a new avatar | 278 x 72 | go | plus-person |
| Menu | Continue | 600 x 96 | go | play |
| Menu | New avatar | 293 x 76 (600 x 96 on first visit) | neutral (go on first visit) | plus-person |
| Menu | Avatars | 293 x 76 | neutral | people |
| Menu | Load a backup | 293 x 76 | neutral | upload |
| Menu | About | 293 x 76 | neutral | info |
| Menu | Português, English | 293 x 64 | neutral (selected) | none |
| Avatars | New avatar | 56 tall | go | plus-person |
| Avatars | Play | 56 tall | go | play |
| Avatars | Backup | 56 tall | neutral | download |
| Avatars | Delete | 56 tall | neutral, red icon | trash |
| Avatars | Cancel | 56 tall | stop | X |
| Avatars | Yes, delete | 56 tall | danger | warning |
| Avatars, About | Back | 592 x 64 | neutral | back arrow |
| Creation | Back | 64 x 56 | neutral | back arrow |
| Creation | PT / EN | 160 x 56 | neutral toggle | none |
| Creation | Avatar card (x 4) | 156 x 236 | card | existing avatar art |
| Creation | Dice | 72 x 72 | neutral | dice |
| Creation | Difficulty card (x 4) | 156 x 132 | card | hill 1 to 4 |
| Creation | Start | 672 x 96 | go | play |

---

## 9. Icons (glyphs)

### 9.1 How to draw them

- **Pure white `#FFFFFF` shapes on a transparent background**, one solid colour, no outline,
  no shading. The game colours them (white on dark buttons, ink on light buttons, red for the
  delete icon, and so on). This lets one icon work on every button.
- Drawn in a **256 x 256 cell**, the icon inside a **200 x 200** area in the middle (28 px empty
  around it).
- Strokes **20 px** thick at this size (about 8% of the cell), round ends and round joins.
  Filled shapes where possible. Corners rounded.
- No detail smaller than 12 px, so the icon still reads at 24 px in the game.
- Figures (people) are simple: a round head and a body of thick rounded strokes, **no face, no
  body size** (neither thin nor fat), no clothes.

### 9.2 The list (sheets G1 to G4, cell = row, column, counted from 1)

**Sheet G1, activities and actions**

| Cell | Id | Drawing | Used on |
|---|---|---|---|
| 1,1 | `exercise` | A person running, mid-stride, leaning forward, side view. | Exercise button, failure habit "Exercise and football". |
| 1,2 | `sleep` | A crescent moon opening to the right, with two small "z" shapes top right (drawn as shapes, not letters of a font). | Sleep button, sleep panel, Sleep amount, failure habit. |
| 1,3 | `eat` | A fork and a knife standing side by side, vertical. | Eat button, canteen header, meals habit. |
| 1,4 | `entertainment` | A small TV screen with a football in front of its lower-right corner. | Entertainment button. |
| 2,1 | `cardio` | A running shoe with three speed lines behind it. | Cardio option. |
| 2,2 | `squats` | A person in a squat, side view, arms straight forward. | Squats option. |
| 2,3 | `push_ups` | A person in a push-up, side view, straight body, arms down. | Push-ups option. |
| 2,4 | `sit_ups` | A person sitting up with knees bent, side view, hands behind the head. | Sit-ups option. |
| 3,1 | `screens` | A tablet in landscape with a "play" triangle in the middle. | Screens option, failure habit "Screens". |
| 3,2 | `football` | A football (simple pentagon pattern). | Football option. |
| 3,3 | `skip_meal` | An empty plate seen from above with a curved arrow jumping over it. | Skip meal. |
| 3,4 | `stop` | A rounded square. | Stop. |
| 4,1 | `cancel` | A bold X with round ends. | Cancel, Close. |
| 4,2 | `confirm` | A bold check mark. | Done, check badge, step done. |
| 4,3 | `back` | An arrow pointing left. | Back. |
| 4,4 | `play` | A triangle pointing right with rounded corners. | Continue, Play, Start, resume. |

**Sheet G2, system**

| Cell | Id | Drawing | Used on |
|---|---|---|---|
| 1,1 | `pause` | Two vertical rounded bars. | Pause. |
| 1,2 | `settings` | A gear with 8 teeth and a round hole. | Settings. |
| 1,3 | `wake` | A half sun rising over a horizontal line, with five short rays. | Wake. |
| 1,4 | `help` | A question mark. | Help. |
| 2,1 | `info` | A lowercase "i" in a circle (drawn as shapes). | About. |
| 2,2 | `home` | A house with a pointed roof and a door. | Main menu. |
| 2,3 | `new_avatar` | A person (head and shoulders) with a "+" at the lower right. | New avatar, Start a new avatar. |
| 2,4 | `avatars` | Three persons (head and shoulders), one in front, two behind. | Avatars. |
| 3,1 | `upload` | An arrow pointing up out of an open tray. | Load a backup. |
| 3,2 | `download` | An arrow pointing down into an open tray. | Backup. |
| 3,3 | `trash` | A bin with a lid and three vertical lines. | Delete. |
| 3,4 | `warning` | A rounded triangle with an exclamation mark cut out. | Yes delete, Yes start again, the warning text. |
| 4,1 | `details` | A magnifying glass. | Details. |
| 4,2 | `language` | A globe with two meridians and the equator. | Language label. |
| 4,3 | `dice` | A dice seen at an angle, showing three faces with dots. | Suggest a name (Proposal). |
| 4,4 | `pencil` | A pencil at 45 degrees. | Name field. |

**Sheet G3, measures**

| Cell | Id | Drawing | Used on |
|---|---|---|---|
| 1,1 | `health` | A heart. | Health box, failure tiles. |
| 1,2 | `xp` | A five-pointed star with rounded points. | XP bar, XP level box, level tile. |
| 1,3 | `physical` | A person standing, arms slightly open, front view (calm, neutral body). | Physical bar. |
| 1,4 | `happiness` | A circle face with a smile and two dot eyes (cut out). | Happiness bar. |
| 2,1 | `calories` | A flame. | Calories spent. |
| 2,2 | `strength` | A dumbbell, horizontal. | Strength. |
| 2,3 | `fitness` | A pair of lungs. | Fitness. |
| 2,4 | `weight` | A bathroom scale seen from the front, with a dial. | Weight, weight tile. |
| 3,1 | `height` | A vertical ruler with an arrow at the top and bottom. | Height. |
| 3,2 | `bmi` | A half-circle gauge with a needle. | BMI-for-age z, z tile. |
| 3,3 | `diet` | An apple with a leaf. | Diet quality. |
| 3,4 | `clock` | A clock face with two hands. | Clock. |
| 4,1 | `sun` | A sun with eight rays. | Clock (day). |
| 4,2 | `moon` | A crescent moon alone (no z). | Clock (night). |
| 4,3 | `calendar` | A calendar page with two rings at the top and a grid. | Days lived tile. |
| 4,4 | `health_up` | A heart with a small arrow pointing up at the lower right. | Highest health tile. |

**Sheet G4, minigames and creation**

| Cell | Id | Drawing | Used on |
|---|---|---|---|
| 1,1 | `tap_run` | A footprint (sole of a shoe). | Tap to run. |
| 1,2 | `arrow_down` | A thick arrow pointing down. | Down. |
| 1,3 | `arrow_up` | A thick arrow pointing up. | Up. |
| 1,4 | `bite` | A fork, tilted, with a round piece of food on it. | Bite! |
| 2,1 | `pass` | A ball with a curved arrow going to the right. | Pass. |
| 2,2 | `shoot` | A ball with three speed lines flying into a small goal net. | Shoot. |
| 2,3 | `tackle` | A football boot, side view, sliding forward. | Tackle. |
| 2,4 | `ask_ball` | A raised open hand. | Ask for ball. |
| 3,1 | `breath` | Three curved wind lines. | Breath bar. |
| 3,2 | `muscle` | A flexed arm. | Muscle bar. |
| 3,3 | `tummy` | A bowl with steam lines. | Tummy bar. |
| 3,4 | `joystick` | A joystick: a round base with a stick and a ball on top. | Football help. |
| 4,1 | `difficulty_1` | A very gentle hill (almost flat). | Easy. |
| 4,2 | `difficulty_2` | A gentle hill. | Normal. |
| 4,3 | `difficulty_3` | A steep hill. | Hard. |
| 4,4 | `difficulty_4` | A sharp mountain peak. | Very hard. |

---

## 10. Pictures in colour (not tinted)

These are **full-colour pictures**, in the same style (flat colour, ink outline 8 px at the
256 cell, soft top highlight, a faint matte clay feel allowed), on a transparent background.

### 10.1 Request pictures in the speech bubble (sheet P, row 1 and 2)

Shown at 60 x 60 in the bubble. Drawn in 256 cells.

| Cell | Id | Picture |
|---|---|---|
| 1,1 | `request_tired` | A small bed with a blue blanket and "z z" above it. |
| 1,2 | `request_fast_food` | A generic burger (bun, lettuce, meat). No brand. |
| 1,3 | `request_healthy` | A red apple with a green leaf. |
| 1,4 | `request_hungry` | An empty plate with a fork and knife beside it. |
| 2,1 | `request_screens` | A tablet with a bright blue screen. |
| 2,2 | `request_football` | A football in black and white. |
| 2,3 | `request_sad` | A small grey rain cloud with one drop (for "I'm sad."; Proposal). |
| 2,4 | `request_hello` | A waving hand (for "Hello!"; Proposal). |

### 10.2 Food pictures for the canteen (sheet F, 1536 x 1024, 6 columns x 4 rows of 256)

Each food alone, seen from the front or slightly above, centred, filling about 200 x 200 of
the cell. Generic, appetising, realistic colours, **no brands**. Healthy and less healthy foods
must both look tasty: the game teaches the choice, it does not make bad food look disgusting.

| Cell | Id | Food | Healthy |
|---|---|---|---|
| 1,1 | `vegetable_soup` | A bowl of green and orange vegetable soup | yes |
| 1,2 | `grilled_fish` | A grilled fish fillet with a lemon slice | yes |
| 1,3 | `salad` | A bowl of green salad with tomato | yes |
| 1,4 | `apple` | A red apple | yes |
| 1,5 | `orange` | An orange with one leaf | yes |
| 1,6 | `rice` | A bowl of white rice | yes |
| 2,1 | `beans` | A bowl of red beans | yes |
| 2,2 | `yoghurt` | A plain yoghurt in a pot with a spoon | yes |
| 2,3 | `water` | A glass of water | yes |
| 2,4 | `wholemeal_bread` | Two slices of brown wholemeal bread | yes |
| 2,5 | `burger` | A burger | no |
| 2,6 | `fries` | Fries in a red-and-white paper cone (no logo) | no |
| 3,1 | `pizza` | A slice of pizza | no |
| 3,2 | `hot_dog` | A hot dog with mustard | no |
| 3,3 | `soft_drink` | A cup or can of a dark fizzy drink with a straw, no logo | no |
| 3,4 | `crisps` | An open bag of crisps, no logo | no |
| 3,5 | `sweets` | A handful of coloured jelly sweets | no |
| 3,6 | `fried_chicken` | Two pieces of fried chicken | no |
| 4,1 | `doughnut` | A pink-iced doughnut with sprinkles | no |
| 4,2 | `milkshake` | A tall milkshake with cream | no |
| 4,3 to 4,6 | (empty) | Leave empty (for foods the team adds later). | |

The food list is Claude's placeholder until the team sends its examples (`data/canteen.json`).

### 10.3 Plate (sheet P, row 3)

| Cell | Id | Picture |
|---|---|---|
| 3,1 to 3,4 (one wide picture, 1024 x 256) | `plate` | A round white plate seen from slightly above, with a light rim, empty. It will hold 4 foods side by side. |

### 10.4 Title logo (optional, sheet P, row 4)

| Cell | Id | Picture |
|---|---|---|
| 4,1 to 4,4 (1024 x 256) | `title_logo` | The words "Plasticine Tamagotchi" as a chunky rounded logo in warm white with an ink outline and a coloured lip (green, orange, indigo, magenta letters or shadow, matching the four activities). This is the **only** asset with words in it, because the name is the same in both languages. |

---

## 11. Backgrounds (second priority, after the buttons)

Full screen, **1440 x 2560** (2x of 720 x 1280), no UI drawn on them. The game puts buttons,
bars and the avatar on top, so the top 240 px (2x) and the bottom 900 px (2x) must be calm
(no strong details). **The ground line is at y = 1672 (2x)** (836 at 1x): the avatar's feet stand
on it in the middle (x = 720 at 2x); nothing may stand in the middle 700 px of width from y = 760
to 1672 (2x), where the avatar is.

| Id | Picture | Now in the game |
|---|---|---|
| `sky_day` | A calm blue sky with two or three soft clouds, light at the bottom. | Plain blue. |
| `sky_night` | A dark blue night sky with small stars and a moon at the top left. | Plain dark blue. |
| `ground` | A strip of grey pavement or floor, from the ground line to the bottom. | Plain grey. |
| `room` (meals) | A room wall with two windows that show the sky (the sky behind the windows is transparent, so the game's day or night sky shows through). A table edge is allowed below the ground line. | Placeholder shapes. |
| `outside` (squats, push-ups, sit-ups) | Only sky and ground (a park lawn or school yard at the horizon). | Placeholder shapes. |
| `street` (cardio) | A street with trees on both sides, in perspective towards the middle, seen from behind the avatar. Deliver also a **tree** sprite (512 x 1024, transparent) that the game moves to make the street scroll. | Placeholder shapes. |
| `bedroom` (sleep) | A grey floor filling the screen and a bed **seen from above**, the pillow at the top; a separate **blanket** piece (transparent) that covers the avatar from the chest down. | Placeholder shapes. |
| `football_field` | A football pitch seen from above, the avatar's team attacks upwards; green with white lines, a goal at the top and at the bottom. The players are drawn by the game. | Plain green. |
| `menu` | The main menu: sky over the top 700 px (1x), ground below. | Sky and grey ground. |

---

## 12. What to deliver (the files) and the prompts

### 12.1 Sheets

All sheets: **PNG with a transparent background**. If the generator cannot make transparency,
use a **flat pure magenta `#FF00FF`** background (no shadows on it), so the background can be
removed by a script, as with the avatar sheets (`tools/cut_avatar_sheets.py`).

Every item sits **centred in its own cell**, never crosses its cell, and has the empty padding
given. No grid lines, no labels, no numbers in the picture.

| Sheet | File name | Size | Grid | Content |
|---|---|---|---|---|
| **S1** button skins 1 | `ui_skins_1.png` | 1024 x 1024 | 4 x 4 of 256 | Row 1: go normal, go pressed, stop normal, stop pressed. Row 2: danger normal, danger pressed, neutral-day normal, neutral-day pressed. Row 3: neutral-night normal, neutral-night pressed, disabled, wake normal. Row 4: wake pressed, team normal, team pressed, gold normal. |
| **S2** button skins 2 | `ui_skins_2.png` | 1024 x 1024 | 4 x 4 of 256 | Row 1: exercise normal, exercise pressed, sleep normal, sleep pressed. Row 2: eat normal, eat pressed, fun normal, fun pressed. Row 3: gold pressed, joystick base (a 224 px circle), joystick knob (a 112 px circle), clock pill (224 x 100). Row 4: card day (no lip), card night (no lip), card day with lip, card night with lip. |
| **B** bars | `ui_bars.png` | 1024 x 1024 | 8 rows of 1024 x 128 | Each a pill 960 x 80 centred: 1 empty track; fills 2 green, 3 red, 4 gold, 5 orange, 6 magenta, 7 indigo, 8 light grey. Fills have no outline (they sit inside the track). |
| **K** panels and marks | `ui_panels.png` | 1024 x 1024 | 4 x 4 of 256 | Row 1: panel day, panel night, speech bubble (224 x 160), speech tail (64 x 40, bottom-centre of its cell). Row 2: text field, text field focused, slider track, slider knob (88 px circle). Row 3: food frame healthy (152 x 152, empty inside), food frame less healthy, plate place empty (dashed circle 152 px), selected ring (224 x 224, only the ring). Row 4: check badge (56 px circle), recommended ribbon (200 x 52), step badge empty (72 px), step badge done (72 px). |
| **G1 to G4** glyph icons | `ui_icons_1.png` to `ui_icons_4.png` | 1024 x 1024 each | 4 x 4 of 256 | Section 9.2. White on transparent. |
| **P** colour pictures | `ui_pictures.png` | 1024 x 1024 | 4 x 4 of 256 | Section 10.1, 10.3, 10.4. |
| **F** food | `ui_food.png` | 1536 x 1024 | 6 x 4 of 256 | Section 10.2. |
| **BG** backgrounds | `bg_<id>.png` | 1440 x 2560 each (or 1024 x 1536 with a 864 x 1536 area, see 13) | one per file | Section 11. |

Skins S1 and S2: the shape fills x 16 to 240 and y 16 to 240 of its cell exactly, corner radius 36,
outline 6, lip 12 (normal) or none with the face 8 px lower (pressed). The same corners on every
skin, only the colours change.

After cutting, the files go to `assets/art/ui/` (skins, bars, panels, icons, pictures, food)
and `assets/art/ui/backgrounds/`.

### 12.2 Master prompt (add it to every request)

> Game interface art for "Plasticine Tamagotchi", a free educational web game for children and
> teenagers (9 to 16) about healthy habits: sport, sleep and food. Style: minimal tactile. Flat
> colour shapes with large rounded corners, a dark ink outline (#1B1F2A) on everything, and a
> solid darker "lip" along the bottom of each button so it looks like a thick physical key; a very
> soft lighter band along the top inside edge; light from the top. Clean, friendly, calm, not
> childish, not glossy, no gradients, no 3D render, no texture on buttons, no blurred shadows, no
> brands or logos, no text or letters anywhere. Exact colours: green #2E9E4A, red #D93A2F, dark
> red #9E1F17, orange #F28A1E, indigo #4C56CF, yellow #F6C343, magenta #B33E8E, sky blue #5BBDF5,
> blue #2F6FE0, gold #F2B705, warm white #FFF8EC, charcoal #2E3340, disabled grey #C9CCD3. Each
> item is centred in its own cell of an invisible grid, with empty space around it, on a
> transparent background.

### 12.3 Prompts per sheet (add after the master prompt)

- **S1:** "A 1024 x 1024 sprite sheet, a 4 by 4 grid of 256-pixel cells. In each cell one blank
  rounded-rectangle button, 224 by 224 pixels, corner radius 36, outline 6 pixels, no text, no icon.
  Normal buttons have a 12-pixel darker lip at the bottom; pressed buttons have no lip and sit
  8 pixels lower. Cells in order, left to right, top to bottom: [list of S1 from 12.1 with the
  face and lip hex codes from section 3.1]."
- **S2, B, K:** the same, with their list.
- **G1 to G4:** "A 1024 x 1024 sheet, 4 by 4 grid of 256-pixel cells. In each cell one simple icon,
  pure white, solid, no outline, no shading, on a transparent background, inside a 200-pixel
  square, thick 20-pixel rounded strokes, round line ends, recognisable at 24 pixels. Figures of
  people have no face and a neutral body. Icons in order: [the 16 drawings of the sheet]."
- **P and F:** "Full-colour flat pictures with an 8-pixel ink outline, a faint matte clay feel,
  appetising and generic, no brands: [list]."
- **Backgrounds:** "A 1440 x 2560 portrait game background, no interface, no characters: [the
  picture]. The ground line is at 1672 pixels from the top; keep the middle 700 pixels of width
  empty from 760 to 1672 pixels; keep the top 240 and the bottom 900 pixels calm."

### 12.4 Checklist for each result

- [ ] Right size and grid; every item inside its cell, nothing touching a cell edge.
- [ ] Transparent (or flat magenta) background, no shadow on it.
- [ ] **No text, letters or numbers** (except the title logo).
- [ ] Colours match the hex codes (check with a colour picker; small differences can be fixed
      by a script).
- [ ] The same outline thickness and corner radius as the other sheets.
- [ ] Skins: straight, even edges (they will be stretched); lip only at the bottom.
- [ ] Icons: one solid white colour, readable when shrunk to 24 px.
- [ ] No brands, no faces on figures, no body shaming.

---

## 13. Mockups to ask for (references only)

The generator's portrait size is usually 1024 x 1536, which is **not** the game's shape (9:16). So
each mockup is drawn as **a 864 x 1536 screen centred on a 1024 x 1536 image**, with plain light grey
`#E0E0E0` bands of 80 px on the left and right. Every position in this brief is then **x 1.2** (for
example the Exercise button is at 29 + 80 = 109, 1190, size 394 x 144).

Text in mockups: the **English** words of this brief (one Portuguese version of the main screen is
useful to check the longest words).

| # | Mockup | What it shows |
|---|---|---|
| 1 | Main screen, day | The whole section 6.1, no activity: the four buttons, the speech bubble "I'm hungry!" with the hungry picture. |
| 2 | Main screen, night | The same at night, Wake enabled, "I slept 9 h. Press the wake button to start the day." |
| 3 | Main screen with the measures and values panels open | Section 6.1 panels. |
| 4 | Main screen during an activity | Stop button visible, the four buttons disabled. |
| 5 | Exercise options panel | Section 6.2 with the slider at 30 minutes. |
| 6 | Entertainment options panel | Section 6.2. |
| 7 | Sleep panel | Section 6.3. |
| 8 | Canteen | Section 6.4 with two foods on the plate. |
| 9 | Cardio minigame | Section 6.5, street behind the avatar. |
| 10 | Strength minigame | Down enabled, Up disabled. |
| 11 | Meal minigame | Bite! and Done, the Tummy bar green. |
| 12 | Football minigame | Field from above, joystick, Pass and Shoot. |
| 13 | Settings, with the warning open | Section 6.7. |
| 14 | Failure screen and its Details | Section 6.8 (two mockups). |
| 15 | Main menu, with an avatar | Section 6.9. |
| 16 | Main menu, first visit | New avatar as the big green button. |
| 17 | Avatars page | Section 6.9, one empty place, one avatar, one asking to delete. |
| 18 | **New avatar creation** | Section 6.10, with a card and Normal selected. |
| 19 | Main screen in Portuguese | To check the longest words fit. |

---

## 14. Open questions for the user and the team

The brief uses these answers; change them here if you decide otherwise, and the mockups follow.

1. **Colours per activity** (section 3.1): exercise orange, sleep indigo, eat yellow,
   entertainment magenta, and the measures bars in the same colours (Physical orange,
   Happiness magenta, Sleep indigo). OK?
2. **Red only for Stop and Cancel** (your example), **dark red with a warning icon** for the
   final "Yes, delete" and "Yes, start again". **Back and Close are neutral** (they only go back,
   they cancel nothing). OK, or should Close and Back be red too?
3. **Sleep's confirm button**: green (like every "go") or indigo (like everything about sleep)?
4. **Delete** on the avatars page: neutral with a red trash icon (the real delete is the second
   press), or red?
5. **Football Shoot and Tackle** change from red to orange (red means stop). OK?
6. **New creation screen** (section 6.10): four avatar cards (age and sex in one tap), Normal
   difficulty chosen at the start with "Recommended", and a dice that suggests a name (needs a
   list of names; Claude would add a placeholder list to `data/`). OK?
7. **First visit**: New avatar becomes the big green button when there is no avatar yet. OK?
8. **XP gold** instead of white, and the boxes say "HEALTH" and "XP LEVEL". OK?
9. **Font Nunito** (free, OFL licence; it would be added to the README's licences). OK?
10. **Sizes changed**: the physical values panel 268 x 340 (now 160 wide), the Help button 56 x 56
    (now 44 x 40). OK?
11. **Backgrounds** (section 11): now, or after the buttons?

## 15. How the art goes into the game (for Claude, later)

- Skins become `StyleBoxTexture` in `scenes/ui/main_theme.tres` and `night_theme.tres`, one theme
  type variation per role (`GoButton`, `StopButton`, `DangerButton`, `ExerciseButton`,
  `SleepButton`, `EatButton`, `FunButton`, `WakeButton`, `TeamButton`, `GoldBox`), with texture
  margins 56 left, right and top and 64 bottom (2x), drawn at half scale. The pressed state moves
  the content 4 px down.
- Icons go on `Button.icon` with `expand_icon` and the role's icon colour; glyphs are white so
  `icon_normal_color` tints them.
- Bars use `StyleBoxTexture` for `background` and `fill`.
- The football pad, beat bar, gauges and food tiles are drawn by scripts; they would draw the
  textures instead of plain rectangles.
- Text stays in `translations/strings.csv`; the new words "HEALTH" and "XP LEVEL" need new keys
  (en and pt).
- Every new picture gets the CC BY 4.0 note in the README, like the avatar sheets.
