class_name AirstrikeBomb
extends Node2D

## A single bomb dropped by the Airstrike gadget. It falls from above and
## detonates on reaching its target height, dealing area damage to players
## and destroying any destructibles caught in the blast radius.

const BOMB_TEXTURE: Texture2D = preload("res://Assets/Sprites/weapons/ammo/shotgun/shell_full.png")

@export var fall_speed: float = 700.0
@export var damage: int = 35
@export var blast_radius: float = 46.0

var target_y: float = 0.0
var source: Node = null

var _exploded: bool = false


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = BOMB_TEXTURE
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	position.y += fall_speed * delta
	rotation += delta * 6.0
	if global_position.y >= target_y:
		_explode()


func _explode() -> void:
	_exploded = true

	var scene := get_tree().current_scene
	if scene:
		var v := VfxBurst.new()
		v.setup(Color(1.0, 0.55, 0.15), blast_radius * 1.7, 0.4)
		scene.add_child(v)
		v.global_position = global_position

	for player in get_tree().get_nodes_in_group("Players"):
		if not is_instance_valid(player):
			continue
		if global_position.distance_to(player.global_position) <= blast_radius:
			if player.has_method("take_damage"):
				player.take_damage(damage)

	for obj in get_tree().get_nodes_in_group("Destructibles"):
		if not is_instance_valid(obj):
			continue
		if global_position.distance_to(obj.global_position) <= blast_radius:
			if obj.has_method("detonate"):
				obj.detonate()

	queue_free()
