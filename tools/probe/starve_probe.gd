extends SceneTree
var _done := false
func _process(_d: float) -> bool:
	if _done: return true
	_done = true
	var sg: Node = root.get_node("SaveGame"); sg.save_path = "user://probe.json"; sg.use_web_storage = false; sg.auto_save_enabled = false
	root.get_node("HealthLog").enabled = false
	var hunger = load("res://scripts/health/hunger.gd")
	for diff in ["easy", "normal", "hard"]:
		root.get_node("Activities").reset(); root.get_node("Habits").reset(); root.get_node("Simulation").reset()
		var gs: Node = root.get_node("GameState"); gs.reset(); var clock: Node = root.get_node("Clock"); clock.reset()
		gs.start_new_avatar("T", "child", "male", diff)
		var portion: float = hunger.healthy_portion_kcal()
		print("== %s start z %.2f kg %.1f happy %.2f" % [diff, gs.weight_z, gs.weight_kg, gs.happiness])
		clock.debug_speed = 600.0
		for day in 30:
			while clock.day_elapsed_hours < clock.day_length_hours - 0.01 and clock.phase == clock.Phase.DAY:
				clock._process(minf(0.1, clock.avatar_hours_to_real_seconds(clock.day_length_hours - 0.01 - clock.day_elapsed_hours, false) / 600.0 + 1e-6))
			root.get_node("Activities").start("sleep", "sleep", 10.0)
			var guard := 0
			while clock.phase == clock.Phase.SLEEPING and guard < 100000:
				clock._process(0.1); guard += 1
			clock.wake_up()
			print("day %d z %.2f kg %.1f hunger %.1f meals happy %.2f target %.2f U %.2f danger %.0f low_h %.0f low_happy %.0f fail '%s' %.1f" % [day+1, gs.weight_z, gs.weight_kg, gs.hunger/portion, gs.happiness, gs.target_health, gs.deficit_u, gs.danger_hours, gs.health_low_hours, gs.happiness_low_hours, gs.failed_cause, gs.failed_day])
			if gs.failed_cause != "": break
	quit()
	return true
