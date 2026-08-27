extends GutTest

const LoadoutMenuScene = preload("res://src/scenes/ui/loadout_menu.tscn")

var _menu: Control


func before_each() -> void:
	_menu = add_child_autofree(LoadoutMenuScene.instantiate())
	_menu.open()


func test_only_implemented_categories_are_enabled() -> void:
	assert_false(_menu.get_node("Center/Panel/Margin/Layout/Content/CategoryBar/LeftCategories/Weapon").disabled)
	assert_false(_menu.get_node("Center/Panel/Margin/Layout/Content/CategoryBar/RightCategories/Gadget").disabled)
	assert_false(_menu.get_node("Center/Panel/Margin/Layout/Content/CategoryBar/RightCategories/Ultimate").disabled)
	assert_true(_menu.get_node("Center/Panel/Margin/Layout/Content/CategoryBar/LeftCategories/DamageType").disabled)
	assert_false(_menu.get_node("Center/Panel/Margin/Layout/Content/CategoryBar/LeftCategories/EffectType").disabled)
	assert_false(_menu.get_node("Center/Panel/Margin/Layout/Content/CategoryBar/RightCategories/Armor").disabled)
	assert_true(_menu.get_node("Center/Panel/Margin/Layout/Content/CategoryBar/RightCategories/Perk").disabled)


func test_weapon_category_lists_all_existing_weapons() -> void:
	var option_grid := _menu.get_node("Center/Panel/Margin/Layout/Content/Options/OptionsInner/OptionScroll/OptionGrid")

	assert_eq(option_grid.get_child_count(), 4)


func test_effect_category_lists_all_existing_effects_and_none() -> void:
	_menu._show_category(&"effect")
	var option_grid := _menu.get_node("Center/Panel/Margin/Layout/Content/Options/OptionsInner/OptionScroll/OptionGrid")

	assert_eq(option_grid.get_child_count(), 5)


func test_cancel_emits_without_changing_saved_selection() -> void:
	var state := get_node("/root/LoadoutState")
	var original_weapon: String = state.selected_weapon_id
	watch_signals(_menu)
	_menu._select_option("knife")

	_menu._cancel()

	assert_signal_emitted(_menu, "cancelled")
	assert_eq(state.selected_weapon_id, original_weapon)


func test_armor_category_button_sizes() -> void:
	_menu._show_category(&"armor")
	var option_grid := _menu.get_node("Center/Panel/Margin/Layout/Content/Options/OptionsInner/OptionScroll/OptionGrid")
	assert_eq(option_grid.get_child_count(), 4)
	for btn: Button in option_grid.get_children():
		assert_eq(btn.custom_minimum_size, Vector2(150, 148))
		assert_eq(btn.icon_alignment, HORIZONTAL_ALIGNMENT_CENTER)
		assert_eq(btn.vertical_icon_alignment, VERTICAL_ALIGNMENT_TOP)
