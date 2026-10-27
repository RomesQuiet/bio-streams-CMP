extends RefCounted
## Physical, health and failure (v1 Steps 8, 11 and 12; Milestone 10 Task 8). All numbers come
## from Config (groups health and fail).
## - Physical = M(w, fitness, strength) x (diet_floor + (1 - diet_floor) x Q) x (1 - deficit.physical_cut
##   x U) x (1 - train.overreach_physical_cut x O), where M is the weighted power mean
##   health.physical_mix (p 0.5; weight 0.5, fitness 0.3, strength 0.2) and w the weight score of z.
## - Target health = 1 + 4 x the weighted power mean health.combine of Physical, Happiness and
##   Sleep (p 0.5, equal weights). It follows the measures every step.
## - Displayed health (the bar, decision 1) moves health.alpha_bar of the way to the target once
##   per avatar day, when a sleep ends. Its changes give or take XP.
## - Failure (no death): target health below fail.health_line for fail.health_hours (decision
##   10: the target, not the slow bar), or happiness below fail.happiness_line for
##   fail.happiness_hours (clock time).

const BodySize := preload("res://scripts/health/body_size.gd")
const Progress := preload("res://scripts/health/progress.gd")


static func physical() -> float:
	var gs := GameState
	var mix := "health.physical_mix."
	var body := power_mean([BodySize.weight_score(gs.weight_z), gs.fitness, gs.strength],
			[Config.get_float(mix + "weight"), Config.get_float(mix + "fitness"), Config.get_float(mix + "strength")],
			Config.get_float(mix + "p"))
	var floor_q := Config.get_float("health.diet_floor")
	return clampf(body * (floor_q + (1.0 - floor_q) * gs.diet_quality)
			* (1.0 - Config.get_float("deficit.physical_cut") * gs.deficit_u)
			* (1.0 - Config.get_float("train.overreach_physical_cut") * gs.overreach), 0.0, 1.0)


## Target health from three measures: 1 + 4 x their weighted power mean (health.combine).
static func target_health(p_physical: float, p_happiness: float, p_sleep: float) -> float:
	var weights := "health.combine.weights."
	var combined := power_mean([p_physical, p_happiness, p_sleep],
			[Config.get_float(weights + "physical"), Config.get_float(weights + "happiness"), Config.get_float(weights + "sleep")],
			Config.get_float("health.combine.p"))
	return lerpf(Config.get_float("measures.health_min"), Config.get_float("measures.health_max"), combined)


## Weighted power mean of values from 0 to 1 (weights divided by their sum). p = 0 is the
## geometric mean.
static func power_mean(values: Array, weights: Array, p: float) -> float:
	var total_weight := 0.0
	for weight in weights:
		total_weight += float(weight)
	var combined := 0.0
	if is_zero_approx(p):
		for i in values.size():
			combined += weights[i] / total_weight * log(clampf(values[i], 0.0, 1.0))
		return exp(combined)
	for i in values.size():
		combined += weights[i] / total_weight * pow(clampf(values[i], 0.0, 1.0), p)
	return clampf(pow(combined, 1.0 / p), 0.0, 1.0)


## Step 7 of the update order: the Physical measure.
static func update_physical() -> void:
	GameState.physical = physical()


## Step 9 of the update order (part): the failure timers. The health timer reads the target
## health (decision 10), so failure does not wait for the slow bar to come down.
static func step(hours: float, _asleep: bool) -> void:
	var gs := GameState
	gs.health_low_hours = gs.health_low_hours + hours if gs.target_health < Config.get_float("fail.health_line") else 0.0
	gs.happiness_low_hours = gs.happiness_low_hours + hours if gs.happiness < Config.get_float("fail.happiness_line") else 0.0


## Once per avatar day (when a sleep ends): the displayed health moves part of the way to the
## target; the change gives or takes XP.
static func daily_step() -> void:
	var gs := GameState
	var change := Config.get_float("health.alpha_bar") * (gs.target_health - gs.health)
	gs.health += change
	Progress.on_health_change(change)


## Failure: target health or happiness has stayed below its line for long enough.
static func is_at_failure() -> bool:
	var gs := GameState
	return gs.health_low_hours >= Config.get_float("fail.health_hours") \
			or gs.happiness_low_hours >= Config.get_float("fail.happiness_hours")
