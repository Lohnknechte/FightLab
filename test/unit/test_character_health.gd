extends GutTest
## Unit tests for the health rules in character.gd.
##
## Uses a partial double so die() can be stubbed out — the real die() needs
## the full character scene ($StatusManager, sprite, weapons).

var CharacterScript = load("res://Assets/Scripts/character.gd")

var _player


func before_each() -> void:
	_player = autofree(partial_double(CharacterScript).new())
	stub(_player.die).to_do_nothing()
	_player.max_health = 100
	_player.current_health = 100
	watch_signals(_player)


func test_damage_reduces_health() -> void:
	_player.take_damage(30)
	assert_eq(_player.current_health, 70)


func test_damage_emits_health_changed() -> void:
	_player.take_damage(30)
	assert_signal_emitted_with_parameters(_player, "health_changed", [70, 100])


func test_health_clamps_at_zero() -> void:
	_player.take_damage(250)
	assert_eq(_player.current_health, 0)


func test_dies_at_zero_health() -> void:
	_player.take_damage(100)
	assert_called(_player.die)


func test_no_damage_when_dead() -> void:
	_player._is_dead = true
	_player.take_damage(30)
	assert_eq(_player.current_health, 100)
	assert_signal_not_emitted(_player, "health_changed")


func test_no_damage_when_invulnerable() -> void:
	_player._invulnerable = true
	_player.take_damage(30)
	assert_eq(_player.current_health, 100)


func test_negative_damage_clamps_at_max() -> void:
	_player.current_health = 90
	_player.take_damage(-50)
	assert_eq(_player.current_health, 100)
