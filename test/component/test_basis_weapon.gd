extends GutTest
## Component tests for the shotgun (basis_weapon.gd + BasisWeapon.tscn):
## ammo, reload and the fire guards. Uses a short reload_time so the real
## await-based reload finishes fast.

const WeaponScene = preload("res://src/scenes/BasisWeapon.tscn")

var _weapon


func before_each() -> void:
	_weapon = WeaponScene.instantiate()
	add_child_autofree(_weapon)
	_weapon.reload_time = 0.1


func _free_spawned_pellets(child_count_before: int) -> void:
	var root := get_tree().root
	while root.get_child_count() > child_count_before:
		var pellet := root.get_child(root.get_child_count() - 1)
		root.remove_child(pellet)
		pellet.free()


func test_shoot_consumes_ammo() -> void:
	_weapon.current_ammo = 2
	var before := get_tree().root.get_child_count()

	_weapon.shoot()

	assert_eq(_weapon.current_ammo, 1)
	_free_spawned_pellets(before)


func test_shoot_blocked_while_reloading() -> void:
	_weapon.is_reloading = true
	_weapon.current_ammo = 3

	_weapon.shoot()

	assert_eq(_weapon.current_ammo, 3)
	_weapon.is_reloading = false


func test_shoot_blocked_when_empty() -> void:
	_weapon.current_ammo = 0
	var before := get_tree().root.get_child_count()

	_weapon.shoot()

	assert_eq(get_tree().root.get_child_count(), before, "no pellets spawned")


func test_last_shot_auto_reloads() -> void:
	_weapon.current_ammo = 1
	var before := get_tree().root.get_child_count()

	_weapon.shoot()

	assert_true(_weapon.is_reloading)
	_free_spawned_pellets(before)
	await wait_seconds(0.3)  # let the reload coroutine finish before teardown


func test_reload_refills_magazine() -> void:
	_weapon.current_ammo = 2

	_weapon.reload()

	assert_true(_weapon.is_reloading)
	await wait_seconds(0.3)
	assert_eq(_weapon.current_ammo, _weapon.magazine_size)
	assert_false(_weapon.is_reloading)


func test_reload_ignored_when_full() -> void:
	_weapon.current_ammo = _weapon.magazine_size
	_weapon.reload()
	assert_false(_weapon.is_reloading)


func test_hud_progress_with_zero_reload_time() -> void:
	_weapon.reload_time = 0.0
	assert_eq(_weapon.get_hud_state()["bar_progress"], 0.0)
