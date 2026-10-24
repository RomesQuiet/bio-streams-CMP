extends Node
## Action log, scoring days and daily habit scores (Milestone 3 Task 3, Milestone 4 Task 2).
## Every activity (and every sleep) is logged with its type, the avatar time it started,
## the avatar hours actually done (Stop counts only the time done), its intensity and its
## calories. A scoring day follows health.score_window: "wake_to_wake" = from one wake-up
## to the next, so it closes when any sleep ends (a night, a nap, or the 0-hour rule).
## Then the totals of that scoring day give four habit scores (0 to 1), and GameState
## updates the slow body states from them. The last log_days scoring days are kept.
## All numbers come from Config (section health).

## Emitted when new habit scores were calculated (a scoring day closed).
signal scores_updated

## The only scoring window built so far.
const WAKE_TO_WAKE := "wake_to_wake"

## Avatar hours since the start of the game (awake and asleep). Start times use it.
var avatar_hours_total := 0.0
## Number of the scoring day that is running now (the first one is 0).
var current_day := 0
## Log entries: {"type": option id, "scoring_day": number, "start_total": avatar hours,
## "day": clock day number, "start_minute": time of day in minutes, "hours": avatar hours done,
## "intensity": activity_intensity from activities.json ("" if none), "kcal": calories spent}.
var entries: Array[Dictionary] = []
## Totals of the closed scoring days (see day_totals()), oldest first. The last log_days are kept.
var days: Array[Dictionary] = []
## Scores from the last closed scoring day: sleep, activity, strength, screens. Empty before the first sleep.
var scores: Dictionary = {}
## Hours of the sleep that closed the last scoring day.
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
	current_day = 0
	entries.clear()
	days.clear()
	scores = {}
	last_sleep_hours = 0.0
	_pending = {}


func to_dict() -> Dictionary:
	return {
		"avatar_hours_total": avatar_hours_total,
		"current_day": current_day,
		"entries": entries.duplicate(true),
		"days": days.duplicate(true),
		"scores": scores.duplicate(),
		"last_sleep_hours": last_sleep_hours,
		"pending": _pending.duplicate(),
	}


## Restores values from to_dict(). Call after Activities.from_dict().
## Entries from a Milestone 3 save have no scoring day: they count in the current one.
func from_dict(data: Dictionary) -> void:
	reset()
	avatar_hours_total = float(data.get("avatar_hours_total", 0.0))
	current_day = int(data.get("current_day", 0))
	for entry in data.get("entries", []):
		if entry is Dictionary:
			var restored: Dictionary = entry.duplicate()
			restored["scoring_day"] = int(restored.get("scoring_day", current_day))
			var option := Activities.find_option(str(restored.get("type", "")))
			restored["intensity"] = str(restored.get("intensity", Activities.option_value(option, "activity_intensity", "")))
			restored["kcal"] = float(restored.get("kcal", float(Activities.option_value(option, "kcal_per_hour", 0.0)) * float(restored.get("hours", 0.0))))
			entries.append(restored)
	for day in data.get("days", []):
		if day is Dictionary:
			days.append(day)
	scores = data.get("scores", {}).duplicate()
	last_sleep_hours = float(data.get("last_sleep_hours", 0.0))
	var pending: Variant = data.get("pending", {})
	if Activities.is_running():
		# A save in the middle of an activity: keep where it started (if known).
		_pending = pending if pending is Dictionary and not pending.is_empty() else _new_pending(Activities.current_option)


## Adds one entry to the current scoring day. Intensity and calories come from the
## activity option in activities.json. start: {"start_total", "day", "start_minute"}
## (where the activity started); empty = now. Used when an activity ends, and by tests.
func add_entry(type: String, hours: float, start: Dictionary = {}) -> void:
	var option := Activities.find_option(type)
	entries.append({
		"type": type,
		"scoring_day": current_day,
		"start_total": float(start.get("start_total", avatar_hours_total)),
		"day": int(start.get("day", Clock.day_number)),
		"start_minute": float(start.get("start_minute", Clock.minute_of_day)),
		"hours": hours,
		"intensity": str(Activities.option_value(option, "activity_intensity", "")),
		"kcal": float(Activities.option_value(option, "kcal_per_hour", 0.0)) * hours,
	})


