# My Healthy Avatar

A free web game about **childhood obesity** and the habits behind it, made for the **BIO-STREAMS Hackathon 2026**.

- **Team:** Romimimartilde: Romeu Varela, Miguel Gil, Martim Pinto, Matilde Costa and Maria Martins
- **School:** Conservatório de Música do Porto, class 9B, Portugal
- **Coordinating teacher:** Bento Miguel Afonso Baptista
- **Category:** Digital Prototype (App/Game)
- **Theme:** physical activity and sedentary behaviour

## What it is

The player looks after a virtual school student, an avatar, and decides when it does sport, sleeps, eats and relaxes. The avatar's health, scored from 1 to 5, depends on those decisions. The game does not lecture: players discover how everyday habits affect health by seeing what their choices do to the avatar. It does not judge or compare players' bodies, and it rewards healthy habits, not weight loss.

Health comes from three measures:

- **Physical:** weight, fitness, strength and food quality.
- **Happiness:** mental well-being, which the WHO includes in its definition of health.
- **Sleep:** the avatar's sleep debt, which lowers training gains, raises hunger and lowers mood.

The player acts through four buttons:

- **Exercise:** cardio (tap on the beat), and strength with squats, push-ups or sit-ups.
- **Sleep:** a slider chooses the hours.
- **Eat:** in a school canteen the player builds a plate of healthy or fast food (or skips the meal) and feeds the avatar in a short minigame.
- **Entertainment:** a video game (a dinosaur jumping from cloud to cloud) or football with friends, which also counts as exercise.

The video game's score never changes health. There are no notifications, and sleeping less to play more earns less XP.

**What is new:** in strength training the player really does the squats, push-ups or sit-ups, so the game itself gets players moving. This works on trust: nothing records or films the player.

## Play

Play in the browser (computer, Android or iOS), in English or Portuguese. Nothing to install, no account, no personal data collected:

**https://romesquiet.github.io/bio-streams-CMP/**

To try it: open the link, choose EN, select "New avatar", create your avatar, then use the four buttons and watch how the health bar responds.

The game saves on your device and nothing is sent to a server. Saves live in the browser on that device: a backup can be made in the settings (and in the menu), and "Save to a file" downloads the avatar. The game opens in Portuguese if your browser is in Portuguese, otherwise in English.

## The science

Every rule and number comes from published sources, or is marked as our own choice. The submission annex labels each value as **Source** (a published value used as is), **Adapted** (a published value we changed, with how and why) or **Design** (no source gives it; we chose it to make the game playable). The main sources are the WHO 2020 physical activity guidelines, the WHO BMI-for-age tables (2007), the AASM sleep recommendations (2016), the Schofield equations and the Youth Compendium of Physical Activities, and the Canadian 24-hour movement guidelines.

Real body changes take months, so the body changes 10 times faster than in real life (a game day is 15 real minutes). All values are provisional and are kept in one configuration file, `data/config.json`, each with its status and owner, so they can be tuned without changing the code. The game is meant to teach how habits affect health. It is not a tool for predicting or changing a real person's health.

## Test in class 9B

On 24 and 26 November 2026 class 9B played the game between two science lessons and answered anonymous paper questionnaires. Of 17 students on the second day, 15 enjoyed the game, 15 found it easy to learn without help, 11 said it made them think about one of their own habits and 11 would use it in class. The avatar's health rose for 12 of the 14 students with a readable sheet. The results come from one class over two days, with no comparison group and self-reported answers: they do not show that playing changes real habits.

## For teachers

A short guide for a 5-day class challenge (5 minutes at the start of a lesson each day: sleep, sport, screens, food, putting it together) is in the submission folder. Students play at home in the browser, with no accounts and no personal data. The class compares how much each avatar improved, never the students' bodies.

## Run it yourself

1. Install [Godot 4.6.3](https://godotengine.org/download/archive/4.6.3-stable/) (standard version, not .NET).
2. Clone or download this repository.
3. Open Godot, click **Import**, and choose the `project.godot` file in this folder.
4. Press **F5** (or the ▶ button at the top right) to run the game.

The project uses the **Compatibility** renderer so that it works in web browsers on computers, Android and iOS.

Debug keys (only when running from the Godot editor): **F9** changes the game speed (x1, x60, x600), **F8** deletes the save and starts a new game, **F6** reloads `data/config.json` (change a value, save the file, press F6), **F7** shows or hides the debug panel (only in debug builds, never in the published game). Debug builds also write one line per scoring day to `health_log.csv` (on the Mac: `~/Library/Application Support/Godot/app_userdata/My Healthy Avatar/health_log.csv`; in Finder use Go → Go to Folder and paste the folder path).

## Tests

Each script in `tests/` checks one area and prints PASS or FAIL for every check, and ALL PASSED at the end. Run one from the project folder (on macOS, `Godot` is `/Applications/Godot.app/Contents/MacOS/Godot`):

```
Godot --headless --path . -s res://tests/clock_test.gd
Godot --headless --path . -s res://tests/save_test.gd
Godot --headless --path . -s res://tests/config_test.gd
```

Replace the file name to run another one. `calibration_test.gd` plays the scenarios of the health design through the real game and takes about 2.5 minutes; `parity_test.gd` takes about 5 minutes.

## Export the web version

1. Install the Godot 4.6.3 export templates (**Editor → Manage Export Templates → Download and Install**).
2. **Project → Export…**, choose the **Web** preset, click **Export Project**, and save as `docs/index.html`.
   Or from the command line: `Godot --headless --path . --export-release "Web" docs/index.html`
3. Commit and push the `docs/` folder. GitHub Pages publishes it automatically.

## Folders

| Folder | Contents |
| --- | --- |
| `scenes/` | Godot scenes (screens, UI, avatar) |
| `scripts/` | GDScript code (`autoload/` holds the global scripts) |
| `data/` | Game data and tunable numbers (JSON) |
| `translations/` | Game texts in Portuguese and English (CSV) |
| `assets/` | Art and audio (`assets/art/avatar/source/` holds the original avatar sheets and the team's upscaled versions) |
| `tools/` | Helper scripts, such as `cut_avatar_sheets.py`, which cuts the avatar sheets for the game, and `render_ui_states.gd`, which renders the interface at the test moments of the specification |
| `tests/` | Headless test scripts |
| `documentation/` | Development notes |
| `docs/` | Web export, published with GitHub Pages |

## Credits and licence

- The team made every decision about the rules, the science and the design. Claude (Anthropic) wrote the code from the team's ideas and polished the texts; it made no decisions about the game.
- Code: MIT (see `LICENSE`).
- Texts and art: CC BY 4.0.
- The avatar art (`assets/art/avatar/`) and the other pictures made by the project team (activities, sleep, food, the menu background, the video game), listed in `documentation/ui_v2/licence.md`, were made by the team with the help of AI: **ChatGPT's image tool (DALL·E, OpenAI)**, on a personal ChatGPT Plus account belonging to an adult team member, and are shared under CC BY 4.0 like the rest of the art. OpenAI's Terms of Use assign the output to the user, so the team may offer it under this licence; checked 24 Nov 2026.
- Music: original, composed by Matilde Costa and Maria Martins and performed by the team. It belongs to its authors, who decide its licence.
- Godot Engine (MIT).
- The font Nunito (`assets/fonts/nunito/`, from Google Fonts' official repository) is by The Nunito Project Authors and is under the SIL Open Font License 1.1 (`assets/fonts/nunito/OFL.txt`).
- The interface is drawn by code; its approved mockups (`documentation/ui_mockups/`) come from the project team.
