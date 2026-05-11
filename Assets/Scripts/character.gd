extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -500.0
@export var acceleration: float = 15.0
@export var friction: float = 12.0
@export var bounce_impulse: float = 16.0

@export var max_health: int = 100
var current_health: int

signal health_changed(new_health: int, max_health: int)

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _sprite: AnimatedSprite2D
var _weaponSprite: Sprite2D
var _weaponPivot: Node2D

var facing_left: bool
var _is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	_sprite = $AnimatedSprite2D
	_weaponSprite = $WeaponPivot/Sprite
	_weaponPivot = $WeaponPivot

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

	else:
		vel.x = move_toward(vel.x, 0.0, friction * speed * delta)

	velocity = vel
	move_and_slide()
	
	$HeadHitDetector.force_raycast_update()
	if $HeadHitDetector.is_colliding():
		var collider = $HeadHitDetector.get_collider()
		# Check if the collider is the destructible object and the player is moving upward
		if collider.is_in_group("Destructibles") and velocity.y < 0:
			collider.detonate()
			velocity.y = bounce_impulse

func take_damage(amount: int) -> void:
	if _is_dead:
		return
	current_health = clamp(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		die()

func die() -> void:
	_is_dead = true
	set_physics_process(false)
	_sprite.visible = false
	_weaponPivot.visible = false
	await get_tree().create_timer(3.0).timeout
	_respawn()

func _respawn() -> void:
	var points := get_tree().get_nodes_in_group("SpawnPoints")
	if points.size() > 0:
		global_position = points[randi() % points.size()].global_position
	current_health = max_health
	health_changed.emit(current_health, max_health)
	velocity = Vector2.ZERO
	set_physics_process(true)
	await get_tree().physics_frame
	_sprite.visible = true
	_weaponPivot.visible = true
	_is_dead = false
