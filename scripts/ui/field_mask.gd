extends Control
## Milestone 40 (documentation/ui_v2/changes.md, change 5): the football field's rounded shape
## (radius 28). It draws the shape in the first stripe's colour and clips its child, the
## FootballField drawing, to it (clip_children), so the stripes, lines and players stop at the
## rounded corners.

const Ui := preload("res://scripts/ui/ui_style.gd")
const RADIUS := 28.0


func _ready() -> void:
	clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_colored_polygon(Ui.rounded_rect_points(Rect2(Vector2.ZERO, size), RADIUS), Ui.FIELD_STRIPE_A)
