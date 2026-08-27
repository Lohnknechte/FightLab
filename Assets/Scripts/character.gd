extends CharacterBody2D

@onready var hud = $HUD # The HUD node
@onready var _camera: Camera2D = $Camera2D
## Whether this instance is the one the local player sees and controls.
## Set automatically in _ready(): the first character to join the "Players"
## group each level (or test) counts as local, every one after it doesn't.
## Non-local instances keep their camera off, their HUD hidden and ignore
## input, so only one character reacts to the keyboard at a time. This is a
## placeholder for real multiplayer authority - once networking exists,
## replace the group-order check in _ready() with is_multiplayer_authority().
@export var is_local_player: bool = true
@export var speed: float = 200.0
@export var jump_velocity: float = -500.0
@export var acceleration: float = 15.0
@export var friction: float = 12.0
@export var bounce_impulse: float = 16.0
@export var footstep_interval: float = 0.28
@export var footstep_pitch_min: float = 0.96
@export var footstep_pitch_max: float = 1.04
@export var max_health: int = 100
## Default status effect applied to this character's weapons when no
## LoadoutState autoload is present (e.g. isolated scene tests). During
## normal play, _apply_loadout() overwrites this with the player's
## confirmed loadout selection (including "None", which clears it to null)
## so every spawned player uses the same menu-selected effect.
@export var equipped_effect: StatusEffect

const FOOTSTEP_STREAM: AudioStream = preload("res://audio/sfx/footsteps/footstep_light_01.wav")
const JUMP_STREAM: AudioStream = preload("res://audio/sfx/player/jump_01.wav")

signal health_changed(new_health: int, max_health: int)
signal weapon_changed(slot: int)
signal weapon_hud_changed(state: Dictionary)
signal ultimate_charge_updated(current: float, max_val: float)
signal gadget_charge_changed(charge: int, max_charge: int) # remove 

var current_health: int = max_health
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
var facing_left: bool = false
var _is_dead: bool = false 
var speed_multiplier = 1.0  # Für "Freeze" (Verlangsamung)
var can_move = true
var has_effect:StringName = "none"
var is_dashing: bool = false
var _damage_reduction: float = 0.0

func _ready() -> void:
	add_to_group("Players")
<<<<<<< Updated upstream
	# First character to join "Players" this level is the local player;
	# every one after it (group already has other members) is not.
	is_local_player = get_tree().get_nodes_in_group("Players").size() == 1
=======
	_apply_armor()
>>>>>>> Stashed changes
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
	_set_active_weapon(_apply_loadout())
	hud.initialize(self)
	_apply_local_player_state()


## Toggles camera, HUD and weapon input for whichever local-player state was
## last assigned via [method set_is_local_player].
func _apply_local_player_state() -> void:
	_camera.set_deferred("current", is_local_player)
	hud.visible = is_local_player
	if _active_weapon != null:
		_set_active_weapon(_active_weapon)


## Called by BaseLevel to designate which character instance the local
## player controls.
func set_is_local_player(value: bool) -> void:
	is_local_player = value
	_apply_local_player_state()


## Reads the confirmed armor selection from the LoadoutState autoload and
## applies its modifiers: flat damage reduction, movement/jump multipliers
## and max health. No-op when the autoload is missing (isolated tests).
func _apply_armor() -> void:
	var state := get_node_or_null("/root/LoadoutState")
	if state == null:
		return

	var armor: Dictionary = state.get_selected_option(&"armor")
	if armor.is_empty():
		return

	_damage_reduction = clampf(float(armor.get("damage_reduction", 0.0)), 0.0, 1.0)
	speed *= float(armor.get("speed_mult", 1.0))
	jump_velocity *= float(armor.get("jump_mult", 1.0))
	max_health = int(armor.get("max_health", max_health))


