extends GutTest
## Unit tests for BurnEffect (Assets/Scripts/Status_effects/burn_effect.gd)

const TargetDouble = preload("res://test/helpers/target_double.gd")

var _target


func before_each() -> void:
	_target = TargetDouble.new()
	# BurnEffect.tick() -> spread() expects a BurnArea child on the target.
	var burn_area := Area2D.new()
	burn_area.name = "BurnArea"
	_target.add_child(burn_area)
	add_child_autofree(_target)


func _make_burn(tick_rate := 1.0, damage_per_tick := 2.0) -> BurnEffect:
	var effect := BurnEffect.new()
	effect.id = &"burn"
	effect.duration = 3.0
	effect.tick_rate = tick_rate
	effect.damage_per_tick = damage_per_tick
	return effect


func test_apply_raises_speed_ten_percent() -> void:
	_make_burn().apply(_target)
	assert_almost_eq(_target.speed_multiplier, 1.1, 0.0001)


func test_no_damage_before_tick_rate() -> void:
	var effect := _make_burn()
	var active := ActiveEffect.new(effect)

	effect.tick(_target, 0.4, active)

	assert_eq(_target.damage_calls.size(), 0)


func test_damages_after_tick_rate() -> void:
	var effect := _make_burn(1.0, 2.0)
	var active := ActiveEffect.new(effect)

	effect.tick(_target, 0.6, active)
	effect.tick(_target, 0.5, active)

	assert_eq(_target.damage_calls, [2.0])


func test_damage_at_exact_tick_rate() -> void:
	var effect := _make_burn(0.5, 1.0)
	var active := ActiveEffect.new(effect)

	effect.tick(_target, 0.5, active)

	assert_eq(_target.damage_calls.size(), 1)


func test_timer_resets_after_damage() -> void:
	var effect := _make_burn(1.0)
	var active := ActiveEffect.new(effect)

	effect.tick(_target, 1.0, active)

	assert_eq(active.tick_timer, 1.0)


func test_remove_restores_speed() -> void:
	var effect := _make_burn()
	effect.apply(_target)
	effect.remove(_target)
	# remove() multiplies by 0.90909 rather than dividing by 1.1,
	# so restoration is approximate, not exact.
	assert_almost_eq(_target.speed_multiplier, 1.0, 0.001)
