extends RefCounted
## Training (v1 Step 6, Milestone 10 Task 5). All numbers come from Config (group train).
## - Daily capacity = (capacity_base_min + capacity_fit_min x fitness) x (1 - capacity_sleep_cut
##   x d) minutes of exercise per avatar day. Minutes beyond it give no benefit (and, in Task 7,
##   cost a little happiness) and build the overreaching load O.
## - Recovery (clock time): cardio and football tire the body (fully after cardio_tire_min
##   continuous minutes) and recover with cardio_recovery_h; strength tires after
##   strength_tire_min and recovers with strength_recovery_h. A strength session that starts
##   below strength_ready, or less than strength_min_gap_h after the start of the previous
##   strength session (Milestone 10.5, team review), counts as too soon: it gives no effective
##   minutes, and all its minutes build O (user decision, 25 Oct 2026).
## - Effective minutes = minutes x performance x recovery (0 beyond capacity). Their average per
##   day over the last train.average_window_h avatar hours gives A_cardio and A_strength
##   (with 24 h: their sum over the last day).
## - Fitness and strength move toward their targets with time constants in body time
##   (k applies); gains are cut by sleep debt, the energy deficit U and O.

const HourWindow := preload("res://scripts/health/hour_window.gd")
const SleepModel := preload("res://scripts/health/sleep_model.gd")

const CARDIO := "cardio"
const STRENGTH := "strength"


## "cardio", "strength" or "" for an activity option id (train.cardio_types, strength_types).
static func kind(option_id: String) -> String:
	if option_id in Config.get_value("train.cardio_types"):
		return CARDIO
	if option_id in Config.get_value("train.strength_types"):
		return STRENGTH
	return ""


## A strength session that starts now, below train.strength_ready or within
## train.strength_min_gap_h of the start of the previous one, is too soon.
static func strength_too_soon() -> bool:
	return GameState.strength_recovery < Config.get_float("train.strength_ready") \
			or GameState.hours_since_strength < Config.get_float("train.strength_min_gap_h")


## Called when the avatar really starts an activity (with a minigame, at the first press).
static func on_activity_started(option_id: String) -> void:
	if kind(option_id) == STRENGTH:
		GameState.strength_too_soon = strength_too_soon()
		GameState.hours_since_strength = 0.0


## A new avatar day (after any sleep, or the 0-hour rule): the daily capacity starts again.
static func new_day() -> void:
	GameState.exercise_minutes_today = 0.0


## Minutes of exercise the avatar can do today with benefit.
static func capacity_min() -> float:
	return (Config.get_float("train.capacity_base_min") + Config.get_float("train.capacity_fit_min") * GameState.fitness) \
			* (1.0 - Config.get_float("train.capacity_sleep_cut") * SleepModel.debt_factor())


## Minigame performance: min_performance + (1 - min_performance) x score x (1 - tired_cut x
## tiredness). The score comes from Minigame: the player's while a session runs, otherwise
## minigame.default_score (decision 5).
static func performance() -> float:
	var lowest := Config.get_float("minigame.min_performance")
	return lowest + (1.0 - lowest) * Minigame.score() \
			* (1.0 - Config.get_float("minigame.tired_cut") * SleepModel.tiredness())


## Step 6 of the update order.
static func step(hours: float, _asleep: bool) -> void:
	var gs := GameState
	var minutes := hours * Config.get_float("units.minutes_per_hour")
	var doing := kind(Activities.doing_option())
	var excess := 0.0
	gs.beyond_capacity_minutes_step = 0.0
	# Clock time since the last strength session started (the minimum gap).
	gs.hours_since_strength += hours
	if not doing.is_empty():
		var within := minf(minutes, maxf(0.0, capacity_min() - gs.exercise_minutes_today))
		var beyond := minutes - within
		gs.exercise_minutes_today += minutes
		gs.beyond_capacity_minutes_step = beyond
		var recovery := gs.cardio_recovery if doing == CARDIO else gs.strength_recovery
		var too_soon := doing == STRENGTH and gs.strength_too_soon
		if not too_soon:
			HourWindow.add(gs.training_window, gs.sim_hours, doing, within * performance() * recovery)
		excess = minutes if too_soon else beyond
		if doing == CARDIO:
			gs.cardio_recovery = maxf(0.0, gs.cardio_recovery - minutes / Config.get_float("train.cardio_tire_min"))
		else:
			gs.strength_recovery = maxf(0.0, gs.strength_recovery - minutes / Config.get_float("train.strength_tire_min"))
	# The kind of training not being done now recovers (clock time).
	if doing != CARDIO:
		gs.cardio_recovery = _toward(gs.cardio_recovery, 1.0, hours / Config.get_float("train.cardio_recovery_h"))
	if doing != STRENGTH:
		gs.strength_recovery = _toward(gs.strength_recovery, 1.0, hours / Config.get_float("train.strength_recovery_h"))
	_update_overreach(hours, excess)
	_update_levels(hours)


