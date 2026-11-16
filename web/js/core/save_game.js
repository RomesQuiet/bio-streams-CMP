// Saves and loads the game on this device. Kept apart from Clock and GameState,
// so a server can replace this module later without changing the rest.
//
// Saves to the browser's localStorage (written at once, so nothing is lost when the tab
// closes). The keys are those of the Godot web version, so its saves load here.
//
// Deleting: delete_save() writes down the last save number, and any copy that is not newer
// than it is ignored (the Godot version needed this because the browser could give back a
// deleted file after a reload; it is kept so the saves behave the same).
//
// Milestone 18 (main menu): save.slots places for avatars. Place 0 keeps the old key, so an
// existing save becomes the first avatar; place n uses keys ending in _<n + 1>. Nothing loads by
// itself: the main menu chooses a place (play_slot) or makes a new avatar in a free one
// (start_slot). A backup is the save's own text, downloaded as a file and loaded into a free
// place.
import {Config} from "./config.js";
import {GameState} from "./game_state.js";
import {Clock} from "./clock.js";
import {Activities} from "./activities.js";
import {Minigame} from "./minigame.js";
import {Habits} from "./habits.js";
import {Simulation} from "./simulation.js";
import {Settings} from "./settings.js";
import {Storage} from "./storage.js";
import {Debug} from "./debug.js";
import {get, push_warning} from "./util.js";

const WEB_STORAGE_KEY = "plasticine_tamagotchi_save";
const WEB_DELETED_KEY = "plasticine_tamagotchi_deleted_save";
// Version of the save format. A save with another version is ignored and the creation
// screen opens. 2 = Milestone 10 (Health Calculation Architecture v1): saves from Milestone 4
// or earlier (version 1) do not load (decision 6, user, 25 Oct 2026).
const SAVE_VERSION = 2;

