extends Control
## Milestone 24 (user, 18 Nov 2026): a sun and a moon that cross the sky in an arch, from left
## to right, so the time of day is easy to see. The sun is up from daylight.start_hour to
## daylight.end_hour (the same hours as the sky colour), the moon from then to the next sunrise.
## Milestone 25 (documentation/ui_specification_v1.md, 7.3 and 7.4): a light cream sun with a very
## soft glow, a warm glow near the horizon while it is low, and a cream crescent moon cut out by
## geometry (so it works over a sky gradient). Only the look; it changes no rule.

const Ui := preload("res://scripts/ui/ui_style.gd")

const SUN := "sun"
const MOON := "moon"
const MINUTES_PER_DAY := 24.0 * 60.0
const MINUTES_PER_HOUR := 60.0
## The ground line, measured from the bottom of the stage (the same as the Scenery's).
const GROUND_FROM_BOTTOM := Ui.GROUND_FROM_BOTTOM

@export var sun_radius := 34.0
@export var moon_radius := 30.0
## Height of the arch, as a share of the sky above the ground.
@export var arch_share := 0.86
## Below 1: the arch rises sooner and is flatter on top (see point()).
@export var arch_roundness := 0.45
@export var sun_color := Ui.SUN_COLOR
@export var sun_glow_color := Color(1.0, 0.96, 0.78, 0.4)
## The warm glow around a low sun (dawn and dusk).
@export var low_glow_color := Color(1.0, 0.72, 0.45, 0.32)
@export var low_glow_radius := 240.0
@export var moon_color := Ui.MOON_COLOR
## How far the cut-out circle is moved, as a share of the moon's radius.
@export var crescent_offset := 0.45



func _ready() -> void:
	# Behind the ground, which covers the whole screen (Milestone 25).
	z_index = Ui.Z_SUN_MOON


## Avatar minute of the day (set by the main screen when the time changes).
var minute := 0.0:
	set(value):
		if value != minute:
			minute = value
			queue_redraw()
## Kept for the screens that still set it (the crescent no longer needs the sky colour).
var sky_color := Color.BLACK


## Which body is up at this minute of the day and how far along its arch it is:
## {"body": SUN or MOON, "t": 0 (rising, left) to 1 (setting, right)}.
static func arc(minute: float, start_hour: float, end_hour: float) -> Dictionary:
	var start := start_hour * MINUTES_PER_HOUR
	var end := end_hour * MINUTES_PER_HOUR
	minute = fposmod(minute, MINUTES_PER_DAY)
	if minute >= start and minute < end:
		return {"body": SUN, "t": (minute - start) / (end - start)}
	var night := MINUTES_PER_DAY - (end - start)
	return {"body": MOON, "t": fposmod(minute - end, MINUTES_PER_DAY) / night}


## Where on the stage: x from left to right, y on an arch of height `height` above `ground`.
## roundness below 1 makes the arch rise sooner and stay high longer (flatter on top), so the sun
## and moon pass above the avatar's head instead of behind it (Milestone 26, user, 19 Nov 2026).
static func point(t: float, width: float, ground: float, height: float, margin: float, roundness := 1.0) -> Vector2:
	return Vector2(margin + t * (width - 2.0 * margin), ground - pow(sin(t * PI), roundness) * height)


func _draw() -> void:
	var a := arc(minute, Config.get_float("daylight.start_hour"), Config.get_float("daylight.end_hour"))
	var ground := size.y - GROUND_FROM_BOTTOM
	var sun: bool = a.body == SUN
	var radius := sun_radius if sun else moon_radius
	var at := point(a.t, size.x, ground, ground * arch_share, radius * 2.0, arch_roundness)
	if sun:
		# Low in the sky (near 0 or 1 along the arch) the sky around it glows warm.
		var low := pow(1.0 - sin(a.t * PI), 2.0)
		if low > 0.01:
			Ui.draw_glow(self, at, low_glow_radius, Color(low_glow_color, low_glow_color.a * low))
		Ui.draw_glow(self, at, radius * 2.2, sun_glow_color)
		draw_circle(at, radius, sun_color, true, -1.0, true)
	else:
		for part in crescent(at, radius, crescent_offset):
			draw_colored_polygon(part, moon_color)
			Ui.draw_outline(self, part, moon_color, 1.2)


## The crescent: a circle minus a slightly smaller circle moved up and to the right.
static func crescent(centre: Vector2, radius: float, offset: float) -> Array[PackedVector2Array]:
	var outer := Ui.ellipse_points(centre, Vector2.ONE * radius, 48)
	var cut := Ui.ellipse_points(centre + Vector2(radius * offset, -radius * offset * 0.5), Vector2.ONE * radius * 0.9, 48)
	return Geometry2D.clip_polygons(outer, cut)
