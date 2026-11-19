extends PanelContainer
## Milestone 25: the avatar's speech balloon (documentation/ui_specification_v1.md, section 9): white,
## a dark navy outline, very round corners and no shadow (theme type SpeechBalloon), and a tail under
## it that points down to the avatar. The tail is drawn over the panel, so it covers the outline
## where they join. A new text comes in softly.

const Ui := preload("res://scripts/ui/ui_style.gd")

## The tail: where it starts (share of the width), its width and its length.
const TAIL_AT := 0.6
const TAIL_WIDTH := 34.0
const TAIL_LENGTH := 28.0
## The tip leans this far left, toward the middle of the avatar.
const TAIL_LEAN := 12.0
const ENTER_SECONDS := 0.22


func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = Vector2(size.x * TAIL_AT, size.y))


## A soft entrance for a new message (not on every refresh of the same text).
func pop() -> void:
	if not is_inside_tree():
		return
	modulate.a = 0.4
	scale = Vector2.ONE * 0.96
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, ENTER_SECONDS)
	tween.tween_property(self, "scale", Vector2.ONE, ENTER_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var line := Ui.BORDER_MEDIUM
	var base_x := size.x * TAIL_AT
	var left := Vector2(base_x - TAIL_WIDTH * 0.5, size.y - line)
	var right := Vector2(base_x + TAIL_WIDTH * 0.5, size.y - line)
	var tip := Vector2(base_x - TAIL_LEAN, size.y + TAIL_LENGTH)
	# White over the outline where the tail joins, then the two outer sides in navy.
	draw_colored_polygon(PackedVector2Array([left + Vector2(0, -line), right + Vector2(0, -line), tip]), Color.WHITE)
	draw_polyline(PackedVector2Array([left + Vector2(0, line * 0.5), tip, right + Vector2(0, line * 0.5)]), Ui.INK, line, true)
