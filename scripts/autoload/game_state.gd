extends Node
## Holds the avatar's current state. All numbers come from Config.
## Time (Clock) and saving (SaveGame) live in their own scripts.

signal changed
## Emitted when XP reaches a new level.
signal leveled_up(new_level: int)

## Values that always stay between 0 and 1.
const MEASURES_0_TO_1 := ["physical", "mental", "sleep", "muscle", "fitness"]
## The player's choices on the avatar creation screen. Empty means not chosen yet.
const CHOICE_KEYS := ["avatar_name", "age_group", "sex", "difficulty"]

const WhoTables := preload("res://scripts/health/who_tables.gd")
const Energy := preload("res://scripts/health/energy.gd")

# Measures: physical, mental and sleep go from 0 to 1. They are worked out from the
# body states once per avatar day. Health (1 to 5) is the displayed health: it starts at
# the target health and moves part of the way toward it once per avatar day.
var physical: float
var mental: float
var sleep: float
var health: float
## Energy the avatar wants to eat now, in kcal (Milestone 10, v1 Step 4). Grows every step
## (also asleep); a meal takes off kcal x satiety. It can go below 0 after eating a lot.
var hunger: float
## Avatar hours since the last meal or skipped meal.
var hours_since_meal: float
## Body weight in kg and body age in months (Milestone 10). Set at the start from the
## starting z, the sex and the age group; they start changing in Task 4.
var weight_kg: float
var body_age_months: float
## kcal spent in the last 5-minute step (not saved; worked out again every step).
var energy_spent_step := 0.0
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
## Mood, 0 to health.mood_max (100). Mental = mood / mood_max.
var mood: float
## The scores the mood target averages (MILESTONE_4.md Task 5: s, a, c and e).
const MOOD_SCORES := ["sleep", "activity", "screens", "enjoyment"]
## Habit-change cost of the last scoring day, per habit and in total (mood points).
var habit_costs: Dictionary = {}
var habit_cost_total := 0.0
## Usual level H of each habit, as an intensity (0 to 1, see health.habit_intensity):
## sleep, activity, strength, screens.
var usual_habits: Dictionary
## Rootedness R of each habit (0 to 1): how deeply the habit is rooted. It grows on every
## real day the habit is stable and makes changing that habit cost more (Milestone 4 Task 5).
var rootedness: Dictionary
## Tired means sleepy. Placeholder rule: the Clock sets this to true when the day ends.
var tired: bool
## Avatar hours awake since the last sleep ended (Milestone 10). Simulation adds to it.
var hours_awake: float
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
	calories_spent = Config.get_float("measures.calories_spent_start")
	tired = false
	hours_awake = 0.0
	health = calculate_health()
	xp = Config.get_float("xp.start")
	high_health_hours = 0.0
	avatar_name = Config.get_string("defaults.avatar_name")
	age_group = ""
	sex = ""
	difficulty = ""
	language = Config.get_string("defaults.language")
	_apply_body_start()
	changed.emit()


