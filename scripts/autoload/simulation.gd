extends Node
## The health update loop (Milestone 10, Task 2; v1 "Update order").
## The Clock moves avatar time every frame by a different amount. Simulation adds it up and
## runs the health system in fixed steps of time.step_avatar_min avatar minutes, so the
## result is the same whatever the frame rate or the debug speed (one big frame = many
## steps). When the Clock changes phase (sleep starts, sleep ends), the part of a step
## not yet run is run at once as a shorter step, so time asleep and time awake stay exact.
## Nothing runs while the game is paused or closed, because the Clock does not move then.
## All numbers come from Config.

## Emitted after each step, with the avatar hours of that step and whether the avatar slept.
signal stepped(hours: float, asleep: bool)

## Avatar minutes that have passed but are not a whole step yet.
var pending_minutes := 0.0
## Whether those minutes were asleep.
var pending_asleep := false


func _ready() -> void:
	Clock.avatar_time_passed.connect(_on_avatar_time_passed)
	Clock.phase_changed.connect(_on_phase_changed)


## Length of one step, in avatar minutes.
func step_minutes() -> float:
	return Config.get_float("time.step_avatar_min")


## New game: nothing pending.
func reset() -> void:
	pending_minutes = 0.0
	pending_asleep = false


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
	if asleep != pending_asleep:
		flush()
	pending_asleep = asleep
	pending_minutes += hours * Config.get_float("units.minutes_per_hour")
	var step := step_minutes()
	while pending_minutes >= step or is_equal_approx(pending_minutes, step):
		pending_minutes = maxf(0.0, pending_minutes - step)
		_step(step / Config.get_float("units.minutes_per_hour"), asleep)


func _on_phase_changed(phase: Clock.Phase) -> void:
	flush()
	# Any sleep that ends (a night or a nap) resets the hours awake.
	if phase == Clock.Phase.SLEEP_OVER:
		GameState.hours_awake = 0.0


## One step of the v1 update order. Each module joins here in its own Milestone 10 task.
func _step(hours: float, asleep: bool) -> void:
	# 1. Clock: awake or asleep (the Clock already moved the time).
	if not asleep:
		GameState.hours_awake += hours
	# 2. Energy spent (Task 4). 3. Hunger (Task 3). 4. Weight, body age, height and z (Task 4).
	# 5. Energy deficit penalty U (Task 4). 6. Training (Task 5). 7. Physical (Task 8).
	# 8. Happiness (Task 7).
	# 9. Health, failure timers, risk and XP. Until Task 8: the Milestone 4 XP over time.
	GameState.apply_avatar_hours(hours, asleep)
	# 10. Avatar messages and images: the main screen listens to GameState.changed.
	stepped.emit(hours, asleep)
