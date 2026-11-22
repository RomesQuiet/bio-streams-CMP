extends Button
## Milestone 40 (documentation/ui_v2/changes.md, change 2): a big button of the activity dock
## (DOWN, UP, Bite, Done): a rounded face with a darker thickness of `depth` pixels under it, and
## inside it what the tables give: an icon, an arrow, a divider, the word, a key hint or a key chip,
## each at its place. Every place is in the button's own pixels, measured from the face's top-left.
## Pressing moves the face down by its thickness at once; it comes back in BUTTON_RETURN_SECONDS.
## Disabled: alpha 0.45. The Button's own text is the word's key (drawn here).

const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")

var face := Ui.MINIGAME_UP_COLOR
var base := Ui.MINIGAME_UP_BASE
## The colour of the icon, arrow, divider and word.
var ink := Ui.INK
var depth := 8.0
var radius := 32.0
## An icon of scripts/ui/ui_icons.gd in this rect ("" for none). A tall rect (the fork) is drawn
## in a box as high as the rect.
var icon_kind := ""
var icon_rect := Rect2()
## "down", "up" or "" for none, in arrow_rect.
var arrow := ""
var arrow_rect := Rect2()
## A thin line (Rect2() for none), drawn in ink at 25%.
var divider := Rect2()
var word_size := 40
## The word: its left edge (or, when word_centred, its centre) and the y it is centred on.
var word_x := 0.0
var word_y := 0.0
var word_centred := false
## The word in capitals (the cardio Tap button).
var upper := false
## A symbol drawn before the word: "cross" on Cancel, "play" on Start (change 9), "back" (an arrow
## to the left), or "" for none. Drawn, not written: the Nunito font has no arrows, ▶ or ✕, and
## the web build has no other font, so those characters showed as boxes with their code.
var prefix := ""
## A key under the word on a computer ("" for none), centred at hint_centre.
var hint := ""
var hint_size := 24
var hint_centre := Vector2()
## A key chip on a computer ("" for none): a pill at chip_rect, outlined in white or filled, with
## the key's letter and, before it, chip_arrow ("down", "up" or "" for none), drawn.
var chip := ""
var chip_arrow := ""
var chip_rect := Rect2()
var chip_fill := Color(0, 0, 0, 0)

## A symbol before the word or in the chip is this share of the text's size wide, with this
## share of it as the gap after it.
const SYMBOL_SHARE := 0.62
const SYMBOL_GAP_SHARE := 0.38
const CHIP_FONT_SIZE := 20

var press := 0.0:
	set(value):
		press = value
		queue_redraw()
var _tween: Tween


func _ready() -> void:
	theme_type_variation = &"ActionButton"
	button_down.connect(_on_down)
	button_up.connect(_on_up)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _on_down() -> void:
	if _tween:
		_tween.kill()
	press = 1.0


