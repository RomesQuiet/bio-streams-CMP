extends Control
## The main menu (Milestone 18, user, 7 Nov 2026): the first screen. Continue (the avatar played
## last), New avatar, Avatars (save.slots places: play, back up, delete), Load a backup, About
## and the language. Since Milestone 40 it has the look of the team's splash screen (coloured
## buttons with icons, a PT/EN switch); since the team's updated zip (22 Nov 2026) its background
## is the team's picture, with the four figures on the hill (scripts/ui/menu_backdrop.gd); the
## music comes later.
## Every text is a translation key.

const MAIN_SCENE := "res://scenes/main.tscn"
const CREATION_SCENE := "res://scenes/ui/creation.tscn"
const AVATAR_SCENE := "res://scenes/avatar/avatar.tscn"
const Ui := preload("res://scripts/ui/ui_style.gd")
const MenuBackdrop := preload("res://scripts/ui/menu_backdrop.gd")
const MenuButtonScript := preload("res://scripts/ui/menu_button.gd")
const LanguageToggle := preload("res://scripts/ui/language_toggle.gd")
const OutsideDim := preload("res://scripts/ui/outside_dim.gd")
const DIM_COLOR := Ui.DIM_COLOR
const CAPTION_COLOR := Color(0.75, 0.77, 0.82)
const FAILED_COLOR := Color(1.0, 0.5, 0.45)

var _home: VBoxContainer
var _continue_button: Button
var _avatars_page: Control
var _cards: VBoxContainer
var _message: Label
var _about_page: Control
## The place whose Delete is waiting for its second press (-1: none).
var _confirm_delete := -1
## Kept so the browser callback is not freed while the file is read.
var _file_callback: JavaScriptObject
var _file_dialog: FileDialog
var _outside_dim: Control


func _ready() -> void:
	# The menu never plays: the game is emptied and time stands still.
	SaveGame.unload()
	_build()
	_refresh()
	if SaveGame.menu_request == "new_avatar":
		SaveGame.menu_request = ""
		_new_avatar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and _home != null:
		_refresh()


# --- Layout ----------------------------------------------------------------------------------

## Milestone 40: the team's splash screen (21 Nov 2026), measured from its 900 x 1600 picture and
## scaled to the 720 x 1280 column: the title and subtitle, four buttons and the language switch
## (the figures on the hill are in the background picture). Rects are [x, y, w, h]; "B" ones keep their distance from the
## bottom of the screen (the buttons), the others their distance from the top.
const TITLE_RECT := Rect2(24, 96, 672, 80)
const TITLE_FONT_SIZE := 64
const SUBTITLE_RECT := Rect2(16, 182, 688, 34)
const SUBTITLE_FONT_SIZE := 24
const BUTTON_X := 90.0
const BUTTON_WIDTH := 540.0
## Without Continue: the four buttons of the splash (faces 86 high and a 6-pixel thickness).
const BUTTON_TOPS := [691.0, 799.0, 908.0, 1016.0]
const BUTTON_HEIGHT := 92.0
const TOGGLE_RECT := Rect2(242, 1142, 238, 56)
const REFERENCE_HEIGHT := 1280.0

var _title: Label
var _new_avatar_button: Button
var _subtitle: Label
var _buttons: Array[Button] = []
var _backdrop: Control


## Puts a control at a rect of the column; bottom: it keeps its distance from the bottom.
static func place(control: Control, rect: Rect2, bottom := false) -> void:
	var anchor := 1.0 if bottom else 0.0
	var shift := REFERENCE_HEIGHT if bottom else 0.0
	control.anchor_left = 0.0
	control.anchor_right = 0.0
	control.anchor_top = anchor
	control.anchor_bottom = anchor
	control.offset_left = rect.position.x
	control.offset_right = rect.end.x
	control.offset_top = rect.position.y - shift
	control.offset_bottom = rect.end.y - shift


