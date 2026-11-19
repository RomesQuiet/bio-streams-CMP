extends Control
## The place behind the avatar during an activity ("scenery" in data/activities.json; user,
## 7 Nov 2026), redrawn in Milestone 25 in the style of documentation/ui_specification_v1.md
## (decision 89): shapes, soft gradients, navy outlines, the palette of the main screen.
## "outside" is the main screen's own sky and curved ground (nothing is drawn here). "room" (meals)
## is a calm blue room with a violet floor and two windows that show the real sky of the hour
## (scripts/ui/sky_palette.gd), with stars at night. "bedroom" (sleep) is a dark blue floor and a
## bed seen from above: the avatar faces the player, so from above it lies on its back, its head on
## the pillow, and a lavender blanket covers it from the chest down. The blanket is drawn by a
## second Scenery node in front of the avatar (front = true). "street" (Milestone 19, cardio) is a
## street with round trees seen from behind the running avatar: the avatar stays in place and the
## street comes closer, one step for every stride (stride()), so it looks as if it always runs
## forward; it moves all the time while the player keeps tapping, as fast as they tap, and stops
## only when a tap comes too late (user, 17 Nov 2026). Every place covers the whole screen (the
## column and beyond, decision 87), except the street's sky. Only the look; no rule.

const Ui := preload("res://scripts/ui/ui_style.gd")
const Palette := preload("res://scripts/ui/sky_palette.gd")

const OUTSIDE := "outside"
const ROOM := "room"
const BEDROOM := "bedroom"
const STREET := "street"

const OUTLINE_COLOR := Ui.INK
## The room: a blue wall, a darker band above the floor, and a violet floor.
const WALL_TOP := Color("#3d52b4")
const WALL_BOTTOM := Color("#6178d2")
const SKIRTING_COLOR := Color("#2a3589")
const FLOOR_TOP := Color("#8b74dc")
const FLOOR_BOTTOM := Color("#4a3fa8")
const FRAME_COLOR := Color("#f4f6ff")
## At night the room is darker by up to this share.
const ROOM_NIGHT := 0.35
## The bedroom seen from above.
const BEDROOM_FLOOR_TOP := Color("#3a409e")
const BEDROOM_FLOOR_BOTTOM := Color("#272c7e")
const PLANK_COLOR := Color(1, 1, 1, 0.06)
const BED_FRAME_COLOR := Color("#7a68cf")
const MATTRESS_COLOR := Color("#f4f6ff")
const PILLOW_COLOR := Color(1, 1, 1)
const PILLOW_SHADE := Color("#e3e6fb")
const BLANKET_COLOR := Ui.SLEEP_COLOR
const BLANKET_FOLD_COLOR := Color("#e7defe")
const BLANKET_STRIPE := Color(1, 1, 1, 0.22)

## Where the ground line is, from the bottom of this control (where the avatar's feet are).
const GROUND_FROM_BOTTOM := Ui.GROUND_FROM_BOTTOM
const WINDOW_WIDTH := 140.0
const WINDOW_HEIGHT := 220.0
const WINDOW_TOP := 450.0
const WINDOW_SIDE := 22.0
const FRAME := 10.0
const SKIRTING := 16.0
const PLANK_GAP := 46.0
## The bed around the avatar's picture: how much wider than it, and how far above its top.
const BED_SIDE := 40.0
const BED_ABOVE := 36.0
const BED_FRAME := 14.0
const BED_RADIUS := 26.0
## The pillow is under the head (seen from above): it ends just below the chin, by this share of
## the avatar's height under the mouth, and reaches up to PILLOW_HEIGHT, staying on the mattress.
const PILLOW_WIDTH := 290.0
const PILLOW_HEIGHT := 190.0
const PILLOW_BELOW_MOUTH := 0.06
## Where the blanket starts: below the mouth, by this share of the avatar's height.
const CHEST_BELOW_MOUTH := 0.13
const FOLD := 34.0
## The stars in the windows at night, as shares of a window.
const STARS := [Vector2(0.2, 0.15), Vector2(0.7, 0.3), Vector2(0.35, 0.6), Vector2(0.8, 0.75), Vector2(0.15, 0.85)]

