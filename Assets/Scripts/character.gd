class_name Character
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

# --- Gadgets (chargeable abilities, separate from the weapon hotbar) ---
# All gadget rules + per-gadget tuning live in GadgetController /
# Gadget subclasses. Character only owns the generic controller config
# (the controller is created at runtime, so its @exports aren't editable
# in the scene) and the minimal integration hooks (input dispatch, dash
# physics state, helper API used by gadgets).
@export var gadget_max_charge: int = 100
@export var gadget_charge_rate: float = 8.0

var _gadget_controller: GadgetController
var _dash_time_left: float = 0.0
var _dash_speed: float = 900.0
var _dash_dir: float = 1.0
var _invulnerable: bool = false

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _sprite: AnimatedSprite2D
var _shotgun: Node2D
var _sniper: Node2D
var _knife: Node2D
var _assault_rifle: Node2D
var _active_weapon: Node2D
var _weapons: Array[Node2D] = []
var _footstep_player: AudioStreamPlayer2D
var _footstep_timer: float = 0.0
var _was_moving: bool = false

var facing_left: bool = false
var _is_dead: bool = false 
@export var equipped_effect: StatusEffect
var speed_multiplier = 1.0  # Für "Freeze" (Verlangsamung)
var can_move = true
var has_effect:StringName = "none"

func _ready() -> void:
	add_to_group("Players")
	current_health = max_health
	_sprite = $AnimatedSprite2D
	_shotgun = $BasisWeapon
	_sniper = $SniperWeapon
	_knife = $KnifeWeapon
	_assault_rifle = $AssaultRifle
	_weapons = [_shotgun, _sniper, _knife, _assault_rifle]
	for weapon in _weapons:
		if weapon.has_signal("hud_state_changed"):
			weapon.hud_state_changed.connect(_on_weapon_hud_changed.bind(weapon))
		# Deactivate all weapons initially so they can't fire before a class is chosen
		weapon.visible = false
		weapon.set_process(false)
		weapon.set_physics_process(false)
		weapon.set_process_input(false)
	_footstep_player = $Footsteps
	_footstep_player.stream = FOOTSTEP_STREAM
	_footstep_player.bus = "SFX"
	_sprite.play("idle")
	_setup_gadgets()
	if has_node("UltimateManager"):
		$UltimateManager.caster = self


func _setup_gadgets() -> void:
	_gadget_controller = GadgetController.new()
	_gadget_controller.max_charge = gadget_max_charge
	_gadget_controller.charge_rate = gadget_charge_rate

	# Gadgets carry their own @export tuning (bomb count, dash speed,
	# shockwave params, ...); Character doesn't know or copy any of it.
	for gadget in [AirstrikeGadget.new(), DashGadget.new(), DiceGadget.new()]:
		_gadget_controller.add_child(gadget)
	add_child(_gadget_controller)

	_gadget_controller.setup(self)
	# Gadgets shouldn't charge before a class has been chosen (mirrors the
	# weapons, which are also fully disabled in _ready() until set_class()).
	_gadget_controller.set_process(false)


func get_gadget_controller() -> GadgetController:
	return _gadget_controller


func set_class(class_id: String) -> void:
	var weapon: Node2D
	match class_id:
		"Bummer":
			weapon = _shotgun
		"Recon":
			weapon = _sniper
		"Assassin":
			weapon = _knife
		"Assault":
			weapon = _assault_rifle
		_:
			weapon = _shotgun
	_set_active_weapon(weapon)
	_gadget_controller.set_process(true)


