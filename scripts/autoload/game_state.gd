extends Node
## Holds the avatar's current state. All numbers come from Config.
## Time (Clock) and saving (SaveGame) live in their own scripts.

signal changed
## Emitted when XP reaches a new level.
signal leveled_up(new_level: int)

## Values that always stay between 0 and 1.
const MEASURES_0_TO_1 := ["physical", "mental", "sleep", "hunger", "muscle", "fitness", "mood"]
## The player's choices on the avatar creation screen. Empty means not chosen yet.
const CHOICE_KEYS := ["avatar_name", "age_group", "sex", "difficulty"]

# Measures: physical, mental and sleep go from 0 to 1. They are worked out from the
# body states once per avatar day. Health (1 to 5) is the displayed health: it starts at
# the target health and moves part of the way toward it once per avatar day.
var physical: float
var mental: float
var sleep: float
var health: float
var hunger: float
## Muscle strength, 0 to 1. A slow body state, trained by muscle strength (strength score).
var muscle: float
## Total kcal spent by exercise so far (not limited to 1). A record only.
var calories_spent: float
## Slow body states (Milestone 3, Task 4). Updated once per avatar day by update_body_states().
## Fitness, 0 to 1. Trained by cardio and muscle strength (activity score).
var fitness: float
## Hours of sleep owed. Never below 0.
var sleep_debt: float
## WHO BMI-for-age z-score. Stays at the difficulty's value until food exists.
var weight_z: float
## Mood, 0 to 1.
var mood: float
## Usual level of each habit, as a habit score (0 to 1): sleep, activity, strength, screens.
var usual_habits: Dictionary
## Tired means sleepy. Placeholder rule: the Clock sets this to true when the day ends.
var tired: bool
var xp: float
## Avatar hours spent at high health without a break (for the XP bonus).
var high_health_hours: float
var avatar_name: String
## "child" or "teenager".
var age_group: String
## "male" or "female".
var sex: String
## "easy", "normal", "hard" or "very_hard".
var difficulty: String
var language: String

## Health the displayed health moves toward: the health formula of the current measures.
var target_health: float:
	get:
		return calculate_health()

## Health as a whole number from 1 to 5 (health rounded). Shown in the health level box.
var health_level: int:
	get:
		return roundi(health)

## Level shown next to the XP bar. Starts at 0.
var level: int:
	get:
		return floori(xp / _xp_per_level())

## How full the XP bar is inside the current level (0 to 1).
var level_progress: float:
	get:
		return fmod(xp, _xp_per_level()) / _xp_per_level()


func _ready() -> void:
	reset()
	if OS.is_debug_build():
		print_state()


## Sets every value to its start value from Config (new avatar). Until the player
## chooses a difficulty, the default difficulty's starting values are used.
func reset() -> void:
	_apply_difficulty_start(Config.get_string("defaults.difficulty"))
	hunger = Config.get_float("measures.hunger_start")
	calories_spent = Config.get_float("measures.calories_spent_start")
	tired = false
	health = calculate_health()
	xp = Config.get_float("xp.start")
	high_health_hours = 0.0
	avatar_name = Config.get_string("defaults.avatar_name")
	age_group = ""
	sex = ""
	difficulty = ""
	language = Config.get_string("defaults.language")
	changed.emit()


## Everything that must be saved. Used by SaveGame (and later, maybe a server).
func to_dict() -> Dictionary:
	return {
		"physical": physical,
		"mental": mental,
		"sleep": sleep,
		"health": health,
		"hunger": hunger,
		"muscle": muscle,
		"calories_spent": calories_spent,
		"fitness": fitness,
		"sleep_debt": sleep_debt,
		"weight_z": weight_z,
		"mood": mood,
		"usual_habits": usual_habits.duplicate(),
		"tired": tired,
		"xp": xp,
		"high_health_hours": high_health_hours,
		"avatar_name": avatar_name,
		"age_group": age_group,
		"sex": sex,
		"difficulty": difficulty,
		"language": language,
	}