## The street (display only, not game values): the horizon above the ground line, how far each
## stride moves the street (field units, about metres; walking is a shorter step), how much each
## new tap counts in the speed, the nearest and farthest depth drawn, the gap between trees and
## between the road's centre dashes, and sizes at the nearest depth.
const HORIZON_ABOVE := 330.0
const RUN_STEP := 1.4
const WALK_STEP := 0.7
const SPEED_FOLLOW := 0.5
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
## The haze above the street's horizon, so the far end fades into the sky.
const HAZE_HEIGHT := 90.0
const GRASS_TOP := Color("#55c99b")
const GRASS_BOTTOM := Color("#2e9d79")
const PAVEMENT_COLOR := Color("#c3c8ea")
const ROAD_COLOR := Color("#5d6ba8")
const DASH_COLOR := Color("#f4f6ff")
const TRUNK_COLOR := Color("#8a5a34")
const CROWN_COLOR := Color("#3fbf7f")
const CROWN_LIGHT := Color("#6fe0a2")
## At night the street is darker by up to this share.
const NIGHT_DARKEN := 0.5

## How far the avatar has run on the street, and how fast it moves now (units per real second).
var distance := 0.0
var speed := 0.0
## The street stops when no tap came for this long (set by scripts/ui/main.gd: the end of the
## Beat bar's green zone).
var late_after := 0.0
var _since_stride := INF

## The avatar, for where the bed and the blanket go (set by scripts/ui/main.gd).
var avatar: Control
## The second node, in front of the avatar: only the blanket.
@export var front := false

var kind := "":
	set(value):
		if value != kind:
			kind = value
			queue_redraw()
## The game's minute of the day: the windows show the sky of that hour.
var minute := 420.0:
	set(value):
		if value != minute:
			minute = value
			if kind == ROOM or kind == STREET:
				queue_redraw()
## How much daylight there is (0 night, 1 day; Clock.daylight_amount()).
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


## The whole visible screen, in this control's coordinates (the column and beyond it).
func cover() -> Rect2:
	var screen := get_viewport_rect() if is_inside_tree() else Rect2(Vector2.ZERO, size)
	var origin := global_position if is_inside_tree() else Vector2.ZERO
	return Rect2(screen.position - origin, screen.size).merge(Rect2(Vector2.ZERO, size))


## One stride of the cardio minigame: the street keeps moving at one step per gap between taps.
## expected: the gap the beat asks for, used after a stop (there is no gap to measure).
func stride(walking: bool, expected: float) -> void:
	var gap := _since_stride if _since_stride <= late_after else expected
	var wanted := (WALK_STEP if walking else RUN_STEP) / maxf(gap, 0.05)
	speed = wanted if is_moving() == false else lerpf(speed, wanted, SPEED_FOLLOW)
	_since_stride = 0.0


## Whether the street moves: a tap came, and not too long ago.
func is_moving() -> bool:
	return _since_stride <= late_after


## The street stops at once (the avatar stands still, or cardio ended).
func stop() -> void:
	_since_stride = INF


func _process(delta: float) -> void:
	if kind != STREET or front:
		return
	if is_moving():
		distance += speed * delta
		_since_stride += delta
		queue_redraw()


## Darker at night: the colour moved toward deep blue by up to `share`.
func _night(color: Color, share: float) -> Color:
	return color.lerp(Color("#10164a"), share * (1.0 - daylight))


# --- The street ------------------------------------------------------------------------------

