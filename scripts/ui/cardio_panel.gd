extends Control
## Milestone 40 (documentation/ui_v2/changes.md, change 4, table "Cardio on the street"): the
## cardio panel in place of the four buttons. It draws the panel, the runner icon, CARDIO, the
## minutes, the Steps and Breath bars and the timing box; its children are the small Stop pill,
## the timing bar and the Tap button. Places are the table's, in the column, moved by this control's
## top-left (x 24, y 760: the Margin and the panel's top), so it keeps its distance from the bottom.

const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")

## This control's top-left in the column.
const ORIGIN := Vector2(24, 760)
const PANEL := Rect2(12, 760, 696, 496)
const PANEL_RADIUS := 28.0
const ICON := Rect2(40, 784, 40, 40)
const TITLE_X := 92.0
const HEADER_Y := 804.0
const MINUTES_RIGHT := 476.0
const STEPS_Y := 860.0
const STEPS_BAR := Rect2(36, 880, 648, 24)
const BREATH_Y := 930.0
const BREATH_BAR := Rect2(36, 950, 648, 24)
const LEFT := 36.0
const RIGHT := 684.0
const TIMING_BOX := Rect2(24, 990, 672, 108)
const TIMING_Y := 1012.0
const TIMING_LEFT := 40.0
const TIMING_RIGHT := 680.0
const HEIGHT := 488.0

var minutes_text := ""
var steps_text := ""
var steps_share := 0.0
var breath_share := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	custom_minimum_size.y = HEIGHT


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


## Sets what the panel shows (only redraws when something changed).
func show_values(minutes: String, steps: String, steps_part: float, breath: float) -> void:
	if minutes == minutes_text and steps == steps_text and is_equal_approx(steps_part, steps_share) \
			and is_equal_approx(breath, breath_share):
		return
	minutes_text = minutes
	steps_text = steps
	steps_share = steps_part
	breath_share = breath
	queue_redraw()


## A rect of the table in this control's pixels.
static func local(rect: Rect2) -> Rect2:
	return Rect2(rect.position - ORIGIN, rect.size)


func _draw() -> void:
	var panel := local(PANEL)
	var points := Ui.rounded_rect_points(panel, PANEL_RADIUS)
	draw_colored_polygon(points, Ui.PANEL_92)
	Ui.draw_outline(self, Ui.rounded_rect_points(panel.grow(-1.0), PANEL_RADIUS - 1.0), Color.WHITE, Ui.BORDER_THIN)
	Icons.draw(self, "exercise", local(ICON).get_center(), ICON.size.x, Color.WHITE)
	_text(Ui.FONT_HEAVY, tr("CARDIO_TITLE"), 30, TITLE_X, HEADER_Y, Color.WHITE, false)
	_text(Ui.FONT_BOLD, minutes_text, 26, MINUTES_RIGHT, HEADER_Y, Color.WHITE, true)
	_text(Ui.FONT_BOLD, tr("MINIGAME_STEPS_LABEL"), 22, LEFT, STEPS_Y, Color.WHITE, false)
	_text(Ui.FONT_BOLD, steps_text, 22, RIGHT, STEPS_Y, Color.WHITE, true)
	_bar(local(STEPS_BAR), steps_share, Ui.STEPS_FILL)
	_text(Ui.FONT_BOLD, tr("MINIGAME_BREATH"), 22, LEFT, BREATH_Y, Color.WHITE, false)
	_bar(local(BREATH_BAR), breath_share, Ui.BREATH_FILL)
	draw_colored_polygon(Ui.rounded_rect_points(local(TIMING_BOX), 20.0), Ui.CHIP_COLOR)
	_text(Ui.FONT_BOLD, tr("TIMING"), 22, TIMING_LEFT, TIMING_Y, Color.WHITE, false)
	_text(Ui.FONT_BOLD, tr("TIMING_HINT"), 20, TIMING_RIGHT, TIMING_Y, Color(1, 1, 1, 0.8), true,
			TIMING_RIGHT - TIMING_LEFT - 120.0)


## A bar with round ends: the track and the fill up to share.
func _bar(rect: Rect2, share: float, fill: Color) -> void:
	var radius := rect.size.y * 0.5 - 0.5
	draw_colored_polygon(Ui.rounded_rect_points(rect, radius), Ui.TRACK)
	var width := clampf(share, 0.0, 1.0) * rect.size.x
	if width >= 2.0:
		var part := Rect2(rect.position, Vector2(maxf(width, rect.size.y), rect.size.y))
		draw_colored_polygon(Ui.rounded_rect_points(part, radius), fill)


## Text centred on the column's y, its left edge (or right edge) on the column's x.
func _text(font: Font, line: String, font_size: int, x: float, y: float, color: Color, right: bool, max_width := -1.0) -> void:
	var fitted := Ui.fit_font_size(font, line, font_size, max_width)
	var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x
	var left := (x - width if right else x) - ORIGIN.x
	var baseline := y - ORIGIN.y + (font.get_ascent(fitted) - font.get_descent(fitted)) * 0.5
	draw_string(font, Vector2(left, baseline), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, color)
