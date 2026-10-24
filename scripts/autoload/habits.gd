extends Node
## Action log and daily habit scores (Milestone 3, Task 3).
## Every activity is logged with its type, the avatar time it started and the avatar
## hours actually done (Stop counts only the time done). The last log_days avatar days
## are kept. When a sleep ends, four habit scores (0 to 1) are worked out from the log,
## and then GameState updates the slow body states from them.
## All numbers come from Config (section health).

## Emitted when new habit scores were calculated (a sleep ended).
signal scores_updated

## Avatar hours since the start of the game (awake and asleep). The log uses it as its time line.
var avatar_hours_total := 0.0
## Log entries: {"type": option id, "start_total": avatar hours, "day": day number,
## "start_minute": time of day in minutes, "hours": avatar hours done}.
var entries: Array[Dictionary] = []
## Scores from the last sleep: sleep, activity, strength, screens. Empty before the first sleep.
var scores: Dictionary = {}
## Hours of the sleep that gave the scores.
var last_sleep_hours := 0.0

## The activity that is running now: type and where it started.
var _pending: Dictionary = {}


func _ready() -> void:
	Clock.avatar_time_passed.connect(_on_avatar_time_passed)
	Clock.day_started.connect(_on_day_started)
	Activities.started.connect(_on_activity_started)
	Activities.ended.connect(_on_activity_ended)


## New game: empty log, no scores.
func reset() -> void:
	avatar_hours_total = 0.0
	entries.clear()
	scores = {}
	last_sleep_hours = 0.0
	_pending = {}


func to_dict() -> Dictionary:
	return {
		"avatar_hours_total": avatar_hours_total,
		"entries": entries.duplicate(true),
		"scores": scores.duplicate(),
		"last_sleep_hours": last_sleep_hours,
		"pending": _pending.duplicate(),
	}


## Restores values from to_dict(). Call after Activities.from_dict().
func from_dict(data: Dictionary) -> void:
	reset()
	avatar_hours_total = float(data.get("avatar_hours_total", 0.0))
	for entry in data.get("entries", []):
		if entry is Dictionary:
			entries.append(entry)
	scores = data.get("scores", {}).duplicate()
	last_sleep_hours = float(data.get("last_sleep_hours", 0.0))
	var pending: Variant = data.get("pending", {})
	if Activities.is_running():
		# A save in the middle of an activity: keep where it started (if known).
		_pending = pending if pending is Dictionary and not pending.is_empty() else _new_pending(Activities.current_option)


## Adds one entry to the log (used when an activity ends, and by tests).
func add_entry(type: String, start_total: float, hours: float, day := 0, start_minute := 0.0) -> void:
	entries.append({"type": type, "start_total": start_total, "day": day, "start_minute": start_minute, "hours": hours})
	_prune()


## The four habit scores for a sleep of this many hours, from the log up to now:
## {"sleep", "activity", "strength", "screens"}, each 0 to 1.
func calculate_scores(sleep_hours: float, age_group: String) -> Dictionary:
	var day_hours := Config.get_float("health.log.avatar_day_hours")
	var activity_minutes := 0.0
	var screen_hours := 0.0
	var strength_days := {}
	var activity_types: Array = Config.get_value("health.log.activity_types")
	var strength_types: Array = Config.get_value("health.log.strength_types")
	var screen_types: Array = Config.get_value("health.log.screen_types")
	for entry in entries:
		var age: float = avatar_hours_total - float(entry["start_total"])
		var type: String = entry["type"]
		var hours: float = entry["hours"]
		if age < day_hours:  # Started in the last avatar day.
			if type in activity_types:
				activity_minutes += hours * Clock.MINUTES_PER_HOUR
			if type in screen_types:
				screen_hours += hours
		if type in strength_types and hours > 0.0 and age < Config.get_float("health.log.log_days") * day_hours:
			strength_days[floori(maxf(age, 0.0) / day_hours)] = true
	return {
		"sleep": sleep_score(sleep_hours, age_group),
		"activity": clampf(activity_minutes / Config.get_float("health.activity_target_min"), 0.0, 1.0),
		"strength": clampf(strength_days.size() / Config.get_float("health.strength_days_target"), 0.0, 1.0),
		"screens": screen_score(screen_hours),
	}


## 1 inside the recommended range for the age group; falls in a straight line to 0
## at sleep_zero_at_hours or less; falls slowly above the range.
func sleep_score(hours: float, age_group: String) -> float:
	var sleep_range := GameState.sleep_range(age_group)
	var low := sleep_range.x
	var high := sleep_range.y
	var zero_at := Config.get_float("health.sleep_zero_at")
	if hours < low:
		return clampf((hours - zero_at) / (low - zero_at), 0.0, 1.0)
	if hours > high:
		return clampf(1.0 - (hours - high) * Config.get_float("health.sleep_over_penalty_per_h"), 0.0, 1.0)
	return 1.0


## 1 up to screens_full_up_to_hours; falls in a straight line to 0 at screens_zero_at_hours.
func screen_score(hours: float) -> float:
	var full := Config.get_float("health.screens_full_until_h")
	var zero := Config.get_float("health.screens_zero_at_h")
	return clampf((zero - hours) / (zero - full), 0.0, 1.0)


func _on_avatar_time_passed(hours: float, _asleep: bool) -> void:
	avatar_hours_total += hours


func _on_activity_started(_activity_id: String, option_id: String) -> void:
	_pending = _new_pending(option_id)


func _new_pending(option_id: String) -> Dictionary:
	return {"type": option_id, "start_total": avatar_hours_total, "day": Clock.day_number,
			"start_minute": Clock.minute_of_day}


func _on_activity_ended(activity_id: String, _option_id: String, hours_done: float) -> void:
	if not _pending.is_empty() and hours_done > 0.0 and activity_id != "sleep":
		add_entry(_pending["type"], _pending["start_total"], hours_done, _pending["day"], _pending["start_minute"])
	_pending = {}
	if activity_id == "sleep":
		_score_sleep(hours_done)


## The awake period ran out without sleep: it counts as 0 hours slept.
func _on_day_started(slept: bool) -> void:
	if not slept:
		_score_sleep(0.0)


func _score_sleep(hours: float) -> void:
	_prune()
	last_sleep_hours = hours
	scores = calculate_scores(hours, GameState.age_group)
	# Then the slow body states change, once per avatar day.
	GameState.update_body_states(scores, hours)
	scores_updated.emit()


## Keeps only the last log_days avatar days.
func _prune() -> void:
	var limit := Config.get_float("health.log.log_days") * Config.get_float("health.log.avatar_day_hours")
	entries = entries.filter(func(entry: Dictionary) -> bool: return avatar_hours_total - float(entry["start_total"]) < limit)


func print_scores() -> void:
	print("--- Habit scores (sleep %.1f h) ---" % last_sleep_hours)
	for key in scores:
		print("%s = %.2f" % [key, scores[key]])
