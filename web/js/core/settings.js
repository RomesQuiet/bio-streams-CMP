// The player's settings on this device (Milestone 11). They belong to the device, not to the
// avatar: nothing here is in the avatar's save, and a new avatar does not change them.
// Started right after Config, so the language is set before any screen opens.
// Saved in localStorage only when the player chooses, so until then the game keeps following
// the browser's language.
import {Config} from "./config.js";
import {Storage} from "./storage.js";
import {Signal, get, format, push_error} from "./util.js";
import {TranslationServer, tr} from "./translation.js";

const WEB_STORAGE_KEY = "plasticine_tamagotchi_settings";
// The languages of translations/strings.csv.
const LANGUAGES = ["pt", "en"];

export const Settings = {
	WEB_STORAGE_KEY,
	LANGUAGES,
	// Emitted after the language changed. Text on screen follows; this is for screens that show
	// which language is chosen.
	language_changed: new Signal(),
	// Where the settings are kept. Tests change this so they never touch the real settings.
	storage_key: WEB_STORAGE_KEY,
	language: "",
	// The first-time explanation of football was shown on this device (Milestone 14).
	football_help_seen: false,
	// The avatar place played last (Milestone 18): the main menu's Continue.
	last_slot: 0,
	// The language the player chose, or "" while the game follows the browser.
	_chosen_language: "",

	_ready() {
		Settings.load_settings();
	},

	// Reads the saved language, or uses the first-start rule when there is none.
	load_settings() {
		const s = Settings;
		const data = _read();
		const saved = String(get(data, "language", ""));
		s._chosen_language = LANGUAGES.includes(saved) ? saved : "";
		s.football_help_seen = Boolean(get(data, "football_help_seen", false));
		s.last_slot = Math.trunc(Number(get(data, "last_slot", 0)));
		_apply(LANGUAGES.includes(saved) ? saved : s.language_for_locale(_locale_language()));
	},

	// First start (decision 15): any Portuguese gives Portuguese, otherwise defaults.language.
	language_for_locale(locale_language) {
		return locale_language === "pt" ? "pt" : Config.get_string("defaults.language");
	},

	// The player chose a language: it is used at once and saved.
	set_language(id) {
		if (!LANGUAGES.includes(id)) {
			push_error(`Settings: unknown language '${id}'`);
			return;
		}
		_apply(id);
		Settings._chosen_language = id;
		_save();
	},

	// The avatar place played last.
	set_last_slot(place) {
		Settings.last_slot = place;
		_save();
	},

	// The player has seen the explanation of football.
	mark_football_help_seen() {
		Settings.football_help_seen = true;
		_save();
	},

	// A number for the player, with the decimal mark of the language (0.85 or 0,85).
	// signed: also shows + on positive numbers.
	number(value, decimals, signed = false) {
		return Settings.decimal_text(format(signed ? "%+.*f" : "%.*f", [decimals, value]));
	},

	// A number already written as text, with the decimal mark of the language.
	decimal_text(text) {
		return String(text).replaceAll(".", tr("FORMAT_DECIMAL_MARK"));
	},
};

function _save() {
	const s = Settings;
	const data = {football_help_seen: s.football_help_seen, last_slot: s.last_slot};
	if (s._chosen_language !== "") data.language = s._chosen_language;
	Storage.set(s.storage_key, JSON.stringify(data, null, "\t"));
}

function _apply(id) {
	Settings.language = id;
	TranslationServer.set_locale(id);
	Settings.language_changed.emit(id);
}

// The saved settings, or {} when there are none.
function _read() {
	const text = Storage.get(Settings.storage_key);
	try {
		const parsed = text !== "" ? JSON.parse(text) : null;
		if (parsed !== null && typeof parsed === "object" && !Array.isArray(parsed)) return parsed;
	} catch (error) {
		// Not valid: as if there were none.
	}
	return {};
}

// The browser's language, like Godot's OS.get_locale_language().
function _locale_language() {
	return typeof navigator !== "undefined" ? String(navigator.language || "en").slice(0, 2).toLowerCase() : "en";
}
