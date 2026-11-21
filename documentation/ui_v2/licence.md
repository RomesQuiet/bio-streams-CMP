# licence.md

**Mockups (`work/mockups/01` to `15`).** Made by the team with an AI image tool. Which tool and which prompts are **not known to me**: the team must write them here before anything is published. They are reference pictures for the look; no mockup is copied into the game.

**Raster files in `assets/` (delivered 21 Nov 2026, listed in `files.md`).** Made by the team with "the built-in image generation and editing tool" (the team's notes; the files came from a Codex folder, so probably the Codex app's tool: **the team must confirm the tool's name**), from the team's own reference pictures of the four characters (the avatar sheets already in the game). The prompts are in `work/team_prompts_assets.json`. According to the team's notes, `child_male/bed.png` started as a picture the team supplied, and the other three beds are edits of it. Cropping, scaling and aligning were done by Claude with `work/normalise.py`; nothing was redrawn. Offered under **CC BY 4.0**, as the avatar art. **To check before publishing:** that the terms of that tool let the team publish its pictures under CC BY 4.0, as was done for the avatar sheets.

| Files | Made by | Tool |
|---|---|---|
| `assets/avatar/*/run_0*.png`, `squat_*`, `pushup_*`, `situp_*`, `tablet.png` | the team | image tool built into Codex |
| `assets/avatar/*/bed.png` | the team (`child_male` from a supplied picture, the rest edits of it) | image tool built into Codex |
| `assets/food/*.png` | the team | image tool built into Codex |
| `assets/scenery/window_blind.png` | the team | image tool built into Codex |
| second delivery (21 Nov 2026): `assets/avatar/*/eat_open.png`, `eat_closed.png` (closed edited from open), `assets/food/{vegetable_soup, wholemeal_bread, rice, beans, water}.png`, the cards with words now in `work/menu_cards_en/` | the team | the same tool; prompts in `work/team_prompts_v2.json` |

**`assets/menu/eat_choice_good.png` and `eat_choice_fast.png`:** put together by Claude (21 Nov 2026) from the team's food pictures above, nothing new drawn; CC BY 4.0. The team's cards with words, `work/menu_cards_en/`, are not used.

**Code-drawn parts** (HUD, buttons, bars, panels, icons, scenery): written for this project, MIT (code) as stated in `CLAUDE.md`.

Pictures from other sources, or made with a tool whose terms do not allow CC BY 4.0, do not go into the game.

**Fonts.** Nunito (OFL), already in `assets/fonts/nunito/`.
