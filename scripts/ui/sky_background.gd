extends Control
## Milestone 25: the sky behind everything (documentation/ui_specification_v1.md, section 7): a
## vertical gradient from the top of the screen to the horizon whose colours follow the game's clock
## (scripts/ui/sky_palette.gd), and small white stars at fixed places that appear as it gets dark.
## It covers the whole screen, also outside the game's column on wide screens (decision 87).
## The sun and moon are scripts/ui/sky_bodies.gd, the ground scripts/ui/curved_ground.gd.

const Palette := preload("res://scripts/ui/sky_palette.gd")
const Ui := preload("res://scripts/ui/ui_style.gd")

## Fixed stars: how many, from a fixed seed, so they never move or blink at random.
const STAR_COUNT := 90
const STAR_SEED := 25
## Where the middle colour sits, as a share of the way from the top to the horizon.
const MIDDLE_SHARE := 0.55

## The game's minute of the day (a screen without a game clock sets a fixed one).
@export var minute := 420.0:
	set(value):
		if value != minute:
			minute = value
			queue_redraw()
## The horizon, in screen pixels from the top (set by the screen: the top of the ground).
var horizon_y := 900.0:
	set(value):
		if value != horizon_y:
			horizon_y = value
			queue_redraw()
## True on screens without a ground (the creation screen): the gradient reaches the bottom.
@export var fill_height := false
## Each star: x and y as shares of the screen, its radius and its own brightness.
var _stars: Array[Vector4] = []


func _ready() -> void:
	top_level = true
	z_index = Ui.Z_SKY
	set_anchors_preset(PRESET_TOP_LEFT)
	mouse_filter = MOUSE_FILTER_IGNORE
	var random := RandomNumberGenerator.new()
	random.seed = STAR_SEED
	for i in STAR_COUNT:
		_stars.append(Vector4(random.randf(), random.randf(), random.randf_range(0.9, 2.2), random.randf_range(0.45, 1.0)))
	get_viewport().size_changed.connect(_fit)
	_fit()


## Covers the whole visible screen.
func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()


func _draw() -> void:
	var top := Palette.color(minute, Palette.SKY_TOP)
	var middle := Palette.color(minute, Palette.SKY_MIDDLE)
	var horizon := Palette.color(minute, Palette.SKY_HORIZON)
	var line := size.y if fill_height else horizon_y
	var middle_y := line * MIDDLE_SHARE
	_band(0.0, middle_y, top, middle)
	_band(middle_y, line, middle, horizon)
	# Below the horizon (hidden by the ground, unless a place leaves it open).
	_band(line, size.y, horizon, horizon)
	var shine := Palette.stars(minute)
	if shine <= 0.0:
		return
	for star in _stars:
		var at := Vector2(star.x * size.x, star.y * line * 0.92)
		draw_circle(at, star.z, Color(Ui.STAR_COLOR, shine * star.w), true, -1.0, true)


func _band(from_y: float, to_y: float, a: Color, b: Color) -> void:
	if to_y <= from_y:
		return
	draw_polygon(PackedVector2Array([Vector2(0, from_y), Vector2(size.x, from_y), Vector2(size.x, to_y), Vector2(0, to_y)]),
			PackedColorArray([a, a, b, b]))
