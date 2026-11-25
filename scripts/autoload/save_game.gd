extends Node
## Saves and loads the game on this device. Kept apart from Clock and GameState,
## so a server can replace this script later without changing the rest.
##
## Saves to user://save.json. In the web build the browser keeps user:// in
## IndexedDB, but writing it finishes a moment later, which can be too late when
## the tab closes. So the web build also keeps a copy in localStorage, which is
## written at once. On load, the newest of the two copies is used.
##
## Deleting has the same problem the other way round: after a reload the browser can still
## give back the deleted file. So delete_save() writes down the last save number in
## localStorage, at once, and any copy that is not newer than it is ignored.
##
## Milestone 18 (main menu): save.slots places for avatars. Place 0 keeps the old file and keys
## (user://save.json), so an existing save becomes the first avatar; place n uses
## user://save_<n + 1>.json and keys ending in _<n + 1>. Nothing loads by itself any more: the
## main menu chooses a place (play_slot) or makes a new avatar in a free one (start_slot).
## A backup is the save's own text, downloaded as a file and loaded into a free place.

const SAVE_PATH := "user://save.json"
const WEB_STORAGE_KEY := "plasticine_tamagotchi_save"
const WEB_DELETED_KEY := "plasticine_tamagotchi_deleted_save"
## Version of the save format. A save with another version is ignored and the creation
## screen opens. 2 = Milestone 10 (Health Calculation Architecture v1): saves from Milestone 4
## or earlier (version 1) do not load (decision 6, user, 25 Oct 2026).
const SAVE_VERSION := 2

## Where the file is saved. Tests change this so they never touch the real save.
var save_path := SAVE_PATH
## The avatar place in use (0 to save.slots - 1), and its browser keys.
var slot := 0
var _web_key := WEB_STORAGE_KEY
var _web_deleted_key := WEB_DELETED_KEY
## What the main menu should do when it opens ("new_avatar" after a failure), then cleared.
var menu_request := ""
var use_web_storage := OS.has_feature("web")
## When false, nothing is saved automatically (key moments, timer, closing). Tests turn it off.
var auto_save_enabled := true

## Goes up by one with every save, so the newest copy can be found
## without reading the device clock.
var _save_count := 0
## Saves up to this number were deleted (web only; "Start a new avatar").
var _deleted_count := 0
var _ready_done := false
## Kept so the browser callback is not freed while the page is open.
var _page_event_callback: JavaScriptObject


func _ready() -> void:
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
		_ask_persistent_storage()
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
	var text := current_text()
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveGame: could not write %s (error %d)" % [save_path, FileAccess.get_open_error()])
	else:
		file.store_string(text)
		file.close()
	if use_web_storage:
		JavaScriptBridge.eval("try { localStorage.setItem(%s, %s); } catch (e) {}" % [
			JSON.stringify(_web_key), JSON.stringify(text)])


## The avatar being played, as a save file's text, from the game itself and not from storage
## (25 Nov 2026: in a browser that keeps no site data, such as Brave with all cookies blocked,
## this is the only copy). The same format as a backup, so Load a backup reads it.
func current_text() -> String:
	var data := {
		"version": SAVE_VERSION,
		"save_count": _save_count,
		"game_state": GameState.to_dict(),
		"clock": Clock.to_dict(),
		"activities": Activities.to_dict(),
		"minigame": Minigame.to_dict(),
		"habits": Habits.to_dict(),
		"simulation": Simulation.to_dict(),
	}
	return JSON.stringify(data, "\t")


## Loads the newest saved copy. Returns false if there is no valid save.
func load_game() -> bool:
	if use_web_storage:
		_deleted_count = _read_deleted_count()
	# New saves must count on from the deleted ones, or they would be ignored too.
	_save_count = maxi(_save_count, _deleted_count)
	var best: Dictionary = {}
	for text in [_read_file(), _read_web_storage()]:
		var data := _parse(text)
		var count := int(data.get("save_count", 0))
		if not data.is_empty() and count > _deleted_count and count > int(best.get("save_count", -1)):
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
	Minigame.from_dict(best.get("minigame", {}))
	Habits.from_dict(best.get("habits", {}))
	Simulation.from_dict(best.get("simulation", {}))
	Simulation.loading = false
	return true


## Removes the save and starts a new game.
func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	_deleted_count = _save_count
	if use_web_storage:
		JavaScriptBridge.eval("try { localStorage.removeItem(%s); localStorage.setItem(%s, %s); } catch (e) {}" % [
			JSON.stringify(_web_key), JSON.stringify(_web_deleted_key), JSON.stringify(str(_deleted_count))])
	Activities.reset()
	Minigame.reset()
	Habits.reset()
	Simulation.reset()
	GameState.reset()
	Clock.reset()


