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

## Where the file is saved. Tests change this so they never touch the real settings.
var settings_path := SETTINGS_PATH
var use_web_storage := OS.has_feature("web")
var language := ""
## The first-time explanation of football was shown on this device (Milestone 14).
var football_help_seen := false

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
	_apply(saved if saved in LANGUAGES else language_for_locale(OS.get_locale_language()))


## First start (decision 15): any Portuguese gives Portuguese, otherwise defaults.language.
func language_for_locale(locale_language: String) -> String:
	return "pt" if locale_language == "pt" else Config.get_string("defaults.language")


## The player chose a language: it is used at once and saved.
func set_language(id: String) -> void:
	if not id in LANGUAGES:
		push_error("Settings: unknown language '%s'" % id)
		return
	_apply(id)
	_chosen_language = id
	_save()


## The player has seen the explanation of football.
func mark_football_help_seen() -> void:
	football_help_seen = true
	_save()


func _save() -> void:
	var data := {"football_help_seen": football_help_seen}
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
