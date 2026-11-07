extends SceneTree
## The avatar art (Milestone 16, user, 6 Nov 2026). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/avatar_art_test.gd

## How far (pixels of the picture, twice the screen's) the feet may be from the middle.
const FEET_TOLERANCE := 4.0

var _failures := 0


func _process(_delta: float) -> bool:
	var avatar: Control = load("res://scenes/avatar/avatar.tscn").instantiate()
	root.add_child(avatar)
	avatar.size = avatar.custom_minimum_size
	_test_sheets(avatar)
	_test_frames(avatar)
	_test_no_animation(avatar)
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
			var sizes_right := true
			var feet_centred := true
			for body in art["columns"].size():
				for face in art["rows"].size():
					var path: String = avatar.picture_path(Vector2i(body, face))
					var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
					# Twice the avatar's size, so it stays sharp on dense screens.
					if texture == null or texture.get_size() != avatar.custom_minimum_size * 2.0:
						sizes_right = false
					elif absf(_feet_x(texture.get_image()) - texture.get_width() * 0.5) > FEET_TOLERANCE:
						feet_centred = false
			_check("%s: all 25 pictures, at twice the avatar's size" % key, sizes_right)
			# So the avatar does not move when its picture changes (user, 7 Nov 2026).
			_check("%s: the feet are in the middle of every picture" % key, feet_centred)
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


## The art does not move like the egg (user, 6 Nov 2026); it only sleeps.
func _test_no_animation(avatar: Control) -> void:
	avatar.sheet = "teenager_female"
	for animation in ["cardio", "strength", "eat", "hop"]:
		avatar.play_animation(animation)
		_check("no %s animation" % animation, avatar.scale == Vector2.ONE and avatar.hop_offset == 0.0
				and not avatar.eyes_closed)
	avatar.stride(false)
	avatar.squat(true)
	avatar.chew()
	_check("no stride, squat or chew", avatar.scale == Vector2.ONE and avatar.hop_offset == 0.0)
	avatar.play_animation("sleep")
	_check("asleep: eyes closed, no breathing", avatar.eyes_closed and avatar.scale == Vector2.ONE)
	avatar.stop_animation()
	_check("awake again", not avatar.eyes_closed)


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


## The middle of the feet: the drawn part of the lowest tenth of the figure.
func _feet_x(image: Image) -> float:
	var figure := image.get_used_rect()
	var band := floori(figure.size.y * 0.1)
	var feet := image.get_region(Rect2i(figure.position.x, figure.end.y - band, figure.size.x, band)).get_used_rect()
	return figure.position.x + feet.get_center().x


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
