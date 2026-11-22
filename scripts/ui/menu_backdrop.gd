extends Control
## The main menu's background: the team's pictures (their updated zip, 22 Nov 2026; Milestone 40
## drew the team's splash screen by code until then): a flat night sky with the sun, the moon,
## clouds and stars, and four figures on a round blue hill (a boy running, a girl with obesity, a
## girl eating an apple and a boy asleep in bed). It covers the whole screen, also outside the
## game's column (decision 87):
## - a screen as wide as the column (a phone): the vertical picture, as wide as the column, from its
##   top; below it, on a taller screen, the hill's flat colour;
## - a wider screen: the wide picture, its figures as large as the vertical picture's and centred
##   on the column, at least as wide as the screen; above and below it the sky's and the hill's
##   flat colours.
## Pictures are loaded once in _ready, never while drawing. Only the look: it does not follow the
## game's clock.

const Ui := preload("res://scripts/ui/ui_style.gd")

const PORTRAIT := "res://assets/art/menu/menu_portrait.png"
const WIDE := "res://assets/art/menu/menu_wide.png"
## The flat colours at the pictures' edges (read from their pixels).
const PORTRAIT_GROUND := Color8(60, 94, 199)
const WIDE_SKY := Color8(94, 101, 202)
const WIDE_GROUND := Color8(64, 102, 217)
## The wide picture's figures are this many times smaller than the vertical one's (measured on
## the girl with obesity, 183 and 338 px tall), and the top of her hair is at y 260 in it and at
## y 482 in the vertical picture.
const WIDE_FIGURE_SHARE := 1.847
const WIDE_FIGURE_TOP := 260.0
const PORTRAIT_FIGURE_TOP := 482.0

## The column's rectangle on the screen (set by the menu every frame).
var column_rect := Rect2(0, 0, 720, 1280):
	set(value):
		if value != column_rect:
			column_rect = value
			queue_redraw()
var _portrait: Texture2D
var _wide: Texture2D


func _ready() -> void:
	top_level = true
	z_index = Ui.Z_SKY
	set_anchors_preset(PRESET_TOP_LEFT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_portrait = load(PORTRAIT)
	_wide = load(WIDE)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()


## Whether the screen is wider than the column (then the wide picture is drawn).
func is_wide() -> bool:
	return size.x > column_rect.size.x + 1.0


## Where the picture is drawn, on the screen.
func picture_rect() -> Rect2:
	var portrait_scale := column_rect.size.x / _portrait.get_width()
	if not is_wide():
		return Rect2(column_rect.position, Vector2(_portrait.get_size()) * portrait_scale)
	var scale_wide := maxf(portrait_scale * WIDE_FIGURE_SHARE, size.x / _wide.get_width())
	var picture := Vector2(_wide.get_size()) * scale_wide
	var centre_x := column_rect.position.x + column_rect.size.x * 0.5
	var top := column_rect.position.y + PORTRAIT_FIGURE_TOP * portrait_scale - WIDE_FIGURE_TOP * scale_wide
	return Rect2(centre_x - picture.x * 0.5, top, picture.x, picture.y)


func _draw() -> void:
	var rect := picture_rect()
	if is_wide():
		draw_rect(Rect2(Vector2.ZERO, size), WIDE_SKY)
		if rect.end.y < size.y:
			draw_rect(Rect2(0.0, rect.end.y, size.x, size.y - rect.end.y), WIDE_GROUND)
		draw_texture_rect(_wide, rect, false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), PORTRAIT_GROUND)
		draw_texture_rect(_portrait, rect, false)