func _build() -> void:
	# A 720-wide column in the middle, as tall as the screen; the backdrop fills the whole screen
	# behind it (Milestone 25, decision 87).
	Ui.make_column(self)
	_backdrop = MenuBackdrop.new()
	add_child(_backdrop)
	_title = _label("MENU_TITLE", TITLE_FONT_SIZE)
	_title.add_theme_font_override("font", Ui.FONT_HEAVY)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Color.WHITE)
	_title.add_theme_color_override("font_outline_color", Ui.MENU_TITLE_OUTLINE)
	_title.add_theme_constant_override("outline_size", 16)
	_title.add_theme_color_override("font_shadow_color", Ui.MENU_TITLE_OUTLINE)
	_title.add_theme_constant_override("shadow_offset_x", 0)
	_title.add_theme_constant_override("shadow_offset_y", 5)
	_title.add_theme_constant_override("shadow_outline_size", 16)
	place(_title, TITLE_RECT)
	add_child(_title)
	var subtitle := _label("MENU_SUBTITLE", SUBTITLE_FONT_SIZE)
	_subtitle = subtitle
	subtitle.add_theme_font_override("font", Ui.FONT_HEAVY)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	subtitle.add_theme_color_override("font_shadow_color", Color(Ui.MENU_TITLE_OUTLINE, 0.45))
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	place(subtitle, SUBTITLE_RECT)
	add_child(subtitle)
	_home = VBoxContainer.new()
	_home.set_anchors_preset(PRESET_FULL_RECT)
	_home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_home)
	# The user (21 Nov 2026): Continue takes New avatar's place; New avatar is on the first screen
	# only while there is no avatar (later it is in the Avatars page, for an empty place).
	_continue_button = _menu_button("", _continue, Ui.MENU_NEW_FACE, Ui.MENU_NEW_BASE, "play")
	_new_avatar_button = _menu_button("MENU_NEW_AVATAR", _new_avatar, Ui.MENU_NEW_FACE, Ui.MENU_NEW_BASE, "person_add")
	_menu_button("MENU_AVATARS", _open_avatars, Ui.MENU_AVATARS_FACE, Ui.MENU_AVATARS_BASE, "people")
	_menu_button("MENU_LOAD_BACKUP", _load_backup, Ui.MENU_BACKUP_FACE, Ui.MENU_BACKUP_BASE, "upload")
	_menu_button("MENU_ABOUT", _open_about, Ui.MENU_ABOUT_FACE, Ui.MENU_ABOUT_BASE, "info")
	var languages := LanguageToggle.new()
	place(languages, TOGGLE_RECT, true)
	add_child(languages)
	_avatars_page = _page("MENU_AVATARS")
	var content: VBoxContainer = _avatars_page.get_meta("content")
	_message = _label("", 20)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_message)
	_cards = VBoxContainer.new()
	_cards.add_theme_constant_override("separation", 12)
	content.add_child(_cards)
	content.add_child(_button("MENU_BACK", _close_pages, 64))
	_about_page = _page("MENU_ABOUT")
	var about: VBoxContainer = _about_page.get_meta("content")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 760)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var text := _label("MENU_ABOUT_TEXT", 20)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 560
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(text)
	about.add_child(scroll)
	about.add_child(_button("MENU_BACK", _close_pages, 64))
	_outside_dim = OutsideDim.new()
	_outside_dim.column = self
	_outside_dim.color = DIM_COLOR
	add_child(_outside_dim)


func _menu_button(key: String, on_pressed: Callable, face: Color, base: Color, icon: String) -> Button:
	var button := MenuButtonScript.new(face, base, icon)
	button.text = key
	button.pressed.connect(on_pressed)
	add_child(button)
	_buttons.append(button)
	return button


## The four buttons at the splash's places (Continue or New avatar first).
func _layout_buttons() -> void:
	var shown: Array[Button] = []
	for button in _buttons:
		if button.visible:
			shown.append(button)
	for i in mini(shown.size(), BUTTON_TOPS.size()):
		place(shown[i], Rect2(BUTTON_X, BUTTON_TOPS[i], BUTTON_WIDTH, BUTTON_HEIGHT), true)


## The title and subtitle as large as fit (Portuguese is longer), down to 70% of its size.
func _fit_title() -> void:
	var fitted := Ui.fit_font_size(Ui.FONT_HEAVY, tr("MENU_TITLE"), TITLE_FONT_SIZE, TITLE_RECT.size.x - 24.0)
	_title.add_theme_font_size_override("font_size", maxi(fitted, int(TITLE_FONT_SIZE * 0.7)))
	fitted = Ui.fit_font_size(Ui.FONT_HEAVY, tr("MENU_SUBTITLE"), SUBTITLE_FONT_SIZE, SUBTITLE_RECT.size.x - 8.0)
	_subtitle.add_theme_font_size_override("font_size", maxi(fitted, int(SUBTITLE_FONT_SIZE * 0.7)))


## The backdrop follows the column, and the outside is dimmed while a page is open.
func _process(_delta: float) -> void:
	if _backdrop == null:
		return
	_backdrop.column_rect = get_global_rect()
	_outside_dim.amount = DIM_COLOR.a if (_avatars_page.visible or _about_page.visible) else 0.0


