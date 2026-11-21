extends Control
## The football controls (Milestone 14): a joystick on a touch screen, and two big buttons, Pass
## and Shoot (Tackle when defending). On a computer the keys box takes the joystick's place.
## Milestone 40 (documentation/ui_v2/changes.md, change 5, table "Football"): every part at the
## table's place. This control covers x 24 to 696 and y 948 to 1144 of the column (ORIGIN), so
## the places below are the table's, moved by ORIGIN. Pressing Pass or Shoot moves its face down 8.

signal stick_moved(direction: Vector2)
signal pass_pressed
signal shoot_pressed
## A finger touched the pad: the device has a touch screen after all.
signal touch_seen

const NO_FINGER := -1
const MOUSE_FINGER := -2
const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")

const ORIGIN := Vector2(24, 948)
const STICK_CENTRE := Vector2(156, 1044)
const STICK_RADIUS := 92.0
const THUMB_RADIUS := 36.0
const ARROW_RADIUS := 70.0
const KEYS_BOX := Rect2(32, 956, 272, 176)
## Each keycap's top-left (52 x 52).
const KEYCAPS := {"W": Vector2(104, 984), "A": Vector2(48, 1044), "S": Vector2(104, 1044), "D": Vector2(160, 1044)}
const KEYCAP := 52.0
const MOVE_TEXT := Vector2(224, 1040)
const WASD_TEXT := Vector2(224, 1070)
## The buttons: their rect with the thickness (176 + 8).
const PASS_RECT := Rect2(320, 956, 176, 184)
const SHOOT_RECT := Rect2(512, 956, 176, 184)
const DEPTH := 8.0
const RADIUS := 28.0
## Inside a button, from its top-left: the icon's centre and box, the word's centre, the chip.
const ICON_CENTRE := Vector2(88, 48)
const ICON_BOX := 96.0
const WORD_CENTRE := Vector2(88, 110)
const CHIP := Rect2(60, 135, 56, 30)

## Within this share of the radius the stick counts as not moved.
@export var dead_zone := 0.15

var pass_text := ""
var shoot_text := ""
var pass_enabled := true
var shoot_enabled := true
## True on a touch screen (or after the first touch): the joystick; false: the keys box and chips.
var touch_mode := DisplayServer.is_touchscreen_available()
## "Move", already translated.
var move_text := ""

var _finger := NO_FINGER
var _direction := Vector2.ZERO
var _pass_press := 0.0:
	set(value):
		_pass_press = value
		queue_redraw()
var _shoot_press := 0.0:
	set(value):
		_shoot_press = value
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_let_go()
		return
	if event is InputEventScreenTouch:
		_on_touch(event.index, event.pressed, make_input_local(event).position)
	elif event is InputEventScreenDrag:
		if event.index == _finger:
			_aim(make_input_local(event).position)
	elif event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_on_touch(MOUSE_FINGER, event.pressed, make_input_local(event).position)
	elif event is InputEventMouseMotion and _finger == MOUSE_FINGER:
		_aim(make_input_local(event).position)


## A rect of the table in this control's pixels.
static func local(rect: Rect2) -> Rect2:
	return Rect2(rect.position - ORIGIN, rect.size)


func _on_touch(finger: int, pressed: bool, point: Vector2) -> void:
	if not pressed:
		if finger == _finger:
			_let_go()
		return
	if not Rect2(Vector2.ZERO, size).has_point(point):
		return
	if finger != MOUSE_FINGER and not touch_mode:
		touch_mode = true
		touch_seen.emit()
	if local(PASS_RECT).has_point(point):
		_press_pass()
	elif local(SHOOT_RECT).has_point(point):
		_press_shoot()
	elif point.x < local(PASS_RECT).position.x and touch_mode:
		_finger = finger
		_aim(point)


