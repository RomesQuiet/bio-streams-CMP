extends Button
## Milestone 25: one of the four big buttons (documentation/ui_specification_v1.md, section 10),
## drawn by code: a rounded body in the button's colour with a very soft vertical gradient and a thin
## light outline, a darker thickness under it and a short shadow, the icon over the text. Pressing
## moves the body down at once (BUTTON_PRESS_OFFSET), the thickness and shadow shrink and the colour
## darkens a little; letting go brings it back smoothly. A disabled button is paler and see-through,
## and its text stays readable. The Button's own text is kept (a translation key) but drawn here
## (theme type ActionButton hides the normal drawing).

const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")
## A disabled button's colour moves halfway to this grey.
const DISABLED_GREY := Color(0.78, 0.8, 0.88)

## "jump" is the Jump button of the video game (Milestone 35), in the entertainment colour.
@export_enum("exercise", "sleep", "eat", "entertainment", "jump") var kind := "exercise":
	set(value):
		kind = value
		queue_redraw()

## 0 up, 1 pressed down.
var press := 0.0:
	set(value):
		press = value
		queue_redraw()
var _tween: Tween


func _ready() -> void:
	theme_type_variation = &"ActionButton"
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
	# A disabled button is see-through as a whole (icon and text included), and paler.
	var alpha := 0.62 if disabled else 1.0
	if self_modulate.a != alpha:
		self_modulate = Color(1, 1, 1, alpha)
	var depth := Ui.BUTTON_BASE_DEPTH
	var offset := Ui.BUTTON_PRESS_OFFSET * press
	var radius := Ui.BUTTON_CORNER_RADIUS
	var color := Ui.action_color(kind)
	if disabled:
		color = color.lerp(DISABLED_GREY, 0.5)
	elif is_hovered():
		color = color.lightened(0.05)
	color = color.darkened(0.07 * press)
	var body := Rect2(0.0, offset, size.x, size.y - depth)
	# Short soft shadow under the button, gone when pressed.
	var shadow := Rect2(6.0, depth + 6.0, size.x - 12.0, size.y - depth)
	Ui.draw_gradient_box(self, shadow, radius, Color(Ui.SHADOW_COLOR, 0.0), Color(Ui.SHADOW_COLOR, Ui.SHADOW_COLOR.a * (1.0 - press)))
	# The thickness: a darker copy of the body, lower down.
	var side := color.darkened(0.22)
	Ui.draw_gradient_box(self, Rect2(0.0, depth, size.x, size.y - depth), radius, side, side)
	Ui.draw_gradient_box(self, body, radius, color.lightened(0.12), color)
	Ui.draw_outline(self, Ui.rounded_rect_points(body.grow(-1.0), radius - 1.0), Color(1, 1, 1, 0.65), Ui.BORDER_THIN)
	var icon_centre := Vector2(size.x * 0.5, body.position.y + body.size.y * 0.35)
	Icons.draw(self, kind, icon_centre, body.size.y * 0.46, Ui.ICON_INK)
	Ui.draw_centred_text(self, Ui.FONT_HEAVY, Vector2(size.x * 0.5, body.position.y + body.size.y * 0.76), atr(text),
			Ui.ACTION_FONT_SIZE, Ui.INK, size.x - 28.0)