## Restores values from to_dict(). Missing keys keep their current value.
func from_dict(data: Dictionary) -> void:
	physical = float(data.get("physical", physical))
	mental = float(data.get("mental", mental))
	sleep = float(data.get("sleep", sleep))
	health = float(data.get("health", health))
	hunger = float(data.get("hunger", hunger))
	muscle = float(data.get("muscle", muscle))
	calories_spent = float(data.get("calories_spent", calories_spent))
	fitness = float(data.get("fitness", fitness))
	sleep_debt = float(data.get("sleep_debt", sleep_debt))
	weight_z = float(data.get("weight_z", weight_z))
	mood = float(data.get("mood", mood))
	var saved_habits: Variant = data.get("usual_habits", {})
	if saved_habits is Dictionary:
		for habit in saved_habits:
			usual_habits[habit] = float(saved_habits[habit])
	tired = bool(data.get("tired", tired))
	xp = float(data.get("xp", xp))
	high_health_hours = float(data.get("high_health_hours", high_health_hours))
	avatar_name = str(data.get("avatar_name", avatar_name))
	age_group = str(data.get("age_group", age_group))
	sex = str(data.get("sex", sex))
	difficulty = str(data.get("difficulty", difficulty))
	language = str(data.get("language", language))
	changed.emit()


## Called by the creation screen's Start button: stores the choices and sets the
## starting values of the chosen difficulty. Starting health is calculated from them.
func start_new_avatar(new_name: String, new_age_group: String, new_sex: String, new_difficulty: String) -> void:
	avatar_name = new_name
	age_group = new_age_group
	sex = new_sex
	difficulty = new_difficulty
	_apply_difficulty_start(difficulty)
	health = calculate_health()
	changed.emit()


## Starting measures and body states of a difficulty (section difficulties in config).
func _apply_difficulty_start(difficulty_id: String) -> void:
	var path := "difficulties." + difficulty_id
	physical = Config.get_float(path + ".physical")
	mental = Config.get_float(path + ".mental")
	sleep = Config.get_float(path + ".sleep")
	muscle = Config.get_float(path + ".muscle")
	fitness = Config.get_float(path + ".fitness")
	sleep_debt = Config.get_float(path + ".sleep_debt")
	weight_z = Config.get_float(path + ".weight_z")
	mood = Config.get_float(path + ".mood")
	usual_habits = Config.get_value(path + ".usual_habits").duplicate()


## Recommended sleep range for an age group, in hours: x = minimum, y = maximum.
## An empty age group uses the default one.
func sleep_range(group: String) -> Vector2:
	var path := "recommended_sleep." + (group if not group.is_empty() else Config.get_string("defaults.age_group"))
	return Vector2(Config.get_float(path + ".min_hours"), Config.get_float(path + ".max_hours"))


## Once per avatar day, when a sleep ends, after the habit scores (Habits calls this).
## scores: sleep, activity, strength, screens (0 to 1). sleep_hours: hours of that sleep.
func update_body_states(scores: Dictionary, sleep_hours: float) -> void:
	var k := Config.get_float("body_states.k")
	var r := Config.get_float("body_states.sleep_debt_r")
	sleep_debt = maxf(0.0, sleep_debt * r + (sleep_range(age_group).x - sleep_hours))
	# How far the habits jumped above their usual levels, before those levels move.
	var change := habit_change(scores)
	fitness = _train(fitness, float(scores.get("activity", 0.0)), k,
			Config.get_float("body_states.fitness_k_up"), Config.get_float("body_states.fitness_k_down"))
	muscle = _train(muscle, float(scores.get("strength", 0.0)), k,
			Config.get_float("body_states.muscle_k_up"), Config.get_float("body_states.muscle_k_down"))
	# weight_z stays the same: no food yet, so no automatic eating.
	mood = clampf(mood + Config.get_float("body_states.mood_speed") * (mood_target(scores) - mood), 0.0, 1.0)
	var habit_speed := minf(1.0, k * Config.get_float("body_states.usual_habit_speed"))
	for habit in usual_habits:
		if scores.has(habit):
			usual_habits[habit] = clampf(usual_habits[habit] + habit_speed * (float(scores[habit]) - usual_habits[habit]), 0.0, 1.0)
	_update_measures(float(scores.get("sleep", 0.0)), change)
	_step_health()
	changed.emit()


