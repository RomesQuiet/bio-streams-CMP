extends Control
## Milestone 25: the curved ground (documentation/ui_specification_v1.md, 7.2; decision 85): the top
## of a very large circle, so it bends down at the sides like the Earth, from the avatar's feet to
## the bottom of the screen and over the whole width. Its colour follows the sky
## (scripts/ui/sky_palette.gd): blue by day, violet at dawn and dusk, dark blue at night. A soft
## shadow under the avatar's feet. It sits in the stage (it knows the ground line from it) but covers
## the whole screen (top_level).

const Palette := preload("res://scripts/ui/sky_palette.gd")
const Ui := preload("res://scripts/ui/ui_style.gd")

## Points along the curve: one every this many pixels.
const STEP := 16.0
const SHADOW_RADII := Vector2(96, 13)

var minute := 420.0:
	set(value):
		if value != minute:
			minute = value
			queue_redraw()
var shadow_visible := true:
	set(value):
		if value != shadow_visible:
			shadow_visible = value
			queue_redraw()
## Where the ground is, in screen pixels: x of the middle of the game's column, y of the avatar's
## feet (the ground line). Set from the stage by follow(), or by a screen without a stage.
var centre := Vector2(360, 900):
	set(value):
		if value != centre:
			centre = value
			queue_redraw()
## The stage whose bottom gives the ground line (empty: `centre` is set by the screen).
var stage: Control


func _ready() -> void:
	top_level = true
	z_index = Ui.Z_GROUND
	set_anchors_preset(PRESET_TOP_LEFT)
	mouse_filter = MOUSE_FILTER_IGNORE
	if stage == null and get_parent() is Control and get_parent().name == "Stage":
		stage = get_parent()
	get_viewport().size_changed.connect(_fit)
	_fit()


## The stage can move without changing size (a wider window moves the column): look every frame;
## it redraws only when something changed.
func _process(_delta: float) -> void:
	follow()


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	follow()
	queue_redraw()


## The ground line from the stage: its bottom minus Ui.GROUND_FROM_BOTTOM.
func follow() -> void:
	if stage and stage.is_inside_tree():
		var rect := stage.get_global_rect()
		# Before the first layout the stage has no size yet: keep the last ground line.
		if rect.size.y > Ui.GROUND_FROM_BOTTOM:
			centre = Vector2(rect.get_center().x, rect.end.y - Ui.GROUND_FROM_BOTTOM)


## The top of the ground (screen pixels) at x.
func top_at(x: float) -> float:
	var top := centre.y - Ui.GROUND_RISE
	var dx := absf(x - centre.x)
	var radius := Ui.GROUND_RADIUS
	if dx >= radius:
		return size.y
	return minf(top + radius - sqrt(radius * radius - dx * dx), size.y)


## The highest point of the ground, where the sky's horizon colour ends.
func horizon() -> float:
	return centre.y - Ui.GROUND_RISE


func _draw() -> void:
	var top := Palette.color(minute, Palette.GROUND_TOP)
	var bottom := Palette.color(minute, Palette.GROUND_BOTTOM)
	var points := PackedVector2Array()
	var x := 0.0
	while x < size.x:
		points.append(Vector2(x, top_at(x)))
		x += STEP
	points.append(Vector2(size.x, top_at(size.x)))
	var curve := points.duplicate()
	points.append(Vector2(size.x, size.y))
	points.append(Vector2(0.0, size.y))
	Ui.fill_vertical_gradient(self, points, horizon(), size.y, top, bottom)
	# A soft lighter edge along the top.
	draw_polyline(curve, Color(top.lightened(0.3), 0.55), 3.0, true)
	if shadow_visible:
		var shadow := Ui.ellipse_points(Vector2(centre.x, centre.y + 2.0), SHADOW_RADII, 32)
		draw_colored_polygon(shadow, Ui.SHADOW_COLOR)
