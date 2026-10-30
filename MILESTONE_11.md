# Milestone 11 — Settings panel and Portuguese

**Status: built and committed (30 October 2026), not pushed.** The user checks the game and the Portuguese, then pushes. Claude's Portuguese is a draft until the user or the team has read it (Task 4). Task 2 `03c4ead`; the later commits are in `documentation/handoff.md`.

**Changes made while building (beyond this list):**

- The settings panel sits on a dark layer over the whole screen, so nothing else can be pressed while it is open (an activity started behind it would have ended the pause).
- **Deleting a save on the web needed a marker.** After "Start a new avatar" and an immediate reload the old avatar came back, because the browser's IndexedDB still held the file. `SaveGame.delete_save()` now writes the last save number to localStorage (`plasticine_tamagotchi_deleted_save`), which is written at once; a copy that is not newer is ignored, and new saves count on from it. Only the browser test found this, so repeat it after any change to saving.
- Numbers with decimals use `%s` in the texts, filled by `Settings.number()`, because `%.1f` cannot give a decimal comma. Keys of texts that only hold a number format stay in the CSV.
- In Portuguese "IMC para a idade" and "Qualidade da alimentação" have a line break, because the values box covered the right column.

**Checked in the web build (browser pane, 30 Oct 2026):** every screen and panel in Portuguese; the language surviving a reload; a `pt-BR` browser opening in Portuguese and `en-GB` in English, with nothing saved until the player chooses; a new avatar deleted and reloaded at once, and the next avatar loading. **Not checked:** a real phone, including the pop-up name box in Portuguese.

Goal: the settings button (top right of the main screen, which does nothing today) opens a real settings panel, and the whole game can be played in **European Portuguese** or English. The concept document requires both languages, "in scientifically correct language, not simplified for young children".

Read `CLAUDE.md` and `documentation/handoff.md` first. Rules that still hold: no game number in a script, explain in plain language, do not invent game rules, nothing is pushed without the user asking (pushing publishes the game, and the user pushes from GitHub Desktop because this shell has no GitHub login).

## Decisions

**User, 30 Oct 2026:**

| # | Question | Decision |
|---|---|---|
| 14 | What is in the settings panel? | **Language (Portuguese or English) and "Start a new avatar"**, with a confirmation step. Music and sound settings wait until the music exists. |
| 15 | Which language at the first start? | **The browser's language:** Portuguese if it is any Portuguese (`pt`, `pt-PT`, `pt-BR`), otherwise English. The **creation screen also gets PT and EN buttons**, because settings cannot be reached from it. |
| 16 | How to work | **All tasks in a row**, each committed on its own; nothing pushed; the user reviews at the end.  |

**Proposed by Claude, not yet confirmed by the user or team** (change them here if they disagree):

- **European Portuguese** (`pt` in the code), as in the team's documents: "telemóvel", "ecrã", "definições". Brazilian browsers get the same text.
- **Wording that does not depend on the avatar's sex**, so one text is enough. Example: "I'm tired" means sleepy in this game (concept), so it becomes "Tenho sono", not "Estou cansado/cansada".
- **Decimal comma in Portuguese** (36,0 kg; 0,85), which is the correct Portuguese form. The clock stays 07:00.
- **The game pauses while settings are open during the day** and returns to how it was when they close. It cannot pause during sleep (`Clock.set_paused` refuses), so sleep keeps running.
- **The debug panel (F7), the CSV log and test output stay in English.** Players never see them.
- **The language is not part of the avatar's save.** It stays when a new avatar starts.

## What exists today (read on 30 Oct 2026)

