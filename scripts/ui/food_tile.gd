extends Button
## A food of the canteen (Milestone 21): a placeholder picture (a coloured tile with the food's
## first letter, until the team's pictures) and its name under it. A flat button: the canteen
## reacts to its press.

const Canteen := preload("res://scripts/health/canteen.gd")
const TILE := 76.0
const LETTER_FONT := 36
const NAME_FONT := 16
const OUTLINE := Color(0.1, 0.1, 0.12)

var food_id := "":
	set(value):
		food_id = value
		queue_redraw()


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(118, 128)
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _draw() -> void:
	if food_id.is_empty():
		var empty := Rect2((size.x - TILE) * 0.5, 4.0, TILE, TILE)
		draw_rect(empty, Color(1, 1, 1, 0.35), false, 3.0)
		return
	var food := Canteen.food(food_id)
	var name := tr(str(food.get("name", food_id)))
	var tile := Rect2((size.x - TILE) * 0.5, 4.0, TILE, TILE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color.html(str(food.get("color", "#888888")))
	style.set_corner_radius_all(18)
	style.set_border_width_all(3)
	style.border_color = OUTLINE
	draw_style_box(style, tile)
	var font := get_theme_default_font()
	var letter := name.left(1).to_upper()
	var letter_y := tile.position.y + (tile.size.y + font.get_ascent(LETTER_FONT) - font.get_descent(LETTER_FONT)) * 0.5
	draw_string_outline(font, Vector2(tile.position.x, letter_y), letter, HORIZONTAL_ALIGNMENT_CENTER, tile.size.x, LETTER_FONT, 6, OUTLINE)
	draw_string(font, Vector2(tile.position.x, letter_y), letter, HORIZONTAL_ALIGNMENT_CENTER, tile.size.x, LETTER_FONT, Color.WHITE)
	draw_multiline_string(font, Vector2(0.0, tile.end.y + 4.0 + font.get_ascent(NAME_FONT)), name, HORIZONTAL_ALIGNMENT_CENTER,
			size.x, NAME_FONT, 2, Color.WHITE)
