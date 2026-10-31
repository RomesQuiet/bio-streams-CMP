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

@export var stick_color := Color(0.11, 0.13, 0.18, 0.9)
@export var knob_color := Color(0.85, 0.87, 0.9)
@export var pass_color := Color(0.25, 0.5, 0.95)
@export var shoot_color := Color(0.9, 0.3, 0.3)
@export var disabled_color := Color(0.3, 0.32, 0.36)
@export var text_color := Color.WHITE
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
		draw_circle(_stick_centre(), _stick_radius(), stick_color)
		draw_circle(_stick_centre() + _direction * _stick_radius() * 0.6, _stick_radius() * 0.4, knob_color)
	else:
		draw_multiline_string(get_theme_default_font(), Vector2(0.0, 30.0), keys_text, HORIZONTAL_ALIGNMENT_LEFT,
				size.x * stick_share, keys_font_size, -1, text_color)
	var left := size.x * stick_share
	var half := size.y * 0.5
	_draw_button(Rect2(left + 8.0, 0.0, size.x - left - 8.0, half - 4.0), pass_text, pass_color if pass_enabled else disabled_color)
	_draw_button(Rect2(left + 8.0, half + 4.0, size.x - left - 8.0, half - 4.0), shoot_text, shoot_color if shoot_enabled else disabled_color)


func _draw_button(rect: Rect2, text: String, color: Color) -> void:
	draw_rect(rect, color)
	var font := get_theme_default_font()
	var y := rect.position.y + (rect.size.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(rect.position.x, y), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, text_color)
