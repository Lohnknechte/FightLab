extends Node2D

signal hud_state_changed(state: Dictionary)


const BULLET_SCENE = preload("res://src/scenes/SniperBullet.tscn")
const ROUND_FULL = preload("res://Assets/Sprites/weapons/ammo/sniper/sniper_round_full.png")
const ROUND_EMPTY = preload("res://Assets/Sprites/weapons/ammo/sniper/sniper_round_empty.png")
const SNIPER_SHOT_STREAM = preload("res://audio/108852__emsiarma__snipershot.wav")
const SNIPER_RELOAD_STREAM = preload("res://audio/276956__gfl7__awp-reload-sound.mp3")

@onready var muzzle = $Muzzle
var _sprite: Sprite2D

@export var fire_cooldown: float = 0.75
@export var bullet_speed: float = 1350.0
@export var bullet_max_distance: float = 2200.0
@export var bullet_damage: int = 50
@export var magazine_size: int = 3
@export var reload_time: float = 2.0

var can_shoot: bool = true
var current_ammo: int = 3
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
		if event.button_index == MOUSE_BUTTON_LEFT and can_shoot:
			shoot()
	elif event.is_action_pressed("reload_weapon"):
		reload()


func shoot() -> void:
	if is_reloading or current_ammo <= 0:
		return

	can_shoot = false
	current_ammo -= 1
	_emit_hud_state()

	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = global_rotation
	bullet.speed = bullet_speed
	bullet.max_distance = bullet_max_distance
	bullet.bullet_Damage = bullet_damage
	bullet.rand_scale = 1.0
	bullet.effect = attack_effect

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(SNIPER_SHOT_STREAM, muzzle.global_position, -5.0, 0.98, 1.02)

	get_tree().root.add_child(bullet)

	if current_ammo <= 0:
		reload()

	await get_tree().create_timer(fire_cooldown).timeout
	if not is_reloading:
		can_shoot = true


func reload() -> void:
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


func get_hud_state() -> Dictionary:
	return {
		"mode": "ammo",
		"label": "Sniper",
		"visible": true,
		"current": current_ammo,
		"max": magazine_size,
		"full_icon": ROUND_FULL,
		"empty_icon": ROUND_EMPTY,
		"bar_visible": is_reloading,
		"bar_progress": clamp(reload_elapsed / reload_time, 0.0, 1.0) if reload_time > 0.0 else 0.0,
	}


func _emit_hud_state() -> void:
	hud_state_changed.emit(get_hud_state())


func _play_reload_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(SNIPER_RELOAD_STREAM, muzzle.global_position, -7.0, 0.98, 1.02)
