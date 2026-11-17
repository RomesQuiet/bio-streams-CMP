extends Control
## The place behind the avatar during an activity ("scenery" in data/activities.json; user,
## 7 Nov 2026): "outside" is only the sky and the ground, "room" a wall with windows that show
## the sky (day or night), "bedroom" a grey floor and a bed seen from above: the avatar faces the
## player, so from above it lies on its back, its head on the pillow, and a blanket covers it
## from the chest down. The blanket is drawn by a second Scenery node in front of the avatar
## (front = true). "street" (Milestone 19, team idea 16 Nov 2026) is a street with trees seen
## from behind the running avatar: the avatar stays in place and the street comes closer, one
## step for every stride (stride()), so it looks as if it always runs forward. The grey ground is
## the Ground node, which is also the road under the avatar. Placeholder art, drawn with shapes.

const OUTSIDE := "outside"
const ROOM := "room"
const BEDROOM := "bedroom"
const STREET := "street"

const WALL_COLOR := Color(0.86, 0.8, 0.68)
const SKIRTING_COLOR := Color(0.62, 0.55, 0.45)
const FRAME_COLOR := Color(0.97, 0.97, 0.95)
const STAR_COLOR := Color(1.0, 1.0, 0.85)
## The bedroom floor: the same grey as the ground, so the whole place is floor.
const FLOOR_COLOR := Color(0.5, 0.5, 0.52)
const BED_FRAME_COLOR := Color(0.38, 0.38, 0.41)
const MATTRESS_COLOR := Color(0.92, 0.92, 0.93)
const PILLOW_COLOR := Color(1.0, 1.0, 1.0)
const BLANKET_COLOR := Color(0.7, 0.7, 0.74)
const BLANKET_FOLD_COLOR := Color(0.84, 0.84, 0.87)
const OUTLINE_COLOR := Color(0.1, 0.1, 0.12)
## Where the ground line is, from the bottom of this control (the Ground node).
const GROUND_FROM_BOTTOM := 60.0
const WINDOW_WIDTH := 130.0
const WINDOW_HEIGHT := 230.0
const WINDOW_TOP := 440.0
const WINDOW_SIDE := 24.0
const FRAME := 10.0
const SKIRTING := 16.0
## The bed around the avatar's picture: how much wider than it, and how far above its top.
const BED_SIDE := 40.0
const BED_ABOVE := 36.0
const BED_FRAME := 14.0
## The pillow is under the head (seen from above): it ends just below the chin, by this share of
## the avatar's height under the mouth, and reaches up to PILLOW_HEIGHT, staying on the mattress.
const PILLOW_WIDTH := 290.0
const PILLOW_HEIGHT := 190.0
const PILLOW_BELOW_MOUTH := 0.06
## Where the blanket starts: below the mouth, by this share of the avatar's height.
const CHEST_BELOW_MOUTH := 0.13
const FOLD := 34.0
## The floor also covers the screen's margins and the top bar around this control.
const FLOOR_BEYOND := 400.0
## The stars in the windows at night, as shares of a window.
const STARS := [Vector2(0.2, 0.15), Vector2(0.7, 0.3), Vector2(0.35, 0.6), Vector2(0.8, 0.75), Vector2(0.15, 0.85)]

## The street (display only, not game values): the horizon above the ground line, how far each
## stride moves the street (field units, about metres; walking is a shorter step), how fast the
## picture catches up with it, the nearest and farthest depth drawn, the gap between trees and
## between the road's centre dashes, and sizes at the nearest depth.
const HORIZON_ABOVE := 330.0
const RUN_STEP := 1.4
const WALK_STEP := 0.7
const CATCH_UP := 6.0
const NEAR := 4.0
const FAR := 90.0
const TREE_GAP := 9.0
const DASH_GAP := 4.0
const DASH_LENGTH := 2.0
const ROAD_HALF := 200.0
const PAVEMENT := 60.0
const TREE_SIDE := 640.0
const TREE_TRUNK := Vector2(40, 230)
const TREE_CROWN := 150.0
const GRASS_COLOR := Color(0.36, 0.6, 0.32)
const PAVEMENT_COLOR := Color(0.72, 0.7, 0.66)
const ROAD_COLOR := Color(0.5, 0.5, 0.52)
const DASH_COLOR := Color(0.95, 0.95, 0.9)
const TRUNK_COLOR := Color(0.45, 0.3, 0.18)
const CROWN_COLOR := Color(0.2, 0.5, 0.25)
## At night the street is darker by up to this share.
const NIGHT_DARKEN := 0.55

