class_name BaseLevel
extends Node2D
## Shared lifecycle for every playable arena.
##
## Levels differ in how their geometry comes to be - hand placed in the editor or
## generated at runtime - but they all publish spawn points to the characters and
## kill anything that falls out of the arena. Both live here so a new level only
## has to fill in [method _prepare_level].

## Group the characters query in [code]character.gd[/code] when respawning.
const SPAWN_POINT_GROUP := &"SpawnPoints"

## Scene the "return_to_menu" action leaves a match for.
const MAIN_MENU_SCENE := "res://Main_Menu.tscn"

## Node holding the [Marker2D] spawn points.
@export var spawn_points_path: NodePath = ^"SpawnPoints"

## Area that kills whatever falls into it.
@export var death_zone_path: NodePath = ^"DeathZone"


func _ready() -> void:
	_prepare_level()
	_register_spawn_points()
	_connect_death_zone()
	_assign_local_player()


## Leaving a match works the same way from every arena, so it lives here rather
## than in one level's script.
## [b]Note:[/b] a level that overrides this must call [code]super[/code], or
## returning to the menu stops working in that level alone.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("return_to_menu") and not event.is_echo():
		get_viewport().set_input_as_handled()
		var error := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		if error != OK:
			push_error("Could not return to the main menu: %s" % error_string(error))


## Hook for levels that have to build their geometry before spawn points are
## published. The base implementation does nothing.
func _prepare_level() -> void:
	pass


## Replaces the spawn markers with one [Marker2D] per entry of [param positions].
## Used by generated levels, which only know where players fit once the layout
## exists.
func set_spawn_positions(positions: Array[Vector2]) -> void:
	var container := get_node_or_null(spawn_points_path)
	if container == null:
		push_warning("BaseLevel: no spawn point container at '%s'." % spawn_points_path)
		return

	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	for index in positions.size():
		var marker := Marker2D.new()
		marker.name = "SpawnPoint%d" % (index + 1)
		marker.global_position = positions[index]
		container.add_child(marker)
		marker.add_to_group(SPAWN_POINT_GROUP)


## Moves every character in the level onto a spawn point, cycling if there are
## more characters than points.
func place_characters_on_spawn_points() -> void:
	var markers := get_tree().get_nodes_in_group(SPAWN_POINT_GROUP)
	if markers.is_empty():
		return
	var index := 0
	for child in get_children():
		if not child is CharacterBody2D:
			continue
		child.global_position = (markers[index % markers.size()] as Node2D).global_position
		index += 1


func _register_spawn_points() -> void:
	var container := get_node_or_null(spawn_points_path)
	if container == null:
		return
	for point in container.get_children():
		point.add_to_group(SPAWN_POINT_GROUP)


func _connect_death_zone() -> void:
	var death_zone := get_node_or_null(death_zone_path) as Area2D
	if death_zone == null:
		return
	if not death_zone.body_entered.is_connected(_on_death_zone_body_entered):
		death_zone.body_entered.connect(_on_death_zone_body_entered)


func _on_death_zone_body_entered(body: Node2D) -> void:
	if body.has_method("die") and not body.get("_is_dead"):
		body.die()


## Marks the first character in the scene as the one the local player sees
## and controls; every other character stops reacting to input until
## something else drives it (AI, or eventually a remote peer). This is a
## placeholder for real multiplayer authority: once networking exists,
## replace the spawn-order check below with each character's
## [code]is_multiplayer_authority()[/code].
func _assign_local_player() -> void:
	var assigned := false
	for child in get_children():
		if child is CharacterBody2D and child.has_method("set_is_local_player"):
			child.set_is_local_player(not assigned)
			assigned = true