## Sum, over the habits, of how far the day's score is above the usual level by more
## than the free step (section measures_from_body). 0 when habits change step by step.
func habit_change(scores: Dictionary) -> float:
	var free_step := Config.get_float("measures_from_body.habit_change_free_step")
	var total := 0.0
	for habit in usual_habits:
		if scores.has(habit):
			total += maxf(0.0, float(scores[habit]) - usual_habits[habit] - free_step)
	return total


## The three measures from the body states (CLAUDE.md, Health calculation, step 4).
func _update_measures(sleep_score: float, change: float) -> void:
	physical = physical_from_body(fitness, muscle, weight_z)
	var debt_factor := 1.0 - Config.get_float("measures_from_body.sleep_debt_penalty_per_hour") * sleep_debt
	sleep = clampf(sleep_score * debt_factor, 0.0, 1.0)
	var cost := Config.get_float("difficulties.%s.habit_change_cost" % _difficulty_or_default())
	mental = clampf(mood - cost * Config.get_float("measures_from_body.habit_change_penalty") * change, 0.0, 1.0)


## The displayed health moves daily_alpha of the way toward the target health.
## A health gain gives XP and a health loss takes XP away (xp.per_health_point per point).
func _step_health() -> void:
	var new_health := health + Config.get_float("health_formula.daily_alpha") * (target_health - health)
	var change := new_health - health
	health = new_health
	if change != 0.0:
		add_xp(change * Config.get_float("xp.per_health_point"))


func _difficulty_or_default() -> String:
	return difficulty if not difficulty.is_empty() else Config.get_string("defaults.difficulty")


## The level mood moves toward: weighted average of the sleep, activity and screens scores.
func mood_target(scores: Dictionary) -> float:
	var weights := {
		"sleep": Config.get_float("body_states.mood_weight_sleep"),
		"activity": Config.get_float("body_states.mood_weight_activity"),
		"screens": Config.get_float("body_states.mood_weight_screens"),
	}
	var total := 0.0
	var weight_sum := 0.0
	for key in weights:
		total += weights[key] * float(scores.get(key, 0.0))
		weight_sum += weights[key]
	return total / weight_sum if weight_sum > 0.0 else mood


## Fitness or muscle after one avatar day: rises with the score toward 1 and falls
## without it toward 0. k multiplies both speeds; each is kept at 1 or less.
func _train(value: float, score: float, k: float, k_up: float, k_down: float) -> float:
	var up := minf(1.0, k * k_up)
	var down := minf(1.0, k * k_down)
	return clampf(value + up * score * (1.0 - value) - down * (1.0 - score) * value, 0.0, 1.0)


## True once the avatar has been created (name, age group, sex and difficulty chosen).
func is_created() -> bool:
	return has_all_choices(to_dict())


## True if saved GameState data (from to_dict()) holds all the creation choices.
## Saves from before the creation screen do not.
func has_all_choices(data: Dictionary) -> bool:
	for key in CHOICE_KEYS:
		if str(data.get(key, "")).strip_edges().is_empty():
			return false
	return true


## Target health from the current measures.
func calculate_health() -> float:
	return health_from_measures(physical, mental, sleep)


## Weighted power mean of the three measures (section health_formula in config),
## mapped from 0..1 to health_min..health_max.
func health_from_measures(p_physical: float, p_mental: float, p_sleep: float) -> float:
	var values := [clampf(p_physical, 0.0, 1.0), clampf(p_mental, 0.0, 1.0), clampf(p_sleep, 0.0, 1.0)]
	var weights := [Config.get_float("health_formula.weight_physical"),
			Config.get_float("health_formula.weight_mental"), Config.get_float("health_formula.weight_sleep")]
	var total_weight: float = weights[0] + weights[1] + weights[2]
	if total_weight <= 0.0:
		push_error("GameState: health weights must add up to more than 0")
		return health
	var p := Config.get_float("health_formula.p")
	var combined := 0.0
	if is_zero_approx(p):
		# p = 0 is the geometric mean.
		for i in 3:
			combined += weights[i] / total_weight * log(values[i])
		combined = exp(combined)
	else:
		for i in 3:
			combined += weights[i] / total_weight * pow(values[i], p)
		combined = pow(combined, 1.0 / p)
	var health_min := Config.get_float("measures.health_min")
	var health_max := Config.get_float("measures.health_max")
	return lerpf(health_min, health_max, clampf(combined, 0.0, 1.0))


