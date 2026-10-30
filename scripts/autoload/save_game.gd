extends Node
## Saves and loads the game on this device. Kept apart from Clock and GameState,
## so a server can replace this script later without changing the rest.
##
## Saves to user://save.json. In the web build the browser keeps user:// in
## IndexedDB, but writing it finishes a moment later, which can be too late when
## the tab closes. So the web build also keeps a copy in localStorage, which is
## written at once. On load, the newest of the two copies is used.

const SAVE_PATH := "user://save.json"
const WEB_STORAGE_KEY := "plasticine_tamagotchi_save"
## Version of the save format. A save with another version is ignored and the creation
## screen opens. 2 = Milestone 10 (Health Calculation Architecture v1): saves from Milestone 4
## or earlier (version 1) do not load (decision 6, user, 25 Oct 2026).
const SAVE_VERSION := 2

## Where the file is saved. Tests change this so they never touch the real save.
var save_path := SAVE_PATH
var use_web_storage := OS.has_feature("web")
## When false, nothing is saved automatically (key moments, timer, closing). Tests turn it off.
var auto_save_enabled := true

## Goes up by one with every save, so the newest copy can be found
## without reading the device clock.
var _save_count := 0
var _ready_done := false
## Kept so the browser callback is not freed while the page is open.
var _page_event_callback: JavaScriptObject


func _ready() -> void:
	var loaded := load_game()
	if loaded and Config.get_value("save.resume_paused") and Clock.phase == Clock.Phase.DAY:
		Clock.set_paused(true)

	# Key moments: every phase change (sleep start, sleep end, wake), every new day,
	# pause, and the start and end of every activity.
	Clock.phase_changed.connect(_auto_save.unbind(1))
	Clock.day_started.connect(_auto_save.unbind(1))
	Clock.paused_changed.connect(_auto_save.unbind(1))
	Activities.started.connect(_auto_save.unbind(2))
	Activities.ended.connect(_auto_save.unbind(3))

	var autosave := Timer.new()
	autosave.wait_time = Config.get_float("save.autosave_real_seconds")
	autosave.timeout.connect(_auto_save)
	add_child(autosave)
	autosave.start()

	if use_web_storage:
		_connect_page_events()
	_ready_done = true


func _notification(what: int) -> void:
	if not _ready_done:
		return
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_auto_save()


func _unhandled_input(event: InputEvent) -> void:
	# Debug only (editor): F8 deletes the save and starts a new game.
	if not OS.has_feature("editor"):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		delete_save()
		print("SaveGame: save deleted, new game started")
		# Reloading the main screen opens the avatar creation screen.
		get_tree().reload_current_scene()


## Nothing is saved before the avatar is created, so an old save stays until then.
func _auto_save() -> void:
	if auto_save_enabled and GameState.is_created():
		save_game()


func save_game() -> void:
	_save_count += 1
	var data := {
		"version": SAVE_VERSION,
		"save_count": _save_count,
		"game_state": GameState.to_dict(),
		"clock": Clock.to_dict(),
		"activities": Activities.to_dict(),
		"habits": Habits.to_dict(),
		"simulation": Simulation.to_dict(),
	}
	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveGame: could not write %s (error %d)" % [save_path, FileAccess.get_open_error()])
	else:
		file.store_string(text)
		file.close()
	if use_web_storage:
		JavaScriptBridge.eval("try { localStorage.setItem(%s, %s); } catch (e) {}" % [
			JSON.stringify(WEB_STORAGE_KEY), JSON.stringify(text)])


## Loads the newest saved copy. Returns false if there is no valid save.
func load_game() -> bool:
	var best: Dictionary = {}
	for text in [_read_file(), _read_web_storage()]:
		var data := _parse(text)
		if not data.is_empty() and int(data.get("save_count", 0)) > int(best.get("save_count", -1)):
			best = data
	if best.is_empty():
		return false
	_save_count = int(best["save_count"])
	# Nothing pending while the Clock is restored (its phase change would run it), and no
	# new day or activity start is run again while the save is restored.
	Simulation.reset()
	Simulation.loading = true
	GameState.from_dict(best.get("game_state", {}))
	Clock.from_dict(best.get("clock", {}))
	Activities.from_dict(best.get("activities", {}))
	Habits.from_dict(best.get("habits", {}))
	Simulation.from_dict(best.get("simulation", {}))
	Simulation.loading = false
	return true


## Removes the save and starts a new game.
func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		# On the web, removing a file alone does not reach the browser's storage: only closing a
		# written file makes Godot sync it, and the old save would come back after a reload.
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		if file != null:
			file.close()
		DirAccess.remove_absolute(save_path)
	if use_web_storage:
		JavaScriptBridge.eval("try { localStorage.removeItem(%s); } catch (e) {}" % JSON.stringify(WEB_STORAGE_KEY))
	_save_count = 0
	Activities.reset()
	Habits.reset()
	Simulation.reset()
	GameState.reset()
	Clock.reset()


func _read_file() -> String:
	if not FileAccess.file_exists(save_path):
		return ""
	return FileAccess.get_file_as_string(save_path)


func _read_web_storage() -> String:
	if not use_web_storage:
		return ""
	var value: Variant = JavaScriptBridge.eval(
		"(function () { try { return localStorage.getItem(%s) || ''; } catch (e) { return ''; } })()"
		% JSON.stringify(WEB_STORAGE_KEY))
	return value if value is String else ""


## Returns the save data, or an empty Dictionary if the text is not a valid save.
func _parse(text: String) -> Dictionary:
	if text.is_empty():
		return {}
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	if not parsed is Dictionary:
		push_warning("SaveGame: ignoring a save that is not valid JSON")
		return {}
	if int(parsed.get("version", 0)) != SAVE_VERSION:
		push_warning("SaveGame: ignoring a save from another version of the game (an old save from Milestone 4 or earlier, or a newer one)")
		return {}
	var state: Variant = parsed.get("game_state", {})
	if not state is Dictionary or not GameState.has_all_choices(state):
		# Saves from Milestones 1 and 2 have no age group, sex or difficulty:
		# the player starts a new game on the creation screen.
		push_warning("SaveGame: ignoring a save without the avatar creation choices")
		return {}
	return parsed


## Web only: save when the tab is hidden or closed.
func _connect_page_events() -> void:
	_page_event_callback = JavaScriptBridge.create_callback(_on_page_event)
	var window := JavaScriptBridge.get_interface("window")
	var document := JavaScriptBridge.get_interface("document")
	document.addEventListener("visibilitychange", _page_event_callback)
	window.addEventListener("pagehide", _page_event_callback)
	window.addEventListener("beforeunload", _page_event_callback)


func _on_page_event(_args: Array) -> void:
	_auto_save()
