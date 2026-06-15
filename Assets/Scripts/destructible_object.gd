extends RigidBody2D

@export var blocks_per_side: int = 6
@export var blocks_impulse: float = 600
@export var debris_max_time: float = 5.0
@export var remove_debris: bool = false
@export var collision_layers: int = 1
@export var collision_masks: int = 1
@export var respawn_delay: float = 3.0

const BOX_BREAK_STREAM: AudioStream = preload("res://audio/sfx/environment/box_break_01.wav")

var sprite_texture: Texture2D
var sprite_size: Vector2

func _ready():
	add_to_group("Destructibles")
	var sprite = $Sprite2D
	if sprite and sprite.texture:
		sprite_texture = sprite.texture
		sprite_size = sprite.texture.get_size()
	else:
		print("No valid sprite found.")
		return

func detonate():
	var original_position = position
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(BOX_BREAK_STREAM, global_position, -26.0, 0.92, 1.04)
	$CollisionShape2D.disabled = true
	visible = false
	set_process(false)
	set_physics_process(false)

	var block_width = sprite_size.x / blocks_per_side
	var block_height = sprite_size.y / blocks_per_side

	for x in range(blocks_per_side):
		for y in range(blocks_per_side):
			create_debris_block(Vector2(x * block_width, y * block_height), block_width, block_height)

	var timer = Timer.new()
	timer.wait_time = respawn_delay
	timer.one_shot = true
	timer.timeout.connect(func():
		position = original_position
		$CollisionShape2D.disabled = false
		visible = true
		set_process(true)
		set_physics_process(true)
	)
	add_child(timer)
	timer.start()

func create_debris_block(offset: Vector2, width: float, height: float):
	var piece = Node2D.new()
	
	var sprite = Sprite2D.new()
	sprite.texture = sprite_texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(offset, Vector2(width, height))
	piece.add_child(sprite)
	
	get_parent().add_child(piece)
	piece.global_position = global_position
	
	var piece_center_offset = offset + Vector2(width/2, height/2)
	var direction = (piece_center_offset - Vector2(sprite_size.x/2, sprite_size.y/2)).normalized()
	var velocity = direction * randf_range(100, 300)
	
	var timer = Timer.new()
	timer.wait_time = 0.016
	timer.one_shot = false
	timer.connect("timeout", Callable(func():
		velocity.y += 500 * 0.016
		piece.global_position += velocity * 0.016
	))
	piece.add_child(timer)
	timer.start()
	
	get_tree().create_timer(0.2).timeout.connect(Callable(func(): piece.queue_free()))   
