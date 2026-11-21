extends Control
## The team's task list (21 Nov 2026): when a minigame ends, a short pop-up with one line about how
## it went ("Great running rhythm!", "You did the push-ups badly.", "You ate bad food."): a navy
## card with a white line, over the stage, that fades in, stays a moment and fades out.
## Only the look: nothing in the game changes.

const Ui := preload("res://scripts/ui/ui_style.gd")

## The card's centre in the column, its height and how long it stays (real seconds).
const CENTRE := Vector2(360, 560)
const HEIGHT := 72.0
const SIDE_PADDING := 32.0
const MAX_WIDTH := 640.0
const FONT_SIZE := 26
const STAY_SECONDS := 2.6
const FADE_SECONDS := 0.25

var text := ""
var _tween: Tween


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	modulate.a = 0.0
	visible = false


func show_text(line: String) -> void:
	text = line
	visible = true
	queue_redraw()
	if _tween:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_SECONDS)
	_tween.tween_interval(STAY_SECONDS)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	_tween.tween_callback(hide)


func _draw() -> void:
	if text.is_empty():
		return
	var fitted := maxi(Ui.fit_font_size(Ui.FONT_HEAVY, text, FONT_SIZE, MAX_WIDTH - SIDE_PADDING * 2.0), int(FONT_SIZE * 0.7))
	var width := minf(Ui.FONT_HEAVY.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x + SIDE_PADDING * 2.0, MAX_WIDTH)
	var card := Rect2(CENTRE - Vector2(width, HEIGHT) * 0.5, Vector2(width, HEIGHT))
	var points := Ui.rounded_rect_points(card, HEIGHT * 0.5 - 0.5)
	draw_colored_polygon(points, Ui.PANEL_92)
	Ui.draw_outline(self, Ui.rounded_rect_points(card.grow(-1.0), HEIGHT * 0.5 - 1.5), Color.WHITE, Ui.BORDER_THIN)
	Ui.draw_centred_text(self, Ui.FONT_HEAVY, card.get_center(), text, fitted, Color.WHITE)
