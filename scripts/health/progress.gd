extends RefCounted
## XP (v1 Step 12, Milestone 10 Task 8; Milestone 22, decision 72). All numbers come from Config
## (group progress).
## - XP follows the target health every step (user, 18 Nov 2026): XP += per_health_point x every
##   change in target health, up or down, at any level, so XP moves while the player plays. The
##   health bar still moves once a day but no longer gives XP itself (nothing is counted twice).
## - Every avatar hour while target health is at least high_health_min: gain_per_avatar_hour
##   x (1 + hours at that level without a break / bonus_hours), at most max_multiplier (more XP at
##   high health).
## XP never goes below 0. Time stops when the game is closed, so the bonus never punishes time away.


## Step 9 of the update order (part): XP from the change in target health, and over time at high
## target health.
static func step(hours: float, _asleep: bool) -> void:
	var gs := GameState
	var target := gs.target_health
	# The first step after a new avatar or an older save only takes the starting point.
	if gs.xp_health >= 0.0 and target != gs.xp_health:
		gs.add_xp((target - gs.xp_health) * Config.get_float("progress.per_health_point"))
	gs.xp_health = target
	if target >= Config.get_float("progress.high_health_min"):
		gs.high_health_hours += hours
		var multiplier := minf(1.0 + gs.high_health_hours / Config.get_float("progress.bonus_hours"),
				Config.get_float("progress.max_multiplier"))
		gs.add_xp(Config.get_float("progress.gain_per_avatar_hour") * multiplier * hours)
	else:
		gs.high_health_hours = 0.0
