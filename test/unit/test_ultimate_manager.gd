extends GutTest
## Unit tests for ultimate_manager.gd (charge, cast gate, one-cast-per-round).
##
## The manager is driven by calling _process with fixed deltas. The full cast
## (scene spawning) needs a scene tree and belongs to an integration test.

const UltimateManagerScript = preload("res://Assets/Scripts/ultimate_manager.gd")

var _manager
var _data: Ultimate_Data


func before_each() -> void:
	_manager = autofree(UltimateManagerScript.new())
	_data = Ultimate_Data.new()
	_data.charge_rate = 10.0
	_data.maxCharge = 100.0
	var ults: Array[Ultimate_Data] = [_data]
	_manager.ultimates = ults
	watch_signals(_manager)


func test_charge_accumulates() -> void:
	_manager._process(1.0)
	assert_eq(_manager.charge, 10.0)
	assert_signal_emitted_with_parameters(_manager, "charge_updated", [10.0, 100.0])


func test_charge_caps_at_max() -> void:
	_manager._process(20.0)
	assert_eq(_manager.charge, 100.0)


func test_no_charge_without_ultimates() -> void:
	var empty: Array[Ultimate_Data] = []
	_manager.ultimates = empty

	_manager._process(1.0)

	assert_eq(_manager.charge, 0.0)
	assert_signal_not_emitted(_manager, "charge_updated")


func test_cast_denied_below_max() -> void:
	_manager.charge = 50.0

	_manager.cast_ultimate()

	assert_eq(_manager.charge, 50.0)
	assert_false(_manager.has_cast)


func test_no_recharge_after_cast() -> void:
	_manager.has_cast = true
	_manager.charge = 50.0

	_manager._process(1.0)

	assert_eq(_manager.charge, 0.0)


func test_reset_allows_recharge() -> void:
	_manager.has_cast = true

	_manager.reset_for_new_round()
	_manager._process(1.0)

	assert_false(_manager.has_cast)
	assert_eq(_manager.charge, 10.0)
