extends Node
## The player's settings on this device (Milestone 11). They belong to the device, not to the
## avatar: nothing here is in the avatar's save, and a new avatar does not change them.
## Listed right after Config, so the language is set before any screen opens.
##
## Saves to user://settings.json and, in the web build, also to localStorage, which is written
## at once (see SaveGame). The file is only written when the player chooses, so until then the
## game keeps following the browser's language.

const SETTINGS_PATH := "user://settings.json"
const WEB_STORAGE_KEY := "plasticine_tamagotchi_settings"
## The languages of translations/strings.csv.
const LANGUAGES: Array[String] = ["pt", "en"]

## Emitted after the language changed. Text on screen follows by itself or with
## NOTIFICATION_TRANSLATION_CHANGED; this is for screens that show which language is chosen.
signal language_changed(id: String)
## Emitted after the music was turned on or off (25 Nov 2026).
signal music_changed(on: bool)

## Where the file is saved. Tests change this so they never touch the real settings.
var settings_path := SETTINGS_PATH
var use_web_storage := OS.has_feature("web")
var language := ""
## The first-time explanation of football was shown on this device (Milestone 14).
var football_help_seen := false
## The avatar place played last (Milestone 18): the main menu's Continue.
var last_slot := 0
## The best scores of the screens minigame on this device (Milestone 35), best first, one per
## avatar: {"id", "name", "score"}. An avatar that was deleted or failed keeps its place.
var sky_leaderboard: Array[Dictionary] = []
## Whether the music plays (25 Nov 2026, user choice, on by default; read by the Music autoload).
var music_enabled := true

## The language the player chose, or "" while the game follows the browser.
var _chosen_language := ""


func _ready() -> void:
	load_settings()


## Reads the saved language, or uses the first-start rule when there is none.
func load_settings() -> void:
	var data := _read()
	var saved := str(data.get("language", ""))
	_chosen_language = saved if saved in LANGUAGES else ""
	football_help_seen = bool(data.get("football_help_seen", false))
	last_slot = int(data.get("last_slot", 0))
	music_enabled = bool(data.get("music_enabled", true))
	sky_leaderboard.clear()
	var board: Variant = data.get("sky_leaderboard", [])
	if board is Array:
		for entry: Variant in board:
			if entry is Dictionary:
				sky_leaderboard.append({"id": str(entry.get("id", "")), "name": str(entry.get("name", "")),
						"score": int(entry.get("score", 0))})
	_apply(saved if saved in LANGUAGES else language_for_locale(OS.get_locale_language()))


## First start (decision 15): any Portuguese gives Portuguese, otherwise defaults.language.
func language_for_locale(locale_language: String) -> String:
	return "pt" if locale_language == "pt" else Config.get_string("defaults.language")


## The player turned the music on or off: it applies at once and is saved.
func set_music_enabled(on: bool) -> void:
	if on == music_enabled:
		return
	music_enabled = on
	music_changed.emit(on)
	_save()


## The player chose a language: it is used at once and saved.
func set_language(id: String) -> void:
	if not id in LANGUAGES:
		push_error("Settings: unknown language '%s'" % id)
		return
	_apply(id)
	_chosen_language = id
	_save()


## The avatar place played last.
func set_last_slot(place: int) -> void:
	last_slot = place
	_save()


## A run of the screens minigame ended with this score: it is the avatar's place on the device's
## leaderboard when it is the avatar's best and good enough. Returns true if the board changed.
func record_sky_score(avatar_id: String, avatar_name: String, score: int) -> bool:
	if score <= 0:
		return false
	for entry in sky_leaderboard:
		if entry.id == avatar_id:
			if score <= int(entry.score):
				return false
			sky_leaderboard.erase(entry)
			break
	sky_leaderboard.append({"id": avatar_id, "name": avatar_name, "score": score})
	sky_leaderboard.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	var kept := Config.get_int("minigame.sky.leaderboard_size")
	var changed := sky_leaderboard.find_custom(func(e: Dictionary) -> bool: return e.id == avatar_id) < kept
	sky_leaderboard.resize(mini(sky_leaderboard.size(), kept))
	if changed:
		_save()
	return changed


## The player has seen the explanation of football.
func mark_football_help_seen() -> void:
	football_help_seen = true
	_save()


func _save() -> void:
	var data := {"football_help_seen": football_help_seen, "last_slot": last_slot, "sky_leaderboard": sky_leaderboard,
			"music_enabled": music_enabled}
	if not _chosen_language.is_empty():
		data["language"] = _chosen_language
	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file == null:
		push_error("Settings: could not write %s (error %d)" % [settings_path, FileAccess.get_open_error()])
	else:
		file.store_string(text)
		file.close()
	if use_web_storage:
		JavaScriptBridge.eval("try { localStorage.setItem(%s, %s); } catch (e) {}" % [
			JSON.stringify(WEB_STORAGE_KEY), JSON.stringify(text)])


## A number for the player, with the decimal mark of the language (0.85 or 0,85).
## signed: also shows + on positive numbers.
func number(value: float, decimals: int, signed := false) -> String:
	return decimal_text(("%+.*f" if signed else "%.*f") % [decimals, value])


## A number already written as text, with the decimal mark of the language.
func decimal_text(text: String) -> String:
	return text.replace(".", tr("FORMAT_DECIMAL_MARK"))


func _apply(id: String) -> void:
	language = id
	TranslationServer.set_locale(id)
	language_changed.emit(id)


## The saved settings, or {} when there are none. The web copy goes first: it is always the
## newest, because the browser writes user:// a moment later.
func _read() -> Dictionary:
	for text in [_read_web_storage(), _read_file()]:
		var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
		if parsed is Dictionary:
			return parsed
	return {}


func _read_file() -> String:
	if not FileAccess.file_exists(settings_path):
		return ""
	return FileAccess.get_file_as_string(settings_path)


func _read_web_storage() -> String:
	if not use_web_storage:
		return ""
	var value: Variant = JavaScriptBridge.eval(
		"(function () { try { return localStorage.getItem(%s) || ''; } catch (e) { return ''; } })()"
		% JSON.stringify(WEB_STORAGE_KEY))
	return value if value is String else ""
