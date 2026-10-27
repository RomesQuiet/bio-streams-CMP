extends RefCounted
## Disease risk, framework only (v1 Step 12, Milestone 10 Task 8; decision 9: shown in the debug
## panel, no disease stages until the team chooses diseases with a health professional).
## R = z_weight x clamp((z - z_from) / z_range) + thin_weight x clamp((thin_from - z) / thin_range)
## + fitness_weight x (1 - fitness) + diet_weight x (1 - Q) + sleep_weight x d. The thinness term
## (Milestone 10.5, team review) mirrors the obesity term. Hidden damage grows at body.k x (R -
## safe_level) / damage_tau_days (per day) while R is above safe_level, and falls while it is
## below. All numbers come from Config.

const SleepModel := preload("res://scripts/health/sleep_model.gd")


static func index() -> float:
	var gs := GameState
	var path := "risk."
	return Config.get_float(path + "z_weight") * clampf((gs.weight_z - Config.get_float(path + "z_from")) / Config.get_float(path + "z_range"), 0.0, 1.0) \
			+ Config.get_float(path + "thin_weight") * clampf((Config.get_float(path + "thin_from") - gs.weight_z) / Config.get_float(path + "thin_range"), 0.0, 1.0) \
			+ Config.get_float(path + "fitness_weight") * (1.0 - gs.fitness) \
			+ Config.get_float(path + "diet_weight") * (1.0 - gs.diet_quality) \
			+ Config.get_float(path + "sleep_weight") * SleepModel.debt_factor()


## Step 9 of the update order (part).
static func step(hours: float, _asleep: bool) -> void:
	var gs := GameState
	gs.risk_index = index()
	var body_days := Config.get_float("body.k") * hours / Config.get_float("units.hours_per_day")
	gs.disease_damage = maxf(0.0, gs.disease_damage
			+ body_days * (gs.risk_index - Config.get_float("risk.safe_level")) / Config.get_float("risk.damage_tau_days"))
