extends RigidBody2D

@export var blocks_per_side: int = 6
@export var blocks_impulse: float = 600
@export var debris_max_time: float = 5.0
@export var remove_debris: bool = false
@export var collision_layers: int = 1
@export var collision_masks: int = 1
@export var respawn_delay: float = 3.0 # Time in seconds before respawn
var sprite_texture: Texture2D
var sprite_size: Vector2

func _ready():
	add_to_group("Destructibles")
	# Get texture and size from child Sprite2D
	var sprite = $Sprite2D
	if sprite and sprite.texture:
		sprite_texture = sprite.texture
		sprite_size = sprite.texture.get_size()
	else:
		print("No valid sprite found.")
		return

func detonate():
	var block_width = sprite_size.x / blocks_per_side
	var block_height = sprite_size.y / blocks_per_side
	var original_position = position
	var original_scene = get_parent().get_path() # Where to respawn
	
	for x in range(blocks_per_side):
		for y in range(blocks_per_side):
			create_debris_block(Vector2(x * block_width, y * block_height), block_width, block_height)
	
	# Disable and explode the current block
	set_process(false)
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	visible = false # Hide the original block
	
	# Create the explosion chunks (your existing code)
	# ... (create_debris_block calls)
	
	# Set up a timer to respawn
	var timer = Timer.new()
	timer.wait_time = respawn_delay
	timer.one_shot = true
	timer.timeout.connect(func():
		# Re-enable the original block
		position = original_position
		set_process(true)
		set_physics_process(true)
		$CollisionShape2D.disabled = false
		visible = true
	)
	add_child(timer)
	timer.start()

func create_debris_block(offset: Vector2, width: float, height: float):
	var block = RigidBody2D.new()
	
	# Create Sprite for the block
	var block_sprite = Sprite2D.new()
	block_sprite.texture = sprite_texture
	block_sprite.region_enabled = true
	block_sprite.region_rect = Rect2(offset, Vector2(width, height))
	block.add_child(block_sprite)
	
	# Create Collision
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.extents = Vector2(width / 2, height / 2)
	block.add_child(collision)
	
	# Physics settings
	block.collision_layer = collision_layers
	block.collision_mask = collision_masks
	block.mode = RigidBody2D.MODE_STATIC # Remove physics interaction
	block.$CollisionShape2D.disabled = true

	# Add to scene FIRST
	get_parent().add_child(block)
	
	# THEN set the correct world position
	block.position = position + offset + Vector2(width/2, height/2)
	
	# Apply impulse
	block.apply_impulse(Vector2.ZERO, Vector2(randf_range(-1, 1), randf_range(-1, 1)) * blocks_impulse)
	
	# Despawn timer
	var timer = Timer.new()
	timer.wait_time = 2.0 # Despawn after 2 seconds
	timer.one_shot = true
	timer.timeout.connect(func(): block.queue_free())
	block.add_child(timer)
	timer.start()   