func _press_pass() -> void:
	if not pass_enabled:
		return
	_pass_press = 1.0
	create_tween().tween_property(self, "_pass_press", 0.0, Ui.BUTTON_RETURN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pass_pressed.emit()


func _press_shoot() -> void:
	if not shoot_enabled:
		return
	_shoot_press = 1.0
	create_tween().tween_property(self, "_shoot_press", 0.0, Ui.BUTTON_RETURN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	shoot_pressed.emit()


func _aim(point: Vector2) -> void:
	var offset := (point - (STICK_CENTRE - ORIGIN)) / STICK_RADIUS
	_direction = Vector2.ZERO if offset.length() < dead_zone else offset.limit_length(1.0)
	stick_moved.emit(_direction)
	queue_redraw()


func _let_go() -> void:
	if _finger == NO_FINGER:
		return
	_finger = NO_FINGER
	_direction = Vector2.ZERO
	stick_moved.emit(_direction)
	queue_redraw()


func _draw() -> void:
	if touch_mode:
		_draw_stick()
	else:
		_draw_keys()
	_draw_button(local(PASS_RECT), pass_text, "pass", "Z", Ui.PASS_COLOR, Ui.PASS_BASE, pass_enabled, _pass_press)
	_draw_button(local(SHOOT_RECT), shoot_text, "goal", "X", Ui.SHOOT_COLOR, Ui.SHOOT_BASE, shoot_enabled, _shoot_press)


## The joystick ring with four small arrows, and the thumb with its shadow.
func _draw_stick() -> void:
	var centre := STICK_CENTRE - ORIGIN
	draw_circle(centre, STICK_RADIUS, Ui.WHITE_08, true, -1.0, true)
	draw_arc(centre, STICK_RADIUS - 1.5, 0.0, TAU, 64, Ui.WHITE_60, Ui.BORDER_MEDIUM, true)
	for i in 4:
		var out := Vector2.from_angle(PI * 0.5 * i)
		var tip := centre + out * (ARROW_RADIUS + 5.0)
		var side := out.orthogonal() * 7.0
		draw_colored_polygon(PackedVector2Array([tip, tip - out * 10.0 + side, tip - out * 10.0 - side]), Ui.WHITE_60)
	var thumb := centre + _direction * (STICK_RADIUS - THUMB_RADIUS)
	draw_circle(thumb + Vector2(0, 4), THUMB_RADIUS, Ui.SHADOW_INK, true, -1.0, true)
	draw_circle(thumb, THUMB_RADIUS, Color.WHITE, true, -1.0, true)


## On a computer: the keys box, the W A S D keycaps, "Move" and "W A S D".
func _draw_keys() -> void:
	var box := local(KEYS_BOX)
	draw_colored_polygon(Ui.rounded_rect_points(box, 20.0), Ui.WHITE_08)
	for letter: String in KEYCAPS:
		var top_left: Vector2 = KEYCAPS[letter] - ORIGIN
		var cap := Rect2(top_left, Vector2(KEYCAP, KEYCAP))
		draw_colored_polygon(Ui.rounded_rect_points(Rect2(top_left + Vector2(0, 4), cap.size), 10.0), Ui.TILE_BASE)
		draw_colored_polygon(Ui.rounded_rect_points(cap, 10.0), Color.WHITE)
		Ui.draw_centred_text(self, Ui.FONT_HEAVY, cap.get_center(), letter, 26, Ui.INK)
	_left_text(Ui.FONT_BOLD, move_text, 22, MOVE_TEXT - ORIGIN, Color.WHITE, box.end.x - (MOVE_TEXT.x - ORIGIN.x) - 6.0)
	_left_text(Ui.FONT_BOLD, "W A S D", 20, WASD_TEXT - ORIGIN, Color(1, 1, 1, 0.8), box.end.x - (WASD_TEXT.x - ORIGIN.x) - 4.0)


## Pass or Shoot: the thickness, the face (down when pressed), the icon, the word and, on a
## computer, the key chip. Disabled at 45%.
func _draw_button(rect: Rect2, text: String, icon: String, key: String, face: Color, base: Color, enabled: bool,
		press: float) -> void:
	var alpha := 1.0 if enabled else Ui.DISABLED_ALPHA
	var height := rect.size.y - DEPTH
	draw_colored_polygon(Ui.rounded_rect_points(Rect2(rect.position + Vector2(0, DEPTH), Vector2(rect.size.x, height)), RADIUS),
			Color(base, alpha))
	var top := rect.position + Vector2(0, DEPTH * press)
	Ui.draw_gradient_box(self, Rect2(top, Vector2(rect.size.x, height)), RADIUS, Color(face.lightened(0.06), alpha), Color(face, alpha))
	Icons.draw(self, icon, top + ICON_CENTRE, ICON_BOX, Color(Ui.INK, alpha))
	Ui.draw_centred_text(self, Ui.FONT_HEAVY, top + WORD_CENTRE, text, 28, Color(Ui.INK, alpha), rect.size.x - 16.0)
	if not touch_mode:
		var chip := Rect2(top + CHIP.position, CHIP.size)
		draw_colored_polygon(Ui.rounded_rect_points(chip, CHIP.size.y * 0.5 - 0.5), Color(Ui.CHIP_COLOR, Ui.CHIP_COLOR.a * alpha))
		Ui.draw_centred_text(self, Ui.FONT_BOLD, chip.get_center(), key, 20, Color(1, 1, 1, alpha))


## Text whose left edge is at point.x, centred on point.y.
func _left_text(font: Font, line: String, font_size: int, point: Vector2, color: Color, max_width: float) -> void:
	var fitted := Ui.fit_font_size(font, line, font_size, max_width)
	var baseline := point.y + (font.get_ascent(fitted) - font.get_descent(fitted)) * 0.5
	draw_string(font, Vector2(point.x, baseline), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, color)
