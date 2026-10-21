# Plasticine Tamagotchi

A web game about **childhood obesity**, made for the Bio-Streams (EU) science competition.

The player looks after an avatar who is a school student and tries to raise its health (from 1 to 5) through **sport, sleep and food**. The game uses scientifically correct information and will be available in Portuguese and English.

## Play

Play in the browser (computer, Android or iOS):
**https://romesquiet.github.io/bio-streams-game-Porto-Portugal-Conservat-rio-de-M-sica-do-Porto/**

The game saves on your device. Nothing is sent to a server. A new game starts on the avatar creation screen. Saves from before Milestone 3 do not load: you create a new avatar. 

## Run it yourself

1. Install [Godot 4.6.3](https://godotengine.org/download/archive/4.6.3-stable/) (standard version, not .NET).
2. Clone or download this repository.
3. Open Godot, click **Import**, and choose the `project.godot` file in this folder.
4. Press **F5** (or the ▶ button at the top right) to run the game.

The project uses the **Compatibility** renderer so that it works in web browsers on computers, Android and iOS.

Debug keys (only when running from the Godot editor): **F9** changes the game speed (x1, x60, x600), **F8** deletes the save and starts a new game.

## Tests

From the project folder (on macOS, `Godot` is `/Applications/Godot.app/Contents/MacOS/Godot`):

```
Godot --headless --path . -s res://tests/clock_test.gd
Godot --headless --path . -s res://tests/save_test.gd
Godot --headless --path . -s res://tests/activities_test.gd
Godot --headless --path . -s res://tests/health_xp_test.gd
Godot --headless --path . -s res://tests/creation_test.gd
Godot --headless --path . -s res://tests/difficulty_test.gd
Godot --headless --path . -s res://tests/habits_test.gd
```

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
| `assets/` | Art and audio |
| `documentation/` | Development notes |
| `docs/` | Web export, published with GitHub Pages |

## Licence

- Code: MIT (see `LICENSE`).
- Texts and art: CC BY 4.0.
- Original music belongs to its authors (Matilde with Senhor Carlitos), who decide its licence.
