extends SceneTree
## Tests for the translations (Milestone 11, Task 9). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/translation_test.gd
## Every key has both languages with the same formats, every key used in the scenes, the scripts
## and activities.json exists, no key is unused, and no scene still holds plain text.

const CSV_PATH := "res://translations/strings.csv"
const SCENES: Array[String] = ["res://scenes/main.tscn", "res://scenes/ui/creation.tscn"]
const SCRIPTS: Array[String] = ["res://scripts/ui/main.gd", "res://scripts/ui/creation.gd", "res://scripts/autoload/settings.gd"]
const ACTIVITIES := "res://data/activities.json"
## Never translated: each language button shows its own name.
const NOT_TRANSLATED: Array[String] = ["Português", "English", "PT", "EN"]

var _failures := 0
## key -> [en, pt]
var _strings := {}
var _used := {}


func _process(_delta: float) -> bool:
	_read_csv()
	_check("the file holds the texts", _strings.size() > 50)
	_test_languages()
	_test_scenes()
	_test_scripts()
	_test_activities()
	var unused: Array = _strings.keys().filter(func(key: String) -> bool: return not _used.has(key))
	_check("every key is used %s" % [unused], unused.is_empty())
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _read_csv() -> void:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	var header := file.get_csv_line()
	_check("the columns are keys, en, pt", Array(header) == ["keys", "en", "pt"])
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() == 3:
			_check("%s is only once in the file" % line[0], not _strings.has(line[0]))
			_strings[line[0]] = [line[1], line[2]]


func _test_languages() -> void:
	var formats := RegEx.create_from_string("%[+-]?[0-9.]*[dsf]")
	for key: String in _strings:
		var en: String = _strings[key][0]
		var pt: String = _strings[key][1]
		if en.is_empty() or pt.is_empty():
			_check("%s has both languages" % key, false)
		var en_formats := formats.search_all(en).map(func(found: RegExMatch) -> String: return found.get_string())
		var pt_formats := formats.search_all(pt).map(func(found: RegExMatch) -> String: return found.get_string())
		if en_formats != pt_formats:
			_check("%s has the same formats in both languages" % key, false)
	_check("every key was checked for both languages and their formats", true)
	for id in [["en", "UI_STOP", "Stop"], ["pt", "UI_STOP", "Parar"]]:
		TranslationServer.set_locale(id[0])
		_check("the imported file gives the %s text (run --import after changing the CSV)" % id[0],
				TranslationServer.translate(id[1]) == id[2])
	for key: String in _strings:
		TranslationServer.set_locale("pt")
		if TranslationServer.translate(key) != _strings[key][1].c_unescape():
			_check("%s in the imported file matches the CSV" % key, false)
	TranslationServer.set_locale("en")


## A text in a scene is a key, holds no letters (a number), or is a language's own name.
func _test_scenes() -> void:
	var texts := RegEx.create_from_string("(?m)^(?:text|tooltip_text|placeholder_text) = \"([^\"]*)\"")
	var letters := RegEx.create_from_string("[A-Za-z]")
	for path in SCENES:
		var plain: Array[String] = []
		for found in texts.search_all(FileAccess.get_file_as_string(path)):
			var text := found.get_string(1)
			if _strings.has(text):
				_used[text] = true
			elif letters.search(text) != null and not text in NOT_TRANSLATED:
				plain.append(text)
		_check("%s holds no plain text %s" % [path, plain], plain.is_empty())


func _test_scripts() -> void:
	var keys := RegEx.create_from_string("\"((?:UI|SPEECH|CREATION|ACTIVITY|MEASURE|FAILURE|SETTINGS|SLEEP|FORMAT|MINIGAME)_[A-Z_]+)\"")
	for path in SCRIPTS:
		var missing: Array[String] = []
		for found in keys.search_all(FileAccess.get_file_as_string(path)):
			var key := found.get_string(1)
			_used[key] = true
			if not _strings.has(key):
				missing.append(key)
		_check("every key in %s exists %s" % [path, missing], missing.is_empty())


func _test_activities() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ACTIVITIES))
	var missing: Array[String] = []
	for activity_id: String in data:
		if activity_id.begins_with("_"):
			continue
		var names: Array = [data[activity_id]["name"]]
		for option_id: String in data[activity_id]["options"]:
			names.append(data[activity_id]["options"][option_id]["name"])
		for key: String in names:
			_used[key] = true
			if not _strings.has(key):
				missing.append(key)
	_check("every activity name is a key %s" % [missing], missing.is_empty())


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
