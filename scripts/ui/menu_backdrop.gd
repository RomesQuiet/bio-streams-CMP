extends Control
## Milestone 40: the main menu's background, from the team's splash screen (21 Nov 2026): a sky
## that is a sunset on the left and night on the right (colours read from the picture's pixels),
## the sun on the left, the crescent moon and the stars on the right, three soft clouds, and a
## round blue hill on which the four figures stand, with their shadows. It covers the whole screen,
## also outside the game's column (decision 87); everything is placed in the 720-wide column.
## Only the look: it does not follow the game's clock.

const Ui := preload("res://scripts/ui/ui_style.gd")
const SkyBodies := preload("res://scripts/ui/sky_bodies.gd")

## The sky's colours, row by row from the top of the column (every 64 px, down to y 640), at the
## left edge, the middle and the right edge of the column.
const SKY_ROWS := [
	["#4b5cc4", "#1e4ab3", "#163a98"],
	["#6a65cc", "#2752bb", "#133795"],
	["#8470d3", "#3a58bf", "#143898"],
	["#b07cd1", "#4a5dc3", "#17399b"],
	["#dc8ac8", "#5461d1", "#1e3fa6"],
	["#fb9daf", "#6d67d3", "#2842b1"],
	["#fda5b5", "#8f6ed6", "#3247be"],
	["#fd99a1", "#b27ad3", "#4751cc"],
	["#fda786", "#cd8ad1", "#5a5cd5"],
	["#fdb175", "#e591c3", "#756ede"],
	["#fdc27a", "#f0a0b8", "#8e82ee"],
]
const ROW_STEP := 64.0
## How many cells across the column the sky's mesh has (more = smoother).
const SKY_COLUMNS := 16

## The hill: its top in the middle of the column, how fast it falls to the sides, and how far
## at most (so it never falls away on a very wide screen).
const HILL_TOP := 596.0
const HILL_RADIUS := 920.0
const HILL_MAX_DROP := 150.0
const HILL_TOP_COLOR := Color("#4466c6")
const HILL_BOTTOM_COLOR := Color("#3551b5")
const HILL_RIM := Color("#8a8fe0", 0.7)

const SUN_CENTRE := Vector2(74, 318)
const SUN_RADIUS := 32.0
const SUN_COLOR := Color("#fdefa8")
const MOON_CENTRE := Vector2(634, 296)
const MOON_RADIUS := 30.0
const MOON_COLOR := Color("#fef4d1")
## Each cloud: its centre, its width and its colour.
const CLOUDS := [
	[Vector2(240, 312), 172.0, Color("#d39bdc", 0.9)],
	[Vector2(524, 364), 150.0, Color("#7470da", 0.9)],
	[Vector2(30, 374), 120.0, Color("#feb1c5", 0.85)],
]
## Each star: where it is and its radius.
const STARS := [
	Vector3(508, 76, 1.8), Vector3(676, 78, 2.2), Vector3(596, 118, 1.6), Vector3(692, 172, 1.8),
	Vector3(470, 212, 1.4), Vector3(492, 264, 2.0), Vector3(592, 244, 1.6), Vector3(688, 260, 2.0),
	Vector3(552, 300, 1.4), Vector3(684, 348, 1.8), Vector3(640, 392, 1.6), Vector3(556, 408, 1.4),
	Vector3(420, 150, 1.2), Vector3(708, 430, 1.4),
]

## The column's rectangle on the screen (set by the menu every frame).
var column_rect := Rect2(0, 0, 720, 1280):
	set(value):
		if value != column_rect:
			column_rect = value
			queue_redraw()
## Shadows under the figures: [centre, radii], in the column.
var shadows: Array = []


func _ready() -> void:
	top_level = true
	z_index = Ui.Z_SKY
	set_anchors_preset(PRESET_TOP_LEFT)
	mouse_filter = MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()


## The hill's top edge at screen x.
func hill_y(x: float) -> float:
	var dx := x - (column_rect.position.x + column_rect.size.x * 0.5)
	var drop := HILL_MAX_DROP * (1.0 - exp(-dx * dx / (2.0 * HILL_RADIUS * HILL_MAX_DROP)))
	return column_rect.position.y + HILL_TOP + drop