## Where a point of the street is on screen: depth z ahead of the avatar, side x at the nearest
## depth (pixels from the middle). Nearer is lower and wider.
func _street_point(ground: float, z: float, x: float) -> Vector2:
	var near_share := NEAR / z
	return Vector2(size.x * 0.5 + x * near_share, ground - HORIZON_ABOVE + HORIZON_ABOVE * near_share)


## Grass, pavements and the road from the horizon to the bottom of the screen, the moving centre
## dashes, and round trees on both sides, the farthest first.
func _draw_street(ground: float) -> void:
	var area := cover()
	var horizon := ground - HORIZON_ABOVE
	var haze := Palette.color(minute, Palette.SKY_HORIZON)
	draw_polygon(PackedVector2Array([Vector2(area.position.x, horizon - HAZE_HEIGHT), Vector2(area.end.x, horizon - HAZE_HEIGHT),
			Vector2(area.end.x, horizon), Vector2(area.position.x, horizon)]),
			PackedColorArray([Color(haze, 0.0), Color(haze, 0.0), haze, haze]))
	var grass := PackedVector2Array([Vector2(area.position.x, horizon), Vector2(area.end.x, horizon),
			Vector2(area.end.x, area.end.y), Vector2(area.position.x, area.end.y)])
	Ui.fill_vertical_gradient(self, grass, horizon, area.end.y, _night(GRASS_TOP, NIGHT_DARKEN), _night(GRASS_BOTTOM, NIGHT_DARKEN))
	# The depth at the bottom of the screen: the road goes on under the avatar to the bottom.
	var nearest := NEAR * HORIZON_ABOVE / maxf(area.end.y - horizon, 1.0)
	for band in [[ROAD_HALF + PAVEMENT, PAVEMENT_COLOR], [ROAD_HALF, ROAD_COLOR]]:
		var color: Color = _night(band[1], NIGHT_DARKEN)
		draw_colored_polygon(PackedVector2Array([_street_point(ground, FAR, -band[0]), _street_point(ground, FAR, band[0]),
				_street_point(ground, nearest, band[0]), _street_point(ground, nearest, -band[0])]), color)
	for side in [-1.0, 1.0]:
		draw_line(_street_point(ground, FAR, side * ROAD_HALF), _street_point(ground, nearest, side * ROAD_HALF),
				Color(1, 1, 1, 0.35), 3.0, true)
	var dash_color := _night(DASH_COLOR, NIGHT_DARKEN)
	var at := floorf((distance + nearest - NEAR) / DASH_GAP) * DASH_GAP
	while at - distance + NEAR < FAR:
		var z_near := at - distance + NEAR
		at += DASH_GAP
		if z_near + DASH_LENGTH <= nearest:
			continue
		z_near = maxf(z_near, nearest)
		var z_far := minf(z_near + DASH_LENGTH, FAR)
		var a := _street_point(ground, z_near, 0.0)
		var b := _street_point(ground, z_far, 0.0)
		var width := 10.0 * NEAR / z_near
		draw_colored_polygon(PackedVector2Array([a + Vector2(-width, 0), a + Vector2(width, 0),
				b + Vector2(width * z_near / z_far, 0), b - Vector2(width * z_near / z_far, 0)]), dash_color)
	var trees: Array[float] = []
	var tree := ceilf(distance / TREE_GAP) * TREE_GAP
	while tree - distance + NEAR < FAR:
		trees.append(tree - distance + NEAR)
		tree += TREE_GAP
	trees.reverse()
	for z in trees:
		var share := NEAR / z
		for side in [-1.0, 1.0]:
			_draw_tree(_street_point(ground, z, side * TREE_SIDE), share)


