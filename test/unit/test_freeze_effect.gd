extends GutTest
## Unit tests for FreezeEffect (Assets/Scripts/Status_effects/freeze_effect.gd)
## Note: FreezeEffect reuses damage_per_tick as the slow-down multiplier.

const TargetDouble = preload("res://test/helpers/target_double.gd")

var _target


func before_each() -> void:
	_target = TargetDouble.new()
	add_child_autofree(_target)


func _make_freeze(slow_factor := 0.5) -> FreezeEffect:
	var effect := FreezeEffect.new()
	effect.id = &"freeze"
	effect.duration = 2.0
	effect.damage_per_tick = slow_factor
	return effect


func test_apply_slows_target() -> void:
	_make_freeze(0.5).apply(_target)
	assert_almost_eq(_target.speed_multiplier, 0.5, 0.0001)


func test_apply_marks_target() -> void:
	_make_freeze().apply(_target)
	assert_eq(_target.has_effect, &"freeze")


func test_remove_restores_speed() -> void:
	var effect := _make_freeze(0.5)
	effect.apply(_target)
	effect.remove(_target)
	assert_almost_eq(_target.speed_multiplier, 1.0, 0.0001)


func test_remove_clears_marker() -> void:
	var effect := _make_freeze()
	effect.apply(_target)
	effect.remove(_target)
	assert_eq(_target.has_effect, &"none")
