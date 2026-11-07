extends Control
## A gauge for the failure screen's Details (user, 7 Nov 2026): a bar in the bars' style with
## the recommended zone in green and a marker where the avatar was. With split set, it is a
## bar of healthy (green) and fast-food (orange) meals instead.

const ZONE_COLOR := Color(0.3, 0.75, 0.35, 0.6)
const HEALTHY_COLOR := Color(0.3, 0.75, 0.35)
const FAST_FOOD_COLOR := Color(0.9, 0.55, 0.25)
const MARKER_COLOR := Color.WHITE
const MARKER_LINE := Color(0.1, 0.1, 0.12)
const MARKER_RADIUS := 11.0
## The bar's border (as the bars' theme), kept clear of the zone and the meal colours.
const INSET := 4.0

## The avatar's value, the recommended zone (zone_to < 0: no upper end) and the end of the scale.
var value := 0.0
var zone_from := 0.0
var zone_to := -1.0
var scale_max := 1.0
## Meals instead: healthy and fast-food meals (split = true).
var split := false
var healthy := 0
var fast_food := 0


func _init() -> void:
	custom_minimum_size = Vector2(0, 30)
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	var bar := Rect2(Vector2.ZERO, size)
	draw_style_box(get_theme_stylebox("background", "ProgressBar"), bar)
	var inner := bar.grow(-INSET)
	if split:
		var meals := healthy + fast_food
		if meals > 0:
			var healthy_width := inner.size.x * healthy / meals
			draw_rect(Rect2(inner.position, Vector2(healthy_width, inner.size.y)), HEALTHY_COLOR)
			draw_rect(Rect2(inner.position + Vector2(healthy_width, 0.0), Vector2(inner.size.x - healthy_width, inner.size.y)), FAST_FOOD_COLOR)
		return
	var top := zone_to if zone_to >= 0.0 else scale_max
	var left := inner.position.x + inner.size.x * clampf(zone_from / scale_max, 0.0, 1.0)
	var right := inner.position.x + inner.size.x * clampf(top / scale_max, 0.0, 1.0)
	draw_rect(Rect2(left, inner.position.y, right - left, inner.size.y), ZONE_COLOR)
	var x := inner.position.x + inner.size.x * clampf(value / scale_max, 0.0, 1.0)
	var middle := Vector2(x, size.y * 0.5)
	draw_circle(middle, MARKER_RADIUS, MARKER_COLOR)
	draw_arc(middle, MARKER_RADIUS, 0.0, TAU, 24, MARKER_LINE, 3.0, true)
