extends ColorRect
## The canteen (Milestone 21, third version, decisions 65 and 66). Two steps: first good food or
## fast food, then the player builds a plate of up to canteen.plate_max foods of that kind from
## many examples (a tap puts a food on the plate, a tap on the plate takes it off) and eats it
## (Activities.start_plate()). A good plate is the healthy meal and a fast-food plate the
## fast-food meal, so the health model is unchanged. Every text is a translation key.
## Milestone 40 (documentation/ui_v2/changes.md, change 10, "Let's eat"): the first step is a
## panel at the table's places: "Let's eat!", the question, two cards with the team's pictures
## (a tap only chooses; Good food is chosen when it opens), Skip meal when hungry, Cancel and
## Continue (it opens the plate of the chosen kind). Change 11 ("Canteen"): the second step is a
## tall panel at the table's places: the kind's icon and title, a grid of the foods with the
## team's pictures (5 columns for 10 foods, 4 for 8), "Your plate", a drawn plate with 4 places,
## the hint, Back and "Eat the plate".

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
## Change 11: places in the column (the table "Canteen").
const PLATE_PANEL := Rect2(24, 210, 672, 1022)
const KIND_ICON := Rect2(168, 226, 56, 56)
const KIND_TITLE := Rect2(232, 226, 320, 56)
const GRID_LEFT := 45.0
const GRID_ROWS := [306.0, 502.0]
## Tiles: 118 wide every 128 (5 columns, 10 foods) or 150 wide every 160 (4 columns, 8 foods).
const TILE_HEIGHT := 184.0
const NARROW_TILE := Vector2(118, 128)
const WIDE_TILE := Vector2(150, 160)
const PLATE_TITLE := Rect2(45, 724, 630, 36)
const PLATE_LINE_GAP := 16.0
const PLATE_CENTRE := Vector2(360, 872)
const PLATE_RADII := Vector2(300, 100)
const PLATE_RIM_RADII := Vector2(270, 80)
const PLATE_SHADOW_DROP := 12.0
const SLOT_XS := [96.0, 232.0, 368.0, 504.0]
const SLOT := Vector2(120, 100)
const SLOT_TOP := 822.0
const HINT := Rect2(45, 990, 630, 28)
const BACK_RECT := Rect2(48, 1120, 300, 92)
const EAT_RECT := Rect2(372, 1120, 300, 92)
const PLATE_BUTTON_FACE := 84.0

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
var plate_box: Control
var kind_title: Label
var good_grid: Control
var fast_grid: Control
var plate_row: Control
var plate_label: Label
var hint_label: Label
var back_button: Button
var good_button: Button
var fast_button: Button
var skip_button: Button
var eat_button: Button


func _ready() -> void:
	color = Color(0.04, 0.05, 0.16, 0.6)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_choice()
	_build_plate()
	visible = false


## Change 11: the second step, at the table's places.
func _build_plate() -> void:
	plate_box = Control.new()
	plate_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate_box)
	kind_title = _label("", 44, plate_box)
	kind_title.add_theme_font_override("font", Ui.FONT_HEAVY)
	kind_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kind_title.position = KIND_TITLE.position
	kind_title.size = KIND_TITLE.size
	good_grid = _grid(Canteen.GOOD)
	fast_grid = _grid(Canteen.FAST_FOOD)
	plate_label = _label("", 28, plate_box)
	_place_label(plate_label, PLATE_TITLE)
	hint_label = _label("CANTEEN_PLATE_HINT", 20, plate_box)
	_place_label(hint_label, HINT)
	hint_label.add_theme_color_override("font_color", Ui.WHITE_60)
	plate_row = Control.new()
	plate_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_box.add_child(plate_row)
	for i in Config.get_int("canteen.plate_max"):
		var place: Button = FoodTile.new()
		place.slot = true
		place.position = Vector2(SLOT_XS[i % SLOT_XS.size()], SLOT_TOP)
		place.size = SLOT
		place.pressed.connect(remove_at.bind(i))
		plate_row.add_child(place)
	back_button = _plate_button("CANTEEN_BACK", "←  ", Ui.SLEEP_COLOR, Ui.SLEEP_BASE, BACK_RECT)
	back_button.pressed.connect(show_kind.bind(""))
	eat_button = _plate_button("CANTEEN_EAT", "", Ui.MINIGAME_UP_COLOR, Ui.MINIGAME_UP_BASE, EAT_RECT)
	eat_button.pressed.connect(_on_eat)


## The foods of a kind: 5 columns for more than 8 foods, otherwise 4 wider ones (two rows).
func _grid(food_kind: String) -> Control:
	var grid := Control.new()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_box.add_child(grid)
	var ids := Canteen.foods(food_kind)
	var columns := 5 if ids.size() > 8 else 4
	var tile_size := NARROW_TILE if columns == 5 else WIDE_TILE
	for i in ids.size():
		var tile: Button = FoodTile.new()
		tile.food_id = ids[i]
		tile.position = Vector2(GRID_LEFT + tile_size.y * (i % columns), GRID_ROWS[mini(floori(float(i) / columns), GRID_ROWS.size() - 1)])
		tile.size = Vector2(tile_size.x, TILE_HEIGHT)
		tile.pressed.connect(add_food.bind(ids[i]))
		grid.add_child(tile)
	return grid


