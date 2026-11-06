extends Control
## A small placeholder picture of the avatar's request in the speech bubble (Milestone 16):
## a bed, a burger, an apple, a fork, a screen or a ball. Hidden when there is no request.

const LINE := Color(0.95, 0.95, 0.9)
const BED_COLOR := Color(0.55, 0.65, 0.95)
const BUN_COLOR := Color(0.9, 0.62, 0.3)
const MEAT_COLOR := Color(0.45, 0.25, 0.15)
const LETTUCE_COLOR := Color(0.45, 0.8, 0.35)
const APPLE_COLOR := Color(0.85, 0.2, 0.2)
const LEAF_COLOR := Color(0.35, 0.75, 0.3)
const SCREEN_COLOR := Color(0.35, 0.75, 0.95)
const BALL_DARK := Color(0.1, 0.1, 0.12)

## A request of scripts/health/requests.gd ("tired", "fast_food", ...) or "" for none.
var kind := "":
	set(value):
		kind = value
		visible = not kind.is_empty()
		queue_redraw()


## The pictures are drawn for a 44-pixel box, then scaled to fit the real one.
const DRAWN_SIZE := 44.0


func _draw() -> void:
	draw_set_transform(size * 0.5, 0.0, Vector2.ONE * minf(size.x, size.y) / DRAWN_SIZE)
	var c := Vector2.ZERO
	match kind:
		"tired":
			draw_rect(Rect2(c + Vector2(-18, 0), Vector2(36, 8)), BED_COLOR)
			draw_rect(Rect2(c + Vector2(-18, -8), Vector2(4, 22)), BED_COLOR)
			draw_rect(Rect2(c + Vector2(-13, -6), Vector2(10, 6)), LINE)
			draw_string(get_theme_default_font(), c + Vector2(2, -6), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LINE)
			draw_string(get_theme_default_font(), c + Vector2(9, -13), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LINE)
		"fast_food":
			draw_circle(c + Vector2(0, -2), 16.0, BUN_COLOR)
			draw_rect(Rect2(c + Vector2(-17, 2), Vector2(34, 4)), LETTUCE_COLOR)
			draw_rect(Rect2(c + Vector2(-17, 6), Vector2(34, 5)), MEAT_COLOR)
			draw_rect(Rect2(c + Vector2(-16, 11), Vector2(32, 5)), BUN_COLOR)
		"healthy":
			draw_circle(c + Vector2(-5, 3), 11.0, APPLE_COLOR)
			draw_circle(c + Vector2(5, 3), 11.0, APPLE_COLOR)
			draw_line(c + Vector2(0, -6), c + Vector2(2, -14), MEAT_COLOR, 3.0)
			draw_circle(c + Vector2(7, -13), 4.0, LEAF_COLOR)
		"hungry":
			draw_line(c + Vector2(-6, -16), c + Vector2(-6, 16), LINE, 3.0)
			for x in [-11.0, -6.0, -1.0]:
				draw_line(c + Vector2(x, -16), c + Vector2(x, -6), LINE, 2.0)
			draw_line(c + Vector2(-11, -6), c + Vector2(-1, -6), LINE, 2.0)
			draw_line(c + Vector2(8, -16), c + Vector2(8, 16), LINE, 3.0)
			draw_circle(c + Vector2(8, -9), 4.0, LINE)
		"screens":
			draw_rect(Rect2(c + Vector2(-18, -13), Vector2(36, 24)), LINE, false, 3.0)
			draw_rect(Rect2(c + Vector2(-15, -10), Vector2(30, 18)), SCREEN_COLOR)
			draw_line(c + Vector2(-8, 16), c + Vector2(8, 16), LINE, 3.0)
		"football":
			draw_circle(c, 15.0, LINE)
			draw_circle(c, 5.0, BALL_DARK)
			for i in 5:
				var angle := TAU * i / 5.0 - PI / 2.0
				draw_circle(c + Vector2.from_angle(angle) * 12.0, 3.0, BALL_DARK)
