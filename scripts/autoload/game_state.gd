extends Node
## Holds the avatar's current state. All numbers come from Config.
## Time (Clock) and saving (SaveGame) live in their own scripts.

signal changed
## Emitted when XP reaches a new level.
signal leveled_up(new_level: int)

## Values that always stay between 0 and 1.
const MEASURES_0_TO_1 := ["physical", "happiness", "sleep", "strength", "fitness"]
## The player's choices on the avatar creation screen. Empty means not chosen yet.
const CHOICE_KEYS := ["avatar_name", "age_group", "sex", "difficulty"]

const WhoTables := preload("res://scripts/health/who_tables.gd")
const Energy := preload("res://scripts/health/energy.gd")
const Training := preload("res://scripts/health/training.gd")
const SleepModel := preload("res://scripts/health/sleep_model.gd")
const Happiness := preload("res://scripts/health/happiness.gd")
const HealthModel := preload("res://scripts/health/health_model.gd")

# Measures: physical, happiness and sleep go from 0 to 1 (v1). Health (1 to 5) is the
# displayed health: it starts at the target health and moves part of the way toward it once
# per avatar day (decision 1). Physical is worked out every step (scripts/health/health_model.gd).
var physical: float
## Happiness, 0 to 1 (v1 Step 10, Milestone 10 Task 7; called mental before). It moves every
## step toward happiness_baseline and jumps with events (scripts/health/happiness.gd).
var happiness: float
var happiness_baseline: float
## Diet quality Q, fast-food craving C and habituation A to fast-food pleasure, 0 to 1 (v1 Step 7).
var diet_quality: float
var craving: float
var habituation: float
## Fun minutes and screen minutes in each of the last 24 avatar hours (v1 Step 10).
var fun_window: Dictionary
## Screen minutes in this avatar day, and awake hours since the last screens (the wish for screens).
var screen_minutes_today: float
var hours_without_screens: float
var sleep: float
var health: float
## Energy the avatar wants to eat now, in kcal (Milestone 10, v1 Step 4). Grows every step
## (also asleep); a meal takes off kcal x satiety. It can go below 0 after eating a lot.
var hunger: float
## Avatar hours since the last meal or skipped meal.
var hours_since_meal: float
## Body weight in kg, body age in months and height in metres (Milestone 10, v1 Step 2).
## Weight changes with energy eaten minus energy spent; the body ages with body time
## (body.k) up to the end of its age group; height is the WHO median for the body age.
var weight_kg: float
var body_age_months: float
var height_m: float
## Energy deficit penalty U, 0 to 1 (v1 Step 5), from the last deficit.window_h avatar hours.
var deficit_u: float
## kcal eaten and spent in each of the last deficit.window_h avatar hours (one slot per hour,
## oldest overwritten), and the avatar hour of the newest slot.
var energy_window: Dictionary
## Avatar hours run by Simulation since the avatar was created.
var sim_hours: float
## Training (Milestone 10, v1 Step 6). Recovery of cardio and of strength, 0 to 1 (1 = rested).
var cardio_recovery: float
var strength_recovery: float
## Whether the strength session running now started too soon (below train.strength_ready).
var strength_too_soon: bool
## Minutes of exercise done in this avatar day (they use up the daily capacity).
var exercise_minutes_today: float
## Excess minutes per day, averaged over train.overreach_tau_h, and the overreaching load O (0 to 1).
var overreach_minutes: float
var overreach: float
## Effective cardio and strength minutes in each of the last 24 avatar hours.
var training_window: Dictionary
## Night quality of the last sleep, 0 to 1 (v1 Step 9; for happiness on waking in Task 7),
## and the hours of that sleep.
var night_quality: float
var last_sleep_hours: float
## Minutes beyond the daily capacity in the last step (not saved; for happiness in Task 7).
var beyond_capacity_minutes_step := 0.0
## kcal spent in the last 5-minute step (not saved; worked out again every step).
var energy_spent_step := 0.0
## Muscle strength, 0 to 1 (v1 Step 6; called muscle before Milestone 10). Trained every step
## by Training from strength sessions (and a little from cardio).
var strength: float
## Total kcal spent by exercise so far (not limited to 1). A record only.
var calories_spent: float
## Aerobic fitness, 0 to 1 (v1 Step 6). Trained every step by Training from cardio and football
## (and a little from strength).
var fitness: float
## Hours of sleep owed (v1 Step 9, Milestone 10 Task 6). Changes at each new avatar day.
var sleep_debt: float
## WHO BMI-for-age z-score (Milestone 10: worked out every step from weight, height and body age).
var weight_z: float
## "I'm tired": tiredness is at least avatar_states.tired_at (SleepModel.update_tired()).
var tired: bool
## Avatar hours awake since the last sleep ended (Milestone 10). Simulation adds to it.
var hours_awake: float
## Failure timers (v1 Step 12): avatar hours that displayed health and happiness have stayed
## below their failure lines.
var health_low_hours: float
var happiness_low_hours: float
## Disease risk index R and hidden damage (v1 Step 12; debug only, decision 9).
var risk_index: float
var disease_damage: float
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
	calories_spent = Config.get_float("measures.calories_spent_start")
	tired = false
	hours_awake = 0.0
	xp = Config.get_float("xp.start")
	high_health_hours = 0.0
	avatar_name = Config.get_string("defaults.avatar_name")
	age_group = ""
	sex = ""
	difficulty = ""
	language = Config.get_string("defaults.language")
	_apply_body_start()
	health = calculate_health()
	changed.emit()


