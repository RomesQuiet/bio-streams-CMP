extends RefCounted
## Energy and weight (v1 Steps 3 and 5, Milestone 10). Energy per avatar hour = BMR / 24 x METy
## of what the avatar is doing. BMR is the Schofield equation for the sex and the body age band
## (energy.bmr in config). Sleep never changes the metabolic rate. Weight changes by
## body.k x (kcal eaten - kcal spent) / body.kcal_per_kg; because BMR depends on weight, weight
## settles where intake and spending meet. The energy deficit penalty U comes from the kcal
## eaten and spent in the last deficit.window_h avatar hours. All numbers come from Config.

const WhoTables := preload("res://scripts/health/who_tables.gd")
const HourWindow := preload("res://scripts/health/hour_window.gd")


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


## Step 2 of the update order: the kcal spent in this step. They go into the energy window,
## take weight off, and (during exercise) add to the calories-spent record.
static func step(hours: float, _asleep: bool) -> void:
	var gs := GameState
	gs.energy_spent_step = kcal_per_hour(gs.sex_or_default(), gs.body_age_months, gs.weight_kg, mety_now()) * hours
	_add_to_window("spent", gs.energy_spent_step)
	_change_weight(-gs.energy_spent_step)
	if Activities.is_running():
		var intensity := str(Activities.option_value(Activities.current_option_data(), "activity_intensity", ""))
		if intensity in Config.get_value("energy.record_intensities"):
			gs.calories_spent += gs.energy_spent_step


## A meal's kcal: into the energy window, and onto the weight.
static func add_eaten(kcal: float) -> void:
	_add_to_window("eaten", kcal)
	_change_weight(kcal)


## Step 5 of the update order: U = 0 below a deficit of deficit.start, rising in a straight
## line to 1 at deficit.full. deficit = 1 - kcal eaten / kcal spent in the window.
static func update_deficit() -> void:
	GameState.deficit_u = deficit_penalty(window_total("eaten"), window_total("spent"))


static func deficit_penalty(eaten: float, spent: float) -> float:
	if spent <= 0.0:
		return 0.0
	var deficit := 1.0 - eaten / spent
	var start := Config.get_float("deficit.start")
	return clampf((deficit - start) / (Config.get_float("deficit.full") - start), 0.0, 1.0)


## Sum of kcal "eaten" or "spent" in the window.
static func window_total(kind: String) -> float:
	return HourWindow.total(GameState.energy_window, GameState.sim_hours, kind)


## A window as if the avatar had eaten what it spent, at the reference appetite, so a new
## avatar does not start with a deficit.
static func balanced_window(sex: String, age_months: float) -> Dictionary:
	var per_hour := reference_kcal_per_day(sex, age_months) / Config.get_float("units.hours_per_day")
	return HourWindow.create(Config.get_int("deficit.window_h"), {"eaten": per_hour, "spent": per_hour}, ["eaten", "spent"])


## Weight change: body.k x kcal / body.kcal_per_kg (k is body time).
static func _change_weight(kcal: float) -> void:
	GameState.weight_kg += Config.get_float("body.k") * kcal / Config.get_float("body.kcal_per_kg")


## Adds kcal to the slot of the current avatar hour.
static func _add_to_window(kind: String, kcal: float) -> void:
	HourWindow.add(GameState.energy_window, GameState.sim_hours, kind, kcal)
