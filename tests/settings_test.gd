extends SceneTree
## Tests for Settings (Milestone 11, Task 2). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/settings_test.gd
## The first-start rule (decision 15), a chosen language surviving a restart, and a new avatar
## leaving it alone. Uses a test file, so the real settings are never touched.

const TEST_PATH := "user://test_settings.json"

var _failures := 0


func _process(_delta: float) -> bool:
	var settings: Node = root.get_node("Settings")
	var game_state: Node = root.get_node("GameState")
	settings.settings_path = TEST_PATH
	settings.use_web_storage = false
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)

	_check("any Portuguese browser gives Portuguese", settings.language_for_locale("pt") == "pt")
	_check("another browser language gives English", settings.language_for_locale("fr") == "en"
			and settings.language_for_locale("en") == "en")
	settings.load_settings()
	_check("without a saved choice the game follows the system language",
			settings.language == settings.language_for_locale(OS.get_locale_language()))
	_check("...and nothing is saved", not FileAccess.file_exists(TEST_PATH))

	settings.set_language("pt")
	_check("a chosen language is used at once", settings.language == "pt" and TranslationServer.get_locale() == "pt")
	_check("...in the translations too", tr("FORMAT_DECIMAL_MARK") == ",")
	_check("...and it is saved", FileAccess.file_exists(TEST_PATH))
	settings.language = ""
	settings.load_settings()
	_check("a chosen language survives a restart", settings.language == "pt")
	settings.set_language("en")
	settings.load_settings()
	_check("changing it again survives a restart too", settings.language == "en" and tr("FORMAT_DECIMAL_MARK") == ".")
	settings.set_language("fr")
	_check("an unknown language is refused", settings.language == "en")

	settings.set_language("en")
	_check("numbers in English: decimal point", settings.number(0.849, 2) == "0.85" and settings.number(36.04, 1) == "36.0")
	_check("...with a sign when asked", settings.number(1.2, 2, true) == "+1.20" and settings.number(-1.2, 2, true) == "-1.20")
	settings.set_language("pt")
	_check("numbers in Portuguese: decimal comma", settings.number(0.849, 2) == "0,85" and settings.number(1.2, 2, true) == "+1,20")
	_check("...also a number written as text", settings.decimal_text("0.5") == "0,5")

	game_state.reset()
	game_state.start_new_avatar("Test", "child", "male", "normal")
	_check("a new avatar does not change the language", settings.language == "pt")
	_check("the language is not part of the avatar's save", not game_state.to_dict().has("language"))

	DirAccess.remove_absolute(TEST_PATH)
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