## A_cardio or A_strength: effective minutes per day, averaged over the hours of the training
## window (train.average_window_h; with 24 h, the sum of the last day).
static func effective_minutes(training_kind: String) -> float:
	var window := GameState.training_window
	return HourWindow.total(window, GameState.sim_hours, training_kind) \
			* Config.get_float("units.hours_per_day") / HourWindow.hours(window)


static func fitness_target() -> float:
	var minutes := effective_minutes(CARDIO) + Config.get_float("train.fitness_strength_share") * effective_minutes(STRENGTH)
	return _target(minutes, Config.get_float("train.fitness_ref_min"))


static func strength_target() -> float:
	var minutes := effective_minutes(STRENGTH) + Config.get_float("train.strength_cardio_share") * effective_minutes(CARDIO)
	return _target(minutes, Config.get_float("train.strength_ref_min"))


## The window of a new avatar: as if it had kept the habits that give its starting fitness and
## strength as targets, so the levels do not start moving before the player does anything.
static func starting_window(fitness: float, strength: float) -> Dictionary:
	var fitness_minutes := _minutes_for(fitness, Config.get_float("train.fitness_ref_min"))
	var strength_minutes := _minutes_for(strength, Config.get_float("train.strength_ref_min"))
	var share_f := Config.get_float("train.fitness_strength_share")
	var share_s := Config.get_float("train.strength_cardio_share")
	# fitness_minutes = cardio + share_f x strength_min; strength_minutes = strength_min + share_s x cardio.
	var cardio := maxf(0.0, (fitness_minutes - share_f * strength_minutes) / (1.0 - share_f * share_s))
	var strength_min := maxf(0.0, strength_minutes - share_s * cardio)
	# Minutes per day spread evenly over every hour of the window.
	var hours_per_day := Config.get_float("units.hours_per_day")
	return HourWindow.create(Config.get_int("train.average_window_h"), {CARDIO: cardio / hours_per_day,
			STRENGTH: strength_min / hours_per_day}, [CARDIO, STRENGTH])


## O: the excess minutes per day, averaged over train.overreach_tau_h (clock time), divided by
## train.overreach_ref_min, from 0 to 1. It fades with rest.
static func _update_overreach(hours: float, excess_minutes: float) -> void:
	var gs := GameState
	var tau := Config.get_float("train.overreach_tau_h")
	gs.overreach_minutes = gs.overreach_minutes * exp(-hours / tau) \
			+ excess_minutes * Config.get_float("units.hours_per_day") / tau
	gs.overreach = clampf(gs.overreach_minutes / Config.get_float("train.overreach_ref_min"), 0.0, 1.0)


## Fitness and strength move toward their targets (body time). Only gains are cut.
static func _update_levels(hours: float) -> void:
	var gs := GameState
	var u_cut := 1.0 - Config.get_float("deficit.train_cut") * gs.deficit_u
	var gain := (1.0 - Config.get_float("train.sleep_gain_cut") * SleepModel.debt_factor()) * u_cut \
			* (1.0 - Config.get_float("train.overreach_gain_cut") * gs.overreach)
	var body_days := Config.get_float("body.k") * hours / Config.get_float("units.hours_per_day")
	gs.fitness = _move(gs.fitness, fitness_target() * u_cut, body_days / Config.get_float("train.fitness_tau_days"), gain)
	gs.strength = _move(gs.strength, strength_target() * u_cut, body_days / Config.get_float("train.strength_tau_days"), gain)


## target_floor + target_range x (1 - e^(-target_rate x minutes / ref_min)).
static func _target(minutes: float, ref_min: float) -> float:
	return Config.get_float("train.target_floor") + Config.get_float("train.target_range") \
			* (1.0 - exp(-Config.get_float("train.target_rate") * minutes / ref_min))


## The minutes per day whose target is this level (the inverse of _target); 0 at the floor,
## and at most a whole day for a level the target can never reach.
static func _minutes_for(level: float, ref_min: float) -> float:
	var share := (level - Config.get_float("train.target_floor")) / Config.get_float("train.target_range")
	if share <= 0.0:
		return 0.0
	var whole_day := Config.get_float("units.hours_per_day") * Config.get_float("units.minutes_per_hour")
	return minf(-ref_min / Config.get_float("train.target_rate") * log(maxf(1.0 - share, 0.0)), whole_day)


## Moves value toward target by the share 1 - e^(-time / tau); a gain is multiplied by gain_cut.
static func _move(value: float, target: float, time_over_tau: float, gain_cut: float) -> float:
	var change := (target - value) * (1.0 - exp(-time_over_tau))
	if change > 0.0:
		change *= gain_cut
	return clampf(value + change, 0.0, 1.0)


## value moves toward goal by the share 1 - e^(-time / tau).
static func _toward(value: float, goal: float, time_over_tau: float) -> float:
	return value + (goal - value) * (1.0 - exp(-time_over_tau))