## Reads the confirmed selection from the LoadoutState autoload (if present)
## and applies it to this character: sets the Ultimate/Gadget manager
## indices, overrides equipped_effect (see its doc comment above), and
## returns the weapon node that should become the active weapon. Falls back
## to the Shotgun and the scene-configured equipped_effect when the
## autoload is unavailable, e.g. in isolated unit tests.
func _apply_loadout() -> Node2D:
	var state := get_node_or_null("/root/LoadoutState")
	if state == null:
		return _shotgun

	var ultimate_option: Dictionary = state.get_selected_option(&"ultimate")
	var gadget_option: Dictionary = state.get_selected_option(&"gadget")
	if not $UltimateManager.ultimates.is_empty():
		$UltimateManager.current_index = clampi(int(ultimate_option.get("manager_index", 0)), 0, $UltimateManager.ultimates.size() - 1)
	if not $GadgetManager.gadgets.is_empty():
		$GadgetManager.current_index = clampi(int(gadget_option.get("manager_index", 0)), 0, $GadgetManager.gadgets.size() - 1)

	var effect_option: Dictionary = state.get_selected_option(&"effect")
	var effect_path := str(effect_option.get("resource_path", ""))
	equipped_effect = load(effect_path) as StatusEffect if not effect_path.is_empty() else null

	var weapon_option: Dictionary = state.get_selected_option(&"weapon")
	var weapon_index := clampi(int(weapon_option.get("weapon_index", 0)), 0, _weapons.size() - 1)
	return _weapons[weapon_index]


func _input(event: InputEvent) -> void:
	if _is_dead or not is_local_player:
		return

	if event.is_action_pressed("weapon_1"):
		_set_active_weapon(_shotgun)
	elif event.is_action_pressed("weapon_2"):
		_set_active_weapon(_sniper)
	elif event.is_action_pressed("weapon_3"):
		_set_active_weapon(_shuriken)
	elif event.is_action_pressed("weapon_4"):
		_set_active_weapon(_knife)


func _unhandled_input(event: InputEvent) -> void:
	# Gadget controls (F = use, G = cycle). Weapon slots use 1-9, reload uses R.
	if _is_dead or not is_local_player:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("cast_gadget"):
			print("GADGET USED")
			$GadgetManager.cast_gadget()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("cast_ultimate"):
			print("INPUT: Q Pressed!")
			$UltimateManager.cast_ultimate()
			get_viewport().set_input_as_handled()

func is_facing_left() -> bool:
	# Gib den Wert deines Sprites zurück
	return _sprite.flip_h
	
func _physics_process(delta: float) -> void:
	var vel: Vector2 = velocity
	if not can_move:
		vel.x = 0.0          # Horizontale Bewegung stoppen
		velocity = vel       # Die (fallende) Geschwindigkeit an Godot übergeben
		move_and_slide()     # Physik ausführen, damit er fällt
		return               # Jetzt erst abbrechen, da die Physik für diesen Frame durch ist!
	# Dash gadget: brief invulnerable horizontal burst that dodges shots.
	if is_dashing:
		if not is_on_floor():
			velocity.y += _gravity * delta
		move_and_slide()
		return

	if not is_on_floor():
		vel.y += _gravity * delta

	if is_local_player and Input.is_action_just_pressed("ui_up") and is_on_floor():
		vel.y = jump_velocity
		_play_jump_sound()

	if is_local_player and Input.is_action_just_released("ui_up") and vel.y < 0.0:
		vel.y *= 0.5

	var direction: float = Input.get_axis("ui_left", "ui_right") if is_local_player else 0.0
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


func _update_facing(direction : float):
	if direction != 0.0: 
		facing_left = direction < 0.0
		_sprite.flip_h = facing_left 

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
	if _is_dead:
		return

	var effective := int(round(amount * (1.0 - _damage_reduction)))
	current_health = clamp(current_health - effective, 0, max_health)
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

	# disable ALL collision shapes
	#for child in get_children():
		#if child is CollisionShape2D or child is CollisionPolygon2D:
			#child.set_deferred("disabled", true)

	# weapons off
	for weapon in _weapons:
		weapon.visible = false
		weapon.set_process(false)
		weapon.set_physics_process(false)
		weapon.set_process_input(false)

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
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
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
		current_weapon.set_process_input(is_active and is_local_player)
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
	var state = _active_weapon.get_hud_state() if (_active_weapon and _active_weapon.has_method("get_hud_state")) else {"visible": false}
	print("DEBUG: Emitting HUD state for ", _active_weapon.name, ": ", state) # ADD THIS
	weapon_hud_changed.emit(state)
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
