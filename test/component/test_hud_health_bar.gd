extends GutTest
## Component tests for the health/ghost bars in hud.gd, using the real
## hud.tscn scene.

const HudScene = preload("res://src/scenes/hud.tscn")

var _hud


func before_each() -> void:
	_hud = HudScene.instantiate()
	add_child_autofree(_hud)


func test_health_change_syncs_bars() -> void:
	_hud._on_health_changed(70, 200)
	assert_eq(_hud.health_bar.value, 70.0)
	assert_eq(_hud.health_bar.max_value, 200.0)
	assert_eq(_hud.ghost_bar.max_value, 200.0)


func test_ghost_snaps_up_on_heal() -> void:
	_hud.ghost_bar.value = 30
	_hud._on_health_changed(80, 100)
	assert_eq(_hud.ghost_bar.value, 80.0)


func test_ghost_lags_then_catches_up_on_damage() -> void:
	_hud.ghost_bar.max_value = 100
	_hud.ghost_bar.value = 100

	_hud._on_health_changed(40, 100)

	assert_eq(_hud.ghost_bar.value, 100.0, "ghost holds the old value first")
	await wait_seconds(0.7)
	assert_eq(_hud.ghost_bar.value, 40.0, "ghost drains to the new value")


func test_negative_health_clamps_to_zero() -> void:
	_hud._on_health_changed(-10, 100)
	assert_eq(_hud.health_bar.value, 0.0)


func test_health_above_max_clamps_to_max() -> void:
	_hud._on_health_changed(150, 100)
	assert_eq(_hud.health_bar.value, 100.0)
