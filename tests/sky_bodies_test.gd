extends SceneTree
## Milestone 24: the sun and the moon in the sky.
##   Godot --headless --path . -s res://tests/sky_bodies_test.gd

const SkyBodies := preload("res://scripts/ui/sky_bodies.gd")

var _failures := 0


func _process(_delta: float) -> bool:
	_test_arc()
	_test_point()
	print("%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "SOME FAILED", _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _test_arc() -> void:
	var a: Dictionary = SkyBodies.arc(7 * 60, 7, 19)
	_check("07:00 the sun rises on the left", a.body == "sun" and is_zero_approx(a.t))
	a = SkyBodies.arc(13 * 60, 7, 19)
	_check("13:00 the sun is in the middle", a.body == "sun" and is_equal_approx(a.t, 0.5))
	a = SkyBodies.arc(19 * 60, 7, 19)
	_check("19:00 the moon rises", a.body == "moon" and is_zero_approx(a.t))
	a = SkyBodies.arc(60, 7, 19)
	_check("01:00 the moon is in the middle", a.body == "moon" and is_equal_approx(a.t, 0.5))
	a = SkyBodies.arc(7 * 60 - 1, 7, 19)
	_check("06:59 the moon is setting on the right", a.body == "moon" and a.t > 0.99)


func _test_point() -> void:
	var left: Vector2 = SkyBodies.point(0.0, 700, 500, 300, 50)
	var top: Vector2 = SkyBodies.point(0.5, 700, 500, 300, 50)
	var right: Vector2 = SkyBodies.point(1.0, 700, 500, 300, 50)
	_check("rises on the ground at the left", is_equal_approx(left.x, 50) and is_equal_approx(left.y, 500))
	_check("highest in the middle", is_equal_approx(top.x, 350) and is_equal_approx(top.y, 200))
	_check("sets on the ground at the right", is_equal_approx(right.x, 650) and is_equal_approx(right.y, 500))


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
