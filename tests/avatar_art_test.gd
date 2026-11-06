extends SceneTree
## The avatar art (Milestone 16, user, 6 Nov 2026). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/avatar_art_test.gd

var _failures := 0


func _process(_delta: float) -> bool:
	var avatar: Control = load("res://scenes/avatar/avatar.tscn").instantiate()
	root.add_child(avatar)
	avatar.size = avatar.custom_minimum_size
	_test_sheets(avatar)
	_test_frames(avatar)
	_test_states()
	avatar.queue_free()
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _test_sheets(avatar: Control) -> void:
	var art: Dictionary = avatar.art_data()
	_check("5 bodies and 5 faces", art["columns"].size() == 5 and art["rows"].size() == 5)
	for age_group in ["child", "teenager"]:
		for sex in ["male", "female"]:
			var key := "%s_%s" % [age_group, sex]
			avatar.sheet = key
			_check("%s has art" % key, avatar.has_art())
			var texture: Texture2D = load(art["sheets"][key]["path"])
			_check("%s: each cell has the avatar's size" % key,
					texture.get_size() == avatar.custom_minimum_size * Vector2(5, 5))
			var mouth: Vector2 = avatar.mouth_point()
			_check("%s: the mouth is on the face" % key, mouth.y > avatar.size.y * 0.2 and mouth.y < avatar.size.y * 0.6)
	avatar.sheet = ""
	_check("no sheet: the egg", not avatar.has_art())
	_check("the egg's mouth", is_equal_approx(avatar.mouth_point().y, avatar.size.y * 0.55))
	avatar.sheet = "_"
	_check("no choices yet: the egg", not avatar.has_art())


func _test_frames(avatar: Control) -> void:
	avatar.sheet = "child_male"
	avatar.eyes_closed = false
	var cases := [
		[{}, Vector2i(2, 1), "healthy and neutral"],
		[{"happy": true}, Vector2i(2, 0), "happy"],
		[{"sad": true}, Vector2i(2, 2), "sad"],
		[{"tired": true, "happy": true}, Vector2i(2, 3), "tired wins over happy"],
		[{"tired": true, "sad": true}, Vector2i(2, 3), "tired wins over sad"],
		[{"thin": true}, Vector2i(3, 1), "thin"],
		[{"muscular": true}, Vector2i(4, 1), "muscular"],
		[{"overweight": true}, Vector2i(1, 1), "overweight"],
		[{"overweight": true, "obese": true}, Vector2i(0, 1), "obese"],
		[{"overweight": true, "muscular": true}, Vector2i(1, 1), "muscular with fat shows the overweight body"],
		[{"overweight": true, "obese": true, "muscular": true}, Vector2i(0, 1), "...and obese"],
	]
	for case in cases:
		avatar.states = case[0]
		_check(case[2], avatar.frame() == case[1])
	avatar.states = {"happy": true, "tired": true}
	avatar.eyes_closed = true
	_check("asleep wins over everything", avatar.frame() == Vector2i(2, 4))
	avatar.eyes_closed = false


func _test_states() -> void:
	var gs: Node = root.get_node("GameState")
	var states: GDScript = load("res://scripts/health/avatar_states.gd")
	gs.reset()
	gs.start_new_avatar("Test", "child", "male", "normal")
	gs.happiness = 0.6
	_check("happiness 0.6: happy", states.current()["happy"])
	gs.happiness = 0.59
	_check("happiness 0.59: neutral", not states.current()["happy"] and not states.current()["sad"])
	gs.weight_z = 2.5
	_check("z +2.5: obese and overweight", states.current()["obese"] and states.current()["overweight"])
	gs.weight_z = 1.5
	_check("z +1.5: overweight, not obese", states.current()["overweight"] and not states.current()["obese"])


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
