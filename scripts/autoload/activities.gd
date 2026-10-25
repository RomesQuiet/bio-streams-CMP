extends Node
## Runs activities (sleep, exercise, entertainment) from data/activities.json.
## Only one activity runs at a time. Effects are applied per avatar hour as the
## Clock moves, so stopping early only counts the time actually done.
## Sleep uses the Clock's sleep time; every other activity uses day time.

const ACTIVITIES_PATH := "res://data/activities.json"

signal started(activity_id: String, option_id: String)
signal ended(activity_id: String, option_id: String, hours_done: float)
## Emitted just before an activity starts or ends, while the old one (or none) still counts,
## so Simulation can first run the minutes that belong to it.
signal changing
## Emitted while an activity runs, after its effects for that frame are applied.
signal progressed

## All activity definitions, by id. Tests may add their own.
var definitions: Dictionary = {}
var current_activity := ""
var current_option := ""
var target_hours := 0.0
var elapsed_hours := 0.0


func _init() -> void:
	_load_definitions()


func _ready() -> void:
	Clock.avatar_time_passed.connect(_on_avatar_time_passed)
	Clock.phase_changed.connect(_on_phase_changed)


func is_running() -> bool:
	return not current_activity.is_empty()


func get_option(activity_id: String, option_id: String) -> Dictionary:
	return definitions.get(activity_id, {}).get("options", {}).get(option_id, {})


func current_option_data() -> Dictionary:
	return get_option(current_activity, current_option)


## The option with this id in any activity (for example "cardio"), or {} if there is none.
func find_option(option_id: String) -> Dictionary:
	for activity_id in definitions:
		var options: Dictionary = definitions[activity_id].get("options", {})
		if options.has(option_id):
			return options[option_id]
	return {}


## A value of an option that may be written as {"value": ..., "status": ..., "owner": ...}.
## Returns default when the option does not have it.
func option_value(option: Dictionary, key: String, default: Variant = null) -> Variant:
	var entry: Variant = option.get(key, default)
	return entry["value"] if entry is Dictionary and entry.has("value") else entry


func uses_sleep_time(activity_id: String) -> bool:
	return bool(definitions.get(activity_id, {}).get("uses_sleep_time", false))


## Whether this activity can start now.
func can_start(activity_id: String) -> bool:
	if is_running() or not definitions.has(activity_id):
		return false
	if uses_sleep_time(activity_id):
		return Clock.can_start_sleep()
	return Clock.phase == Clock.Phase.DAY


## Starts an activity option. hours is used when the option's duration is "slider".
## Returns false if it could not start.
func start(activity_id: String, option_id: String, hours := -1.0) -> bool:
	var option := get_option(activity_id, option_id)
	if option.is_empty() or not can_start(activity_id):
		return false
	var duration: Variant = option.get("duration_hours")
	target_hours = hours if duration is String else float(duration)
	elapsed_hours = 0.0
	changing.emit()
	current_activity = activity_id
	current_option = option_id
	started.emit(activity_id, option_id)
	if uses_sleep_time(activity_id):
		Clock.start_sleep(target_hours)
		if Clock.phase != Clock.Phase.SLEEPING and Clock.phase != Clock.Phase.SLEEP_OVER:
			_end()
			return false
	else:
		Clock.set_paused(false)
	return true


## Ends the running activity early. Effects already applied are kept.
func stop() -> void:
	if not is_running():
		return
	if uses_sleep_time(current_activity):
		Clock.stop_sleep()  # The phase change then ends the activity.
	else:
		_end()


## No activity running (new game).
func reset() -> void:
	current_activity = ""
	current_option = ""
	target_hours = 0.0
	elapsed_hours = 0.0


func to_dict() -> Dictionary:
	return {
		"activity": current_activity,
		"option": current_option,
		"target_hours": target_hours,
		"elapsed_hours": elapsed_hours,
	}


## Restores values from to_dict(). Call after Clock.from_dict().
func from_dict(data: Dictionary) -> void:
	reset()
	if data.is_empty() and Clock.phase == Clock.Phase.SLEEPING:
		# Save from Milestone 1 (before activities existed): the avatar was asleep.
		data = {
			"activity": "sleep",
			"option": "sleep",
			"target_hours": Clock.sleep_target_hours,
			"elapsed_hours": Clock.sleep_elapsed_hours,
		}
	var activity_id := str(data.get("activity", ""))
	var option_id := str(data.get("option", ""))
	if get_option(activity_id, option_id).is_empty():
		return
	current_activity = activity_id
	current_option = option_id
	target_hours = float(data.get("target_hours", 0.0))
	elapsed_hours = float(data.get("elapsed_hours", 0.0))
	started.emit(current_activity, current_option)


func _on_avatar_time_passed(hours: float, asleep: bool) -> void:
	if not is_running() or asleep != uses_sleep_time(current_activity):
		return
	var done := minf(hours, target_hours - elapsed_hours)
	if done > 0.0:
		elapsed_hours += done
		var option := current_option_data()
		GameState.apply_effects(option.get("effects_per_hour", {}), done)
		# The calories-spent record comes from the energy spent in each step (Simulation).
	progressed.emit()
	if not uses_sleep_time(current_activity) and elapsed_hours >= target_hours:
		_end()


func _on_phase_changed(phase: Clock.Phase) -> void:
	if not is_running():
		return
	var needed_phase := Clock.Phase.SLEEPING if uses_sleep_time(current_activity) else Clock.Phase.DAY
	if phase != needed_phase:
		_end()


func _end() -> void:
	var activity_id := current_activity
	var option_id := current_option
	var hours_done := elapsed_hours
	changing.emit()
	reset()
	ended.emit(activity_id, option_id, hours_done)


func _load_definitions() -> void:
	var text := FileAccess.get_file_as_string(ACTIVITIES_PATH)
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if not parsed is Dictionary:
		push_error("Activities: could not read %s" % ACTIVITIES_PATH)
		return
	for key in parsed:
		if not str(key).begins_with("_"):
			definitions[key] = parsed[key]
