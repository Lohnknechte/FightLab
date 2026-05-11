extends Node2D


const BULLET_SCENE = preload("res://src/scenes/Bullet.tscn")
@onready var muzzle = $Muzzle 
var _sprite: Sprite2D
const CHARACTER_SCENE = preload("res://src/scenes/player.tscn")

var originalPosX : float
var originalPosY : float

func _ready() -> void:
	_sprite = $Sprite
	

func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	
	$Sprite.flip_v = to_mouse.x < 0
	
	look_at(mouse_pos)
	
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT :
			shoot()

func shoot():
	var bullet_count = randf_range(4,7)
	var spread_angle = 0.3 # Radians
	
	for i in range(bullet_count):
		var bullet = BULLET_SCENE.instantiate()
		
		# Set bullet position to muzzle
		bullet.global_position = muzzle.global_position
		
		# Calculate angle variation
		var rotation_offset = (i - (bullet_count - 1) / 2.0) * randf_range(-spread_angle, spread_angle)
		
		# Set direction based on player rotation + spread
		bullet.rotation = global_rotation + rotation_offset
		
		# Spawn bullet
		get_tree().root.add_child(bullet)
