extends Control
## The place behind the avatar during an activity ("scenery" in data/activities.json; user,
## 7 Nov 2026): "outside" is only the sky and the ground, "room" a wall with windows that show
## the sky (day or night), "bedroom" a grey floor and a bed seen from above: the avatar faces the
## player, so from above it lies on its back, its head on the pillow, and a blanket covers it
## from the chest down. The blanket is drawn by a second Scenery node in front of the avatar
## (front = true). The grey ground is the Ground node. Placeholder art, drawn with shapes.

const OUTSIDE := "outside"
const ROOM := "room"
const BEDROOM := "bedroom"

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
const PILLOW_SIZE := Vector2(250.0, 120.0)
## Where the blanket starts: below the mouth, by this share of the avatar's height.
const CHEST_BELOW_MOUTH := 0.13
const FOLD := 34.0
## The floor also covers the screen's margins and the top bar around this control.
const FLOOR_BEYOND := 400.0
## The stars in the windows at night, as shares of a window.
const STARS := [Vector2(0.2, 0.15), Vector2(0.7, 0.3), Vector2(0.35, 0.6), Vector2(0.8, 0.75), Vector2(0.15, 0.85)]

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
	var pillow := Rect2(Vector2(bed.get_center().x - PILLOW_SIZE.x * 0.5, bed.position.y + BED_FRAME * 2.0), PILLOW_SIZE)
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
