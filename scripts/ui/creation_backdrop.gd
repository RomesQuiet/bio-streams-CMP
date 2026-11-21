extends Control
## The creation screen's background (the team's picture, 21 Nov 2026): a gradient from blue at the
## top through lavender to peach at the bottom (colours read from the picture), with a few faint
## stars at the top. It covers the whole screen, also outside the column (decision 87).

const Ui := preload("res://scripts/ui/ui_style.gd")

## [share of the screen's height, colour].
const STOPS := [[0.0, "#3b63dc"], [0.25, "#4a6bde"], [0.5, "#647be5"], [0.75, "#b496d4"], [0.875, "#e9acb4"], [1.0, "#fdbba5"]]
const STARS := [Vector2(0.06, 0.04), Vector2(0.22, 0.09), Vector2(0.38, 0.03), Vector2(0.55, 0.07), Vector2(0.9, 0.12),
		Vector2(0.12, 0.2), Vector2(0.95, 0.27), Vector2(0.7, 0.16), Vector2(0.03, 0.33)]


func _ready() -> void:
	top_level = true
	z_index = Ui.Z_SKY
	set_anchors_preset(PRESET_TOP_LEFT)
	mouse_filter = MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()


func _draw() -> void:
	for i in STOPS.size() - 1:
		var top: float = STOPS[i][0] * size.y
		var bottom: float = STOPS[i + 1][0] * size.y
		var a := Color(STOPS[i][1])
		var b := Color(STOPS[i + 1][1])
		draw_polygon(PackedVector2Array([Vector2(0, top), Vector2(size.x, top), Vector2(size.x, bottom), Vector2(0, bottom)]),
				PackedColorArray([a, a, b, b]))
	for star: Vector2 in STARS:
		draw_circle(star * size, 1.6, Color(1, 1, 1, 0.35), true, -1.0, true)