## Totals of one scoring day: sleep hours, moderate-to-vigorous activity minutes,
## strength days in the last log_days scoring days (this one included), entertainment
## hours, recreational screen hours and calories.
func day_totals(day: int) -> Dictionary:
	var totals := {"scoring_day": day, "sleep_hours": 0.0, "activity_minutes": 0.0, "strength_days": 0,
			"entertainment_hours": 0.0, "screen_hours": 0.0, "kcal": 0.0}
	var sleep_types: Array = Config.get_value("health.log.sleep_types")
	var activity_intensities: Array = Config.get_value("health.log.activity_intensities")
	var strength_types: Array = Config.get_value("health.log.strength_types")
	var entertainment_types: Array = Config.get_value("health.log.entertainment_types")
	var screen_types: Array = Config.get_value("health.log.screen_types")
	var oldest_day := day - Config.get_int("health.log.log_days") + 1
	var strength_days := {}
	for entry in entries:
		var entry_day: int = entry["scoring_day"]
		var type: String = entry["type"]
		var hours: float = entry["hours"]
		if type in strength_types and hours > 0.0 and entry_day >= oldest_day and entry_day <= day:
			strength_days[entry_day] = true
		if entry_day != day:
			continue
		if type in sleep_types:
			totals["sleep_hours"] += hours
		if entry["intensity"] in activity_intensities:
			totals["activity_minutes"] += hours * Clock.MINUTES_PER_HOUR
		if type in entertainment_types:
			totals["entertainment_hours"] += hours
		if type in screen_types:
			totals["screen_hours"] += hours
		totals["kcal"] += float(entry["kcal"])
	totals["strength_days"] = strength_days.size()
	return totals


## The four habit scores of a scoring day's totals: {"sleep", "activity", "strength",
## "screens"}, each 0 to 1.
func calculate_scores(totals: Dictionary, age_group: String) -> Dictionary:
	return {
		"sleep": sleep_score(totals["sleep_hours"], age_group),
		"activity": clampf(totals["activity_minutes"] / Config.get_float("health.activity_target_min"), 0.0, 1.0),
		"strength": clampf(totals["strength_days"] / Config.get_float("health.strength_days_target"), 0.0, 1.0),
		"screens": screen_score(totals["screen_hours"]),
	}


## Closes the current scoring day after a sleep of this many hours (0 for the 0-hour
## rule): logs the sleep, works out the scores, updates the body states and starts the
## next scoring day. start: where the sleep started (empty = now).
func end_scoring_day(sleep_hours: float, start: Dictionary = {}) -> void:
	if Config.get_string("health.score_window") != WAKE_TO_WAKE:
		push_error("Habits: score_window '%s' is not built; using %s" % [Config.get_string("health.score_window"), WAKE_TO_WAKE])
	if sleep_hours > 0.0:
		add_entry(Config.get_value("health.log.sleep_types")[0], sleep_hours, start)
	var totals := day_totals(current_day)
	days.append(totals)
	last_sleep_hours = sleep_hours
	scores = calculate_scores(totals, GameState.age_group)
	# Then the slow body states change, once per scoring day.
	GameState.update_body_states(scores, sleep_hours)
	current_day += 1
	_prune()
	scores_updated.emit()


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
	var start := _pending
	_pending = {}
	if Activities.uses_sleep_time(activity_id):
		end_scoring_day(hours_done, start)
	elif hours_done > 0.0:
		add_entry(str(start.get("type", _option_id)), hours_done, start)


## The awake period ran out without sleep: it counts as 0 hours slept.
func _on_day_started(slept: bool) -> void:
	if not slept:
		end_scoring_day(0.0)


## Keeps only the last log_days scoring days (entries and totals).
func _prune() -> void:
	var oldest_day := current_day - Config.get_int("health.log.log_days") + 1
	entries = entries.filter(func(entry: Dictionary) -> bool: return entry["scoring_day"] >= oldest_day)
	days = days.filter(func(day: Dictionary) -> bool: return day["scoring_day"] >= oldest_day - 1)


func print_scores() -> void:
	print("--- Habit scores (sleep %.1f h) ---" % last_sleep_hours)
	for key in scores:
		print("%s = %.2f" % [key, scores[key]])