## A round tree: a brown trunk and a green crown with a lighter top, both outlined in navy.
func _draw_tree(foot: Vector2, share: float) -> void:
	var trunk := TREE_TRUNK * share
	var line := maxf(1.0, Ui.BORDER_MEDIUM * share * 1.5)
	var trunk_rect := Rect2(foot.x - trunk.x * 0.5, foot.y - trunk.y, trunk.x, trunk.y)
	var trunk_points := Ui.rounded_rect_points(trunk_rect, trunk.x * 0.3, 3)
	draw_colored_polygon(trunk_points, _night(TRUNK_COLOR, NIGHT_DARKEN))
	Ui.draw_outline(self, trunk_points, OUTLINE_COLOR, line)
	var radius := TREE_CROWN * share
	var centre := foot - Vector2(0, trunk.y + radius * 0.6)
	draw_circle(centre, radius + line, OUTLINE_COLOR, true, -1.0, true)
	draw_circle(centre, radius, _night(CROWN_COLOR, NIGHT_DARKEN), true, -1.0, true)
	draw_circle(centre + Vector2(-radius * 0.25, -radius * 0.3), radius * 0.55, _night(CROWN_LIGHT, NIGHT_DARKEN), true, -1.0, true)


# --- The room --------------------------------------------------------------------------------

## A blue wall down to the ground line, a darker band, a violet floor to the bottom of the screen,
## one window on each side of the avatar, and the avatar's shadow.
func _draw_room(ground: float) -> void:
	var area := cover()
	var wall := PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), Vector2(area.end.x, ground),
			Vector2(area.position.x, ground)])
	Ui.fill_vertical_gradient(self, wall, area.position.y, ground, _night(WALL_TOP, ROOM_NIGHT), _night(WALL_BOTTOM, ROOM_NIGHT))
	var floor_points := PackedVector2Array([Vector2(area.position.x, ground), Vector2(area.end.x, ground), area.end,
			Vector2(area.position.x, area.end.y)])
	Ui.fill_vertical_gradient(self, floor_points, ground, area.end.y, _night(FLOOR_TOP, ROOM_NIGHT), _night(FLOOR_BOTTOM, ROOM_NIGHT))
	var y := ground + PLANK_GAP * 0.5
	while y < area.end.y:
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), PLANK_COLOR, 2.0)
		y += PLANK_GAP
	draw_rect(Rect2(area.position.x, ground - SKIRTING, area.size.x, SKIRTING), _night(SKIRTING_COLOR, ROOM_NIGHT))
	draw_line(Vector2(area.position.x, ground - SKIRTING), Vector2(area.end.x, ground - SKIRTING), Color(1, 1, 1, 0.25), 2.0)
	for left in [WINDOW_SIDE, size.x - WINDOW_SIDE - WINDOW_WIDTH]:
		_draw_window(Rect2(left, ground - WINDOW_TOP, WINDOW_WIDTH, WINDOW_HEIGHT))
	var shadow := Ui.ellipse_points(Vector2(size.x * 0.5, ground + 2.0), Vector2(96, 13), 32)
	draw_colored_polygon(shadow, Ui.SHADOW_COLOR)


## A rounded white frame with a navy outline, and the sky of the hour behind the glass.
func _draw_window(window: Rect2) -> void:
	var outer := window.grow(FRAME)
	var frame_points := Ui.rounded_rect_points(outer, 16.0, 5)
	draw_colored_polygon(frame_points, FRAME_COLOR)
	Ui.draw_outline(self, frame_points, OUTLINE_COLOR, Ui.BORDER_MEDIUM)
	var glass := Ui.rounded_rect_points(window, 8.0, 4)
	Ui.fill_vertical_gradient(self, glass, window.position.y, window.end.y,
			Palette.color(minute, Palette.SKY_TOP), Palette.color(minute, Palette.SKY_HORIZON))
	var shine := Palette.stars(minute)
	for star in STARS:
		draw_circle(window.position + star * window.size, 2.2, Color(Ui.STAR_COLOR, shine), true, -1.0, true)
	var middle := window.get_center()
	draw_line(Vector2(middle.x, window.position.y), Vector2(middle.x, window.end.y), FRAME_COLOR, FRAME * 0.7)
	draw_line(Vector2(window.position.x, middle.y), Vector2(window.end.x, middle.y), FRAME_COLOR, FRAME * 0.7)
	Ui.draw_outline(self, glass, Color(OUTLINE_COLOR, 0.6), Ui.BORDER_THIN)


