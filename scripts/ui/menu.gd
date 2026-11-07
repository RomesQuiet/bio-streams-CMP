extends Control
## The main menu (Milestone 18, user, 7 Nov 2026): the first screen. Continue (the avatar played
## last), New avatar, Avatars (save.slots places: play, back up, delete), Load a backup, About
## and the language. The lobby's look: the sky, the grey ground and the last avatar standing; the
## team's pictures of the creation process and the music come later (placeholders).
## Every text is a translation key.

const MAIN_SCENE := "res://scenes/main.tscn"
const CREATION_SCENE := "res://scenes/ui/creation.tscn"
const AVATAR_SCENE := "res://scenes/avatar/avatar.tscn"
const SKY_COLOR := Color(0.3, 0.45, 0.62)
const GROUND_COLOR := Color(0.5, 0.5, 0.52)
const DIM_COLOR := Color(0, 0, 0, 0.6)
const CAPTION_COLOR := Color(0.75, 0.77, 0.82)
const FAILED_COLOR := Color(1.0, 0.5, 0.45)
const GROUND_TOP := 700.0

var _home: VBoxContainer
var _continue_button: Button
var _avatar: Control
var _avatars_page: Control
var _cards: VBoxContainer
var _message: Label
var _about_page: Control
## The place whose Delete is waiting for its second press (-1: none).
var _confirm_delete := -1
## Kept so the browser callback is not freed while the file is read.
var _file_callback: JavaScriptObject
var _file_dialog: FileDialog


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

func _build() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var sky := ColorRect.new()
	sky.color = SKY_COLOR
	sky.set_anchors_preset(PRESET_FULL_RECT)
	add_child(sky)
	var ground := ColorRect.new()
	ground.color = GROUND_COLOR
	ground.set_anchors_preset(PRESET_FULL_RECT)
	ground.offset_top = GROUND_TOP
	add_child(ground)
	var title := _label("MENU_TITLE", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_TOP_WIDE)
	title.offset_top = 70
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 10)
	add_child(title)
	var subtitle := _label("MENU_SUBTITLE", 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(PRESET_TOP_WIDE)
	subtitle.offset_top = 150
	add_child(subtitle)
	_avatar = load(AVATAR_SCENE).instantiate()
	_avatar.size = Vector2(330, 450)
	_avatar.position = Vector2(360 - 165, GROUND_TOP + 10 - 450)
	add_child(_avatar)
	_home = VBoxContainer.new()
	_home.add_theme_constant_override("separation", 14)
	_home.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_home.offset_left = 60
	_home.offset_right = -60
	_home.offset_top = -470
	_home.offset_bottom = -40
	add_child(_home)
	_continue_button = _button("", _continue, 96)
	_home.add_child(_continue_button)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.add_child(_button("MENU_NEW_AVATAR", _new_avatar, 76, true))
	row.add_child(_button("MENU_AVATARS", _open_avatars, 76, true))
	_home.add_child(row)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 14)
	row2.add_child(_button("MENU_LOAD_BACKUP", _load_backup, 76, true))
	row2.add_child(_button("MENU_ABOUT", _open_about, 76, true))
	_home.add_child(row2)
	var languages := HBoxContainer.new()
	languages.add_theme_constant_override("separation", 14)
	var group := ButtonGroup.new()
	for id in ["pt", "en"]:
		var language := _button("Português" if id == "pt" else "English", Settings.set_language.bind(id), 64, true)
		language.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		language.toggle_mode = true
		language.button_group = group
		language.set_pressed_no_signal(Settings.language == id)
		languages.add_child(language)
	_home.add_child(languages)
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
	var last := Settings.last_slot if Settings.last_slot < SaveGame.slot_count() else 0
	var avatar := SaveGame.slot_summary(last)
	_continue_button.visible = not avatar.is_empty()
	if not avatar.is_empty():
		_continue_button.text = "%s\n%s" % [tr("MENU_CONTINUE"), summary_text(avatar)]
	_show_avatar(_avatar, avatar)
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

func _continue() -> void:
	_play(Settings.last_slot if Settings.last_slot < SaveGame.slot_count() else 0)


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
