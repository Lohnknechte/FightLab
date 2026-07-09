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
const GADGET_AIRSTRIKE: int = 0
const GADGET_DASH: int = 1
const GADGET_DICE: int = 2
const GADGET_NAMES: Array[String] = ["Airstrike", "Dash", "Dice"]
const GADGET_VOICELINES: Dictionary = {
	"Airstrike": "The Missile Knows where it is because it knows where it isn't",
	"Dash": "Weeeeeeeeeeee",
	"Dice": "Surprise! You're Dead.",
}
# Dice has its OWN pool of effects. Weighted so strong outcomes are rarer.
const DICE_OUTCOMES: Array[String] = ["Heal", "Teleport", "Shockwave", "Swap", "Jackpot", "Snake Eyes"]
const DICE_WEIGHTS: Array[int] = [2, 3, 3, 4, 1, 6]
const DICE_VOICELINES: Dictionary = {
	"Heal": "Patched up!",
	"Teleport": "Now you see me...",
	"Shockwave": "Get baaack!",
	"Swap": "Let's trade places!",
	"Jackpot": "Surprise! You're Dead.",
	"Snake Eyes": "Ouch... bad luck.",
}

@export var gadget_max_charge: int = 100
@export var gadget_charge_rate: float = 8.0
@export var airstrike_bomb_count: int = 6
@export var airstrike_spread: float = 150.0
@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.18
@export var shockwave_radius: float = 160.0
@export var shockwave_damage: int = 30
@export var shockwave_force: float = 650.0
@export var snake_eyes_damage: int = 25

var gadget_charge: int = 0
var _charge_accum: float = 0.0
var current_gadget: int = GADGET_AIRSTRIKE
var _dice_result: int = -1
var _dash_time_left: float = 0.0
var _dash_dir: float = 1.0
var _invulnerable: bool = false

signal gadget_charge_changed(charge: int, max_charge: int)
signal gadget_selected(gadget_name: String)
signal gadget_used(gadget_name: String, voiceline: String)
signal gadget_use_denied()
signal dice_rolled(result_name: String)

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
	gadget_charge_changed.emit(gadget_charge, gadget_max_charge)
	gadget_selected.emit(get_gadget_name())


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


func _unhandled_input(event: InputEvent) -> void:
	# Gadget controls (F = use, G = cycle). Weapon slots use 1-9, reload uses R.
	if _is_dead:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			_select_gadget((current_gadget + 1) % GADGET_NAMES.size())
		elif event.keycode == KEY_F:
			_try_use_gadget()
		elif event.is_action_pressed("cast_ultimate"):
			print("INPUT: Q Pressed!")
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
		vel.x = _dash_dir * dash_speed
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

	_update_gadget_charge(delta)

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
	if _is_dead or _invulnerable:
		return
	print(amount)
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
	_dash_time_left = 0.0
	_invulnerable = false
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


# ---------------------------------------------------------------------------
# Gadgets
# ---------------------------------------------------------------------------

func get_gadget_name() -> String:
	return GADGET_NAMES[current_gadget]


func _update_gadget_charge(delta: float) -> void:
	if gadget_charge >= gadget_max_charge:
		return
	_charge_accum += gadget_charge_rate * delta
	var new_charge: int = min(gadget_max_charge, int(_charge_accum))
	if new_charge != gadget_charge:
		gadget_charge = new_charge
		gadget_charge_changed.emit(gadget_charge, gadget_max_charge)
		if gadget_charge >= gadget_max_charge and current_gadget == GADGET_DICE and _dice_result == -1:
			_roll_dice()


func _select_gadget(index: int) -> void:
	if index == current_gadget:
		return
	current_gadget = index
	gadget_selected.emit(get_gadget_name())
	# Roll Dice once when selected-while-charged; a previous roll is kept
	# (you can't re-roll by switching away and back — only using clears it).
	if current_gadget == GADGET_DICE and gadget_charge >= gadget_max_charge and _dice_result == -1:
		_roll_dice()


func _roll_dice() -> void:
	_dice_result = _weighted_dice()
	dice_rolled.emit(DICE_OUTCOMES[_dice_result])


func _weighted_dice() -> int:
	var total: int = 0
	for w in DICE_WEIGHTS:
		total += w
	var pick: int = randi() % total
	var acc: int = 0
	for i in DICE_WEIGHTS.size():
		acc += DICE_WEIGHTS[i]
		if pick < acc:
			return i
	return DICE_WEIGHTS.size() - 1