func _draw() -> void:
	var origin := column_rect.position
	_draw_sky(origin)
	for star in STARS:
		draw_circle(origin + Vector2(star.x, star.y), star.z, Color(1, 1, 1, 0.9), true, -1.0, true)
	Ui.draw_glow(self, origin + SUN_CENTRE, SUN_RADIUS * 2.4, Color("#ffe9a8", 0.45))
	draw_circle(origin + SUN_CENTRE, SUN_RADIUS, SUN_COLOR, true, -1.0, true)
	Ui.draw_glow(self, origin + MOON_CENTRE, MOON_RADIUS * 2.0, Color(MOON_COLOR, 0.25))
	for part in SkyBodies.crescent(origin + MOON_CENTRE, MOON_RADIUS, 0.45):
		draw_colored_polygon(part, MOON_COLOR)
		Ui.draw_outline(self, part, MOON_COLOR, 1.2)
	for cloud in CLOUDS:
		_draw_cloud(origin + cloud[0], cloud[1], cloud[2])
	_draw_hill()
	for shadow in shadows:
		var points := Ui.ellipse_points(origin + shadow[0], shadow[1], 32)
		draw_colored_polygon(points, Color(Ui.INK, 0.3))
		Ui.draw_outline(self, points, Color(Ui.INK, 0.3), 1.0)


## The sky as a mesh of small quads, each corner coloured from SKY_ROWS (bilinear), from the top
## of the screen down to below the hill.
func _draw_sky(origin: Vector2) -> void:
	var bottom := hill_y(0.0) + 4.0
	var step_x := column_rect.size.x / SKY_COLUMNS
	var xs: Array[float] = [0.0]
	var x := origin.x - step_x * ceilf(origin.x / step_x)
	while x < size.x:
		if x > 0.0:
			xs.append(x)
		x += step_x
	xs.append(size.x)
	var ys: Array[float] = [0.0]
	var y := origin.y + ROW_STEP * 0.5
	while y < bottom:
		if y > 0.0:
			ys.append(y)
		y += ROW_STEP * 0.5
	ys.append(bottom)
	for j in ys.size() - 1:
		for i in xs.size() - 1:
			var corners := PackedVector2Array([Vector2(xs[i], ys[j]), Vector2(xs[i + 1], ys[j]),
					Vector2(xs[i + 1], ys[j + 1]), Vector2(xs[i], ys[j + 1])])
			var colors := PackedColorArray()
			for corner in corners:
				colors.append(sky_color(corner - origin))
			draw_polygon(corners, colors)


## The sky's colour at a point of the column (outside it, the colour of its nearest edge).
func sky_color(point: Vector2) -> Color:
	var row := clampf(point.y / ROW_STEP, 0.0, SKY_ROWS.size() - 1.0)
	var r0 := floori(row)
	var r1 := mini(r0 + 1, SKY_ROWS.size() - 1)
	var across := clampf(point.x / column_rect.size.x, 0.0, 1.0) * 2.0
	var c0 := mini(floori(across), 1)
	var t := across - c0
	var top := Color(SKY_ROWS[r0][c0]).lerp(Color(SKY_ROWS[r0][c0 + 1]), t)
	var low := Color(SKY_ROWS[r1][c0]).lerp(Color(SKY_ROWS[r1][c0 + 1]), t)
	return top.lerp(low, row - r0)


## A soft cloud: a flat-bottomed band with three round puffs on it.
func _draw_cloud(centre: Vector2, width: float, color: Color) -> void:
	var height := width * 0.16
	var band := Rect2(centre.x - width * 0.5, centre.y - height * 0.5, width, height)
	draw_colored_polygon(Ui.rounded_rect_points(band, height * 0.5 - 0.5), color)
	for puff in [Vector3(-0.18, -0.35, 0.16), Vector3(0.06, -0.62, 0.2), Vector3(0.26, -0.3, 0.13)]:
		draw_circle(centre + Vector2(puff.x * width, puff.y * height), puff.z * width, color, true, -1.0, true)


## The hill: from the left edge of the screen to the right along its curved top, down to the
## bottom of the screen, with a light rim.
func _draw_hill() -> void:
	var points := PackedVector2Array()
	var steps := 48
	for i in steps + 1:
		var x := size.x * i / steps
		points.append(Vector2(x, hill_y(x)))
	var rim := points.duplicate()
	points.append(Vector2(size.x, size.y))
	points.append(Vector2(0.0, size.y))
	Ui.fill_vertical_gradient(self, points, column_rect.position.y + HILL_TOP, size.y, HILL_TOP_COLOR, HILL_BOTTOM_COLOR)
	draw_polyline(rim, HILL_RIM, 3.0, true)
