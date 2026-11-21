extends Button
## Milestone 40 (documentation/ui_v2/changes.md, change 5): football's help strip, which is the
## help button: a see-through pill (656 x 64) with a white "?" circle and the controls in one line
## (FOOTBALL_CONTROLS_TOUCH or _KEYS). The control is 88 high around it (the touch area, rule 2).

const Ui := preload("res://scripts/ui/ui_style.gd")

const STRIP_HEIGHT := 64.0
const CIRCLE_X := 44.0
const CIRCLE_RADIUS := 20.0
const TEXT_X := 80.0

## The key of the controls' line.
var line_key := "FOOTBALL_CONTROLS_TOUCH":
	set(value):
		if value != line_key:
			line_key = value
			queue_redraw()


func _ready() -> void:
	theme_type_variation = &"ActionButton"


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _draw() -> void:
	var strip := Rect2(0.0, (size.y - STRIP_HEIGHT) * 0.5, size.x, STRIP_HEIGHT)
	var radius := STRIP_HEIGHT * 0.5 - 0.5
	var color := Color(1, 1, 1, 0.14) if is_hovered() else Ui.WHITE_08
	draw_colored_polygon(Ui.rounded_rect_points(strip, radius), color)
	Ui.draw_outline(self, Ui.rounded_rect_points(strip.grow(-1.0), radius - 1.0), Ui.WHITE_25, Ui.BORDER_THIN)
	var middle := strip.get_center().y
	draw_circle(Vector2(CIRCLE_X, middle), CIRCLE_RADIUS, Color.WHITE, true, -1.0, true)
	Ui.draw_centred_text(self, Ui.FONT_HEAVY, Vector2(CIRCLE_X, middle), "?", 26, Ui.INK)
	var line := tr(line_key)
	var fitted := Ui.fit_font_size(Ui.FONT_BOLD, line, 20, size.x - TEXT_X - 20.0)
	var baseline := middle + (Ui.FONT_BOLD.get_ascent(fitted) - Ui.FONT_BOLD.get_descent(fitted)) * 0.5
	draw_string(Ui.FONT_BOLD, Vector2(TEXT_X, baseline), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, Color.WHITE)
