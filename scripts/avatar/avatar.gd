@tool
extends Control
## Placeholder avatar: an egg shape drawn with code, filling this control's rect.
## The bottom of the rect is where the egg touches the ground.

@export var body_color := Color(0.98, 0.9, 0.75)
@export var outline_color := Color(0.35, 0.25, 0.2)
@export var eye_color := Color(0.15, 0.12, 0.1)
@export_range(16, 128) var point_count := 64


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var points := _egg_points()
	draw_colored_polygon(points, body_color)
	points.append(points[0])
	draw_polyline(points, outline_color, 4.0, true)
	var eye_y := size.y * 0.42
	var eye_radius := size.x * 0.05
	draw_circle(Vector2(size.x * 0.38, eye_y), eye_radius, eye_color)
	draw_circle(Vector2(size.x * 0.62, eye_y), eye_radius, eye_color)


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
