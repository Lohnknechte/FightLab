extends GutTest
## Integration test: player damage reaches the HUD health bar through
## connect_to_player and the health_changed signal.

const HudScene = preload("res://src/scenes/hud.tscn")

var CharacterScript = load("res://Assets/Scripts/character.gd")


func test_player_damage_updates_health_bar() -> void:
	var hud = HudScene.instantiate()
	add_child_autofree(hud)
	var player = autofree(partial_double(CharacterScript).new())
	stub(player.die).to_do_nothing()
	player.max_health = 100
	player.current_health = 100
	hud.connect_to_player(player)

	player.take_damage(35)

	assert_eq(hud.health_bar.value, 65.0)