## Everything that must be saved. Used by SaveGame (and later, maybe a server).
func to_dict() -> Dictionary:
	return {
		"physical": physical,
		"happiness": happiness,
		"happiness_baseline": happiness_baseline,
		"diet_quality": diet_quality,
		"craving": craving,
		"habituation": habituation,
		"fun_window": fun_window.duplicate(true),
		"screen_minutes_today": screen_minutes_today,
		"hours_without_screens": hours_without_screens,
		"sleep": sleep,
		"health": health,
		"hunger": hunger,
		"hours_since_meal": hours_since_meal,
		"weight_kg": weight_kg,
		"body_age_months": body_age_months,
		"height_m": height_m,
		"deficit_u": deficit_u,
		"energy_window": energy_window.duplicate(true),
		"sim_hours": sim_hours,
		"cardio_recovery": cardio_recovery,
		"strength_recovery": strength_recovery,
		"strength_too_soon": strength_too_soon,
		"exercise_minutes_today": exercise_minutes_today,
		"overreach_minutes": overreach_minutes,
		"overreach": overreach,
		"training_window": training_window.duplicate(true),
		"strength": strength,
		"calories_spent": calories_spent,
		"fitness": fitness,
		"sleep_debt": sleep_debt,
		"night_quality": night_quality,
		"last_sleep_hours": last_sleep_hours,
		"weight_z": weight_z,
		"tired": tired,
		"hours_awake": hours_awake,
		"health_low_hours": health_low_hours,
		"happiness_low_hours": happiness_low_hours,
		"risk_index": risk_index,
		"disease_damage": disease_damage,
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
	happiness = float(data.get("happiness", happiness))
	happiness_baseline = float(data.get("happiness_baseline", happiness_baseline))
	diet_quality = float(data.get("diet_quality", diet_quality))
	craving = float(data.get("craving", craving))
	habituation = float(data.get("habituation", habituation))
	if data.get("fun_window") is Dictionary:
		fun_window = data["fun_window"].duplicate(true)
		fun_window["hour"] = int(fun_window.get("hour", -1))
	screen_minutes_today = float(data.get("screen_minutes_today", screen_minutes_today))
	hours_without_screens = float(data.get("hours_without_screens", hours_without_screens))
	sleep = float(data.get("sleep", sleep))
	health = float(data.get("health", health))
	hunger = float(data.get("hunger", hunger))
	hours_since_meal = float(data.get("hours_since_meal", hours_since_meal))
	weight_kg = float(data.get("weight_kg", weight_kg))
	body_age_months = float(data.get("body_age_months", body_age_months))
	height_m = float(data.get("height_m", height_m))
	deficit_u = float(data.get("deficit_u", deficit_u))
	if data.get("energy_window") is Dictionary:
		energy_window = data["energy_window"].duplicate(true)
		# JSON reads every number as a decimal; the hour is a whole number.
		energy_window["hour"] = int(energy_window.get("hour", -1))
	sim_hours = float(data.get("sim_hours", sim_hours))
	cardio_recovery = float(data.get("cardio_recovery", cardio_recovery))
	strength_recovery = float(data.get("strength_recovery", strength_recovery))
	strength_too_soon = bool(data.get("strength_too_soon", strength_too_soon))
	exercise_minutes_today = float(data.get("exercise_minutes_today", exercise_minutes_today))
	overreach_minutes = float(data.get("overreach_minutes", overreach_minutes))
	overreach = float(data.get("overreach", overreach))
	if data.get("training_window") is Dictionary:
		training_window = data["training_window"].duplicate(true)
		training_window["hour"] = int(training_window.get("hour", -1))
	strength = float(data.get("strength", data.get("muscle", strength)))
	calories_spent = float(data.get("calories_spent", calories_spent))
	fitness = float(data.get("fitness", fitness))
	sleep_debt = float(data.get("sleep_debt", sleep_debt))
	night_quality = float(data.get("night_quality", night_quality))
	last_sleep_hours = float(data.get("last_sleep_hours", last_sleep_hours))
	weight_z = float(data.get("weight_z", weight_z))
	tired = bool(data.get("tired", tired))
	hours_awake = float(data.get("hours_awake", 0.0))
	health_low_hours = float(data.get("health_low_hours", 0.0))
	happiness_low_hours = float(data.get("happiness_low_hours", 0.0))
	risk_index = float(data.get("risk_index", 0.0))
	disease_damage = float(data.get("disease_damage", 0.0))
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
	_apply_body_start()
	health = calculate_health()
	changed.emit()


## Starting body (Milestone 10): body age from the age group, the starting z of the
## difficulty (health.difficulties), weight from that z at the WHO median height for the age,
## an energy window in balance, and hunger of a new avatar (ready for breakfast).
func _apply_body_start() -> void:
	var difficulty_id := difficulty if not difficulty.is_empty() else Config.get_string("defaults.difficulty")
	body_age_months = Config.get_float("body.start_age_months." + _age_group_or_default(age_group))
	weight_z = Config.get_float("health.difficulties.%s.z" % difficulty_id)
	height_m = WhoTables.median_height_m(sex_or_default(), body_age_months)
	weight_kg = WhoTables.weight_from_z(sex_or_default(), body_age_months, weight_z)
	sim_hours = 0.0
	energy_window = Energy.balanced_window(sex_or_default(), body_age_months)
	deficit_u = 0.0
	# Training starts rested, from the v1 starting fitness and strength of the difficulty.
	fitness = Config.get_float("health.difficulties.%s.fitness" % difficulty_id)
	strength = Config.get_float("health.difficulties.%s.strength" % difficulty_id)
	training_window = Training.starting_window(fitness, strength)
	cardio_recovery = 1.0
	# Sleep (v1 Step 9): the starting debt of the difficulty gives the starting Sleep measure.
	sleep_debt = Config.get_float("health.difficulties.%s.sleep_debt" % difficulty_id)
	sleep = SleepModel.sleep_measure(sleep_debt, 0.0)
	night_quality = 1.0
	last_sleep_hours = 0.0
	SleepModel.update_tired()
	strength_recovery = 1.0
	strength_too_soon = false
	exercise_minutes_today = 0.0
	overreach_minutes = 0.0
	overreach = 0.0
	hunger = Config.get_float("meals.start_hunger_meals") * Energy.healthy_portion_kcal(sex_or_default(), body_age_months)
	hours_since_meal = Config.get_float("meals.min_gap_h")
	# Happiness and diet (v1 Steps 7 and 10).
	var path := "health.difficulties.%s." % difficulty_id
	happiness = Config.get_float(path + "happiness")
	diet_quality = Config.get_float(path + "Q")
	craving = Config.get_float(path + "C")
	habituation = Config.get_float(path + "A")
	fun_window = Happiness.starting_window()
	screen_minutes_today = 0.0
	hours_without_screens = 0.0
	# The measures and failure from those starting states (v1 Steps 8 and 12).
	physical = HealthModel.physical()
	health_low_hours = 0.0
	happiness_low_hours = 0.0
	risk_index = 0.0
	disease_damage = 0.0
	happiness_baseline = Happiness.baseline()


## The chosen sex, or the default one before the player chooses.
func sex_or_default() -> String:
	return sex if not sex.is_empty() else Config.get_string("defaults.sex")


func _age_group_or_default(group: String) -> String:
	return group if not group.is_empty() else Config.get_string("defaults.age_group")


## Once per avatar day, when a sleep ends (Habits calls this): the displayed health moves
## part of the way to the target (decision 1). Everything else changes in Simulation's steps
## and events.
func daily_update() -> void:
	HealthModel.daily_step()
	changed.emit()


## Failure (there is no death): displayed health or happiness has stayed below its failure line
## for long enough (fail group in config). The effect is not decided; the main screen shows a message.
func is_at_failure() -> bool:
	return HealthModel.is_at_failure()


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


## Target health from the current measures (v1 Step 11).
func calculate_health() -> float:
	return HealthModel.target_health(physical, happiness, sleep)


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
	print("physical=%.2f happiness=%.2f sleep=%.2f" % [physical, happiness, sleep])
	print("strength=%.2f calories_spent=%.0f" % [strength, calories_spent])
	print("fitness=%.3f sleep_debt=%.2f h weight_z=%+.1f Q=%.2f C=%.2f A=%.2f" % [fitness, sleep_debt, weight_z, diet_quality, craving, habituation])
	print("hunger=%.0f kcal weight=%.1f kg tired=%s" % [hunger, weight_kg, tired])
	print("health=%.2f (level %d) target=%.2f" % [health, health_level, target_health])
	print("xp=%.1f level=%d progress=%.2f" % [xp, level, level_progress])
