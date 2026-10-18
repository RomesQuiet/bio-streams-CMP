extends Node
## Loads data/config.json and gives the rest of the game its tunable numbers.
## Usage: Config.get_value("time.day_baseline_hours")

const CONFIG_PATH := "res://data/config.json"

var _data: Dictionary = {}


func _init() -> void:
	load_config()


func load_config() -> void:
	var text := FileAccess.get_file_as_string(CONFIG_PATH)
	if text.is_empty():
		push_error("Config: could not read %s" % CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("Config: %s is not a valid JSON object" % CONFIG_PATH)
		return
	_data = parsed


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


## True if the entry at this path is marked "placeholder": true.
func is_placeholder(path: String) -> bool:
	var node: Variant = _data
	for key in path.split("."):
		if not node is Dictionary or not node.has(key):
			return false
		node = node[key]
	return node is Dictionary and node.get("placeholder", false)
