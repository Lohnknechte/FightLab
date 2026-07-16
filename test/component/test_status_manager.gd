extends GutTest
## Component tests for StatusManager
## (Assets/Scripts/Status_effects/status_manager.gd)
##
## The manager is wired with stub sprite children and a target double as its
## parent. _process is disabled and driven manually with fixed deltas so every
## test is deterministic.

const StatusManagerScript = preload("res://Assets/Scripts/Status_effects/status_manager.gd")
const TargetDouble = preload("res://test/helpers/target_double.gd")
const StubSprite = preload("res://test/helpers/stub_effect_sprite.gd")
const SpyEffect = preload("res://test/helpers/spy_effect.gd")

var _target
var _manager
var _sprites := {}


func before_each() -> void:
	_target = TargetDouble.new()
	_manager = StatusManagerScript.new()
	_sprites.clear()
	for sprite_name in [&"FreezeSprite", &"BurnSprite", &"PoisonSprite", &"ShockSprite"]:
		var sprite := StubSprite.new()
		sprite.name = sprite_name
		_manager.add_child(sprite)
		_sprites[sprite_name] = sprite
	_target.add_child(_manager)
	add_child_autofree(_target)
	_manager.set_process(false)


func _make_spy(effect_id := &"spy", duration := 2.0, max_stacks := 1) -> StatusEffect:
	return SpyEffect.new(effect_id, duration, max_stacks, 1.0, 0.0)


# --- _ready -----------------------------------------------------------------

func test_hides_sprites_on_ready() -> void:
	assert_false(_sprites[&"BurnSprite"].visible)
	assert_false(_sprites[&"PoisonSprite"].visible)
	assert_false(_sprites[&"ShockSprite"].visible)


# --- apply_effect -----------------------------------------------------------

func test_apply_adds_active_effect() -> void:
	_manager.apply_effect(_make_spy())
	assert_eq(_manager.active_effects.size(), 1)


func test_apply_calls_effect_apply_on_parent() -> void:
	var effect := _make_spy()
	_manager.apply_effect(effect)
	assert_eq(effect.apply_calls, 1)
	assert_eq(effect.last_target, _target)


func test_apply_ignored_when_target_dead() -> void:
	_target._is_dead = true
	var effect := _make_spy()
	_manager.apply_effect(effect)
	assert_eq(_manager.active_effects.size(), 0)
	assert_eq(effect.apply_calls, 0)


func test_reapply_keeps_one_instance() -> void:
	var effect := _make_spy(&"spy", 2.0, 3)
	_manager.apply_effect(effect)
	_manager.apply_effect(effect)
	assert_eq(_manager.active_effects.size(), 1)


func test_reapply_refreshes_duration() -> void:
	var effect := _make_spy(&"spy", 2.0)
	_manager.apply_effect(effect)
	_manager._process(1.5)

	_manager.apply_effect(effect)

	assert_eq(_manager.active_effects[0].time_left, 2.0)


func test_reapply_adds_stack() -> void:
	var effect := _make_spy(&"spy", 2.0, 3)
	_manager.apply_effect(effect)
	_manager.apply_effect(effect)
	assert_eq(_manager.active_effects[0].stacks, 2)


func test_stacks_capped_at_max() -> void:
	var effect := _make_spy(&"spy", 2.0, 2)
	_manager.apply_effect(effect)
	_manager.apply_effect(effect)
	_manager.apply_effect(effect)
	assert_eq(_manager.active_effects[0].stacks, 2)


func test_reapply_calls_apply_once() -> void:
	var effect := _make_spy(&"spy", 2.0, 3)
	_manager.apply_effect(effect)
	_manager.apply_effect(effect)
	assert_eq(effect.apply_calls, 1)


# --- _process / expiry ------------------------------------------------------

func test_process_ticks_effects() -> void:
	var effect := _make_spy()
	_manager.apply_effect(effect)

	_manager._process(0.25)

	assert_eq(effect.tick_calls, 1)
	assert_eq(effect.last_tick_delta, 0.25)
	assert_eq(effect.last_target, _target)


func test_expired_effect_is_removed() -> void:
	var effect := _make_spy(&"spy", 1.0)
	_manager.apply_effect(effect)

	_manager._process(0.6)
	_manager._process(0.6)

	assert_eq(_manager.active_effects.size(), 0)
	assert_eq(effect.remove_calls, 1)


func test_effect_survives_until_expiry() -> void:
	var effect := _make_spy(&"spy", 1.0)
	_manager.apply_effect(effect)

	_manager._process(0.5)

	assert_eq(_manager.active_effects.size(), 1)
	assert_eq(effect.remove_calls, 0)


# --- remove_effect / clear_effects -------------------------------------------

func test_remove_erases_and_notifies() -> void:
	var effect := _make_spy()
	_manager.apply_effect(effect)

	_manager.remove_effect(_manager.active_effects[0])

	assert_eq(_manager.active_effects.size(), 0)
	assert_eq(effect.remove_calls, 1)


func test_clear_removes_all_effects() -> void:
	var burn := _make_spy(&"burn")
	var poison := _make_spy(&"poison")
	_manager.apply_effect(burn)
	_manager.apply_effect(poison)

	_manager.clear_effects()

	assert_eq(_manager.active_effects.size(), 0)
	assert_eq(burn.remove_calls, 1)
	assert_eq(poison.remove_calls, 1)


# --- visuals ----------------------------------------------------------------

func test_burn_toggles_burn_sprite() -> void:
	_manager.apply_effect(_make_spy(&"burn"))
	assert_true(_sprites[&"BurnSprite"].visible)
	assert_eq(_sprites[&"BurnSprite"].played, [&"burn"])

	_manager.remove_effect(_manager.active_effects[0])
	assert_false(_sprites[&"BurnSprite"].visible)


func test_poison_toggles_poison_sprite() -> void:
	_manager.apply_effect(_make_spy(&"poison"))
	assert_true(_sprites[&"PoisonSprite"].visible)
	assert_eq(_sprites[&"PoisonSprite"].played, [&"poison"])

	_manager.remove_effect(_manager.active_effects[0])
	assert_false(_sprites[&"PoisonSprite"].visible)


func test_shock_toggles_shock_sprite() -> void:
	_manager.apply_effect(_make_spy(&"shock"))
	assert_true(_sprites[&"ShockSprite"].visible)
	assert_eq(_sprites[&"ShockSprite"].played, [&"shock"])

	_manager.remove_effect(_manager.active_effects[0])
	assert_false(_sprites[&"ShockSprite"].visible)
