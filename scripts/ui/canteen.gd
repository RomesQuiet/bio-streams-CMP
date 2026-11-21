extends ColorRect
## The canteen (Milestone 21, third version, decisions 65 and 66). Two steps: first good food or
## fast food, then the player builds a plate of up to canteen.plate_max foods of that kind from
## many examples (a tap puts a food on the plate, a tap on the plate takes it off) and eats it
## (Activities.start_plate()). A good plate is the healthy meal and a fast-food plate the
## fast-food meal, so the health model is unchanged. Every text is a translation key.
## Milestone 40 (documentation/ui_v2/changes.md, change 10, "Let's eat"): the first step is a
## panel at the table's places: "Let's eat!", the question, two cards with the team's pictures
## (a tap only chooses; Good food is chosen when it opens), Skip meal when hungry, Cancel and
## Continue (it opens the plate of the chosen kind).

signal closed

const Canteen := preload("res://scripts/health/canteen.gd")
const Hunger := preload("res://scripts/health/hunger.gd")
const FoodTile := preload("res://scripts/ui/food_tile.gd")
const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")
const EatCard := preload("res://scripts/ui/eat_card.gd")
const DockButton := preload("res://scripts/ui/dock_button.gd")
## Change 10: places in the column (the table "Let's eat").
const CHOICE_PANEL := Rect2(52, 214, 616, 656)
const CHOICE_ICON := Rect2(332, 224, 56, 56)
const CHOICE_TITLE := Rect2(80, 280, 560, 48)
const CHOICE_DIVIDER_Y := 336.0
const CHOICE_DIVIDER := Vector2(148, 572)
const CHOICE_QUESTION := Rect2(80, 350, 560, 34)
const GOOD_CARD := Rect2(80, 400, 560, 164)
const FAST_CARD := Rect2(80, 578, 560, 164)
const CARD_PICTURES := {"good": "res://assets/art/menu/eat_choice_good.png", "fast_food": "res://assets/art/menu/eat_choice_fast.png"}
## The buttons (a face of 76 and a thickness of 8); with Skip meal they move down 92.
const SKIP_RECT := Rect2(80, 760, 560, 84)
const CANCEL_RECT := Rect2(80, 760, 270, 84)
const CONTINUE_RECT := Rect2(370, 760, 270, 84)
const SKIP_SHIFT := 92.0
const CHOICE_BUTTON_FACE := 76.0
const CHOICE_PANEL_BELOW := 34.0
const COLUMNS := 5
const GOOD_COLOR := Color(0.55, 0.9, 0.55)
const FAST_COLOR := Color(1.0, 0.65, 0.45)

## The kind being shown: "" (step 1), Canteen.GOOD or Canteen.FAST_FOOD (step 2).
var kind := ""
## Food ids on the plate, in the order they were added.
var plate: Array[String] = []
var kind_box: Control
## The card chosen in the first step (Canteen.GOOD or Canteen.FAST_FOOD).
var chosen_kind := ""
var continue_button: Button
var cancel_button: Button
## Where the first step's panel ends (it is longer with Skip meal).
var _choice_bottom := 870.0
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
	color = Color(0.04, 0.05, 0.16, 0.6)
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
	var top_title := _label("CANTEEN_TITLE", 32, content)
	top_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_choice()
	# Step 2: build a plate of that kind.
	plate_box = VBoxContainer.new()
	plate_box.add_theme_constant_override("separation", 10)
	content.add_child(plate_box)
	panel.visible = false
	plate_box.set_meta("panel", panel)
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


## Change 10: the first step, at the table's places (this screen covers the column).
func _build_choice() -> void:
	kind_box = Control.new()
	kind_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kind_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(kind_box)
	var title := _label("EAT_CHOOSE_TITLE", 44, kind_box)
	title.add_theme_font_override("font", Ui.FONT_HEAVY)
	_place_label(title, CHOICE_TITLE)
	var question := _label("EAT_CHOOSE_QUESTION", 26, kind_box)
	_place_label(question, CHOICE_QUESTION)
	good_button = _card(Canteen.GOOD, "CANTEEN_GOOD", "EAT_GOOD_SUB", GOOD_CARD)
	fast_button = _card(Canteen.FAST_FOOD, "CANTEEN_FAST", "EAT_FAST_SUB", FAST_CARD)
	skip_button = _choice_button("UI_SKIP_MEAL", "", false)
	skip_button.pressed.connect(_on_skip)
	cancel_button = _choice_button("UI_CANCEL", "✕  ", false)
	cancel_button.pressed.connect(close)
	continue_button = _choice_button("UI_CONTINUE", "▶  ", true)
	continue_button.pressed.connect(func() -> void: show_kind(chosen_kind))


