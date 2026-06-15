extends Node2D

signal hud_state_changed(state: Dictionary)


const BULLET_SCENE = preload("res://src/scenes/ShurikenBullet.tscn")
const THROW_STREAM = preload("res://audio/throw.mp3")
@onready var muzzle = $Muzzle
var _sprite: Sprite2D

@export var fire_cooldown: float = 0.3
@export var bullet_speed: float = 950.0
@export var bullet_max_distance: float = 950.0
@export var bullet_damage: int = 20

var can_shoot: bool = true
var cooldown_elapsed: float = 0.3


func _ready() -> void:
	_sprite = $Sprite
	cooldown_elapsed = fire_cooldown
	_emit_hud_state()


func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position

	$Sprite.flip_v = to_mouse.x < 0
	look_at(mouse_pos)

	if not can_shoot:
		cooldown_elapsed = min(cooldown_elapsed + delta, fire_cooldown)
		_emit_hud_state()


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and can_shoot:
			shoot()


func shoot() -> void:
	can_shoot = false
	cooldown_elapsed = 0.0
	_emit_hud_state()

	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = global_rotation
	bullet.speed = bullet_speed
	bullet.max_distance = bullet_max_distance
	bullet.bullet_Damage = bullet_damage
	bullet.rand_scale = 0.9

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(THROW_STREAM, muzzle.global_position, -8.0, 0.98, 1.04)

	get_tree().root.add_child(bullet)

	await get_tree().create_timer(fire_cooldown).timeout
	can_shoot = true
	cooldown_elapsed = fire_cooldown
	_emit_hud_state()


func get_hud_state() -> Dictionary:
	return {
		"mode": "cooldown",
		"label": "Shuriken",
		"visible": true,
		"bar_visible": true,
		"bar_progress": clamp(cooldown_elapsed / fire_cooldown, 0.0, 1.0) if fire_cooldown > 0.0 else 1.0,
	}


func _emit_hud_state() -> void:
	hud_state_changed.emit(get_hud_state())
