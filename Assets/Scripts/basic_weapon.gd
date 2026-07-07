class_name BasicWeapon
extends Node2D

signal hud_state_changed(state: Dictionary)

# --- Shared weapon stats (set per-weapon in _setup()) ---
var fire_cooldown: float = 0.0       # Seconds between shots; 0 = no cooldown (semi-auto click)
var magazine_size: int = 0           # 0 = no magazine (cooldown-only weapons like thrown knives)
var reload_time: float = 1.5
var bullet_damage: int = 10
var bullet_speed: float = 600.0
var bullet_max_distance: float = 1000.0
var weapon_label: String = "Weapon"
var auto_fire: bool = false          # Hold LMB to keep firing (assault rifle)
var bullet_rand_scale: float = 1.0   # Scale applied to spawned bullets

# --- HUD ammo icons (assigned per-weapon in _setup()) ---
var full_icon: Texture2D = null
var empty_icon: Texture2D = null

# --- Internal state ---
@onready var muzzle = $Muzzle
var _sprite: Sprite2D
var can_shoot: bool = true
var current_ammo: int = 0
var is_reloading: bool = false
var reload_elapsed: float = 0.0
var cooldown_elapsed: float = 0.0
var _reload_cycle: int = 0
var _fire_held: bool = false


func _ready() -> void:
	_sprite = $Sprite
	_setup()
	current_ammo = magazine_size
	cooldown_elapsed = fire_cooldown
	_emit_hud_state()


## Override in subclasses to configure per-weapon stats and icons.
func _setup() -> void:
	pass


func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position

	_sprite.flip_v = to_mouse.x < 0
	look_at(mouse_pos)

	if is_reloading:
		reload_elapsed = min(reload_elapsed + delta, reload_time)
		_emit_hud_state()
	elif not can_shoot and fire_cooldown > 0.0:
		cooldown_elapsed = min(cooldown_elapsed + delta, fire_cooldown)
		_emit_hud_state()

	# Auto-fire: keep shooting while LMB is held (assault rifle)
	if auto_fire and _fire_held and can_shoot and not is_reloading:
		if magazine_size == 0 or current_ammo > 0:
			shoot()


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_fire_held = true
			if can_shoot and not is_reloading:
				if magazine_size == 0 or current_ammo > 0:
					shoot()
		else:
			_fire_held = false
	elif event.is_action_pressed("reload_weapon"):
		reload()


func shoot() -> void:
	if is_reloading:
		return
	if fire_cooldown > 0.0 and not can_shoot:
		return
	if magazine_size > 0 and current_ammo <= 0:
		reload()
		return

	if fire_cooldown > 0.0:
		can_shoot = false
		cooldown_elapsed = 0.0
	if magazine_size > 0:
		current_ammo -= 1
	_emit_hud_state()

	_fire()
	_play_fire_sound()

	if fire_cooldown > 0.0:
		await get_tree().create_timer(fire_cooldown).timeout
		if not is_reloading:
			can_shoot = true
			cooldown_elapsed = fire_cooldown
			_emit_hud_state()

	if magazine_size > 0 and current_ammo <= 0:
		reload()


## Override in subclasses to spawn bullets (pellets, single round, etc.).
func _fire() -> void:
	pass


## Override in subclasses to play a weapon-specific fire sound.
func _play_fire_sound() -> void:
	pass


## Override in subclasses to play a weapon-specific reload sound.
func _play_reload_sound() -> void:
	pass


func reload() -> void:
	if magazine_size == 0:
		return
	if is_reloading or current_ammo == magazine_size:
		return

	is_reloading = true
	can_shoot = false
	reload_elapsed = 0.0
	_reload_cycle += 1
	var reload_id := _reload_cycle
	_emit_hud_state()
	_play_reload_sound()

	await get_tree().create_timer(reload_time).timeout

	if reload_id != _reload_cycle:
		return

	current_ammo = magazine_size
	is_reloading = false
	reload_elapsed = 0.0
	can_shoot = true
	_emit_hud_state()


func get_weapon_summary() -> String:
	var parts: Array[String] = ["%d dmg" % bullet_damage]
	if magazine_size > 0:
		parts.append("%d ammo" % magazine_size)
		if fire_cooldown > 0.0:
			parts.append("%.2fs shot cd" % fire_cooldown)
		if reload_time > 0.0:
			parts.append("%.1fs reload" % reload_time)
	else:
		if fire_cooldown > 0.0:
			parts.append("%.2fs cooldown" % fire_cooldown)
		if bullet_max_distance > 0.0:
			parts.append("%.0f range" % bullet_max_distance)
	return " • ".join(parts)


func get_weapon_status_text() -> String:
	if magazine_size > 0:
		if is_reloading:
			var reload_remaining := max(reload_time - reload_elapsed, 0.0)
			return "Nachladen %.1fs" % reload_remaining
		return "%d / %d" % [current_ammo, magazine_size]

	if fire_cooldown <= 0.0:
		return "Bereit"

	if can_shoot:
		return "Bereit"

	var cooldown_remaining := max(fire_cooldown - cooldown_elapsed, 0.0)
	return "Cooldown %.1fs" % cooldown_remaining


func get_hud_state() -> Dictionary:
	if magazine_size > 0:
		return {
			"mode": "ammo",
			"label": weapon_label,
			"summary": get_weapon_summary(),
			"status_text": get_weapon_status_text(),
			"visible": true,
			"current": current_ammo,
			"max": magazine_size,
			"full_icon": full_icon,
			"empty_icon": empty_icon,
			"bar_visible": is_reloading,
			"bar_progress": clamp(reload_elapsed / reload_time, 0.0, 1.0) if reload_time > 0.0 else 0.0,
		}
	return {
		"mode": "cooldown",
		"label": weapon_label,
		"summary": get_weapon_summary(),
		"status_text": get_weapon_status_text(),
		"visible": true,
		"bar_visible": true,
		"bar_progress": clamp(cooldown_elapsed / fire_cooldown, 0.0, 1.0) if fire_cooldown > 0.0 else 1.0,
	}


func _emit_hud_state() -> void:
	hud_state_changed.emit(get_hud_state())
