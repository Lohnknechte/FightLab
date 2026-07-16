extends GutTest
## Unit tests for PoisonEffect (Assets/Scripts/Status_effects/poison_effect.gd)

const TargetDouble = preload("res://test/helpers/target_double.gd")

var _target


func before_each() -> void:
	_target = TargetDouble.new()
	add_child_autofree(_target)


func _make_poison(tick_rate := 1.0, damage_per_tick := 3.0) -> PoisonEffect:
	var effect := PoisonEffect.new()
	effect.id = &"poison"
	effect.duration = 4.0
	effect.tick_rate = tick_rate
	effect.damage_per_tick = damage_per_tick
	return effect


func test_no_damage_before_tick_rate() -> void:
	var effect := _make_poison()
	var active := ActiveEffect.new(effect)

	effect.tick(_target, 0.9, active)

	assert_eq(_target.damage_calls.size(), 0)


func test_damage_equals_damage_per_tick() -> void:
	var effect := _make_poison(1.0, 3.0)
	var active := ActiveEffect.new(effect)

	effect.tick(_target, 1.0, active)

	assert_eq(_target.damage_calls, [3.0])


func test_damage_scales_with_stacks() -> void:
	var effect := _make_poison(1.0, 3.0)
	var active := ActiveEffect.new(effect)
	active.stacks = 3

	effect.tick(_target, 1.0, active)

	assert_eq(_target.damage_calls, [9.0])


func test_timer_resets_after_damage() -> void:
	var effect := _make_poison(0.5)
	var active := ActiveEffect.new(effect)

	effect.tick(_target, 0.5, active)

	assert_eq(active.tick_timer, 0.5)
