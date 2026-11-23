extends Control
## The meal minigame (Milestone 15): a fork with food swings over the avatar's mouth. A ring at
## the mouth shows where a tap is a bite, and turns bright when the fork is inside it. Short messages ("Yum!") show above it.
## Team's task list, sheet 2 (22 Nov 2026): the food on the fork is the picture of one of the foods
## the player put on the plate (food_texture, set by main.gd, the plate's foods in turn, one per
## bite); without a plate or a picture it is a round bite of food_color.

## Colours of Milestone 25 (scripts/ui/ui_style.gd).
const FORK_COLOR := Color("#eef1ff")
const RING_COLOR := Color(1.0, 1.0, 1.0, 0.4)
## The ring at the mouth when the fork is inside it: the green of the timing zones (Milestone 40).
const GOOD_COLOR := Color("#6bf0b0")
const OUTLINE_COLOR := Color("#1b2552")
const SWING := 230.0
const HEIGHT_ABOVE_MOUTH := 34.0
const HANDLE := 110.0
const TINE := 22.0
const FOOD_RADIUS := 16.0
## The food's picture on the fork: this wide (its height follows the picture), its middle this far
## under the tines' tips.
const FOOD_PICTURE_WIDTH := 84.0
const FOOD_PICTURE_DROP := 14.0
## Half the height of the ring around the mouth (Milestone 26: a ring, not a box over the face).
const RING_HALF_HEIGHT := 26.0
const RING_POINTS := 40
const EVENT_FONT := 40
const EVENT_SECONDS := 1.2

## Where the fork is, -1 to 1, and whether it is at the mouth.
var fork := 0.0
var at_mouth := false
## How close to the mouth a tap is a bite, as a share of the swing.
var hit_share := 0.0
## The avatar's mouth, in this control's coordinates.
var mouth := Vector2.ZERO
var food_color := Color(0.4, 0.75, 0.35)
## The plate's food on the fork now (loaded by main.gd, never while drawing), or null.
var food_texture: Texture2D

var _event_text := ""
var _event_left := 0.0


func show_event(text: String) -> void:
	_event_text = text
	_event_left = EVENT_SECONDS


func _process(delta: float) -> void:
	if visible:
		_event_left -= delta
		queue_redraw()


func _draw() -> void:
	var half := hit_share * SWING
	# A ring around the mouth as wide as the bite zone; it fills softly when the fork is inside.
	var ring := PackedVector2Array()
	for i in RING_POINTS + 1:
		var angle := TAU * i / RING_POINTS
		ring.append(mouth + Vector2(cos(angle) * half, sin(angle) * RING_HALF_HEIGHT))
	if at_mouth:
		draw_colored_polygon(ring.slice(0, RING_POINTS), Color(GOOD_COLOR, 0.3))
	draw_polyline(ring, OUTLINE_COLOR, 7.0, true)
	draw_polyline(ring, GOOD_COLOR if at_mouth else Color.WHITE, 4.0, true)
	var tip := mouth + Vector2(fork * SWING, -HEIGHT_ABOVE_MOUTH)
	draw_line(tip, tip + Vector2(0.0, -HANDLE), FORK_COLOR, 8.0)
	for side in [-1.0, 0.0, 1.0]:
		draw_line(tip + Vector2(side * 9.0, 0.0), tip + Vector2(side * 9.0, TINE), FORK_COLOR, 4.0)
	if food_texture:
		var picture_size := Vector2(FOOD_PICTURE_WIDTH, FOOD_PICTURE_WIDTH * food_texture.get_height() / food_texture.get_width())
		var centre := tip + Vector2(0.0, TINE + FOOD_PICTURE_DROP)
		draw_texture_rect(food_texture, Rect2(centre - picture_size * 0.5, picture_size), false)
	else:
		draw_circle(tip + Vector2(0.0, TINE + FOOD_RADIUS * 0.6), FOOD_RADIUS, food_color)
	if _event_left > 0.0:
		var font := get_theme_default_font()
		var at := Vector2(0.0, mouth.y - HANDLE - HEIGHT_ABOVE_MOUTH - 30.0)
		draw_string_outline(font, at, _event_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, EVENT_FONT, 8, OUTLINE_COLOR)
		draw_string(font, at, _event_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, EVENT_FONT, Color.WHITE)
