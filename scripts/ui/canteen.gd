extends ColorRect
## The canteen (Milestone 21, decisions 61 to 64): two choosers, healthy food and bad food, with
## many examples, and a plate of up to canteen.plate_max foods. A tap on a food puts it on the
## plate; a tap on the plate takes it off. Eat the plate starts the meal (Activities.start_plate());
## a plate counts by share of the healthy and fast-food meals, so the health model is unchanged.
## Every text is a translation key.

signal closed

const Canteen := preload("res://scripts/health/canteen.gd")
const Hunger := preload("res://scripts/health/hunger.gd")
const FoodTile := preload("res://scripts/ui/food_tile.gd")
const COLUMNS := 5

## Food ids on the plate, in the order they were added.
var plate: Array[String] = []
var healthy_grid: GridContainer
var bad_grid: GridContainer
var plate_row: HBoxContainer
var plate_label: Label
var eat_button: Button
var skip_button: Button


func _ready() -> void:
	color = Color(0, 0, 0, 0.6)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 12.0
	panel.offset_top = 24.0
	panel.offset_right = -12.0
	panel.offset_bottom = -24.0
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var title := _label("CANTEEN_TITLE", 32, content)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label("CANTEEN_HEALTHY", 24, content).add_theme_color_override("font_color", Color(0.55, 0.9, 0.55))
	healthy_grid = _grid(content)
	_label("CANTEEN_BAD", 24, content).add_theme_color_override("font_color", Color(1.0, 0.65, 0.45))
	bad_grid = _grid(content)
	plate_label = _label("", 24, content)
	var hint := _label("CANTEEN_PLATE_HINT", 18, content)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plate_row = HBoxContainer.new()
	plate_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(plate_row)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	eat_button = _button("CANTEEN_EAT", content, 72)
	eat_button.pressed.connect(_on_eat)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	skip_button = _button("UI_SKIP_MEAL", row, 64)
	skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_button.pressed.connect(_on_skip)
	var cancel := _button("UI_CANCEL", row, 64)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(close)
	for healthy in [true, false]:
		for id in Canteen.foods(healthy):
			var tile: Button = FoodTile.new()
			tile.food_id = id
			tile.pressed.connect(add_food.bind(id))
			(healthy_grid if healthy else bad_grid).add_child(tile)
	for i in Config.get_int("canteen.plate_max"):
		var slot: Button = FoodTile.new()
		slot.pressed.connect(remove_at.bind(i))
		plate_row.add_child(slot)
	visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and plate_label != null:
		_refresh()


## Opens with an empty plate. Skip meal only when the avatar is hungry.
func open() -> void:
	plate.clear()
	_refresh()
	show()


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
	skip_button.visible = Hunger.is_hungry()
	for grid in [healthy_grid, bad_grid]:
		for tile in grid.get_children():
			tile.disabled = plate.size() >= plate_max
			tile.modulate.a = 0.4 if tile.disabled else 1.0


func _on_eat() -> void:
	var foods := plate.duplicate()
	hide()
	closed.emit()
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
