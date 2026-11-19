extends Control
## The football controls (Milestone 14): a joystick on the left and two buttons on the right. It
## reads touches itself, because Godot's Button only hears the first finger, and a player needs
## one finger on the joystick and another on a button at the same time.
## On a computer there is no joystick: the left side lists the keys, and the buttons show theirs.
## The first touch on a screen with a keyboard too brings the joystick back.

signal stick_moved(direction: Vector2)
signal pass_pressed
signal shoot_pressed
## The first touch on a device that started as a computer.
signal touch_seen

const NO_FINGER := -1
const MOUSE_FINGER := -2

## Colours of Milestone 25 (scripts/ui/ui_style.gd): a flat see-through joystick, and pressable
## buttons with a thickness (cyan Pass, salmon Shoot or Tackle) and navy text.
const Ui := preload("res://scripts/ui/ui_style.gd")
@export var stick_color := Color(1, 1, 1, 0.12)
@export var knob_color := Color(1, 1, 1, 0.92)
@export var pass_color := Ui.XP_COLOR
@export var shoot_color := Ui.EAT_COLOR
@export var disabled_color := Color(0.75, 0.78, 0.9, 0.45)
@export var text_color := Ui.INK
@export var keys_color := Color.WHITE
@export var font_size := 24
@export var keys_font_size := 20
## Moves smaller than this share of the joystick do nothing.
@export var dead_zone := 0.15
## Share of the width for the joystick.
@export var stick_share := 0.45

var pass_text := ""
var shoot_text := ""
var pass_enabled := true
var shoot_enabled := true
## True on a touch screen: the joystick is shown.
var touch_mode := DisplayServer.is_touchscreen_available()
## The list of keys, already translated.
var keys_text := ""

var _finger := NO_FINGER
var _direction := Vector2.ZERO


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
	if point.x < size.x * stick_share:
		if not touch_mode:
			return
		_finger = finger
		_aim(point)
	elif point.y < size.y * 0.5:
		pass_pressed.emit()
	else:
		shoot_pressed.emit()


func _aim(point: Vector2) -> void:
	var offset := (point - _stick_centre()) / _stick_radius()
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


func _stick_centre() -> Vector2:
	return Vector2(size.x * stick_share * 0.5, size.y * 0.5)


func _stick_radius() -> float:
	return minf(size.x * stick_share, size.y) * 0.5


func _draw() -> void:
	if touch_mode:
		draw_circle(_stick_centre(), _stick_radius(), stick_color, true, -1.0, true)
		draw_circle(_stick_centre(), _stick_radius(), Ui.HUD_LINE, false, Ui.BORDER_THIN, true)
		draw_circle(_stick_centre() + _direction * _stick_radius() * 0.6, _stick_radius() * 0.4, knob_color, true, -1.0, true)
	else:
		draw_multiline_string(get_theme_default_font(), Vector2(0.0, 30.0), keys_text, HORIZONTAL_ALIGNMENT_LEFT,
				size.x * stick_share, keys_font_size, -1, keys_color)
	var left := size.x * stick_share
	var half := size.y * 0.5
	_draw_button(Rect2(left + 8.0, 0.0, size.x - left - 8.0, half - 4.0), pass_text, pass_color if pass_enabled else disabled_color)
	_draw_button(Rect2(left + 8.0, half + 4.0, size.x - left - 8.0, half - 4.0), shoot_text, shoot_color if shoot_enabled else disabled_color)


## A pressable button: a darker thickness under a body with a soft gradient.
func _draw_button(rect: Rect2, text: String, color: Color) -> void:
	var depth := Ui.BUTTON_BASE_DEPTH * 0.75
	var body := Rect2(rect.position, rect.size - Vector2(0, depth))
	Ui.draw_gradient_box(self, Rect2(rect.position + Vector2(0, depth), body.size), 20.0, color.darkened(0.22), color.darkened(0.22))
	Ui.draw_gradient_box(self, body, 20.0, color.lightened(0.12), color)
	Ui.draw_outline(self, Ui.rounded_rect_points(body.grow(-1.0), 19.0), Color(1, 1, 1, 0.6), Ui.BORDER_THIN)
	Ui.draw_centred_text(self, Ui.FONT_HEAVY, body.get_center(), text, font_size, text_color, body.size.x - 12.0)
