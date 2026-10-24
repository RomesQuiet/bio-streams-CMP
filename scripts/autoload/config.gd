extends Node
## Loads data/config.json and gives the rest of the game its tunable numbers.
## Usage: Config.get_value("time.day_baseline_hours")
## In debug builds, F6 reloads the file while the game runs, so a changed value is
## used from the next calculation on, without any code change.

const CONFIG_PATH := "res://data/config.json"

## Emitted after the config file was read again (F6).
signal reloaded

## The file that is read. Tests may point it at a copy.
var config_path := CONFIG_PATH
var _data: Dictionary = {}


func _init() -> void:
	load_config()


## Reads the config file. Returns false (and keeps the old values) if it cannot be read.
func load_config() -> bool:
	var text := FileAccess.get_file_as_string(config_path)
	if text.is_empty():
		push_error("Config: could not read %s" % config_path)
		return false
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("Config: %s is not a valid JSON object" % config_path)
		return false
	_data = parsed
	return true


## Reads the config file again and tells the game (debug key F6).
func reload() -> void:
	if load_config():
		print("Config: reloaded %s" % config_path)
		reloaded.emit()
		GameState.changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		reload()


## Returns the value at a dotted path such as "xp.per_level".
## Placeholder entries ({"value": ..., "placeholder": true}) return their "value".
func get_value(path: String) -> Variant:
	var node: Variant = _data
	for key in path.split("."):
		if not node is Dictionary or not node.has(key):
			push_error("Config: missing key '%s'" % path)
			return null
		node = node[key]
	if node is Dictionary and node.has("value"):
		return node["value"]
	return node


func get_float(path: String) -> float:
	var value: Variant = get_value(path)
	return float(value) if value != null else 0.0


func get_int(path: String) -> int:
	var value: Variant = get_value(path)
	return int(value) if value != null else 0


func get_string(path: String) -> String:
	var value: Variant = get_value(path)
	return str(value) if value != null else ""


## True if the entry at this path is marked "placeholder": true or "status": "placeholder".
func is_placeholder(path: String) -> bool:
	var node: Variant = _data
	for key in path.split("."):
		if not node is Dictionary or not node.has(key):
			return false
		node = node[key]
	return node is Dictionary and (node.get("placeholder", false) or node.get("status", "") == "placeholder")
