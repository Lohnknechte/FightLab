extends CharacterBody2D
 
@export var speed: float = 200.0
@export var jump_velocity: float = -500.0
@export var acceleration: float = 15.0
@export var friction: float = 12.0
@export var bounce_impulse: float = 16.0

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _sprite: AnimatedSprite2D 
var originalPosX : float 

var facing_left : bool

func _ready() -> void:
	_sprite = $AnimatedSprite2D 

func _physics_process(delta: float) -> void:
	var vel: Vector2 = velocity 
	 
	if not is_on_floor():
		vel.y += _gravity * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		vel.y = jump_velocity

	if Input.is_action_just_released("ui_up") and vel.y < 0.0:
		vel.y *= 0.5

	var direction: float = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0.0:
		vel.x = move_toward(vel.x, direction * speed, acceleration * speed * delta)
		
		facing_left = direction < 0.0  
		_sprite.flip_h = facing_left
		_sprite.play("walk")
	else:
		vel.x = move_toward(vel.x, 0.0, friction * speed * delta)
		_sprite.play("idle")

	velocity = vel
	move_and_slide()
	
	$HeadHitDetector.force_raycast_update()
	if $HeadHitDetector.is_colliding():
		var collider = $HeadHitDetector.get_collider()
		# Check if the collider is the destructible object and the player is moving upward
		if collider.is_in_group("Destructibles") and velocity.y < 0:
			collider.detonate() # Trigger the explosion
			# Apply a bounce to the player
			velocity.y = bounce_impulse # e.g., 300
