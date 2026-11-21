extends Button
## Milestone 40 (documentation/ui_v2/changes.md, change 10, "Let's eat"): a card of the first step
## of the canteen: a light rounded face (560 x 156, radius 28, a thickness of 8), the team's
## picture without words on the left, a thin divider, the title and a subtitle (two lines at most).
## A tap only chooses it; the chosen one is mint with a green thickness and a green badge with a
## white check. The Button's own text is the title's key; subtitle_key is the subtitle's.

const Ui := preload("res://scripts/ui/ui_style.gd")

const DEPTH := 8.0
const RADIUS := 28.0
## Places from the card's top-left (the table's numbers minus the card's x 80 and y).
const PICTURE := Rect2(16, 13, 260, 130)
const DIVIDER := Rect2(292, 30, 2, 96)
const TEXT_X := 312.0
const TEXT_WIDTH := 232.0
const TITLE_Y := 60.0
const TITLE_SIZE := 34
const SUBTITLE_Y := 104.0
const SUBTITLE_SIZE := 20
const SUBTITLE_LINE := 22.0
const BADGE := Vector2(532, 28)
const BADGE_RADIUS := 22.0

var subtitle_key := ""
## The picture, loaded when it is set (never while drawing).
var picture: Texture2D
var chosen := false:
	set(value):
		if value != chosen:
			chosen = value
			queue_redraw()


func _ready() -> void:
	theme_type_variation = &"ActionButton"
	focus_mode = Control.FOCUS_NONE


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _draw() -> void:
	var height := size.y - DEPTH
	var face := Ui.EXERCISE_COLOR if chosen else Ui.TILE_COLOR
	var base := Ui.MINIGAME_UP_BASE if chosen else Ui.TILE_BASE
	if is_hovered() and not chosen:
		face = face.lightened(0.3)
	draw_colored_polygon(Ui.rounded_rect_points(Rect2(0, DEPTH, size.x, height), RADIUS), base)
	Ui.draw_gradient_box(self, Rect2(0, 0, size.x, height), RADIUS, face.lightened(0.05), face)
	if picture:
		draw_texture_rect(picture, PICTURE, false)
	draw_rect(DIVIDER, Color(Ui.INK, 0.25))
	var title := atr(text)
	# The title ends before the badge (8 px gap), chosen or not, so it never runs under the check.
	var title_room := BADGE.x - BADGE_RADIUS - 8.0 - TEXT_X
	var fitted := maxi(Ui.fit_font_size(Ui.FONT_HEAVY, title, TITLE_SIZE, title_room), int(TITLE_SIZE * 0.7))
	var baseline := TITLE_Y + (Ui.FONT_HEAVY.get_ascent(fitted) - Ui.FONT_HEAVY.get_descent(fitted)) * 0.5
	draw_string(Ui.FONT_HEAVY, Vector2(TEXT_X, baseline), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, Ui.INK)
	_draw_subtitle(tr(subtitle_key))
	if chosen:
		draw_circle(BADGE, BADGE_RADIUS, Ui.BADGE_COLOR, true, -1.0, true)
		draw_polyline(PackedVector2Array([BADGE + Vector2(-9, 0), BADGE + Vector2(-2, 7), BADGE + Vector2(9, -7)]), Color.WHITE, 4.0, true)


## The subtitle on one line centred on SUBTITLE_Y, or on two lines of 22 px around it.
func _draw_subtitle(line: String) -> void:
	var font := Ui.FONT_BOLD
	var lines: Array[String] = [line]
	if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, SUBTITLE_SIZE).x > TEXT_WIDTH:
		var words := line.split(" ")
		var first := ""
		var split := words.size()
		for i in words.size():
			var attempt := (first + " " + words[i]).strip_edges()
			if font.get_string_size(attempt, HORIZONTAL_ALIGNMENT_LEFT, -1, SUBTITLE_SIZE).x > TEXT_WIDTH and i > 0:
				split = i
				break
			first = attempt
		lines = [first, " ".join(words.slice(split))]
	var top := SUBTITLE_Y - SUBTITLE_LINE * (lines.size() - 1) * 0.5
	for i in lines.size():
		var fitted := maxi(Ui.fit_font_size(font, lines[i], SUBTITLE_SIZE, TEXT_WIDTH), int(SUBTITLE_SIZE * 0.7))
		var baseline := top + SUBTITLE_LINE * i + (font.get_ascent(fitted) - font.get_descent(fitted)) * 0.5
		draw_string(font, Vector2(TEXT_X, baseline), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, Ui.SUBTITLE_COLOR)
