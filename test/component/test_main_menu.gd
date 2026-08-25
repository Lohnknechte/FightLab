extends GutTest

const MainMenuScene = preload("res://Main_Menu.tscn")
const LevelScript = preload("res://Assets/Scripts/level01.gd")


func test_quick_join_is_connected_to_existing_level() -> void:
	var menu = add_child_autofree(MainMenuScene.instantiate())
	var quick_button: Button = menu.get_node("Quick_Button")

	assert_true(quick_button.pressed.is_connected(menu._quick_join))
	assert_true(ResourceLoader.exists(menu.QUICK_JOIN_SCENE))


func test_l_action_returns_to_existing_main_menu() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_L
	event.pressed = true

	assert_true(InputMap.has_action("return_to_menu"))
	assert_true(InputMap.event_is_action(event, "return_to_menu"))
	assert_true(ResourceLoader.exists(LevelScript.MAIN_MENU_SCENE))


func test_profile_and_loadout_navigation_is_connected() -> void:
	var menu = add_child_autofree(MainMenuScene.instantiate())
	var loadout_menu = menu.get_node("LoadoutMenu")
	var profile_menu = menu.get_node("ProfileMenu")

	assert_true(loadout_menu.profile_requested.is_connected(menu._open_profile))
	assert_true(profile_menu.loadout_requested.is_connected(menu._open_loadout))


func test_join_uses_placeholder_lobby_list_for_quick_join_level() -> void:
	var menu = add_child_autofree(MainMenuScene.instantiate())
	var lobby_list = menu.get_node("LobbyList")

	assert_true(menu.get_node("Join_Button").pressed.is_connected(menu._open_lobby_list))
	assert_true(lobby_list.join_requested.is_connected(menu._quick_join))
	assert_eq(lobby_list.PLACEHOLDER_SERVERS.size(), 3)
	for server in lobby_list.PLACEHOLDER_SERVERS:
		assert_eq(server.level, "Arena 01")


func test_close_game_button_is_connected() -> void:
	var menu = add_child_autofree(MainMenuScene.instantiate())

	assert_true(menu.get_node("Quit_Button").pressed.is_connected(menu._quit_game))