## Weight score (0 to 1) from the WHO BMI-for-age z-score: 1 near the median,
## falling to 0 along a curve (section physical_measure in config).
func weight_score(weight_z: float) -> float:
	var full := Config.get_float("physical_measure.weight_score_full_within_z")
	var zero := Config.get_float("physical_measure.weight_score_zero_at_z")
	var power := Config.get_float("physical_measure.weight_score_curve_power")
	return pow(clampf((zero - absf(weight_z)) / (zero - full), 0.0, 1.0), power)


## Physical measure from the body states: weighted mix of fitness, muscle and weight score.
func physical_from_body(fitness: float, muscle_value: float, weight_z: float) -> float:
	var w_fitness := Config.get_float("physical_measure.weight_fitness")
	var w_muscle := Config.get_float("physical_measure.weight_muscle")
	var w_weight := Config.get_float("physical_measure.weight_weight_score")
	return (w_fitness * fitness + w_muscle * muscle_value + w_weight * weight_score(weight_z)) \
			/ (w_fitness + w_muscle + w_weight)


## Called by the Clock as avatar time passes. Measures and health change only once per
## avatar day (update_body_states); here only the XP over time.
func apply_avatar_hours(hours: float, _asleep: bool) -> void:
	_apply_time_xp(hours)
	changed.emit()


## Adds activity effects: {"value name": change per avatar hour} for this many hours.
## Called by Activities. Unknown names are reported and skipped. Health does not change
## here; it moves once per avatar day.
func apply_effects(effects_per_hour: Dictionary, hours: float) -> void:
	for key in effects_per_hour:
		if not key in self:
			push_error("GameState: unknown effect '%s'" % key)
			continue
		var value: float = get(key) + float(effects_per_hour[key]) * hours
		if key in MEASURES_0_TO_1:
			value = clampf(value, 0.0, 1.0)
		set(key, value)
	changed.emit()


## Placeholder XP over time: at high health XP grows, and faster the longer health
## stays high; at low health XP falls.
func _apply_time_xp(hours: float) -> void:
	if health_level >= Config.get_int("xp.high_health_min"):
		high_health_hours += hours
		var multiplier := minf(1.0 + Config.get_float("xp.high_health_bonus_per_hour") * high_health_hours,
				Config.get_float("xp.high_health_max_multiplier"))
		add_xp(Config.get_float("xp.gain_per_avatar_hour") * multiplier * hours)
	else:
		high_health_hours = 0.0
		if health_level <= Config.get_int("xp.low_health_max"):
			add_xp(-Config.get_float("xp.loss_per_avatar_hour") * hours)


## Adds (or, if negative, removes) XP. XP never goes below 0.
func add_xp(amount: float) -> void:
	var old_level := level
	xp = maxf(0.0, xp + amount)
	if level > old_level:
		leveled_up.emit(level)
	changed.emit()


func _xp_per_level() -> float:
	return maxf(1.0, Config.get_float("xp.per_level"))


func print_state() -> void:
	print("--- GameState ---")
	print("avatar_name='%s' age_group=%s sex=%s difficulty=%s language=%s" % [
			avatar_name, age_group, sex, difficulty, language])
	print("physical=%.2f mental=%.2f sleep=%.2f" % [physical, mental, sleep])
	print("muscle=%.2f calories_spent=%.0f" % [muscle, calories_spent])
	print("fitness=%.3f sleep_debt=%.2f h weight_z=%+.1f mood=%.3f" % [fitness, sleep_debt, weight_z, mood])
	print("usual_habits=%s" % usual_habits)
	print("hunger=%.2f tired=%s" % [hunger, tired])
	print("health=%.2f (level %d) target=%.2f" % [health, health_level, target_health])
	print("xp=%.1f level=%d progress=%.2f" % [xp, level, level_progress])
