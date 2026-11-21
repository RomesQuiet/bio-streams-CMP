extends Button
## A choice of the creation screen (the team's picture, 21 Nov 2026): a rounded face in its own
## colour, a darker thickness, a thin white line, an icon and the text (a key; a second line, after
## "\n", is drawn smaller under the first). The chosen one (button_pressed) has a navy badge with a
## white check at its top right. A toggle button in a ButtonGroup.

const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")

const DEPTH := 6.0
const RADIUS := 24.0
const BADGE_RADIUS := 20.0

var face := Ui.TILE_COLOR
## The text's colour (white on dark faces).
var ink := Ui.INK
var icon_kind := ""
var icon_box := 56.0
var font_size := 32
var detail_size := 22
## False for the language buttons (they have no check).
var show_check := true
## The face while chosen, when it differs (the language buttons); transparent: always `face`.
var chosen_face := Color(0, 0, 0, 0)


func _ready() -> void:
	theme_type_variation = &"ActionButton"
	focus_mode = Control.FOCUS_NONE
	toggled.connect(queue_redraw.unbind(1))


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _draw() -> void:
	var height := size.y - DEPTH
	var base_face := chosen_face if chosen_face.a > 0.0 and button_pressed else face
	var color := base_face.lightened(0.06) if is_hovered() else base_face
	draw_colored_polygon(Ui.rounded_rect_points(Rect2(0, DEPTH, size.x, height), minf(RADIUS, height * 0.5 - 0.5)), base_face.darkened(0.28))
	var body := Rect2(0, 0, size.x, height)
	var radius := minf(RADIUS, height * 0.5 - 0.5)
	Ui.draw_gradient_box(self, body, radius, color.lightened(0.08), color)
	Ui.draw_outline(self, Ui.rounded_rect_points(body.grow(-1.5), radius - 1.5), Color(1, 1, 1, 0.85), Ui.BORDER_MEDIUM)
	var lines := atr(text).split("\n")
	var title := lines[0]
	var detail := lines[1].strip_edges().trim_prefix("(").trim_suffix(")") if lines.size() > 1 else ""
	var room := size.x - 32.0 - (icon_box + 18.0 if not icon_kind.is_empty() else 0.0)
	var title_size := maxi(Ui.fit_font_size(Ui.FONT_HEAVY, title, font_size, room), int(font_size * 0.7))
	var detail_fit := maxi(Ui.fit_font_size(Ui.FONT_BOLD, detail, detail_size, room), int(detail_size * 0.7))
	var text_width := Ui.FONT_HEAVY.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	if not detail.is_empty():
		text_width = maxf(text_width, Ui.FONT_BOLD.get_string_size(detail, HORIZONTAL_ALIGNMENT_LEFT, -1, detail_fit).x)
	var group := text_width + (icon_box + 18.0 if not icon_kind.is_empty() else 0.0)
	var left := (size.x - group) * 0.5
	var middle := body.get_center().y
	if not icon_kind.is_empty():
		Icons.draw(self, icon_kind, Vector2(left + icon_box * 0.5, middle), icon_box, ink)
		left += icon_box + 18.0
	if detail.is_empty():
		_line(Ui.FONT_HEAVY, title, title_size, left, middle)
	else:
		_line(Ui.FONT_HEAVY, title, title_size, left, middle - 16.0)
		_line(Ui.FONT_BOLD, detail, detail_fit, left, middle + 20.0)
	if show_check and button_pressed:
		var centre := Vector2(size.x - 26.0, 14.0)
		draw_circle(centre, BADGE_RADIUS + 3.0, Color.WHITE, true, -1.0, true)
		draw_circle(centre, BADGE_RADIUS, Ui.INK, true, -1.0, true)
		draw_polyline(PackedVector2Array([centre + Vector2(-8, 0), centre + Vector2(-2, 6), centre + Vector2(8, -6)]), Color.WHITE, 4.0, true)


func _line(font: Font, line: String, line_size: int, x: float, y: float) -> void:
	var baseline := y + (font.get_ascent(line_size) - font.get_descent(line_size)) * 0.5
	draw_string(font, Vector2(x, baseline), line, HORIZONTAL_ALIGNMENT_LEFT, -1, line_size, ink)
