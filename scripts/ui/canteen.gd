extends ColorRect
## The canteen (Milestone 21, third version, decisions 65 and 66). Two steps: first good food or
## fast food, then the player builds a plate of up to canteen.plate_max foods of that kind from
## many examples (a tap puts a food on the plate, a tap on the plate takes it off) and eats it
## (Activities.start_plate()). A good plate is the healthy meal and a fast-food plate the
## fast-food meal, so the health model is unchanged. Every text is a translation key.

signal closed

const Canteen := preload("res://scripts/health/canteen.gd")
const Hunger := preload("res://scripts/health/hunger.gd")
const FoodTile := preload("res://scripts/ui/food_tile.gd")
const COLUMNS := 5
const GOOD_COLOR := Color(0.55, 0.9, 0.55)
const FAST_COLOR := Color(1.0, 0.65, 0.45)

## The kind being shown: "" (step 1), Canteen.GOOD or Canteen.FAST_FOOD (step 2).
var kind := ""
## Food ids on the plate, in the order they were added.
var plate: Array[String] = []
var kind_box: VBoxContainer
var plate_box: VBoxContainer
var kind_title: Label
var good_grid: GridContainer
var fast_grid: GridContainer
var plate_row: HBoxContainer
var plate_label: Label
var good_button: Button
var fast_button: Button
var skip_button: Button
var eat_button: Button


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
	good_button.pressed.connect(show_kind.bind(Canteen.GOOD))
	fast_button = _button("CANTEEN_FAST", kind_box, 110)
	fast_button.add_theme_color_override("font_color", FAST_COLOR.darkened(0.45))
	fast_button.pressed.connect(show_kind.bind(Canteen.FAST_FOOD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	kind_box.add_child(row)
	skip_button = _button("UI_SKIP_MEAL", row, 64)
	skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_button.pressed.connect(_on_skip)
	var cancel := _button("UI_CANCEL", row, 64)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(close)
	# Step 2: build a plate of that kind.
	plate_box = VBoxContainer.new()
	plate_box.add_theme_constant_override("separation", 10)
	content.add_child(plate_box)
	kind_title = _label("", 26, plate_box)
	good_grid = _grid(plate_box)
	fast_grid = _grid(plate_box)
	for food_kind in [Canteen.GOOD, Canteen.FAST_FOOD]:
		for id in Canteen.foods(food_kind):
			var tile: Button = FoodTile.new()
			tile.food_id = id
			tile.pressed.connect(add_food.bind(id))
			(good_grid if food_kind == Canteen.GOOD else fast_grid).add_child(tile)
	plate_label = _label("", 24, plate_box)
	var hint := _label("CANTEEN_PLATE_HINT", 18, plate_box)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plate_row = HBoxContainer.new()
	plate_row.alignment = BoxContainer.ALIGNMENT_CENTER
	plate_box.add_child(plate_row)
	for i in Config.get_int("canteen.plate_max"):
		var slot: Button = FoodTile.new()
		slot.pressed.connect(remove_at.bind(i))
		plate_row.add_child(slot)
	eat_button = _button("CANTEEN_EAT", plate_box, 72)
	eat_button.pressed.connect(_on_eat)
	_button("CANTEEN_BACK", plate_box, 64).pressed.connect(show_kind.bind(""))
	visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and plate_label != null:
		_refresh()


## Opens on step 1. Skip meal only when the avatar is hungry.
func open() -> void:
	show_kind("")
	show()


## Step 1 (kind ""), or building a plate of GOOD or FAST_FOOD. The plate starts empty.
func show_kind(new_kind: String) -> void:
	kind = new_kind
	plate.clear()
	kind_box.visible = kind.is_empty()
	plate_box.visible = not kind.is_empty()
	good_grid.visible = kind == Canteen.GOOD
	fast_grid.visible = kind == Canteen.FAST_FOOD
	kind_title.text = "CANTEEN_GOOD" if kind == Canteen.GOOD else "CANTEEN_FAST"
	kind_title.add_theme_color_override("font_color", GOOD_COLOR if kind == Canteen.GOOD else FAST_COLOR)
	skip_button.visible = Hunger.is_hungry()
	_refresh()


func close() -> void:
	hide()
	closed.emit()


## Puts a food on the plate, if there is room.
func add_food(id: String) -> void:
	if plate.size() < Config.get_int("canteen.plate_max"):
		plate.append(id)
	_refresh()


## Takes the food in this place of the plate off.
func remove_at(index: int) -> void:
	if index < plate.size():
		plate.remove_at(index)
	_refresh()


func _refresh() -> void:
	var plate_max := Config.get_int("canteen.plate_max")
	plate_label.text = tr("CANTEEN_PLATE") % [plate.size(), plate_max]
	var slots := plate_row.get_children()
	for i in slots.size():
		slots[i].food_id = plate[i] if i < plate.size() else ""
		slots[i].disabled = i >= plate.size()
	eat_button.disabled = plate.is_empty()
	for grid in [good_grid, fast_grid]:
		for tile in grid.get_children():
			tile.disabled = plate.size() >= plate_max
			tile.modulate.a = 0.4 if tile.disabled else 1.0


func _on_eat() -> void:
	var foods := plate.duplicate()
	close()
	Activities.start_plate(foods)


func _on_skip() -> void:
	close()
	Hunger.skip()


func _grid(parent: Control) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
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