## How far the avatar has run on the street, and how far the picture shows (it catches up).
var distance := 0.0
var _shown := 0.0

## The avatar, for where the bed and the blanket go (set by scripts/ui/main.gd).
var avatar: Control
## The second node, in front of the avatar: only the blanket.
@export var front := false

var kind := "":
	set(value):
		if value != kind:
			kind = value
			queue_redraw()
## The sky seen through the windows, and how much daylight there is (0 night, 1 day).
var sky_color := Color.BLACK:
	set(value):
		if value != sky_color:
			sky_color = value
			queue_redraw()
var daylight := 1.0:
	set(value):
		if value != daylight:
			daylight = value
			queue_redraw()


func _draw() -> void:
	var ground := size.y - GROUND_FROM_BOTTOM
	if front:
		if kind == BEDROOM and avatar:
			_draw_blanket(ground)
		return
	match kind:
		ROOM:
			_draw_room(ground)
		BEDROOM:
			_draw_bedroom(ground)
		STREET:
			_draw_street(ground)


## One stride of the cardio minigame: the street comes one step closer.
func stride(walking: bool) -> void:
	distance += WALK_STEP if walking else RUN_STEP


func _process(delta: float) -> void:
	if kind != STREET or front or is_equal_approx(_shown, distance):
		return
	_shown = move_toward(_shown, distance, maxf(distance - _shown, RUN_STEP) * minf(1.0, delta * CATCH_UP))
	queue_redraw()


## Where a point of the street is on screen: depth z ahead of the avatar, side x at the nearest
## depth (pixels from the middle). Nearer is lower and wider.
func _street_point(ground: float, z: float, x: float) -> Vector2:
	var near_share := NEAR / z
	return Vector2(size.x * 0.5 + x * near_share, ground - HORIZON_ABOVE + HORIZON_ABOVE * near_share)


## Grass, pavements and the road from the horizon to the ground line, the moving centre dashes,
## and trees on both sides, the farthest first.
func _draw_street(ground: float) -> void:
	var dark := 1.0 - NIGHT_DARKEN * (1.0 - daylight)
	var tint := Color(dark, dark, dark)
	var horizon := ground - HORIZON_ABOVE
	draw_rect(Rect2(-FLOOR_BEYOND, horizon, size.x + FLOOR_BEYOND * 2.0, HORIZON_ABOVE), GRASS_COLOR * tint)
	for band in [[ROAD_HALF + PAVEMENT, PAVEMENT_COLOR], [ROAD_HALF, ROAD_COLOR]]:
		var far_left := _street_point(ground, FAR, -band[0])
		var far_right := _street_point(ground, FAR, band[0])
		var near_left := _street_point(ground, NEAR, -band[0])
		var near_right := _street_point(ground, NEAR, band[0])
		draw_colored_polygon(PackedVector2Array([far_left, far_right, near_right, near_left]), band[1] * tint)
	var first_dash := ceilf(_shown / DASH_GAP) * DASH_GAP
	var at := first_dash
	while at - _shown + NEAR < FAR:
		var z_near := at - _shown + NEAR
		var z_far := minf(z_near + DASH_LENGTH, FAR)
		var a := _street_point(ground, z_near, 0.0)
		var b := _street_point(ground, z_far, 0.0)
		var width := 10.0 * NEAR / z_near
		draw_colored_polygon(PackedVector2Array([a + Vector2(-width, 0), a + Vector2(width, 0),
				b + Vector2(width * z_near / z_far, 0), b - Vector2(width * z_near / z_far, 0)]), DASH_COLOR * tint)
		at += DASH_GAP
	var trees: Array[float] = []
	var tree := ceilf(_shown / TREE_GAP) * TREE_GAP
	while tree - _shown + NEAR < FAR:
		trees.append(tree - _shown + NEAR)
		tree += TREE_GAP
	trees.reverse()
	for z in trees:
		var share := NEAR / z
		for side in [-1.0, 1.0]:
			var foot := _street_point(ground, z, side * TREE_SIDE)
			var trunk := TREE_TRUNK * share
			draw_rect(Rect2(foot.x - trunk.x * 0.5, foot.y - trunk.y, trunk.x, trunk.y), TRUNK_COLOR * tint)
			draw_circle(foot - Vector2(0, trunk.y + TREE_CROWN * share * 0.6), TREE_CROWN * share, CROWN_COLOR * tint)


