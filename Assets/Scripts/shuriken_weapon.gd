extends BasicWeapon

const BULLET_SCENE = preload("res://src/scenes/ShurikenBullet.tscn")
const THROW_STREAM = preload("res://audio/throw.mp3")

# Der neue Statuseffekt deines Kollegen:
var attack_effect: StatusEffect

# Deine neue Setup-Funktion mit den Shuriken-Stats:
func _setup() -> void:
	fire_cooldown = 0.3
	magazine_size = 0 # Cooldown-only weapon, no magazine
	bullet_damage = 20
	bullet_speed = 950.0
	bullet_max_distance = 950.0
	bullet_rand_scale = 0.9
	weapon_label = "Shuriken"

func _ready() -> void:
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)


func _input(event):
	super._input(event)


func _fire() -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = global_rotation
	bullet.speed = bullet_speed
	bullet.max_distance = bullet_max_distance
	bullet.bullet_damage = bullet_damage
	bullet.rand_scale = bullet_rand_scale
	bullet.effect = attack_effect
	get_tree().root.add_child(bullet)


func _play_fire_sound() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx_2d(THROW_STREAM, muzzle.global_position, -8.0, 0.98, 1.04)