- `SettingsButton` is in `scenes/main.tscn` but connected to nothing.
- `translations/` holds only `.gitkeep`, and no script uses `tr()`.
- `GameState.language` exists and is saved in the avatar's save, but nothing reads it. It comes from `defaults.language` in `data/config.json` (`"pt"`, placeholder). **That is the wrong place:** the language must be known before an avatar exists, and nothing is saved before Start.
- `SaveGame.delete_save()` already removes both copies of the save (`user://save.json` and the browser's localStorage). Debug key F8 uses it. Removing only localStorage is not enough: the other copy loads again.
- About 75 player-facing texts, in these places:
  - `scenes/main.tscn` and `scenes/ui/creation.tscn`: `text`, `tooltip_text`, `placeholder_text`;
  - `scripts/ui/main.gd`: speech, failure messages, physical values, XP, sleep information, "Skip meal", "Level up!";
  - `scripts/ui/creation.gd`: age groups, sexes, difficulties and their descriptions;
  - `data/activities.json`: the `name` of every activity and option.

## How translation works in Godot (tested 30 Oct 2026 in a copy of the project)

- A CSV file `translations/strings.csv` with columns `keys,en,pt`. Godot imports it into `strings.en.translation` and `strings.pt.translation`.
- `project.godot` must list both files under `[internationalization]`, `locale/translations`.
- `TranslationServer.set_locale("pt")` changes the language, and `tr("KEY")` returns the text. Formats work: `tr("LEVEL_UP") % 3`.
- **After changing the CSV, run the import** before headless tests: `"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . --import`. The `.translation` files are ignored by git (`.gitignore`), so a new copy of the project also needs this. `strings.csv.import` is committed.
- The default font has ã, ç, é and õ (checked).
- The web export includes the translations, and `OS.get_locale_language()` gives the browser's language (checked in Task 8 in the browser pane; a real phone is still to be checked).
- Controls translate their own `text` and `tooltip_text` when these hold a key. Text set from a script needs `tr()` and must be set again when the language changes (`NOTIFICATION_TRANSLATION_CHANGED`).

## Task 1 — The phone name field (done, 30 Oct 2026)

The pop-up box (`fe5c4c3`) is confirmed on a real Android phone and stays (user). The virtual keyboard attempt `adfe369` was never published and is reverted. Its two texts, "Tap to type a name" and "Name of your avatar:" (`scripts/ui/creation.gd`), are translated in Tasks 3 and 4.

## Task 2 — Settings store and language at start

- New autoload `Settings` (`scripts/autoload/settings.gd`), listed right after `Config`, so the language is set before any screen opens. It keeps the player's device settings apart from the avatar.
- Saves `user://settings.json`, and on the web also a localStorage copy, in the same way as `SaveGame`. It has a path that tests can change, so they never touch the real file.
- `Settings.language`, `Settings.set_language(id)` (saves at once, calls `TranslationServer.set_locale`).
- First start: `OS.get_locale_language()`, `pt` gives Portuguese, anything else gives `defaults.language`, which becomes `"en"`.
- Remove `GameState.language` (keeps save version 2: older saves simply carry an unused key).
- Create `translations/strings.csv` and add it to `project.godot`.
- Done when: `tests/settings_test.gd` shows the first-start rule, that a chosen language survives a restart, and that a new avatar does not change it.

## Task 3 — Every text becomes a key

- Replace the texts listed above with keys, grouped by a prefix: `UI_`, `SPEECH_`, `CREATION_`, `ACTIVITY_`, `MEASURE_`, `FAILURE_`, `SETTINGS_`. Example: `text = "UI_EXERCISE"`.
- `data/activities.json`: `name` holds a key (`ACTIVITY_CARDIO`).
- `main.gd` and `creation.gd` use `tr()` and refresh on `NOTIFICATION_TRANSLATION_CHANGED`, including an options list that is open and the "Level up!" message.
- A small helper for numbers with the right decimal mark, used by every value the player sees.
- Fill the `en` column with today's exact wording, so **the English game does not change** in this task.
- Tests compare with `tr()` and set English first (`measures_test.gd` uses `FAILURE_TEXTS` and `DANGER_TEXT`).
- Done when: all tests pass and the English game looks exactly as before.

## Task 4 — The Portuguese text

- Fill the `pt` column. Use the terms below. Keep every `%d`, `%s`, `%.1f` and `\n` of the English text.
- Done when: the user or the team has read the Portuguese, because Claude's translation is only a draft. It is a science competition, so the health terms matter.

**Terms (draft for the team to check):**

| English | Portuguese |
|---|---|
| Health | Saúde |
| Physical | Físico |
| Happiness | Felicidade |
| Sleep amount | Quantidade de sono |
| Fitness | Aptidão física |
| Strength | Força |
| Muscle strength (activity) | Força muscular |
| Calories spent | Calorias gastas |
| BMI-for-age | IMC para a idade |
| Diet quality | Qualidade da alimentação |
| Weight, Height | Peso, Altura |
| Healthy meal | Refeição saudável |
| Fast-food meal | Refeição de fast food |
| Skip meal | Saltar a refeição |
| Screens | Ecrãs |
| Football | Futebol |
| Entertainment | Entretenimento |
| Exercise | Exercício |
| Eat, Sleep | Comer, Dormir |
| Wake | Acordar |
| Stop, Start, Cancel | Parar, Começar, Cancelar |
| I'm hungry! | Tenho fome! |
| I'm tired. Sleep is recommended. | Tenho sono. Recomenda-se dormir. |
| I'm not sleepy. | Não tenho sono. |
| I'm sad. | Estou triste. |
| Level up! | Subiste de nível! |
| Child, Teenager | Criança, Adolescente |
| Sex, Male, Female | Sexo, Masculino, Feminino |
| Difficulty: Easy, Normal, Hard, Very hard | Dificuldade: Fácil, Normal, Difícil, Muito difícil |
| Settings, Language | Definições, Idioma |
| Tap to type a name | Toca para escrever um nome |
| Name of your avatar: | Nome do teu avatar: |
| Start a new avatar | Criar um novo avatar |

## Task 5 — The settings panel

- A `PanelContainer` in `scenes/main.tscn`, like the options panel. The settings button opens it, at any moment, even during an activity.
- It holds the title, the language (two toggle buttons, "Português" and "English", never translated), "Start a new avatar" and Close.
- Pauses the day as proposed above, and returns to the previous state on Close.
- Done when: changing the language changes every text at once, without a reload, and the choice survives closing the page.

## Task 6 — Language buttons on the creation screen

- Small PT and EN buttons at the top of `scenes/ui/creation.tscn`, using `Settings.set_language()`.
- What was already typed and chosen stays when the language changes. The chosen difficulty's description changes language.
- Done when: `tests/creation_test.gd` checks this.

## Task 7 — Start a new avatar

- The button shows a warning and two choices (this avatar will be lost / Cancel). Nothing happens without the second press.
- On confirmation: stop any activity, `SaveGame.delete_save()`, reset `Activities`, `Habits`, `Simulation`, `GameState` and `Clock`, then open the creation screen.
- The language stays.
- Check that closing the page right after confirming does not bring the old avatar back. (Nothing saves before an avatar is created, so it should not, but the page saves on closing, so test it.)
- Done when: a test covers confirm and Cancel, and it works in the web build after a reload.

## Task 8 — Layout in Portuguese

- Portuguese texts are longer. Check every screen and panel at phone width in Portuguese: creation screen, speech bubble, options, sleep panel, measures, physical values, settings.
- Shorten the wording or make the box larger if something is cut. The base layout stays 720 x 1280.

## Task 9 — Tests, export and docs

- New `tests/translation_test.gd`: every key has both languages; both languages have the same `%` formats; every key used in scenes, scripts and `activities.json` is in the CSV; no scene still holds plain English.
- Run all tests (`--import` first). Export the web build. Check in the browser pane and on a real phone: the language follows the browser, the buttons work, the Portuguese appears in the web build, the name can be typed.
- Update `CLAUDE.md`, `documentation/handoff.md` and this file. Do not push: the user checks and pushes.

## Out of scope

Music and sound settings; the failure screen and its effect (concept: after failure the player restarts with a new avatar; that can use Task 7 later); a third language; translating the team's documents; the lobby; server and accounts.
