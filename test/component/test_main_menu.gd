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