func _try_use_gadget() -> void:
	if gadget_charge < gadget_max_charge:
		gadget_use_denied.emit()
		return

	match current_gadget:
		GADGET_AIRSTRIKE:
			_gadget_airstrike(get_global_mouse_position())
			gadget_used.emit("Airstrike", GADGET_VOICELINES["Airstrike"])
		GADGET_DASH:
			_gadget_dash()
			gadget_used.emit("Dash", GADGET_VOICELINES["Dash"])
		GADGET_DICE:
			_use_dice()

	gadget_charge = 0
	_charge_accum = 0.0
	_dice_result = -1
	gadget_charge_changed.emit(gadget_charge, gadget_max_charge)


func _spawn_vfx(pos: Vector2, color: Color, radius: float, dur: float = 0.35) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var v := VfxBurst.new()
	v.setup(color, radius, dur)
	scene.add_child(v)
	v.global_position = pos


func _gadget_dash() -> void:
	_dash_dir = -1.0 if facing_left else 1.0
	_dash_time_left = dash_duration
	_invulnerable = true
	_spawn_vfx(global_position, Color(0.85, 0.92, 1.0), 38.0, 0.3)


func _gadget_airstrike(center: Vector2) -> void:
	for i in range(airstrike_bomb_count):
		var t: float = float(i) / float(max(1, airstrike_bomb_count - 1))
		var x: float = center.x - airstrike_spread * 0.5 + airstrike_spread * t
		await get_tree().create_timer(0.08 * i).timeout
		if not is_inside_tree():
			return
		var bomb := AirstrikeBomb.new()
		bomb.target_y = center.y
		get_tree().current_scene.add_child(bomb)
		bomb.global_position = Vector2(x, center.y - 360.0)


func _other_players() -> Array:
	var list: Array = []
	for player in get_tree().get_nodes_in_group("Players"):
		if player != self and is_instance_valid(player) and not player._is_dead:
			list.append(player)
	return list


func _use_dice() -> void:
	var idx: int = _dice_result if _dice_result != -1 else _weighted_dice()
	var outcome: String = DICE_OUTCOMES[idx]
	match idx:
		0:
			_dice_heal()
		1:
			_dice_teleport()
		2:
			_dice_shockwave()
		3:
			_dice_swap()
		4:
			_dice_jackpot()
		5:
			_dice_snake_eyes()
	gadget_used.emit("Dice → %s" % outcome, DICE_VOICELINES.get(outcome, GADGET_VOICELINES["Dice"]))


func _dice_heal() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	_spawn_vfx(global_position, Color(0.3, 0.85, 0.4), 44.0, 0.45)


func _dice_teleport() -> void:
	_spawn_vfx(global_position, Color(0.6, 0.45, 0.95), 40.0, 0.35)
	global_position = get_global_mouse_position()
	velocity = Vector2.ZERO
	_spawn_vfx(global_position, Color(0.6, 0.45, 0.95), 40.0, 0.35)


func _dice_shockwave() -> void:
	_spawn_vfx(global_position, Color(0.4, 0.85, 1.0), shockwave_radius, 0.4)
	for other in _other_players():
		if global_position.distance_to(other.global_position) <= shockwave_radius:
			var dir: Vector2 = (other.global_position - global_position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.RIGHT
			other.velocity = dir * shockwave_force + Vector2.UP * shockwave_force * 0.4
			if other.has_method("take_damage"):
				other.take_damage(shockwave_damage)


func _dice_swap() -> void:
	var others := _other_players()
	if others.size() > 0:
		var target = others[randi() % others.size()]
		var tmp := global_position
		_spawn_vfx(global_position, Color(0.95, 0.6, 0.2), 38.0, 0.35)
		global_position = target.global_position
		target.global_position = tmp
		_spawn_vfx(global_position, Color(0.95, 0.6, 0.2), 38.0, 0.35)
		_spawn_vfx(tmp, Color(0.95, 0.6, 0.2), 38.0, 0.35)


func _dice_jackpot() -> void:
	var others := _other_players()
	if others.size() > 0:
		var victim = others[randi() % others.size()]
		_spawn_vfx(victim.global_position, Color(0.95, 0.25, 0.22), 50.0, 0.45)
		victim.die()


func _dice_snake_eyes() -> void:
	_spawn_vfx(global_position, Color(0.9, 0.3, 0.28), 34.0, 0.35)
	take_damage(snake_eyes_damage)
