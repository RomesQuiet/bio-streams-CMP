extends Control
## The place behind the avatar during an activity ("scenery" in data/activities.json; user,
## 7 Nov 2026): "outside" is only the sky and the ground, "room" a wall with windows that show
## the sky (day or night), "bedroom" a grey room with a bed. The grey ground is the Ground node
## in front of it. Placeholder art, drawn with shapes.

const OUTSIDE := "outside"
const ROOM := "room"
const BEDROOM := "bedroom"

const WALL_COLOR := Color(0.86, 0.8, 0.68)
const SKIRTING_COLOR := Color(0.62, 0.55, 0.45)
const FRAME_COLOR := Color(0.97, 0.97, 0.95)
const STAR_COLOR := Color(1.0, 1.0, 0.85)
const BEDROOM_WALL_COLOR := Color(0.6, 0.6, 0.62)
const HEADBOARD_COLOR := Color(0.42, 0.42, 0.45)
const MATTRESS_COLOR := Color(0.92, 0.92, 0.93)
const PILLOW_COLOR := Color(1.0, 1.0, 1.0)
const BLANKET_COLOR := Color(0.72, 0.72, 0.75)
const OUTLINE_COLOR := Color(0.1, 0.1, 0.12)
## Where the ground line is, from the bottom of this control (the Ground node).
const GROUND_FROM_BOTTOM := 60.0
const WINDOW_WIDTH := 130.0
const WINDOW_HEIGHT := 230.0
const WINDOW_TOP := 440.0
const WINDOW_SIDE := 24.0
const FRAME := 10.0
const SKIRTING := 16.0
const BED_WIDTH := 560.0
const HEADBOARD_HEIGHT := 330.0
const MATTRESS_TOP := 190.0
const MATTRESS_BOTTOM := 70.0
const PILLOW_SIZE := Vector2(170.0, 60.0)
## The stars in the windows at night, as shares of a window.
const STARS := [Vector2(0.2, 0.15), Vector2(0.7, 0.3), Vector2(0.35, 0.6), Vector2(0.8, 0.75), Vector2(0.15, 0.85)]

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


## A grey room, and a bed seen from the front behind the avatar.
func _draw_bedroom(ground: float) -> void:
	draw_rect(Rect2(0.0, 0.0, size.x, ground), BEDROOM_WALL_COLOR)
	var left := (size.x - BED_WIDTH) * 0.5
	var headboard := Rect2(left + 20.0, ground - HEADBOARD_HEIGHT, BED_WIDTH - 40.0, HEADBOARD_HEIGHT)
	_draw_box(headboard, HEADBOARD_COLOR)
	var mattress := Rect2(left, ground - MATTRESS_TOP, BED_WIDTH, MATTRESS_TOP - MATTRESS_BOTTOM)
	_draw_box(mattress, MATTRESS_COLOR)
	_draw_box(Rect2(Vector2(left + 40.0, mattress.position.y - PILLOW_SIZE.y * 0.6), PILLOW_SIZE), PILLOW_COLOR)
	_draw_box(Rect2(left + BED_WIDTH * 0.42, mattress.position.y - 10.0, BED_WIDTH * 0.58, mattress.size.y + 10.0), BLANKET_COLOR)
	for x in [left + 16.0, left + BED_WIDTH - 36.0]:
		_draw_box(Rect2(x, ground - MATTRESS_BOTTOM, 20.0, MATTRESS_BOTTOM), HEADBOARD_COLOR)


func _draw_box(box: Rect2, color: Color) -> void:
	draw_rect(box, color)
	draw_rect(box, OUTLINE_COLOR, false, 3.0)
