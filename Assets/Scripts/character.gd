extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -500.0
@export var acceleration: float = 15.0
@export var friction: float = 12.0
@export var bounce_impulse: float = 16.0
@export var footstep_interval: float = 0.28
@export var footstep_pitch_min: float = 0.96
@export var footstep_pitch_max: float = 1.04

const FOOTSTEP_STREAM: AudioStream = preload("res://audio/sfx/footsteps/footstep_light_01.wav")
const JUMP_STREAM: AudioStream = preload("res://audio/sfx/player/jump_01.wav")

@export var max_health: int = 100
var current_health: int

signal health_changed(new_health: int, max_health: int)

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _sprite: AnimatedSprite2D
var originalPosX: float
var _weaponSprite: Node2D
var _weapon: Node2D
var _footstep_player: AudioStreamPlayer2D
var _footstep_timer: float = 0.0
var _was_moving: bool = false

var facing_left: bool
var _is_dead: bool = false


func _ready() -> void:
	add_to_group("Players")
	current_health = max_health
	_sprite = $AnimatedSprite2D
	_weaponSprite = $BasisWeapon/Sprite
	_weapon = $BasisWeapon
	_footstep_player = $Footsteps
	_footstep_player.stream = FOOTSTEP_STREAM
	_footstep_player.bus = "SFX"
	_sprite.play("idle")


func _physics_process(delta: float) -> void:
	var vel: Vector2 = velocity

	if not is_on_floor():
		vel.y += _gravity * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		vel.y = jump_velocity
		_play_jump_sound()

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

	var is_grounded: bool = is_on_floor()
	var is_moving_on_ground: bool = is_grounded and abs(velocity.x) > 5.0
	_update_animation(is_moving_on_ground)
	_update_footsteps(delta, is_moving_on_ground)

	$HeadHitDetector.force_raycast_update()
	if $HeadHitDetector.is_colliding():
		var collider = $HeadHitDetector.get_collider()
		# Check if the collider is the destructible object and the player is moving upward
		if collider.is_in_group("Destructibles") and velocity.y < 0:
			collider.detonate()
			velocity.y = bounce_impulse


func _update_animation(is_moving: bool) -> void:
	var target_animation: StringName = &"walk" if is_moving else &"idle"
	if _sprite.animation != target_animation:
		_sprite.play(target_animation)


func _update_footsteps(delta: float, is_moving: bool) -> void:
	if not is_moving:
		if _footstep_player.playing:
			_footstep_player.stop()
		_footstep_timer = 0.0
		_was_moving = false
		return

	if not _was_moving:
		_footstep_timer = footstep_interval * 0.5
		_was_moving = true

	_footstep_timer += delta
	if _footstep_timer >= footstep_interval:
		_footstep_timer -= footstep_interval
		_play_footstep()


func _play_footstep() -> void:
	if _footstep_player == null:
		return

	_footstep_player.global_position = global_position
	_footstep_player.pitch_scale = randf_range(footstep_pitch_min, footstep_pitch_max)
	_footstep_player.play()


func _play_jump_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(JUMP_STREAM, global_position, -12.0, 0.98, 1.04)


func take_damage(amount: int) -> void:
	if _is_dead:
		return
	current_health = clamp(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		die()


func die() -> void:
	_is_dead = true
	_weapon.set_process_input(false)
	set_physics_process(false)
	_weaponSprite.visible = false
	_sprite.visible = false
	await get_tree().create_timer(3.0).timeout
	_respawn()


func _respawn() -> void:
	var points := get_tree().get_nodes_in_group("SpawnPoints")
	if points.size() > 0:
		global_position = points[randi() % points.size()].global_position
	current_health = max_health
	health_changed.emit(current_health, max_health)
	velocity = Vector2.ZERO
	_weapon.set_process_input(true)
	set_physics_process(true)
	if _footstep_player:
		_footstep_player.stop()
	_footstep_timer = 0.0
	_was_moving = false
	await get_tree().physics_frame
	_sprite.visible = true
	_weaponSprite.visible = true
	_is_dead = false
	_sprite.play("idle")
