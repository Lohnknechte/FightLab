extends GutTest
## Unit tests for ActiveEffect (Assets/Scripts/Status_effects/active_effects.gd)

const SpyEffect = preload("res://test/helpers/spy_effect.gd")


func test_init_from_effect() -> void:
	var effect := SpyEffect.new(&"spy", 5.0, 1, 0.25, 0.0)
	var active := ActiveEffect.new(effect)
	assert_eq(active.effect, effect)
	assert_eq(active.time_left, 5.0)
	assert_eq(active.tick_timer, 0.25)
	assert_eq(active.stacks, 1)
