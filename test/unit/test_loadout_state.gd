extends GutTest

const LoadoutStateScript = preload("res://Assets/Scripts/loadout_state.gd")

var _state: Node
var _storage_path: String


func before_each() -> void:
	_storage_path = "user://test_loadout_%s.cfg" % get_instance_id()
	_remove_test_file()
	_state = autofree(LoadoutStateScript.new())
	_state.storage_path = _storage_path
	_state.load_selection()


func after_each() -> void:
	_remove_test_file()


func test_defaults_match_existing_equipment() -> void:
	assert_eq(_state.selected_weapon_id, "shotgun")
	assert_eq(_state.selected_ultimate_id, "avada")
	assert_eq(_state.selected_gadget_id, "dash")
	assert_eq(_state.selected_effect_id, "none")
	assert_eq(_state.get_options(&"weapon").size(), 4)
	assert_eq(_state.get_options(&"ultimate").size(), 1)
	assert_eq(_state.get_options(&"gadget").size(), 1)
	assert_eq(_state.get_options(&"effect").size(), 5)


func test_every_configured_icon_and_effect_resource_exists() -> void:
	for category in [&"weapon", &"ultimate", &"gadget", &"effect"]:
		for option in _state.get_options(category):
			var icon_path: String = option.get("icon", "")
			if not icon_path.is_empty():
				assert_true(ResourceLoader.exists(icon_path), "missing icon: %s" % icon_path)
			var resource_path: String = option.get("resource_path", "")
			if not resource_path.is_empty():
				assert_true(ResourceLoader.exists(resource_path), "missing resource: %s" % resource_path)


func test_confirmed_selection_is_loaded_by_a_new_state() -> void:
	assert_eq(_state.confirm_selection("sniper", "avada", "dash", "shock"), OK)
	var loaded_state = autofree(LoadoutStateScript.new())
	loaded_state.storage_path = _storage_path
	loaded_state.load_selection()

	assert_eq(loaded_state.selected_weapon_id, "sniper")
	assert_eq(loaded_state.selected_ultimate_id, "avada")
	assert_eq(loaded_state.selected_gadget_id, "dash")
	assert_eq(loaded_state.selected_effect_id, "shock")


func test_invalid_selection_is_rejected_without_changing_state() -> void:
	var error: Error = _state.confirm_selection("missing", "avada", "dash")

	assert_eq(error, ERR_INVALID_DATA)
	assert_eq(_state.selected_weapon_id, "shotgun")
	assert_false(FileAccess.file_exists(_storage_path))


func test_invalid_saved_ids_fall_back_to_defaults() -> void:
	var config := ConfigFile.new()
	config.set_value("loadout", "weapon", "removed_weapon")
	config.set_value("loadout", "ultimate", "removed_ultimate")
	config.set_value("loadout", "gadget", "removed_gadget")
	config.set_value("loadout", "effect", "removed_effect")
	assert_eq(config.save(_storage_path), OK)

	_state.load_selection()

	assert_eq(_state.selected_weapon_id, "shotgun")
	assert_eq(_state.selected_ultimate_id, "avada")
	assert_eq(_state.selected_gadget_id, "dash")
	assert_eq(_state.selected_effect_id, "none")


func _remove_test_file() -> void:
	if FileAccess.file_exists(_storage_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_storage_path))
