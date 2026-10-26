extends Node
## Action log and avatar days (Milestone 3 Task 3, Milestone 4 Task 2, Milestone 10).
## Every activity (and every sleep) is logged with its type, the avatar time it started,
## the avatar hours actually done (Stop counts only the time done), its intensity, its
## calories and, for a meal, the kcal eaten. An avatar day runs from one wake-up to the
## next, so it closes when any sleep ends (a night, a nap, or the 0-hour rule); then its
## totals are kept and GameState.daily_update() runs. The last log_days days are kept.
## The Milestone 4 habit scores were removed in Milestone 10 Task 7.
## All numbers come from Config.

## Emitted when an avatar day closed (after any sleep, or the 0-hour rule).
signal day_closed

const Hunger := preload("res://scripts/health/hunger.gd")
const Energy := preload("res://scripts/health/energy.gd")

## Avatar hours since the start of the game (awake and asleep). Start times use it.
var avatar_hours_total := 0.0
## Number of the scoring day that is running now (the first one is 0).
var current_day := 0
## Log entries: {"type": option id, "scoring_day": number, "start_total": avatar hours,
## "day": clock day number, "start_minute": time of day in minutes, "hours": avatar hours done,
## "intensity": activity_intensity from activities.json ("" if none), "kcal": calories spent (BMR / 24 x mety x hours),
## "kcal_eaten": kcal of a meal (Milestone 10; 0 for other activities)}.
var entries: Array[Dictionary] = []
## Totals of the closed scoring days (see day_totals()), oldest first. The last log_days are kept.
var days: Array[Dictionary] = []

## The activity that is running now: type and where it started.
var _pending: Dictionary = {}


func _ready() -> void:
	Clock.avatar_time_passed.connect(_on_avatar_time_passed)
	Clock.day_started.connect(_on_day_started)
	Activities.started.connect(_on_activity_started)
	Activities.ended.connect(_on_activity_ended)


## New game: empty log.
func reset() -> void:
	avatar_hours_total = 0.0
	current_day = 0
	entries.clear()
	days.clear()
	_pending = {}


func to_dict() -> Dictionary:
	return {
		"avatar_hours_total": avatar_hours_total,
		"current_day": current_day,
		"entries": entries.duplicate(true),
		"days": days.duplicate(true),
		"pending": _pending.duplicate(),
	}


## Restores values from to_dict(). Call after Activities.from_dict().
func from_dict(data: Dictionary) -> void:
	reset()
	avatar_hours_total = float(data.get("avatar_hours_total", 0.0))
	current_day = int(data.get("current_day", 0))
	for entry in data.get("entries", []):
		if entry is Dictionary:
			var restored: Dictionary = entry.duplicate()
			# JSON reads every number as a decimal; the scoring day and the clock day are whole numbers.
			restored["scoring_day"] = int(restored.get("scoring_day", current_day))
			restored["day"] = int(restored.get("day", 0))
			entries.append(restored)
	for day in data.get("days", []):
		if day is Dictionary:
			days.append(day)
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
		"kcal": _kcal_spent(option, hours),
		"kcal_eaten": _meal_kcal(type, hours, option),
	})


## kcal spent in an activity of this many hours: BMR / 24 x its mety (Milestone 10).
func _kcal_spent(option: Dictionary, hours: float) -> float:
	var gs := GameState
	var mety := float(Activities.option_value(option, "mety", 0.0))
	return Energy.kcal_per_hour(gs.sex_or_default(), gs.body_age_months, gs.weight_kg, mety) * hours


## kcal of a meal entry: the share of the meal eaten in these hours (0 if not a meal).
func _meal_kcal(type: String, hours: float, option: Dictionary) -> float:
	var duration := float(option.get("duration_hours", 0.0))
	if not Hunger.is_food(type) or duration <= 0.0:
		return 0.0
	return Hunger.meal_kcal(type, hours / duration)


## Totals of one scoring day: sleep hours, moderate-to-vigorous activity minutes,
## strength days in the last log_days scoring days (this one included), entertainment
## hours, recreational screen hours and calories.
func day_totals(day: int) -> Dictionary:
	var totals := {"scoring_day": day, "sleep_hours": 0.0, "activity_minutes": 0.0, "strength_days": 0,
			"entertainment_hours": 0.0, "screen_hours": 0.0, "kcal": 0.0}
	var sleep_types: Array = Config.get_value("log.sleep_types")
	var activity_intensities: Array = Config.get_value("log.activity_intensities")
	var strength_types: Array = Config.get_value("log.strength_types")
	var entertainment_types: Array = Config.get_value("log.entertainment_types")
	var screen_types: Array = Config.get_value("log.screen_types")
	var oldest_day := day - Config.get_int("log.log_days") + 1
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


## Closes the current avatar day after a sleep of this many hours (0 for the 0-hour rule):
## logs the sleep, keeps the day's totals, runs GameState.daily_update() and starts the next
## day. start: where the sleep started (empty = now).
func end_scoring_day(sleep_hours: float, start: Dictionary = {}) -> void:
	if sleep_hours > 0.0:
		add_entry(Config.get_value("log.sleep_types")[0], sleep_hours, start)
	days.append(day_totals(current_day))
	GameState.daily_update()
	current_day += 1
	_prune()
	day_closed.emit()


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
	var oldest_day := current_day - Config.get_int("log.log_days") + 1
	entries = entries.filter(func(entry: Dictionary) -> bool: return entry["scoring_day"] >= oldest_day)
	days = days.filter(func(day: Dictionary) -> bool: return day["scoring_day"] >= oldest_day - 1)

