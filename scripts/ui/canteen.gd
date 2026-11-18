extends ColorRect
## The canteen (Milestone 21, decisions 61 to 64). Two steps: first good food or bad food, then
## one dish from many examples of that kind, so players learn to tell them apart. A tap on a
## dish eats it (Activities.start_dish()): a good dish is the healthy meal and a bad dish the
## fast-food meal, so the health model is unchanged. Every text is a translation key.

signal closed

const Canteen := preload("res://scripts/health/canteen.gd")
const Hunger := preload("res://scripts/health/hunger.gd")
const DishTile := preload("res://scripts/ui/food_tile.gd")
const COLUMNS := 5
const GOOD_COLOR := Color(0.55, 0.9, 0.55)
const BAD_COLOR := Color(1.0, 0.65, 0.45)

## The kind being shown: "" (step 1), "good" or "bad" (step 2).
var kind := ""
var kind_box: VBoxContainer
var dish_box: VBoxContainer
var dish_title: Label
var good_grid: GridContainer
var bad_grid: GridContainer
var good_button: Button
var bad_button: Button
var skip_button: Button


func _ready() -> void:
	color = Color(0, 0, 0, 0.6)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(680, 0)
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	_label("CANTEEN_TITLE", 32, content).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Step 1: the kind of food.
	kind_box = VBoxContainer.new()
	kind_box.add_theme_constant_override("separation", 14)
	content.add_child(kind_box)
	_label("CANTEEN_CHOOSE", 24, kind_box).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	good_button = _button("CANTEEN_GOOD", kind_box, 110)
	good_button.add_theme_color_override("font_color", GOOD_COLOR.darkened(0.45))
	good_button.pressed.connect(show_kind.bind("good"))
	bad_button = _button("CANTEEN_BAD", kind_box, 110)
	bad_button.add_theme_color_override("font_color", BAD_COLOR.darkened(0.45))
	bad_button.pressed.connect(show_kind.bind("bad"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	kind_box.add_child(row)
	skip_button = _button("UI_SKIP_MEAL", row, 64)
	skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_button.pressed.connect(_on_skip)
	var cancel := _button("UI_CANCEL", row, 64)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(close)
	# Step 2: one dish of that kind.
	dish_box = VBoxContainer.new()
	dish_box.add_theme_constant_override("separation", 10)
	content.add_child(dish_box)
	dish_title = _label("", 26, dish_box)
	_label("CANTEEN_CHOOSE_DISH", 20, dish_box)
	good_grid = _grid(dish_box)
	bad_grid = _grid(dish_box)
	for good in [true, false]:
		for id in Canteen.dishes(good):
			var tile: Button = DishTile.new()
			tile.dish_id = id
			tile.pressed.connect(eat.bind(id))
			(good_grid if good else bad_grid).add_child(tile)
	_button("CANTEEN_BACK", dish_box, 64).pressed.connect(show_kind.bind(""))
	visible = false


## Opens on step 1. Skip meal only when the avatar is hungry.
func open() -> void:
	show_kind("")
	show()


## Step 1 (kind ""), or the dishes of "good" or "bad" food.
func show_kind(new_kind: String) -> void:
	kind = new_kind
	kind_box.visible = kind.is_empty()
	dish_box.visible = not kind.is_empty()
	good_grid.visible = kind == "good"
	bad_grid.visible = kind == "bad"
	dish_title.text = "CANTEEN_GOOD" if kind == "good" else "CANTEEN_BAD"
	dish_title.add_theme_color_override("font_color", GOOD_COLOR if kind == "good" else BAD_COLOR)
	skip_button.visible = Hunger.is_hungry()


func close() -> void:
	hide()
	closed.emit()


## The player chose this dish: the meal starts.
func eat(dish_id: String) -> void:
	close()
	Activities.start_dish(dish_id)


func _on_skip() -> void:
	close()
	Hunger.skip()


func _grid(parent: Control) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	parent.add_child(grid)
	return grid


func _label(text: String, font_size: int, parent: Control) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _button(text: String, parent: Control, height: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	parent.add_child(button)
	return button
