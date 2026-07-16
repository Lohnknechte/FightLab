extends Node2D

func _ready() -> void:
	for point in $SpawnPoints.get_children():
		point.add_to_group("SpawnPoints")
	var player := $TileMapLayer/CharacterBody2D 
	$DeathZone.body_entered.connect(_on_death_zone_entered)

func _on_death_zone_entered(body: Node2D) -> void:
	if body.has_method("die") and not body.get("_is_dead"):
		body.die()
