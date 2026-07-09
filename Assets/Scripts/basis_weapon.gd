extends Node2D

signal hud_state_changed(state: Dictionary)


const BULLET_SCENE = preload("res://src/scenes/Bullet.tscn")
const SHOTGUN_FIRE_STREAM = preload("res://audio/sfx/weapons/shotgun/shotgun_fire_01.wav")
const SHOTGUN_RELOAD_STREAM = preload("res://audio/reload.wav")
const SHELL_FULL = preload("res://Assets/Sprites/weapons/ammo/shotgun/shell_full.png")
const SHELL_EMPTY = preload("res://Assets/Sprites/weapons/ammo/shotgun/shell_empty.png")

@onready var muzzle = $Muzzle
var _sprite: Sprite2D

@export var magazine_size: int = 5
@export var reload_time: float = 1.5
@export var pellet_damage: int = 5

var current_ammo: int = 5
var is_reloading: bool = false
var reload_elapsed: float = 0.0
var _reload_cycle: int = 0 
var attack_effect: StatusEffect

func _ready() -> void:
	_sprite = $Sprite
	current_ammo = magazine_size
	_emit_hud_state()


func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position

	$Sprite.flip_v = to_mouse.x < 0
	look_at(mouse_pos)

	if is_reloading:
		reload_elapsed = min(reload_elapsed + delta, reload_time)
		_emit_hud_state()


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			shoot()
	elif event.is_action_pressed("reload_weapon"):
		reload()


func shoot() -> void:
	if is_reloading or current_ammo <= 0:
		return

	var bullet_count := 5
	var spread_angle := 0.26
	current_ammo -= 1
	_emit_hud_state()

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(SHOTGUN_FIRE_STREAM, muzzle.global_position, -3.0, 0.98, 1.02)

	for i in range(bullet_count):
		var bullet = BULLET_SCENE.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.speed = randf_range(180.0, 260.0)
		bullet.max_distance = randf_range(90.0, 125.0)
		bullet.rand_scale = randf_range(0.9, 1.2)
		bullet.bullet_Damage = pellet_damage 
		bullet.effect = attack_effect
		var rotation_offset = (i - (bullet_count - 1) / 2.0) * randf_range(-spread_angle, spread_angle)
		bullet.rotation = global_rotation + rotation_offset
		get_tree().root.add_child(bullet)

	if current_ammo <= 0:
		reload()


func reload() -> void:
	if is_reloading or current_ammo == magazine_size:
		return

	is_reloading = true
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
	_emit_hud_state()


func get_hud_state() -> Dictionary:
	return {
		"mode": "ammo",
		"label": "Shotgun",
		"visible": true,
		"current": current_ammo,
		"max": magazine_size,
		"full_icon": SHELL_FULL,
		"empty_icon": SHELL_EMPTY,
		"bar_visible": is_reloading,
		"bar_progress": clamp(reload_elapsed / reload_time, 0.0, 1.0) if reload_time > 0.0 else 0.0,
	}


func _emit_hud_state() -> void:
	hud_state_changed.emit(get_hud_state())


func _play_reload_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(SHOTGUN_RELOAD_STREAM, muzzle.global_position, -6.0, 0.98, 1.02)
