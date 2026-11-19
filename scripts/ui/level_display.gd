extends Control
## Milestone 25: the XP level as "2 → 3" (documentation/ui_specification_v1.md, 4.4): the current
## level large and white, a small arrow, and the next level smaller and see-through. When the level
## changes the numbers roll up (since Milestone 26, decision 90, XP and the level never go down; a falling roll is kept for safety).
## No frame and no ring.

const Ui := preload("res://scripts/ui/ui_style.gd")

const CURRENT_SIZE := 40
const NEXT_SIZE := 26
const ARROW_WIDTH := 16.0
const SPACING := 7.0
const NEXT_ALPHA := 0.5
const ROLL_SECONDS := 0.45

var level := 0:
	set(value):
		if value == level:
			return
		_from = level
		level = value
		if _tween:
			_tween.kill()
		if not is_inside_tree() or not animate:
			roll = 1.0
			return
		roll = 0.0
		_tween = create_tween()
		_tween.tween_property(self, "roll", 1.0, ROLL_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
## 0 at the start of a change, 1 when the new numbers are in place.
var roll := 1.0:
	set(value):
		roll = value
		queue_redraw()
## False shows a new level at once (a save that loads, tests).
var animate := true
var _from := 0
var _tween: Tween


func _ready() -> void:
	clip_contents = true


func _draw() -> void:
	if roll < 1.0:
		var direction := 1.0 if level > _from else -1.0
		_draw_pair(_from, -direction * roll * size.y, 1.0 - roll)
		_draw_pair(level, direction * (1.0 - roll) * size.y, roll)
	else:
		_draw_pair(level, 0.0, 1.0)


## "current → next" centred, moved down by dy, with this opacity.
func _draw_pair(current: int, dy: float, alpha: float) -> void:
	var big := Ui.FONT_HEAVY
	var small := Ui.FONT_BOLD
	var current_text := str(current)
	var next_text := str(current + 1)
	var current_width := big.get_string_size(current_text, HORIZONTAL_ALIGNMENT_LEFT, -1, CURRENT_SIZE).x
	var next_width := small.get_string_size(next_text, HORIZONTAL_ALIGNMENT_LEFT, -1, NEXT_SIZE).x
	var total := current_width + SPACING + ARROW_WIDTH + SPACING + next_width
	var x := (size.x - total) * 0.5
	var baseline := size.y * 0.5 + (big.get_ascent(CURRENT_SIZE) - big.get_descent(CURRENT_SIZE)) * 0.5 + dy
	draw_string(big, Vector2(x, baseline), current_text, HORIZONTAL_ALIGNMENT_LEFT, -1, CURRENT_SIZE,
			Color(Ui.TEXT_PRIMARY, alpha))
	x += current_width + SPACING
	var arrow_y := baseline - small.get_ascent(NEXT_SIZE) * 0.38
	var arrow_color := Color(Ui.TEXT_PRIMARY, 0.6 * alpha)
	draw_line(Vector2(x, arrow_y), Vector2(x + ARROW_WIDTH, arrow_y), arrow_color, 2.5, true)
	draw_polyline(PackedVector2Array([Vector2(x + ARROW_WIDTH - 6.0, arrow_y - 5.0), Vector2(x + ARROW_WIDTH, arrow_y),
			Vector2(x + ARROW_WIDTH - 6.0, arrow_y + 5.0)]), arrow_color, 2.5, true)
	x += ARROW_WIDTH + SPACING
	draw_string(small, Vector2(x, baseline), next_text, HORIZONTAL_ALIGNMENT_LEFT, -1, NEXT_SIZE,
			Color(Ui.TEXT_PRIMARY, NEXT_ALPHA * alpha))
