extends Control
## The Beat bar of the cardio minigame (Milestone 12). A marker runs along the bar from the last
## tap, and the player taps when it is in the green zone. It turns red after a tap off the beat.

@export var background_color := Color(0.11, 0.13, 0.18)
@export var zone_color := Color(0.3, 0.7, 0.4)
@export var marker_color := Color(0.95, 0.95, 0.9)
@export var miss_color := Color(0.95, 0.5, 0.4)
@export var marker_width := 8.0
## How many intervals the whole bar shows, so the green zone is not at the very end.
@export var span := 1.5

## Time since the last tap, as a share of the interval.
var _elapsed := 0.0
## Half the width of the green zone, as a share of the interval.
var _zone := 0.0
var _on_beat := true


## Meal (Milestone 15): the Tummy bar. level, and the green zone from zone_from to zone_to, as
## shares of the bar.
var _level := -1.0
var _zone_from := 0.0
var _zone_to := 0.0
@export var level_color := Color(0.95, 0.65, 0.3)


func show_level(level: float, zone_from: float, zone_to: float) -> void:
	_level = level
	_zone_from = zone_from
	_zone_to = zone_to
	queue_redraw()


func show_time(elapsed: float, zone: float, on_beat: bool) -> void:
	_level = -1.0
	_elapsed = elapsed
	_zone = zone
	_on_beat = on_beat
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), background_color)
	if _level >= 0.0:
		draw_rect(Rect2(_zone_from * size.x, 0.0, (_zone_to - _zone_from) * size.x, size.y), zone_color)
		draw_rect(Rect2(0.0, size.y * 0.25, minf(_level, 1.0) * size.x, size.y * 0.5), level_color)
		return
	draw_rect(Rect2((1.0 - _zone) / span * size.x, 0.0, 2.0 * _zone / span * size.x, size.y), zone_color)
	var x := minf(_elapsed / span, 1.0) * size.x
	draw_rect(Rect2(x - marker_width * 0.5, 0.0, marker_width, size.y), marker_color if _on_beat else miss_color)