## Back and "Eat the plate": 300 x 84 and a thickness of 8, radius 26, ExtraBold 32.
func _plate_button(key: String, prefix: String, face: Color, base: Color, rect: Rect2) -> Button:
	var button: Button = DockButton.new()
	button.text = key
	button.focus_mode = Control.FOCUS_NONE
	button.face = face
	button.base = base
	button.radius = 26.0
	button.word_size = 32
	button.word_centred = true
	button.word_x = rect.size.x * 0.5
	button.word_y = PLATE_BUTTON_FACE * 0.5
	button.prefix = prefix
	button.position = rect.position
	button.size = rect.size
	plate_box.add_child(button)
	return button


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
		_draw_plate_step()
		return
	var panel := Rect2(CHOICE_PANEL.position, Vector2(CHOICE_PANEL.size.x, _choice_bottom - CHOICE_PANEL.position.y))
	draw_colored_polygon(Ui.rounded_rect_points(panel, 28.0), Ui.PANEL_COLOR)
	Ui.draw_outline(self, Ui.rounded_rect_points(panel.grow(-1.0), 27.0), Color.WHITE, Ui.BORDER_THIN)
	Icons.draw(self, "apple_line", CHOICE_ICON.get_center(), CHOICE_ICON.size.x, Color.WHITE)
	draw_line(Vector2(CHOICE_DIVIDER.x, CHOICE_DIVIDER_Y), Vector2(CHOICE_DIVIDER.y, CHOICE_DIVIDER_Y), Ui.WHITE_25, 2.0)


## Change 11: the tall panel, the kind's icon, the lines beside "Your plate" and the plate.
func _draw_plate_step() -> void:
	draw_colored_polygon(Ui.rounded_rect_points(PLATE_PANEL, 28.0), Ui.PANEL_COLOR)
	Ui.draw_outline(self, Ui.rounded_rect_points(PLATE_PANEL.grow(-1.0), 27.0), Color.WHITE, Ui.BORDER_THIN)
	Icons.draw(self, "hungry" if kind == Canteen.GOOD else "burger_line", KIND_ICON.get_center(), KIND_ICON.size.x, Color.WHITE)
	var font_size := plate_label.get_theme_font_size("font_size")
	var half := Ui.FONT_BOLD.get_string_size(plate_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * 0.5
	var y := PLATE_TITLE.get_center().y
	var middle := PLATE_TITLE.get_center().x
	draw_line(Vector2(PLATE_TITLE.position.x, y), Vector2(middle - half - PLATE_LINE_GAP, y), Ui.WHITE_60, 2.0)
	draw_line(Vector2(middle + half + PLATE_LINE_GAP, y), Vector2(PLATE_TITLE.end.x, y), Ui.WHITE_60, 2.0)
	var shadow := Ui.ellipse_points(PLATE_CENTRE + Vector2(0, PLATE_SHADOW_DROP), PLATE_RADII, 64)
	draw_colored_polygon(shadow, Ui.SHADOW_INK)
	var dish := Ui.ellipse_points(PLATE_CENTRE, PLATE_RADII, 64)
	draw_colored_polygon(dish, Ui.PLATE_COLOR)
	Ui.draw_outline(self, dish, Ui.PLATE_COLOR, 1.2)
	Ui.draw_outline(self, Ui.ellipse_points(PLATE_CENTRE, PLATE_RIM_RADII, 64), Ui.PLATE_RIM, Ui.BORDER_MEDIUM)


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
	good_grid.visible = kind == Canteen.GOOD
	fast_grid.visible = kind == Canteen.FAST_FOOD
	kind_title.text = "CANTEEN_GOOD" if kind == Canteen.GOOD else "CANTEEN_FAST"
	kind_title.add_theme_font_size_override("font_size", maxi(Ui.fit_font_size(Ui.FONT_HEAVY, tr(kind_title.text), 44,
			KIND_TITLE.size.x), 31))
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
			# On the plate: mint with a badge; a full plate takes no more (the others at 45%).
			tile.chosen = plate.has(tile.food_id)
			tile.disabled = plate.size() >= plate_max
	hint_label.add_theme_font_size_override("font_size", maxi(Ui.fit_font_size(Ui.FONT_BOLD, tr("CANTEEN_PLATE_HINT"), 20,
			HINT.size.x), 15))
	queue_redraw()


func _on_eat() -> void:
	var foods := plate.duplicate()
	close()
	Activities.start_plate(foods)


func _on_skip() -> void:
	close()
	Hunger.skip()


func _label(text: String, font_size: int, parent: Control) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label