func _on_up() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "press", 0.0, Ui.BUTTON_RETURN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	self_modulate.a = Ui.DISABLED_ALPHA if disabled else 1.0
	var height := size.y - depth
	Ui.draw_gradient_box(self, Rect2(0.0, depth, size.x, height), radius, base, base)
	var offset := Vector2(0.0, depth * press)
	var color := face.lightened(0.04) if is_hovered() and not disabled else face
	Ui.draw_gradient_box(self, Rect2(offset, Vector2(size.x, height)), radius, color.lightened(0.06), color)
	if not icon_kind.is_empty():
		Icons.draw(self, icon_kind, offset + icon_rect.get_center(), maxf(icon_rect.size.x, icon_rect.size.y), ink)
	if not arrow.is_empty():
		_draw_arrow(Rect2(arrow_rect.position + offset, arrow_rect.size), arrow == "down")
	if divider.has_area():
		draw_rect(Rect2(divider.position + offset, divider.size), Color(ink, 0.25))
	var word := atr(text).to_upper() if upper else atr(text)
	var room := size.x - (word_x if not word_centred else 0.0) - 20.0
	var fitted := Ui.fit_font_size(Ui.FONT_HEAVY, word, word_size, room - (_symbol_room(word_size) if not prefix.is_empty() else 0.0))
	fitted = maxi(fitted, int(word_size * 0.7))
	var symbol := 0.0 if prefix.is_empty() else _symbol_room(fitted)
	var x := word_x
	if word_centred:
		x -= (symbol + Ui.FONT_HEAVY.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x) * 0.5
	if not prefix.is_empty():
		var side := fitted * SYMBOL_SHARE
		_draw_symbol(prefix, Rect2(offset + Vector2(x, word_y - side * 0.5), Vector2(side, side)), ink)
	var baseline := word_y + (Ui.FONT_HEAVY.get_ascent(fitted) - Ui.FONT_HEAVY.get_descent(fitted)) * 0.5
	draw_string(Ui.FONT_HEAVY, offset + Vector2(x + symbol, baseline), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, ink)
	if not hint.is_empty():
		Ui.draw_centred_text(self, Ui.FONT_BOLD, offset + hint_centre, hint, hint_size, ink)
	if not chip.is_empty():
		var pill := Rect2(chip_rect.position + offset, chip_rect.size)
		var points := Ui.rounded_rect_points(pill, chip_rect.size.y * 0.5 - 0.5)
		if chip_fill.a > 0.0:
			draw_colored_polygon(points, chip_fill)
		else:
			Ui.draw_outline(self, points, Color(1, 1, 1, 0.6), Ui.BORDER_THIN)
		var arrow_room := 0.0 if chip_arrow.is_empty() else _symbol_room(CHIP_FONT_SIZE)
		var letter := Ui.FONT_BOLD.get_string_size(chip, HORIZONTAL_ALIGNMENT_LEFT, -1, CHIP_FONT_SIZE).x
		var left := pill.get_center().x - (arrow_room + letter) * 0.5
		if not chip_arrow.is_empty():
			var side := CHIP_FONT_SIZE * SYMBOL_SHARE
			_draw_symbol(chip_arrow, Rect2(Vector2(left, pill.get_center().y - side * 0.5), Vector2(side, side)), Color.WHITE)
		Ui.draw_centred_text(self, Ui.FONT_BOLD, Vector2(left + arrow_room + letter * 0.5, pill.get_center().y), chip,
				CHIP_FONT_SIZE, Color.WHITE)


## The width of a symbol and the gap after it, for text of this size.
func _symbol_room(font_size: float) -> float:
	return font_size * (SYMBOL_SHARE + SYMBOL_GAP_SHARE)


## A symbol drawn in rect: "play" (a triangle), "cross", "back" (an arrow to the left), "down" or
## "up" (an arrow).
func _draw_symbol(kind: String, rect: Rect2, color: Color) -> void:
	var width := maxf(2.0, rect.size.x * 0.16)
	var c := rect.get_center()
	var h := rect.size.x * 0.5
	match kind:
		"play":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.75, -h), c + Vector2(h, 0.0), c + Vector2(-h * 0.75, h)]), color)
		"cross":
			Ui.draw_round_line(self, c + Vector2(-h, -h) * 0.8, c + Vector2(h, h) * 0.8, color, width)
			Ui.draw_round_line(self, c + Vector2(-h, h) * 0.8, c + Vector2(h, -h) * 0.8, color, width)
		"back", "down", "up":
			var direction: Vector2 = {"back": Vector2.LEFT, "down": Vector2.DOWN, "up": Vector2.UP}[kind]
			var tip := c + direction * h * 0.9
			var side := Vector2(-direction.y, direction.x)
			Ui.draw_round_line(self, c - direction * h * 0.9, tip, color, width)
			Ui.draw_round_line(self, tip, tip - direction * h * 0.55 + side * h * 0.55, color, width)
			Ui.draw_round_line(self, tip, tip - direction * h * 0.55 - side * h * 0.55, color, width)


## An arrow down or up in rect (a stem and a head), in ink.
func _draw_arrow(rect: Rect2, down: bool) -> void:
	var width := rect.size.x * 0.4
	var head := rect.size.x * 0.5
	var tip := Vector2(rect.get_center().x, rect.end.y - 3.0 if down else rect.position.y + 3.0)
	var tail := Vector2(tip.x, rect.position.y + 3.0 if down else rect.end.y - 3.0)
	var back := -1.0 if down else 1.0
	Ui.draw_round_line(self, tail, tip, ink, width)
	Ui.draw_round_line(self, tip, tip + Vector2(-head, back * head), ink, width)
	Ui.draw_round_line(self, tip, tip + Vector2(head, back * head), ink, width)