func _place_label(label: Label, rect: Rect2) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = rect.position
	label.size = rect.size


func _card(card_kind: String, title_key: String, subtitle_key: String, rect: Rect2) -> Button:
	var card: Button = EatCard.new()
	card.text = title_key
	card.subtitle_key = subtitle_key
	card.picture = load(CARD_PICTURES[card_kind])
	card.position = rect.position
	card.size = rect.size
	card.pressed.connect(choose_kind.bind(card_kind))
	kind_box.add_child(card)
	return card


## Skip meal, Cancel and Continue: radius 26, a thickness of 8, ExtraBold 30 centred.
func _choice_button(key: String, prefix: String, mint: bool) -> Button:
	var button: Button = DockButton.new()
	button.text = key
	button.focus_mode = Control.FOCUS_NONE
	button.face = Ui.MINIGAME_UP_COLOR if mint else Ui.TILE_COLOR
	button.base = Ui.MINIGAME_UP_BASE if mint else Ui.TILE_BASE
	button.radius = 26.0
	button.word_size = 30
	button.word_centred = true
	button.word_y = CHOICE_BUTTON_FACE * 0.5
	button.prefix = prefix
	kind_box.add_child(button)
	return button


## Chooses a card (it does not open the plate yet).
func choose_kind(card_kind: String) -> void:
	chosen_kind = card_kind
	good_button.chosen = card_kind == Canteen.GOOD
	fast_button.chosen = card_kind == Canteen.FAST_FOOD


## The first step's buttons: with Skip meal (when hungry) Cancel and Continue move down 92 and
## the panel grows.
func _place_choice_buttons(with_skip: bool) -> void:
	var shift := SKIP_SHIFT if with_skip else 0.0
	skip_button.visible = with_skip
	for pair in [[skip_button, SKIP_RECT, 0.0], [cancel_button, CANCEL_RECT, shift], [continue_button, CONTINUE_RECT, shift]]:
		var button: Button = pair[0]
		var rect: Rect2 = pair[1]
		button.position = rect.position + Vector2(0, pair[2])
		button.size = rect.size
		button.word_x = rect.size.x * 0.5
	_choice_bottom = CANCEL_RECT.position.y + shift + CHOICE_BUTTON_FACE + CHOICE_PANEL_BELOW
	queue_redraw()


## The first step's panel, its apple and divider (under the children).
func _draw() -> void:
	if not kind.is_empty():
		return
	var panel := Rect2(CHOICE_PANEL.position, Vector2(CHOICE_PANEL.size.x, _choice_bottom - CHOICE_PANEL.position.y))
	draw_colored_polygon(Ui.rounded_rect_points(panel, 28.0), Ui.PANEL_COLOR)
	Ui.draw_outline(self, Ui.rounded_rect_points(panel.grow(-1.0), 27.0), Color.WHITE, Ui.BORDER_THIN)
	Icons.draw(self, "apple_line", CHOICE_ICON.get_center(), CHOICE_ICON.size.x, Color.WHITE)
	draw_line(Vector2(CHOICE_DIVIDER.x, CHOICE_DIVIDER_Y), Vector2(CHOICE_DIVIDER.y, CHOICE_DIVIDER_Y), Ui.WHITE_25, 2.0)


## Opens on step 1. Skip meal only when the avatar is hungry.
func open() -> void:
	choose_kind(Canteen.GOOD)
	show_kind("")
	show()


## Step 1 (kind ""), or building a plate of GOOD or FAST_FOOD. The plate starts empty.
func show_kind(new_kind: String) -> void:
	kind = new_kind
	plate.clear()
	kind_box.visible = kind.is_empty()
	plate_box.visible = not kind.is_empty()
	plate_box.get_meta("panel").visible = not kind.is_empty()
	good_grid.visible = kind == Canteen.GOOD
	fast_grid.visible = kind == Canteen.FAST_FOOD
	kind_title.text = "CANTEEN_GOOD" if kind == Canteen.GOOD else "CANTEEN_FAST"
	kind_title.add_theme_color_override("font_color", GOOD_COLOR if kind == Canteen.GOOD else FAST_COLOR)
	_place_choice_buttons(Hunger.is_hungry())
	if kind.is_empty() and chosen_kind.is_empty():
		choose_kind(Canteen.GOOD)
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
