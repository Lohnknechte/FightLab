extends BasicWeapon

const BULLET_SCENE = preload("res://src/scenes/KnifeBullet.tscn")
const THROW_STREAM = preload("res://audio/throw.mp3")


func _setup() -> void:
	fire_cooldown = 0.85
	magazine_size = 0  # Cooldown-only weapon, no magazine
	bullet_damage = 34
	bullet_speed = 1050.0
	bullet_max_distance = 1200.0
	bullet_rand_scale = 1.0
	weapon_label = "Wurfmesser"


func _fire() -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = global_rotation
	bullet.speed = bullet_speed
	bullet.max_distance = bullet_max_distance
	bullet.bullet_damage = bullet_damage
	bullet.rand_scale = bullet_rand_scale
	get_tree().root.add_child(bullet)


func _play_fire_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(THROW_STREAM, muzzle.global_position, -8.0, 0.98, 1.04)
