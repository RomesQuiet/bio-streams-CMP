extends RefCounted
## Short verdicts for values (user, 7 Nov 2026: "just say too thin, too something"), shared by
## the main screen's panels and the failure screen. They only choose words; the game does not
## use them. Each returns a translation key.


## BMI-for-age z: its WHO 2007 band, with the game's cut-offs (fail and avatar_states groups).
static func z_key(z: float) -> String:
	if z < Config.get_float("fail.danger_z"):
		return "MEASURE_VERDICT_Z_SEVERE_THIN"
	if z < Config.get_float("avatar_states.thin_below_z"):
		return "MEASURE_VERDICT_Z_THIN"
	if z > Config.get_float("avatar_states.obese_above_z"):
		return "MEASURE_VERDICT_Z_OBESE"
	if z > Config.get_float("avatar_states.overweight_above_z"):
		return "MEASURE_VERDICT_Z_OVER"
	return "MEASURE_VERDICT_Z_HEALTHY"


## A value from 0 to 1 (Physical, Happiness, Sleep, strength, fitness, diet quality): too low,
## could be better or good (verdicts.low_below and verdicts.good_from).
static func level_key(value: float) -> String:
	if value < Config.get_float("verdicts.low_below"):
		return "MEASURE_VERDICT_LOW"
	if value >= Config.get_float("verdicts.good_from"):
		return "MEASURE_VERDICT_GOOD"
	return "MEASURE_VERDICT_MIDDLE"
