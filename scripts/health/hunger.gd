extends RefCounted
## Appetite and meals (v1 Step 4, Milestone 10 Task 3). Hunger is in kcal.
## Every step: hunger += (habit_share x reference / 24 x hours + (1 - habit_share) x kcal spent
## in the step) x (1 + sleep_debt_boost x d) x (1 + thin_boost_per_sd x max(0, -z)).
## Appetite is mostly habit and only partly follows the energy spent; sleep debt raises it,
## and so does being below the median weight. It grows during sleep too.
## A meal removes kcal x satiety (data/foods.json). All numbers come from Config.

const Energy := preload("res://scripts/health/energy.gd")
const SleepModel := preload("res://scripts/health/sleep_model.gd")
const FOODS_PATH := "res://data/foods.json"

static var _foods := {}


## Step 3 of the update order. Uses the kcal spent in this step (Energy.step()).
static func step(hours: float, _asleep: bool) -> void:
	var gs := GameState
	gs.hunger += growth(hours, gs.energy_spent_step)
	gs.hours_since_meal += hours


## How much hunger grows in this many avatar hours when kcal_spent were spent in them.
static func growth(hours: float, kcal_spent: float) -> float:
	var gs := GameState
	var share := Config.get_float("appetite.habit_share")
	var reference := Energy.reference_kcal_per_day(gs.sex_or_default(), gs.body_age_months)
	var habit := share * reference / Config.get_float("units.hours_per_day") * hours
	var spending := (1.0 - share) * kcal_spent
	var sleep_boost := 1.0 + Config.get_float("appetite.sleep_debt_boost") * SleepModel.debt_factor()
	var thin_boost := 1.0 + Config.get_float("appetite.thin_boost_per_sd") * maxf(0.0, -gs.weight_z)
	return (habit + spending) * sleep_boost * thin_boost


## One healthy portion for the avatar now, in kcal.
static func healthy_portion_kcal() -> float:
	return Energy.healthy_portion_kcal(GameState.sex_or_default(), GameState.body_age_months)


## "I'm hungry!": hunger is at least meals.hungry_trigger healthy meals, and at least
## meals.min_gap_h avatar hours have passed since the last meal or skip.
static func is_hungry() -> bool:
	var gs := GameState
	return _at_least(gs.hunger, Config.get_float("meals.hungry_trigger") * healthy_portion_kcal()) \
			and _at_least(gs.hours_since_meal, Config.get_float("meals.min_gap_h"))


## kcal of a meal (an eat option id from data/foods.json), for this share of it (0 to 1).
static func meal_kcal(food_id: String, share: float) -> float:
	return _food_value(food_id, "portion_factor") * healthy_portion_kcal() * clampf(share, 0.0, 1.0)


## Eats this share of a meal: takes kcal x satiety off hunger and starts the meal gap again.
## Returns the kcal eaten.
static func eat(food_id: String, share: float) -> float:
	var kcal := meal_kcal(food_id, share)
	GameState.hunger -= kcal * _food_value(food_id, "satiety")
	GameState.hours_since_meal = 0.0
	GameState.changed.emit()
	return kcal


## Skips a meal when hungry: hunger stays, the meal gap starts again. Returns false if the
## avatar is not hungry (nothing to skip).
static func skip() -> bool:
	if not is_hungry():
		return false
	GameState.hours_since_meal = 0.0
	GameState.changed.emit()
	return true


## Whether an option id is a meal in data/foods.json.
static func is_food(food_id: String) -> bool:
	return _all_foods().has(food_id)


static func _food_value(food_id: String, key: String) -> float:
	var entry: Variant = _all_foods().get(food_id, {}).get(key)
	if entry == null:
		push_error("Hunger: food '%s' has no '%s'" % [food_id, key])
		return 0.0
	return float(entry["value"] if entry is Dictionary else entry)


static func _all_foods() -> Dictionary:
	if _foods.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FOODS_PATH))
		if not parsed is Dictionary:
			push_error("Hunger: could not read %s" % FOODS_PATH)
			return {}
		for key in parsed:
			if not str(key).begins_with("_"):
				_foods[key] = parsed[key]
	return _foods


## value >= limit, also when value is a sum of steps that lands a tiny bit below it.
static func _at_least(value: float, limit: float) -> bool:
	return value >= limit or is_equal_approx(value, limit)
