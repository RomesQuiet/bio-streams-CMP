extends Control
## Milestone 25: the health bar as five rounded pills (documentation/ui_specification_v1.md, 4.2).
## The pills are only a mask over one continuous bar: health 3.7 fills three pills and 70% of the
## fourth. The red part is health (1 to 5 shown as 1 to 5 pills); while `danger` it flashes
## (decision 82). The fill moves smoothly to a new value.

const Ui := preload("res://scripts/ui/ui_style.gd")

const PILLS := 5
## The gap between pills, as a share of the height.
const GAP_SHARE := 0.28
## Real seconds the fill takes to move to a new value.
const MOVE_SECONDS := 0.6
## Pulses per real second while in danger.
const FLASH_RATE := 1.6

## The health shown (1 to 5).
var value := 1.0:
	set(new_value):
		new_value = clampf(new_value, 0.0, PILLS)
		if is_equal_approx(new_value, value):
			return
		value = new_value
		if _tween:
			_tween.kill()
		if not is_inside_tree() or not animate:
			shown = value
			return
		_tween = create_tween()
		_tween.tween_property(self, "shown", value, MOVE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
## The value drawn now (moves toward `value`).
var shown := 1.0:
	set(new_value):
		shown = new_value
		queue_redraw()
## False draws the new value at once (a save that loads, tests).
var animate := true
var danger := false:
	set(new_value):
		if new_value != danger:
			danger = new_value
			_flash_time = 0.0
			set_process(danger)
			queue_redraw()
var _tween: Tween
var _flash_time := 0.0


func _ready() -> void:
	set_process(danger)


func _process(delta: float) -> void:
	_flash_time += delta
	queue_redraw()


## How much of pill `index` (0 to 4) is red: 0 to 1.
static func pill_fill(health: float, index: int) -> float:
	return clampf(health - index, 0.0, 1.0)


## The rectangle of pill `index` in a bar of `bar_size`.
static func pill_rect(bar_size: Vector2, index: int) -> Rect2:
	var gap := bar_size.y * GAP_SHARE
	var width := (bar_size.x - gap * (PILLS - 1)) / PILLS
	return Rect2(index * (width + gap), 0.0, width, bar_size.y)


func _draw() -> void:
	var flash := 0.5 - 0.5 * cos(_flash_time * TAU * FLASH_RATE) if danger else 0.0
	var top := Ui.HEALTH_COLOR.lightened(0.12).lerp(Ui.HEALTH_FLASH, flash)
	var bottom := Ui.HEALTH_COLOR_DARK.lerp(Ui.HEALTH_COLOR, flash)
	for i in PILLS:
		var rect := pill_rect(size, i)
		var pill := Ui.rounded_rect_points(rect, rect.size.y * 0.5, 6)
		Ui.fill_vertical_gradient(self, pill, rect.position.y, rect.end.y, Ui.TRACK, Ui.TRACK)
		var filled := pill_fill(shown, i)
		if filled <= 0.0:
			continue
		var part := pill
		if filled < 1.0:
			var mask := PackedVector2Array([rect.position, Vector2(rect.position.x + rect.size.x * filled, rect.position.y),
					Vector2(rect.position.x + rect.size.x * filled, rect.end.y), Vector2(rect.position.x, rect.end.y)])
			var cut := Geometry2D.intersect_polygons(pill, mask)
			if cut.is_empty():
				continue
			part = cut[0]
		Ui.fill_vertical_gradient(self, part, rect.position.y, rect.end.y, top, bottom)
