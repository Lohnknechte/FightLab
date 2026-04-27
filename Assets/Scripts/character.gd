extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -500.0
@export var acceleration: float = 15.0
@export var friction: float = 12.0

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _sprite: Sprite2D

func _ready() -> void:
	_sprite = $Sprite

func _physics_process(delta: float) -> void:
	var vel: Vector2 = velocity

	if not is_on_floor():
		vel.y += _gravity * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		vel.y = jump_velocity

	if Input.is_action_just_released("ui_up") and vel.y < 0.0:
		vel.y *= 0.5wwww

	var direction: float = Input.get_axis("ui_left", "ui_right")

	if direction != 0.0:
		vel.x = move_toward(vel.x, direction * speed, acceleration * speed * delta)
		_sprite.flip_h = direction < 0.0
	else:
		vel.x = move_toward(vel.x, 0.0, friction * speed * delta)

	velocity = vel
	move_and_slide()
