extends RefCounted
## Happiness, 0 to 1 (v1 Step 10, Milestone 10 Task 7). It moves toward a baseline with the time
## constant mood.tau_h (clock time; k does not apply) and jumps with events.
## Baseline = base + physical x Physical + sleep x Sleep + diet x Q + fun x Fun - deficit x U
## - screen_excess x screen excess - overreach x O, from 0 to 1.
## - Fun = the minutes of the last 24 avatar hours of football x 1.0, screens x 0.6 (only the
##   first 120 minutes of each day) and exercise x 0.3, divided by 90, at most 1.
## - Screen excess = (screen minutes in the last 24 avatar hours - 120) / 120, from 0 to 1.
## Events (mood.events): meals, starting exercise (it does not want to), exercise within or
## beyond the daily capacity, football, screens, 4 awake hours without screens (a wish
## refused), being hungry while awake, waking up (night quality) and being kept awake while
## very tired. All numbers come from Config.

const HourWindow := preload("res://scripts/health/hour_window.gd")
const Hunger := preload("res://scripts/health/hunger.gd")
const SleepModel := preload("res://scripts/health/sleep_model.gd")

const FUN := "fun"
const SCREENS := "screens"


## A window of fun minutes and screen minutes for a new avatar (empty).
static func starting_window() -> Dictionary:
	return HourWindow.create(Config.get_int("mood.fun.window_h"), {}, [FUN, SCREENS])


## "football", "screens", "exercise" or "" for an activity option id (mood.fun types).
static func kind(option_id: String) -> String:
	for kind_name in ["football", "screen", "exercise"]:
		if option_id in Config.get_value("mood.fun.%s_types" % kind_name):
			return SCREENS if kind_name == "screen" else kind_name
	return ""


static func fun() -> float:
	var window_minutes := HourWindow.total(GameState.fun_window, GameState.sim_hours, FUN)
	return clampf(window_minutes / Config.get_float("mood.fun.full_at_min"), 0.0, 1.0)


static func screen_excess() -> float:
	var minutes := HourWindow.total(GameState.fun_window, GameState.sim_hours, SCREENS)
	return clampf((minutes - Config.get_float("mood.screen_excess_from_min")) / Config.get_float("mood.screen_excess_range_min"), 0.0, 1.0)


static func baseline() -> float:
	var gs := GameState
	var path := "mood.baseline."
	return clampf(Config.get_float(path + "base") + Config.get_float(path + "physical") * gs.physical
			+ Config.get_float(path + "sleep") * gs.sleep + Config.get_float(path + "diet") * gs.diet_quality
			+ Config.get_float(path + "fun") * fun() - Config.get_float(path + "deficit") * gs.deficit_u
			- Config.get_float(path + "screen_excess") * screen_excess() - Config.get_float(path + "overreach") * gs.overreach,
			0.0, 1.0)


## Step 8 of the update order: fun minutes, the events of this step, then the move toward
## the baseline.
static func step(hours: float, asleep: bool) -> void:
	var gs := GameState
	var minutes := hours * Config.get_float("units.minutes_per_hour")
	var doing := kind(Activities.current_option) if Activities.is_running() else ""
	var events := "mood.events."
	var change := 0.0
	match doing:
		"football":
			HourWindow.add(gs.fun_window, gs.sim_hours, FUN, minutes * Config.get_float("mood.fun.football"))
			change += Config.get_float(events + "football_per_h") * hours
		SCREENS:
			HourWindow.add(gs.fun_window, gs.sim_hours, SCREENS, minutes)
			var counted := clampf(Config.get_float("mood.fun.screen_max_min") - gs.screen_minutes_today, 0.0, minutes)
			gs.screen_minutes_today += minutes
			HourWindow.add(gs.fun_window, gs.sim_hours, FUN, counted * Config.get_float("mood.fun.screens"))
			change += Config.get_float(events + "screens_per_h") * counted / Config.get_float("units.minutes_per_hour")
		"exercise":
			HourWindow.add(gs.fun_window, gs.sim_hours, FUN, minutes * Config.get_float("mood.fun.exercise"))
			var beyond := minf(gs.beyond_capacity_minutes_step, minutes)
			var within_hours := (minutes - beyond) / Config.get_float("units.minutes_per_hour")
			change += Config.get_float(events + "exercise_per_h") * within_hours \
					* (1.0 - Config.get_float(events + "exercise_tired_cut") * SleepModel.tiredness())
			change += Config.get_float(events + "beyond_capacity_per_h") * beyond / Config.get_float("units.minutes_per_hour")
	if not asleep:
		# A wish refused: every no_screens_after_h awake hours without screens.
		gs.hours_without_screens = 0.0 if doing == SCREENS else gs.hours_without_screens + hours
		if gs.hours_without_screens >= Config.get_float(events + "no_screens_after_h"):
			gs.hours_without_screens -= Config.get_float(events + "no_screens_after_h")
			change += Config.get_float(events + "no_screens")
		if gs.hunger > Config.get_float(events + "hungry_at_meals") * Hunger.healthy_portion_kcal():
			change += Config.get_float(events + "hungry_per_h") * hours
		if SleepModel.tiredness() >= 1.0:
			change += Config.get_float(events + "kept_awake_per_h") * hours
	gs.happiness_baseline = baseline()
	gs.happiness = clampf(gs.happiness + change, 0.0, 1.0)
	gs.happiness += (gs.happiness_baseline - gs.happiness) * (1.0 - exp(-hours / Config.get_float("mood.tau_h")))


## A meal (this share of it): healthy meal + meal - meal_craving x C; fast food + meal +
## meal_craving x C x (1 - A). Uses C and A from before the meal (Diet changes them after).
static func on_meal(food_id: String, share: float) -> void:
	var gs := GameState
	var events := "mood.events."
	var craving_effect := Config.get_float(events + "meal_craving") * gs.craving
	if Hunger.food_value(food_id, "healthy") >= 1.0:
		_jump((Config.get_float(events + "meal") - craving_effect) * share)
	else:
		_jump((Config.get_float(events + "meal") + craving_effect * (1.0 - gs.habituation)) * share)


## Starting cardio or strength: start_exercise x (1 - fitness) (it does not want to exercise).
static func on_activity_started(option_id: String) -> void:
	if kind(option_id) == "exercise":
		_jump(Config.get_float("mood.events.start_exercise") * (1.0 - GameState.fitness))


## Waking up after a sleep: wake x (night quality - wake_mid).
static func on_wake() -> void:
	_jump(Config.get_float("mood.events.wake") * (GameState.night_quality - Config.get_float("mood.events.wake_mid")))


## A new avatar day: the screen minutes of the day start again.
static func new_day() -> void:
	GameState.screen_minutes_today = 0.0


static func _jump(change: float) -> void:
	GameState.happiness = clampf(GameState.happiness + change, 0.0, 1.0)
	GameState.changed.emit()
