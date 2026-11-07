extends SceneTree
## The main menu and the avatar places (Milestone 18). Run from the project folder (after --import):
##   Godot --headless --path . -s res://tests/menu_test.gd
## Uses the real place files in this user folder, so run it with an empty HOME (as every test).

var _failures := 0
var save_game: Node
var gs: Node
var clock: Node
var settings: Node


func _process(_delta: float) -> bool:
	save_game = root.get_node("SaveGame")
	gs = root.get_node("GameState")
	clock = root.get_node("Clock")
	settings = root.get_node("Settings")
	save_game.use_web_storage = false
	save_game.auto_save_enabled = false
	settings.use_web_storage = false
	settings.settings_path = "user://test_menu_settings.json"
	settings.set_language("en")
	for place in save_game.slot_count():
		save_game.delete_slot(place)
	_test_places()
	_test_backups()
	_test_menu_screen()
	for place in save_game.slot_count():
		save_game.delete_slot(place)
	DirAccess.remove_absolute("user://test_menu_settings.json")
	print("ALL PASSED (0 failed)" if _failures == 0 else "SOME FAILED (%d failed)" % _failures)
	quit(1 if _failures > 0 else 0)
	return true


func _make_avatar(place: int, avatar_name: String) -> void:
	save_game.start_slot(place)
	gs.start_new_avatar(avatar_name, "child", "female", "normal")
	save_game.save_game()


func _test_places() -> void:
	_check("3 places, all empty", save_game.slot_count() == 3 and save_game.first_free_slot() == 0)
	_check("place 1 keeps the old save file, the others their own",
			save_game.path_for(0) == "user://save.json" and save_game.path_for(2) == "user://save_3.json")
	_make_avatar(0, "Ana")
	_make_avatar(1, "Rui")
	_check("two avatars: the next free place is 3", save_game.first_free_slot() == 2)
	_check("each place keeps its own avatar", save_game.slot_summary(0)["avatar_name"] == "Ana"
			and save_game.slot_summary(1)["avatar_name"] == "Rui" and save_game.slot_summary(2).is_empty())
	save_game.unload()
	_check("the menu empties the game and stops time", not gs.is_created() and clock.halted)
	_check("playing a place loads its avatar and lets time run", save_game.play_slot(1) and gs.avatar_name == "Rui"
			and not clock.halted and settings.last_slot == 1)
	_check("an empty place cannot be played", not save_game.play_slot(2))
	save_game.delete_slot(0)
	_check("deleting a place empties only that one", save_game.slot_summary(0).is_empty()
			and save_game.slot_summary(1)["avatar_name"] == "Rui" and save_game.first_free_slot() == 0)


func _test_backups() -> void:
	var text: String = save_game.backup_text(1)
	_check("a backup is the avatar's save as text", text.contains("\"Rui\"") and save_game.backup_text(2).is_empty())
	_check("a file that is not a backup is refused", not save_game.restore_backup("{\"hello\": 1}", 2)
			and save_game.slot_summary(2).is_empty())
	_check("a backup loads into a place", save_game.restore_backup(text, 2) and save_game.slot_summary(2)["avatar_name"] == "Rui")
	_check("...and plays like the original", save_game.play_slot(2) and gs.avatar_name == "Rui")
	save_game.unload()


func _test_menu_screen() -> void:
	settings.set_last_slot(1)
	var menu: Control = load("res://scenes/ui/menu.tscn").instantiate()
	root.add_child(menu)
	_check("the menu opens with the game emptied", not gs.is_created() and clock.halted)
	_check("Continue shows the avatar played last", menu._continue_button.visible
			and menu._continue_button.text.begins_with("Continue\nRui · level 0"))
	menu._open_avatars()
	_check("the avatars page has a card per place", menu._cards.get_child_count() == 3)
	_make_avatar(0, "Ana")
	save_game.unload()
	menu._new_avatar()
	_check("all places taken: the avatars page says to delete one first", menu._avatars_page.visible
			and menu._message.text == "MENU_FULL")
	menu._ask_delete(0)
	_check("Delete asks first", menu._confirm_delete == 0 and not save_game.slot_summary(0).is_empty())
	menu._delete(0)
	_check("...and the second press deletes", save_game.slot_summary(0).is_empty())
	gs.failed_cause = ""
	var failed: Dictionary = save_game.slot_summary(1).duplicate()
	failed["failed_cause"] = "health"
	failed["sim_hours"] = 48.0
	_check("a failed avatar's card says so", menu.summary_text(failed) == "Rui · failed after 2.0 days")
	root.remove_child(menu)
	menu.free()


func _check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		_failures += 1
