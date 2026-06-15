extends Node2D


const BULLET_SCENE = preload("res://src/scenes/Bullet.tscn")
const SHOTGUN_FIRE_STREAM = preload("res://audio/sfx/weapons/shotgun/shotgun_fire_01.wav")
const SHOTGUN_PUMP_STREAM = preload("res://audio/sfx/weapons/shotgun/shotgun_pump_01.wav")
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

func shoot() -> void:
	var bullet_count = randf_range(4,7)
	var spread_angle = 0.3 # Radians

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(SHOTGUN_FIRE_STREAM, muzzle.global_position, -3.0, 0.98, 1.02)
	_play_pump_sound()
	
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


func _play_pump_sound() -> void:
	await get_tree().create_timer(0.10).timeout
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(SHOTGUN_PUMP_STREAM, muzzle.global_position, -10.0, 0.96, 1.0)
