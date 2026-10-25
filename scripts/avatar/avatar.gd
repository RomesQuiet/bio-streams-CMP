@tool
extends Control
## Placeholder avatar: an egg shape drawn with code, filling this control's rect.
## The bottom of the rect is where the egg touches the ground.

@export var body_color := Color(0.98, 0.9, 0.75)
@export var outline_color := Color(0.35, 0.25, 0.2)
@export var eye_color := Color(0.15, 0.12, 0.1)
@export_range(16, 128) var point_count := 64
## Placeholder sleep animation: slow breathing (squash and stretch) in seconds per breath.
@export var breath_seconds := 2.4
@export var breath_squash := Vector2(1.04, 0.96)
## Placeholder hop used by activities without their own animation yet.
@export var hop_seconds := 0.6
@export var hop_height := 24.0
## Placeholder exercise animations: cardio is a fast, high hop; strength is a slow
## squat (squash and stretch).
@export var cardio_seconds := 0.35
@export var cardio_height := 36.0
@export var strength_seconds := 1.4
@export var strength_squash := Vector2(1.08, 0.88)
## Eating: a quick, small squash (chewing).
@export var eat_seconds := 0.5
@export var eat_squash := Vector2(1.03, 0.97)

var eyes_closed := false:
	set(value):
		eyes_closed = value
		queue_redraw()

## How far the avatar is drawn above the ground during hops. Animations change this
## instead of the node's position, so they never fight the screen layout.
var hop_offset := 0.0:
	set(value):
		hop_offset = value
		queue_redraw()

var _animation: Tween


func _ready() -> void:
	resized.connect(_on_resized)
	_on_resized()


func _on_resized() -> void:
	pivot_offset = Vector2(size.x * 0.5, size.y)
	queue_redraw()


## Plays a repeating placeholder animation by name (from data/activities.json)
## until stop_animation() is called. Unknown names use a simple hop.
func play_animation(animation_name: String) -> void:
	stop_animation()
	_animation = create_tween().set_loops()
	_animation.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match animation_name:
		"sleep":
			eyes_closed = true
			_animation.tween_property(self, "scale", breath_squash, breath_seconds * 0.5)
			_animation.tween_property(self, "scale", Vector2.ONE, breath_seconds * 0.5)
		"cardio":
			_animation.tween_property(self, "hop_offset", cardio_height, cardio_seconds * 0.5)
			_animation.tween_property(self, "hop_offset", 0.0, cardio_seconds * 0.5)
		"strength":
			_animation.tween_property(self, "scale", strength_squash, strength_seconds * 0.5)
			_animation.tween_property(self, "scale", Vector2.ONE, strength_seconds * 0.5)
		"eat":
			_animation.tween_property(self, "scale", eat_squash, eat_seconds * 0.5)
			_animation.tween_property(self, "scale", Vector2.ONE, eat_seconds * 0.5)
		_:
			_animation.tween_property(self, "hop_offset", hop_height, hop_seconds * 0.5)
			_animation.tween_property(self, "hop_offset", 0.0, hop_seconds * 0.5)


func stop_animation() -> void:
	if _animation:
		_animation.kill()
		_animation = null
	hop_offset = 0.0
	scale = Vector2.ONE
	eyes_closed = false


func _draw() -> void:
	draw_set_transform(Vector2(0.0, -hop_offset))
	var points := _egg_points()
	draw_colored_polygon(points, body_color)
	points.append(points[0])
	draw_polyline(points, outline_color, 4.0, true)
	var eye_y := size.y * 0.42
	var eye_radius := size.x * 0.05
	for eye_x in [size.x * 0.38, size.x * 0.62]:
		if eyes_closed:
			draw_line(Vector2(eye_x - eye_radius, eye_y), Vector2(eye_x + eye_radius, eye_y), eye_color, 4.0, true)
		else:
			draw_circle(Vector2(eye_x, eye_y), eye_radius, eye_color)


## Egg outline: an ellipse whose top half is taller and narrower than its bottom half.
func _egg_points() -> PackedVector2Array:
	var center := Vector2(size.x * 0.5, size.y * 0.58)
	var top_height := size.y * 0.58
	var bottom_height := size.y * 0.42
	var half_width := size.x * 0.5
	var points := PackedVector2Array()
	for i in point_count:
		var angle := TAU * i / point_count
		var s := sin(angle)
		var narrowing := 1.0 - 0.15 * maxf(0.0, -s)
		var height := bottom_height if s > 0.0 else top_height
		points.append(center + Vector2(cos(angle) * half_width * narrowing, s * height))
	return points