## Everything that must be saved. Used by SaveGame (and later, maybe a server).
func to_dict() -> Dictionary:
	return {
		"physical": physical,
		"mental": mental,
		"sleep": sleep,
		"health": health,
		"hunger": hunger,
		"hours_since_meal": hours_since_meal,
		"weight_kg": weight_kg,
		"body_age_months": body_age_months,
		"muscle": muscle,
		"calories_spent": calories_spent,
		"fitness": fitness,
		"sleep_debt": sleep_debt,
		"weight_z": weight_z,
		"mood": mood,
		"habit_costs": habit_costs.duplicate(),
		"habit_cost_total": habit_cost_total,
		"usual_habits": usual_habits.duplicate(),
		"rootedness": rootedness.duplicate(),
		"tired": tired,
		"hours_awake": hours_awake,
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
	hours_since_meal = float(data.get("hours_since_meal", hours_since_meal))
	weight_kg = float(data.get("weight_kg", weight_kg))
	body_age_months = float(data.get("body_age_months", body_age_months))
	muscle = float(data.get("muscle", muscle))
	calories_spent = float(data.get("calories_spent", calories_spent))
	fitness = float(data.get("fitness", fitness))
	sleep_debt = float(data.get("sleep_debt", sleep_debt))
	weight_z = float(data.get("weight_z", weight_z))
	mood = float(data.get("mood", mood))
	habit_costs = data.get("habit_costs", {}).duplicate() if data.get("habit_costs") is Dictionary else {}
	habit_cost_total = float(data.get("habit_cost_total", 0.0))
	if data.get("rootedness") is Dictionary:
		for habit in data["usual_habits"]:
			usual_habits[habit] = float(data["usual_habits"][habit])
		for habit in data["rootedness"]:
			rootedness[habit] = float(data["rootedness"][habit])
	else:
		# A Milestone 3 save: no rootedness, its usual levels were habit scores and its
		# mood was 0 to 1. H and R start again from the Normal starting values; mood is scaled.
		_apply_habit_start(Config.get_string("defaults.difficulty"))
		mood *= Config.get_float("health_m4.mood_max")
	tired = bool(data.get("tired", tired))
	hours_awake = float(data.get("hours_awake", 0.0))
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
	_apply_body_start()
	health = calculate_health()
	changed.emit()


## Starting measures and body states of a difficulty (health.difficulties in config).
func _apply_difficulty_start(difficulty_id: String) -> void:
	var path := "health_m4.difficulties." + difficulty_id
	physical = Config.get_float(path + ".physical")
	mental = Config.get_float(path + ".mental")
	sleep = Config.get_float(path + ".sleep")
	muscle = Config.get_float(path + ".muscle")
	fitness = Config.get_float(path + ".fitness")
	sleep_debt = Config.get_float(path + ".sleep_debt")
	weight_z = Config.get_float(path + ".weight_z")
	mood = Config.get_float(path + ".mood")
	_apply_habit_start(difficulty_id)


## Starting body (Milestone 10): body age from the age group, weight from the starting z
## at the median height for that age (WHO), and hunger of a new avatar (ready for breakfast).
## Until Task 4 the starting z is the Milestone 4 weight_z.
func _apply_body_start() -> void:
	body_age_months = Config.get_float("body.start_age_months." + _age_group_or_default(age_group))
	weight_kg = WhoTables.weight_from_z(sex_or_default(), body_age_months, weight_z)
	hunger = Config.get_float("meals.start_hunger_meals") * Energy.healthy_portion_kcal(sex_or_default(), body_age_months)
	hours_since_meal = Config.get_float("meals.min_gap_h")


## The chosen sex, or the default one before the player chooses.
func sex_or_default() -> String:
	return sex if not sex.is_empty() else Config.get_string("defaults.sex")


## Starting usual level H and rootedness R of each habit for a difficulty.
func _apply_habit_start(difficulty_id: String) -> void:
	var path := "health_m4.difficulties." + difficulty_id
	usual_habits = Config.get_value(path + ".start_H").duplicate()
	rootedness = {}
	for habit in usual_habits:
		rootedness[habit] = Config.get_float(path + ".start_R")


## Recommended sleep range for an age group, in hours: x = minimum, y = maximum.
## An empty age group uses the default one.
func sleep_range(group: String) -> Vector2:
	var hours: Array = Config.get_value("health_m4.sleep_range." + _age_group_or_default(group))
	return Vector2(float(hours[0]), float(hours[1]))


## The one number of recommended sleep used by the sleep debt formula (hours).
func recommended_sleep(group: String) -> float:
	return Config.get_float("health_m4.sleep_recommended." + _age_group_or_default(group))


func _age_group_or_default(group: String) -> String:
	return group if not group.is_empty() else Config.get_string("defaults.age_group")


## Once per scoring day, when a sleep ends, after the habit scores (Habits calls this).
## scores: sleep, activity, strength, screens, enjoyment (0 to 1). sleep_hours: hours of
## that sleep. intensities: today's intensity A of each habit (Habits.intensities());
## a habit missing from it keeps its usual level.
## The slow states that use k run the real-day update k times (Milestone 4 Task 4), so
## one avatar day counts as k real days for the body and never overshoots.
func update_body_states(scores: Dictionary, sleep_hours: float, intensities: Dictionary = {}) -> void:
	var real_days := real_days_per_avatar_day()
	var r := Config.get_float("health_m4.r")
	var debt_updates := real_days if Config.get_value("health_m4.k_applies_to_sleep_debt") else 1
	for i in debt_updates:
		sleep_debt = maxf(0.0, sleep_debt * r + (recommended_sleep(age_group) - sleep_hours))
	# The cost of changing habits uses H and R from before this day.
	habit_costs = habit_change_costs(intensities)
	habit_cost_total = total_habit_cost(habit_costs)
	var activity := float(scores.get("activity", 0.0))
	var strength := float(scores.get("strength", 0.0))
	# Per real day, a habit moves the share that reaches habit_share_reached (95%) of a
	# new habit in habit_days_to_95 days.
	var habit_rate := 1.0 - pow(1.0 - Config.get_float("health_m4.habit_share_reached"),
			1.0 / Config.get_float("health_m4.habit_days_to_95"))
	var lambda := Config.get_float("health_m4.habit_cost.lambda")
	var tolerance := Config.get_float("health_m4.habit_cost.T")
	for i in real_days:
		fitness = _train(fitness, activity, Config.get_float("health_m4.fitness_k_up"), Config.get_float("health_m4.fitness_k_down"))
		muscle = _train(muscle, strength, Config.get_float("health_m4.muscle_k_up"), Config.get_float("health_m4.muscle_k_down"))
		for habit in usual_habits:
			# Rootedness grows only while the habit is stable (|A - H| at most T), so a
			# change in progress does not become more expensive every day.
			var stable := true
			if intensities.has(habit):
				stable = absf(float(intensities[habit]) - usual_habits[habit]) <= tolerance
				usual_habits[habit] = clampf(usual_habits[habit] + habit_rate * (float(intensities[habit]) - usual_habits[habit]), 0.0, 1.0)
			if stable:
				rootedness[habit] = clampf(rootedness[habit] + lambda * (1.0 - rootedness[habit]), 0.0, 1.0)
	# weight_z stays the same: no food yet, so no automatic eating.
	mood = clampf(mood + Config.get_float("health_m4.mood_speed") * (mood_target(scores) - mood) - habit_cost_total,
			0.0, Config.get_float("health_m4.mood_max"))
	_update_measures(float(scores.get("sleep", 0.0)))
	_step_health()
	changed.emit()


## How many real days one avatar day counts for the body: k, rounded to a whole number.
func real_days_per_avatar_day() -> int:
	return maxi(1, roundi(Config.get_float("health_m4.k")))


## Team model for the cost of changing habits (health.habit_cost), in mood points.
## For each habit, with A = today's intensity, H = usual level, R = rootedness:
## D = max(0, |A - H| - T), P = min(P_max, alpha x alpha_factor x R^gamma x D^gamma).
## Small changes (up to T) cost nothing; with gamma 2 two small steps cost less than one
## big one, and a big jump in a well-rooted habit costs most. Sleep has factor 0.
func habit_change_costs(intensities: Dictionary) -> Dictionary:
	var path := "health_m4.habit_cost."
	var tolerance := Config.get_float(path + "T")
	var alpha := Config.get_float(path + "alpha")
	var gamma := Config.get_float(path + "gamma")
	var p_max := Config.get_float(path + "P_max")
	var costs := {}
	for habit in usual_habits:
		if not intensities.has(habit):
			continue
		var deviation := maxf(0.0, absf(float(intensities[habit]) - usual_habits[habit]) - tolerance)
		var factor := Config.get_float(path + "alpha_factor." + habit)
		costs[habit] = minf(p_max, alpha * factor * pow(rootedness[habit], gamma) * pow(deviation, gamma))
	return costs


## The day's total cost: the sum over the habits, with no cap (P_max limits each habit).
func total_habit_cost(costs: Dictionary) -> float:
	var total := 0.0
	for habit in costs:
		total += costs[habit]
	return total


## The three measures from the body states (CLAUDE.md, Health calculation, step 4).
func _update_measures(sleep_score: float) -> void:
	physical = physical_from_body(fitness, muscle, weight_z)
	var debt_factor := 1.0 - sleep_debt / Config.get_float("health_m4.debt_max")
	sleep = clampf(sleep_score * debt_factor, 0.0, 1.0)
	mental = clampf(mood / Config.get_float("health_m4.mood_max"), 0.0, 1.0)


## The displayed health moves daily_alpha of the way toward the target health.
## A health gain gives XP and a health loss takes XP away (xp.per_health_point per point).
func _step_health() -> void:
	var new_health := health + Config.get_float("health_m4.alpha_bar") * (target_health - health)
	var change := new_health - health
	health = new_health
	if change != 0.0:
		add_xp(change * Config.get_float("xp.per_health_point"))



## The level mood moves toward: mood_max x the average of the sleep, activity, screens
## and enjoyment scores.
func mood_target(scores: Dictionary) -> float:
	var total := 0.0
	for key in MOOD_SCORES:
		total += float(scores.get(key, 0.0))
	return Config.get_float("health_m4.mood_max") * total / MOOD_SCORES.size()


## Fitness or muscle after one real day: rises with the score toward 1 and falls
## without it toward 0 (k_up and k_down are per real day).
func _train(value: float, score: float, k_up: float, k_down: float) -> float:
	return clampf(value + k_up * score * (1.0 - value) - k_down * (1.0 - score) * value, 0.0, 1.0)


## Failure (there is no death): the displayed health has reached the minimum
## (health.failure_at_health). The effect is not decided; the main screen shows a message.
func is_at_failure() -> bool:
	return health <= Config.get_float("health_m4.failure_at_health")


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


## Weighted power mean of the three measures (health.combine in config),
## mapped from 0..1 to health_min..health_max.
func health_from_measures(p_physical: float, p_mental: float, p_sleep: float) -> float:
	var values := [clampf(p_physical, 0.0, 1.0), clampf(p_mental, 0.0, 1.0), clampf(p_sleep, 0.0, 1.0)]
	var weights := [Config.get_float("health_m4.combine.weights.physical"),
			Config.get_float("health_m4.combine.weights.mental"), Config.get_float("health_m4.combine.weights.sleep")]
	var total_weight := 0.0
	for weight in weights:
		total_weight += weight
	if total_weight <= 0.0:
		push_error("GameState: health weights must add up to more than 0")
		return health
	var p := Config.get_float("health_m4.combine.p")
	var combined := 0.0
	if is_zero_approx(p):
		# p = 0 is the geometric mean.
		for i in values.size():
			combined += weights[i] / total_weight * log(values[i])
		combined = exp(combined)
	else:
		for i in values.size():
			combined += weights[i] / total_weight * pow(values[i], p)
		combined = pow(combined, 1.0 / p)
	var health_min := Config.get_float("measures.health_min")
	var health_max := Config.get_float("measures.health_max")
	return lerpf(health_min, health_max, clampf(combined, 0.0, 1.0))


## Weight score (0 to 1) from the WHO BMI-for-age z-score: 1 near the median,
## falling to 0 along a curve (health.weight_score in config).
func weight_score(weight_z: float) -> float:
	var full := Config.get_float("health_m4.weight_score.full_within_z")
	var zero := Config.get_float("health_m4.weight_score.zero_at_z")
	var power := Config.get_float("health_m4.weight_score.curve_power")
	return pow(clampf((zero - absf(weight_z)) / (zero - full), 0.0, 1.0), power)


## Physical measure from the body states: weighted mix of fitness, muscle and weight score.
func physical_from_body(fitness: float, muscle_value: float, weight_z: float) -> float:
	var w_fitness := Config.get_float("health_m4.physical_mix.fitness")
	var w_muscle := Config.get_float("health_m4.physical_mix.muscle")
	var w_weight := Config.get_float("health_m4.physical_mix.weight")
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
	print("fitness=%.3f sleep_debt=%.2f h weight_z=%+.1f mood=%.1f habit cost=%.2f" % [fitness, sleep_debt, weight_z, mood, habit_cost_total])
	print("usual_habits=%s" % usual_habits)
	print("rootedness=%s" % rootedness)
	print("hunger=%.0f kcal weight=%.1f kg tired=%s" % [hunger, weight_kg, tired])
	print("health=%.2f (level %d) target=%.2f" % [health, health_level, target_health])
	print("xp=%.1f level=%d progress=%.2f" % [xp, level, level_progress])
