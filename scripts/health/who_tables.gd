extends RefCounted
## WHO growth reference 5 to 19 years (2007): BMI-for-age z-scores and median height.
## Reads data/who_bmi_for_age.json and data/who_height_for_age.json once.
## Sex is "male" or "female" (as GameState saves it). Age is in months and may have a
## fraction: values between two months are interpolated in a straight line, and ages
## outside the tables use the first or last month.
## Use it with preload("res://scripts/health/who_tables.gd").

const BMI_PATH := "res://data/who_bmi_for_age.json"
const HEIGHT_PATH := "res://data/who_height_for_age.json"

## Columns of a row in both tables (age in months first).
enum Column { MONTH, L, M, S }

## {"bmi": {"male": rows, "female": rows}, "height": {...}}, filled on first use.
static var _tables := {}


## L, M and S of the BMI-for-age table for this sex and age: {"L", "M", "S"}.
static func bmi_lms(sex: String, age_months: float) -> Dictionary:
	var row := _row("bmi", BMI_PATH, sex, age_months)
	return {"L": row[Column.L], "M": row[Column.M], "S": row[Column.S]}


## WHO BMI-for-age z-score of this BMI (kg/m²). Beyond ±extension_from_z the WHO
## rule is used: z = 3 + (BMI - SD3) / (SD3 - SD2), and the mirror below -3.
static func z_from_bmi(sex: String, age_months: float, bmi: float) -> float:
	var lms := bmi_lms(sex, age_months)
	var z := _lms_z(lms, bmi)
	var edge := Config.get_float("who.extension_from_z")
	if absf(z) <= edge:
		return z
	var side := signf(z)
	var sd_edge := _lms_bmi(lms, side * edge)
	var sd_inner := _lms_bmi(lms, side * (edge - 1.0))
	return side * edge + (bmi - sd_edge) / absf(sd_edge - sd_inner)


## BMI (kg/m²) that gives this BMI-for-age z-score. The inverse of z_from_bmi().
static func bmi_from_z(sex: String, age_months: float, z: float) -> float:
	var lms := bmi_lms(sex, age_months)
	var edge := Config.get_float("who.extension_from_z")
	if absf(z) <= edge:
		return _lms_bmi(lms, z)
	var side := signf(z)
	var sd_edge := _lms_bmi(lms, side * edge)
	var sd_inner := _lms_bmi(lms, side * (edge - 1.0))
	return sd_edge + (z - side * edge) * absf(sd_edge - sd_inner)


## WHO median height-for-age, in metres.
static func median_height_m(sex: String, age_months: float) -> float:
	var row := _row("height", HEIGHT_PATH, sex, age_months)
	return row[Column.M] / Config.get_float("units.cm_per_m")


## Weight (kg) with this BMI-for-age z-score at the median height for the age.
static func weight_from_z(sex: String, age_months: float, z: float) -> float:
	var height := median_height_m(sex, age_months)
	return bmi_from_z(sex, age_months, z) * height * height


## Youngest and oldest age in the tables, in months: x = first, y = last.
static func age_range_months() -> Vector2:
	var rows: Array = _rows("bmi", BMI_PATH, "male")
	return Vector2(rows[0][Column.MONTH], rows[-1][Column.MONTH])


## z from the LMS curve: ((BMI / M)^L - 1) / (L x S).
static func _lms_z(lms: Dictionary, bmi: float) -> float:
	return (pow(bmi / lms["M"], lms["L"]) - 1.0) / (lms["L"] * lms["S"])


## BMI from the LMS curve: M x (1 + L x S x z)^(1 / L).
static func _lms_bmi(lms: Dictionary, z: float) -> float:
	return lms["M"] * pow(1.0 + lms["L"] * lms["S"] * z, 1.0 / lms["L"])


## The row for this age, interpolated between the two nearest months.
static func _row(table: String, path: String, sex: String, age_months: float) -> Array:
	var rows: Array = _rows(table, path, sex)
	var first: float = rows[0][Column.MONTH]
	var position := clampf(age_months - first, 0.0, rows.size() - 1.0)
	var below: Array = rows[floori(position)]
	var above: Array = rows[ceili(position)]
	var t := position - floorf(position)
	var row := []
	for i in below.size():
		row.append(lerpf(below[i], above[i], t))
	return row


static func _rows(table: String, path: String, sex: String) -> Array:
	if not _tables.has(table):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			push_error("WhoTables: could not read %s" % path)
			return []
		_tables[table] = parsed
	if not _tables[table].has(sex):
		push_error("WhoTables: unknown sex '%s'" % sex)
		return []
	return _tables[table][sex]
