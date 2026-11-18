extends Control
## Milestone 24 (user, 18 Nov 2026): a sun and a moon that cross the sky in an arch, from left
## to right, so the time of day is easy to see. The sun is up from daylight.start_hour to
## daylight.end_hour (the same hours as the sky colour), the moon from then to the next sunrise.
## Only the look; it changes no rule. Placeholder art, drawn with shapes.

const SUN := "sun"
const MOON := "moon"
const MINUTES_PER_DAY := 24.0 * 60.0
const MINUTES_PER_HOUR := 60.0


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
