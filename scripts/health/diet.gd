extends RefCounted
## Diet quality and cravings (v1 Step 7, Milestone 10 Task 7). At each meal (x = 1 for a healthy
## meal, 0 for fast food, the "healthy" value in data/foods.json):
## - diet quality Q moves toward x, and fast-food craving C toward 1 - x, by
##   1 / (time constant in avatar days x meals.per_day_ref); their time constants are body
##   time (real days / body.k);
## - habituation A to fast-food pleasure moves toward 1 - x the same way, in clock time.
## A part of a meal (Stop) moves them by that share. All numbers come from Config.

const Hunger := preload("res://scripts/health/hunger.gd")


## Moves Q, C and A after eating this share (0 to 1) of a meal.
static func on_meal(food_id: String, share: float) -> void:
	var gs := GameState
	var x := Hunger.food_value(food_id, "healthy")
	var k := Config.get_float("body.k")
	gs.diet_quality += (x - gs.diet_quality) * _rate(Config.get_float("diet.quality_tau_days") / k, share)
	gs.craving += ((1.0 - x) - gs.craving) * _rate(Config.get_float("diet.craving_tau_days") / k, share)
	gs.habituation += ((1.0 - x) - gs.habituation) * _rate(Config.get_float("diet.habituation_tau_days"), share)


## The share of the way one meal moves a value with this time constant (avatar days).
static func _rate(tau_avatar_days: float, share: float) -> float:
	return clampf(share / (tau_avatar_days * Config.get_float("meals.per_day_ref")), 0.0, 1.0)