## A page over the menu in the settings panel's style; its content box is in the "content" meta.
func _page(title_key: String) -> Control:
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.visible = false
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	panel.set_anchors_preset(PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 24)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	var title := _label(title_key, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	margin.add_child(content)
	panel.add_child(margin)
	dim.add_child(panel)
	dim.set_meta("content", content)
	add_child(dim)
	return dim


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _button(text: String, on_pressed: Callable, height: float, expand := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	if expand:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(on_pressed)
	return button


# --- What the menu shows ---------------------------------------------------------------------

func _refresh() -> void:
	var place := continue_place()
	var avatar := SaveGame.slot_summary(place) if place >= 0 else {}
	_continue_button.visible = not avatar.is_empty()
	_new_avatar_button.visible = avatar.is_empty()
	if not avatar.is_empty():
		_continue_button.text = "%s\n%s" % [tr("MENU_CONTINUE"), summary_text(avatar)]
	_layout_buttons()
	_fit_title()
	if _avatars_page.visible:
		_build_cards()


## One line about an avatar: its name, level, health and days, or that it failed.
func summary_text(avatar: Dictionary) -> String:
	var days := Settings.number(float(avatar.get("sim_hours", 0.0)) / Config.get_float("units.hours_per_day"), 1)
	if not str(avatar.get("failed_cause", "")).is_empty():
		return tr("MENU_SUMMARY_FAILED") % [avatar.get("avatar_name", ""), days]
	var level := floori(float(avatar.get("xp", 0.0)) / maxf(1.0, Config.get_float("xp.per_level")))
	return tr("MENU_SUMMARY") % [avatar.get("avatar_name", ""), level, Settings.number(float(avatar.get("health", 0.0)), 1), days]


## The avatar's picture from its saved values (the egg when there is none).
func _show_avatar(picture: Control, avatar: Dictionary) -> void:
	if avatar.is_empty():
		picture.sheet = ""
		picture.states = {}
		return
	picture.states = {
		"thin": float(avatar.get("weight_z", 0.0)) < Config.get_float("avatar_states.thin_below_z"),
		"overweight": float(avatar.get("weight_z", 0.0)) > Config.get_float("avatar_states.overweight_above_z"),
		"obese": float(avatar.get("weight_z", 0.0)) > Config.get_float("avatar_states.obese_above_z"),
		"muscular": float(avatar.get("strength", 0.0)) >= Config.get_float("avatar_states.muscular_strength"),
		"happy": float(avatar.get("happiness", 0.0)) >= Config.get_float("avatar_states.happy_from"),
		"sad": float(avatar.get("happiness", 0.0)) < Config.get_float("avatar_states.sad_below")
				or not str(avatar.get("failed_cause", "")).is_empty(),
	}
	picture.sheet = "%s_%s" % [avatar.get("age_group", ""), avatar.get("sex", "")]


## The avatars page: one card per place, with Play, Backup and Delete, or New avatar.
func _build_cards() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for place in SaveGame.slot_count():
		var avatar := SaveGame.slot_summary(place)
		var card := PanelContainer.new()
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var picture: Control = load(AVATAR_SCENE).instantiate()
		picture.custom_minimum_size = Vector2(88, 120)
		_show_avatar(picture, avatar)
		row.add_child(picture)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 6)
		var line := _label(tr("MENU_EMPTY_PLACE") if avatar.is_empty() else summary_text(avatar), 20)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if not str(avatar.get("failed_cause", "")).is_empty():
			line.add_theme_color_override("font_color", FAILED_COLOR)
		column.add_child(line)
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 8)
		if avatar.is_empty():
			buttons.add_child(_button("MENU_NEW_AVATAR", _start_in.bind(place), 56, true))
		elif _confirm_delete == place:
			line.text = tr("MENU_DELETE_QUESTION") % avatar.get("avatar_name", "")
			buttons.add_child(_button("UI_CANCEL", _ask_delete.bind(-1), 56, true))
			buttons.add_child(_button("MENU_DELETE_YES", _delete.bind(place), 56, true))
		else:
			buttons.add_child(_button("MENU_PLAY", _play.bind(place), 56, true))
			buttons.add_child(_button("MENU_BACKUP", _download_backup.bind(place), 56, true))
			buttons.add_child(_button("MENU_DELETE", _ask_delete.bind(place), 56, true))
		column.add_child(buttons)
		row.add_child(column)
		var margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 10)
		margin.add_child(row)
		card.add_child(margin)
		_cards.add_child(card)


