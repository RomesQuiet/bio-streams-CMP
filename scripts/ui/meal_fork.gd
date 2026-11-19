extends Control
## The meal minigame (Milestone 15): a fork with food swings over the avatar's mouth. A ring at
## the mouth shows where a tap is a bite, and turns bright when the fork is inside it. Short messages ("Yum!") show above it.

## Colours of Milestone 25 (scripts/ui/ui_style.gd).
const FORK_COLOR := Color("#eef1ff")
const RING_COLOR := Color(1.0, 1.0, 1.0, 0.4)
const GOOD_COLOR := Color("#84f2da")
const OUTLINE_COLOR := Color("#1b2552")
const SWING := 230.0
const HEIGHT_ABOVE_MOUTH := 34.0
const HANDLE := 110.0
const TINE := 22.0
const FOOD_RADIUS := 16.0
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
	draw_circle(tip + Vector2(0.0, TINE + FOOD_RADIUS * 0.6), FOOD_RADIUS, food_color)
	if _event_left > 0.0:
		var font := get_theme_default_font()
		var at := Vector2(0.0, mouth.y - HANDLE - HEIGHT_ABOVE_MOUTH - 30.0)
		draw_string_outline(font, at, _event_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, EVENT_FONT, 8, OUTLINE_COLOR)
		draw_string(font, at, _event_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, EVENT_FONT, Color.WHITE)
