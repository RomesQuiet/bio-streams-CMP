# Milestone 18 — The main menu

**Status: built and committed (7 November 2026), not pushed.** The user plays it, then tunes it.

## What was decided before

- Concept and development plan: the screens include a **lobby** with flashes of the creation process and the team's original music (low priority, kept). Saving is local (18 Oct 2026); no server or accounts (a server with one avatar per account is only a proposal). Open: how to protect saves from the browser deleting them ("an account or a recovery code").

## The user's request (7 Nov 2026)

"Build the main menu, before playing, so it feels more natural: play, avatars, continue, saving mechanism, all that." Claude proposed a menu, avatar places, backups, a Main menu button and keeping failed avatars, and asked five questions; the user: "build it already, then we tune", and "make this task a milestone of its own". Built with Claude's suggested answers (to tune):

| Question | Built with |
|---|---|
| How many avatars? | 3 places (`save.slots`, placeholder) |
| Protecting saves | Backup files: download one per avatar, load one into a free place |
| Lobby pictures and music | Placeholders: the sky, the grey ground and the last avatar; the team's photos and music later |
| About and How to play | About (team, sources, licences, saving); How to play not built |
| Failed avatars | Kept in the list with "failed after N days" until deleted |

## Built

- **The menu** (`scenes/ui/menu.tscn`, `scripts/ui/menu.gd`; now the game's first scene): the title, a line about the game, the avatar played last standing on the ground, **Continue** (with its name, level, health and days), **New avatar**, **Avatars**, **Load a backup**, **About**, and Português / English. The game is emptied and time stands still while the menu is open.
- **Avatars page:** a card per place with the avatar's picture and line; **Play**, **Backup** and **Delete** (a second press confirms), or **New avatar** for an empty place. New avatar with every place taken opens this page with "All places are taken. Delete an avatar first."
- **Places** (`SaveGame`): place 1 keeps the old file and browser keys (`user://save.json`), so an existing save becomes the first avatar; places 2 and 3 use `user://save_2.json` and `save_3.json`. `select_slot`, `slot_summary`, `first_free_slot`, `play_slot`, `start_slot`, `delete_slot`, `unload`, `backup_text` and `restore_backup`. Nothing loads by itself any more. `Settings.last_slot` remembers the place played last (Continue).
- **Backups:** the avatar's save as a `.json` file. In the browser it downloads, and Load a backup opens the browser's file picker; on a computer Godot's file window opens. A file that is not a save of this version is refused. Automatic saving is unchanged.
- **Main menu** button in the in-game settings (saves, then opens the menu). The creation screen has **Back**. After failure, **Start a new avatar** opens the menu and starts a new avatar in a free place; the failed one stays in the list.
- **About:** the team and the competition, how health works in one sentence, the main sources, the licences (and that the avatar drawings were made by the team with an AI tool), and why to make backups.
- Texts in English and Portuguese (Claude's draft).

## Checked

`tests/menu_test.gd` (places, deleting, playing, backups, the menu's Continue and cards, the full message, the delete confirmation, a failed avatar's line) and all other quick tests. Rendered in a Godot window. In the web build: the old browser save shows as the first avatar, Continue opens it where it was, Settings → Main menu returns, the avatars page shows the cards; no console errors. **Not checked:** downloading and loading a backup in a browser and on phones (the browser file picker may need the tap to reach it quickly, especially on iPhone), a real person playing.

## Still open

The team's lobby pictures and music, How to play, the number of places, and the Portuguese wording.
