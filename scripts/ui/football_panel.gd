extends Control
## Milestone 40 (documentation/ui_v2/changes.md, change 5, table "Football"): the football panel
## in place of the four buttons. It draws the panel, the ball icon, FOOTBALL, the minutes, a divider,
## Breath and its bar; its children are the small Stop pill, the controls (FootballPad) and the
## help strip (HelpButton). Places are the table's, in the column, moved by this control's
## top-left (x 24, y 812), so it keeps its distance from the bottom of the screen.

const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")

const ORIGIN := Vector2(24, 812)
const PANEL := Rect2(16, 812, 688, 424)
const ICON := Rect2(40, 828, 44, 44)
const TITLE_X := 100.0
const HEADER_Y := 852.0
const MINUTES_RIGHT := 488.0
const DIVIDER_Y := 890.0
const DIVIDER_FROM := 40.0
const DIVIDER_TO := 680.0
const BREATH_X := 40.0
const BREATH_Y := 920.0
const BREATH_BAR := Rect2(132, 908, 548, 24)
const HEIGHT := 436.0

var minutes_text := ""
var breath_share := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	custom_minimum_size.y = HEIGHT


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func show_values(minutes: String, breath: float) -> void:
	if minutes == minutes_text and is_equal_approx(breath, breath_share):
		return
	minutes_text = minutes
	breath_share = breath
	queue_redraw()


static func local(rect: Rect2) -> Rect2:
	return Rect2(rect.position - ORIGIN, rect.size)


func _draw() -> void:
	var panel := local(PANEL)
	draw_colored_polygon(Ui.rounded_rect_points(panel, 28.0), Ui.PANEL_92)
	Ui.draw_outline(self, Ui.rounded_rect_points(panel.grow(-1.0), 27.0), Color.WHITE, Ui.BORDER_THIN)
	Icons.draw(self, "football", local(ICON).get_center(), ICON.size.x, Color.WHITE)
	_text(Ui.FONT_HEAVY, tr("FOOTBALL_TITLE"), 30, TITLE_X, HEADER_Y, false)
	_text(Ui.FONT_BOLD, minutes_text, 26, MINUTES_RIGHT, HEADER_Y, true)
	draw_line(Vector2(DIVIDER_FROM, DIVIDER_Y) - ORIGIN, Vector2(DIVIDER_TO, DIVIDER_Y) - ORIGIN, Ui.WHITE_25, 2.0)
	_text(Ui.FONT_BOLD, tr("MINIGAME_BREATH"), 22, BREATH_X, BREATH_Y, false, BREATH_BAR.position.x - BREATH_X - 6.0)
	var bar := local(BREATH_BAR)
	var radius := bar.size.y * 0.5 - 0.5
	draw_colored_polygon(Ui.rounded_rect_points(bar, radius), Ui.TRACK)
	var width := clampf(breath_share, 0.0, 1.0) * bar.size.x
	if width >= 2.0:
		draw_colored_polygon(Ui.rounded_rect_points(Rect2(bar.position, Vector2(maxf(width, bar.size.y), bar.size.y)), radius), Ui.BREATH_FILL)


func _text(font: Font, line: String, font_size: int, x: float, y: float, right: bool, max_width := -1.0) -> void:
	var fitted := Ui.fit_font_size(font, line, font_size, max_width)
	var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x
	var left := (x - width if right else x) - ORIGIN.x
	var baseline := y - ORIGIN.y + (font.get_ascent(fitted) - font.get_descent(fitted)) * 0.5
	draw_string(font, Vector2(left, baseline), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, Color.WHITE)