export const SaveGame = {
	WEB_STORAGE_KEY, WEB_DELETED_KEY, SAVE_VERSION,
	// The storage key of the save. Tests change it so they never touch the real save.
	save_key: WEB_STORAGE_KEY,
	_deleted_key: WEB_DELETED_KEY,
	// When false, nothing is saved automatically (key moments, timer, closing). Tests turn it off.
	auto_save_enabled: true,
	// The avatar place in use (0 to save.slots - 1).
	slot: 0,
	// What the main menu should do when it opens ("new_avatar" after a failure), then cleared.
	menu_request: "",
	// Goes up by one with every save, so the newest copy can be found without the device clock.
	_save_count: 0,
	// Saves up to this number were deleted.
	_deleted_count: 0,
	_ready_done: false,
	_autosave_left: 0,

	_ready() {
		// Key moments: every phase change (sleep start, sleep end, wake), every new day,
		// pause, and the start and end of every activity.
		Clock.phase_changed.connect(() => _auto_save());
		Clock.day_started.connect(() => _auto_save());
		Clock.paused_changed.connect(() => _auto_save());
		Activities.started.connect(() => _auto_save());
		Activities.ended.connect(() => _auto_save());
		SaveGame._autosave_left = Config.get_float("save.autosave_real_seconds");
		// The page is hidden or closed: save at once.
		if (typeof document !== "undefined") {
			document.addEventListener("visibilitychange", () => _auto_save());
			window.addEventListener("pagehide", () => _auto_save());
			window.addEventListener("beforeunload", () => _auto_save());
		}
		SaveGame._ready_done = true;
	},

	// Extra safety save every save.autosave_real_seconds while the game is open.
	_process(delta) {
		SaveGame._autosave_left -= delta;
		if (SaveGame._autosave_left <= 0) {
			SaveGame._autosave_left = Config.get_float("save.autosave_real_seconds");
			_auto_save();
		}
	},

	save_game() {
		const s = SaveGame;
		s._save_count += 1;
		const data = {
			version: SAVE_VERSION,
			save_count: s._save_count,
			game_state: GameState.to_dict(),
			clock: Clock.to_dict(),
			activities: Activities.to_dict(),
			minigame: Minigame.to_dict(),
			habits: Habits.to_dict(),
			simulation: Simulation.to_dict(),
		};
		Storage.set(s.save_key, JSON.stringify(data, null, "\t"));
	},

	// Loads the newest saved copy. Returns false if there is no valid save.
	load_game() {
		const s = SaveGame;
		s._deleted_count = _read_deleted_count();
		// New saves must count on from the deleted ones, or they would be ignored too.
		s._save_count = Math.max(s._save_count, s._deleted_count);
		const data = _parse(Storage.get(s.save_key));
		const count = Math.trunc(Number(get(data, "save_count", 0)));
		if (Object.keys(data).length === 0 || count <= s._deleted_count) return false;
		s._save_count = count;
		// Nothing pending while the Clock is restored (its phase change would run it), and no
		// new day or activity start is run again while the save is restored.
		Simulation.reset();
		Simulation.loading = true;
		GameState.from_dict(get(data, "game_state", {}));
		Clock.from_dict(get(data, "clock", {}));
		Activities.from_dict(get(data, "activities", {}));
		Minigame.from_dict(get(data, "minigame", {}));
		Habits.from_dict(get(data, "habits", {}));
		Simulation.from_dict(get(data, "simulation", {}));
		Simulation.loading = false;
		return true;
	},

	// Removes the save and starts a new game.
	delete_save() {
		const s = SaveGame;
		s._deleted_count = Math.max(s._save_count, _read_deleted_count());
		Storage.remove(s.save_key);
		Storage.set(s._deleted_key, String(s._deleted_count));
		Activities.reset();
		Minigame.reset();
		Habits.reset();
		Simulation.reset();
		GameState.reset();
		Clock.reset();
	},

	// Debug only (?debug): F8 deletes the save and starts a new game.
	_key_pressed(key) {
		if (!Debug.allowed() || key !== "F8") return;
		SaveGame.delete_save();
		console.log("SaveGame: save deleted, new game started");
		location.reload();
	},

	// --- Avatar places (Milestone 18) ---

	slot_count() {
		return Config.get_int("save.slots");
	},

	key_for(place) {
		return WEB_STORAGE_KEY + _key_suffix(place);
	},

	// Uses this place for saving and loading from now on (nothing is loaded).
	select_slot(place) {
		const s = SaveGame;
		s.slot = place;
		s.save_key = WEB_STORAGE_KEY + _key_suffix(place);
		s._deleted_key = WEB_DELETED_KEY + _key_suffix(place);
		s._save_count = 0;
		s._deleted_count = 0;
	},

	// The newest valid save of a place, without loading it: {} when the place is empty.
	slot_data(place) {
		const deleted = _read_deleted_count(WEB_DELETED_KEY + _key_suffix(place));
		const data = _parse(Storage.get(WEB_STORAGE_KEY + _key_suffix(place)));
		const count = Math.trunc(Number(get(data, "save_count", 0)));
		return Object.keys(data).length > 0 && count > deleted ? data : {};
	},

	// The avatar of a place, for the menu's cards: its GameState values, or {} when empty.
	slot_summary(place) {
		return get(SaveGame.slot_data(place), "game_state", {});
	},

	// The first place without an avatar, or -1 when all are taken.
	first_free_slot() {
		for (let place = 0; place < SaveGame.slot_count(); place++) {
			if (Object.keys(SaveGame.slot_summary(place)).length === 0) return place;
		}
		return -1;
	},

	// Back to the menu: the game is emptied and time stops (the avatar is saved first).
	unload() {
		if (GameState.is_created()) SaveGame.save_game();
		Activities.reset();
		Minigame.reset();
		Habits.reset();
		Simulation.reset();
		GameState.reset();
		Clock.reset();
		Clock.halted = true;
	},

	// Loads the avatar of a place to play it. False if the place is empty.
	play_slot(place) {
		SaveGame.unload();
		SaveGame.select_slot(place);
		if (!SaveGame.load_game()) return false;
		Clock.halted = false;
		if (Config.get_value("save.resume_paused") && Clock.phase === Clock.Phase.DAY) Clock.set_paused(true);
		Settings.set_last_slot(place);
		return true;
	},

	// A new avatar in this place: an empty game that runs; the creation screen fills it.
	start_slot(place) {
		SaveGame.unload();
		SaveGame.select_slot(place);
		Clock.halted = false;
		Settings.set_last_slot(place);
	},

	// Deletes the avatar of a place for good.
	delete_slot(place) {
		SaveGame.unload();
		SaveGame.select_slot(place);
		SaveGame.delete_save();
		Clock.halted = true;
	},

	// A backup: the place's save as text ("" when empty).
	backup_text(place) {
		const data = SaveGame.slot_data(place);
		return Object.keys(data).length === 0 ? "" : JSON.stringify(data, null, "\t");
	},

	// Loads a backup into a place. False if the text is not a valid save of this version.
	restore_backup(text, place) {
		const data = _parse(text);
		if (Object.keys(data).length === 0) return false;
		const previous = SaveGame.slot;
		SaveGame.unload();
		SaveGame.select_slot(place);
		// Newer than anything deleted from this place, so it is never ignored.
		data.save_count = _read_deleted_count() + 1;
		Storage.set(SaveGame.save_key, JSON.stringify(data, null, "\t"));
		SaveGame.select_slot(previous);
		Clock.halted = true;
		return true;
	},
};

// Nothing is saved before the avatar is created, so an old save stays until then.
function _auto_save() {
	if (SaveGame.auto_save_enabled && SaveGame._ready_done && GameState.is_created()) SaveGame.save_game();
}

function _key_suffix(place) {
	return place === 0 ? "" : `_${place + 1}`;
}

function _read_deleted_count(key = "") {
	const value = Storage.get(key !== "" ? key : SaveGame._deleted_key);
	const count = Math.trunc(Number(value || "0"));
	return Number.isFinite(count) ? count : 0;
}

// Returns the save data, or an empty object if the text is not a valid save.
function _parse(text) {
	if (!text) return {};
	let parsed;
	try {
		parsed = JSON.parse(text);
	} catch (error) {
		push_warning("SaveGame: ignoring a save that is not valid JSON");
		return {};
	}
	if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
		push_warning("SaveGame: ignoring a save that is not valid JSON");
		return {};
	}
	if (Math.trunc(Number(get(parsed, "version", 0))) !== SAVE_VERSION) {
		push_warning("SaveGame: ignoring a save from another version of the game (an old save from Milestone 4 or earlier, or a newer one)");
		return {};
	}
	const state = get(parsed, "game_state", {});
	if (state === null || typeof state !== "object" || !GameState.has_all_choices(state)) {
		// Saves from Milestones 1 and 2 have no age group, sex or difficulty:
		// the player starts a new game on the creation screen.
		push_warning("SaveGame: ignoring a save without the avatar creation choices");
		return {};
	}
	return parsed;
}

