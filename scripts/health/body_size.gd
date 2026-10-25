extends RefCounted
## Body size and weight status (v1 Step 2, Milestone 10). The body ages with body time
## (body.k), but never past the end of its age group (decision 8). Height is the WHO median
## height for the body age, so a growing child's BMI-for-age can fall without losing weight.
## z is the WHO BMI-for-age z-score of weight / height². All numbers come from Config.

const WhoTables := preload("res://scripts/health/who_tables.gd")


## Step 4 of the update order: body age, height and z.
static func step(hours: float, _asleep: bool) -> void:
	var gs := GameState
	var group := gs.age_group if not gs.age_group.is_empty() else Config.get_string("defaults.age_group")
	var months_per_hour := Config.get_float("units.months_per_year") / Config.get_float("units.hours_per_year")
	gs.body_age_months = minf(gs.body_age_months + Config.get_float("body.k") * hours * months_per_hour,
			Config.get_float("body.max_age_months." + group))
	gs.height_m = WhoTables.median_height_m(gs.sex_or_default(), gs.body_age_months)
	gs.weight_z = WhoTables.z_from_bmi(gs.sex_or_default(), gs.body_age_months, bmi(gs.weight_kg, gs.height_m))


static func bmi(weight_kg: float, height_m: float) -> float:
	return weight_kg / (height_m * height_m)


## Weight score w(z), 0 to 1: straight lines between the [z, score] points of
## health.weight_score_points; 0 outside them.
static func weight_score(z: float) -> float:
	var points: Array = Config.get_value("health.weight_score_points")
	if z < float(points[0][0]) or z > float(points[-1][0]):
		return 0.0
	for i in points.size() - 1:
		var a: Array = points[i]
		var b: Array = points[i + 1]
		if z <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (z - float(a[0])) / (float(b[0]) - float(a[0])))
	return float(points[-1][1])