func _unhandled_input(event: InputEvent) -> void:
	# Gadget controls (F = use, G = cycle). Weapon slots use 1-9, reload uses R.
	if _is_dead:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			_gadget_controller.select_next()
		elif event.keycode == KEY_F:
			_gadget_controller.try_use()
		elif event.is_action_pressed("cast_ultimate"):
			$UltimateManager.cast_ultimate()
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var vel: Vector2 = velocity
	if not can_move:
		vel.x = 0.0          # Horizontale Bewegung stoppen
		velocity = vel       # Die (fallende) Geschwindigkeit an Godot übergeben
		move_and_slide()     # Physik ausführen, damit er fällt
		return               # Jetzt erst abbrechen, da die Physik für diesen Frame durch ist!
	# Dash gadget: brief invulnerable horizontal burst that dodges shots.
	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		vel.x = _dash_dir * _dash_speed
		vel.y = 0.0
		velocity = vel
		move_and_slide()
		if _dash_time_left <= 0.0:
			_invulnerable = false
		return

	if not is_on_floor():
		vel.y += _gravity * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		vel.y = jump_velocity
		_play_jump_sound()

	if Input.is_action_just_released("ui_up") and vel.y < 0.0:
		vel.y *= 0.5

	var direction: float = Input.get_axis("ui_left", "ui_right")
	_update_facing(direction)

	if direction != 0.0:
		vel.x = move_toward(vel.x, direction * (speed * speed_multiplier), acceleration * (speed * speed_multiplier) * delta)
	else:
		vel.x = move_toward(vel.x, 0.0, friction * (speed * speed_multiplier) * delta)
 
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


func _update_facing(direction: float) -> void:
	if direction != 0.0:
		facing_left = direction < 0.0
		_sprite.flip_h = facing_left


func get_facing_direction() -> Vector2:
	return Vector2.LEFT if facing_left else Vector2.RIGHT


func _update_animation(is_moving: bool) -> void:
	var target_animation: StringName = &"walk" if is_moving else &"idle"
	if has_effect == "freeze":
		target_animation= &"frozen_walk" if is_moving else &"frozen_idle"
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
	if _is_dead or _invulnerable:
		return
	current_health = clamp(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		die()


func die() -> void:
	_is_dead = true
	$StatusManager.clear_effects()
	# stop movement logic
	set_physics_process(false)

	# hide visuals
	_sprite.visible = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# weapons off
	for weapon in _weapons:
		weapon.visible = false
		weapon.set_process(false)
		weapon.set_physics_process(false)
		weapon.set_process_input(false)

	# gadgets off — GadgetController runs on its own _process(), so it must
	# be paused explicitly or charge would keep accumulating while dead.
	if _gadget_controller:
		_gadget_controller.set_process(false)

	await get_tree().create_timer(3.0).timeout
	_respawn()


func _respawn() -> void:
	var points := get_tree().get_nodes_in_group("SpawnPoints")
	if points.size() > 0:
		global_position = points[randi() % points.size()].global_position
	current_health = max_health
	health_changed.emit(current_health, max_health)
	velocity = Vector2.ZERO
	_dash_time_left = 0.0
	_invulnerable = false
	set_physics_process(true)
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	if _footstep_player:
		_footstep_player.stop()
	_footstep_timer = 0.0
	_was_moving = false
	if _gadget_controller:
		_gadget_controller.set_process(true)
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
		current_weapon.attack_effect = equipped_effect
	var slot := _get_weapon_slot(weapon)
	if slot != -1:
		weapon_changed.emit(slot)
	_emit_active_weapon_hud_state()


func _get_weapon_slot(weapon: Node2D) -> int:
	if weapon == _shotgun:
		return 1
	if weapon == _sniper:
		return 2
	if weapon == _knife:
		return 3
	if weapon == _assault_rifle:
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


func set_weapon_input_enabled(enabled: bool) -> void:
	if enabled:
		_set_active_weapon(_active_weapon if _active_weapon != null else _shotgun)
		return
	for weapon in _weapons:
		weapon.set_process_input(false)


# ---------------------------------------------------------------------------
# Gadgets — public API used by GadgetController / Gadget subclasses
# ---------------------------------------------------------------------------

func start_dash(speed: float, duration: float) -> void:
	_dash_dir = -1.0 if facing_left else 1.0
	_dash_speed = speed
	_dash_time_left = duration
	_invulnerable = true


func heal_to_full() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func teleport_to(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO


func spawn_vfx(pos: Vector2, color: Color, radius: float, dur: float = 0.35) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var v := VfxBurst.new()
	v.setup(color, radius, dur)
	scene.add_child(v)
	v.global_position = pos


func is_dead() -> bool:
	return _is_dead


func get_other_players() -> Array:
	var list: Array = []
	for player in get_tree().get_nodes_in_group("Players"):
		if player != self and is_instance_valid(player) and not player.is_dead():
			list.append(player)
	return list
