extends RefCounted
## Energy spent (v1 Step 3, Milestone 10). Energy per avatar hour = BMR / 24 x METy of what
## the avatar is doing. BMR is the Schofield equation for the sex and the body age band
## (energy.bmr in config). Sleep never changes the metabolic rate. All numbers come from Config.
## Task 3 uses it for hunger; Task 4 adds weight change and the energy deficit.

const WhoTables := preload("res://scripts/health/who_tables.gd")


## Basal metabolic rate in kcal per day.
static func bmr(sex: String, age_months: float, weight_kg: float) -> float:
	var band := "from_10" if age_months >= Config.get_float("energy.bmr_band_from_months") else "below_10"
	var path := "energy.bmr.%s.%s." % [sex, band]
	return Config.get_float(path + "per_kg") * weight_kg + Config.get_float(path + "base")


## Weight (kg) at the WHO median BMI (z 0) and median height for the age.
static func healthy_weight_kg(sex: String, age_months: float) -> float:
	return WhoTables.weight_from_z(sex, age_months, 0.0)


## Reference appetite in kcal per day: BMR at the healthy weight x energy.pal_ref, the energy
## needs of an active child of healthy weight (v1 Step 4).
static func reference_kcal_per_day(sex: String, age_months: float) -> float:
	return bmr(sex, age_months, healthy_weight_kg(sex, age_months)) * Config.get_float("energy.pal_ref")


## One healthy portion in kcal: the reference / meals.per_day_ref.
static func healthy_portion_kcal(sex: String, age_months: float) -> float:
	return reference_kcal_per_day(sex, age_months) / Config.get_float("meals.per_day_ref")


## METy of what the avatar is doing now: the running activity's mety (data/activities.json),
## or energy.mety_idle when no activity runs.
static func mety_now() -> float:
	if Activities.is_running():
		return float(Activities.option_value(Activities.current_option_data(), "mety", Config.get_float("energy.mety_idle")))
	return Config.get_float("energy.mety_idle")


## kcal spent per avatar hour with this METy.
static func kcal_per_hour(sex: String, age_months: float, weight_kg: float, mety: float) -> float:
	return bmr(sex, age_months, weight_kg) / Config.get_float("units.hours_per_day") * mety


## Step 2 of the update order: the kcal spent in this step.
static func step(hours: float, _asleep: bool) -> void:
	var gs := GameState
	gs.energy_spent_step = kcal_per_hour(gs.sex_or_default(), gs.body_age_months, gs.weight_kg, mety_now()) * hours
