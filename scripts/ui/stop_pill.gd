extends Button
## Milestone 40 (documentation/ui_v2/changes.md, change 2): the stop button as a pill: a salmon face
## with a darker thickness, a navy square and the word. The control is the touch area (at least
## 88 high, changes.md rule 2); the pill is drawn in its middle. Pressing moves the face down by its
## thickness at once; it comes back in BUTTON_RETURN_SECONDS. The Button's own text is the key.

const Ui := preload("res://scripts/ui/ui_style.gd")

## The pill's size, its thickness, the square and the text (changes.md, "Stop pill").
@export var pill_size := Vector2(260, 64)
@export var depth := 6.0
@export var square := 26.0
@export var square_radius := 6.0
## From the pill's left edge: the square's left and the text's left.
@export var square_left := 32.0
@export var text_left := 74.0
@export var font_size := 30
@export var face := Ui.STOP_COLOR
@export var base := Ui.STOP_BASE
## "square" (stop) or "sun" (a half sun, the Wake up pill of change 8).
@export var mark := "square"

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


## The pill's rect (without its thickness, not pressed), centred in the control.
func pill_rect() -> Rect2:
	var height := pill_size.y - depth
	return Rect2((size.x - pill_size.x) * 0.5, (size.y - pill_size.y) * 0.5, pill_size.x, height + depth)


func _draw() -> void:
	self_modulate.a = Ui.DISABLED_ALPHA if disabled else 1.0
	var whole := pill_rect()
	var radius := pill_size.y * 0.5 - 0.5
	# The face is pill_size high; the thickness shows under it.
	var base_rect := Rect2(whole.position + Vector2(0, depth), pill_size)
	Ui.draw_gradient_box(self, base_rect, radius, base, base)
	var body := Rect2(whole.position + Vector2(0, depth * press), pill_size)
	var color := face.lightened(0.04) if is_hovered() else face
	Ui.draw_gradient_box(self, body, radius, color.lightened(0.06), color)
	var middle := body.get_center().y
	if mark == "sun":
		_draw_half_sun(Vector2(body.position.x + square_left + 22.0, middle + 6.0))
	else:
		var mark_rect := Rect2(body.position.x + square_left, middle - square * 0.5, square, square)
		draw_colored_polygon(Ui.rounded_rect_points(mark_rect, square_radius, 4), Ui.INK)
	var label := atr(text)
	var room := pill_size.x - text_left - 16.0
	var fitted := Ui.fit_font_size(Ui.FONT_HEAVY, label, font_size, room)
	var baseline := middle + (Ui.FONT_HEAVY.get_ascent(fitted) - Ui.FONT_HEAVY.get_descent(fitted)) * 0.5
	draw_string(Ui.FONT_HEAVY, Vector2(body.position.x + text_left, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, Ui.INK)


## A half sun 44 x 28: a half circle of radius 14 on a line 44 long, and 5 rays 8 long.
func _draw_half_sun(bottom_centre: Vector2) -> void:
	draw_line(bottom_centre + Vector2(-22, 0), bottom_centre + Vector2(22, 0), Ui.INK, 4.0, true)
	var half := PackedVector2Array()
	for i in 17:
		half.append(bottom_centre + Vector2.from_angle(PI + PI * i / 16.0) * 9.0)
	draw_colored_polygon(half, Ui.INK)
	for i in 5:
		var out := Vector2.from_angle(PI + PI * (i + 0.5) / 5.0)
		Ui.draw_round_line(self, bottom_centre + out * 12.0, bottom_centre + out * 18.0, Ui.INK, 3.0)