## A wall from the top to the ground, with one window on each side of the avatar.
func _draw_room(ground: float) -> void:
	draw_rect(Rect2(0.0, 0.0, size.x, ground), WALL_COLOR)
	draw_rect(Rect2(0.0, ground - SKIRTING, size.x, SKIRTING), SKIRTING_COLOR)
	for left in [WINDOW_SIDE, size.x - WINDOW_SIDE - WINDOW_WIDTH]:
		_draw_window(Rect2(left, ground - WINDOW_TOP, WINDOW_WIDTH, WINDOW_HEIGHT))


func _draw_window(window: Rect2) -> void:
	draw_rect(window, sky_color)
	for star in STARS:
		draw_circle(window.position + star * window.size, 2.5, Color(STAR_COLOR, 1.0 - daylight))
	draw_rect(window, FRAME_COLOR, false, FRAME)
	var middle := window.get_center()
	draw_line(Vector2(middle.x, window.position.y), Vector2(middle.x, window.end.y), FRAME_COLOR, FRAME * 0.6)
	draw_line(Vector2(window.position.x, middle.y), Vector2(window.end.x, middle.y), FRAME_COLOR, FRAME * 0.6)
	draw_rect(window.grow(FRAME * 0.5), OUTLINE_COLOR, false, 2.0)


## The grey floor and the bed from above, its pillow under the avatar's head.
func _draw_bedroom(ground: float) -> void:
	draw_rect(Rect2(-Vector2.ONE * FLOOR_BEYOND, size + Vector2.ONE * FLOOR_BEYOND * 2.0), FLOOR_COLOR)
	if avatar == null:
		return
	var bed := _bed(ground)
	_draw_box(bed, BED_FRAME_COLOR)
	_draw_box(bed.grow(-BED_FRAME), MATTRESS_COLOR)
	var bottom: float = avatar.position.y + avatar.mouth_point().y + avatar.size.y * PILLOW_BELOW_MOUTH
	var top := maxf(bottom - PILLOW_HEIGHT, bed.position.y + BED_FRAME * 2.0)
	var pillow := Rect2(bed.get_center().x - PILLOW_WIDTH * 0.5, top, PILLOW_WIDTH, bottom - top)
	draw_style_box(_rounded(PILLOW_COLOR), pillow)


## Over the avatar, from its chest over the foot of the bed (so the feet are covered), with the
## top folded back.
func _draw_blanket(ground: float) -> void:
	var bed := _bed(ground)
	var top: float = avatar.position.y + avatar.mouth_point().y + avatar.size.y * CHEST_BELOW_MOUTH
	var blanket := Rect2(bed.position.x + BED_FRAME, top, bed.size.x - BED_FRAME * 2.0, bed.end.y - top)
	_draw_box(blanket, BLANKET_COLOR)
	_draw_box(Rect2(blanket.position, Vector2(blanket.size.x, FOLD)), BLANKET_FOLD_COLOR)


## The bed: around the avatar's picture, from above its head to the ground line.
func _bed(ground: float) -> Rect2:
	var left := avatar.position.x - BED_SIDE
	var top := avatar.position.y - BED_ABOVE
	return Rect2(left, top, avatar.size.x + BED_SIDE * 2.0, ground - top)


func _rounded(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(30)
	style.set_border_width_all(3)
	style.border_color = OUTLINE_COLOR
	return style


func _draw_box(box: Rect2, color: Color) -> void:
	draw_rect(box, color)
	draw_rect(box, OUTLINE_COLOR, false, 3.0)