func _read_file(path := "") -> String:
	path = save_path if path.is_empty() else path
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _read_deleted_count(key := "") -> int:
	if not use_web_storage:
		return 0
	var value: Variant = JavaScriptBridge.eval(
		"(function () { try { return localStorage.getItem(%s) || '0'; } catch (e) { return '0'; } })()"
		% JSON.stringify(_web_deleted_key if key.is_empty() else key))
	return int(value) if value is String else 0


func _read_web_storage(key := "") -> String:
	if not use_web_storage:
		return ""
	var value: Variant = JavaScriptBridge.eval(
		"(function () { try { return localStorage.getItem(%s) || ''; } catch (e) { return ''; } })()"
		% JSON.stringify(_web_key if key.is_empty() else key))
	return value if value is String else ""


# --- Avatar places (Milestone 18) ------------------------------------------------------------

func slot_count() -> int:
	return Config.get_int("save.slots")


func path_for(place: int) -> String:
	return SAVE_PATH if place == 0 else "user://save_%d.json" % (place + 1)


func _key_suffix(place: int) -> String:
	return "" if place == 0 else "_%d" % (place + 1)


## Uses this place for saving and loading from now on (nothing is loaded).
func select_slot(place: int) -> void:
	slot = place
	save_path = path_for(place)
	_web_key = WEB_STORAGE_KEY + _key_suffix(place)
	_web_deleted_key = WEB_DELETED_KEY + _key_suffix(place)
	_save_count = 0
	_deleted_count = 0


## The newest valid save of a place, without loading it: {} when the place is empty.
func slot_data(place: int) -> Dictionary:
	var deleted := _read_deleted_count(WEB_DELETED_KEY + _key_suffix(place))
	var best: Dictionary = {}
	for text in [_read_file(path_for(place)), _read_web_storage(WEB_STORAGE_KEY + _key_suffix(place))]:
		var data := _parse(text)
		var count := int(data.get("save_count", 0))
		if not data.is_empty() and count > deleted and count > int(best.get("save_count", -1)):
			best = data
	return best


## The avatar of a place, for the menu's cards: its GameState values, or {} when empty.
func slot_summary(place: int) -> Dictionary:
	return slot_data(place).get("game_state", {})


## The first place without an avatar, or -1 when all are taken.
func first_free_slot() -> int:
	for place in slot_count():
		if slot_summary(place).is_empty():
			return place
	return -1


## Back to the menu: the game is emptied and time stops (the avatar is saved first).
func unload() -> void:
	if GameState.is_created():
		save_game()
	Activities.reset()
	Minigame.reset()
	Habits.reset()
	Simulation.reset()
	GameState.reset()
	Clock.reset()
	Clock.halted = true


## Loads the avatar of a place to play it. False if the place is empty.
func play_slot(place: int) -> bool:
	unload()
	select_slot(place)
	if not load_game():
		return false
	Clock.halted = false
	if Config.get_value("save.resume_paused") and Clock.phase == Clock.Phase.DAY:
		Clock.set_paused(true)
	Settings.set_last_slot(place)
	return true


## A new avatar in this place: an empty game that runs; the creation screen fills it.
func start_slot(place: int) -> void:
	unload()
	select_slot(place)
	Clock.halted = false
	Settings.set_last_slot(place)


## Deletes the avatar of a place for good.
func delete_slot(place: int) -> void:
	unload()
	select_slot(place)
	delete_save()
	Clock.halted = true


## A backup: the place's save as text ("" when empty).
func backup_text(place: int) -> String:
	var data := slot_data(place)
	return "" if data.is_empty() else JSON.stringify(data, "\t")


## Loads a backup into a place. False if the text is not a valid save of this version.
func restore_backup(text: String, place: int) -> bool:
	var data := _parse(text)
	if data.is_empty():
		return false
	var previous := slot
	unload()
	select_slot(place)
	# Newer than anything deleted from this place, so it is never ignored.
	data["save_count"] = _read_deleted_count() + 1
	var saved := JSON.stringify(data, "\t")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(saved)
		file.close()
	if use_web_storage:
		JavaScriptBridge.eval("try { localStorage.setItem(%s, %s); } catch (e) {}" % [
			JSON.stringify(_web_key), JSON.stringify(saved)])
	select_slot(previous)
	Clock.halted = true
	return true


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


## Web only (user, 22 Nov 2026): asks the browser to keep this site's data (the saves in
## localStorage and IndexedDB) instead of clearing it by itself when space is short or the site
## has not been visited for a while (Safari on iPhones clears script-written data after about 7
## days without a visit, unless the storage is persistent). Chrome and Edge decide alone, Firefox
## may ask the player, and a browser without the feature is skipped. Nothing waits for the answer.
func _ask_persistent_storage() -> void:
	JavaScriptBridge.eval("try { if (navigator.storage && navigator.storage.persist) { navigator.storage.persist(); } } catch (e) {}")


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
