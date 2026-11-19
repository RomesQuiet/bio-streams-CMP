extends RefCounted
## Milestone 25: the colours of the sky and the ground over the 24 hours
## (documentation/ui_specification_v1.md, 7.2 and 7.6). One table of colour stops, each at an hour,
## read from the approved mockups (the day ground made greener in Milestone 26, user, 19 Nov 2026,
## so it reads as grass, not water); between two stops every colour is interpolated, so nothing jumps.
## Everything follows one value: the game's minute of the day (Clock.minute_of_day). Only the look;
## the hours of sunrise and sunset for the sun and moon are the `daylight` hours in config.

const MINUTES_PER_DAY := 24.0 * 60.0

## [hour, sky top, sky middle, sky at the horizon, ground top, ground bottom, stars (0 to 1)].
const STOPS := [
	[0.0, Color("#10164a"), Color("#1a2166"), Color("#2b3184"), Color("#2a3388"), Color("#1b2163"), 1.0],
	[4.75, Color("#10164a"), Color("#1a2166"), Color("#2b3184"), Color("#2a3388"), Color("#1b2163"), 1.0],
	[5.75, Color("#1d2672"), Color("#3c3b90"), Color("#7b5aa8"), Color("#3c3c94"), Color("#232a72"), 0.7],
	[6.5, Color("#3052b8"), Color("#8f7fd4"), Color("#f6a98a"), Color("#6658b8"), Color("#33358f"), 0.15],
	[7.5, Color("#2c5fca"), Color("#6c9ae4"), Color("#f6c9a4"), Color("#4f8fb0"), Color("#2f5c98"), 0.0],
	[9.0, Color("#2a66d6"), Color("#4a95e8"), Color("#9fdcf6"), Color("#4ea98a"), Color("#2f8078"), 0.0],
	[12.0, Color("#1f64de"), Color("#3b93ef"), Color("#8dd6fa"), Color("#52b28c"), Color("#318878"), 0.0],
	[15.0, Color("#2563d4"), Color("#4f95e6"), Color("#b5dcf0"), Color("#4ea98a"), Color("#2f8078"), 0.0],
	[16.5, Color("#2c62cc"), Color("#6a98e0"), Color("#f0d6a8"), Color("#5090a8"), Color("#305e9a"), 0.0],
	[18.25, Color("#36489f"), Color("#8a68c4"), Color("#f7a46a"), Color("#6152b2"), Color("#343a95"), 0.0],
	[19.25, Color("#2f3592"), Color("#7552b0"), Color("#ef8a5c"), Color("#5a46a8"), Color("#2d3188"), 0.0],
	[20.25, Color("#232a78"), Color("#3d3a96"), Color("#7c58b4"), Color("#3a3a96"), Color("#262b78"), 0.5],
	[22.25, Color("#1a2068"), Color("#2a3184"), Color("#5a4cc0"), Color("#2e3590"), Color("#20266c"), 1.0],
	[24.0, Color("#10164a"), Color("#1a2166"), Color("#2b3184"), Color("#2a3388"), Color("#1b2163"), 1.0],
]

const SKY_TOP := 1
const SKY_MIDDLE := 2
const SKY_HORIZON := 3
const GROUND_TOP := 4
const GROUND_BOTTOM := 5
const STARS := 6


## The value in column `column` of STOPS at this minute of the day, interpolated between the two
## stops around it (a Color, or a float for STARS).
static func at(minute: float, column: int) -> Variant:
	var hour := fposmod(minute, MINUTES_PER_DAY) / 60.0
	for i in STOPS.size() - 1:
		var a: Array = STOPS[i]
		var b: Array = STOPS[i + 1]
		if hour >= a[0] and hour <= b[0]:
			var t: float = (hour - a[0]) / maxf(b[0] - a[0], 0.0001)
			t = t * t * (3.0 - 2.0 * t)
			if column == STARS:
				return lerpf(a[column], b[column], t)
			return (a[column] as Color).lerp(b[column], t)
	return STOPS[0][column]


static func color(minute: float, column: int) -> Color:
	return at(minute, column)


static func stars(minute: float) -> float:
	return at(minute, STARS)
