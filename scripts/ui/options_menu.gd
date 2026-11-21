extends ColorRect
## Milestone 40 (documentation/ui_v2/changes.md, change 9, table "Exercise menu"): the panel that
## opens over the dimmed screen for exercise and entertainment: the panel, the icon at its top,
## the title (a child Label), a divider; the minutes and slider, the tiles, Cancel and Start are
## children placed by main.gd. Places are the table's, in the column (this control covers it).

const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")

const PANEL_X := 40.0
const PANEL_TOP := 214.0
const PANEL_WIDTH := 640.0
const PANEL_RADIUS := 28.0
const ICON := Rect2(336, 222, 48, 48)
const DIVIDER := Rect2(80, 330, 560, 0)

## The icon at the top ("exercise", "controller") and the panel's bottom (y).
var icon_kind := "exercise":
	set(value):
		icon_kind = value
		queue_redraw()
var panel_bottom := 904.0:
	set(value):
		panel_bottom = value
		queue_redraw()


func _draw() -> void:
	var panel := Rect2(PANEL_X, PANEL_TOP, PANEL_WIDTH, panel_bottom - PANEL_TOP)
	draw_colored_polygon(Ui.rounded_rect_points(panel, PANEL_RADIUS), Ui.PANEL_COLOR)
	Ui.draw_outline(self, Ui.rounded_rect_points(panel.grow(-1.0), PANEL_RADIUS - 1.0), Color.WHITE, Ui.BORDER_THIN)
	Icons.draw(self, icon_kind, ICON.get_center(), ICON.size.x, Color.WHITE)
	draw_line(DIVIDER.position, DIVIDER.position + Vector2(DIVIDER.size.x, 0), Ui.WHITE_25, 2.0)
