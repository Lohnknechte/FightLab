extends Node2D

const MAIN_MENU_SCENE := "res://Main_Menu.tscn"


func _ready() -> void:
	for point in $SpawnPoints.get_children():
		point.add_to_group("SpawnPoints")
	var player := $TileMapLayer/CharacterBody2D 
	$DeathZone.body_entered.connect(_on_death_zone_entered)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("return_to_menu") and not event.is_echo():
		get_viewport().set_input_as_handled()
		var error := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		if error != OK:
			push_error("Could not return to the main menu: %s" % error_string(error))


func _on_death_zone_entered(body: Node2D) -> void:
	if body.has_method("die") and not body.get("_is_dead"):
		body.die()
