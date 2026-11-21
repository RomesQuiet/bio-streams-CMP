extends Button
## Milestone 40: a button of the main menu, in the style of the team's splash screen (21 Nov 2026):
## a wide rounded face with a soft vertical gradient and a thin white outline, a darker thickness
## under it, and an icon left of the text, the two centred together. Pressing moves the face down
## by its thickness at once; it comes back in BUTTON_RETURN_SECONDS. The Button's own text is kept
## (a translation key, or "title\ndetail" for Continue) but drawn here (theme type ActionButton
## hides the normal drawing). A second line, when there is one, is drawn smaller under the first.

const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")

const DEPTH := 6.0
const RADIUS := 28.0
const FONT_SIZE := 32
const DETAIL_FONT_SIZE := 18
const ICON_BOX := 58.0
const GAP := 22.0

var face := Ui.NEUTRAL_COLOR
var base := Color("#9babde")
## An icon of scripts/ui/ui_icons.gd ("" for none).
var icon_kind := ""
## 0 up, 1 pressed down.
var press := 0.0:
	set(value):
		press = value
		queue_redraw()
var _tween: Tween


func _init(face_color := Ui.NEUTRAL_COLOR, base_color := Color("#9babde"), icon := "") -> void:
	face = face_color
	base = base_color
	icon_kind = icon


func _ready() -> void:
	theme_type_variation = &"ActionButton"
	focus_mode = Control.FOCUS_NONE
	button_down.connect(_on_down)
	button_up.connect(_on_up)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _on_down() -> void:
	if _tween:
		_tween.kill()
	press = 1.0


func _on_up() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "press", 0.0, Ui.BUTTON_RETURN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var offset := DEPTH * press
	var radius := minf(RADIUS, (size.y - DEPTH) * 0.5)
	Ui.draw_gradient_box(self, Rect2(0.0, DEPTH, size.x, size.y - DEPTH), radius, base, base)
	var body := Rect2(0.0, offset, size.x, size.y - DEPTH)
	var color := face.lightened(0.04) if is_hovered() else face
	Ui.draw_gradient_box(self, body, radius, color.lightened(0.08), color.darkened(0.03))
	Ui.draw_outline(self, Ui.rounded_rect_points(body.grow(-1.0), radius - 1.0), Color(1, 1, 1, 0.8), Ui.BORDER_THIN)
	var lines := atr(text).split("\n")
	var title := lines[0]
	var detail := lines[1] if lines.size() > 1 else ""
	var room := size.x - 48.0 - (ICON_BOX + GAP if not icon_kind.is_empty() else 0.0)
	var title_size := Ui.fit_font_size(Ui.FONT_HEAVY, title, FONT_SIZE, room)
	var detail_size := Ui.fit_font_size(Ui.FONT_BOLD, detail, DETAIL_FONT_SIZE, room)
	var text_width := Ui.FONT_HEAVY.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	if not detail.is_empty():
		text_width = maxf(text_width, Ui.FONT_BOLD.get_string_size(detail, HORIZONTAL_ALIGNMENT_LEFT, -1, detail_size).x)
	var group := text_width + (ICON_BOX + GAP if not icon_kind.is_empty() else 0.0)
	var left := (size.x - group) * 0.5
	var middle := body.get_center().y
	if not icon_kind.is_empty():
		Icons.draw(self, icon_kind, Vector2(left + ICON_BOX * 0.5, middle), ICON_BOX, Ui.INK)
		left += ICON_BOX + GAP
	if detail.is_empty():
		_text(Ui.FONT_HEAVY, title, title_size, left, middle)
	else:
		_text(Ui.FONT_HEAVY, title, title_size, left, middle - 12.0)
		_text(Ui.FONT_BOLD, detail, detail_size, left, middle + 17.0)


## Text whose left edge is x, centred on y.
func _text(font: Font, line: String, font_size: int, x: float, y: float) -> void:
	var baseline := y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(x, baseline), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Ui.INK)
