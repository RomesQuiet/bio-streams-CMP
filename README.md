# Plasticine Tamagotchi

A web game about **childhood obesity**, made for the Bio-Streams (EU) science competition.

The player looks after an avatar who is a school student and tries to raise its health (from 1 to 5) through **sport, sleep and food**. The game uses scientifically correct information and is available in Portuguese and English.

## Play

The published game will be available on GitHub Pages. *(Link coming soon.)*

## Run it yourself

1. Install [Godot 4.6.3](https://godotengine.org/download/archive/4.6.3-stable/) (standard version, not .NET).
2. Clone or download this repository.
3. Open Godot, click **Import**, and choose the `project.godot` file in this folder.
4. Press **F5** (or the ▶ button at the top right) to run the game.

The project uses the **Compatibility** renderer so that it works in web browsers on computers, Android and iOS.

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
