extends GutTest

const PlayerScene = preload("res://src/scenes/player.tscn")

var _state: Node
var _original_weapon: String
var _original_ultimate: String
var _original_gadget: String
var _original_effect: String


func before_all() -> void:
	_state = get_node("/root/LoadoutState")
	_original_weapon = _state.selected_weapon_id
	_original_ultimate = _state.selected_ultimate_id
	_original_gadget = _state.selected_gadget_id
	_original_effect = _state.selected_effect_id
	_state.selected_weapon_id = "sniper"
	_state.selected_ultimate_id = "avada"
	_state.selected_gadget_id = "dash"
	_state.selected_effect_id = "freeze"


func after_all() -> void:
	_state.selected_weapon_id = _original_weapon
	_state.selected_ultimate_id = _original_ultimate
	_state.selected_gadget_id = _original_gadget
	_state.selected_effect_id = _original_effect


func test_every_player_uses_the_confirmed_loadout_on_spawn() -> void:
	var player_one = add_child_autofree(PlayerScene.instantiate())
	var player_two = add_child_autofree(PlayerScene.instantiate())

	assert_eq(player_one._active_weapon, player_one.get_node("SniperWeapon"))
	assert_eq(player_two._active_weapon, player_two.get_node("SniperWeapon"))
	assert_eq(player_one.get_node("UltimateManager").current_index, 0)
	assert_eq(player_one.get_node("GadgetManager").current_index, 0)
	assert_eq(player_one.equipped_effect.id, &"freeze")
	assert_eq(player_two.equipped_effect.id, &"freeze")
	assert_eq(player_one._active_weapon.attack_effect, player_one.equipped_effect)
	assert_true(player_one.get_node("HUD/WeaponModule").visible)

	_state.selected_effect_id = "none"
	var player_without_effect = add_child_autofree(PlayerScene.instantiate())
	assert_null(player_without_effect.equipped_effect)
	assert_null(player_without_effect._active_weapon.attack_effect)