# --- Actions ---------------------------------------------------------------------------------

## The place Continue opens: the avatar played last, or else the first place with an avatar;
## -1 when there is no avatar at all (then New avatar is shown instead).
func continue_place() -> int:
	var last := Settings.last_slot if Settings.last_slot < SaveGame.slot_count() else 0
	if not SaveGame.slot_summary(last).is_empty():
		return last
	for place in SaveGame.slot_count():
		if not SaveGame.slot_summary(place).is_empty():
			return place
	return -1


func _continue() -> void:
	var place := continue_place()
	if place >= 0:
		_play(place)


func _play(place: int) -> void:
	if SaveGame.play_slot(place):
		get_tree().change_scene_to_file(MAIN_SCENE)


## A new avatar in the first free place; when all are taken, the avatars page says so.
func _new_avatar() -> void:
	var place := SaveGame.first_free_slot()
	if place < 0:
		_open_avatars("MENU_FULL")
		return
	_start_in(place)


func _start_in(place: int) -> void:
	SaveGame.start_slot(place)
	get_tree().change_scene_to_file(CREATION_SCENE)


func _open_avatars(message := "") -> void:
	_confirm_delete = -1
	_message.text = message
	_message.visible = not message.is_empty()
	_build_cards()
	_about_page.hide()
	_avatars_page.show()


func _open_about() -> void:
	_avatars_page.hide()
	_about_page.show()


func _close_pages() -> void:
	_avatars_page.hide()
	_about_page.hide()
	_refresh()


func _ask_delete(place: int) -> void:
	_confirm_delete = place
	_build_cards()


func _delete(place: int) -> void:
	SaveGame.delete_slot(place)
	_confirm_delete = -1
	_message.visible = false
	_build_cards()
	_refresh()


# --- Backups ---------------------------------------------------------------------------------

func _download_backup(place: int) -> void:
	var text := SaveGame.backup_text(place)
	if text.is_empty():
		return
	var file_name := "%s-backup.json" % str(SaveGame.slot_summary(place).get("avatar_name", "avatar")).validate_filename()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), file_name, "application/json")
		_show_message("MENU_BACKUP_DONE")
		return
	_ask_file(FileDialog.FILE_MODE_SAVE_FILE, file_name, func(path: String) -> void:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(text)
			file.close()
			_show_message("MENU_BACKUP_DONE"))


## Loads a backup file into the first free place.
func _load_backup() -> void:
	if SaveGame.first_free_slot() < 0:
		_open_avatars("MENU_FULL")
		return
	if OS.has_feature("web"):
		_file_callback = JavaScriptBridge.create_callback(func(args: Array) -> void: restore(str(args[0])))
		JavaScriptBridge.get_interface("window").set("godotBackupLoaded", _file_callback)
		JavaScriptBridge.eval("""(function () {
			var input = document.createElement('input');
			input.type = 'file';
			input.accept = '.json,application/json';
			input.onchange = function () {
				var file = input.files[0];
				if (!file) { return; }
				var reader = new FileReader();
				reader.onload = function () { window.godotBackupLoaded(reader.result); };
				reader.readAsText(file);
			};
			input.click();
		})()""")
		return
	_ask_file(FileDialog.FILE_MODE_OPEN_FILE, "", func(path: String) -> void: restore(FileAccess.get_file_as_string(path)))


## The text of a backup file: into the first free place, or a message why not.
func restore(text: String) -> void:
	var place := SaveGame.first_free_slot()
	if place < 0:
		_open_avatars("MENU_FULL")
	elif SaveGame.restore_backup(text, place):
		_open_avatars("MENU_BACKUP_LOADED")
	else:
		_open_avatars("MENU_BACKUP_INVALID")
	_refresh()


func _show_message(key: String) -> void:
	_message.text = key
	_message.visible = true


## On a computer: Godot's file window (the browser uses its own).
func _ask_file(mode: FileDialog.FileMode, file_name: String, on_chosen: Callable) -> void:
	if _file_dialog != null:
		_file_dialog.queue_free()
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_mode = mode
	_file_dialog.use_native_dialog = true
	_file_dialog.filters = PackedStringArray(["*.json"])
	_file_dialog.current_file = file_name
	_file_dialog.file_selected.connect(on_chosen)
	add_child(_file_dialog)
	_file_dialog.popup_centered_ratio(0.8)
