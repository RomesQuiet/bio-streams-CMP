extends Control
## Milestone 25: on screens wider than the game's column (decision 87) the panels that cover the game
## (settings, the canteen, the football explanation, the failure screen) darken only the column.
## This darkens the rest of the screen by the same amount, so the whole screen looks covered.

## The game's column (the screen's root control).
@export var column: Control
## How dark: the alpha of the panel's own colour (0 = nothing).
var amount := 0.0:
	set(value):
		if not is_equal_approx(value, amount):
			amount = value
			queue_redraw()
var color := Color.BLACK:
	set(value):
		if value != color:
			color = value
			queue_redraw()


func _ready() -> void:
	top_level = true
	set_anchors_preset(PRESET_TOP_LEFT)
	mouse_filter = MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()


func _draw() -> void:
	if amount <= 0.0 or column == null:
		return
	var inside := column.get_global_rect()
	var dim := Color(color, amount)
	draw_rect(Rect2(0.0, 0.0, inside.position.x, size.y), dim)
	draw_rect(Rect2(inside.end.x, 0.0, size.x - inside.end.x, size.y), dim)
	draw_rect(Rect2(inside.position.x, 0.0, inside.size.x, inside.position.y), dim)
	draw_rect(Rect2(inside.position.x, inside.end.y, inside.size.x, size.y - inside.end.y), dim)
