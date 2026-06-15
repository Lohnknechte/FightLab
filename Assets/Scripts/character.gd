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
signal weapon_changed(slot: int)
signal weapon_hud_changed(state: Dictionary)

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _sprite: AnimatedSprite2D
var originalPosX: float
var _shotgun: Node2D
var _sniper: Node2D
var _shuriken: Node2D
var _knife: Node2D
var _active_weapon: Node2D
var _weapons: Array[Node2D] = []
var _footstep_player: AudioStreamPlayer2D
var _footstep_timer: float = 0.0
var _was_moving: bool = false

var facing_left: bool
var _is_dead: bool = false


func _ready() -> void:
	add_to_group("Players")
	current_health = max_health
	_sprite = $AnimatedSprite2D
	_shotgun = $BasisWeapon
	_sniper = $SniperWeapon
	_shuriken = $ShurikenWeapon
	_knife = $KnifeWeapon
	_weapons = [_shotgun, _sniper, _shuriken, _knife]
	for weapon in _weapons:
		if weapon.has_signal("hud_state_changed"):
			weapon.hud_state_changed.connect(_on_weapon_hud_changed.bind(weapon))
	_footstep_player = $Footsteps
	_footstep_player.stream = FOOTSTEP_STREAM
	_footstep_player.bus = "SFX"
	_sprite.play("idle")
	_set_active_weapon(_shotgun)


func _input(event: InputEvent) -> void:
	if _is_dead:
		return

	if event.is_action_pressed("weapon_1"):
		_set_active_weapon(_shotgun)
	elif event.is_action_pressed("weapon_2"):
		_set_active_weapon(_sniper)
	elif event.is_action_pressed("weapon_3"):
		_set_active_weapon(_shuriken)
	elif event.is_action_pressed("weapon_4"):
		_set_active_weapon(_knife)


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
	set_physics_process(false)
	for weapon in _weapons:
		weapon.visible = false
		weapon.set_process(false)
		weapon.set_physics_process(false)
		weapon.set_process_input(false)
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
	set_physics_process(true)
	if _footstep_player:
		_footstep_player.stop()
	_footstep_timer = 0.0
	_was_moving = false
	await get_tree().physics_frame
	_sprite.visible = true
	_is_dead = false
	_set_active_weapon(_active_weapon if _active_weapon != null else _shotgun)
	_sprite.play("idle")


func _set_active_weapon(weapon: Node2D) -> void:
	if weapon == null:
		return

	_active_weapon = weapon

	for current_weapon in _weapons:
		var is_active := current_weapon == weapon and not _is_dead
		current_weapon.visible = is_active
		current_weapon.set_process(is_active)
		current_weapon.set_physics_process(is_active)
		current_weapon.set_process_input(is_active)

	var slot := _get_weapon_slot(weapon)
	if slot != -1:
		weapon_changed.emit(slot)
	_emit_active_weapon_hud_state()


func _get_weapon_slot(weapon: Node2D) -> int:
	if weapon == _shotgun:
		return 1
	if weapon == _sniper:
		return 2
	if weapon == _shuriken:
		return 3
	if weapon == _knife:
		return 4
	return -1


func _on_weapon_hud_changed(state: Dictionary, weapon: Node2D) -> void:
	if weapon != _active_weapon:
		return

	weapon_hud_changed.emit(state)


func _emit_active_weapon_hud_state() -> void:
	if _active_weapon == null:
		weapon_hud_changed.emit({
			"visible": false,
		})
		return

	if _active_weapon.has_method("get_hud_state"):
		weapon_hud_changed.emit(_active_weapon.get_hud_state())
		return

	weapon_hud_changed.emit({
		"visible": false,
	})


func get_active_weapon_hud_state() -> Dictionary:
	if _active_weapon != null and _active_weapon.has_method("get_hud_state"):
		return _active_weapon.get_hud_state()

	return {
		"visible": false,
	}
