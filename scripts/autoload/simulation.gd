extends Node
## The health update loop (Milestone 10, Task 2; v1 "Update order").
## The Clock moves avatar time every frame by a different amount. Simulation adds it up and
## runs the health system in fixed steps of time.step_avatar_min avatar minutes, so the
## result is the same whatever the frame rate or the debug speed (one big frame = many
## steps). When the Clock changes phase (sleep starts, sleep ends), the part of a step
## not yet run is run at once as a shorter step, so time asleep and time awake stay exact.
## Nothing runs while the game is paused or closed, because the Clock does not move then.
## Simulation is listed before Activities in the autoloads, so it hears each frame's time
## while the activity of that frame still runs; and just before an activity starts or ends
## (Activities.changing) the minutes not yet run are run, so each step uses the right METy.
## A frame that goes past the end of a day activity is split: the part after the end is
## counted when the activity has ended.
## All numbers come from Config.

const Energy := preload("res://scripts/health/energy.gd")
const Hunger := preload("res://scripts/health/hunger.gd")
const BodySize := preload("res://scripts/health/body_size.gd")
const Training := preload("res://scripts/health/training.gd")
const SleepModel := preload("res://scripts/health/sleep_model.gd")

## Emitted after each step, with the avatar hours of that step and whether the avatar slept.
signal stepped(hours: float, asleep: bool)

## Avatar minutes that have passed but are not a whole step yet.
var pending_minutes := 0.0
## Whether those minutes were asleep.
var pending_asleep := false
## Avatar hours of the current frame that come after the running day activity ends.
var _after_activity_hours := 0.0
## True while SaveGame restores a save: the Clock and Activities then repeat their events
## (phase change, activity start), which must not run a new day or change the state again.
var loading := false


func _ready() -> void:
	Clock.avatar_time_passed.connect(_on_avatar_time_passed)
	Clock.phase_changed.connect(_on_phase_changed)
	Activities.changing.connect(flush)
	Activities.started.connect(_on_activity_started)
	Clock.day_started.connect(_on_day_started)
	Activities.ended.connect(_on_activity_ended)


## Length of one step, in avatar minutes.
func step_minutes() -> float:
	return Config.get_float("time.step_avatar_min")


## New game: nothing pending.
func reset() -> void:
	pending_minutes = 0.0
	pending_asleep = false
	_after_activity_hours = 0.0


func to_dict() -> Dictionary:
	return {"pending_minutes": pending_minutes, "pending_asleep": pending_asleep}


func from_dict(data: Dictionary) -> void:
	pending_minutes = float(data.get("pending_minutes", 0.0))
	pending_asleep = bool(data.get("pending_asleep", false))


## Runs the minutes not yet run as one shorter step.
func flush() -> void:
	if pending_minutes > 0.0:
		var minutes := pending_minutes
		pending_minutes = 0.0
		_step(minutes / Config.get_float("units.minutes_per_hour"), pending_asleep)


func _on_avatar_time_passed(hours: float, asleep: bool) -> void:
	var now := hours
	if Activities.is_running() and not Activities.uses_sleep_time(Activities.current_activity):
		var left := maxf(0.0, Activities.target_hours - Activities.elapsed_hours)
		if hours > left:
			now = left
			_after_activity_hours = hours - left
	_add(now, asleep)


## Adds avatar hours and runs every whole step in them.
func _add(hours: float, asleep: bool) -> void:
	if asleep != pending_asleep:
		flush()
	pending_asleep = asleep
	pending_minutes += hours * Config.get_float("units.minutes_per_hour")
	var step := step_minutes()
	while pending_minutes >= step or is_equal_approx(pending_minutes, step):
		pending_minutes = maxf(0.0, pending_minutes - step)
		_step(step / Config.get_float("units.minutes_per_hour"), asleep)


func _on_phase_changed(phase: Clock.Phase) -> void:
	if loading:
		return
	flush()
	# Any sleep that ends (a night or a nap) resets the hours awake and starts a new avatar day.
	if phase == Clock.Phase.SLEEP_OVER:
		GameState.hours_awake = 0.0
		SleepModel.new_day(Clock.sleep_elapsed_hours)
		Training.new_day()


## The 0-hour rule (the awake period ran out without sleep) also starts a new avatar day.
func _on_day_started(slept: bool) -> void:
	if not slept and not loading:
		flush()
		SleepModel.new_day(0.0)
		Training.new_day()


func _on_activity_started(_activity_id: String, option_id: String) -> void:
	if not loading:
		Training.on_activity_started(option_id)


## A meal counts when it ends, in proportion to the time eaten (Stop = part of a meal).
## Its minutes were already run (Activities.changing), so hunger is up to date.
func _on_activity_ended(_activity_id: String, option_id: String, hours_done: float) -> void:
	if Hunger.is_food(option_id):
		var duration := float(Activities.find_option(option_id).get("duration_hours", 0.0))
		Energy.add_eaten(Hunger.eat(option_id, hours_done / duration if duration > 0.0 else 1.0))
	# The rest of the frame, after the activity.
	if _after_activity_hours > 0.0:
		var hours := _after_activity_hours
		_after_activity_hours = 0.0
		_add(hours, false)


## One step of the v1 update order. Each module joins here in its own Milestone 10 task.
func _step(hours: float, asleep: bool) -> void:
	# 1. Clock: awake or asleep (the Clock already moved the time).
	GameState.sim_hours += hours
	if not asleep:
		GameState.hours_awake += hours
	# 2. Energy spent.
	Energy.step(hours, asleep)
	# 3. Hunger.
	Hunger.step(hours, asleep)
	# 4. Body age, height and z (weight changed in step 2 and at meals).
	BodySize.step(hours, asleep)
	# 5. Energy deficit penalty U.
	Energy.update_deficit()
	# 6. Training: capacity, recovery, overreaching, fitness and strength.
	Training.step(hours, asleep)
	# Tiredness for "I'm tired" (sleep debt and hours awake; the debt changes at each new day).
	SleepModel.update_tired()
	# 7. Physical (Task 8).
	# 8. Happiness (Task 7).
	# 9. Health, failure timers, risk and XP. Until Task 8: the Milestone 4 XP over time.
	GameState.apply_avatar_hours(hours, asleep)
	# 10. Avatar messages and images: the main screen listens to GameState.changed.
	stepped.emit(hours, asleep)