# --- The bedroom -----------------------------------------------------------------------------

## The floor from above over the whole screen, and the bed, its pillow under the avatar's head.
func _draw_bedroom(ground: float) -> void:
	var area := cover()
	var floor_points := PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end,
			Vector2(area.position.x, area.end.y)])
	Ui.fill_vertical_gradient(self, floor_points, area.position.y, area.end.y, BEDROOM_FLOOR_TOP, BEDROOM_FLOOR_BOTTOM)
	var x := area.position.x + fposmod(-area.position.x, PLANK_GAP * 2.0)
	while x < area.end.x:
		draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), PLANK_COLOR, 2.0)
		x += PLANK_GAP * 2.0
	if avatar == null:
		return
	var bed := _bed(ground)
	_draw_box(bed, BED_FRAME_COLOR, BED_RADIUS)
	_draw_box(bed.grow(-BED_FRAME), MATTRESS_COLOR, BED_RADIUS - BED_FRAME * 0.5)
	var bottom: float = avatar.position.y + avatar.mouth_point().y + avatar.size.y * PILLOW_BELOW_MOUTH
	var top := maxf(bottom - PILLOW_HEIGHT, bed.position.y + BED_FRAME * 2.0)
	var pillow := Rect2(bed.get_center().x - PILLOW_WIDTH * 0.5, top, PILLOW_WIDTH, bottom - top)
	var points := Ui.rounded_rect_points(pillow, 30.0, 6)
	Ui.fill_vertical_gradient(self, points, pillow.position.y, pillow.end.y, PILLOW_COLOR, PILLOW_SHADE)
	Ui.draw_outline(self, points, OUTLINE_COLOR, Ui.BORDER_MEDIUM)


## Over the avatar, from its chest over the foot of the bed (so the feet are covered), with the
## top folded back and soft stripes.
func _draw_blanket(ground: float) -> void:
	var bed := _bed(ground)
	var top: float = avatar.position.y + avatar.mouth_point().y + avatar.size.y * CHEST_BELOW_MOUTH
	var blanket := Rect2(bed.position.x + BED_FRAME, top, bed.size.x - BED_FRAME * 2.0, bed.end.y - BED_FRAME - top)
	var points := Ui.rounded_rect_points(blanket, 14.0, 4)
	Ui.fill_vertical_gradient(self, points, blanket.position.y, blanket.end.y, BLANKET_COLOR.lightened(0.08), BLANKET_COLOR.darkened(0.06))
	var y := blanket.position.y + FOLD + 30.0
	while y < blanket.end.y - 12.0:
		draw_line(Vector2(blanket.position.x + 8.0, y), Vector2(blanket.end.x - 8.0, y), BLANKET_STRIPE, 6.0)
		y += 40.0
	Ui.draw_outline(self, points, OUTLINE_COLOR, Ui.BORDER_MEDIUM)
	_draw_box(Rect2(blanket.position, Vector2(blanket.size.x, FOLD)), BLANKET_FOLD_COLOR, 12.0)


## The bed: around the avatar's picture, from above its head to the ground line.
func _bed(ground: float) -> Rect2:
	var left := avatar.position.x - BED_SIDE
	var top := avatar.position.y - BED_ABOVE
	return Rect2(left, top, avatar.size.x + BED_SIDE * 2.0, ground - top)


func _draw_box(box: Rect2, color: Color, radius: float) -> void:
	var points := Ui.rounded_rect_points(box, radius, 5)
	draw_colored_polygon(points, color)
	Ui.draw_outline(self, points, OUTLINE_COLOR, Ui.BORDER_MEDIUM)
