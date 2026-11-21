extends Control
## The Beat bar of the cardio minigame (Milestone 12). A marker runs along the bar from the last
## tap, and the player taps when it is in the green zone. It turns red after a tap off the beat.
## Milestone 40 (documentation/ui_v2/changes.md, rule 5): a timing bar has fully round ends, the
## TRACK colour, a white outline of 3 px and a green zone (ZONE) inset 6 px with radius 18. The
## marker is a white bar (cardio) or a white ring with 4 ticks (strength, marker_style "ring").

const Ui := preload("res://scripts/ui/ui_style.gd")
@export var background_color := Ui.TRACK
@export var zone_color := Ui.ZONE_COLOR
@export var marker_color := Color.WHITE
@export var miss_color := Ui.EAT_COLOR
@export var marker_width := 8.0
## How many intervals the whole bar shows, so the green zone is not at the very end.
@export var span := 1.5
## "bar" or "ring" (radius 22, line 5, with 4 ticks 10 long).
@export var marker_style := "bar"
const OUTLINE := 3.0
const INSET := 6.0
const ZONE_RADIUS := 18.0
const RING_RADIUS := 22.0
const RING_LINE := 5.0
const TICK := 10.0

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
@export var level_color := Color.WHITE


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
	var whole := Rect2(Vector2.ZERO, size)
	var track := Ui.rounded_rect_points(whole, size.y * 0.5 - 0.5)
	draw_colored_polygon(track, background_color)
	var inner := whole.grow(-INSET)
	var radius := minf(ZONE_RADIUS, inner.size.y * 0.5 - 0.5)
	if _level >= 0.0:
		_inner_box(_zone_from, _zone_to, inner, radius, zone_color)
		_inner_box(0.0, minf(_level, 1.0), inner, radius, level_color)
	else:
		# The marker's x is a share of the whole width, so the zone is too.
		var from := ((1.0 - _zone) / span * size.x - inner.position.x) / inner.size.x
		var to := ((1.0 + _zone) / span * size.x - inner.position.x) / inner.size.x
		_inner_box(from, to, inner, radius, zone_color)
	Ui.draw_outline(self, Ui.rounded_rect_points(whole.grow(-OUTLINE * 0.5), size.y * 0.5 - OUTLINE * 0.5), Color.WHITE, OUTLINE)
	if _level >= 0.0:
		return
	var x := minf(_elapsed / span, 1.0) * size.x
	var color := marker_color if _on_beat else miss_color
	if marker_style == "ring":
		var centre := Vector2(clampf(x, RING_RADIUS, size.x - RING_RADIUS), size.y * 0.5)
		draw_arc(centre, RING_RADIUS, 0.0, TAU, 40, color, RING_LINE, true)
		for i in 4:
			var out := Vector2.from_angle(PI * 0.5 * i)
			Ui.draw_round_line(self, centre + out * (RING_RADIUS + RING_LINE * 0.5), centre + out * (RING_RADIUS + RING_LINE * 0.5 + TICK), color, 4.0)
	else:
		draw_rect(Rect2(x - marker_width * 0.5, 0.0, marker_width, size.y), color)


## A rounded box inside the bar from share a to share b of its width (clipped to the inside).
func _inner_box(a: float, b: float, inner: Rect2, radius: float, color: Color) -> void:
	var left := inner.position.x + clampf(a, 0.0, 1.0) * inner.size.x
	var right := inner.position.x + clampf(b, 0.0, 1.0) * inner.size.x
	if right - left < 1.0:
		return
	var box := Rect2(left, inner.position.y, right - left, inner.size.y)
	draw_colored_polygon(Ui.rounded_rect_points(box, minf(radius, box.size.x * 0.5 - 0.5)), color)
