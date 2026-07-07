extends BasicWeapon

const BULLET_SCENE = preload("res://src/scenes/Bullet.tscn")
const SHOTGUN_FIRE_STREAM = preload("res://audio/sfx/weapons/shotgun/shotgun_fire_01.wav")
const SHOTGUN_RELOAD_STREAM = preload("res://audio/reload.wav")
const SHELL_FULL = preload("res://Assets/Sprites/weapons/ammo/shotgun/shell_full.png")
const SHELL_EMPTY = preload("res://Assets/Sprites/weapons/ammo/shotgun/shell_empty.png")

const PELLET_COUNT := 5
const SPREAD_ANGLE := 0.26


func _setup() -> void:
	fire_cooldown = 0.0
	magazine_size = 5
	reload_time = 1.5
	bullet_damage = 5
	weapon_label = "Shotgun"
	full_icon = SHELL_FULL
	empty_icon = SHELL_EMPTY


func _fire() -> void:
	for i in range(PELLET_COUNT):
		var bullet = BULLET_SCENE.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.speed = randf_range(180.0, 260.0)
		bullet.max_distance = randf_range(90.0, 125.0)
		bullet.rand_scale = randf_range(0.9, 1.2)
		bullet.bullet_damage = bullet_damage

		var rotation_offset = (i - (PELLET_COUNT - 1) / 2.0) * randf_range(-SPREAD_ANGLE, SPREAD_ANGLE)
		bullet.rotation = global_rotation + rotation_offset
		get_tree().root.add_child(bullet)


func _play_fire_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(SHOTGUN_FIRE_STREAM, muzzle.global_position, -3.0, 0.98, 1.02)


func _play_reload_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(SHOTGUN_RELOAD_STREAM, muzzle.global_position, -6.0, 0.98, 1.02)
