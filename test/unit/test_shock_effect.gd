extends GutTest
## Unit tests for ShockEffect (Assets/Scripts/Status_effects/shock_effect.gd)

const TargetDouble = preload("res://test/helpers/target_double.gd")

var _target
var _weapon_a: Node2D
var _weapon_b: Node2D


func before_each() -> void:
	_target = TargetDouble.new()
	_weapon_a = autofree(Node2D.new())
	_weapon_b = autofree(Node2D.new())
	_weapon_a.set_process_input(true)
	_weapon_b.set_process_input(true)
	var weapons: Array[Node2D] = [_weapon_a, _weapon_b]
	_target._weapons = weapons
	_target._shotgun = _weapon_a
	add_child_autofree(_target)


func _make_shock() -> ShockEffect:
	var effect := ShockEffect.new()
	effect.id = &"shock"
	effect.duration = 1.5
	return effect


func test_apply_blocks_movement() -> void:
	_make_shock().apply(_target)
	assert_false(_target.can_move)


func test_apply_disables_weapon_input() -> void:
	_make_shock().apply(_target)
	assert_false(_weapon_a.is_processing_input())
	assert_false(_weapon_b.is_processing_input())


func test_remove_restores_movement() -> void:
	var effect := _make_shock()
	effect.apply(_target)
	effect.remove(_target)
	assert_true(_target.can_move)


func test_remove_reactivates_active_weapon() -> void:
	_target._active_weapon = _weapon_b
	var effect := _make_shock()
	effect.apply(_target)

	effect.remove(_target)

	assert_eq(_target.set_active_weapon_calls, [_weapon_b])


func test_remove_falls_back_to_shotgun() -> void:
	_target._active_weapon = null
	var effect := _make_shock()
	effect.apply(_target)

	effect.remove(_target)

	assert_eq(_target.set_active_weapon_calls, [_weapon_a])
