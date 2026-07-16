extends GutTest
## Unit tests for the gadget rules in character.gd (charge, use, weighted dice).
##
## Partial double: die() and _spawn_vfx() are stubbed because they need the
## full scene/tree; everything else runs real production code.

var CharacterScript = load("res://Assets/Scripts/character.gd")

var _player


func before_each() -> void:
	_player = autofree(partial_double(CharacterScript).new())
	stub(_player.die).to_do_nothing()
	stub(_player._spawn_vfx).to_do_nothing()
	_player.gadget_max_charge = 100
	_player.gadget_charge_rate = 8.0
	watch_signals(_player)


func test_charge_accumulates() -> void:
	_player._update_gadget_charge(1.0)
	assert_eq(_player.gadget_charge, 8)
	assert_signal_emitted_with_parameters(_player, "gadget_charge_changed", [8, 100])


func test_charge_caps_at_max() -> void:
	_player._update_gadget_charge(50.0)
	assert_eq(_player.gadget_charge, 100)


func test_use_denied_when_not_charged() -> void:
	_player.gadget_charge = 50

	_player._try_use_gadget()

	assert_signal_emitted(_player, "gadget_use_denied")
	assert_signal_not_emitted(_player, "gadget_used")
	assert_eq(_player.gadget_charge, 50)


func test_use_resets_charge() -> void:
	_player.current_gadget = _player.GADGET_DASH
	_player.gadget_charge = 100

	_player._try_use_gadget()

	assert_signal_emitted(_player, "gadget_used")
	assert_eq(_player.gadget_charge, 0)


func test_weighted_dice_always_valid() -> void:
	for i in 200:
		var idx: int = _player._weighted_dice()
		if idx < 0 or idx >= _player.DICE_OUTCOMES.size():
			fail_test("roll %d returned invalid index %d" % [i, idx])
			return
	pass_test("200 rolls all landed on a valid outcome")


func test_dice_rolls_once_per_charge() -> void:
	_player.gadget_charge = 100

	_player._select_gadget(_player.GADGET_DICE)
	_player._select_gadget(_player.GADGET_AIRSTRIKE)
	_player._select_gadget(_player.GADGET_DICE)

	assert_signal_emit_count(_player, "dice_rolled", 1)
