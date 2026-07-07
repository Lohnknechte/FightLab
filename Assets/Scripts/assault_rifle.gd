extends BasicWeapon

const BULLET_SCENE = preload("res://src/scenes/AssaultRifleBullet.tscn")
const ROUND_FULL = preload("res://Assets/Sprites/weapons/ammo/assault rifle/ammo full.png")
const ROUND_EMPTY = preload("res://Assets/Sprites/weapons/ammo/assault rifle/ammo_empty.png")
const FIRE_STREAM = preload("res://audio/sfx/weapons/shotgun/shotgun_fire_01.wav")
const RELOAD_STREAM = preload("res://audio/reload.wav")

const SPREAD_ANGLE := 0.04  # ~2.3° — tight burst, still readable spread


func _setup() -> void:
	fire_cooldown = 0.1          # 10 rounds/sec — smooth full-auto
	magazine_size = 20
	reload_time = 1.8
	bullet_damage = 9            # 9 × 10/s = 90 burst DPS
	bullet_speed = 1150.0
	bullet_max_distance = 1400.0
	bullet_rand_scale = 1.0
	weapon_label = "Sturmgewehr"
	auto_fire = true
	full_icon = ROUND_FULL
	empty_icon = ROUND_EMPTY


func _fire() -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = global_rotation + randf_range(-SPREAD_ANGLE, SPREAD_ANGLE)
	bullet.speed = bullet_speed + randf_range(-30.0, 30.0)
	bullet.max_distance = bullet_max_distance
	bullet.bullet_damage = bullet_damage
	bullet.rand_scale = bullet_rand_scale
	get_tree().root.add_child(bullet)


func _play_fire_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(FIRE_STREAM, muzzle.global_position, -4.0, 1.15, 1.30)


func _play_reload_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(RELOAD_STREAM, muzzle.global_position, -6.0, 0.98, 1.02)
