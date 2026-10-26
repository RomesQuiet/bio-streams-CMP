extends RefCounted
## XP (v1 Step 12, Milestone 10 Task 8). All numbers come from Config (group progress).
## - XP += per_health_point x every change in displayed health (losing health loses XP).
## - Every avatar hour while displayed health is at least high_health_min: gain_per_avatar_hour
##   x (1 + hours at that level without a break / bonus_hours), at most max_multiplier.
## XP never goes below 0. Time stops when the game is closed, so the bonus never punishes time away.


static func on_health_change(change: float) -> void:
	if change != 0.0:
		GameState.add_xp(change * Config.get_float("progress.per_health_point"))


## Step 9 of the update order (part): XP over time at high health.
static func step(hours: float, _asleep: bool) -> void:
	var gs := GameState
	if gs.health >= Config.get_float("progress.high_health_min"):
		gs.high_health_hours += hours
		var multiplier := minf(1.0 + gs.high_health_hours / Config.get_float("progress.bonus_hours"),
				Config.get_float("progress.max_multiplier"))
		gs.add_xp(Config.get_float("progress.gain_per_avatar_hour") * multiplier * hours)
	else:
		gs.high_health_hours = 0.0
