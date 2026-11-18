extends Control
## Milestone 24 (user, 18 Nov 2026): a sun and a moon that cross the sky in an arch, from left
## to right, so the time of day is easy to see. The sun is up from daylight.start_hour to
## daylight.end_hour (the same hours as the sky colour), the moon from then to the next sunrise.
## Only the look; it changes no rule. Placeholder art, drawn with shapes.

const SUN := "sun"
const MOON := "moon"
const MINUTES_PER_DAY := 24.0 * 60.0
const MINUTES_PER_HOUR := 60.0
## The ground line, measured from the bottom of the stage (the same as the Scenery's).
const GROUND_FROM_BOTTOM := 60.0

@export var sun_radius := 34.0
@export var moon_radius := 28.0
## Height of the arch, as a share of the sky above the ground.
@export var arch_share := 0.7
@export var sun_color := Color(1.0, 0.84, 0.25)
@export var sun_glow_color := Color(1.0, 0.9, 0.4, 0.25)
@export var moon_color := Color(0.93, 0.93, 0.85)
## How far the dark part of the crescent is moved, as a share of the moon's radius.
@export var crescent_offset := 0.45

## Avatar minute of the day (set by the main screen when the time changes).
var minute := 0.0:
	set(value):
		if value != minute:
			minute = value
			queue_redraw()
## The sky behind, used to cut the moon into a crescent.
var sky_color := Color.BLACK:
	set(value):
		if value != sky_color:
			sky_color = value
			queue_redraw()


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
static func point(t: float, width: float, ground: float, height: float, margin: float) -> Vector2:
	return Vector2(margin + t * (width - 2.0 * margin), ground - sin(t * PI) * height)


func _draw() -> void:
	var a := arc(minute, Config.get_float("daylight.start_hour"), Config.get_float("daylight.end_hour"))
	var ground := size.y - GROUND_FROM_BOTTOM
	var sun: bool = a.body == SUN
	var radius := sun_radius if sun else moon_radius
	var at := point(a.t, size.x, ground, ground * arch_share, radius * 2.0)
	if sun:
		draw_circle(at, radius * 1.5, sun_glow_color)
		draw_circle(at, radius, sun_color)
	else:
		draw_circle(at, radius, moon_color)
		draw_circle(at + Vector2(radius * crescent_offset, -radius * crescent_offset * 0.5), radius * 0.9, sky_color)
